<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AuthService
{
    /**
     * The notification service instance.
     *
     * @var NotificationService
     */
    protected NotificationService $notificationService;

    /**
     * The admin group service instance.
     *
     * @var AdminGroupService
     */
    protected AdminGroupService $adminGroupService;

    /**
     * Create a new AuthService instance.
     *
     * @param NotificationService $notificationService
     * @param AdminGroupService $adminGroupService
     */
    public function __construct(NotificationService $notificationService, AdminGroupService $adminGroupService)
    {
        $this->notificationService = $notificationService;
        $this->adminGroupService = $adminGroupService;
    }
    /**
     * Register a new user with bcrypt password hashing.
     *
     * @param array $data
     * @return User
     * @throws ValidationException
     */
    public function register(array $data): User
    {
        // Validate organization_name (required, 2-255 chars)
        if (empty($data['organization_name']) || strlen($data['organization_name']) < 2 || strlen($data['organization_name']) > 255) {
            throw ValidationException::withMessages([
                'organization_name' => ['Organization name must be between 2 and 255 characters.'],
            ]);
        }

        // Validate department_name (optional, 2-255 chars if provided)
        if (!empty($data['department_name']) && (strlen($data['department_name']) < 2 || strlen($data['department_name']) > 255)) {
            throw ValidationException::withMessages([
                'department_name' => ['Department name must be between 2 and 255 characters.'],
            ]);
        }

        // Validate group_code if provided
        if (!empty($data['group_code'])) {
            $groupCode = $data['group_code'];
            
            // Validate format (4-6 digits)
            if (!preg_match('/^\d{4,6}$/', $groupCode)) {
                throw ValidationException::withMessages([
                    'group_code' => ['Group code must be 4-6 digits.'],
                ]);
            }
        }

        // Create user with hashed password and organizational context
        $user = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => Hash::make($data['password']),
            'role' => $data['role'] ?? 'user',
            'organization_name' => $data['organization_name'],
            'department_name' => $data['department_name'] ?? null,
            // Keep backward compatibility with old fields if provided
            'organization_id' => $data['organization_id'] ?? null,
            'department_id' => $data['department_id'] ?? null,
        ]);

        // Handle admin group creation for admin users
        if ($user->isAdmin()) {
            $this->adminGroupService->createGroupForAdmin($user);
        }

        // Handle group joining for regular users with group_code
        if ($user->isUser() && !empty($data['group_code'])) {
            try {
                $this->adminGroupService->joinGroupByCode($user, $data['group_code']);
                // Reload user to get updated admin_group_id
                $user->refresh();
            } catch (ValidationException $e) {
                // If group joining fails, delete the user and re-throw the exception
                $user->forceDelete();
                throw $e;
            }
        }

        // Load relationships for response
        $user->load(['organization', 'department', 'adminGroup', 'managedGroup']);

        // Send welcome email
        $this->notificationService->sendWelcomeEmail($user);

        return $user;
    }

    /**
     * Login user with credential validation and token generation.
     *
     * @param array $credentials
     * @return array
     * @throws ValidationException
     */
    public function login(array $credentials): array
    {
        // Validate credentials
        if (!Auth::attempt(['email' => $credentials['email'], 'password' => $credentials['password']])) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        // Get authenticated user
        $user = Auth::user();

        // Load group relationships
        $user->load(['adminGroup', 'managedGroup']);

        // Prepare token abilities with organizational and group context
        $tokenAbilities = [
            'organization_id' => $user->organization_id,
            'department_id' => $user->department_id,
            'organization_name' => $user->organization_name,
            'department_name' => $user->department_name,
            'admin_group_id' => $user->admin_group_id,
            'role' => $user->role,
            'is_admin' => $user->isAdmin(),
            'is_group_member' => $user->isGroupMember(),
        ];

        // Generate Sanctum token with 30-day expiration and organizational context
        $token = $user->createToken('auth_token', ['*'], now()->addDays(30))->plainTextToken;

        return [
            'user' => $user,
            'token' => $token,
            'token_type' => 'Bearer',
            'expires_in' => 30 * 24 * 60 * 60, // 30 days in seconds
        ];
    }

    /**
     * Refresh the authentication token for a user.
     *
     * @param User $user
     * @return array
     */
    public function refreshToken(User $user): array
    {
        // Revoke all existing tokens for the user
        $user->tokens()->delete();

        // Load group relationships
        $user->load(['adminGroup', 'managedGroup']);

        // Generate new token with 30-day expiration
        $token = $user->createToken('auth_token', ['*'], now()->addDays(30))->plainTextToken;

        return [
            'user' => $user,
            'token' => $token,
            'token_type' => 'Bearer',
            'expires_in' => 30 * 24 * 60 * 60, // 30 days in seconds
        ];
    }

    /**
     * Logout user by revoking their tokens.
     *
     * @param User $user
     * @return void
     */
    public function logout(User $user): void
    {
        // Revoke all tokens for the user
        $user->tokens()->delete();
    }

    /**
     * Send password reset link to user's email.
     *
     * @param string $email
     * @return string
     * @throws ValidationException
     */
    public function sendPasswordResetLink(string $email): string
    {
        // Check if user exists
        $user = User::where('email', $email)->first();
        
        if (!$user) {
            throw ValidationException::withMessages([
                'email' => ['We could not find a user with that email address.'],
            ]);
        }

        // Delete any existing tokens for this email
        DB::table('password_reset_tokens')->where('email', $email)->delete();

        // Generate a secure token
        $token = Str::random(64);

        // Store the token in the database
        DB::table('password_reset_tokens')->insert([
            'email' => $email,
            'token' => Hash::make($token),
            'created_at' => now(),
        ]);

        // Send password reset notification
        $user->sendPasswordResetNotification($token);

        return 'Password reset link sent to your email.';
    }

    /**
     * Reset user password with token validation.
     *
     * @param array $data
     * @return string
     * @throws ValidationException
     */
    public function resetPassword(array $data): string
    {
        // Get the password reset token record
        $resetRecord = DB::table('password_reset_tokens')
            ->where('email', $data['email'])
            ->first();

        if (!$resetRecord) {
            throw ValidationException::withMessages([
                'email' => ['Invalid or expired password reset token.'],
            ]);
        }

        // Verify the token
        if (!Hash::check($data['token'], $resetRecord->token)) {
            throw ValidationException::withMessages([
                'token' => ['Invalid password reset token.'],
            ]);
        }

        // Check if token is expired (tokens expire after 60 minutes)
        $tokenAge = now()->diffInMinutes($resetRecord->created_at);
        if ($tokenAge > 60) {
            // Delete expired token
            DB::table('password_reset_tokens')->where('email', $data['email'])->delete();
            
            throw ValidationException::withMessages([
                'token' => ['Password reset token has expired.'],
            ]);
        }

        // Find the user and update password
        $user = User::where('email', $data['email'])->first();
        
        if (!$user) {
            throw ValidationException::withMessages([
                'email' => ['User not found.'],
            ]);
        }

        // Update the password
        $user->password = Hash::make($data['password']);
        $user->save();

        // Delete the used token
        DB::table('password_reset_tokens')->where('email', $data['email'])->delete();

        // Revoke all existing tokens for security
        $user->tokens()->delete();

        return 'Password has been reset successfully.';
    }
}

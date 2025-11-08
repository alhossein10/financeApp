<?php

namespace Tests\Unit;

use App\Models\User;
use App\Services\AuthService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Notification;
use App\Notifications\ResetPasswordNotification;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class AuthServiceTest extends TestCase
{
    use RefreshDatabase;

    protected AuthService $authService;

    protected function setUp(): void
    {
        parent::setUp();
        $this->authService = new AuthService();
    }

    public function test_register_creates_user_with_hashed_password(): void
    {
        $userData = [
            'name' => 'Test User',
            'email' => 'test@example.com',
            'password' => 'password123',
            'role' => 'user',
        ];

        $user = $this->authService->register($userData);

        $this->assertInstanceOf(User::class, $user);
        $this->assertEquals('Test User', $user->name);
        $this->assertEquals('test@example.com', $user->email);
        $this->assertEquals('user', $user->role);
        $this->assertTrue(Hash::check('password123', $user->password));
        $this->assertDatabaseHas('users', [
            'email' => 'test@example.com',
            'name' => 'Test User',
        ]);
    }

    public function test_register_defaults_to_user_role(): void
    {
        $userData = [
            'name' => 'Test User',
            'email' => 'test@example.com',
            'password' => 'password123',
        ];

        $user = $this->authService->register($userData);

        $this->assertEquals('user', $user->role);
    }

    public function test_login_returns_token_with_valid_credentials(): void
    {
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('password123'),
        ]);

        $credentials = [
            'email' => 'test@example.com',
            'password' => 'password123',
        ];

        $result = $this->authService->login($credentials);

        $this->assertArrayHasKey('user', $result);
        $this->assertArrayHasKey('token', $result);
        $this->assertArrayHasKey('token_type', $result);
        $this->assertArrayHasKey('expires_in', $result);
        $this->assertEquals('Bearer', $result['token_type']);
        $this->assertEquals(30 * 24 * 60 * 60, $result['expires_in']);
        $this->assertNotEmpty($result['token']);
    }

    public function test_login_throws_exception_with_invalid_credentials(): void
    {
        User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('password123'),
        ]);

        $credentials = [
            'email' => 'test@example.com',
            'password' => 'wrongpassword',
        ];

        $this->expectException(ValidationException::class);
        $this->authService->login($credentials);
    }

    public function test_refresh_token_revokes_old_tokens_and_creates_new_one(): void
    {
        $user = User::factory()->create();
        
        // Create initial token
        $oldToken = $user->createToken('auth_token')->plainTextToken;
        $this->assertCount(1, $user->tokens);

        // Refresh token
        $result = $this->authService->refreshToken($user);

        $this->assertArrayHasKey('token', $result);
        $this->assertArrayHasKey('user', $result);
        $this->assertArrayHasKey('token_type', $result);
        $this->assertEquals('Bearer', $result['token_type']);
        
        // Verify old tokens were revoked
        $user->refresh();
        $this->assertCount(1, $user->tokens);
    }

    public function test_logout_revokes_all_user_tokens(): void
    {
        $user = User::factory()->create();
        
        // Create multiple tokens
        $user->createToken('token1');
        $user->createToken('token2');
        $this->assertCount(2, $user->tokens);

        // Logout
        $this->authService->logout($user);

        // Verify all tokens were revoked
        $user->refresh();
        $this->assertCount(0, $user->tokens);
    }

    public function test_send_password_reset_link_creates_token_and_sends_notification(): void
    {
        Notification::fake();

        $user = User::factory()->create([
            'email' => 'test@example.com',
        ]);

        $message = $this->authService->sendPasswordResetLink('test@example.com');

        $this->assertEquals('Password reset link sent to your email.', $message);
        
        // Verify token was created in database
        $this->assertDatabaseHas('password_reset_tokens', [
            'email' => 'test@example.com',
        ]);

        // Verify notification was sent
        Notification::assertSentTo($user, ResetPasswordNotification::class);
    }

    public function test_send_password_reset_link_throws_exception_for_nonexistent_user(): void
    {
        $this->expectException(ValidationException::class);
        $this->authService->sendPasswordResetLink('nonexistent@example.com');
    }

    public function test_reset_password_updates_password_with_valid_token(): void
    {
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('oldpassword'),
        ]);

        // Create a password reset token
        $token = 'test-reset-token';
        DB::table('password_reset_tokens')->insert([
            'email' => 'test@example.com',
            'token' => Hash::make($token),
            'created_at' => now(),
        ]);

        // Reset password
        $message = $this->authService->resetPassword([
            'email' => 'test@example.com',
            'token' => $token,
            'password' => 'newpassword123',
        ]);

        $this->assertEquals('Password has been reset successfully.', $message);

        // Verify password was updated
        $user->refresh();
        $this->assertTrue(Hash::check('newpassword123', $user->password));

        // Verify token was deleted
        $this->assertDatabaseMissing('password_reset_tokens', [
            'email' => 'test@example.com',
        ]);

        // Verify all tokens were revoked
        $this->assertCount(0, $user->tokens);
    }

    public function test_reset_password_throws_exception_with_invalid_token(): void
    {
        $user = User::factory()->create([
            'email' => 'test@example.com',
        ]);

        DB::table('password_reset_tokens')->insert([
            'email' => 'test@example.com',
            'token' => Hash::make('valid-token'),
            'created_at' => now(),
        ]);

        $this->expectException(ValidationException::class);
        $this->authService->resetPassword([
            'email' => 'test@example.com',
            'token' => 'invalid-token',
            'password' => 'newpassword123',
        ]);
    }

    public function test_reset_password_throws_exception_with_expired_token(): void
    {
        $user = User::factory()->create([
            'email' => 'test@example.com',
        ]);

        // Create an expired token (older than 60 minutes)
        $token = 'test-reset-token';
        DB::table('password_reset_tokens')->insert([
            'email' => 'test@example.com',
            'token' => Hash::make($token),
            'created_at' => now()->subMinutes(61),
        ]);

        $this->expectException(ValidationException::class);
        $this->authService->resetPassword([
            'email' => 'test@example.com',
            'token' => $token,
            'password' => 'newpassword123',
        ]);
    }

    public function test_reset_password_throws_exception_for_nonexistent_email(): void
    {
        $this->expectException(ValidationException::class);
        $this->authService->resetPassword([
            'email' => 'nonexistent@example.com',
            'token' => 'some-token',
            'password' => 'newpassword123',
        ]);
    }
}

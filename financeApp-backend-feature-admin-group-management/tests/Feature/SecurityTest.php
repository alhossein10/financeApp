<?php

namespace Tests\Feature;

use App\Models\Expense;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class SecurityTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Clear rate limiters before each test
        RateLimiter::clear('api');
        RateLimiter::clear('login');
        RateLimiter::clear('public');
    }

    // ==================== Rate Limiting Tests ====================

    public function test_authenticated_api_requests_are_rate_limited_to_60_per_minute(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test-token')->plainTextToken;

        // Make 60 requests (should all succeed)
        for ($i = 0; $i < 60; $i++) {
            $response = $this->withHeader('Authorization', 'Bearer ' . $token)
                ->getJson('/api/v1/expenses');
            
            $response->assertStatus(200);
        }

        // 61st request should be rate limited
        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/v1/expenses');

        $response->assertStatus(429)
            ->assertHeader('X-RateLimit-Limit', '60')
            ->assertHeader('Retry-After');
    }

    public function test_login_endpoint_is_rate_limited_to_5_per_minute(): void
    {
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('password123'),
        ]);

        // Make 5 login attempts (should all be processed)
        for ($i = 0; $i < 5; $i++) {
            $response = $this->postJson('/api/v1/auth/login', [
                'email' => 'test@example.com',
                'password' => 'password123',
            ]);
            
            // Should get response (either success or validation error)
            $this->assertContains($response->status(), [200, 401, 422]);
        }

        // 6th request should be rate limited
        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'test@example.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(429)
            ->assertHeader('Retry-After');
    }

    public function test_public_endpoints_are_rate_limited_by_ip(): void
    {
        // Make 20 requests to public endpoint (should all succeed)
        for ($i = 0; $i < 20; $i++) {
            $response = $this->postJson('/api/v1/auth/register', [
                'name' => 'Test User ' . $i,
                'email' => 'test' . $i . '@example.com',
                'password' => 'password123',
                'password_confirmation' => 'password123',
            ]);
            
            $this->assertContains($response->status(), [200, 201, 422]);
        }

        // 21st request should be rate limited
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Test User 21',
            'email' => 'test21@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertStatus(429);
    }

    public function test_rate_limit_response_includes_retry_after_header(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test-token')->plainTextToken;

        // Exhaust rate limit
        for ($i = 0; $i < 60; $i++) {
            $this->withHeader('Authorization', 'Bearer ' . $token)
                ->getJson('/api/v1/expenses');
        }

        // Next request should include Retry-After header
        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/v1/expenses');

        $response->assertStatus(429)
            ->assertHeader('Retry-After')
            ->assertHeader('X-RateLimit-Limit')
            ->assertHeader('X-RateLimit-Remaining', '0');
    }

    // ==================== File Upload Validation Tests ====================

    public function test_file_upload_validates_file_type(): void
    {
        Storage::fake('local');
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        // Try to upload an invalid file type (e.g., .txt)
        $file = UploadedFile::fake()->create('document.txt', 100, 'text/plain');

        $response = $this->actingAs($user)
            ->postJson("/api/v1/expenses/{$expense->id}/invoice", [
                'invoice' => $file,
            ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
                'error_code' => 'INVALID_FILE_TYPE',
            ])
            ->assertJsonPath('message', 'Invalid file type. Only JPEG, PNG, and PDF files are allowed.');
    }

    public function test_file_upload_validates_file_size(): void
    {
        Storage::fake('local');
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        // Try to upload a file larger than 10MB
        $file = UploadedFile::fake()->create('large-image.jpg', 11000); // 11MB

        $response = $this->actingAs($user)
            ->postJson("/api/v1/expenses/{$expense->id}/invoice", [
                'invoice' => $file,
            ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
                'error_code' => 'FILE_TOO_LARGE',
                'max_size_mb' => 10,
            ])
            ->assertJsonPath('message', 'File size exceeds maximum allowed size of 10MB.');
    }

    public function test_file_upload_accepts_valid_image_types(): void
    {
        Storage::fake('local');
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        // Test JPEG
        $jpegFile = UploadedFile::fake()->image('invoice.jpg');
        $response = $this->actingAs($user)
            ->postJson("/api/v1/expenses/{$expense->id}/invoice", [
                'invoice' => $jpegFile,
            ]);
        $response->assertStatus(200);

        // Test PNG
        $pngFile = UploadedFile::fake()->image('invoice.png');
        $response = $this->actingAs($user)
            ->postJson("/api/v1/expenses/{$expense->id}/invoice", [
                'invoice' => $pngFile,
            ]);
        $response->assertStatus(200);
    }

    public function test_file_upload_accepts_pdf_files(): void
    {
        Storage::fake('local');
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        // Create a fake PDF file
        $pdfFile = UploadedFile::fake()->create('invoice.pdf', 100, 'application/pdf');

        $response = $this->actingAs($user)
            ->postJson("/api/v1/expenses/{$expense->id}/invoice", [
                'invoice' => $pdfFile,
            ]);

        $response->assertStatus(200);
    }

    public function test_file_upload_rejects_files_with_double_extensions(): void
    {
        Storage::fake('local');
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        // Create a file with double extension (potential security risk)
        $file = UploadedFile::fake()->createWithContent(
            'malicious.php.jpg',
            'fake content'
        );

        $response = $this->actingAs($user)
            ->postJson("/api/v1/expenses/{$expense->id}/invoice", [
                'invoice' => $file,
            ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
                'error_code' => 'SUSPICIOUS_FILE_NAME',
            ]);
    }

    public function test_file_upload_validates_file_extension_matches_mime_type(): void
    {
        Storage::fake('local');
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        // Try to upload a file with mismatched extension
        $file = UploadedFile::fake()->create('document.exe', 100, 'image/jpeg');

        $response = $this->actingAs($user)
            ->postJson("/api/v1/expenses/{$expense->id}/invoice", [
                'invoice' => $file,
            ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
                'error_code' => 'INVALID_FILE_EXTENSION',
            ]);
    }

    // ==================== Sensitive Operation Authentication Tests ====================

    public function test_password_change_requires_recent_authentication(): void
    {
        $user = User::factory()->create([
            'password' => Hash::make('oldpassword123'),
        ]);

        // Create a token that's older than 15 minutes
        $token = $user->createToken('test-token')->plainTextToken;
        
        // Manually update the token's created_at to be 20 minutes ago
        $user->tokens()->update(['created_at' => now()->subMinutes(20)]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->putJson('/api/v1/profile/password', [
                'current_password' => 'oldpassword123',
                'new_password' => 'newpassword123',
                'new_password_confirmation' => 'newpassword123',
            ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'error_code' => 'RECENT_AUTH_REQUIRED',
            ])
            ->assertJsonPath('message', 'Recent authentication required. Please re-authenticate to perform this action.');
    }

    public function test_account_deletion_requires_recent_authentication(): void
    {
        $user = User::factory()->create();

        // Create a token that's older than 15 minutes
        $token = $user->createToken('test-token')->plainTextToken;
        $user->tokens()->update(['created_at' => now()->subMinutes(20)]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->deleteJson('/api/v1/profile');

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'error_code' => 'RECENT_AUTH_REQUIRED',
            ]);
    }

    public function test_password_change_succeeds_with_recent_authentication(): void
    {
        $user = User::factory()->create([
            'password' => Hash::make('oldpassword123'),
        ]);

        // Create a fresh token (within 15 minutes)
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->putJson('/api/v1/profile/password', [
                'current_password' => 'oldpassword123',
                'new_password' => 'newpassword123',
                'new_password_confirmation' => 'newpassword123',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);
    }

    public function test_account_deletion_succeeds_with_recent_authentication(): void
    {
        $user = User::factory()->create();

        // Create a fresh token (within 15 minutes)
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->deleteJson('/api/v1/profile');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);
    }

    public function test_recent_auth_middleware_returns_minutes_since_auth(): void
    {
        $user = User::factory()->create([
            'password' => Hash::make('password123'),
        ]);

        $token = $user->createToken('test-token')->plainTextToken;
        $user->tokens()->update(['created_at' => now()->subMinutes(25)]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->putJson('/api/v1/profile/password', [
                'current_password' => 'password123',
                'new_password' => 'newpassword123',
                'new_password_confirmation' => 'newpassword123',
            ]);

        $response->assertStatus(403)
            ->assertJsonStructure([
                'success',
                'message',
                'error_code',
                'minutes_since_auth',
            ])
            ->assertJsonPath('minutes_since_auth', 25);
    }

    // ==================== Security Headers Tests ====================

    public function test_api_responses_include_security_headers(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)
            ->getJson('/api/v1/expenses');

        $response->assertStatus(200)
            ->assertHeader('X-Content-Type-Options', 'nosniff')
            ->assertHeader('X-Frame-Options', 'DENY')
            ->assertHeader('X-XSS-Protection', '1; mode=block')
            ->assertHeader('Referrer-Policy', 'strict-origin-when-cross-origin')
            ->assertHeader('Permissions-Policy', 'geolocation=(), microphone=(), camera=()');
    }

    public function test_options_requests_include_cors_headers(): void
    {
        $response = $this->options('/api/v1/expenses');

        $response->assertHeader('Access-Control-Allow-Methods')
            ->assertHeader('Access-Control-Allow-Headers')
            ->assertHeader('Access-Control-Max-Age', '86400');
    }

    // ==================== Authentication Token Security Tests ====================

    public function test_invalid_token_returns_401(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer invalid-token-here')
            ->getJson('/api/v1/expenses');

        $response->assertStatus(401);
    }

    public function test_missing_token_returns_401(): void
    {
        $response = $this->getJson('/api/v1/expenses');

        $response->assertStatus(401);
    }

    public function test_revoked_token_cannot_access_protected_routes(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test-token')->plainTextToken;

        // Verify token works
        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/v1/expenses');
        $response->assertStatus(200);

        // Revoke all tokens
        $user->tokens()->delete();

        // Token should no longer work
        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/v1/expenses');
        $response->assertStatus(401);
    }

    // ==================== Authorization Tests ====================

    public function test_regular_user_cannot_access_admin_endpoints(): void
    {
        $user = User::factory()->create(['role' => 'user']);

        $response = $this->actingAs($user)
            ->getJson('/api/v1/admin/dashboard/stats');

        $response->assertStatus(403);
    }

    public function test_admin_user_can_access_admin_endpoints(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin)
            ->getJson('/api/v1/admin/dashboard/stats');

        $response->assertStatus(200);
    }

    public function test_user_cannot_access_other_users_data(): void
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        
        $expense = Expense::factory()->create(['user_id' => $user2->id]);

        $response = $this->actingAs($user1)
            ->getJson("/api/v1/expenses/{$expense->id}");

        $response->assertStatus(403);
    }

    public function test_user_can_only_delete_their_own_data(): void
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        
        $expense = Expense::factory()->create(['user_id' => $user2->id]);

        $response = $this->actingAs($user1)
            ->deleteJson("/api/v1/expenses/{$expense->id}");

        $response->assertStatus(403);
    }
}

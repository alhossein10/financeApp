<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TokenValidationTest extends TestCase
{
    use RefreshDatabase;

    public function test_valid_token_allows_access_to_protected_routes(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/v1/auth/me');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => [
                        'id' => $user->id,
                        'email' => $user->email,
                    ],
                ],
            ]);
    }

    public function test_missing_token_returns_unauthorized(): void
    {
        $response = $this->getJson('/api/v1/auth/me');

        $response->assertStatus(401);
    }

    public function test_invalid_token_returns_unauthorized(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer invalid-token-string')
            ->getJson('/api/v1/auth/me');

        $response->assertStatus(401);
    }

    public function test_malformed_authorization_header_returns_unauthorized(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('auth_token')->plainTextToken;

        // Missing "Bearer" prefix
        $response = $this->withHeader('Authorization', $token)
            ->getJson('/api/v1/auth/me');

        $response->assertStatus(401);
    }

    public function test_token_refresh_revokes_old_tokens_and_issues_new_one(): void
    {
        $user = User::factory()->create();
        $oldToken = $user->createToken('auth_token')->plainTextToken;

        // Verify old token works
        $response = $this->withHeader('Authorization', 'Bearer ' . $oldToken)
            ->getJson('/api/v1/auth/me');
        $response->assertStatus(200);

        // Refresh token
        $refreshResponse = $this->withHeader('Authorization', 'Bearer ' . $oldToken)
            ->postJson('/api/v1/auth/refresh');

        $refreshResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Token refreshed successfully.',
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'user',
                    'token',
                    'token_type',
                    'expires_in',
                ],
            ]);

        $newToken = $refreshResponse->json('data.token');
        $this->assertNotEmpty($newToken);
        $this->assertNotEquals($oldToken, $newToken);

        // Verify old token no longer works
        $oldTokenResponse = $this->withHeader('Authorization', 'Bearer ' . $oldToken)
            ->getJson('/api/v1/auth/me');
        $oldTokenResponse->assertStatus(401);

        // Verify new token works
        $newTokenResponse = $this->withHeader('Authorization', 'Bearer ' . $newToken)
            ->getJson('/api/v1/auth/me');
        $newTokenResponse->assertStatus(200);
    }

    public function test_token_refresh_requires_authentication(): void
    {
        $response = $this->postJson('/api/v1/auth/refresh');

        $response->assertStatus(401);
    }

    public function test_me_endpoint_returns_authenticated_user_data(): void
    {
        $user = User::factory()->create([
            'name' => 'Test User',
            'email' => 'test@example.com',
            'role' => 'user',
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/auth/me');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => [
                        'id' => $user->id,
                        'name' => 'Test User',
                        'email' => 'test@example.com',
                        'role' => 'user',
                    ],
                ],
            ]);
    }

    public function test_token_includes_correct_expiration_time(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/auth/refresh');

        $response->assertStatus(200);

        $expiresIn = $response->json('data.expires_in');
        $this->assertEquals(30 * 24 * 60 * 60, $expiresIn); // 30 days in seconds
    }

    public function test_multiple_tokens_can_exist_for_same_user(): void
    {
        $user = User::factory()->create();
        
        $token1 = $user->createToken('device1')->plainTextToken;
        $token2 = $user->createToken('device2')->plainTextToken;

        // Both tokens should work
        $response1 = $this->withHeader('Authorization', 'Bearer ' . $token1)
            ->getJson('/api/v1/auth/me');
        $response1->assertStatus(200);

        $response2 = $this->withHeader('Authorization', 'Bearer ' . $token2)
            ->getJson('/api/v1/auth/me');
        $response2->assertStatus(200);

        $this->assertCount(2, $user->tokens);
    }
}

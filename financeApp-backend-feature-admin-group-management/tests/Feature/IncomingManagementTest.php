<?php

namespace Tests\Feature;

use App\Models\Incoming;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class IncomingManagementTest extends TestCase
{
    use RefreshDatabase;

    // ========== CREATE TESTS ==========

    public function test_user_can_create_incoming(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/incoming', [
                'description' => 'Freelance payment',
                'amount_usd' => 1500.00,
                'incoming_date' => '2025-10-15',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Incoming created successfully',
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'id',
                    'user_id',
                    'description',
                    'amount_usd',
                    'incoming_date',
                    'sync_status',
                    'created_at',
                    'updated_at',
                ],
            ]);

        $this->assertDatabaseHas('incomings', [
            'user_id' => $user->id,
            'description' => 'Freelance payment',
            'amount_usd' => 1500.00,
        ]);
    }

    public function test_create_incoming_validates_required_fields(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/incoming', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['description', 'amount_usd', 'incoming_date']);
    }

    public function test_create_incoming_validates_amount_is_numeric(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/incoming', [
                'description' => 'Test incoming',
                'amount_usd' => 'not-a-number',
                'incoming_date' => '2025-10-15',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['amount_usd']);
    }

    public function test_create_incoming_validates_amount_is_non_negative(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/incoming', [
                'description' => 'Test incoming',
                'amount_usd' => -100.00,
                'incoming_date' => '2025-10-15',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['amount_usd']);
    }

    public function test_create_incoming_validates_date_not_in_future(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/incoming', [
                'description' => 'Future incoming',
                'amount_usd' => 500.00,
                'incoming_date' => '2026-12-31',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['incoming_date']);
    }

    public function test_unauthenticated_user_cannot_create_incoming(): void
    {
        $response = $this->postJson('/api/v1/incoming', [
            'description' => 'Test incoming',
            'amount_usd' => 500.00,
            'incoming_date' => '2025-10-15',
        ]);

        $response->assertStatus(401);
    }

    // ========== READ TESTS ==========

    public function test_user_can_list_their_own_incoming(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();

        Incoming::factory()->count(3)->create(['user_id' => $user->id]);
        Incoming::factory()->count(2)->create(['user_id' => $otherUser->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/incoming');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonCount(3, 'data')
            ->assertJsonStructure([
                'success',
                'data' => [
                    '*' => [
                        'id',
                        'user_id',
                        'description',
                        'amount_usd',
                        'incoming_date',
                    ],
                ],
                'meta' => [
                    'current_page',
                    'last_page',
                    'per_page',
                    'total',
                ],
            ]);

        // Verify user only sees their own incoming records
        $responseData = $response->json('data');
        foreach ($responseData as $incoming) {
            $this->assertEquals($user->id, $incoming['user_id']);
        }
    }

    public function test_admin_can_list_all_incoming(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        Incoming::factory()->count(2)->create(['user_id' => $user1->id]);
        Incoming::factory()->count(3)->create(['user_id' => $user2->id]);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/incoming');

        $response->assertStatus(200)
            ->assertJsonCount(5, 'data');
    }

    public function test_user_can_view_their_own_incoming(): void
    {
        $user = User::factory()->create();
        $incoming = Incoming::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson("/api/v1/incoming/{$incoming->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $incoming->id,
                    'user_id' => $user->id,
                    'description' => $incoming->description,
                ],
            ]);
    }

    public function test_user_cannot_view_other_users_incoming(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $incoming = Incoming::factory()->create(['user_id' => $otherUser->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson("/api/v1/incoming/{$incoming->id}");

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthorized to view this incoming',
            ]);
    }

    public function test_admin_can_view_any_incoming(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();
        $incoming = Incoming::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson("/api/v1/incoming/{$incoming->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $incoming->id,
                ],
            ]);
    }

    // ========== UPDATE TESTS ==========

    public function test_user_can_update_their_own_incoming(): void
    {
        $user = User::factory()->create();
        $incoming = Incoming::factory()->create([
            'user_id' => $user->id,
            'description' => 'Original description',
            'amount_usd' => 500.00,
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->putJson("/api/v1/incoming/{$incoming->id}", [
                'description' => 'Updated description',
                'amount_usd' => 750.00,
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Incoming updated successfully',
                'data' => [
                    'id' => $incoming->id,
                    'description' => 'Updated description',
                    'amount_usd' => '750.00',
                ],
            ]);

        $this->assertDatabaseHas('incomings', [
            'id' => $incoming->id,
            'description' => 'Updated description',
            'amount_usd' => 750.00,
        ]);
    }

    public function test_user_cannot_update_other_users_incoming(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $incoming = Incoming::factory()->create(['user_id' => $otherUser->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->putJson("/api/v1/incoming/{$incoming->id}", [
                'description' => 'Hacked description',
            ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthorized to update this incoming',
            ]);
    }

    public function test_admin_can_update_any_incoming(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();
        $incoming = Incoming::factory()->create([
            'user_id' => $user->id,
            'description' => 'Original',
        ]);

        $response = $this->actingAs($admin, 'sanctum')
            ->putJson("/api/v1/incoming/{$incoming->id}", [
                'description' => 'Admin updated',
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('incomings', [
            'id' => $incoming->id,
            'description' => 'Admin updated',
        ]);
    }

    public function test_update_incoming_updates_timestamp(): void
    {
        $user = User::factory()->create();
        $incoming = Incoming::factory()->create(['user_id' => $user->id]);

        $originalUpdatedAt = $incoming->updated_at;

        // Wait a moment to ensure timestamp difference
        sleep(1);

        $response = $this->actingAs($user, 'sanctum')
            ->putJson("/api/v1/incoming/{$incoming->id}", [
                'description' => 'Updated',
            ]);

        $response->assertStatus(200);

        $incoming->refresh();
        $this->assertNotEquals($originalUpdatedAt, $incoming->updated_at);
    }

    // ========== DELETE TESTS ==========

    public function test_user_can_delete_their_own_incoming(): void
    {
        $user = User::factory()->create();
        $incoming = Incoming::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->deleteJson("/api/v1/incoming/{$incoming->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Incoming deleted successfully',
            ]);

        // Verify soft delete
        $this->assertSoftDeleted('incomings', [
            'id' => $incoming->id,
        ]);
    }

    public function test_user_cannot_delete_other_users_incoming(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $incoming = Incoming::factory()->create(['user_id' => $otherUser->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->deleteJson("/api/v1/incoming/{$incoming->id}");

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthorized to delete this incoming',
            ]);

        // Verify incoming was not deleted
        $this->assertDatabaseHas('incomings', [
            'id' => $incoming->id,
            'deleted_at' => null,
        ]);
    }

    public function test_admin_can_delete_any_incoming(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();
        $incoming = Incoming::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($admin, 'sanctum')
            ->deleteJson("/api/v1/incoming/{$incoming->id}");

        $response->assertStatus(200);

        $this->assertSoftDeleted('incomings', [
            'id' => $incoming->id,
        ]);
    }

    public function test_soft_deleted_incoming_not_shown_in_list(): void
    {
        $user = User::factory()->create();
        $incoming1 = Incoming::factory()->create(['user_id' => $user->id]);
        $incoming2 = Incoming::factory()->create(['user_id' => $user->id]);

        // Delete one incoming
        $incoming1->delete();

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/incoming');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data');

        $responseData = $response->json('data');
        $this->assertEquals($incoming2->id, $responseData[0]['id']);
    }

    // ========== AUTHORIZATION TESTS ==========

    public function test_regular_user_cannot_see_other_users_incoming_in_list(): void
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        Incoming::factory()->count(3)->create(['user_id' => $user1->id]);
        Incoming::factory()->count(2)->create(['user_id' => $user2->id]);

        $response = $this->actingAs($user1, 'sanctum')
            ->getJson('/api/v1/incoming');

        $response->assertStatus(200)
            ->assertJsonCount(3, 'data');

        // Verify all returned incoming records belong to user1
        $responseData = $response->json('data');
        foreach ($responseData as $incoming) {
            $this->assertEquals($user1->id, $incoming['user_id']);
        }
    }

    public function test_admin_sees_all_users_incoming_in_list(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        Incoming::factory()->count(2)->create(['user_id' => $user1->id]);
        Incoming::factory()->count(3)->create(['user_id' => $user2->id]);
        Incoming::factory()->count(1)->create(['user_id' => $admin->id]);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/incoming');

        $response->assertStatus(200)
            ->assertJsonCount(6, 'data');
    }

    public function test_unauthenticated_user_cannot_list_incoming(): void
    {
        $response = $this->getJson('/api/v1/incoming');

        $response->assertStatus(401);
    }

    public function test_unauthenticated_user_cannot_view_incoming(): void
    {
        $user = User::factory()->create();
        $incoming = Incoming::factory()->create(['user_id' => $user->id]);

        $response = $this->getJson("/api/v1/incoming/{$incoming->id}");

        $response->assertStatus(401);
    }

    public function test_unauthenticated_user_cannot_update_incoming(): void
    {
        $user = User::factory()->create();
        $incoming = Incoming::factory()->create(['user_id' => $user->id]);

        $response = $this->putJson("/api/v1/incoming/{$incoming->id}", [
            'description' => 'Updated',
        ]);

        $response->assertStatus(401);
    }

    public function test_unauthenticated_user_cannot_delete_incoming(): void
    {
        $user = User::factory()->create();
        $incoming = Incoming::factory()->create(['user_id' => $user->id]);

        $response = $this->deleteJson("/api/v1/incoming/{$incoming->id}");

        $response->assertStatus(401);
    }
}

<?php

namespace Tests\Feature;

use App\Models\Exchange;
use App\Models\Transfer;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TransferManagementTest extends TestCase
{
    use RefreshDatabase;

    // ========== CREATE TESTS ==========

    public function test_user_can_create_transfer(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => 'John Doe',
                'amount_usd' => 500.00,
                'transfer_date' => '2025-10-15',
                'notes' => 'Payment for services',
            ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'id',
                    'user_id',
                    'recipient_name',
                    'amount_usd',
                    'transfer_date',
                    'notes',
                    'sync_status',
                    'created_at',
                    'updated_at',
                ],
            ]);

        $this->assertDatabaseHas('transfers', [
            'user_id' => $user->id,
            'recipient_name' => 'John Doe',
            'amount_usd' => 500.00,
        ]);
    }

    public function test_create_transfer_requires_authentication(): void
    {
        $response = $this->postJson('/api/v1/transfers', [
            'recipient_name' => 'John Doe',
            'amount_usd' => 500.00,
            'transfer_date' => '2025-10-15',
        ]);

        $response->assertStatus(401);
    }

    public function test_create_transfer_validates_required_fields(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/transfers', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['recipient_name', 'amount_usd', 'transfer_date']);
    }

    // ========== READ TESTS ==========

    public function test_user_can_list_their_transfers(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();

        Transfer::factory()->count(3)->create(['user_id' => $user->id]);
        Transfer::factory()->count(2)->create(['user_id' => $otherUser->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/transfers');

        $response->assertStatus(200)
            ->assertJsonCount(3, 'data');
    }

    public function test_admin_can_list_all_transfers(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        Transfer::factory()->count(2)->create(['user_id' => $user1->id]);
        Transfer::factory()->count(3)->create(['user_id' => $user2->id]);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/transfers');

        $response->assertStatus(200)
            ->assertJsonCount(5, 'data');
    }

    public function test_user_can_view_single_transfer(): void
    {
        $user = User::factory()->create();
        $transfer = Transfer::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson("/api/v1/transfers/{$transfer->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $transfer->id,
                    'recipient_name' => $transfer->recipient_name,
                ],
            ]);
    }

    public function test_user_cannot_view_other_users_transfer(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $transfer = Transfer::factory()->create(['user_id' => $otherUser->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson("/api/v1/transfers/{$transfer->id}");

        $response->assertStatus(403);
    }

    public function test_admin_can_view_any_transfer(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();
        $transfer = Transfer::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson("/api/v1/transfers/{$transfer->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $transfer->id,
                ],
            ]);
    }

    // ========== UPDATE TESTS ==========

    public function test_user_can_update_their_transfer(): void
    {
        $user = User::factory()->create();
        $transfer = Transfer::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->putJson("/api/v1/transfers/{$transfer->id}", [
                'recipient_name' => 'Jane Smith',
                'amount_usd' => 750.00,
                'transfer_date' => '2025-10-20',
                'notes' => 'Updated payment',
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('transfers', [
            'id' => $transfer->id,
            'recipient_name' => 'Jane Smith',
            'amount_usd' => 750.00,
        ]);
    }

    public function test_user_cannot_update_other_users_transfer(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $transfer = Transfer::factory()->create(['user_id' => $otherUser->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->putJson("/api/v1/transfers/{$transfer->id}", [
                'recipient_name' => 'Jane Smith',
                'amount_usd' => 750.00,
                'transfer_date' => '2025-10-20',
            ]);

        $response->assertStatus(403);
    }

    public function test_admin_can_update_any_transfer(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();
        $transfer = Transfer::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($admin, 'sanctum')
            ->putJson("/api/v1/transfers/{$transfer->id}", [
                'recipient_name' => 'Admin Updated',
                'amount_usd' => 1000.00,
                'transfer_date' => '2025-10-25',
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('transfers', [
            'id' => $transfer->id,
            'recipient_name' => 'Admin Updated',
        ]);
    }

    // ========== DELETE TESTS ==========

    public function test_user_can_delete_their_transfer(): void
    {
        $user = User::factory()->create();
        $transfer = Transfer::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->deleteJson("/api/v1/transfers/{$transfer->id}");

        $response->assertStatus(200);

        $this->assertSoftDeleted('transfers', [
            'id' => $transfer->id,
        ]);
    }

    public function test_user_cannot_delete_other_users_transfer(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $transfer = Transfer::factory()->create(['user_id' => $otherUser->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->deleteJson("/api/v1/transfers/{$transfer->id}");

        $response->assertStatus(403);

        $this->assertDatabaseHas('transfers', [
            'id' => $transfer->id,
            'deleted_at' => null,
        ]);
    }

    public function test_admin_can_delete_any_transfer(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();
        $transfer = Transfer::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($admin, 'sanctum')
            ->deleteJson("/api/v1/transfers/{$transfer->id}");

        $response->assertStatus(200);

        $this->assertSoftDeleted('transfers', [
            'id' => $transfer->id,
        ]);
    }

    // ========== EXCHANGE DATA LINKING TESTS ==========

    public function test_user_can_add_exchange_to_transfer(): void
    {
        $user = User::factory()->create();
        $transfer = Transfer::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/transfers/{$transfer->id}/exchange", [
                'converted_amount_syp' => 12500000.00,
                'exchange_rate_usd_to_syp' => 12500.00,
                'exchange_date' => '2025-10-15',
            ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'id',
                    'transfer_id',
                    'converted_amount_syp',
                    'exchange_rate_usd_to_syp',
                    'exchange_date',
                ],
            ]);

        $this->assertDatabaseHas('exchanges', [
            'transfer_id' => $transfer->id,
            'converted_amount_syp' => 12500000.00,
        ]);
    }

    public function test_user_cannot_add_exchange_to_other_users_transfer(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $transfer = Transfer::factory()->create(['user_id' => $otherUser->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/transfers/{$transfer->id}/exchange", [
                'converted_amount_syp' => 12500000.00,
                'exchange_rate_usd_to_syp' => 12500.00,
                'exchange_date' => '2025-10-15',
            ]);

        $response->assertStatus(403);
    }

    public function test_exchange_can_have_syp_only(): void
    {
        $user = User::factory()->create();
        $transfer = Transfer::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/transfers/{$transfer->id}/exchange", [
                'converted_amount_syp' => 12500000.00,
                'exchange_rate_usd_to_syp' => 12500.00,
                'exchange_date' => '2025-10-15',
            ]);

        $response->assertStatus(201);

        $this->assertDatabaseHas('exchanges', [
            'transfer_id' => $transfer->id,
            'converted_amount_syp' => 12500000.00,
            'converted_amount_try' => null,
        ]);
    }

    public function test_exchange_can_have_try_only(): void
    {
        $user = User::factory()->create();
        $transfer = Transfer::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/transfers/{$transfer->id}/exchange", [
                'converted_amount_try' => 15000.00,
                'exchange_rate_usd_to_try' => 30.00,
                'exchange_date' => '2025-10-15',
            ]);

        $response->assertStatus(201);

        $this->assertDatabaseHas('exchanges', [
            'transfer_id' => $transfer->id,
            'converted_amount_try' => 15000.00,
            'converted_amount_syp' => null,
        ]);
    }

    public function test_exchange_can_have_both_currencies(): void
    {
        $user = User::factory()->create();
        $transfer = Transfer::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/transfers/{$transfer->id}/exchange", [
                'converted_amount_syp' => 12500000.00,
                'exchange_rate_usd_to_syp' => 12500.00,
                'converted_amount_try' => 15000.00,
                'exchange_rate_usd_to_try' => 30.00,
                'exchange_date' => '2025-10-15',
            ]);

        $response->assertStatus(201);

        $this->assertDatabaseHas('exchanges', [
            'transfer_id' => $transfer->id,
            'converted_amount_syp' => 12500000.00,
            'converted_amount_try' => 15000.00,
        ]);
    }

    // ========== RELATIONSHIP LOADING TESTS ==========

    public function test_transfer_includes_exchange_data_when_present(): void
    {
        $user = User::factory()->create();
        $transfer = Transfer::factory()->create(['user_id' => $user->id]);
        $exchange = Exchange::factory()->create([
            'transfer_id' => $transfer->id,
            'converted_amount_syp' => 12500000.00,
            'exchange_rate_usd_to_syp' => 12500.00,
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson("/api/v1/transfers/{$transfer->id}");

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'id',
                    'recipient_name',
                    'exchange' => [
                        'id',
                        'transfer_id',
                        'converted_amount_syp',
                        'exchange_rate_usd_to_syp',
                    ],
                ],
            ])
            ->assertJson([
                'data' => [
                    'exchange' => [
                        'id' => $exchange->id,
                        'transfer_id' => $transfer->id,
                    ],
                ],
            ]);
    }

    public function test_transfer_list_includes_exchange_relationships(): void
    {
        $user = User::factory()->create();
        
        // Transfer with exchange
        $transferWithExchange = Transfer::factory()->create(['user_id' => $user->id]);
        Exchange::factory()->create(['transfer_id' => $transferWithExchange->id]);
        
        // Transfer without exchange
        Transfer::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/transfers');

        $response->assertStatus(200)
            ->assertJsonCount(2, 'data')
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'id',
                        'recipient_name',
                        'exchange',
                    ],
                ],
            ]);
    }

    public function test_transfer_without_exchange_returns_null_exchange(): void
    {
        $user = User::factory()->create();
        $transfer = Transfer::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson("/api/v1/transfers/{$transfer->id}");

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'id' => $transfer->id,
                    'exchange' => null,
                ],
            ]);
    }
}

<?php

namespace Tests\Feature;

use App\Models\FundBox;
use App\Models\Incoming;
use App\Models\Transfer;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FundBoxManagementTest extends TestCase
{
    use RefreshDatabase;

    // ========== FUND BOX RETRIEVAL TESTS ==========

    public function test_admin_can_retrieve_fund_box(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/fund-box');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonStructure([
                'success',
                'data' => [
                    'id',
                    'balance_usd',
                    'last_calculated_at',
                    'updated_at',
                ],
            ]);
    }

    public function test_fund_box_is_created_automatically_if_not_exists(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        // Ensure no fund box exists
        FundBox::query()->delete();

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/fund-box');

        $response->assertStatus(200);

        $this->assertDatabaseHas('fund_boxes', [
            'id' => 1,
            'balance_usd' => 0.00,
        ]);
    }

    public function test_regular_user_cannot_retrieve_fund_box(): void
    {
        $user = User::factory()->create(['role' => 'user']);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/fund-box');

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthorized. Admin access required.',
            ]);
    }

    public function test_unauthenticated_user_cannot_retrieve_fund_box(): void
    {
        $response = $this->getJson('/api/v1/fund-box');

        $response->assertStatus(401);
    }

    // ========== BALANCE UPDATE TESTS ==========

    public function test_admin_can_update_fund_box_balance(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin, 'sanctum')
            ->putJson('/api/v1/fund-box', [
                'balance_usd' => 5000.00,
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Fund box balance updated successfully.',
                'data' => [
                    'balance_usd' => '5000.00',
                ],
            ]);

        $this->assertDatabaseHas('fund_boxes', [
            'id' => 1,
            'balance_usd' => 5000.00,
        ]);
    }

    public function test_update_balance_validates_required_field(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin, 'sanctum')
            ->putJson('/api/v1/fund-box', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['balance_usd']);
    }

    public function test_update_balance_validates_numeric_value(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin, 'sanctum')
            ->putJson('/api/v1/fund-box', [
                'balance_usd' => 'not-a-number',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['balance_usd']);
    }

    public function test_update_balance_validates_non_negative_value(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin, 'sanctum')
            ->putJson('/api/v1/fund-box', [
                'balance_usd' => -100.00,
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['balance_usd']);
    }

    public function test_regular_user_cannot_update_fund_box_balance(): void
    {
        $user = User::factory()->create(['role' => 'user']);

        $response = $this->actingAs($user, 'sanctum')
            ->putJson('/api/v1/fund-box', [
                'balance_usd' => 5000.00,
            ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthorized. Admin access required.',
            ]);
    }

    public function test_unauthenticated_user_cannot_update_fund_box_balance(): void
    {
        $response = $this->putJson('/api/v1/fund-box', [
            'balance_usd' => 5000.00,
        ]);

        $response->assertStatus(401);
    }

    // ========== AUTOMATIC BALANCE ADJUSTMENT TESTS ==========

    public function test_fund_box_increases_when_incoming_is_created(): void
    {
        $user = User::factory()->create();
        $admin = User::factory()->create(['role' => 'admin']);

        // Get initial balance
        $initialResponse = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/fund-box');
        $initialBalance = (float) $initialResponse->json('data.balance_usd');

        // Create incoming
        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/incoming', [
                'description' => 'Test incoming',
                'amount_usd' => 1000.00,
                'incoming_date' => '2025-10-15',
            ]);

        // Check updated balance
        $updatedResponse = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/fund-box');
        $updatedBalance = (float) $updatedResponse->json('data.balance_usd');

        $this->assertEquals($initialBalance + 1000.00, $updatedBalance);
    }

    public function test_fund_box_decreases_when_transfer_is_created(): void
    {
        $user = User::factory()->create();
        $admin = User::factory()->create(['role' => 'admin']);

        // Set initial balance
        $this->actingAs($admin, 'sanctum')
            ->putJson('/api/v1/fund-box', [
                'balance_usd' => 5000.00,
            ]);

        // Create transfer
        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => 'John Doe',
                'amount_usd' => 500.00,
                'transfer_date' => '2025-10-15',
            ]);

        // Check updated balance
        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/fund-box');

        $this->assertEquals('4500.00', $response->json('data.balance_usd'));
    }

    public function test_fund_box_adjusts_when_incoming_is_updated(): void
    {
        $user = User::factory()->create();
        $admin = User::factory()->create(['role' => 'admin']);

        // Create incoming with initial amount
        $incoming = Incoming::factory()->create([
            'user_id' => $user->id,
            'amount_usd' => 1000.00,
        ]);

        // Get balance after creation
        $initialResponse = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/fund-box');
        $initialBalance = (float) $initialResponse->json('data.balance_usd');

        // Update incoming amount
        $this->actingAs($user, 'sanctum')
            ->putJson("/api/v1/incoming/{$incoming->id}", [
                'amount_usd' => 1500.00,
            ]);

        // Check updated balance (should increase by 500)
        $updatedResponse = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/fund-box');
        $updatedBalance = (float) $updatedResponse->json('data.balance_usd');

        $this->assertEquals($initialBalance + 500.00, $updatedBalance);
    }

    public function test_fund_box_adjusts_when_transfer_is_updated(): void
    {
        $user = User::factory()->create();
        $admin = User::factory()->create(['role' => 'admin']);

        // Set initial balance
        $this->actingAs($admin, 'sanctum')
            ->putJson('/api/v1/fund-box', [
                'balance_usd' => 5000.00,
            ]);

        // Create transfer
        $transfer = Transfer::factory()->create([
            'user_id' => $user->id,
            'amount_usd' => 500.00,
        ]);

        // Get balance after creation
        $initialResponse = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/fund-box');
        $initialBalance = (float) $initialResponse->json('data.balance_usd');

        // Update transfer amount (increase to 800)
        $this->actingAs($user, 'sanctum')
            ->putJson("/api/v1/transfers/{$transfer->id}", [
                'amount_usd' => 800.00,
            ]);

        // Check updated balance (should decrease by 300)
        $updatedResponse = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/fund-box');
        $updatedBalance = (float) $updatedResponse->json('data.balance_usd');

        $this->assertEquals($initialBalance - 300.00, $updatedBalance);
    }

    public function test_fund_box_increases_when_incoming_is_deleted(): void
    {
        $user = User::factory()->create();
        $admin = User::factory()->create(['role' => 'admin']);

        // Create incoming
        $incoming = Incoming::factory()->create([
            'user_id' => $user->id,
            'amount_usd' => 1000.00,
        ]);

        // Get balance after creation
        $initialResponse = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/fund-box');
        $initialBalance = (float) $initialResponse->json('data.balance_usd');

        // Delete incoming
        $this->actingAs($user, 'sanctum')
            ->deleteJson("/api/v1/incoming/{$incoming->id}");

        // Check updated balance (should decrease by 1000)
        $updatedResponse = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/fund-box');
        $updatedBalance = (float) $updatedResponse->json('data.balance_usd');

        $this->assertEquals($initialBalance - 1000.00, $updatedBalance);
    }

    public function test_fund_box_increases_when_transfer_is_deleted(): void
    {
        $user = User::factory()->create();
        $admin = User::factory()->create(['role' => 'admin']);

        // Set initial balance
        $this->actingAs($admin, 'sanctum')
            ->putJson('/api/v1/fund-box', [
                'balance_usd' => 5000.00,
            ]);

        // Create transfer
        $transfer = Transfer::factory()->create([
            'user_id' => $user->id,
            'amount_usd' => 500.00,
        ]);

        // Get balance after creation
        $initialResponse = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/fund-box');
        $initialBalance = (float) $initialResponse->json('data.balance_usd');

        // Delete transfer
        $this->actingAs($user, 'sanctum')
            ->deleteJson("/api/v1/transfers/{$transfer->id}");

        // Check updated balance (should increase by 500)
        $updatedResponse = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/fund-box');
        $updatedBalance = (float) $updatedResponse->json('data.balance_usd');

        $this->assertEquals($initialBalance + 500.00, $updatedBalance);
    }

    public function test_fund_box_balance_reflects_multiple_transactions(): void
    {
        $user = User::factory()->create();
        $admin = User::factory()->create(['role' => 'admin']);

        // Set initial balance to 0
        $this->actingAs($admin, 'sanctum')
            ->putJson('/api/v1/fund-box', [
                'balance_usd' => 0.00,
            ]);

        // Create multiple incoming transactions
        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/incoming', [
                'description' => 'Incoming 1',
                'amount_usd' => 1000.00,
                'incoming_date' => '2025-10-15',
            ]);

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/incoming', [
                'description' => 'Incoming 2',
                'amount_usd' => 2000.00,
                'incoming_date' => '2025-10-16',
            ]);

        // Create multiple transfers
        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => 'Recipient 1',
                'amount_usd' => 500.00,
                'transfer_date' => '2025-10-17',
            ]);

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => 'Recipient 2',
                'amount_usd' => 300.00,
                'transfer_date' => '2025-10-18',
            ]);

        // Check final balance: 0 + 1000 + 2000 - 500 - 300 = 2200
        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/fund-box');

        $this->assertEquals('2200.00', $response->json('data.balance_usd'));
    }
}

<?php

namespace Tests\Feature;

use App\Models\Expense;
use App\Models\Incoming;
use App\Models\Transfer;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminDashboardTest extends TestCase
{
    use RefreshDatabase;

    // ========== STATS ENDPOINT TESTS ==========

    public function test_admin_can_retrieve_overall_stats(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create(['role' => 'user']);

        // Create some test data
        Expense::factory()->count(3)->create(['user_id' => $user->id]);
        Transfer::factory()->count(2)->create(['user_id' => $user->id]);
        Incoming::factory()->count(1)->create(['user_id' => $user->id]);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/stats');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonStructure([
                'success',
                'data' => [
                    'user_count',
                    'expense_count',
                    'transfer_count',
                    'incoming_count',
                    'fund_box_balance',
                    'fund_box_last_calculated_at',
                ],
            ]);

        $this->assertEquals(2, $response->json('data.user_count'));
        $this->assertEquals(3, $response->json('data.expense_count'));
        $this->assertEquals(2, $response->json('data.transfer_count'));
        $this->assertEquals(1, $response->json('data.incoming_count'));
    }

    public function test_regular_user_cannot_access_stats(): void
    {
        $user = User::factory()->create(['role' => 'user']);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/stats');

        $response->assertStatus(403);
    }

    // ========== USER ACTIVITY TESTS ==========

    public function test_admin_can_retrieve_user_activity_list(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user1 = User::factory()->create(['role' => 'user']);
        $user2 = User::factory()->create(['role' => 'user']);

        // Create transactions for users
        Expense::factory()->count(2)->create(['user_id' => $user1->id]);
        Transfer::factory()->count(1)->create(['user_id' => $user1->id]);
        Incoming::factory()->count(3)->create(['user_id' => $user2->id]);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/users');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonStructure([
                'success',
                'data' => [
                    '*' => [
                        'id',
                        'name',
                        'email',
                        'role',
                        'expense_count',
                        'transfer_count',
                        'incoming_count',
                        'last_activity_at',
                        'created_at',
                    ],
                ],
            ]);

        $this->assertCount(3, $response->json('data'));
    }

    public function test_regular_user_cannot_access_user_activity(): void
    {
        $user = User::factory()->create(['role' => 'user']);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/users');

        $response->assertStatus(403);
    }

    // ========== EXPENSE SUMMARIES TESTS ==========

    public function test_admin_can_retrieve_expense_summaries(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user1 = User::factory()->create(['role' => 'user']);
        $user2 = User::factory()->create(['role' => 'user']);

        // Create expenses with different currencies
        Expense::factory()->create([
            'user_id' => $user1->id,
            'price_usd' => 100.00,
            'price_syp' => 50000.00,
            'price_try' => 300.00,
        ]);
        Expense::factory()->create([
            'user_id' => $user2->id,
            'price_usd' => 200.00,
            'price_syp' => 100000.00,
            'price_try' => 600.00,
        ]);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/expenses');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonStructure([
                'success',
                'data' => [
                    'by_currency' => [
                        'total_usd',
                        'total_syp',
                        'total_try',
                    ],
                    'by_user' => [
                        '*' => [
                            'user_id',
                            'user_name',
                            'user_email',
                            'total_usd',
                            'total_syp',
                            'total_try',
                            'expense_count',
                        ],
                    ],
                ],
            ]);

        $this->assertEquals(300.00, $response->json('data.by_currency.total_usd'));
        $this->assertEquals(150000.00, $response->json('data.by_currency.total_syp'));
        $this->assertEquals(900.00, $response->json('data.by_currency.total_try'));
    }

    public function test_admin_can_filter_expense_summaries_by_date_range(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create(['role' => 'user']);

        // Create expenses with different dates
        Expense::factory()->create([
            'user_id' => $user->id,
            'price_usd' => 100.00,
            'expense_date' => '2025-01-01',
        ]);
        Expense::factory()->create([
            'user_id' => $user->id,
            'price_usd' => 200.00,
            'expense_date' => '2025-02-01',
        ]);
        Expense::factory()->create([
            'user_id' => $user->id,
            'price_usd' => 300.00,
            'expense_date' => '2025-03-01',
        ]);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/expenses?start_date=2025-01-15&end_date=2025-02-15');

        $response->assertStatus(200);
        $this->assertEquals(200.00, $response->json('data.by_currency.total_usd'));
    }

    public function test_regular_user_cannot_access_expense_summaries(): void
    {
        $user = User::factory()->create(['role' => 'user']);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/expenses');

        $response->assertStatus(403);
    }

    // ========== ANALYTICS TESTS ==========

    public function test_admin_can_retrieve_analytics_with_date_range(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create(['role' => 'user']);

        // Create test data
        Expense::factory()->create([
            'user_id' => $user->id,
            'price_usd' => 100.00,
            'expense_date' => '2025-01-15',
        ]);
        Transfer::factory()->create([
            'user_id' => $user->id,
            'amount_usd' => 50.00,
            'transfer_date' => '2025-01-20',
        ]);
        Incoming::factory()->create([
            'user_id' => $user->id,
            'amount_usd' => 200.00,
            'incoming_date' => '2025-01-25',
        ]);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/analytics?start_date=2025-01-01&end_date=2025-01-31');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonStructure([
                'success',
                'data' => [
                    'date_range' => [
                        'start_date',
                        'end_date',
                    ],
                    'expenses' => [
                        'count',
                        'total_usd',
                        'total_syp',
                        'total_try',
                        'with_invoice_count',
                    ],
                    'transfers' => [
                        'count',
                        'total_usd',
                    ],
                    'incoming' => [
                        'count',
                        'total_usd',
                    ],
                    'summary' => [
                        'total_expenses_usd',
                        'total_transfers_usd',
                        'total_incoming_usd',
                        'net_flow_usd',
                    ],
                ],
            ]);

        $this->assertEquals(1, $response->json('data.expenses.count'));
        $this->assertEquals(1, $response->json('data.transfers.count'));
        $this->assertEquals(1, $response->json('data.incoming.count'));
        $this->assertEquals(50.00, $response->json('data.summary.net_flow_usd'));
    }

    public function test_analytics_requires_start_date(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/analytics?end_date=2025-01-31');

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['start_date']);
    }

    public function test_analytics_requires_end_date(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/analytics?start_date=2025-01-01');

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['end_date']);
    }

    public function test_analytics_end_date_must_be_after_or_equal_start_date(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/analytics?start_date=2025-01-31&end_date=2025-01-01');

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['end_date']);
    }

    public function test_regular_user_cannot_access_analytics(): void
    {
        $user = User::factory()->create(['role' => 'user']);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/analytics?start_date=2025-01-01&end_date=2025-01-31');

        $response->assertStatus(403);
    }

    public function test_unauthenticated_user_cannot_access_admin_dashboard(): void
    {
        $response = $this->getJson('/api/v1/admin/dashboard/stats');
        $response->assertStatus(401);

        $response = $this->getJson('/api/v1/admin/dashboard/users');
        $response->assertStatus(401);

        $response = $this->getJson('/api/v1/admin/dashboard/expenses');
        $response->assertStatus(401);

        $response = $this->getJson('/api/v1/admin/dashboard/analytics?start_date=2025-01-01&end_date=2025-01-31');
        $response->assertStatus(401);
    }
}

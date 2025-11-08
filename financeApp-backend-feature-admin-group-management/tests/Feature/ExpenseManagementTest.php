<?php

namespace Tests\Feature;

use App\Models\Expense;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ExpenseManagementTest extends TestCase
{
    use RefreshDatabase;

    // ========== CREATE TESTS ==========

    public function test_user_can_create_expense_with_usd_only(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/expenses', [
                'description' => 'Office supplies',
                'price_usd' => 150.50,
                'expense_date' => '2025-10-20',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Expense created successfully',
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'id',
                    'user_id',
                    'description',
                    'price_usd',
                    'expense_date',
                    'created_at',
                    'updated_at',
                ],
            ]);

        $this->assertDatabaseHas('expenses', [
            'user_id' => $user->id,
            'description' => 'Office supplies',
            'price_usd' => 150.50,
        ]);
    }

    public function test_user_can_create_expense_with_multiple_currencies(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/expenses', [
                'description' => 'International purchase',
                'price_usd' => 100.00,
                'price_syp' => 250000.00,
                'price_try' => 3500.00,
                'expense_date' => '2025-10-20',
            ]);

        $response->assertStatus(201);

        $this->assertDatabaseHas('expenses', [
            'user_id' => $user->id,
            'description' => 'International purchase',
            'price_usd' => 100.00,
            'price_syp' => 250000.00,
            'price_try' => 3500.00,
        ]);
    }

    public function test_create_expense_validates_required_fields(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/expenses', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['description', 'price_usd', 'expense_date']);
    }

    public function test_create_expense_validates_usd_price_is_numeric(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/expenses', [
                'description' => 'Test expense',
                'price_usd' => 'not-a-number',
                'expense_date' => '2025-10-20',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['price_usd']);
    }

    public function test_create_expense_validates_usd_price_is_non_negative(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/expenses', [
                'description' => 'Test expense',
                'price_usd' => -50.00,
                'expense_date' => '2025-10-20',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['price_usd']);
    }

    public function test_create_expense_validates_expense_date_not_in_future(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/expenses', [
                'description' => 'Future expense',
                'price_usd' => 100.00,
                'expense_date' => '2026-12-31',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['expense_date']);
    }

    public function test_unauthenticated_user_cannot_create_expense(): void
    {
        $response = $this->postJson('/api/v1/expenses', [
            'description' => 'Test expense',
            'price_usd' => 100.00,
            'expense_date' => '2025-10-20',
        ]);

        $response->assertStatus(401);
    }

    // ========== READ TESTS ==========

    public function test_user_can_list_their_own_expenses(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();

        Expense::factory()->count(3)->create(['user_id' => $user->id]);
        Expense::factory()->count(2)->create(['user_id' => $otherUser->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/expenses');

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
                        'price_usd',
                        'expense_date',
                    ],
                ],
                'meta' => [
                    'current_page',
                    'last_page',
                    'per_page',
                    'total',
                ],
            ]);

        // Verify user only sees their own expenses
        $responseData = $response->json('data');
        foreach ($responseData as $expense) {
            $this->assertEquals($user->id, $expense['user_id']);
        }
    }

    public function test_admin_can_list_all_expenses(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        Expense::factory()->count(2)->create(['user_id' => $user1->id]);
        Expense::factory()->count(3)->create(['user_id' => $user2->id]);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/expenses');

        $response->assertStatus(200)
            ->assertJsonCount(5, 'data');
    }

    public function test_user_can_view_their_own_expense(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson("/api/v1/expenses/{$expense->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $expense->id,
                    'user_id' => $user->id,
                    'description' => $expense->description,
                ],
            ]);
    }

    public function test_user_cannot_view_other_users_expense(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $otherUser->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson("/api/v1/expenses/{$expense->id}");

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthorized to view this expense',
            ]);
    }

    public function test_admin_can_view_any_expense(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson("/api/v1/expenses/{$expense->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $expense->id,
                ],
            ]);
    }

    // ========== UPDATE TESTS ==========

    public function test_user_can_update_their_own_expense(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'description' => 'Original description',
            'price_usd' => 100.00,
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->putJson("/api/v1/expenses/{$expense->id}", [
                'description' => 'Updated description',
                'price_usd' => 150.00,
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Expense updated successfully',
                'data' => [
                    'id' => $expense->id,
                    'description' => 'Updated description',
                    'price_usd' => '150.00',
                ],
            ]);

        $this->assertDatabaseHas('expenses', [
            'id' => $expense->id,
            'description' => 'Updated description',
            'price_usd' => 150.00,
        ]);
    }

    public function test_user_can_update_multi_currency_prices(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'price_usd' => 100.00,
            'price_syp' => null,
            'price_try' => null,
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->putJson("/api/v1/expenses/{$expense->id}", [
                'price_syp' => 250000.00,
                'price_try' => 3500.00,
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('expenses', [
            'id' => $expense->id,
            'price_syp' => 250000.00,
            'price_try' => 3500.00,
        ]);
    }

    public function test_user_cannot_update_other_users_expense(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $otherUser->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->putJson("/api/v1/expenses/{$expense->id}", [
                'description' => 'Hacked description',
            ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthorized to update this expense',
            ]);
    }

    public function test_admin_can_update_any_expense(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'description' => 'Original',
        ]);

        $response = $this->actingAs($admin, 'sanctum')
            ->putJson("/api/v1/expenses/{$expense->id}", [
                'description' => 'Admin updated',
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('expenses', [
            'id' => $expense->id,
            'description' => 'Admin updated',
        ]);
    }

    public function test_update_expense_updates_timestamp(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        $originalUpdatedAt = $expense->updated_at;

        // Wait a moment to ensure timestamp difference
        sleep(1);

        $response = $this->actingAs($user, 'sanctum')
            ->putJson("/api/v1/expenses/{$expense->id}", [
                'description' => 'Updated',
            ]);

        $response->assertStatus(200);

        $expense->refresh();
        $this->assertNotEquals($originalUpdatedAt, $expense->updated_at);
    }

    // ========== DELETE TESTS ==========

    public function test_user_can_delete_their_own_expense(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->deleteJson("/api/v1/expenses/{$expense->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Expense deleted successfully',
            ]);

        // Verify soft delete
        $this->assertSoftDeleted('expenses', [
            'id' => $expense->id,
        ]);
    }

    public function test_user_cannot_delete_other_users_expense(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $otherUser->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->deleteJson("/api/v1/expenses/{$expense->id}");

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthorized to delete this expense',
            ]);

        // Verify expense was not deleted
        $this->assertDatabaseHas('expenses', [
            'id' => $expense->id,
            'deleted_at' => null,
        ]);
    }

    public function test_admin_can_delete_any_expense(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($admin, 'sanctum')
            ->deleteJson("/api/v1/expenses/{$expense->id}");

        $response->assertStatus(200);

        $this->assertSoftDeleted('expenses', [
            'id' => $expense->id,
        ]);
    }

    public function test_delete_expense_removes_invoice_file(): void
    {
        Storage::fake('local');

        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'has_invoice' => true,
            'invoice_path' => 'invoices/test-invoice.jpg',
        ]);

        // Create a fake file
        Storage::put('invoices/test-invoice.jpg', 'fake content');
        Storage::assertExists('invoices/test-invoice.jpg');

        $response = $this->actingAs($user, 'sanctum')
            ->deleteJson("/api/v1/expenses/{$expense->id}");

        $response->assertStatus(200);

        // Verify file was deleted
        Storage::assertMissing('invoices/test-invoice.jpg');
    }

    public function test_soft_deleted_expenses_not_shown_in_list(): void
    {
        $user = User::factory()->create();
        $expense1 = Expense::factory()->create(['user_id' => $user->id]);
        $expense2 = Expense::factory()->create(['user_id' => $user->id]);

        // Delete one expense
        $expense1->delete();

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/expenses');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data');

        $responseData = $response->json('data');
        $this->assertEquals($expense2->id, $responseData[0]['id']);
    }

    // ========== MULTI-CURRENCY VALIDATION TESTS ==========

    public function test_expense_accepts_null_optional_currencies(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/expenses', [
                'description' => 'USD only expense',
                'price_usd' => 100.00,
                'price_syp' => null,
                'price_try' => null,
                'expense_date' => '2025-10-20',
            ]);

        $response->assertStatus(201);

        $this->assertDatabaseHas('expenses', [
            'user_id' => $user->id,
            'price_usd' => 100.00,
            'price_syp' => null,
            'price_try' => null,
        ]);
    }

    public function test_expense_validates_syp_currency_format(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/expenses', [
                'description' => 'Test',
                'price_usd' => 100.00,
                'price_syp' => 'invalid',
                'expense_date' => '2025-10-20',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['price_syp']);
    }

    public function test_expense_validates_try_currency_format(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/expenses', [
                'description' => 'Test',
                'price_usd' => 100.00,
                'price_try' => 'invalid',
                'expense_date' => '2025-10-20',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['price_try']);
    }

    public function test_expense_validates_negative_syp_price(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/expenses', [
                'description' => 'Test',
                'price_usd' => 100.00,
                'price_syp' => -1000.00,
                'expense_date' => '2025-10-20',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['price_syp']);
    }

    public function test_expense_validates_negative_try_price(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/expenses', [
                'description' => 'Test',
                'price_usd' => 100.00,
                'price_try' => -500.00,
                'expense_date' => '2025-10-20',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['price_try']);
    }

    // ========== AUTHORIZATION TESTS ==========

    public function test_regular_user_cannot_see_other_users_expenses_in_list(): void
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        Expense::factory()->count(3)->create(['user_id' => $user1->id]);
        Expense::factory()->count(2)->create(['user_id' => $user2->id]);

        $response = $this->actingAs($user1, 'sanctum')
            ->getJson('/api/v1/expenses');

        $response->assertStatus(200)
            ->assertJsonCount(3, 'data');

        // Verify all returned expenses belong to user1
        $responseData = $response->json('data');
        foreach ($responseData as $expense) {
            $this->assertEquals($user1->id, $expense['user_id']);
        }
    }

    public function test_admin_sees_all_users_expenses_in_list(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        Expense::factory()->count(2)->create(['user_id' => $user1->id]);
        Expense::factory()->count(3)->create(['user_id' => $user2->id]);
        Expense::factory()->count(1)->create(['user_id' => $admin->id]);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/expenses');

        $response->assertStatus(200)
            ->assertJsonCount(6, 'data');
    }

    public function test_unauthenticated_user_cannot_list_expenses(): void
    {
        $response = $this->getJson('/api/v1/expenses');

        $response->assertStatus(401);
    }

    public function test_unauthenticated_user_cannot_view_expense(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        $response = $this->getJson("/api/v1/expenses/{$expense->id}");

        $response->assertStatus(401);
    }

    public function test_unauthenticated_user_cannot_update_expense(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        $response = $this->putJson("/api/v1/expenses/{$expense->id}", [
            'description' => 'Updated',
        ]);

        $response->assertStatus(401);
    }

    public function test_unauthenticated_user_cannot_delete_expense(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        $response = $this->deleteJson("/api/v1/expenses/{$expense->id}");

        $response->assertStatus(401);
    }
}

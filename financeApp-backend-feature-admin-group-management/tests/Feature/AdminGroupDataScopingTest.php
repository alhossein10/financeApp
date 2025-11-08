<?php

namespace Tests\Feature;

use App\Models\AdminGroup;
use App\Models\Expense;
use App\Models\FundBox;
use App\Models\Incoming;
use App\Models\Transfer;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminGroupDataScopingTest extends TestCase
{
    use RefreshDatabase;

    // ========== ADMIN SEES ONLY GROUP MEMBER EXPENSES ==========

    public function test_admin_sees_only_group_member_expenses(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
        ]);

        // Create group members
        $member1 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => $adminGroup->id,
        ]);
        $member2 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => $adminGroup->id,
        ]);

        // Create user outside the group
        $outsideUser = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Other Organization',
        ]);

        // Create expenses
        $expense1 = Expense::factory()->create(['user_id' => $member1->id]);
        $expense2 = Expense::factory()->create(['user_id' => $member2->id]);
        $expenseOutside = Expense::factory()->create(['user_id' => $outsideUser->id]);

        // Admin requests expenses
        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/expenses');

        $response->assertStatus(200)
            ->assertJsonCount(2, 'data');

        // Verify only group member expenses are returned
        $expenseIds = collect($response->json('data'))->pluck('id')->toArray();
        $this->assertContains($expense1->id, $expenseIds);
        $this->assertContains($expense2->id, $expenseIds);
        $this->assertNotContains($expenseOutside->id, $expenseIds);
    }

    // ========== ADMIN SEES ONLY GROUP MEMBER TRANSFERS ==========

    public function test_admin_sees_only_group_member_transfers(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
        ]);

        // Create group members
        $member1 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => $adminGroup->id,
        ]);
        $member2 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => $adminGroup->id,
        ]);

        // Create user outside the group
        $outsideUser = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Other Organization',
        ]);

        // Create transfers
        $transfer1 = Transfer::factory()->create(['user_id' => $member1->id]);
        $transfer2 = Transfer::factory()->create(['user_id' => $member2->id]);
        $transferOutside = Transfer::factory()->create(['user_id' => $outsideUser->id]);

        // Admin requests transfers
        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/transfers');

        $response->assertStatus(200)
            ->assertJsonCount(2, 'data');

        // Verify only group member transfers are returned
        $transferIds = collect($response->json('data'))->pluck('id')->toArray();
        $this->assertContains($transfer1->id, $transferIds);
        $this->assertContains($transfer2->id, $transferIds);
        $this->assertNotContains($transferOutside->id, $transferIds);
    }

    // ========== ADMIN SEES ONLY GROUP MEMBER INCOMING TRANSACTIONS ==========

    public function test_admin_sees_only_group_member_incoming_transactions(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
        ]);

        // Create group members
        $member1 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => $adminGroup->id,
        ]);
        $member2 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => $adminGroup->id,
        ]);

        // Create user outside the group
        $outsideUser = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Other Organization',
        ]);

        // Create incoming transactions
        $incoming1 = Incoming::factory()->create(['user_id' => $member1->id]);
        $incoming2 = Incoming::factory()->create(['user_id' => $member2->id]);
        $incomingOutside = Incoming::factory()->create(['user_id' => $outsideUser->id]);

        // Admin requests incoming transactions
        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/incoming');

        $response->assertStatus(200)
            ->assertJsonCount(2, 'data');

        // Verify only group member incoming transactions are returned
        $incomingIds = collect($response->json('data'))->pluck('id')->toArray();
        $this->assertContains($incoming1->id, $incomingIds);
        $this->assertContains($incoming2->id, $incomingIds);
        $this->assertNotContains($incomingOutside->id, $incomingIds);
    }

    // ========== REGULAR USER SEES ONLY OWN EXPENSES ==========

    public function test_regular_user_sees_only_own_expenses(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
        ]);

        // Create group members
        $user1 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => $adminGroup->id,
        ]);
        $user2 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => $adminGroup->id,
        ]);

        // Create expenses
        $expense1 = Expense::factory()->create(['user_id' => $user1->id]);
        $expense2 = Expense::factory()->create(['user_id' => $user1->id]);
        $expenseOther = Expense::factory()->create(['user_id' => $user2->id]);

        // User1 requests expenses
        $response = $this->actingAs($user1, 'sanctum')
            ->getJson('/api/v1/expenses');

        $response->assertStatus(200)
            ->assertJsonCount(2, 'data');

        // Verify only user1's expenses are returned
        $expenseIds = collect($response->json('data'))->pluck('id')->toArray();
        $this->assertContains($expense1->id, $expenseIds);
        $this->assertContains($expense2->id, $expenseIds);
        $this->assertNotContains($expenseOther->id, $expenseIds);

        // Verify all returned expenses belong to user1
        $responseData = $response->json('data');
        foreach ($responseData as $expense) {
            $this->assertEquals($user1->id, $expense['user_id']);
        }
    }

    // ========== REGULAR USER SEES ONLY OWN TRANSFERS ==========

    public function test_regular_user_sees_only_own_transfers(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
        ]);

        // Create group members
        $user1 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => $adminGroup->id,
        ]);
        $user2 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => $adminGroup->id,
        ]);

        // Create transfers
        $transfer1 = Transfer::factory()->create(['user_id' => $user1->id]);
        $transfer2 = Transfer::factory()->create(['user_id' => $user1->id]);
        $transferOther = Transfer::factory()->create(['user_id' => $user2->id]);

        // User1 requests transfers
        $response = $this->actingAs($user1, 'sanctum')
            ->getJson('/api/v1/transfers');

        $response->assertStatus(200)
            ->assertJsonCount(2, 'data');

        // Verify only user1's transfers are returned
        $transferIds = collect($response->json('data'))->pluck('id')->toArray();
        $this->assertContains($transfer1->id, $transferIds);
        $this->assertContains($transfer2->id, $transferIds);
        $this->assertNotContains($transferOther->id, $transferIds);

        // Verify all returned transfers belong to user1
        $responseData = $response->json('data');
        foreach ($responseData as $transfer) {
            $this->assertEquals($user1->id, $transfer['user_id']);
        }
    }

    // ========== REGULAR USER SEES ONLY OWN INCOMING TRANSACTIONS ==========

    public function test_regular_user_sees_only_own_incoming_transactions(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
        ]);

        // Create group members
        $user1 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => $adminGroup->id,
        ]);
        $user2 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => $adminGroup->id,
        ]);

        // Create incoming transactions
        $incoming1 = Incoming::factory()->create(['user_id' => $user1->id]);
        $incoming2 = Incoming::factory()->create(['user_id' => $user1->id]);
        $incomingOther = Incoming::factory()->create(['user_id' => $user2->id]);

        // User1 requests incoming transactions
        $response = $this->actingAs($user1, 'sanctum')
            ->getJson('/api/v1/incoming');

        $response->assertStatus(200)
            ->assertJsonCount(2, 'data');

        // Verify only user1's incoming transactions are returned
        $incomingIds = collect($response->json('data'))->pluck('id')->toArray();
        $this->assertContains($incoming1->id, $incomingIds);
        $this->assertContains($incoming2->id, $incomingIds);
        $this->assertNotContains($incomingOther->id, $incomingIds);

        // Verify all returned incoming transactions belong to user1
        $responseData = $response->json('data');
        foreach ($responseData as $incoming) {
            $this->assertEquals($user1->id, $incoming['user_id']);
        }
    }

    // ========== CROSS-GROUP DATA ISOLATION ==========

    public function test_admin_a_cannot_see_admin_b_group_expenses(): void
    {
        // Create Admin A with group
        $adminA = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Organization A',
        ]);
        $adminGroupA = AdminGroup::factory()->create([
            'admin_user_id' => $adminA->id,
        ]);

        // Create Admin B with group
        $adminB = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Organization B',
        ]);
        $adminGroupB = AdminGroup::factory()->create([
            'admin_user_id' => $adminB->id,
        ]);

        // Create members for Admin A's group
        $memberA1 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Organization A',
            'admin_group_id' => $adminGroupA->id,
        ]);
        $memberA2 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Organization A',
            'admin_group_id' => $adminGroupA->id,
        ]);

        // Create members for Admin B's group
        $memberB1 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Organization B',
            'admin_group_id' => $adminGroupB->id,
        ]);
        $memberB2 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Organization B',
            'admin_group_id' => $adminGroupB->id,
        ]);

        // Create expenses for both groups
        $expenseA1 = Expense::factory()->create(['user_id' => $memberA1->id]);
        $expenseA2 = Expense::factory()->create(['user_id' => $memberA2->id]);
        $expenseB1 = Expense::factory()->create(['user_id' => $memberB1->id]);
        $expenseB2 = Expense::factory()->create(['user_id' => $memberB2->id]);

        // Admin A requests expenses
        $responseA = $this->actingAs($adminA, 'sanctum')
            ->getJson('/api/v1/expenses');

        $responseA->assertStatus(200)
            ->assertJsonCount(2, 'data');

        // Verify Admin A only sees their group's expenses
        $expenseIdsA = collect($responseA->json('data'))->pluck('id')->toArray();
        $this->assertContains($expenseA1->id, $expenseIdsA);
        $this->assertContains($expenseA2->id, $expenseIdsA);
        $this->assertNotContains($expenseB1->id, $expenseIdsA);
        $this->assertNotContains($expenseB2->id, $expenseIdsA);

        // Admin B requests expenses
        $responseB = $this->actingAs($adminB, 'sanctum')
            ->getJson('/api/v1/expenses');

        $responseB->assertStatus(200)
            ->assertJsonCount(2, 'data');

        // Verify Admin B only sees their group's expenses
        $expenseIdsB = collect($responseB->json('data'))->pluck('id')->toArray();
        $this->assertContains($expenseB1->id, $expenseIdsB);
        $this->assertContains($expenseB2->id, $expenseIdsB);
        $this->assertNotContains($expenseA1->id, $expenseIdsB);
        $this->assertNotContains($expenseA2->id, $expenseIdsB);
    }

    public function test_admin_a_cannot_see_admin_b_group_transfers(): void
    {
        // Create Admin A with group
        $adminA = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Organization A',
        ]);
        $adminGroupA = AdminGroup::factory()->create([
            'admin_user_id' => $adminA->id,
        ]);

        // Create Admin B with group
        $adminB = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Organization B',
        ]);
        $adminGroupB = AdminGroup::factory()->create([
            'admin_user_id' => $adminB->id,
        ]);

        // Create members for Admin A's group
        $memberA = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Organization A',
            'admin_group_id' => $adminGroupA->id,
        ]);

        // Create members for Admin B's group
        $memberB = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Organization B',
            'admin_group_id' => $adminGroupB->id,
        ]);

        // Create transfers for both groups
        $transferA = Transfer::factory()->create(['user_id' => $memberA->id]);
        $transferB = Transfer::factory()->create(['user_id' => $memberB->id]);

        // Admin A requests transfers
        $responseA = $this->actingAs($adminA, 'sanctum')
            ->getJson('/api/v1/transfers');

        $responseA->assertStatus(200)
            ->assertJsonCount(1, 'data');

        // Verify Admin A only sees their group's transfers
        $transferIdsA = collect($responseA->json('data'))->pluck('id')->toArray();
        $this->assertContains($transferA->id, $transferIdsA);
        $this->assertNotContains($transferB->id, $transferIdsA);

        // Admin B requests transfers
        $responseB = $this->actingAs($adminB, 'sanctum')
            ->getJson('/api/v1/transfers');

        $responseB->assertStatus(200)
            ->assertJsonCount(1, 'data');

        // Verify Admin B only sees their group's transfers
        $transferIdsB = collect($responseB->json('data'))->pluck('id')->toArray();
        $this->assertContains($transferB->id, $transferIdsB);
        $this->assertNotContains($transferA->id, $transferIdsB);
    }

    public function test_admin_a_cannot_see_admin_b_group_incoming_transactions(): void
    {
        // Create Admin A with group
        $adminA = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Organization A',
        ]);
        $adminGroupA = AdminGroup::factory()->create([
            'admin_user_id' => $adminA->id,
        ]);

        // Create Admin B with group
        $adminB = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Organization B',
        ]);
        $adminGroupB = AdminGroup::factory()->create([
            'admin_user_id' => $adminB->id,
        ]);

        // Create members for Admin A's group
        $memberA = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Organization A',
            'admin_group_id' => $adminGroupA->id,
        ]);

        // Create members for Admin B's group
        $memberB = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Organization B',
            'admin_group_id' => $adminGroupB->id,
        ]);

        // Create incoming transactions for both groups
        $incomingA = Incoming::factory()->create(['user_id' => $memberA->id]);
        $incomingB = Incoming::factory()->create(['user_id' => $memberB->id]);

        // Admin A requests incoming transactions
        $responseA = $this->actingAs($adminA, 'sanctum')
            ->getJson('/api/v1/incoming');

        $responseA->assertStatus(200)
            ->assertJsonCount(1, 'data');

        // Verify Admin A only sees their group's incoming transactions
        $incomingIdsA = collect($responseA->json('data'))->pluck('id')->toArray();
        $this->assertContains($incomingA->id, $incomingIdsA);
        $this->assertNotContains($incomingB->id, $incomingIdsA);

        // Admin B requests incoming transactions
        $responseB = $this->actingAs($adminB, 'sanctum')
            ->getJson('/api/v1/incoming');

        $responseB->assertStatus(200)
            ->assertJsonCount(1, 'data');

        // Verify Admin B only sees their group's incoming transactions
        $incomingIdsB = collect($responseB->json('data'))->pluck('id')->toArray();
        $this->assertContains($incomingB->id, $incomingIdsB);
        $this->assertNotContains($incomingA->id, $incomingIdsB);
    }

    public function test_cross_group_isolation_in_same_organization(): void
    {
        // Create two admins in the SAME organization with separate groups
        $adminA = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Same Organization',
        ]);
        $adminGroupA = AdminGroup::factory()->create([
            'admin_user_id' => $adminA->id,
        ]);

        $adminB = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Same Organization',
        ]);
        $adminGroupB = AdminGroup::factory()->create([
            'admin_user_id' => $adminB->id,
        ]);

        // Create members for each group
        $memberA = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Same Organization',
            'admin_group_id' => $adminGroupA->id,
        ]);

        $memberB = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Same Organization',
            'admin_group_id' => $adminGroupB->id,
        ]);

        // Create data for both groups
        $expenseA = Expense::factory()->create(['user_id' => $memberA->id]);
        $expenseB = Expense::factory()->create(['user_id' => $memberB->id]);

        $transferA = Transfer::factory()->create(['user_id' => $memberA->id]);
        $transferB = Transfer::factory()->create(['user_id' => $memberB->id]);

        $incomingA = Incoming::factory()->create(['user_id' => $memberA->id]);
        $incomingB = Incoming::factory()->create(['user_id' => $memberB->id]);

        // Admin A should only see their group's data
        $expensesA = $this->actingAs($adminA, 'sanctum')
            ->getJson('/api/v1/expenses');
        $expensesA->assertStatus(200)->assertJsonCount(1, 'data');
        $this->assertEquals($expenseA->id, $expensesA->json('data.0.id'));

        $transfersA = $this->actingAs($adminA, 'sanctum')
            ->getJson('/api/v1/transfers');
        $transfersA->assertStatus(200)->assertJsonCount(1, 'data');
        $this->assertEquals($transferA->id, $transfersA->json('data.0.id'));

        $incomingsA = $this->actingAs($adminA, 'sanctum')
            ->getJson('/api/v1/incoming');
        $incomingsA->assertStatus(200)->assertJsonCount(1, 'data');
        $this->assertEquals($incomingA->id, $incomingsA->json('data.0.id'));

        // Admin B should only see their group's data
        $expensesB = $this->actingAs($adminB, 'sanctum')
            ->getJson('/api/v1/expenses');
        $expensesB->assertStatus(200)->assertJsonCount(1, 'data');
        $this->assertEquals($expenseB->id, $expensesB->json('data.0.id'));

        $transfersB = $this->actingAs($adminB, 'sanctum')
            ->getJson('/api/v1/transfers');
        $transfersB->assertStatus(200)->assertJsonCount(1, 'data');
        $this->assertEquals($transferB->id, $transfersB->json('data.0.id'));

        $incomingsB = $this->actingAs($adminB, 'sanctum')
            ->getJson('/api/v1/incoming');
        $incomingsB->assertStatus(200)->assertJsonCount(1, 'data');
        $this->assertEquals($incomingB->id, $incomingsB->json('data.0.id'));
    }
}

<?php

namespace Tests\Feature;

use App\Models\AdminGroup;
use App\Models\Expense;
use App\Models\Incoming;
use App\Models\Transfer;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Feature tests for multi-admin scenarios
 * 
 * Tests Requirements: 9.1, 9.2, 9.3, 9.4, 9.5
 * - Multiple admins in same organization with separate groups
 * - Data isolation between different admin groups
 * - Users can only join one group at a time
 * - Group code uniqueness across all admins
 */
class AdminGroupMultiAdminScenariosTest extends TestCase
{
    use RefreshDatabase;

    // ========== REQUIREMENT 9.1: Multiple admins in same organization ==========

    public function test_multiple_admins_can_exist_in_same_organization(): void
    {
        // Create three admins in the same organization
        $admin1 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Acme Corporation',
            'department_name' => 'IT',
        ]);
        $admin2 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Acme Corporation',
            'department_name' => 'Finance',
        ]);
        $admin3 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Acme Corporation',
            'department_name' => 'HR',
        ]);

        // Create groups for each admin
        $group1 = AdminGroup::factory()->create(['admin_user_id' => $admin1->id]);
        $group2 = AdminGroup::factory()->create(['admin_user_id' => $admin2->id]);
        $group3 = AdminGroup::factory()->create(['admin_user_id' => $admin3->id]);

        // Verify all admins have the same organization
        $this->assertEquals('Acme Corporation', $admin1->organization_name);
        $this->assertEquals('Acme Corporation', $admin2->organization_name);
        $this->assertEquals('Acme Corporation', $admin3->organization_name);

        // Verify each admin has their own group
        $this->assertNotNull($group1);
        $this->assertNotNull($group2);
        $this->assertNotNull($group3);

        // Verify groups are different
        $this->assertNotEquals($group1->id, $group2->id);
        $this->assertNotEquals($group1->id, $group3->id);
        $this->assertNotEquals($group2->id, $group3->id);
    }

    public function test_admins_in_same_organization_have_separate_member_lists(): void
    {
        // Create two admins in same organization
        $admin1 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Tech Company',
        ]);
        $group1 = AdminGroup::factory()->create(['admin_user_id' => $admin1->id]);

        $admin2 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Tech Company',
        ]);
        $group2 = AdminGroup::factory()->create(['admin_user_id' => $admin2->id]);

        // Create members for admin1's group
        $member1A = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Tech Company',
            'admin_group_id' => $group1->id,
        ]);
        $member1B = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Tech Company',
            'admin_group_id' => $group1->id,
        ]);

        // Create members for admin2's group
        $member2A = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Tech Company',
            'admin_group_id' => $group2->id,
        ]);

        // Admin1 gets their members
        $response1 = $this->actingAs($admin1, 'sanctum')
            ->getJson('/api/v1/admin/group/members');

        $response1->assertStatus(200)->assertJsonCount(2, 'data');
        $memberIds1 = collect($response1->json('data'))->pluck('id')->toArray();
        $this->assertContains($member1A->id, $memberIds1);
        $this->assertContains($member1B->id, $memberIds1);
        $this->assertNotContains($member2A->id, $memberIds1);

        // Admin2 gets their members
        $response2 = $this->actingAs($admin2, 'sanctum')
            ->getJson('/api/v1/admin/group/members');

        $response2->assertStatus(200)->assertJsonCount(1, 'data');
        $memberIds2 = collect($response2->json('data'))->pluck('id')->toArray();
        $this->assertContains($member2A->id, $memberIds2);
        $this->assertNotContains($member1A->id, $memberIds2);
        $this->assertNotContains($member1B->id, $memberIds2);
    }

    // ========== REQUIREMENT 9.2: Each admin has unique group code ==========

    public function test_each_admin_gets_unique_group_code(): void
    {
        $groupCodes = [];

        // Create 10 admins and verify all have unique codes
        for ($i = 0; $i < 10; $i++) {
            $admin = User::factory()->create([
                'role' => 'admin',
                'organization_name' => 'Test Organization',
            ]);
            $group = AdminGroup::factory()->create(['admin_user_id' => $admin->id]);

            // Verify code is valid format
            $this->assertMatchesRegularExpression('/^\d{4,6}$/', $group->group_code);

            // Verify code is unique
            $this->assertNotContains($group->group_code, $groupCodes);

            $groupCodes[] = $group->group_code;
        }

        // Verify we have 10 unique codes
        $this->assertCount(10, array_unique($groupCodes));
    }

    public function test_group_code_uniqueness_across_different_organizations(): void
    {
        // Create admins in different organizations
        $admin1 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Organization A',
        ]);
        $group1 = AdminGroup::factory()->create(['admin_user_id' => $admin1->id]);

        $admin2 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Organization B',
        ]);
        $group2 = AdminGroup::factory()->create(['admin_user_id' => $admin2->id]);

        $admin3 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Organization C',
        ]);
        $group3 = AdminGroup::factory()->create(['admin_user_id' => $admin3->id]);

        // Verify all codes are unique
        $codes = [$group1->group_code, $group2->group_code, $group3->group_code];
        $this->assertCount(3, array_unique($codes));
    }

    public function test_regenerated_group_codes_remain_unique(): void
    {
        // Create multiple admins
        $admin1 = User::factory()->create(['role' => 'admin', 'organization_name' => 'Test Org']);
        $group1 = AdminGroup::factory()->create(['admin_user_id' => $admin1->id]);

        $admin2 = User::factory()->create(['role' => 'admin', 'organization_name' => 'Test Org']);
        $group2 = AdminGroup::factory()->create(['admin_user_id' => $admin2->id]);

        $admin3 = User::factory()->create(['role' => 'admin', 'organization_name' => 'Test Org']);
        $group3 = AdminGroup::factory()->create(['admin_user_id' => $admin3->id]);

        $originalCodes = [
            $group1->group_code,
            $group2->group_code,
            $group3->group_code,
        ];

        // Admin1 regenerates their code
        $response = $this->actingAs($admin1, 'sanctum')
            ->postJson('/api/v1/admin/group/regenerate');

        $response->assertStatus(200);
        $newCode = $response->json('data.group_code');

        // Verify new code is different from original
        $this->assertNotEquals($group1->group_code, $newCode);

        // Verify new code doesn't conflict with other admins' codes
        $this->assertNotEquals($group2->group_code, $newCode);
        $this->assertNotEquals($group3->group_code, $newCode);

        // Verify new code is valid format
        $this->assertMatchesRegularExpression('/^\d{4,6}$/', $newCode);
    }

    // ========== REQUIREMENT 9.3: Data isolation between admin groups ==========

    public function test_complete_data_isolation_between_admin_groups_in_same_organization(): void
    {
        // Create two admins in same organization
        $adminA = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Shared Organization',
            'department_name' => 'Team A',
        ]);
        $groupA = AdminGroup::factory()->create(['admin_user_id' => $adminA->id]);

        $adminB = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Shared Organization',
            'department_name' => 'Team B',
        ]);
        $groupB = AdminGroup::factory()->create(['admin_user_id' => $adminB->id]);

        // Create members for each group
        $memberA1 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Shared Organization',
            'admin_group_id' => $groupA->id,
        ]);
        $memberA2 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Shared Organization',
            'admin_group_id' => $groupA->id,
        ]);

        $memberB1 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Shared Organization',
            'admin_group_id' => $groupB->id,
        ]);
        $memberB2 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Shared Organization',
            'admin_group_id' => $groupB->id,
        ]);

        // Create financial data for Group A members
        $expenseA1 = Expense::factory()->create(['user_id' => $memberA1->id, 'amount' => 100]);
        $expenseA2 = Expense::factory()->create(['user_id' => $memberA2->id, 'amount' => 200]);
        $transferA1 = Transfer::factory()->create(['user_id' => $memberA1->id, 'amount' => 50]);
        $incomingA1 = Incoming::factory()->create(['user_id' => $memberA1->id, 'amount' => 150]);

        // Create financial data for Group B members
        $expenseB1 = Expense::factory()->create(['user_id' => $memberB1->id, 'amount' => 300]);
        $expenseB2 = Expense::factory()->create(['user_id' => $memberB2->id, 'amount' => 400]);
        $transferB1 = Transfer::factory()->create(['user_id' => $memberB1->id, 'amount' => 75]);
        $incomingB1 = Incoming::factory()->create(['user_id' => $memberB1->id, 'amount' => 250]);

        // Test Admin A can only see Group A expenses
        $expensesA = $this->actingAs($adminA, 'sanctum')->getJson('/api/v1/expenses');
        $expensesA->assertStatus(200)->assertJsonCount(2, 'data');
        $expenseIdsA = collect($expensesA->json('data'))->pluck('id')->toArray();
        $this->assertContains($expenseA1->id, $expenseIdsA);
        $this->assertContains($expenseA2->id, $expenseIdsA);
        $this->assertNotContains($expenseB1->id, $expenseIdsA);
        $this->assertNotContains($expenseB2->id, $expenseIdsA);

        // Test Admin B can only see Group B expenses
        $expensesB = $this->actingAs($adminB, 'sanctum')->getJson('/api/v1/expenses');
        $expensesB->assertStatus(200)->assertJsonCount(2, 'data');
        $expenseIdsB = collect($expensesB->json('data'))->pluck('id')->toArray();
        $this->assertContains($expenseB1->id, $expenseIdsB);
        $this->assertContains($expenseB2->id, $expenseIdsB);
        $this->assertNotContains($expenseA1->id, $expenseIdsB);
        $this->assertNotContains($expenseA2->id, $expenseIdsB);

        // Test Admin A can only see Group A transfers
        $transfersA = $this->actingAs($adminA, 'sanctum')->getJson('/api/v1/transfers');
        $transfersA->assertStatus(200)->assertJsonCount(1, 'data');
        $this->assertEquals($transferA1->id, $transfersA->json('data.0.id'));

        // Test Admin B can only see Group B transfers
        $transfersB = $this->actingAs($adminB, 'sanctum')->getJson('/api/v1/transfers');
        $transfersB->assertStatus(200)->assertJsonCount(1, 'data');
        $this->assertEquals($transferB1->id, $transfersB->json('data.0.id'));

        // Test Admin A can only see Group A incoming
        $incomingA = $this->actingAs($adminA, 'sanctum')->getJson('/api/v1/incoming');
        $incomingA->assertStatus(200)->assertJsonCount(1, 'data');
        $this->assertEquals($incomingA1->id, $incomingA->json('data.0.id'));

        // Test Admin B can only see Group B incoming
        $incomingB = $this->actingAs($adminB, 'sanctum')->getJson('/api/v1/incoming');
        $incomingB->assertStatus(200)->assertJsonCount(1, 'data');
        $this->assertEquals($incomingB1->id, $incomingB->json('data.0.id'));
    }

    public function test_admin_cannot_access_another_admins_group_members(): void
    {
        // Create two admins
        $admin1 = User::factory()->create(['role' => 'admin', 'organization_name' => 'Org A']);
        $group1 = AdminGroup::factory()->create(['admin_user_id' => $admin1->id]);

        $admin2 = User::factory()->create(['role' => 'admin', 'organization_name' => 'Org B']);
        $group2 = AdminGroup::factory()->create(['admin_user_id' => $admin2->id]);

        // Create members
        $member1 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Org A',
            'admin_group_id' => $group1->id,
        ]);
        $member2 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Org B',
            'admin_group_id' => $group2->id,
        ]);

        // Admin1 tries to remove Admin2's member
        $response = $this->actingAs($admin1, 'sanctum')
            ->deleteJson("/api/v1/admin/group/members/{$member2->id}");

        $response->assertStatus(403);

        // Verify member2 is still in group2
        $this->assertDatabaseHas('users', [
            'id' => $member2->id,
            'admin_group_id' => $group2->id,
        ]);

        // Admin2 tries to remove Admin1's member
        $response2 = $this->actingAs($admin2, 'sanctum')
            ->deleteJson("/api/v1/admin/group/members/{$member1->id}");

        $response2->assertStatus(403);

        // Verify member1 is still in group1
        $this->assertDatabaseHas('users', [
            'id' => $member1->id,
            'admin_group_id' => $group1->id,
        ]);
    }

    public function test_data_isolation_with_five_admins_in_same_organization(): void
    {
        // Create 5 admins in same organization
        $admins = [];
        $groups = [];
        $members = [];
        $expenses = [];

        for ($i = 1; $i <= 5; $i++) {
            $admin = User::factory()->create([
                'role' => 'admin',
                'organization_name' => 'Large Corporation',
                'department_name' => "Department {$i}",
            ]);
            $group = AdminGroup::factory()->create(['admin_user_id' => $admin->id]);

            // Create 2 members for each admin
            $member1 = User::factory()->create([
                'role' => 'user',
                'organization_name' => 'Large Corporation',
                'admin_group_id' => $group->id,
            ]);
            $member2 = User::factory()->create([
                'role' => 'user',
                'organization_name' => 'Large Corporation',
                'admin_group_id' => $group->id,
            ]);

            // Create expenses for each member
            $expense1 = Expense::factory()->create(['user_id' => $member1->id]);
            $expense2 = Expense::factory()->create(['user_id' => $member2->id]);

            $admins[$i] = $admin;
            $groups[$i] = $group;
            $members[$i] = [$member1, $member2];
            $expenses[$i] = [$expense1, $expense2];
        }

        // Verify each admin sees only their group's expenses
        for ($i = 1; $i <= 5; $i++) {
            $response = $this->actingAs($admins[$i], 'sanctum')
                ->getJson('/api/v1/expenses');

            $response->assertStatus(200)->assertJsonCount(2, 'data');

            $expenseIds = collect($response->json('data'))->pluck('id')->toArray();

            // Should see own group's expenses
            $this->assertContains($expenses[$i][0]->id, $expenseIds);
            $this->assertContains($expenses[$i][1]->id, $expenseIds);

            // Should NOT see other groups' expenses
            for ($j = 1; $j <= 5; $j++) {
                if ($i !== $j) {
                    $this->assertNotContains($expenses[$j][0]->id, $expenseIds);
                    $this->assertNotContains($expenses[$j][1]->id, $expenseIds);
                }
            }
        }
    }

    // ========== REQUIREMENT 9.4: Users can only join one group at a time ==========

    public function test_user_cannot_join_second_group_in_same_organization(): void
    {
        // Create two admins in same organization
        $admin1 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Company',
        ]);
        $group1 = AdminGroup::factory()->create([
            'admin_user_id' => $admin1->id,
            'group_code' => '111111',
        ]);

        $admin2 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Company',
        ]);
        $group2 = AdminGroup::factory()->create([
            'admin_user_id' => $admin2->id,
            'group_code' => '222222',
        ]);

        // Create user and join first group
        $user = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Company',
            'admin_group_id' => $group1->id,
        ]);

        // Try to join second group
        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/user/join-group', [
                'group_code' => '222222',
            ]);

        $response->assertStatus(409)
            ->assertJson([
                'success' => false,
                'message' => 'User already belongs to a group',
            ]);

        // Verify user is still in first group only
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'admin_group_id' => $group1->id,
        ]);
    }

    public function test_user_cannot_join_second_group_during_registration(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $group = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
            'group_code' => '123456',
        ]);

        // Register user with group code
        $response1 = $this->postJson('/api/v1/auth/register', [
            'name' => 'Test User',
            'email' => 'testuser@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'organization_name' => 'Test Organization',
            'group_code' => '123456',
        ]);

        $response1->assertStatus(201);

        // Verify user is in the group
        $user = User::where('email', 'testuser@example.com')->first();
        $this->assertEquals($group->id, $user->admin_group_id);

        // Create another admin with different group
        $admin2 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $group2 = AdminGroup::factory()->create([
            'admin_user_id' => $admin2->id,
            'group_code' => '654321',
        ]);

        // Try to join second group
        $response2 = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/user/join-group', [
                'group_code' => '654321',
            ]);

        $response2->assertStatus(409);

        // Verify user is still in first group
        $user->refresh();
        $this->assertEquals($group->id, $user->admin_group_id);
    }

    public function test_user_can_join_different_group_after_being_removed(): void
    {
        // Create two admins
        $admin1 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Org',
        ]);
        $group1 = AdminGroup::factory()->create([
            'admin_user_id' => $admin1->id,
            'group_code' => '111111',
        ]);

        $admin2 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Org',
        ]);
        $group2 = AdminGroup::factory()->create([
            'admin_user_id' => $admin2->id,
            'group_code' => '222222',
        ]);

        // Create user in first group
        $user = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Org',
            'admin_group_id' => $group1->id,
        ]);

        // Admin1 removes user from group
        $response1 = $this->actingAs($admin1, 'sanctum')
            ->deleteJson("/api/v1/admin/group/members/{$user->id}");

        $response1->assertStatus(200);

        // Verify user is no longer in any group
        $user->refresh();
        $this->assertNull($user->admin_group_id);

        // User can now join second group
        $response2 = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/user/join-group', [
                'group_code' => '222222',
            ]);

        $response2->assertStatus(200);

        // Verify user is now in second group
        $user->refresh();
        $this->assertEquals($group2->id, $user->admin_group_id);
    }

    public function test_multiple_users_can_join_same_group_but_not_multiple_groups(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Company',
        ]);
        $group = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
            'group_code' => '999999',
        ]);

        // Create 5 users and have them all join the same group
        $users = [];
        for ($i = 1; $i <= 5; $i++) {
            $user = User::factory()->create([
                'role' => 'user',
                'organization_name' => 'Company',
                'admin_group_id' => null,
            ]);

            $response = $this->actingAs($user, 'sanctum')
                ->postJson('/api/v1/user/join-group', [
                    'group_code' => '999999',
                ]);

            $response->assertStatus(200);
            $users[] = $user;
        }

        // Verify all users are in the same group
        foreach ($users as $user) {
            $user->refresh();
            $this->assertEquals($group->id, $user->admin_group_id);
        }

        // Create another admin with different group
        $admin2 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Company',
        ]);
        $group2 = AdminGroup::factory()->create([
            'admin_user_id' => $admin2->id,
            'group_code' => '888888',
        ]);

        // Try to have first user join second group
        $response = $this->actingAs($users[0], 'sanctum')
            ->postJson('/api/v1/user/join-group', [
                'group_code' => '888888',
            ]);

        $response->assertStatus(409);

        // Verify user is still in first group
        $users[0]->refresh();
        $this->assertEquals($group->id, $users[0]->admin_group_id);
    }

    // ========== REQUIREMENT 9.5: Complex multi-admin scenarios ==========

    public function test_users_choose_which_admin_group_to_join_by_code(): void
    {
        // Create 3 admins in same organization
        $admin1 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Big Company',
            'department_name' => 'Sales',
        ]);
        $group1 = AdminGroup::factory()->create([
            'admin_user_id' => $admin1->id,
            'group_code' => '111111',
        ]);

        $admin2 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Big Company',
            'department_name' => 'Marketing',
        ]);
        $group2 = AdminGroup::factory()->create([
            'admin_user_id' => $admin2->id,
            'group_code' => '222222',
        ]);

        $admin3 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Big Company',
            'department_name' => 'Engineering',
        ]);
        $group3 = AdminGroup::factory()->create([
            'admin_user_id' => $admin3->id,
            'group_code' => '333333',
        ]);

        // Create users who choose different groups
        $userA = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Big Company',
            'admin_group_id' => null,
        ]);
        $userB = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Big Company',
            'admin_group_id' => null,
        ]);
        $userC = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Big Company',
            'admin_group_id' => null,
        ]);

        // UserA joins group1
        $this->actingAs($userA, 'sanctum')
            ->postJson('/api/v1/user/join-group', ['group_code' => '111111'])
            ->assertStatus(200);

        // UserB joins group2
        $this->actingAs($userB, 'sanctum')
            ->postJson('/api/v1/user/join-group', ['group_code' => '222222'])
            ->assertStatus(200);

        // UserC joins group3
        $this->actingAs($userC, 'sanctum')
            ->postJson('/api/v1/user/join-group', ['group_code' => '333333'])
            ->assertStatus(200);

        // Verify each user is in the correct group
        $userA->refresh();
        $userB->refresh();
        $userC->refresh();

        $this->assertEquals($group1->id, $userA->admin_group_id);
        $this->assertEquals($group2->id, $userB->admin_group_id);
        $this->assertEquals($group3->id, $userC->admin_group_id);

        // Verify each admin sees only their member
        $membersA = $this->actingAs($admin1, 'sanctum')
            ->getJson('/api/v1/admin/group/members');
        $membersA->assertStatus(200)->assertJsonCount(1, 'data');
        $this->assertEquals($userA->id, $membersA->json('data.0.id'));

        $membersB = $this->actingAs($admin2, 'sanctum')
            ->getJson('/api/v1/admin/group/members');
        $membersB->assertStatus(200)->assertJsonCount(1, 'data');
        $this->assertEquals($userB->id, $membersB->json('data.0.id'));

        $membersC = $this->actingAs($admin3, 'sanctum')
            ->getJson('/api/v1/admin/group/members');
        $membersC->assertStatus(200)->assertJsonCount(1, 'data');
        $this->assertEquals($userC->id, $membersC->json('data.0.id'));
    }

    public function test_admin_group_isolation_with_mixed_departments(): void
    {
        // Create admins with different departments in same organization
        $adminIT = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Tech Corp',
            'department_name' => 'IT',
        ]);
        $groupIT = AdminGroup::factory()->create(['admin_user_id' => $adminIT->id]);

        $adminHR = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Tech Corp',
            'department_name' => 'HR',
        ]);
        $groupHR = AdminGroup::factory()->create(['admin_user_id' => $adminHR->id]);

        // Create users from various departments joining different groups
        $itUser1 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Tech Corp',
            'department_name' => 'IT',
            'admin_group_id' => $groupIT->id,
        ]);
        $itUser2 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Tech Corp',
            'department_name' => 'IT',
            'admin_group_id' => $groupIT->id,
        ]);

        // HR user joins IT admin's group (allowed - different departments can join same group)
        $hrUser = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Tech Corp',
            'department_name' => 'HR',
            'admin_group_id' => $groupIT->id,
        ]);

        // Finance user joins HR admin's group
        $financeUser = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Tech Corp',
            'department_name' => 'Finance',
            'admin_group_id' => $groupHR->id,
        ]);

        // Create expenses
        Expense::factory()->create(['user_id' => $itUser1->id]);
        Expense::factory()->create(['user_id' => $itUser2->id]);
        Expense::factory()->create(['user_id' => $hrUser->id]);
        Expense::factory()->create(['user_id' => $financeUser->id]);

        // IT Admin should see 3 expenses (2 IT users + 1 HR user in their group)
        $itExpenses = $this->actingAs($adminIT, 'sanctum')
            ->getJson('/api/v1/expenses');
        $itExpenses->assertStatus(200)->assertJsonCount(3, 'data');

        // HR Admin should see 1 expense (1 Finance user in their group)
        $hrExpenses = $this->actingAs($adminHR, 'sanctum')
            ->getJson('/api/v1/expenses');
        $hrExpenses->assertStatus(200)->assertJsonCount(1, 'data');
    }

    public function test_group_code_regeneration_does_not_affect_existing_members(): void
    {
        // Create admin with group and members
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Org',
        ]);
        $group = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
            'group_code' => '123456',
        ]);

        // Create members
        $member1 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Org',
            'admin_group_id' => $group->id,
        ]);
        $member2 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Org',
            'admin_group_id' => $group->id,
        ]);

        $originalCode = $group->group_code;

        // Admin regenerates group code
        $response = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/admin/group/regenerate');

        $response->assertStatus(200);
        $newCode = $response->json('data.group_code');

        // Verify code changed
        $this->assertNotEquals($originalCode, $newCode);

        // Verify existing members are still in the group
        $member1->refresh();
        $member2->refresh();
        $this->assertEquals($group->id, $member1->admin_group_id);
        $this->assertEquals($group->id, $member2->admin_group_id);

        // Verify admin can still see members
        $members = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/group/members');
        $members->assertStatus(200)->assertJsonCount(2, 'data');

        // Verify new users cannot join with old code
        $newUser = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Org',
        ]);

        $responseOldCode = $this->actingAs($newUser, 'sanctum')
            ->postJson('/api/v1/user/join-group', [
                'group_code' => $originalCode,
            ]);
        $responseOldCode->assertStatus(422);

        // Verify new users can join with new code
        $responseNewCode = $this->actingAs($newUser, 'sanctum')
            ->postJson('/api/v1/user/join-group', [
                'group_code' => $newCode,
            ]);
        $responseNewCode->assertStatus(200);

        $newUser->refresh();
        $this->assertEquals($group->id, $newUser->admin_group_id);
    }

    public function test_complete_multi_admin_workflow(): void
    {
        // Scenario: Large organization with multiple teams
        $orgName = 'Global Enterprise';

        // Step 1: Three team leads register as admins
        $teamLeadA = $this->postJson('/api/v1/auth/register', [
            'name' => 'Team Lead A',
            'email' => 'leada@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'role' => 'admin',
            'organization_name' => $orgName,
            'department_name' => 'Development',
        ])->assertStatus(201);

        $teamLeadB = $this->postJson('/api/v1/auth/register', [
            'name' => 'Team Lead B',
            'email' => 'leadb@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'role' => 'admin',
            'organization_name' => $orgName,
            'department_name' => 'QA',
        ])->assertStatus(201);

        $teamLeadC = $this->postJson('/api/v1/auth/register', [
            'name' => 'Team Lead C',
            'email' => 'leadc@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'role' => 'admin',
            'organization_name' => $orgName,
            'department_name' => 'DevOps',
        ])->assertStatus(201);

        // Step 2: Get admin users and their group codes
        $adminA = User::where('email', 'leada@example.com')->first();
        $adminB = User::where('email', 'leadb@example.com')->first();
        $adminC = User::where('email', 'leadc@example.com')->first();

        $groupA = AdminGroup::where('admin_user_id', $adminA->id)->first();
        $groupB = AdminGroup::where('admin_user_id', $adminB->id)->first();
        $groupC = AdminGroup::where('admin_user_id', $adminC->id)->first();

        // Verify all have unique codes
        $this->assertNotEquals($groupA->group_code, $groupB->group_code);
        $this->assertNotEquals($groupA->group_code, $groupC->group_code);
        $this->assertNotEquals($groupB->group_code, $groupC->group_code);

        // Step 3: Team members register and join their respective teams
        // Team A members
        $this->postJson('/api/v1/auth/register', [
            'name' => 'Developer 1',
            'email' => 'dev1@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'organization_name' => $orgName,
            'group_code' => $groupA->group_code,
        ])->assertStatus(201);

        $this->postJson('/api/v1/auth/register', [
            'name' => 'Developer 2',
            'email' => 'dev2@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'organization_name' => $orgName,
            'group_code' => $groupA->group_code,
        ])->assertStatus(201);

        // Team B members
        $this->postJson('/api/v1/auth/register', [
            'name' => 'QA Engineer 1',
            'email' => 'qa1@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'organization_name' => $orgName,
            'group_code' => $groupB->group_code,
        ])->assertStatus(201);

        // Team C members
        $this->postJson('/api/v1/auth/register', [
            'name' => 'DevOps Engineer 1',
            'email' => 'devops1@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'organization_name' => $orgName,
            'group_code' => $groupC->group_code,
        ])->assertStatus(201);

        // Step 4: Verify each admin sees only their team members
        $membersA = $this->actingAs($adminA, 'sanctum')
            ->getJson('/api/v1/admin/group/members');
        $membersA->assertStatus(200)->assertJsonCount(2, 'data');

        $membersB = $this->actingAs($adminB, 'sanctum')
            ->getJson('/api/v1/admin/group/members');
        $membersB->assertStatus(200)->assertJsonCount(1, 'data');

        $membersC = $this->actingAs($adminC, 'sanctum')
            ->getJson('/api/v1/admin/group/members');
        $membersC->assertStatus(200)->assertJsonCount(1, 'data');

        // Step 5: Create expenses for each team
        $dev1 = User::where('email', 'dev1@example.com')->first();
        $dev2 = User::where('email', 'dev2@example.com')->first();
        $qa1 = User::where('email', 'qa1@example.com')->first();
        $devops1 = User::where('email', 'devops1@example.com')->first();

        Expense::factory()->create(['user_id' => $dev1->id, 'amount' => 100]);
        Expense::factory()->create(['user_id' => $dev2->id, 'amount' => 200]);
        Expense::factory()->create(['user_id' => $qa1->id, 'amount' => 150]);
        Expense::factory()->create(['user_id' => $devops1->id, 'amount' => 175]);

        // Step 6: Verify data isolation
        $expensesA = $this->actingAs($adminA, 'sanctum')
            ->getJson('/api/v1/expenses');
        $expensesA->assertStatus(200)->assertJsonCount(2, 'data');

        $expensesB = $this->actingAs($adminB, 'sanctum')
            ->getJson('/api/v1/expenses');
        $expensesB->assertStatus(200)->assertJsonCount(1, 'data');

        $expensesC = $this->actingAs($adminC, 'sanctum')
            ->getJson('/api/v1/expenses');
        $expensesC->assertStatus(200)->assertJsonCount(1, 'data');

        // Step 7: Admin A removes a member
        $this->actingAs($adminA, 'sanctum')
            ->deleteJson("/api/v1/admin/group/members/{$dev2->id}")
            ->assertStatus(200);

        // Verify member count decreased
        $membersAAfter = $this->actingAs($adminA, 'sanctum')
            ->getJson('/api/v1/admin/group/members');
        $membersAAfter->assertStatus(200)->assertJsonCount(1, 'data');

        // Step 8: Removed member can join another team
        $dev2->refresh();
        $this->assertNull($dev2->admin_group_id);

        $this->actingAs($dev2, 'sanctum')
            ->postJson('/api/v1/user/join-group', [
                'group_code' => $groupB->group_code,
            ])
            ->assertStatus(200);

        // Verify member is now in Team B
        $membersB2 = $this->actingAs($adminB, 'sanctum')
            ->getJson('/api/v1/admin/group/members');
        $membersB2->assertStatus(200)->assertJsonCount(2, 'data');
    }
}

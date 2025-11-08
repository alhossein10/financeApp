<?php

namespace Tests\Feature;

use App\Models\AdminGroup;
use App\Models\Transfer;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminGroupTransferRestrictionsTest extends TestCase
{
    use RefreshDatabase;

    // ========== ADMIN TRANSFER TO GROUP MEMBERS TESTS ==========

    public function test_admin_can_transfer_to_group_member(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
        ]);

        // Create group member
        $member = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => $adminGroup->id,
        ]);

        // Admin creates transfer to group member
        $response = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => $member->name,
                'recipient_user_id' => $member->id,
                'amount_usd' => 500.00,
                'transfer_date' => '2025-10-15',
                'notes' => 'Payment to group member',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'id',
                    'user_id',
                    'recipient_name',
                    'amount_usd',
                ],
            ]);

        // Verify transfer was created
        $this->assertDatabaseHas('transfers', [
            'user_id' => $admin->id,
            'recipient_name' => $member->name,
            'amount_usd' => 500.00,
        ]);
    }

    public function test_admin_can_transfer_to_multiple_group_members(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
        ]);

        // Create multiple group members
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

        // Admin creates transfer to first member
        $response1 = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => $member1->name,
                'recipient_user_id' => $member1->id,
                'amount_usd' => 300.00,
                'transfer_date' => '2025-10-15',
            ]);

        $response1->assertStatus(201);

        // Admin creates transfer to second member
        $response2 = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => $member2->name,
                'recipient_user_id' => $member2->id,
                'amount_usd' => 400.00,
                'transfer_date' => '2025-10-16',
            ]);

        $response2->assertStatus(201);

        // Verify both transfers were created
        $this->assertDatabaseHas('transfers', [
            'user_id' => $admin->id,
            'recipient_name' => $member1->name,
        ]);
        $this->assertDatabaseHas('transfers', [
            'user_id' => $admin->id,
            'recipient_name' => $member2->name,
        ]);
    }

    // ========== ADMIN CANNOT TRANSFER TO NON-GROUP MEMBERS TESTS ==========

    public function test_admin_cannot_transfer_to_non_group_member(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
        ]);

        // Create user not in admin's group
        $nonMember = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Other Organization',
        ]);

        // Admin tries to create transfer to non-member
        $response = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => $nonMember->name,
                'recipient_user_id' => $nonMember->id,
                'amount_usd' => 500.00,
                'transfer_date' => '2025-10-15',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['recipient_user_id'])
            ->assertJson([
                'message' => 'The given data was invalid.',
                'errors' => [
                    'recipient_user_id' => ['Cannot transfer to user outside your group.'],
                ],
            ]);

        // Verify transfer was not created
        $this->assertDatabaseMissing('transfers', [
            'user_id' => $admin->id,
            'recipient_name' => $nonMember->name,
        ]);
    }

    public function test_admin_cannot_transfer_to_user_in_different_admin_group(): void
    {
        // Create first admin with group
        $admin1 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup1 = AdminGroup::factory()->create([
            'admin_user_id' => $admin1->id,
        ]);

        // Create second admin with group
        $admin2 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup2 = AdminGroup::factory()->create([
            'admin_user_id' => $admin2->id,
        ]);

        // Create member in admin2's group
        $member2 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => $adminGroup2->id,
        ]);

        // Admin1 tries to transfer to admin2's member
        $response = $this->actingAs($admin1, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => $member2->name,
                'recipient_user_id' => $member2->id,
                'amount_usd' => 500.00,
                'transfer_date' => '2025-10-15',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['recipient_user_id'])
            ->assertJson([
                'errors' => [
                    'recipient_user_id' => ['Cannot transfer to user outside your group.'],
                ],
            ]);

        // Verify transfer was not created
        $this->assertDatabaseMissing('transfers', [
            'user_id' => $admin1->id,
            'recipient_name' => $member2->name,
        ]);
    }

    public function test_admin_cannot_transfer_to_user_without_group(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
        ]);

        // Create user without group
        $userWithoutGroup = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => null,
        ]);

        // Admin tries to transfer to user without group
        $response = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => $userWithoutGroup->name,
                'recipient_user_id' => $userWithoutGroup->id,
                'amount_usd' => 500.00,
                'transfer_date' => '2025-10-15',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['recipient_user_id']);

        // Verify transfer was not created
        $this->assertDatabaseMissing('transfers', [
            'user_id' => $admin->id,
            'recipient_name' => $userWithoutGroup->name,
        ]);
    }

    // ========== TRANSFER VALIDATION ERROR MESSAGES TESTS ==========

    public function test_transfer_validation_returns_appropriate_error_message(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
        ]);

        // Create non-member user
        $nonMember = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Other Organization',
        ]);

        // Admin tries to transfer to non-member
        $response = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => $nonMember->name,
                'recipient_user_id' => $nonMember->id,
                'amount_usd' => 500.00,
                'transfer_date' => '2025-10-15',
            ]);

        $response->assertStatus(422)
            ->assertJsonStructure([
                'message',
                'errors' => [
                    'recipient_user_id',
                ],
            ])
            ->assertJson([
                'errors' => [
                    'recipient_user_id' => ['Cannot transfer to user outside your group.'],
                ],
            ]);
    }

    public function test_transfer_validation_with_invalid_recipient_user_id(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
        ]);

        // Try to transfer to non-existent user
        $response = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => 'Non Existent User',
                'recipient_user_id' => 99999,
                'amount_usd' => 500.00,
                'transfer_date' => '2025-10-15',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['recipient_user_id']);
    }

    // ========== REGULAR USER TRANSFER RESTRICTIONS TESTS ==========

    public function test_regular_user_can_transfer_to_themselves(): void
    {
        // Create regular user
        $user = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
        ]);

        // User creates transfer to themselves
        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => $user->name,
                'recipient_user_id' => $user->id,
                'amount_usd' => 300.00,
                'transfer_date' => '2025-10-15',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
            ]);

        // Verify transfer was created
        $this->assertDatabaseHas('transfers', [
            'user_id' => $user->id,
            'recipient_name' => $user->name,
        ]);
    }

    public function test_regular_user_in_group_can_transfer_to_group_member(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
        ]);

        // Create two users in the same group
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

        // User1 creates transfer to user2
        $response = $this->actingAs($user1, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => $user2->name,
                'recipient_user_id' => $user2->id,
                'amount_usd' => 200.00,
                'transfer_date' => '2025-10-15',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
            ]);

        // Verify transfer was created
        $this->assertDatabaseHas('transfers', [
            'user_id' => $user1->id,
            'recipient_name' => $user2->name,
        ]);
    }

    public function test_regular_user_in_group_cannot_transfer_to_user_outside_group(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
        ]);

        // Create user in group
        $userInGroup = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => $adminGroup->id,
        ]);

        // Create user outside group
        $userOutsideGroup = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Other Organization',
            'admin_group_id' => null,
        ]);

        // User in group tries to transfer to user outside group
        $response = $this->actingAs($userInGroup, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => $userOutsideGroup->name,
                'recipient_user_id' => $userOutsideGroup->id,
                'amount_usd' => 200.00,
                'transfer_date' => '2025-10-15',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['recipient_user_id'])
            ->assertJson([
                'errors' => [
                    'recipient_user_id' => ['Cannot transfer to user outside your group.'],
                ],
            ]);

        // Verify transfer was not created
        $this->assertDatabaseMissing('transfers', [
            'user_id' => $userInGroup->id,
            'recipient_name' => $userOutsideGroup->name,
        ]);
    }

    public function test_regular_user_without_group_can_only_transfer_to_themselves(): void
    {
        // Create two users without groups
        $user1 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => null,
        ]);
        $user2 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => null,
        ]);

        // User1 tries to transfer to user2
        $response = $this->actingAs($user1, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => $user2->name,
                'recipient_user_id' => $user2->id,
                'amount_usd' => 200.00,
                'transfer_date' => '2025-10-15',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['recipient_user_id'])
            ->assertJson([
                'errors' => [
                    'recipient_user_id' => ['You can only transfer to yourself.'],
                ],
            ]);

        // Verify transfer was not created
        $this->assertDatabaseMissing('transfers', [
            'user_id' => $user1->id,
            'recipient_name' => $user2->name,
        ]);
    }

    public function test_regular_user_without_group_can_transfer_to_themselves(): void
    {
        // Create user without group
        $user = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => null,
        ]);

        // User creates transfer to themselves
        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => $user->name,
                'recipient_user_id' => $user->id,
                'amount_usd' => 150.00,
                'transfer_date' => '2025-10-15',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
            ]);

        // Verify transfer was created
        $this->assertDatabaseHas('transfers', [
            'user_id' => $user->id,
            'recipient_name' => $user->name,
        ]);
    }

    // ========== TRANSFER WITHOUT RECIPIENT_USER_ID TESTS ==========

    public function test_admin_can_create_transfer_without_recipient_user_id(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
        ]);

        // Admin creates transfer without recipient_user_id (external recipient)
        $response = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => 'External Recipient',
                'amount_usd' => 500.00,
                'transfer_date' => '2025-10-15',
                'notes' => 'Payment to external party',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
            ]);

        // Verify transfer was created
        $this->assertDatabaseHas('transfers', [
            'user_id' => $admin->id,
            'recipient_name' => 'External Recipient',
        ]);
    }

    public function test_regular_user_can_create_transfer_without_recipient_user_id(): void
    {
        // Create regular user
        $user = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
        ]);

        // User creates transfer without recipient_user_id (external recipient)
        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => 'External Recipient',
                'amount_usd' => 300.00,
                'transfer_date' => '2025-10-15',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
            ]);

        // Verify transfer was created
        $this->assertDatabaseHas('transfers', [
            'user_id' => $user->id,
            'recipient_name' => 'External Recipient',
        ]);
    }

    // ========== CROSS-GROUP ISOLATION TESTS ==========

    public function test_admin_from_different_organization_cannot_transfer_to_user(): void
    {
        // Create admin1 with group in Organization A
        $admin1 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Organization A',
        ]);
        $adminGroup1 = AdminGroup::factory()->create([
            'admin_user_id' => $admin1->id,
        ]);

        // Create user in Organization B
        $userOrgB = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Organization B',
        ]);

        // Admin1 tries to transfer to user in different organization
        $response = $this->actingAs($admin1, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => $userOrgB->name,
                'recipient_user_id' => $userOrgB->id,
                'amount_usd' => 500.00,
                'transfer_date' => '2025-10-15',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['recipient_user_id']);

        // Verify transfer was not created
        $this->assertDatabaseMissing('transfers', [
            'user_id' => $admin1->id,
            'recipient_name' => $userOrgB->name,
        ]);
    }

    public function test_data_isolation_between_admin_groups_in_same_organization(): void
    {
        // Create two admins in same organization with separate groups
        $admin1 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup1 = AdminGroup::factory()->create([
            'admin_user_id' => $admin1->id,
        ]);

        $admin2 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup2 = AdminGroup::factory()->create([
            'admin_user_id' => $admin2->id,
        ]);

        // Create members for each group
        $member1 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => $adminGroup1->id,
        ]);
        $member2 = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => $adminGroup2->id,
        ]);

        // Admin1 can transfer to member1
        $response1 = $this->actingAs($admin1, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => $member1->name,
                'recipient_user_id' => $member1->id,
                'amount_usd' => 300.00,
                'transfer_date' => '2025-10-15',
            ]);
        $response1->assertStatus(201);

        // Admin1 cannot transfer to member2
        $response2 = $this->actingAs($admin1, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => $member2->name,
                'recipient_user_id' => $member2->id,
                'amount_usd' => 300.00,
                'transfer_date' => '2025-10-15',
            ]);
        $response2->assertStatus(422)
            ->assertJsonValidationErrors(['recipient_user_id']);

        // Admin2 can transfer to member2
        $response3 = $this->actingAs($admin2, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => $member2->name,
                'recipient_user_id' => $member2->id,
                'amount_usd' => 400.00,
                'transfer_date' => '2025-10-15',
            ]);
        $response3->assertStatus(201);

        // Admin2 cannot transfer to member1
        $response4 = $this->actingAs($admin2, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => $member1->name,
                'recipient_user_id' => $member1->id,
                'amount_usd' => 400.00,
                'transfer_date' => '2025-10-15',
            ]);
        $response4->assertStatus(422)
            ->assertJsonValidationErrors(['recipient_user_id']);
    }
}

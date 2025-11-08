<?php

namespace Tests\Feature;

use App\Models\AdminGroup;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminGroupManagementTest extends TestCase
{
    use RefreshDatabase;

    // ========== ADMIN REGISTRATION AND GROUP CREATION TESTS ==========

    public function test_admin_registration_creates_group_with_unique_code(): void
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Admin User',
            'email' => 'admin@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'role' => 'admin',
            'organization_name' => 'Test Organization',
            'department_name' => 'IT Department',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'User registered successfully.',
            ]);

        // Verify admin user was created
        $this->assertDatabaseHas('users', [
            'email' => 'admin@example.com',
            'role' => 'admin',
            'organization_name' => 'Test Organization',
            'department_name' => 'IT Department',
        ]);

        // Verify admin group was created
        $admin = User::where('email', 'admin@example.com')->first();
        $this->assertDatabaseHas('admin_groups', [
            'admin_user_id' => $admin->id,
            'is_active' => true,
        ]);

        // Verify group code is unique and valid format
        $adminGroup = AdminGroup::where('admin_user_id', $admin->id)->first();
        $this->assertNotNull($adminGroup);
        $this->assertNotNull($adminGroup->group_code);
        $this->assertMatchesRegularExpression('/^\d{4,6}$/', $adminGroup->group_code);
    }

    public function test_multiple_admins_get_unique_group_codes(): void
    {
        // Create first admin
        $response1 = $this->postJson('/api/v1/auth/register', [
            'name' => 'Admin One',
            'email' => 'admin1@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);

        $response1->assertStatus(201);

        // Create second admin
        $response2 = $this->postJson('/api/v1/auth/register', [
            'name' => 'Admin Two',
            'email' => 'admin2@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);

        $response2->assertStatus(201);

        // Verify both have different group codes
        $admin1 = User::where('email', 'admin1@example.com')->first();
        $admin2 = User::where('email', 'admin2@example.com')->first();

        $group1 = AdminGroup::where('admin_user_id', $admin1->id)->first();
        $group2 = AdminGroup::where('admin_user_id', $admin2->id)->first();

        $this->assertNotEquals($group1->group_code, $group2->group_code);
    }

    // ========== USER REGISTRATION WITH GROUP CODE TESTS ==========

    public function test_user_registration_with_valid_group_code_joins_group(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
            'department_name' => 'IT',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
            'group_code' => '123456',
        ]);

        // Register user with group code
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Regular User',
            'email' => 'user@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'organization_name' => 'Test Organization',
            'department_name' => 'HR',
            'group_code' => '123456',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'User registered successfully.',
            ]);

        // Verify user was assigned to admin group
        $this->assertDatabaseHas('users', [
            'email' => 'user@example.com',
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => $adminGroup->id,
        ]);
    }

    public function test_user_registration_with_invalid_group_code_fails(): void
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Regular User',
            'email' => 'user@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'organization_name' => 'Test Organization',
            'group_code' => '999999',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['group_code']);
    }

    public function test_organization_mismatch_prevents_group_joining(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Organization A',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
            'group_code' => '123456',
        ]);

        // Try to register user with different organization
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Regular User',
            'email' => 'user@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'organization_name' => 'Organization B',
            'group_code' => '123456',
        ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
            ]);

        // Verify user was not assigned to group
        $user = User::where('email', 'user@example.com')->first();
        if ($user) {
            $this->assertNull($user->admin_group_id);
        }
    }

    public function test_organization_matching_is_case_insensitive(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
            'group_code' => '123456',
        ]);

        // Register user with different case organization name
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Regular User',
            'email' => 'user@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'organization_name' => 'TEST ORGANIZATION',
            'group_code' => '123456',
        ]);

        $response->assertStatus(201);

        // Verify user was assigned to admin group
        $this->assertDatabaseHas('users', [
            'email' => 'user@example.com',
            'admin_group_id' => $adminGroup->id,
        ]);
    }

    public function test_different_departments_can_join_same_group(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
            'department_name' => 'IT',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
            'group_code' => '123456',
        ]);

        // Register user with different department
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Regular User',
            'email' => 'user@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'organization_name' => 'Test Organization',
            'department_name' => 'HR',
            'group_code' => '123456',
        ]);

        $response->assertStatus(201);

        // Verify user was assigned to admin group
        $this->assertDatabaseHas('users', [
            'email' => 'user@example.com',
            'admin_group_id' => $adminGroup->id,
            'department_name' => 'HR',
        ]);
    }

    // ========== ADMIN GROUP MEMBER MANAGEMENT TESTS ==========

    public function test_admin_can_view_group_members(): void
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

        // Admin requests group members
        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/group/members');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonCount(2, 'data')
            ->assertJsonStructure([
                'success',
                'data' => [
                    '*' => [
                        'id',
                        'name',
                        'email',
                        'organization_name',
                        'department_name',
                        'created_at',
                    ],
                ],
            ]);

        // Verify correct members are returned
        $memberIds = collect($response->json('data'))->pluck('id')->toArray();
        $this->assertContains($member1->id, $memberIds);
        $this->assertContains($member2->id, $memberIds);
    }

    public function test_admin_can_remove_group_member(): void
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

        // Admin removes member
        $response = $this->actingAs($admin, 'sanctum')
            ->deleteJson("/api/v1/admin/group/members/{$member->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Member removed from group successfully',
            ]);

        // Verify member was removed from group
        $this->assertDatabaseHas('users', [
            'id' => $member->id,
            'admin_group_id' => null,
        ]);
    }

    public function test_admin_cannot_remove_non_group_member(): void
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
        $otherUser = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Other Organization',
        ]);

        // Admin tries to remove non-member
        $response = $this->actingAs($admin, 'sanctum')
            ->deleteJson("/api/v1/admin/group/members/{$otherUser->id}");

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_admin_can_regenerate_group_code(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
            'group_code' => '123456',
        ]);

        $originalCode = $adminGroup->group_code;

        // Admin regenerates group code
        $response = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/admin/group/regenerate');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Group code regenerated successfully',
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'group_code',
                ],
            ]);

        // Verify new code is different
        $newCode = $response->json('data.group_code');
        $this->assertNotEquals($originalCode, $newCode);
        $this->assertMatchesRegularExpression('/^\d{4,6}$/', $newCode);

        // Verify database was updated
        $this->assertDatabaseHas('admin_groups', [
            'id' => $adminGroup->id,
            'group_code' => $newCode,
        ]);
    }

    public function test_admin_can_get_group_info(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
            'group_code' => '123456',
        ]);

        // Admin requests group info
        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/group');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $adminGroup->id,
                    'group_code' => '123456',
                    'admin_user_id' => $admin->id,
                ],
            ])
            ->assertJsonStructure([
                'success',
                'data' => [
                    'id',
                    'admin_user_id',
                    'group_code',
                    'is_active',
                    'created_at',
                ],
            ]);
    }

    // ========== USER GROUP JOINING TESTS ==========

    public function test_user_can_join_group_after_registration(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
            'group_code' => '123456',
        ]);

        // Create user without group
        $user = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => null,
        ]);

        // User joins group
        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/user/join-group', [
                'group_code' => '123456',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Successfully joined group',
            ]);

        // Verify user was assigned to group
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'admin_group_id' => $adminGroup->id,
        ]);
    }

    public function test_user_cannot_join_multiple_groups(): void
    {
        // Create two admins with groups
        $admin1 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup1 = AdminGroup::factory()->create([
            'admin_user_id' => $admin1->id,
            'group_code' => '111111',
        ]);

        $admin2 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup2 = AdminGroup::factory()->create([
            'admin_user_id' => $admin2->id,
            'group_code' => '222222',
        ]);

        // Create user and join first group
        $user = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => $adminGroup1->id,
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

        // Verify user is still in first group
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'admin_group_id' => $adminGroup1->id,
        ]);
    }

    public function test_user_can_view_their_group_info(): void
    {
        // Create admin with group
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup = AdminGroup::factory()->create([
            'admin_user_id' => $admin->id,
            'group_code' => '123456',
        ]);

        // Create user in group
        $user = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => $adminGroup->id,
        ]);

        // User requests group info
        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/user/group-info');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'group_id' => $adminGroup->id,
                    'admin_name' => $admin->name,
                ],
            ])
            ->assertJsonStructure([
                'success',
                'data' => [
                    'group_id',
                    'admin_name',
                    'admin_email',
                    'organization_name',
                ],
            ]);
    }

    // ========== AUTHORIZATION TESTS ==========

    public function test_regular_user_cannot_access_admin_group_endpoints(): void
    {
        $user = User::factory()->create(['role' => 'user']);

        // Try to get group info
        $response1 = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/admin/group');
        $response1->assertStatus(403);

        // Try to get group members
        $response2 = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/admin/group/members');
        $response2->assertStatus(403);

        // Try to regenerate code
        $response3 = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/admin/group/regenerate');
        $response3->assertStatus(403);
    }

    public function test_unauthenticated_user_cannot_access_group_endpoints(): void
    {
        // Try admin endpoints
        $this->getJson('/api/v1/admin/group')->assertStatus(401);
        $this->getJson('/api/v1/admin/group/members')->assertStatus(401);
        $this->postJson('/api/v1/admin/group/regenerate')->assertStatus(401);

        // Try user endpoints
        $this->postJson('/api/v1/user/join-group')->assertStatus(401);
        $this->getJson('/api/v1/user/group-info')->assertStatus(401);
    }

    // ========== MULTI-ADMIN SCENARIO TESTS ==========

    public function test_multiple_admins_in_same_organization_have_separate_groups(): void
    {
        // Create two admins in same organization
        $admin1 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup1 = AdminGroup::factory()->create([
            'admin_user_id' => $admin1->id,
            'group_code' => '111111',
        ]);

        $admin2 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $adminGroup2 = AdminGroup::factory()->create([
            'admin_user_id' => $admin2->id,
            'group_code' => '222222',
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

        // Admin1 should only see their members
        $response1 = $this->actingAs($admin1, 'sanctum')
            ->getJson('/api/v1/admin/group/members');

        $response1->assertStatus(200)
            ->assertJsonCount(1, 'data');

        $memberIds1 = collect($response1->json('data'))->pluck('id')->toArray();
        $this->assertContains($member1->id, $memberIds1);
        $this->assertNotContains($member2->id, $memberIds1);

        // Admin2 should only see their members
        $response2 = $this->actingAs($admin2, 'sanctum')
            ->getJson('/api/v1/admin/group/members');

        $response2->assertStatus(200)
            ->assertJsonCount(1, 'data');

        $memberIds2 = collect($response2->json('data'))->pluck('id')->toArray();
        $this->assertContains($member2->id, $memberIds2);
        $this->assertNotContains($member1->id, $memberIds2);
    }

    public function test_admin_cannot_remove_member_from_another_admins_group(): void
    {
        // Create two admins with groups
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

        // Create member in admin2's group
        $member = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
            'admin_group_id' => $adminGroup2->id,
        ]);

        // Admin1 tries to remove admin2's member
        $response = $this->actingAs($admin1, 'sanctum')
            ->deleteJson("/api/v1/admin/group/members/{$member->id}");

        $response->assertStatus(403);

        // Verify member is still in admin2's group
        $this->assertDatabaseHas('users', [
            'id' => $member->id,
            'admin_group_id' => $adminGroup2->id,
        ]);
    }

    // ========== VALIDATION TESTS ==========

    public function test_group_code_validation_requires_4_to_6_digits(): void
    {
        $user = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
        ]);

        // Test too short
        $response1 = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/user/join-group', [
                'group_code' => '123',
            ]);
        $response1->assertStatus(422);

        // Test too long
        $response2 = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/user/join-group', [
                'group_code' => '1234567',
            ]);
        $response2->assertStatus(422);

        // Test non-numeric
        $response3 = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/user/join-group', [
                'group_code' => 'ABCD',
            ]);
        $response3->assertStatus(422);
    }

    public function test_organization_name_validation_during_registration(): void
    {
        // Test missing organization_name
        $response1 = $this->postJson('/api/v1/auth/register', [
            'name' => 'Test User',
            'email' => 'test@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);
        $response1->assertStatus(422)
            ->assertJsonValidationErrors(['organization_name']);

        // Test too short organization_name
        $response2 = $this->postJson('/api/v1/auth/register', [
            'name' => 'Test User',
            'email' => 'test@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'organization_name' => 'A',
        ]);
        $response2->assertStatus(422)
            ->assertJsonValidationErrors(['organization_name']);

        // Test too long organization_name
        $response3 = $this->postJson('/api/v1/auth/register', [
            'name' => 'Test User',
            'email' => 'test@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'organization_name' => str_repeat('A', 256),
        ]);
        $response3->assertStatus(422)
            ->assertJsonValidationErrors(['organization_name']);
    }

    public function test_department_name_is_optional_during_registration(): void
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Test User',
            'email' => 'test@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'organization_name' => 'Test Organization',
            // department_name is omitted
        ]);

        $response->assertStatus(201);

        $this->assertDatabaseHas('users', [
            'email' => 'test@example.com',
            'organization_name' => 'Test Organization',
            'department_name' => null,
        ]);
    }
}

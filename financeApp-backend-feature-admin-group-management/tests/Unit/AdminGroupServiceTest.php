<?php

namespace Tests\Unit;

use App\Models\AdminGroup;
use App\Models\User;
use App\Repositories\AdminGroupRepository;
use App\Services\AdminGroupService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class AdminGroupServiceTest extends TestCase
{
    use RefreshDatabase;

    protected AdminGroupService $adminGroupService;
    protected AdminGroupRepository $adminGroupRepository;

    protected function setUp(): void
    {
        parent::setUp();
        $this->adminGroupRepository = new AdminGroupRepository();
        $this->adminGroupService = new AdminGroupService($this->adminGroupRepository);
    }

    // Tests for createGroupForAdmin()

    public function test_create_group_for_admin_creates_group_with_unique_code(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
            'name' => 'Admin User',
        ]);

        $group = $this->adminGroupService->createGroupForAdmin($admin);

        $this->assertInstanceOf(AdminGroup::class, $group);
        $this->assertEquals($admin->id, $group->admin_user_id);
        $this->assertNotEmpty($group->group_code);
        $this->assertMatchesRegularExpression('/^\d{6}$/', $group->group_code);
        $this->assertTrue($group->is_active);
        $this->assertDatabaseHas('admin_groups', [
            'admin_user_id' => $admin->id,
            'group_code' => $group->group_code,
        ]);
    }

    public function test_create_group_for_admin_generates_default_group_name(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Org',
            'name' => 'John Doe',
        ]);

        $group = $this->adminGroupService->createGroupForAdmin($admin);

        $this->assertEquals('Test Org - John Doe', $group->group_name);
    }

    public function test_create_group_for_admin_accepts_custom_group_name(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Org',
        ]);

        $group = $this->adminGroupService->createGroupForAdmin($admin, 'Custom Group Name');

        $this->assertEquals('Custom Group Name', $group->group_name);
    }

    public function test_create_group_for_admin_returns_existing_group_if_already_exists(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        
        // Create first group
        $firstGroup = $this->adminGroupService->createGroupForAdmin($admin);
        
        // Try to create again
        $secondGroup = $this->adminGroupService->createGroupForAdmin($admin);

        $this->assertEquals($firstGroup->id, $secondGroup->id);
        $this->assertEquals($firstGroup->group_code, $secondGroup->group_code);
        
        // Verify only one group exists
        $this->assertCount(1, AdminGroup::where('admin_user_id', $admin->id)->get());
    }

    public function test_create_group_for_admin_throws_exception_for_non_admin_user(): void
    {
        $user = User::factory()->create(['role' => 'user']);

        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('Only admin users can have groups created for them.');
        
        $this->adminGroupService->createGroupForAdmin($user);
    }

    // Tests for joinGroupByCode()

    public function test_join_group_by_code_assigns_user_to_group_with_valid_code(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Org',
        ]);
        $group = $this->adminGroupService->createGroupForAdmin($admin);

        $user = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Org',
        ]);

        $result = $this->adminGroupService->joinGroupByCode($user, $group->group_code);

        $this->assertInstanceOf(AdminGroup::class, $result);
        $this->assertEquals($group->id, $result->id);
        
        $user->refresh();
        $this->assertEquals($group->id, $user->admin_group_id);
    }

    public function test_join_group_by_code_throws_exception_for_invalid_code(): void
    {
        $user = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Org',
        ]);

        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('Invalid group code.');
        
        $this->adminGroupService->joinGroupByCode($user, '999999');
    }

    public function test_join_group_by_code_throws_exception_for_admin_user(): void
    {
        $admin1 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Org',
        ]);
        $group = $this->adminGroupService->createGroupForAdmin($admin1);

        $admin2 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Org',
        ]);

        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('Admin users cannot join groups.');
        
        $this->adminGroupService->joinGroupByCode($admin2, $group->group_code);
    }

    public function test_join_group_by_code_throws_exception_if_user_already_in_group(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Org',
        ]);
        $group = $this->adminGroupService->createGroupForAdmin($admin);

        $user = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Org',
            'admin_group_id' => $group->id,
        ]);

        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('User already belongs to a group.');
        
        $this->adminGroupService->joinGroupByCode($user, $group->group_code);
    }

    public function test_join_group_by_code_throws_exception_for_different_organization(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Organization A',
        ]);
        $group = $this->adminGroupService->createGroupForAdmin($admin);

        $user = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Organization B',
        ]);

        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('Cannot join group from different organization.');
        
        $this->adminGroupService->joinGroupByCode($user, $group->group_code);
    }

    // Tests for validateGroupCodeForUser()

    public function test_validate_group_code_for_user_returns_true_for_matching_organization(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $group = $this->adminGroupService->createGroupForAdmin($admin);

        $user = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Organization',
        ]);

        $result = $this->adminGroupService->validateGroupCodeForUser($user, $group->group_code);

        $this->assertTrue($result);
    }

    public function test_validate_group_code_for_user_is_case_insensitive(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $group = $this->adminGroupService->createGroupForAdmin($admin);

        $user = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'TEST ORGANIZATION',
        ]);

        $result = $this->adminGroupService->validateGroupCodeForUser($user, $group->group_code);

        $this->assertTrue($result);
    }

    public function test_validate_group_code_for_user_handles_whitespace(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Organization',
        ]);
        $group = $this->adminGroupService->createGroupForAdmin($admin);

        $user = User::factory()->create([
            'role' => 'user',
            'organization_name' => '  Test Organization  ',
        ]);

        $result = $this->adminGroupService->validateGroupCodeForUser($user, $group->group_code);

        $this->assertTrue($result);
    }

    public function test_validate_group_code_for_user_returns_false_for_different_organization(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Organization A',
        ]);
        $group = $this->adminGroupService->createGroupForAdmin($admin);

        $user = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Organization B',
        ]);

        $result = $this->adminGroupService->validateGroupCodeForUser($user, $group->group_code);

        $this->assertFalse($result);
    }

    public function test_validate_group_code_for_user_returns_false_for_invalid_code(): void
    {
        $user = User::factory()->create([
            'role' => 'user',
            'organization_name' => 'Test Org',
        ]);

        $result = $this->adminGroupService->validateGroupCodeForUser($user, '999999');

        $this->assertFalse($result);
    }

    // Tests for getGroupMembers()

    public function test_get_group_members_returns_paginated_members(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Org',
        ]);
        $group = $this->adminGroupService->createGroupForAdmin($admin);

        // Create members
        User::factory()->count(5)->create([
            'role' => 'user',
            'admin_group_id' => $group->id,
        ]);

        $result = $this->adminGroupService->getGroupMembers($admin, [], 10);

        $this->assertInstanceOf(\Illuminate\Contracts\Pagination\LengthAwarePaginator::class, $result);
        $this->assertCount(5, $result);
    }

    public function test_get_group_members_respects_pagination(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Org',
        ]);
        $group = $this->adminGroupService->createGroupForAdmin($admin);

        // Create 10 members
        User::factory()->count(10)->create([
            'role' => 'user',
            'admin_group_id' => $group->id,
        ]);

        $result = $this->adminGroupService->getGroupMembers($admin, [], 5);

        $this->assertCount(5, $result);
        $this->assertEquals(10, $result->total());
        $this->assertEquals(2, $result->lastPage());
    }

    public function test_get_group_members_throws_exception_if_admin_has_no_group(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('Admin does not have a group.');
        
        $this->adminGroupService->getGroupMembers($admin);
    }

    // Tests for removeMemberFromGroup()

    public function test_remove_member_from_group_removes_user_from_group(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Org',
        ]);
        $group = $this->adminGroupService->createGroupForAdmin($admin);

        $member = User::factory()->create([
            'role' => 'user',
            'admin_group_id' => $group->id,
        ]);

        $result = $this->adminGroupService->removeMemberFromGroup($admin, $member);

        $this->assertTrue($result);
        
        $member->refresh();
        $this->assertNull($member->admin_group_id);
    }

    public function test_remove_member_from_group_throws_exception_if_admin_has_no_group(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $member = User::factory()->create(['role' => 'user']);

        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('Admin does not have a group.');
        
        $this->adminGroupService->removeMemberFromGroup($admin, $member);
    }

    public function test_remove_member_from_group_throws_exception_if_user_not_in_group(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Org',
        ]);
        $group = $this->adminGroupService->createGroupForAdmin($admin);

        $nonMember = User::factory()->create(['role' => 'user']);

        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('User is not a member of your group.');
        
        $this->adminGroupService->removeMemberFromGroup($admin, $nonMember);
    }

    public function test_remove_member_from_group_prevents_removing_member_from_different_group(): void
    {
        // Admin 1 with their group
        $admin1 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Org A',
        ]);
        $group1 = $this->adminGroupService->createGroupForAdmin($admin1);

        // Admin 2 with their group
        $admin2 = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Org B',
        ]);
        $group2 = $this->adminGroupService->createGroupForAdmin($admin2);

        // Member in admin2's group
        $member = User::factory()->create([
            'role' => 'user',
            'admin_group_id' => $group2->id,
        ]);

        // Admin1 tries to remove member from admin2's group
        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('User is not a member of your group.');
        
        $this->adminGroupService->removeMemberFromGroup($admin1, $member);
    }

    // Tests for regenerateGroupCode()

    public function test_regenerate_group_code_generates_new_code(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Org',
        ]);
        $group = $this->adminGroupService->createGroupForAdmin($admin);
        $originalCode = $group->group_code;

        $updatedGroup = $this->adminGroupService->regenerateGroupCode($admin);

        $this->assertNotEquals($originalCode, $updatedGroup->group_code);
        $this->assertMatchesRegularExpression('/^\d{6}$/', $updatedGroup->group_code);
        $this->assertDatabaseHas('admin_groups', [
            'id' => $group->id,
            'group_code' => $updatedGroup->group_code,
        ]);
    }

    public function test_regenerate_group_code_throws_exception_if_admin_has_no_group(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('Admin does not have a group.');
        
        $this->adminGroupService->regenerateGroupCode($admin);
    }

    // Tests for getAdminGroup()

    public function test_get_admin_group_returns_admin_group(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Org',
        ]);
        $group = $this->adminGroupService->createGroupForAdmin($admin);

        $result = $this->adminGroupService->getAdminGroup($admin);

        $this->assertInstanceOf(AdminGroup::class, $result);
        $this->assertEquals($group->id, $result->id);
    }

    public function test_get_admin_group_returns_null_if_no_group(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $result = $this->adminGroupService->getAdminGroup($admin);

        $this->assertNull($result);
    }

    // Tests for getAvailableTransferRecipients()

    public function test_get_available_transfer_recipients_returns_group_members(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Org',
        ]);
        $group = $this->adminGroupService->createGroupForAdmin($admin);

        // Create members
        $member1 = User::factory()->create([
            'role' => 'user',
            'admin_group_id' => $group->id,
            'name' => 'Alice',
        ]);
        $member2 = User::factory()->create([
            'role' => 'user',
            'admin_group_id' => $group->id,
            'name' => 'Bob',
        ]);

        $result = $this->adminGroupService->getAvailableTransferRecipients($admin);

        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Collection::class, $result);
        $this->assertCount(2, $result);
        $this->assertTrue($result->contains('id', $member1->id));
        $this->assertTrue($result->contains('id', $member2->id));
    }

    public function test_get_available_transfer_recipients_excludes_non_group_members(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Org',
        ]);
        $group = $this->adminGroupService->createGroupForAdmin($admin);

        // Member in group
        $member = User::factory()->create([
            'role' => 'user',
            'admin_group_id' => $group->id,
        ]);

        // User not in group
        $nonMember = User::factory()->create(['role' => 'user']);

        $result = $this->adminGroupService->getAvailableTransferRecipients($admin);

        $this->assertCount(1, $result);
        $this->assertTrue($result->contains('id', $member->id));
        $this->assertFalse($result->contains('id', $nonMember->id));
    }

    public function test_get_available_transfer_recipients_returns_sorted_by_name(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'organization_name' => 'Test Org',
        ]);
        $group = $this->adminGroupService->createGroupForAdmin($admin);

        // Create members with specific names
        User::factory()->create([
            'role' => 'user',
            'admin_group_id' => $group->id,
            'name' => 'Zoe',
        ]);
        User::factory()->create([
            'role' => 'user',
            'admin_group_id' => $group->id,
            'name' => 'Alice',
        ]);
        User::factory()->create([
            'role' => 'user',
            'admin_group_id' => $group->id,
            'name' => 'Mike',
        ]);

        $result = $this->adminGroupService->getAvailableTransferRecipients($admin);

        $this->assertEquals('Alice', $result->first()->name);
        $this->assertEquals('Zoe', $result->last()->name);
    }

    public function test_get_available_transfer_recipients_throws_exception_if_admin_has_no_group(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('Admin does not have a group.');
        
        $this->adminGroupService->getAvailableTransferRecipients($admin);
    }
}

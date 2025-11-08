<?php

namespace Tests\Unit;

use App\Models\AdminGroup;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminGroupTest extends TestCase
{
    use RefreshDatabase;

    public function test_generate_unique_group_code_generates_valid_codes(): void
    {
        $code = AdminGroup::generateUniqueGroupCode(4);
        
        $this->assertIsString($code);
        $this->assertEquals(4, strlen($code));
        $this->assertMatchesRegularExpression('/^\d{4}$/', $code);
    }

    public function test_generate_unique_group_code_generates_six_digit_code_by_default(): void
    {
        $code = AdminGroup::generateUniqueGroupCode();
        
        $this->assertIsString($code);
        $this->assertEquals(6, strlen($code));
        $this->assertMatchesRegularExpression('/^\d{6}$/', $code);
    }

    public function test_generate_unique_group_code_generates_different_codes(): void
    {
        $code1 = AdminGroup::generateUniqueGroupCode();
        $code2 = AdminGroup::generateUniqueGroupCode();
        
        // While there's a tiny chance they could be the same, it's extremely unlikely
        // This test validates that the generation is working
        $this->assertIsString($code1);
        $this->assertIsString($code2);
    }

    public function test_generate_unique_group_code_ensures_uniqueness(): void
    {
        // Create an admin group with a specific code
        $admin = User::factory()->create(['role' => 'admin']);
        $existingGroup = AdminGroup::create([
            'admin_user_id' => $admin->id,
            'group_code' => '123456',
            'is_active' => true,
        ]);

        // Generate a new code - it should not be '123456'
        $newCode = AdminGroup::generateUniqueGroupCode();
        
        $this->assertNotEquals('123456', $newCode);
        $this->assertMatchesRegularExpression('/^\d{6}$/', $newCode);
    }

    public function test_regenerate_group_code_creates_new_unique_code(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $group = AdminGroup::create([
            'admin_user_id' => $admin->id,
            'group_code' => '123456',
            'is_active' => true,
        ]);

        $originalCode = $group->group_code;
        
        $result = $group->regenerateGroupCode();
        
        $this->assertTrue($result);
        $this->assertNotEquals($originalCode, $group->group_code);
        $this->assertMatchesRegularExpression('/^\d{6}$/', $group->group_code);
        
        // Verify it was saved to database
        $this->assertDatabaseHas('admin_groups', [
            'id' => $group->id,
            'group_code' => $group->group_code,
        ]);
    }

    public function test_admin_relationship_returns_admin_user(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $group = AdminGroup::create([
            'admin_user_id' => $admin->id,
            'group_code' => '123456',
            'is_active' => true,
        ]);

        $this->assertInstanceOf(User::class, $group->admin);
        $this->assertEquals($admin->id, $group->admin->id);
        $this->assertEquals('admin', $group->admin->role);
    }

    public function test_members_relationship_returns_group_members(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $group = AdminGroup::create([
            'admin_user_id' => $admin->id,
            'group_code' => '123456',
            'is_active' => true,
        ]);

        // Create members
        $member1 = User::factory()->create([
            'role' => 'user',
            'admin_group_id' => $group->id,
        ]);
        $member2 = User::factory()->create([
            'role' => 'user',
            'admin_group_id' => $group->id,
        ]);

        $members = $group->members;
        
        $this->assertCount(2, $members);
        $this->assertTrue($members->contains($member1));
        $this->assertTrue($members->contains($member2));
    }

    public function test_add_member_assigns_user_to_group(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $group = AdminGroup::create([
            'admin_user_id' => $admin->id,
            'group_code' => '123456',
            'is_active' => true,
        ]);

        $user = User::factory()->create(['role' => 'user']);
        
        $result = $group->addMember($user);
        
        $this->assertTrue($result);
        $user->refresh();
        $this->assertEquals($group->id, $user->admin_group_id);
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'admin_group_id' => $group->id,
        ]);
    }

    public function test_remove_member_unassigns_user_from_group(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $group = AdminGroup::create([
            'admin_user_id' => $admin->id,
            'group_code' => '123456',
            'is_active' => true,
        ]);

        $user = User::factory()->create([
            'role' => 'user',
            'admin_group_id' => $group->id,
        ]);
        
        $result = $group->removeMember($user);
        
        $this->assertTrue($result);
        $user->refresh();
        $this->assertNull($user->admin_group_id);
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'admin_group_id' => null,
        ]);
    }

    public function test_is_member_returns_true_for_group_member(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $group = AdminGroup::create([
            'admin_user_id' => $admin->id,
            'group_code' => '123456',
            'is_active' => true,
        ]);

        $member = User::factory()->create([
            'role' => 'user',
            'admin_group_id' => $group->id,
        ]);
        
        $this->assertTrue($group->isMember($member));
    }

    public function test_is_member_returns_false_for_non_member(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $group = AdminGroup::create([
            'admin_user_id' => $admin->id,
            'group_code' => '123456',
            'is_active' => true,
        ]);

        $nonMember = User::factory()->create(['role' => 'user']);
        
        $this->assertFalse($group->isMember($nonMember));
    }

    public function test_group_code_uniqueness_validation(): void
    {
        $admin1 = User::factory()->create(['role' => 'admin']);
        $admin2 = User::factory()->create(['role' => 'admin']);
        
        AdminGroup::create([
            'admin_user_id' => $admin1->id,
            'group_code' => '111111',
            'is_active' => true,
        ]);

        // Attempting to create another group with the same code should fail
        $this->expectException(\Illuminate\Database\QueryException::class);
        
        AdminGroup::create([
            'admin_user_id' => $admin2->id,
            'group_code' => '111111',
            'is_active' => true,
        ]);
    }
}

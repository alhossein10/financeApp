<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\AdminGroup;
use App\Models\Expense;
use App\Models\Transfer;
use App\Models\Incoming;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminGroupSeeder extends Seeder
{
    /**
     * Run the database seeds for admin group management testing.
     * Creates multiple admin users with groups and regular users assigned to different groups.
     */
    public function run(): void
    {
        $this->command->info('Creating admin groups and test data...');

        // ========================================
        // Organization 1: TechCorp
        // ========================================
        
        // Admin 1: Alice (TechCorp - Engineering)
        $admin1 = User::create([
            'name' => 'Alice Johnson',
            'email' => 'alice.admin@techcorp.com',
            'password' => Hash::make('password123'),
            'role' => 'admin',
            'organization_name' => 'TechCorp',
            'department_name' => 'Engineering',
            'email_verified_at' => now(),
        ]);

        $group1 = AdminGroup::create([
            'admin_user_id' => $admin1->id,
            'group_code' => '123456',
            'group_name' => 'TechCorp Engineering Team',
            'is_active' => true,
        ]);

        $this->command->info("Created Admin 1: {$admin1->email} with group code: {$group1->group_code}");

        // Regular users for Admin 1's group
        $user1 = User::create([
            'name' => 'Bob Smith',
            'email' => 'bob.user@techcorp.com',
            'password' => Hash::make('password123'),
            'role' => 'user',
            'organization_name' => 'TechCorp',
            'department_name' => 'Engineering',
            'admin_group_id' => $group1->id,
            'email_verified_at' => now(),
        ]);

        $user2 = User::create([
            'name' => 'Carol Davis',
            'email' => 'carol.user@techcorp.com',
            'password' => Hash::make('password123'),
            'role' => 'user',
            'organization_name' => 'TechCorp',
            'department_name' => 'Engineering',
            'admin_group_id' => $group1->id,
            'email_verified_at' => now(),
        ]);

        $this->command->info("Created 2 users for Admin 1's group");

        // Create expenses for Admin 1's group members
        Expense::factory()->count(10)->create(['user_id' => $user1->id]);
        Expense::factory()->count(8)->create(['user_id' => $user2->id]);

        // Create transfers for Admin 1's group members
        Transfer::factory()->count(5)->create(['user_id' => $user1->id]);
        Transfer::factory()->count(4)->create(['user_id' => $user2->id]);

        // Create incoming transactions for Admin 1's group members
        Incoming::factory()->count(6)->create(['user_id' => $user1->id]);
        Incoming::factory()->count(5)->create(['user_id' => $user2->id]);

        $this->command->info("Created financial data for Admin 1's group");

        // ========================================
        // Organization 1: TechCorp (Different Department)
        // ========================================
        
        // Admin 2: David (TechCorp - Marketing)
        $admin2 = User::create([
            'name' => 'David Wilson',
            'email' => 'david.admin@techcorp.com',
            'password' => Hash::make('password123'),
            'role' => 'admin',
            'organization_name' => 'TechCorp',
            'department_name' => 'Marketing',
            'email_verified_at' => now(),
        ]);

        $group2 = AdminGroup::create([
            'admin_user_id' => $admin2->id,
            'group_code' => '789012',
            'group_name' => 'TechCorp Marketing Team',
            'is_active' => true,
        ]);

        $this->command->info("Created Admin 2: {$admin2->email} with group code: {$group2->group_code}");

        // Regular users for Admin 2's group
        $user3 = User::create([
            'name' => 'Emma Brown',
            'email' => 'emma.user@techcorp.com',
            'password' => Hash::make('password123'),
            'role' => 'user',
            'organization_name' => 'TechCorp',
            'department_name' => 'Marketing',
            'admin_group_id' => $group2->id,
            'email_verified_at' => now(),
        ]);

        $user4 = User::create([
            'name' => 'Frank Miller',
            'email' => 'frank.user@techcorp.com',
            'password' => Hash::make('password123'),
            'role' => 'user',
            'organization_name' => 'TechCorp',
            'department_name' => 'Marketing',
            'admin_group_id' => $group2->id,
            'email_verified_at' => now(),
        ]);

        $this->command->info("Created 2 users for Admin 2's group");

        // Create expenses for Admin 2's group members
        Expense::factory()->count(12)->create(['user_id' => $user3->id]);
        Expense::factory()->count(9)->create(['user_id' => $user4->id]);

        // Create transfers for Admin 2's group members
        Transfer::factory()->count(6)->create(['user_id' => $user3->id]);
        Transfer::factory()->count(3)->create(['user_id' => $user4->id]);

        // Create incoming transactions for Admin 2's group members
        Incoming::factory()->count(7)->create(['user_id' => $user3->id]);
        Incoming::factory()->count(4)->create(['user_id' => $user4->id]);

        $this->command->info("Created financial data for Admin 2's group");

        // ========================================
        // Organization 2: GlobalFinance
        // ========================================
        
        // Admin 3: Grace (GlobalFinance - Operations)
        $admin3 = User::create([
            'name' => 'Grace Lee',
            'email' => 'grace.admin@globalfinance.com',
            'password' => Hash::make('password123'),
            'role' => 'admin',
            'organization_name' => 'GlobalFinance',
            'department_name' => 'Operations',
            'email_verified_at' => now(),
        ]);

        $group3 = AdminGroup::create([
            'admin_user_id' => $admin3->id,
            'group_code' => '345678',
            'group_name' => 'GlobalFinance Operations Team',
            'is_active' => true,
        ]);

        $this->command->info("Created Admin 3: {$admin3->email} with group code: {$group3->group_code}");

        // Regular users for Admin 3's group
        $user5 = User::create([
            'name' => 'Henry Taylor',
            'email' => 'henry.user@globalfinance.com',
            'password' => Hash::make('password123'),
            'role' => 'user',
            'organization_name' => 'GlobalFinance',
            'department_name' => 'Operations',
            'admin_group_id' => $group3->id,
            'email_verified_at' => now(),
        ]);

        $user6 = User::create([
            'name' => 'Iris Chen',
            'email' => 'iris.user@globalfinance.com',
            'password' => Hash::make('password123'),
            'role' => 'user',
            'organization_name' => 'GlobalFinance',
            'department_name' => 'Operations',
            'admin_group_id' => $group3->id,
            'email_verified_at' => now(),
        ]);

        $this->command->info("Created 2 users for Admin 3's group");

        // Create expenses for Admin 3's group members
        Expense::factory()->count(15)->create(['user_id' => $user5->id]);
        Expense::factory()->count(11)->create(['user_id' => $user6->id]);

        // Create transfers for Admin 3's group members
        Transfer::factory()->count(7)->create(['user_id' => $user5->id]);
        Transfer::factory()->count(5)->create(['user_id' => $user6->id]);

        // Create incoming transactions for Admin 3's group members
        Incoming::factory()->count(8)->create(['user_id' => $user5->id]);
        Incoming::factory()->count(6)->create(['user_id' => $user6->id]);

        $this->command->info("Created financial data for Admin 3's group");

        // ========================================
        // Unassigned User (No Group)
        // ========================================
        
        $unassignedUser = User::create([
            'name' => 'Jack Robinson',
            'email' => 'jack.user@techcorp.com',
            'password' => Hash::make('password123'),
            'role' => 'user',
            'organization_name' => 'TechCorp',
            'department_name' => 'Sales',
            'admin_group_id' => null,
            'email_verified_at' => now(),
        ]);

        // Create some data for unassigned user
        Expense::factory()->count(5)->create(['user_id' => $unassignedUser->id]);
        Transfer::factory()->count(2)->create(['user_id' => $unassignedUser->id]);
        Incoming::factory()->count(3)->create(['user_id' => $unassignedUser->id]);

        $this->command->info("Created unassigned user: {$unassignedUser->email}");

        // ========================================
        // Summary
        // ========================================
        
        $this->command->info('');
        $this->command->info('=== Admin Group Seeding Summary ===');
        $this->command->info('');
        $this->command->info('Organization: TechCorp');
        $this->command->info("  Admin 1: alice.admin@techcorp.com (Group: {$group1->group_code})");
        $this->command->info('    - bob.user@techcorp.com');
        $this->command->info('    - carol.user@techcorp.com');
        $this->command->info("  Admin 2: david.admin@techcorp.com (Group: {$group2->group_code})");
        $this->command->info('    - emma.user@techcorp.com');
        $this->command->info('    - frank.user@techcorp.com');
        $this->command->info('');
        $this->command->info('Organization: GlobalFinance');
        $this->command->info("  Admin 3: grace.admin@globalfinance.com (Group: {$group3->group_code})");
        $this->command->info('    - henry.user@globalfinance.com');
        $this->command->info('    - iris.user@globalfinance.com');
        $this->command->info('');
        $this->command->info('Unassigned Users:');
        $this->command->info('  - jack.user@techcorp.com (No group)');
        $this->command->info('');
        $this->command->info('All passwords: password123');
        $this->command->info('');
        $this->command->info('Admin group seeding completed successfully!');
    }
}

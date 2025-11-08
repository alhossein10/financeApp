<?php

namespace Database\Seeders;

use App\Models\Department;
use App\Models\Organization;
use Illuminate\Database\Seeder;

class OrganizationSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Create or get initial organization
        $organization = Organization::firstOrCreate(
            ['name' => 'هيئة الاتصالات']
        );

        // Create initial departments if they don't exist
        $departments = [
            'إدارة الإشارة',
            'إدارة المعلوماتية',
            'إدارة الشبكات',
            'إدارة الحرب الالكترونية',
        ];

        foreach ($departments as $departmentName) {
            Department::firstOrCreate([
                'organization_id' => $organization->id,
                'name' => $departmentName,
            ]);
        }
    }
}

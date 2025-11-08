<?php

namespace Database\Seeders;

use App\Models\Department;
use App\Models\Organization;
use Illuminate\Database\Seeder;

class AdditionalOrganizationsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Create الديوان العام organization
        $org2 = Organization::create([
            'name' => 'الديوان العام',
        ]);

        // Create departments for الديوان العام
        $departments = [
            'إدارة المعلوماتية',
            'إدارة الموارد البشرية',
            'إدارة المالية',
            'إدارة الإشارة',
            'إدارة الشبكات',
            'إدارة الحرب الالكترونية',
        ];

        foreach ($departments as $departmentName) {
            Department::create([
                'organization_id' => $org2->id,
                'name' => $departmentName,
            ]);
        }

        // Create هيئة الطيران organization
        $org3 = Organization::create([
            'name' => 'هيئة الطيران',
        ]);

        // Create departments for هيئة الطيران
        foreach ($departments as $departmentName) {
            Department::create([
                'organization_id' => $org3->id,
                'name' => $departmentName,
            ]);
        }
    }
}

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // First, ensure we have a default organization
        $orgId = DB::table('organizations')->insertGetId([
            'name' => 'هيئة الاتصالات',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Create default department
        $deptId = DB::table('departments')->insertGetId([
            'organization_id' => $orgId,
            'name' => 'إدارة المعلوماتية',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Update all existing users to belong to the default organization
        DB::table('users')->update([
            'organization_id' => $orgId,
            'department_id' => $deptId,
        ]);

        // Update all existing expenses
        if (DB::getSchemaBuilder()->hasTable('expenses')) {
            DB::table('expenses')->update([
                'organization_id' => $orgId,
                'department_id' => $deptId,
            ]);
        }

        // Update all existing transfers
        if (DB::getSchemaBuilder()->hasTable('transfers')) {
            DB::table('transfers')->update([
                'organization_id' => $orgId,
                'department_id' => $deptId,
            ]);
        }

        // Update all existing incoming records
        if (DB::getSchemaBuilder()->hasTable('incomings')) {
            DB::table('incomings')->update([
                'organization_id' => $orgId,
                'department_id' => $deptId,
            ]);
        }

        // Update all existing fund_boxes
        if (DB::getSchemaBuilder()->hasTable('fund_boxes')) {
            DB::table('fund_boxes')->update([
                'organization_id' => $orgId,
                'department_id' => $deptId,
            ]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // No need to reverse this data migration
    }
};

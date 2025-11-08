<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Add new text-based organization and department fields
            $table->string('organization_name', 255)->nullable()->after('role');
            $table->string('department_name', 255)->nullable()->after('organization_name');
            
            // Add admin_group_id field
            $table->unsignedBigInteger('admin_group_id')->nullable()->after('department_name');
            
            // Add indexes for performance
            $table->index('organization_name');
            $table->index('admin_group_id');
        });

        // Migrate existing organization_id and department_id data to new text fields
        DB::statement('
            UPDATE users u
            LEFT JOIN organizations o ON u.organization_id = o.id
            SET u.organization_name = o.name
            WHERE u.organization_id IS NOT NULL AND o.name IS NOT NULL
        ');

        DB::statement('
            UPDATE users u
            LEFT JOIN departments d ON u.department_id = d.id
            SET u.department_name = d.name
            WHERE u.department_id IS NOT NULL AND d.name IS NOT NULL
        ');

        // Make old organization_id and department_id nullable for backward compatibility
        Schema::table('users', function (Blueprint $table) {
            $table->unsignedBigInteger('organization_id')->nullable()->change();
            $table->unsignedBigInteger('department_id')->nullable()->change();
        });

        // Add foreign key for admin_group_id
        Schema::table('users', function (Blueprint $table) {
            $table->foreign('admin_group_id')
                  ->references('id')
                  ->on('admin_groups')
                  ->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Before dropping columns, attempt to restore organization_id and department_id
        // from organization_name and department_name if possible
        DB::statement('
            UPDATE users u
            INNER JOIN organizations o ON LOWER(u.organization_name) = LOWER(o.name)
            SET u.organization_id = o.id
            WHERE u.organization_name IS NOT NULL 
            AND u.organization_id IS NULL
        ');

        DB::statement('
            UPDATE users u
            INNER JOIN departments d ON LOWER(u.department_name) = LOWER(d.name)
            INNER JOIN organizations o ON u.organization_id = o.id
            SET u.department_id = d.id
            WHERE u.department_name IS NOT NULL 
            AND u.department_id IS NULL
            AND d.organization_id = o.id
        ');

        Schema::table('users', function (Blueprint $table) {
            // Drop foreign key
            $table->dropForeign(['admin_group_id']);
            
            // Drop indexes
            $table->dropIndex(['organization_name']);
            $table->dropIndex(['admin_group_id']);
            
            // Drop new columns
            $table->dropColumn(['organization_name', 'department_name', 'admin_group_id']);
        });

        // Note: organization_id and department_id remain nullable after rollback
        // Run the restore_organization_department_constraints migration to make them NOT NULL
        // after ensuring all users have valid organization and department assignments
    }
};

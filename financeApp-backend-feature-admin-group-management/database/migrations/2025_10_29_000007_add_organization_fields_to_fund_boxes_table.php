<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('fund_boxes', function (Blueprint $table) {
            if (!Schema::hasColumn('fund_boxes', 'organization_id')) {
                $table->unsignedBigInteger('organization_id')->after('id')->default(1);
                $table->index('organization_id');
            }
            
            if (!Schema::hasColumn('fund_boxes', 'department_id')) {
                $table->unsignedBigInteger('department_id')->nullable()->after('organization_id');
                $table->index('department_id');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('fund_boxes', function (Blueprint $table) {
            $table->dropIndex(['organization_id']);
            $table->dropIndex(['department_id']);
            $table->dropColumn(['organization_id', 'department_id']);
        });
    }
};

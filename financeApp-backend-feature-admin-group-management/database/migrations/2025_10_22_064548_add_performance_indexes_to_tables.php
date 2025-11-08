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
        // Add sync_status index to transfers table
        Schema::table('transfers', function (Blueprint $table) {
            $table->index('sync_status');
        });

        // Add sync_status index to incomings table
        Schema::table('incomings', function (Blueprint $table) {
            $table->index('sync_status');
        });

        // Add composite index for audit logs filtering
        Schema::table('audit_logs', function (Blueprint $table) {
            $table->index(['action', 'created_at']);
            $table->index(['resource_type', 'resource_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Drop indexes from transfers table
        Schema::table('transfers', function (Blueprint $table) {
            $table->dropIndex(['sync_status']);
        });

        // Drop indexes from incomings table
        Schema::table('incomings', function (Blueprint $table) {
            $table->dropIndex(['sync_status']);
        });

        // Drop indexes from audit_logs table
        Schema::table('audit_logs', function (Blueprint $table) {
            $table->dropIndex(['action', 'created_at']);
            $table->dropIndex(['resource_type', 'resource_id']);
        });
    }
};

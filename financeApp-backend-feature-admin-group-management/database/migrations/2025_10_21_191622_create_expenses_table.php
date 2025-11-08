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
        Schema::create('expenses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->text('description');
            $table->decimal('price_usd', 10, 2);
            $table->decimal('price_syp', 15, 2)->nullable();
            $table->decimal('price_try', 10, 2)->nullable();
            $table->boolean('has_invoice')->default(false);
            $table->string('invoice_path')->nullable();
            $table->date('expense_date');
            $table->enum('sync_status', ['pending', 'syncing', 'synced', 'failed'])->default('synced');
            $table->timestamp('synced_at')->nullable();
            $table->integer('sync_retry_count')->default(0);
            $table->text('sync_error_message')->nullable();
            $table->timestamps();
            $table->softDeletes();
            
            // Indexes
            $table->index(['user_id', 'expense_date']);
            $table->index('sync_status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('expenses');
    }
};

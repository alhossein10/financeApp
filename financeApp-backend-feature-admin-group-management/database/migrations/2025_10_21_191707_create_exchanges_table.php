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
        Schema::create('exchanges', function (Blueprint $table) {
            $table->id();
            $table->foreignId('transfer_id')->unique()->constrained()->onDelete('cascade');
            $table->decimal('converted_amount_syp', 15, 2)->nullable();
            $table->decimal('converted_amount_try', 10, 2)->nullable();
            $table->decimal('exchange_rate_usd_to_syp', 10, 4)->nullable();
            $table->decimal('exchange_rate_usd_to_try', 10, 4)->nullable();
            $table->date('exchange_date');
            $table->timestamps();
            
            // Index
            $table->index('transfer_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('exchanges');
    }
};

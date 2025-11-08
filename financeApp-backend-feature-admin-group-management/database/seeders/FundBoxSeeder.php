<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class FundBoxSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        \App\Models\FundBox::firstOrCreate(
            ['id' => 1],
            [
                'balance_usd' => 0.00,
                'last_calculated_at' => null,
            ]
        );
    }
}

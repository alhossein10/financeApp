<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Expense;
use App\Models\Transfer;
use App\Models\Exchange;
use App\Models\Incoming;
use Illuminate\Database\Seeder;

class DevelopmentSeeder extends Seeder
{
    /**
     * Run the database seeds for development environment.
     * Creates sample data for testing and development.
     */
    public function run(): void
    {
        $this->command->info('Creating development data...');

        // Create test users
        $regularUser = User::factory()->create([
            'name' => 'John Doe',
            'email' => 'user@finance.local',
            'role' => 'user',
        ]);

        $anotherUser = User::factory()->create([
            'name' => 'Jane Smith',
            'email' => 'jane@finance.local',
            'role' => 'user',
        ]);

        $this->command->info('Created test users: user@finance.local, jane@finance.local');

        // Create expenses for regular user
        Expense::factory()->count(15)->create([
            'user_id' => $regularUser->id,
        ]);

        // Create some expenses with invoices
        Expense::factory()->count(5)->create([
            'user_id' => $regularUser->id,
            'has_invoice' => true,
            'invoice_path' => 'invoices/sample-invoice.jpg',
        ]);

        $this->command->info('Created 20 expenses for John Doe');

        // Create expenses for another user
        Expense::factory()->count(10)->create([
            'user_id' => $anotherUser->id,
        ]);

        $this->command->info('Created 10 expenses for Jane Smith');

        // Create transfers for regular user
        $transfers = Transfer::factory()->count(8)->create([
            'user_id' => $regularUser->id,
        ]);

        // Add exchange data to some transfers
        foreach ($transfers->take(4) as $transfer) {
            Exchange::factory()->create([
                'transfer_id' => $transfer->id,
            ]);
        }

        $this->command->info('Created 8 transfers (4 with exchange data) for John Doe');

        // Create transfers for another user
        Transfer::factory()->count(5)->create([
            'user_id' => $anotherUser->id,
        ]);

        $this->command->info('Created 5 transfers for Jane Smith');

        // Create incoming transactions
        Incoming::factory()->count(12)->create([
            'user_id' => $regularUser->id,
        ]);

        Incoming::factory()->count(7)->create([
            'user_id' => $anotherUser->id,
        ]);

        $this->command->info('Created incoming transactions for both users');

        $this->command->info('Development data seeding completed!');
    }
}

<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     * 
     * This seeder runs essential seeders for all environments,
     * and optionally runs development seeders in non-production environments.
     */
    public function run(): void
    {
        $this->command->info('Starting database seeding...');

        // Essential seeders for all environments
        $this->call([
            FundBoxSeeder::class,
            AdminUserSeeder::class,
        ]);

        // Development/testing seeders (only in non-production)
        if (!app()->environment('production')) {
            $this->command->info('Running development seeders...');
            $this->call([
                DevelopmentSeeder::class,
                AdminGroupSeeder::class,
            ]);
        }

        $this->command->info('Database seeding completed successfully!');
    }
}

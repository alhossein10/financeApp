<?php

namespace Database\Factories;

use App\Models\Expense;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Expense>
 */
class ExpenseFactory extends Factory
{
    protected $model = Expense::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'description' => fake()->sentence(),
            'price_usd' => fake()->randomFloat(2, 10, 1000),
            'price_syp' => fake()->optional()->randomFloat(2, 1000, 100000),
            'price_try' => fake()->optional()->randomFloat(2, 100, 10000),
            'has_invoice' => false,
            'invoice_path' => null,
            'expense_date' => fake()->dateTimeBetween('-1 year', 'now'),
            'sync_status' => 'synced',
            'synced_at' => now(),
            'sync_retry_count' => 0,
            'sync_error_message' => null,
        ];
    }

    /**
     * Indicate that the expense has an invoice.
     */
    public function withInvoice(): static
    {
        return $this->state(fn (array $attributes) => [
            'has_invoice' => true,
            'invoice_path' => 'invoices/' . fake()->uuid() . '.jpg',
        ]);
    }

    /**
     * Indicate that the expense is pending sync.
     */
    public function pendingSync(): static
    {
        return $this->state(fn (array $attributes) => [
            'sync_status' => 'pending',
            'synced_at' => null,
        ]);
    }

    /**
     * Indicate that the expense sync failed.
     */
    public function syncFailed(): static
    {
        return $this->state(fn (array $attributes) => [
            'sync_status' => 'failed',
            'sync_retry_count' => fake()->numberBetween(1, 5),
            'sync_error_message' => fake()->sentence(),
        ]);
    }
}

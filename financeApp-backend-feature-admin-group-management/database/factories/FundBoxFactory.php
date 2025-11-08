<?php

namespace Database\Factories;

use App\Models\FundBox;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\FundBox>
 */
class FundBoxFactory extends Factory
{
    /**
     * The name of the factory's corresponding model.
     *
     * @var string
     */
    protected $model = FundBox::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'id' => 1, // Always use ID 1 for single-row table
            'balance_usd' => fake()->randomFloat(2, 0, 100000),
            'last_calculated_at' => fake()->optional()->dateTimeBetween('-1 month', 'now'),
        ];
    }

    /**
     * Indicate that the fund box has zero balance.
     */
    public function empty(): static
    {
        return $this->state(fn (array $attributes) => [
            'balance_usd' => 0.00,
            'last_calculated_at' => null,
        ]);
    }
}

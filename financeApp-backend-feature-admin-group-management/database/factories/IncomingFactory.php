<?php

namespace Database\Factories;

use App\Models\Incoming;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Incoming>
 */
class IncomingFactory extends Factory
{
    /**
     * The name of the factory's corresponding model.
     *
     * @var string
     */
    protected $model = Incoming::class;

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
            'amount_usd' => fake()->randomFloat(2, 10, 10000),
            'incoming_date' => fake()->dateTimeBetween('-1 year', 'now'),
            'sync_status' => fake()->randomElement(['pending', 'syncing', 'synced', 'failed']),
            'synced_at' => fake()->optional()->dateTimeBetween('-1 year', 'now'),
        ];
    }

    /**
     * Indicate that the incoming record is synced.
     *
     * @return static
     */
    public function synced(): static
    {
        return $this->state(fn (array $attributes) => [
            'sync_status' => 'synced',
            'synced_at' => now(),
        ]);
    }

    /**
     * Indicate that the incoming record is pending sync.
     *
     * @return static
     */
    public function pending(): static
    {
        return $this->state(fn (array $attributes) => [
            'sync_status' => 'pending',
            'synced_at' => null,
        ]);
    }

    /**
     * Indicate that the incoming record has failed sync.
     *
     * @return static
     */
    public function failed(): static
    {
        return $this->state(fn (array $attributes) => [
            'sync_status' => 'failed',
            'synced_at' => null,
        ]);
    }
}

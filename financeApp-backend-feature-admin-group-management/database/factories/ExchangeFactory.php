<?php

namespace Database\Factories;

use App\Models\Exchange;
use App\Models\Transfer;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Exchange>
 */
class ExchangeFactory extends Factory
{
    /**
     * The name of the factory's corresponding model.
     *
     * @var string
     */
    protected $model = Exchange::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $hasSyp = fake()->boolean(70);
        $hasTry = fake()->boolean(70);

        return [
            'transfer_id' => Transfer::factory(),
            'converted_amount_syp' => $hasSyp ? fake()->randomFloat(2, 100, 1000000) : null,
            'converted_amount_try' => $hasTry ? fake()->randomFloat(2, 100, 100000) : null,
            'exchange_rate_usd_to_syp' => $hasSyp ? fake()->randomFloat(4, 10000, 15000) : null,
            'exchange_rate_usd_to_try' => $hasTry ? fake()->randomFloat(4, 25, 35) : null,
            'exchange_date' => fake()->dateTimeBetween('-1 year', 'now'),
        ];
    }

    /**
     * Indicate that the exchange is for SYP only.
     *
     * @return static
     */
    public function sypOnly(): static
    {
        return $this->state(fn (array $attributes) => [
            'converted_amount_syp' => fake()->randomFloat(2, 100, 1000000),
            'exchange_rate_usd_to_syp' => fake()->randomFloat(4, 10000, 15000),
            'converted_amount_try' => null,
            'exchange_rate_usd_to_try' => null,
        ]);
    }

    /**
     * Indicate that the exchange is for TRY only.
     *
     * @return static
     */
    public function tryOnly(): static
    {
        return $this->state(fn (array $attributes) => [
            'converted_amount_try' => fake()->randomFloat(2, 100, 100000),
            'exchange_rate_usd_to_try' => fake()->randomFloat(4, 25, 35),
            'converted_amount_syp' => null,
            'exchange_rate_usd_to_syp' => null,
        ]);
    }

    /**
     * Indicate that the exchange has both currencies.
     *
     * @return static
     */
    public function bothCurrencies(): static
    {
        return $this->state(fn (array $attributes) => [
            'converted_amount_syp' => fake()->randomFloat(2, 100, 1000000),
            'exchange_rate_usd_to_syp' => fake()->randomFloat(4, 10000, 15000),
            'converted_amount_try' => fake()->randomFloat(2, 100, 100000),
            'exchange_rate_usd_to_try' => fake()->randomFloat(4, 25, 35),
        ]);
    }
}

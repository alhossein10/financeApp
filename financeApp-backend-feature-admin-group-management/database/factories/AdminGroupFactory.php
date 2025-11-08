<?php

namespace Database\Factories;

use App\Models\AdminGroup;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\AdminGroup>
 */
class AdminGroupFactory extends Factory
{
    protected $model = AdminGroup::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'admin_user_id' => User::factory()->create(['role' => 'admin']),
            'group_code' => $this->generateUniqueGroupCode(),
            'group_name' => fake()->company() . ' Group',
            'is_active' => true,
        ];
    }

    /**
     * Generate a unique group code.
     */
    private function generateUniqueGroupCode(): string
    {
        do {
            $code = str_pad((string) fake()->numberBetween(1000, 999999), 4, '0', STR_PAD_LEFT);
        } while (AdminGroup::where('group_code', $code)->exists());

        return $code;
    }

    /**
     * Indicate that the group is inactive.
     */
    public function inactive(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_active' => false,
        ]);
    }
}

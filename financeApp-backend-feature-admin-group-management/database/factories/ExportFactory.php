<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Export>
 */
class ExportFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $type = fake()->randomElement(['pdf', 'xlsx']);
        $fileName = 'export_' . time() . '_' . uniqid() . '.' . $type;
        
        return [
            'user_id' => \App\Models\User::factory(),
            'type' => $type,
            'resource_type' => fake()->randomElement(['expenses', 'system_wide']),
            'file_path' => 'exports/' . $fileName,
            'file_name' => $fileName,
            'filters' => [],
            'status' => 'completed',
            'error_message' => null,
            'expires_at' => now()->addHours(24),
        ];
    }

    /**
     * Indicate that the export is pending.
     */
    public function pending(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'pending',
        ]);
    }

    /**
     * Indicate that the export is processing.
     */
    public function processing(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'processing',
        ]);
    }

    /**
     * Indicate that the export has failed.
     */
    public function failed(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'failed',
            'error_message' => 'Export generation failed',
        ]);
    }

    /**
     * Indicate that the export is expired.
     */
    public function expired(): static
    {
        return $this->state(fn (array $attributes) => [
            'expires_at' => now()->subHours(1),
        ]);
    }
}

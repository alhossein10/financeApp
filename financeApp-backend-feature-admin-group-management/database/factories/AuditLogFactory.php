<?php

namespace Database\Factories;

use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\AuditLog>
 */
class AuditLogFactory extends Factory
{
    /**
     * The name of the factory's corresponding model.
     *
     * @var string
     */
    protected $model = AuditLog::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $resourceTypes = ['Expense', 'Transfer', 'Incoming', 'FundBox', 'User'];
        $actions = ['create', 'update', 'delete', 'view'];

        return [
            'user_id' => User::factory(),
            'action' => fake()->randomElement($actions),
            'resource_type' => fake()->randomElement($resourceTypes),
            'resource_id' => fake()->numberBetween(1, 100),
            'ip_address' => fake()->ipv4(),
            'user_agent' => fake()->userAgent(),
            'metadata' => [
                'changes' => fake()->optional()->words(3, true),
                'timestamp' => now()->toIso8601String(),
            ],
        ];
    }

    /**
     * Indicate that the audit log is for a failed authentication.
     */
    public function failedAuth(): static
    {
        return $this->state(fn (array $attributes) => [
            'user_id' => null,
            'action' => 'failed_login',
            'resource_type' => 'Auth',
            'resource_id' => null,
            'metadata' => [
                'email' => fake()->email(),
                'reason' => 'Invalid credentials',
            ],
        ]);
    }

    /**
     * Indicate that the audit log is for data access by admin.
     */
    public function adminAccess(): static
    {
        return $this->state(fn (array $attributes) => [
            'action' => 'view',
            'metadata' => [
                'admin_access' => true,
                'accessed_user_id' => fake()->numberBetween(1, 100),
            ],
        ]);
    }
}

<?php

namespace Tests\Feature;

use App\Models\AuditLog;
use App\Models\Expense;
use App\Models\Incoming;
use App\Models\Transfer;
use App\Models\User;
use App\Services\AuditLogService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuditLogTest extends TestCase
{
    use RefreshDatabase;

    // ========== AUTOMATIC LOGGING ON MODEL EVENTS ==========

    public function test_expense_creation_is_automatically_logged(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/expenses', [
                'description' => 'Test expense',
                'price_usd' => 100.00,
                'expense_date' => '2025-10-20',
            ]);

        $this->assertDatabaseHas('audit_logs', [
            'user_id' => $user->id,
            'action' => 'create',
            'resource_type' => 'Expense',
        ]);

        $log = AuditLog::where('action', 'create')
            ->where('resource_type', 'Expense')
            ->first();

        $this->assertNotNull($log);
        $this->assertEquals($user->id, $log->user_id);
        $this->assertIsArray($log->metadata);
        $this->assertArrayHasKey('description', $log->metadata);
        $this->assertEquals('Test expense', $log->metadata['description']);
    }

    public function test_expense_update_is_automatically_logged(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'description' => 'Original',
        ]);

        $this->actingAs($user, 'sanctum')
            ->putJson("/api/v1/expenses/{$expense->id}", [
                'description' => 'Updated',
            ]);

        $this->assertDatabaseHas('audit_logs', [
            'user_id' => $user->id,
            'action' => 'update',
            'resource_type' => 'Expense',
            'resource_id' => $expense->id,
        ]);

        $log = AuditLog::where('action', 'update')
            ->where('resource_type', 'Expense')
            ->where('resource_id', $expense->id)
            ->first();

        $this->assertNotNull($log);
        $this->assertArrayHasKey('changes', $log->metadata);
    }

    public function test_expense_deletion_is_automatically_logged(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        $this->actingAs($user, 'sanctum')
            ->deleteJson("/api/v1/expenses/{$expense->id}");

        $this->assertDatabaseHas('audit_logs', [
            'user_id' => $user->id,
            'action' => 'delete',
            'resource_type' => 'Expense',
            'resource_id' => $expense->id,
        ]);
    }

    public function test_transfer_creation_is_automatically_logged(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/transfers', [
                'recipient_name' => 'John Doe',
                'amount_usd' => 500.00,
                'transfer_date' => '2025-10-20',
            ]);

        $this->assertDatabaseHas('audit_logs', [
            'user_id' => $user->id,
            'action' => 'create',
            'resource_type' => 'Transfer',
        ]);

        $log = AuditLog::where('action', 'create')
            ->where('resource_type', 'Transfer')
            ->first();

        $this->assertNotNull($log);
        $this->assertArrayHasKey('recipient_name', $log->metadata);
        $this->assertEquals('John Doe', $log->metadata['recipient_name']);
    }

    public function test_transfer_update_is_automatically_logged(): void
    {
        $user = User::factory()->create();
        $transfer = Transfer::factory()->create([
            'user_id' => $user->id,
            'recipient_name' => 'Original Name',
        ]);

        $this->actingAs($user, 'sanctum')
            ->putJson("/api/v1/transfers/{$transfer->id}", [
                'recipient_name' => 'Updated Name',
            ]);

        $this->assertDatabaseHas('audit_logs', [
            'user_id' => $user->id,
            'action' => 'update',
            'resource_type' => 'Transfer',
            'resource_id' => $transfer->id,
        ]);
    }

    public function test_transfer_deletion_is_automatically_logged(): void
    {
        $user = User::factory()->create();
        $transfer = Transfer::factory()->create(['user_id' => $user->id]);

        $this->actingAs($user, 'sanctum')
            ->deleteJson("/api/v1/transfers/{$transfer->id}");

        $this->assertDatabaseHas('audit_logs', [
            'user_id' => $user->id,
            'action' => 'delete',
            'resource_type' => 'Transfer',
            'resource_id' => $transfer->id,
        ]);
    }

    public function test_incoming_creation_is_automatically_logged(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/incoming', [
                'description' => 'Payment received',
                'amount_usd' => 1000.00,
                'incoming_date' => '2025-10-20',
            ]);

        $this->assertDatabaseHas('audit_logs', [
            'user_id' => $user->id,
            'action' => 'create',
            'resource_type' => 'Incoming',
        ]);

        $log = AuditLog::where('action', 'create')
            ->where('resource_type', 'Incoming')
            ->first();

        $this->assertNotNull($log);
        $this->assertArrayHasKey('description', $log->metadata);
        $this->assertEquals('Payment received', $log->metadata['description']);
    }

    public function test_incoming_update_is_automatically_logged(): void
    {
        $user = User::factory()->create();
        $incoming = Incoming::factory()->create([
            'user_id' => $user->id,
            'description' => 'Original',
        ]);

        $this->actingAs($user, 'sanctum')
            ->putJson("/api/v1/incoming/{$incoming->id}", [
                'description' => 'Updated',
            ]);

        $this->assertDatabaseHas('audit_logs', [
            'user_id' => $user->id,
            'action' => 'update',
            'resource_type' => 'Incoming',
            'resource_id' => $incoming->id,
        ]);
    }

    public function test_incoming_deletion_is_automatically_logged(): void
    {
        $user = User::factory()->create();
        $incoming = Incoming::factory()->create(['user_id' => $user->id]);

        $this->actingAs($user, 'sanctum')
            ->deleteJson("/api/v1/incoming/{$incoming->id}");

        $this->assertDatabaseHas('audit_logs', [
            'user_id' => $user->id,
            'action' => 'delete',
            'resource_type' => 'Incoming',
            'resource_id' => $incoming->id,
        ]);
    }

    // ========== FAILED AUTH LOGGING ==========

    public function test_failed_login_attempt_is_logged(): void
    {
        User::factory()->create([
            'email' => 'test@example.com',
            'password' => bcrypt('correct-password'),
        ]);

        $this->postJson('/api/v1/auth/login', [
            'email' => 'test@example.com',
            'password' => 'wrong-password',
        ]);

        $this->assertDatabaseHas('audit_logs', [
            'action' => 'failed_auth',
            'resource_type' => 'User',
        ]);

        $log = AuditLog::where('action', 'failed_auth')->first();
        $this->assertNotNull($log);
        $this->assertNull($log->user_id);
        $this->assertArrayHasKey('email', $log->metadata);
        $this->assertEquals('test@example.com', $log->metadata['email']);
    }

    public function test_failed_login_with_nonexistent_email_is_logged(): void
    {
        $this->postJson('/api/v1/auth/login', [
            'email' => 'nonexistent@example.com',
            'password' => 'any-password',
        ]);

        $this->assertDatabaseHas('audit_logs', [
            'action' => 'failed_auth',
            'resource_type' => 'User',
        ]);

        $log = AuditLog::where('action', 'failed_auth')->first();
        $this->assertNotNull($log);
        $this->assertArrayHasKey('email', $log->metadata);
        $this->assertEquals('nonexistent@example.com', $log->metadata['email']);
    }

    // ========== ADMIN ACCESS LOGGING ==========

    public function test_admin_viewing_user_expense_is_logged(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        $this->actingAs($admin, 'sanctum')
            ->getJson("/api/v1/expenses/{$expense->id}");

        $this->assertDatabaseHas('audit_logs', [
            'user_id' => $admin->id,
            'action' => 'view',
            'resource_type' => 'Expense',
            'resource_id' => $expense->id,
        ]);

        $log = AuditLog::where('action', 'view')
            ->where('resource_type', 'Expense')
            ->where('resource_id', $expense->id)
            ->first();

        $this->assertNotNull($log);
        $this->assertArrayHasKey('admin_access', $log->metadata);
        $this->assertTrue($log->metadata['admin_access']);
    }

    public function test_admin_viewing_user_transfer_is_logged(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();
        $transfer = Transfer::factory()->create(['user_id' => $user->id]);

        $this->actingAs($admin, 'sanctum')
            ->getJson("/api/v1/transfers/{$transfer->id}");

        $this->assertDatabaseHas('audit_logs', [
            'user_id' => $admin->id,
            'action' => 'view',
            'resource_type' => 'Transfer',
            'resource_id' => $transfer->id,
        ]);
    }

    public function test_admin_viewing_user_incoming_is_logged(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();
        $incoming = Incoming::factory()->create(['user_id' => $user->id]);

        $this->actingAs($admin, 'sanctum')
            ->getJson("/api/v1/incoming/{$incoming->id}");

        $this->assertDatabaseHas('audit_logs', [
            'user_id' => $admin->id,
            'action' => 'view',
            'resource_type' => 'Incoming',
            'resource_id' => $incoming->id,
        ]);
    }

    // ========== LOG FILTERING ==========

    public function test_can_filter_audit_logs_by_user(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        // Create expenses to generate logs
        Expense::factory()->create(['user_id' => $user1->id]);
        Expense::factory()->create(['user_id' => $user2->id]);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson("/api/v1/audit-logs?user_id={$user1->id}");

        $response->assertStatus(200);

        $logs = $response->json('data');
        foreach ($logs as $log) {
            $this->assertEquals($user1->id, $log['user_id']);
        }
    }

    public function test_can_filter_audit_logs_by_action(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();

        // Create and update expense to generate different action logs
        $expense = Expense::factory()->create(['user_id' => $user->id]);
        $expense->update(['description' => 'Updated']);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/audit-logs?action=update');

        $response->assertStatus(200);

        $logs = $response->json('data');
        foreach ($logs as $log) {
            $this->assertEquals('update', $log['action']);
        }
    }

    public function test_can_filter_audit_logs_by_resource_type(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();

        // Create different resource types
        Expense::factory()->create(['user_id' => $user->id]);
        Transfer::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/audit-logs?resource_type=Expense');

        $response->assertStatus(200);

        $logs = $response->json('data');
        foreach ($logs as $log) {
            $this->assertEquals('Expense', $log['resource_type']);
        }
    }

    public function test_can_filter_audit_logs_by_date_range(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();

        // Create expense to generate log
        Expense::factory()->create(['user_id' => $user->id]);

        $startDate = now()->subDay()->format('Y-m-d');
        $endDate = now()->addDay()->format('Y-m-d');

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson("/api/v1/audit-logs?created_from={$startDate}&created_to={$endDate}");

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    '*' => [
                        'id',
                        'user_id',
                        'action',
                        'resource_type',
                        'resource_id',
                        'created_at',
                    ],
                ],
            ]);
    }

    public function test_audit_logs_are_paginated(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();

        // Create multiple expenses to generate logs
        Expense::factory()->count(20)->create(['user_id' => $user->id]);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/audit-logs?per_page=10');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data',
                'pagination' => [
                    'current_page',
                    'last_page',
                    'per_page',
                    'total',
                ],
            ]);

        $this->assertCount(10, $response->json('data'));
        $this->assertEquals(10, $response->json('pagination.per_page'));
    }

    public function test_audit_logs_are_ordered_by_newest_first(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();

        // Create multiple expenses
        Expense::factory()->count(5)->create(['user_id' => $user->id]);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/audit-logs');

        $response->assertStatus(200);

        $logs = $response->json('data');
        $timestamps = array_column($logs, 'created_at');

        // Verify timestamps are in descending order
        for ($i = 0; $i < count($timestamps) - 1; $i++) {
            $this->assertGreaterThanOrEqual(
                strtotime($timestamps[$i + 1]),
                strtotime($timestamps[$i])
            );
        }
    }

    // ========== AUTHORIZATION TESTS ==========

    public function test_regular_user_cannot_access_audit_logs(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/audit-logs');

        $response->assertStatus(403);
    }

    public function test_admin_can_access_audit_logs(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/audit-logs');

        $response->assertStatus(200);
    }

    public function test_unauthenticated_user_cannot_access_audit_logs(): void
    {
        $response = $this->getJson('/api/v1/audit-logs');

        $response->assertStatus(401);
    }

    // ========== METADATA TESTS ==========

    public function test_audit_log_captures_ip_address(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/expenses', [
                'description' => 'Test',
                'price_usd' => 100.00,
                'expense_date' => '2025-10-20',
            ]);

        $log = AuditLog::where('action', 'create')
            ->where('resource_type', 'Expense')
            ->first();

        $this->assertNotNull($log->ip_address);
    }

    public function test_audit_log_captures_user_agent(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')
            ->withHeader('User-Agent', 'TestAgent/1.0')
            ->postJson('/api/v1/expenses', [
                'description' => 'Test',
                'price_usd' => 100.00,
                'expense_date' => '2025-10-20',
            ]);

        $log = AuditLog::where('action', 'create')
            ->where('resource_type', 'Expense')
            ->first();

        $this->assertNotNull($log->user_agent);
    }

    public function test_audit_log_service_can_log_custom_action(): void
    {
        $user = User::factory()->create();
        $auditLogService = app(AuditLogService::class);

        $log = $auditLogService->logAction(
            $user,
            'custom_action',
            'CustomResource',
            123,
            ['custom_field' => 'custom_value']
        );

        $this->assertDatabaseHas('audit_logs', [
            'user_id' => $user->id,
            'action' => 'custom_action',
            'resource_type' => 'CustomResource',
            'resource_id' => 123,
        ]);

        $this->assertArrayHasKey('custom_field', $log->metadata);
        $this->assertEquals('custom_value', $log->metadata['custom_field']);
    }
}

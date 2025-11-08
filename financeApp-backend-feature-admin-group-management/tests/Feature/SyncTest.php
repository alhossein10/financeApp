<?php

namespace Tests\Feature;

use App\Models\Expense;
use App\Models\Incoming;
use App\Models\Transfer;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SyncTest extends TestCase
{
    use RefreshDatabase;

    // ========== BATCH SYNC TESTS ==========

    public function test_batch_sync_creates_multiple_expenses(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/sync/batch', [
                'records' => [
                    [
                        'resource_type' => 'expense',
                        'action' => 'create',
                        'client_id' => 'client-1',
                        'data' => [
                            'description' => 'Expense 1',
                            'price_usd' => 100.00,
                            'expense_date' => '2025-10-20',
                        ],
                    ],
                    [
                        'resource_type' => 'expense',
                        'action' => 'create',
                        'client_id' => 'client-2',
                        'data' => [
                            'description' => 'Expense 2',
                            'price_usd' => 200.00,
                            'expense_date' => '2025-10-21',
                        ],
                    ],
                ],
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'summary' => [
                    'total' => 2,
                    'succeeded' => 2,
                    'failed' => 0,
                ],
            ]);

        $this->assertDatabaseHas('expenses', [
            'user_id' => $user->id,
            'description' => 'Expense 1',
            'sync_status' => 'synced',
        ]);

        $this->assertDatabaseHas('expenses', [
            'user_id' => $user->id,
            'description' => 'Expense 2',
            'sync_status' => 'synced',
        ]);
    }

    public function test_batch_sync_creates_multiple_resource_types(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/sync/batch', [
                'records' => [
                    [
                        'resource_type' => 'expense',
                        'action' => 'create',
                        'data' => [
                            'description' => 'Test expense',
                            'price_usd' => 100.00,
                            'expense_date' => '2025-10-20',
                        ],
                    ],
                    [
                        'resource_type' => 'transfer',
                        'action' => 'create',
                        'data' => [
                            'recipient_name' => 'John Doe',
                            'amount_usd' => 500.00,
                            'transfer_date' => '2025-10-20',
                        ],
                    ],
                    [
                        'resource_type' => 'incoming',
                        'action' => 'create',
                        'data' => [
                            'description' => 'Payment received',
                            'amount_usd' => 1000.00,
                            'incoming_date' => '2025-10-20',
                        ],
                    ],
                ],
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'summary' => [
                    'total' => 3,
                    'succeeded' => 3,
                    'failed' => 0,
                ],
            ]);

        $this->assertDatabaseHas('expenses', ['description' => 'Test expense']);
        $this->assertDatabaseHas('transfers', ['recipient_name' => 'John Doe']);
        $this->assertDatabaseHas('incoming', ['description' => 'Payment received']);
    }

    public function test_batch_sync_updates_existing_expense(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'description' => 'Original',
            'price_usd' => 100.00,
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/sync/batch', [
                'records' => [
                    [
                        'resource_type' => 'expense',
                        'action' => 'update',
                        'id' => $expense->id,
                        'data' => [
                            'description' => 'Updated',
                            'price_usd' => 150.00,
                            'updated_at' => $expense->updated_at->toIso8601String(),
                        ],
                    ],
                ],
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'summary' => [
                    'succeeded' => 1,
                    'failed' => 0,
                ],
            ]);

        $this->assertDatabaseHas('expenses', [
            'id' => $expense->id,
            'description' => 'Updated',
            'price_usd' => 150.00,
        ]);
    }

    public function test_batch_sync_deletes_expense(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/sync/batch', [
                'records' => [
                    [
                        'resource_type' => 'expense',
                        'action' => 'delete',
                        'id' => $expense->id,
                        'data' => [],
                    ],
                ],
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'summary' => [
                    'succeeded' => 1,
                    'failed' => 0,
                ],
            ]);

        $this->assertSoftDeleted('expenses', ['id' => $expense->id]);
    }

    public function test_batch_sync_handles_partial_failures(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/sync/batch', [
                'records' => [
                    [
                        'resource_type' => 'expense',
                        'action' => 'create',
                        'client_id' => 'success-1',
                        'data' => [
                            'description' => 'Valid expense',
                            'price_usd' => 100.00,
                            'expense_date' => '2025-10-20',
                        ],
                    ],
                    [
                        'resource_type' => 'expense',
                        'action' => 'update',
                        'id' => 99999,
                        'client_id' => 'fail-1',
                        'data' => [
                            'description' => 'Non-existent',
                        ],
                    ],
                ],
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'summary' => [
                    'total' => 2,
                    'succeeded' => 1,
                    'failed' => 1,
                ],
            ]);

        $results = $response->json('results');
        $this->assertTrue($results[0]['success']);
        $this->assertFalse($results[1]['success']);
        $this->assertEquals('fail-1', $results[1]['client_id']);
    }

    public function test_batch_sync_validates_required_fields(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/sync/batch', [
                'records' => [
                    [
                        'action' => 'create',
                        'data' => [],
                    ],
                ],
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['records.0.resource_type']);
    }

    public function test_batch_sync_requires_authentication(): void
    {
        $response = $this->postJson('/api/v1/sync/batch', [
            'records' => [],
        ]);

        $response->assertStatus(401);
    }

    // ========== TIMESTAMP-BASED CHANGE RETRIEVAL TESTS ==========

    public function test_get_changes_returns_expenses_modified_after_timestamp(): void
    {
        $user = User::factory()->create();
        
        $oldExpense = Expense::factory()->create([
            'user_id' => $user->id,
            'created_at' => Carbon::now()->subDays(5),
            'updated_at' => Carbon::now()->subDays(5),
        ]);

        $newExpense = Expense::factory()->create([
            'user_id' => $user->id,
            'created_at' => Carbon::now()->subHours(1),
            'updated_at' => Carbon::now()->subHours(1),
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/sync/changes?since=' . Carbon::now()->subDays(2)->toIso8601String());

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $changes = $response->json('data.changes');
        $this->assertCount(1, $changes);
        $this->assertEquals($newExpense->id, $changes[0]['id']);
        $this->assertEquals('expense', $changes[0]['resource_type']);
    }

    public function test_get_changes_returns_multiple_resource_types(): void
    {
        $user = User::factory()->create();
        $timestamp = Carbon::now()->subHours(2);

        Expense::factory()->create([
            'user_id' => $user->id,
            'updated_at' => Carbon::now()->subHours(1),
        ]);

        Transfer::factory()->create([
            'user_id' => $user->id,
            'updated_at' => Carbon::now()->subMinutes(30),
        ]);

        Incoming::factory()->create([
            'user_id' => $user->id,
            'updated_at' => Carbon::now()->subMinutes(15),
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/sync/changes?since=' . $timestamp->toIso8601String());

        $response->assertStatus(200);

        $changes = $response->json('data.changes');
        $this->assertCount(3, $changes);

        $resourceTypes = collect($changes)->pluck('resource_type')->toArray();
        $this->assertContains('expense', $resourceTypes);
        $this->assertContains('transfer', $resourceTypes);
        $this->assertContains('incoming', $resourceTypes);
    }

    public function test_get_changes_only_returns_user_own_records(): void
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        $timestamp = Carbon::now()->subHours(2);

        Expense::factory()->create([
            'user_id' => $user1->id,
            'updated_at' => Carbon::now()->subHours(1),
        ]);

        Expense::factory()->create([
            'user_id' => $user2->id,
            'updated_at' => Carbon::now()->subHours(1),
        ]);

        $response = $this->actingAs($user1, 'sanctum')
            ->getJson('/api/v1/sync/changes?since=' . $timestamp->toIso8601String());

        $response->assertStatus(200);

        $changes = $response->json('data.changes');
        $this->assertCount(1, $changes);
        
        foreach ($changes as $change) {
            $this->assertEquals($user1->id, $change['data']['user_id']);
        }
    }

    public function test_get_changes_returns_empty_when_no_changes(): void
    {
        $user = User::factory()->create();

        Expense::factory()->create([
            'user_id' => $user->id,
            'updated_at' => Carbon::now()->subDays(5),
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/sync/changes?since=' . Carbon::now()->subHours(1)->toIso8601String());

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'changes' => [],
                ],
            ]);
    }

    public function test_get_changes_validates_since_parameter(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/sync/changes?since=invalid-date');

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['since']);
    }

    public function test_get_changes_requires_since_parameter(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/sync/changes');

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['since']);
    }

    public function test_get_changes_requires_authentication(): void
    {
        $response = $this->getJson('/api/v1/sync/changes?since=' . Carbon::now()->toIso8601String());

        $response->assertStatus(401);
    }

    // ========== CONFLICT DETECTION AND RESOLUTION TESTS ==========

    public function test_batch_sync_detects_conflict_when_server_version_newer(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'description' => 'Server version',
            'updated_at' => Carbon::now(),
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/sync/batch', [
                'records' => [
                    [
                        'resource_type' => 'expense',
                        'action' => 'update',
                        'id' => $expense->id,
                        'data' => [
                            'description' => 'Client version',
                            'updated_at' => Carbon::now()->subHours(1)->toIso8601String(),
                        ],
                    ],
                ],
            ]);

        $response->assertStatus(200);

        $results = $response->json('results');
        $this->assertFalse($results[0]['success']);
        $this->assertStringContainsString('Conflict', $results[0]['error']);
    }

    public function test_resolve_conflict_with_server_wins_strategy(): void
    {
        $user = User::factory()->create();

        $clientData = [
            'id' => 1,
            'description' => 'Client version',
            'price_usd' => 100.00,
        ];

        $serverData = [
            'id' => 1,
            'description' => 'Server version',
            'price_usd' => 200.00,
        ];

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/sync/resolve', [
                'strategy' => 'server_wins',
                'client_data' => $clientData,
                'server_data' => $serverData,
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => $serverData,
            ]);
    }

    public function test_resolve_conflict_with_client_wins_strategy(): void
    {
        $user = User::factory()->create();

        $clientData = [
            'id' => 1,
            'description' => 'Client version',
            'price_usd' => 100.00,
        ];

        $serverData = [
            'id' => 1,
            'description' => 'Server version',
            'price_usd' => 200.00,
        ];

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/sync/resolve', [
                'strategy' => 'client_wins',
                'client_data' => $clientData,
                'server_data' => $serverData,
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => $clientData,
            ]);
    }

    public function test_resolve_conflict_with_merge_strategy(): void
    {
        $user = User::factory()->create();

        $clientData = [
            'description' => 'Client description',
            'price_usd' => 100.00,
        ];

        $serverData = [
            'id' => 1,
            'user_id' => $user->id,
            'description' => 'Server description',
            'price_usd' => 200.00,
            'created_at' => '2025-10-20T10:00:00Z',
            'updated_at' => '2025-10-21T10:00:00Z',
        ];

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/sync/resolve', [
                'strategy' => 'merge',
                'client_data' => $clientData,
                'server_data' => $serverData,
            ]);

        $response->assertStatus(200);

        $resolved = $response->json('data');
        $this->assertEquals(1, $resolved['id']);
        $this->assertEquals($user->id, $resolved['user_id']);
        $this->assertEquals('Client description', $resolved['description']);
        $this->assertEquals(100.00, $resolved['price_usd']);
    }

    public function test_resolve_conflict_with_newest_wins_strategy(): void
    {
        $user = User::factory()->create();

        $clientData = [
            'description' => 'Client version',
            'updated_at' => Carbon::now()->toIso8601String(),
        ];

        $serverData = [
            'description' => 'Server version',
            'updated_at' => Carbon::now()->subHours(1)->toIso8601String(),
        ];

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/sync/resolve', [
                'strategy' => 'newest_wins',
                'client_data' => $clientData,
                'server_data' => $serverData,
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'description' => 'Client version',
                ],
            ]);
    }

    public function test_resolve_conflict_validates_strategy(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/sync/resolve', [
                'strategy' => 'invalid_strategy',
                'client_data' => [],
                'server_data' => [],
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['strategy']);
    }

    public function test_resolve_conflict_requires_authentication(): void
    {
        $response = $this->postJson('/api/v1/sync/resolve', [
            'strategy' => 'server_wins',
            'client_data' => [],
            'server_data' => [],
        ]);

        $response->assertStatus(401);
    }

    // ========== SYNC STATUS TRACKING TESTS ==========

    public function test_batch_sync_sets_sync_status_to_synced_on_create(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/sync/batch', [
                'records' => [
                    [
                        'resource_type' => 'expense',
                        'action' => 'create',
                        'data' => [
                            'description' => 'Test expense',
                            'price_usd' => 100.00,
                            'expense_date' => '2025-10-20',
                        ],
                    ],
                ],
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('expenses', [
            'description' => 'Test expense',
            'sync_status' => 'synced',
        ]);

        $expense = Expense::where('description', 'Test expense')->first();
        $this->assertNotNull($expense->synced_at);
    }

    public function test_batch_sync_updates_sync_status_on_update(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'sync_status' => 'pending',
            'synced_at' => null,
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/sync/batch', [
                'records' => [
                    [
                        'resource_type' => 'expense',
                        'action' => 'update',
                        'id' => $expense->id,
                        'data' => [
                            'description' => 'Updated',
                            'updated_at' => $expense->updated_at->toIso8601String(),
                        ],
                    ],
                ],
            ]);

        $response->assertStatus(200);

        $expense->refresh();
        $this->assertEquals('synced', $expense->sync_status);
        $this->assertNotNull($expense->synced_at);
    }

    public function test_batch_sync_tracks_sync_status_for_transfers(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/sync/batch', [
                'records' => [
                    [
                        'resource_type' => 'transfer',
                        'action' => 'create',
                        'data' => [
                            'recipient_name' => 'John Doe',
                            'amount_usd' => 500.00,
                            'transfer_date' => '2025-10-20',
                        ],
                    ],
                ],
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('transfers', [
            'recipient_name' => 'John Doe',
            'sync_status' => 'synced',
        ]);
    }

    public function test_batch_sync_tracks_sync_status_for_incoming(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/sync/batch', [
                'records' => [
                    [
                        'resource_type' => 'incoming',
                        'action' => 'create',
                        'data' => [
                            'description' => 'Payment received',
                            'amount_usd' => 1000.00,
                            'incoming_date' => '2025-10-20',
                        ],
                    ],
                ],
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('incoming', [
            'description' => 'Payment received',
            'sync_status' => 'synced',
        ]);
    }
}


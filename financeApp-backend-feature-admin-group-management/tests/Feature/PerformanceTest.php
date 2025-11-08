<?php

namespace Tests\Feature;

use App\Models\Expense;
use App\Models\Transfer;
use App\Models\Incoming;
use App\Models\User;
use App\Services\CacheService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class PerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected CacheService $cacheService;

    protected function setUp(): void
    {
        parent::setUp();
        $this->cacheService = app(CacheService::class);
    }

    // ========== QUERY EFFICIENCY TESTS ==========

    public function test_expense_list_query_efficiency_with_large_dataset(): void
    {
        $user = User::factory()->create();
        
        // Create large dataset
        Expense::factory()->count(100)->create(['user_id' => $user->id]);

        // Enable query logging
        DB::enableQueryLog();

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/expenses?per_page=20');

        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        $response->assertStatus(200);

        // Should use minimal queries (ideally 2-3: auth check, count, data fetch)
        $this->assertLessThanOrEqual(5, count($queries), 
            'Expense list should use minimal queries. Found: ' . count($queries));

        // Verify no N+1 query issues
        $selectQueries = array_filter($queries, fn($q) => str_starts_with(strtolower($q['query']), 'select'));
        $this->assertLessThanOrEqual(3, count($selectQueries),
            'Should not have N+1 query issues');
    }

    public function test_admin_dashboard_query_efficiency(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        
        // Create diverse dataset
        $users = User::factory()->count(10)->create();
        foreach ($users as $user) {
            Expense::factory()->count(5)->create(['user_id' => $user->id]);
            Transfer::factory()->count(3)->create(['user_id' => $user->id]);
            Incoming::factory()->count(2)->create(['user_id' => $user->id]);
        }

        DB::enableQueryLog();

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/stats');

        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        $response->assertStatus(200);

        // Dashboard stats should use efficient aggregation queries
        $this->assertLessThanOrEqual(10, count($queries),
            'Dashboard stats should use efficient queries. Found: ' . count($queries));
    }

    public function test_transfer_with_exchange_eager_loading(): void
    {
        $user = User::factory()->create();
        
        // Create transfers with exchanges
        $transfers = Transfer::factory()->count(20)->create(['user_id' => $user->id]);
        foreach ($transfers as $transfer) {
            $transfer->exchange()->create([
                'converted_amount_syp' => 250000.00,
                'exchange_rate_usd_to_syp' => 2500.00,
                'exchange_date' => now()->toDateString(),
            ]);
        }

        DB::enableQueryLog();

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/transfers');

        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        $response->assertStatus(200);

        // Should use eager loading (2-3 queries max: auth, transfers, exchanges)
        $selectQueries = array_filter($queries, fn($q) => str_starts_with(strtolower($q['query']), 'select'));
        $this->assertLessThanOrEqual(4, count($selectQueries),
            'Should use eager loading to prevent N+1 queries');
    }

    public function test_pagination_query_efficiency(): void
    {
        $user = User::factory()->create();
        Expense::factory()->count(100)->create(['user_id' => $user->id]);

        DB::enableQueryLog();

        // Request first page
        $response1 = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/expenses?page=1&per_page=15');

        $queries1 = DB::getQueryLog();
        DB::disableQueryLog();

        $response1->assertStatus(200);

        DB::enableQueryLog();

        // Request second page
        $response2 = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/expenses?page=2&per_page=15');

        $queries2 = DB::getQueryLog();
        DB::disableQueryLog();

        $response2->assertStatus(200);

        // Both pages should use similar number of queries
        $this->assertEquals(count($queries1), count($queries2),
            'Pagination should have consistent query count across pages');
    }

    public function test_filtered_query_uses_indexes(): void
    {
        $user = User::factory()->create();
        
        // Create expenses with various dates
        Expense::factory()->count(50)->create([
            'user_id' => $user->id,
            'expense_date' => now()->subDays(rand(1, 30))->toDateString(),
        ]);

        DB::enableQueryLog();

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/expenses?start_date=' . now()->subDays(10)->toDateString());

        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        $response->assertStatus(200);

        // Verify query uses WHERE clause for filtering
        $mainQuery = collect($queries)->first(fn($q) => 
            str_contains($q['query'], 'expenses') && 
            str_contains($q['query'], 'expense_date')
        );

        $this->assertNotNull($mainQuery, 'Should use indexed date filtering');
    }

    // ========== CACHE HIT RATE TESTS ==========

    public function test_dashboard_stats_cache_hit(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        
        // Create test data
        User::factory()->count(5)->create();
        Expense::factory()->count(10)->create();

        Cache::flush();

        // First request - cache miss
        $startTime1 = microtime(true);
        $response1 = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/stats');
        $duration1 = microtime(true) - $startTime1;

        $response1->assertStatus(200);

        // Second request - should hit cache
        $startTime2 = microtime(true);
        $response2 = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/stats');
        $duration2 = microtime(true) - $startTime2;

        $response2->assertStatus(200);

        // Cached response should be faster
        $this->assertLessThan($duration1, $duration2,
            'Cached request should be faster than initial request');

        // Verify responses are identical
        $this->assertEquals($response1->json('data'), $response2->json('data'));
    }

    public function test_cache_invalidation_on_data_change(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();

        Cache::flush();

        // First request - populate cache
        $response1 = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/stats');

        $response1->assertStatus(200);
        $initialExpenseCount = $response1->json('data.total_expenses');

        // Create new expense - should invalidate cache
        Expense::factory()->create(['user_id' => $user->id]);

        // Second request - should reflect new data
        $response2 = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/stats');

        $response2->assertStatus(200);
        $newExpenseCount = $response2->json('data.total_expenses');

        $this->assertEquals($initialExpenseCount + 1, $newExpenseCount,
            'Cache should be invalidated after data change');
    }

    public function test_user_activity_cache_performance(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        
        // Create users with activities
        $users = User::factory()->count(20)->create();
        foreach ($users as $user) {
            Expense::factory()->count(5)->create(['user_id' => $user->id]);
        }

        Cache::flush();

        // Measure uncached request
        DB::enableQueryLog();
        $startTime1 = microtime(true);
        
        $response1 = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/users');
        
        $duration1 = microtime(true) - $startTime1;
        $queries1 = count(DB::getQueryLog());
        DB::disableQueryLog();

        $response1->assertStatus(200);

        // Measure cached request
        DB::enableQueryLog();
        $startTime2 = microtime(true);
        
        $response2 = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/users');
        
        $duration2 = microtime(true) - $startTime2;
        $queries2 = count(DB::getQueryLog());
        DB::disableQueryLog();

        $response2->assertStatus(200);

        // Cached request should use fewer queries
        $this->assertLessThan($queries1, $queries2,
            'Cached request should use fewer database queries');

        // Cached request should be faster
        $this->assertLessThan($duration1, $duration2,
            'Cached request should be faster');
    }

    public function test_expense_summaries_cache_with_filters(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        
        Expense::factory()->count(30)->create([
            'expense_date' => now()->subDays(5)->toDateString(),
        ]);

        Cache::flush();

        $filters = [
            'start_date' => now()->subDays(10)->toDateString(),
            'end_date' => now()->toDateString(),
        ];

        // First request
        $response1 = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/expenses?' . http_build_query($filters));

        $response1->assertStatus(200);

        // Second request with same filters - should hit cache
        DB::enableQueryLog();
        
        $response2 = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/expenses?' . http_build_query($filters));

        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        $response2->assertStatus(200);

        // Should use minimal queries (just auth check)
        $this->assertLessThanOrEqual(2, count($queries),
            'Cached request should use minimal queries');

        // Verify data consistency
        $this->assertEquals($response1->json('data'), $response2->json('data'));
    }

    public function test_cache_key_uniqueness_for_different_filters(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        
        Expense::factory()->count(20)->create();

        Cache::flush();

        // Request with filter 1
        $response1 = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/expenses?start_date=' . now()->subDays(10)->toDateString());

        // Request with filter 2
        $response2 = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/expenses?start_date=' . now()->subDays(5)->toDateString());

        $response1->assertStatus(200);
        $response2->assertStatus(200);

        // Different filters should produce different results
        $this->assertNotEquals(
            $response1->json('data'),
            $response2->json('data'),
            'Different filters should use different cache keys'
        );
    }

    // ========== RESPONSE TIME TESTS ==========

    public function test_expense_list_response_time_with_large_dataset(): void
    {
        $user = User::factory()->create();
        
        // Create large dataset
        Expense::factory()->count(200)->create(['user_id' => $user->id]);

        $startTime = microtime(true);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/expenses?per_page=50');

        $duration = microtime(true) - $startTime;

        $response->assertStatus(200);

        // Response should be under 1 second for 200 records
        $this->assertLessThan(1.0, $duration,
            "Expense list response took {$duration}s, should be under 1s");
    }

    public function test_admin_dashboard_response_time(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        
        // Create realistic dataset
        $users = User::factory()->count(50)->create();
        foreach ($users as $user) {
            Expense::factory()->count(10)->create(['user_id' => $user->id]);
            Transfer::factory()->count(5)->create(['user_id' => $user->id]);
            Incoming::factory()->count(3)->create(['user_id' => $user->id]);
        }

        Cache::flush();

        $startTime = microtime(true);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/dashboard/stats');

        $duration = microtime(true) - $startTime;

        $response->assertStatus(200);

        // Dashboard should respond within 2 seconds even with large dataset
        $this->assertLessThan(2.0, $duration,
            "Dashboard stats response took {$duration}s, should be under 2s");
    }

    public function test_transfer_list_with_relationships_response_time(): void
    {
        $user = User::factory()->create();
        
        // Create transfers with exchanges
        $transfers = Transfer::factory()->count(100)->create(['user_id' => $user->id]);
        foreach ($transfers as $transfer) {
            $transfer->exchange()->create([
                'converted_amount_syp' => 250000.00,
                'exchange_rate_usd_to_syp' => 2500.00,
                'exchange_date' => now()->toDateString(),
            ]);
        }

        $startTime = microtime(true);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/transfers?per_page=50');

        $duration = microtime(true) - $startTime;

        $response->assertStatus(200);

        // Should load relationships efficiently
        $this->assertLessThan(1.5, $duration,
            "Transfer list with exchanges took {$duration}s, should be under 1.5s");
    }

    public function test_sync_batch_processing_response_time(): void
    {
        $user = User::factory()->create();

        // Prepare batch sync data
        $batchData = [];
        for ($i = 0; $i < 50; $i++) {
            $batchData[] = [
                'type' => 'expense',
                'data' => [
                    'description' => "Batch expense {$i}",
                    'price_usd' => rand(10, 1000),
                    'expense_date' => now()->subDays(rand(1, 30))->toDateString(),
                ],
            ];
        }

        $startTime = microtime(true);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/sync/batch', [
                'records' => $batchData,
            ]);

        $duration = microtime(true) - $startTime;

        $response->assertStatus(200);

        // Batch processing should complete within reasonable time
        $this->assertLessThan(5.0, $duration,
            "Batch sync of 50 records took {$duration}s, should be under 5s");
    }

    public function test_export_generation_response_time(): void
    {
        $user = User::factory()->create();
        
        // Create moderate dataset for export
        Expense::factory()->count(50)->create(['user_id' => $user->id]);

        $startTime = microtime(true);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/export/expenses/excel', [
                'start_date' => now()->subDays(30)->toDateString(),
                'end_date' => now()->toDateString(),
            ]);

        $duration = microtime(true) - $startTime;

        $response->assertStatus(200);

        // Export generation should be reasonably fast
        $this->assertLessThan(3.0, $duration,
            "Export generation took {$duration}s, should be under 3s");
    }

    public function test_authentication_response_time(): void
    {
        $user = User::factory()->create([
            'password' => bcrypt('password123'),
        ]);

        $startTime = microtime(true);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => $user->email,
            'password' => 'password123',
        ]);

        $duration = microtime(true) - $startTime;

        $response->assertStatus(200);

        // Authentication should be fast
        $this->assertLessThan(0.5, $duration,
            "Authentication took {$duration}s, should be under 0.5s");
    }

    public function test_concurrent_request_handling(): void
    {
        $user = User::factory()->create();
        Expense::factory()->count(100)->create(['user_id' => $user->id]);

        $durations = [];

        // Simulate multiple concurrent requests
        for ($i = 0; $i < 5; $i++) {
            $startTime = microtime(true);

            $response = $this->actingAs($user, 'sanctum')
                ->getJson('/api/v1/expenses?page=' . ($i + 1));

            $durations[] = microtime(true) - $startTime;

            $response->assertStatus(200);
        }

        // All requests should complete in reasonable time
        foreach ($durations as $index => $duration) {
            $this->assertLessThan(1.0, $duration,
                "Request {$index} took {$duration}s, should be under 1s");
        }

        // Average response time should be consistent
        $avgDuration = array_sum($durations) / count($durations);
        $this->assertLessThan(0.8, $avgDuration,
            "Average response time {$avgDuration}s should be under 0.8s");
    }

    public function test_memory_usage_with_large_dataset(): void
    {
        $user = User::factory()->create();
        
        // Create large dataset
        Expense::factory()->count(500)->create(['user_id' => $user->id]);

        $memoryBefore = memory_get_usage(true);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/expenses?per_page=100');

        $memoryAfter = memory_get_usage(true);
        $memoryUsed = ($memoryAfter - $memoryBefore) / 1024 / 1024; // Convert to MB

        $response->assertStatus(200);

        // Memory usage should be reasonable (under 50MB for this operation)
        $this->assertLessThan(50, $memoryUsed,
            "Memory usage {$memoryUsed}MB should be under 50MB");
    }
}

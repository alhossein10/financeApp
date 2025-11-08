<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Closure;

class CacheService
{
    /**
     * Cache key prefix for the application.
     */
    protected const CACHE_PREFIX = 'finance_app';

    /**
     * Default cache TTL in seconds (5 minutes).
     */
    protected const DEFAULT_TTL = 300;

    /**
     * Cache dashboard statistics.
     *
     * @param Closure $callback
     * @return mixed
     */
    public function cacheDashboardStats(Closure $callback): mixed
    {
        return Cache::remember(
            $this->getCacheKey('dashboard.stats'),
            self::DEFAULT_TTL,
            $callback
        );
    }

    /**
     * Cache user activity list.
     *
     * @param Closure $callback
     * @return mixed
     */
    public function cacheUserActivityList(Closure $callback): mixed
    {
        return Cache::remember(
            $this->getCacheKey('dashboard.user_activity'),
            self::DEFAULT_TTL,
            $callback
        );
    }

    /**
     * Cache expense summaries with filters.
     *
     * @param array $filters
     * @param Closure $callback
     * @return mixed
     */
    public function cacheExpenseSummaries(array $filters, Closure $callback): mixed
    {
        $key = $this->getCacheKey('dashboard.expense_summaries', $filters);
        
        return Cache::remember($key, self::DEFAULT_TTL, $callback);
    }

    /**
     * Cache analytics data.
     *
     * @param string $startDate
     * @param string $endDate
     * @param Closure $callback
     * @return mixed
     */
    public function cacheAnalytics(string $startDate, string $endDate, Closure $callback): mixed
    {
        $key = $this->getCacheKey('dashboard.analytics', [
            'start' => $startDate,
            'end' => $endDate,
        ]);
        
        return Cache::remember($key, self::DEFAULT_TTL, $callback);
    }

    /**
     * Cache user permissions and roles.
     *
     * @param int $userId
     * @param Closure $callback
     * @return mixed
     */
    public function cacheUserPermissions(int $userId, Closure $callback): mixed
    {
        return Cache::remember(
            $this->getCacheKey("user.{$userId}.permissions"),
            self::DEFAULT_TTL,
            $callback
        );
    }

    /**
     * Cache user role.
     *
     * @param int $userId
     * @param Closure $callback
     * @return mixed
     */
    public function cacheUserRole(int $userId, Closure $callback): mixed
    {
        return Cache::remember(
            $this->getCacheKey("user.{$userId}.role"),
            self::DEFAULT_TTL,
            $callback
        );
    }

    /**
     * Invalidate dashboard caches.
     *
     * @return void
     */
    public function invalidateDashboardCache(): void
    {
        Cache::forget($this->getCacheKey('dashboard.stats'));
        Cache::forget($this->getCacheKey('dashboard.user_activity'));
        
        // Clear all expense summaries (pattern-based)
        $this->clearCacheByPattern('dashboard.expense_summaries');
        $this->clearCacheByPattern('dashboard.analytics');
    }

    /**
     * Invalidate user-specific caches.
     *
     * @param int $userId
     * @return void
     */
    public function invalidateUserCache(int $userId): void
    {
        Cache::forget($this->getCacheKey("user.{$userId}.permissions"));
        Cache::forget($this->getCacheKey("user.{$userId}.role"));
        
        // Invalidate dashboard caches as user data affects them
        $this->invalidateDashboardCache();
    }

    /**
     * Invalidate all user caches (for bulk operations).
     *
     * @return void
     */
    public function invalidateAllUserCaches(): void
    {
        // This would typically use cache tags in production
        // For now, we'll invalidate dashboard which includes user data
        $this->invalidateDashboardCache();
    }

    /**
     * Invalidate all expense-related caches.
     *
     * @return void
     */
    public function invalidateExpenseCache(): void
    {
        $this->invalidateDashboardCache();
    }

    /**
     * Invalidate all transfer-related caches.
     *
     * @return void
     */
    public function invalidateTransferCache(): void
    {
        $this->invalidateDashboardCache();
    }

    /**
     * Invalidate all incoming-related caches.
     *
     * @return void
     */
    public function invalidateIncomingCache(): void
    {
        $this->invalidateDashboardCache();
    }

    /**
     * Generate a cache key with optional parameters.
     *
     * @param string $key
     * @param array $params
     * @return string
     */
    protected function getCacheKey(string $key, array $params = []): string
    {
        $baseKey = self::CACHE_PREFIX . '.' . $key;
        
        if (empty($params)) {
            return $baseKey;
        }
        
        // Sort params for consistent cache keys
        ksort($params);
        $paramString = md5(json_encode($params));
        
        return $baseKey . '.' . $paramString;
    }

    /**
     * Clear cache entries matching a pattern.
     * Note: This is a simplified implementation. For production with Redis,
     * use Redis SCAN command for better performance.
     *
     * @param string $pattern
     * @return void
     */
    protected function clearCacheByPattern(string $pattern): void
    {
        // For database cache driver, we'll use tags if available
        // For now, we'll just document that specific keys need to be cleared
        // In production with Redis, implement proper pattern matching
        
        // This is a placeholder - actual implementation depends on cache driver
        // For Redis: Cache::tags(['dashboard'])->flush();
    }

    /**
     * Flush all application caches.
     *
     * @return void
     */
    public function flushAll(): void
    {
        // Clear specific cache keys
        $this->invalidateDashboardCache();
        
        // Note: Avoid Cache::flush() as it clears ALL cache including framework cache
    }
}

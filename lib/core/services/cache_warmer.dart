import 'package:flutter/foundation.dart';
import 'cache_service.dart';

/// Service for warming up cache with frequently accessed data
class CacheWarmer {
  final CacheService cacheService;
  
  // Track which resources have been warmed
  final Set<String> _warmedResources = {};

  CacheWarmer({required this.cacheService});

  /// Warm cache with data from a loader function
  /// 
  /// [key] - Cache key to store data under
  /// [loader] - Function that loads the data
  /// [ttl] - Time to live for cached data
  /// [force] - Force reload even if already warmed
  Future<T?> warm<T>({
    required String key,
    required Future<T> Function() loader,
    Duration? ttl,
    bool force = false,
  }) async {
    // Skip if already warmed and not forcing
    if (!force && _warmedResources.contains(key)) {
      debugPrint('Cache already warmed for: $key');
      return await cacheService.get<T>(key);
    }

    try {
      debugPrint('Warming cache for: $key');
      
      // Load data
      final data = await loader();
      
      // Store in cache
      await cacheService.set<T>(key, data, ttl: ttl);
      
      // Mark as warmed
      _warmedResources.add(key);
      
      return data;
    } catch (e) {
      debugPrint('Error warming cache for $key: $e');
      return null;
    }
  }

  /// Warm multiple cache entries in parallel
  Future<void> warmMultiple(List<WarmupTask> tasks) async {
    debugPrint('Warming ${tasks.length} cache entries');
    
    await Future.wait(
      tasks.map((task) => warm(
        key: task.key,
        loader: task.loader,
        ttl: task.ttl,
        force: task.force,
      )),
    );
    
    debugPrint('Cache warming complete');
  }

  /// Check if a resource has been warmed
  bool isWarmed(String key) {
    return _warmedResources.contains(key);
  }

  /// Reset warmed resources tracking
  void reset() {
    _warmedResources.clear();
  }

  /// Get list of warmed resources
  List<String> get warmedResources => List.unmodifiable(_warmedResources);
}

/// Represents a cache warmup task
class WarmupTask<T> {
  final String key;
  final Future<T> Function() loader;
  final Duration? ttl;
  final bool force;

  WarmupTask({
    required this.key,
    required this.loader,
    this.ttl,
    this.force = false,
  });
}

/// Predefined warmup strategies
class CacheWarmupStrategy {
  /// Warm up user-specific data on login
  static List<WarmupTask> userDataWarmup({
    required Future<dynamic> Function() loadProfile,
    required Future<dynamic> Function() loadRecentExpenses,
    required Future<dynamic> Function() loadRecentTransfers,
  }) {
    return [
      WarmupTask(
        key: 'user_profile',
        loader: loadProfile,
        ttl: const Duration(hours: 1),
      ),
      WarmupTask(
        key: 'recent_expenses',
        loader: loadRecentExpenses,
        ttl: const Duration(minutes: 30),
      ),
      WarmupTask(
        key: 'recent_transfers',
        loader: loadRecentTransfers,
        ttl: const Duration(minutes: 30),
      ),
    ];
  }

  /// Warm up admin dashboard data
  static List<WarmupTask> adminDashboardWarmup({
    required Future<dynamic> Function() loadStats,
    required Future<dynamic> Function() loadAnalytics,
  }) {
    return [
      WarmupTask(
        key: 'admin_stats',
        loader: loadStats,
        ttl: const Duration(minutes: 15),
      ),
      WarmupTask(
        key: 'admin_analytics',
        loader: loadAnalytics,
        ttl: const Duration(minutes: 15),
      ),
    ];
  }
}

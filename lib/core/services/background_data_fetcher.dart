import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service for fetching fresh data in the background while showing cached data
class BackgroundDataFetcher<T> {
  final Future<T> Function() fetchData;
  final void Function(T data) onDataFetched;
  final void Function(dynamic error)? onError;
  final Duration? debounceDelay;

  Timer? _debounceTimer;
  bool _isFetching = false;

  BackgroundDataFetcher({
    required this.fetchData,
    required this.onDataFetched,
    this.onError,
    this.debounceDelay,
  });

  /// Fetch data in background
  /// 
  /// If [debounceDelay] is set, multiple calls within the delay period
  /// will be debounced to a single fetch
  Future<void> fetch() async {
    if (_isFetching) {
      debugPrint('Background fetch already in progress, skipping');
      return;
    }

    if (debounceDelay != null) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(debounceDelay!, _executeFetch);
    } else {
      await _executeFetch();
    }
  }

  Future<void> _executeFetch() async {
    if (_isFetching) return;

    _isFetching = true;
    debugPrint('Starting background data fetch');

    try {
      final data = await fetchData();
      onDataFetched(data);
      debugPrint('Background data fetch completed successfully');
    } catch (e) {
      debugPrint('Background data fetch failed: $e');
      onError?.call(e);
    } finally {
      _isFetching = false;
    }
  }

  /// Cancel any pending fetch
  void cancel() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  /// Check if currently fetching
  bool get isFetching => _isFetching;

  /// Dispose resources
  void dispose() {
    cancel();
  }
}

/// Manager for multiple background fetchers
class BackgroundFetchManager {
  final Map<String, BackgroundDataFetcher> _fetchers = {};

  /// Register a fetcher
  void register<T>({
    required String key,
    required Future<T> Function() fetchData,
    required void Function(T data) onDataFetched,
    void Function(dynamic error)? onError,
    Duration? debounceDelay,
  }) {
    _fetchers[key] = BackgroundDataFetcher<T>(
      fetchData: fetchData,
      onDataFetched: onDataFetched,
      onError: onError,
      debounceDelay: debounceDelay,
    );
  }

  /// Trigger fetch for a specific key
  Future<void> fetch(String key) async {
    final fetcher = _fetchers[key];
    if (fetcher == null) {
      debugPrint('No fetcher registered for key: $key');
      return;
    }

    await fetcher.fetch();
  }

  /// Trigger fetch for multiple keys
  Future<void> fetchMultiple(List<String> keys) async {
    await Future.wait(
      keys.map((key) => fetch(key)),
    );
  }

  /// Trigger fetch for all registered fetchers
  Future<void> fetchAll() async {
    await Future.wait(
      _fetchers.values.map((fetcher) => fetcher.fetch()),
    );
  }

  /// Cancel fetch for a specific key
  void cancel(String key) {
    _fetchers[key]?.cancel();
  }

  /// Cancel all fetches
  void cancelAll() {
    for (final fetcher in _fetchers.values) {
      fetcher.cancel();
    }
  }

  /// Unregister a fetcher
  void unregister(String key) {
    _fetchers[key]?.dispose();
    _fetchers.remove(key);
  }

  /// Unregister all fetchers
  void unregisterAll() {
    for (final fetcher in _fetchers.values) {
      fetcher.dispose();
    }
    _fetchers.clear();
  }

  /// Check if a fetcher is currently fetching
  bool isFetching(String key) {
    return _fetchers[key]?.isFetching ?? false;
  }

  /// Get list of registered keys
  List<String> get registeredKeys => _fetchers.keys.toList();

  /// Dispose all resources
  void dispose() {
    unregisterAll();
  }
}

/// Strategy for cache-first with background refresh
class CacheFirstStrategy<T> {
  final Future<T?> Function() loadFromCache;
  final Future<T> Function() fetchFromApi;
  final Future<void> Function(T data) saveToCache;
  final void Function(T data) onDataAvailable;
  final void Function(dynamic error)? onError;

  CacheFirstStrategy({
    required this.loadFromCache,
    required this.fetchFromApi,
    required this.saveToCache,
    required this.onDataAvailable,
    this.onError,
  });

  /// Execute cache-first strategy
  /// 
  /// 1. Load from cache immediately if available
  /// 2. Fetch fresh data from API in background
  /// 3. Update cache and notify when fresh data arrives
  Future<void> execute() async {
    // Step 1: Load from cache
    try {
      final cachedData = await loadFromCache();
      if (cachedData != null) {
        debugPrint('Loaded data from cache');
        onDataAvailable(cachedData);
      }
    } catch (e) {
      debugPrint('Error loading from cache: $e');
    }

    // Step 2: Fetch fresh data in background
    try {
      debugPrint('Fetching fresh data from API');
      final freshData = await fetchFromApi();
      
      // Step 3: Update cache
      await saveToCache(freshData);
      
      // Notify with fresh data
      onDataAvailable(freshData);
      debugPrint('Fresh data fetched and cached');
    } catch (e) {
      debugPrint('Error fetching fresh data: $e');
      onError?.call(e);
    }
  }
}

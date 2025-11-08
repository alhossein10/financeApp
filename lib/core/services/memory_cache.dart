import 'dart:collection';

/// In-memory cache for hot data with LRU eviction
class MemoryCache<K, V> {
  final int maxSize;
  final Duration? defaultTTL;
  
  final LinkedHashMap<K, _CacheEntry<V>> _cache = LinkedHashMap();

  MemoryCache({
    this.maxSize = 100,
    this.defaultTTL,
  });

  /// Get value from cache
  V? get(K key) {
    final entry = _cache.remove(key);
    if (entry == null) return null;

    // Check if expired
    if (entry.isExpired) {
      return null;
    }

    // Move to end (most recently used)
    _cache[key] = entry;
    return entry.value;
  }

  /// Put value in cache
  void put(K key, V value, {Duration? ttl}) {
    // Remove if exists (to update position)
    _cache.remove(key);

    // Evict oldest if at capacity
    if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }

    // Add new entry
    final expiresAt = ttl != null || defaultTTL != null
        ? DateTime.now().add(ttl ?? defaultTTL!)
        : null;
    
    _cache[key] = _CacheEntry(value: value, expiresAt: expiresAt);
  }

  /// Remove value from cache
  void remove(K key) {
    _cache.remove(key);
  }

  /// Clear all entries
  void clear() {
    _cache.clear();
  }

  /// Check if key exists and is not expired
  bool containsKey(K key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  /// Get cache size
  int get size => _cache.length;

  /// Check if cache is empty
  bool get isEmpty => _cache.isEmpty;

  /// Check if cache is full
  bool get isFull => _cache.length >= maxSize;

  /// Get all keys
  Iterable<K> get keys => _cache.keys;

  /// Clean up expired entries
  void cleanupExpired() {
    final expiredKeys = <K>[];
    
    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }
}

class _CacheEntry<V> {
  final V value;
  final DateTime? expiresAt;

  _CacheEntry({
    required this.value,
    this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

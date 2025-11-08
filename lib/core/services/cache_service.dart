import 'package:hive_flutter/hive_flutter.dart';

/// Cache entry with TTL support
class CacheEntry<T> {
  final T value;
  final DateTime expiresAt;

  CacheEntry({
    required this.value,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'value': value,
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry<T>(
      value: json['value'] as T,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

/// LRU (Least Recently Used) tracking
class LRUTracker {
  final int maxSize;
  final List<String> _accessOrder = [];

  LRUTracker({required this.maxSize});

  void access(String key) {
    _accessOrder.remove(key);
    _accessOrder.add(key);
  }

  String? getLeastRecentlyUsed() {
    return _accessOrder.isEmpty ? null : _accessOrder.first;
  }

  void remove(String key) {
    _accessOrder.remove(key);
  }

  int get size => _accessOrder.length;

  bool get isFull => size >= maxSize;
}

/// Cache service with TTL and LRU eviction policy
abstract class CacheService {
  Future<T?> get<T>(String key);
  Future<void> set<T>(String key, T value, {Duration? ttl});
  Future<void> delete(String key);
  Future<void> clear();
  bool isExpired(String key);
  Future<void> initialize();
  Future<void> dispose();
}

class CacheServiceImpl implements CacheService {
  static const String _boxName = 'app_cache';
  static const String _metadataBoxName = 'cache_metadata';
  static const Duration _defaultTTL = Duration(hours: 24);
  static const int _maxCacheSize = 1000; // Maximum number of cache entries

  Box? _cacheBox;
  Box? _metadataBox;
  late LRUTracker _lruTracker;

  CacheServiceImpl() {
    _lruTracker = LRUTracker(maxSize: _maxCacheSize);
  }

  @override
  Future<void> initialize() async {
    await Hive.initFlutter();
    _cacheBox = await Hive.openBox(_boxName);
    _metadataBox = await Hive.openBox(_metadataBoxName);

    // Initialize LRU tracker with existing keys
    final keys = _cacheBox?.keys.cast<String>().toList() ?? [];
    for (final key in keys) {
      _lruTracker.access(key);
    }

    // Clean up expired entries on initialization
    await _cleanupExpiredEntries();
  }

  @override
  Future<T?> get<T>(String key) async {
    if (_cacheBox == null) {
      throw Exception('CacheService not initialized. Call initialize() first.');
    }

    final data = _cacheBox!.get(key);
    if (data == null) {
      return null;
    }

    // Check if entry has expired
    if (isExpired(key)) {
      await delete(key);
      return null;
    }

    // Update LRU tracker
    _lruTracker.access(key);

    // Handle different data types
    if (data is Map) {
      final entry = CacheEntry<T>.fromJson(Map<String, dynamic>.from(data));
      return entry.value;
    }

    return data as T?;
  }

  @override
  Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    if (_cacheBox == null || _metadataBox == null) {
      throw Exception('CacheService not initialized. Call initialize() first.');
    }

    // Implement LRU eviction if cache is full
    if (_lruTracker.isFull && !_cacheBox!.containsKey(key)) {
      final lruKey = _lruTracker.getLeastRecentlyUsed();
      if (lruKey != null) {
        await delete(lruKey);
      }
    }

    final expiresAt = DateTime.now().add(ttl ?? _defaultTTL);
    final entry = CacheEntry<T>(
      value: value,
      expiresAt: expiresAt,
    );

    await _cacheBox!.put(key, entry.toJson());
    await _metadataBox!.put('${key}_expires', expiresAt.toIso8601String());

    // Update LRU tracker
    _lruTracker.access(key);
  }

  @override
  Future<void> delete(String key) async {
    if (_cacheBox == null || _metadataBox == null) {
      throw Exception('CacheService not initialized. Call initialize() first.');
    }

    await _cacheBox!.delete(key);
    await _metadataBox!.delete('${key}_expires');
    _lruTracker.remove(key);
  }

  @override
  Future<void> clear() async {
    if (_cacheBox == null || _metadataBox == null) {
      throw Exception('CacheService not initialized. Call initialize() first.');
    }

    await _cacheBox!.clear();
    await _metadataBox!.clear();
    _lruTracker = LRUTracker(maxSize: _maxCacheSize);
  }

  @override
  bool isExpired(String key) {
    if (_metadataBox == null) {
      return true;
    }

    final expiresAtStr = _metadataBox!.get('${key}_expires');
    if (expiresAtStr == null) {
      return true;
    }

    final expiresAt = DateTime.parse(expiresAtStr as String);
    return DateTime.now().isAfter(expiresAt);
  }

  @override
  Future<void> dispose() async {
    await _cacheBox?.close();
    await _metadataBox?.close();
  }

  /// Clean up expired entries
  Future<void> _cleanupExpiredEntries() async {
    if (_cacheBox == null) return;

    final keys = _cacheBox!.keys.cast<String>().toList();
    for (final key in keys) {
      if (isExpired(key)) {
        await delete(key);
      }
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStatistics() async {
    if (_cacheBox == null) {
      return {
        'totalEntries': 0,
        'maxSize': _maxCacheSize,
        'utilizationPercent': 0.0,
      };
    }

    final totalEntries = _cacheBox!.length;
    return {
      'totalEntries': totalEntries,
      'maxSize': _maxCacheSize,
      'utilizationPercent': (totalEntries / _maxCacheSize) * 100,
    };
  }
}

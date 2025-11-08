import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finance_app/core/services/cache_service.dart';

void main() {
  late CacheServiceImpl cacheService;

  setUp(() async {
    // Initialize Hive with temporary directory for testing
    await Hive.initFlutter();

    // Delete any existing test boxes
    try {
      await Hive.deleteBoxFromDisk('app_cache');
      await Hive.deleteBoxFromDisk('cache_metadata');
    } catch (e) {
      // Boxes don't exist, ignore
    }

    cacheService = CacheServiceImpl();
    await cacheService.initialize();
  });

  tearDown(() async {
    await cacheService.dispose();
    await Hive.deleteBoxFromDisk('app_cache');
    await Hive.deleteBoxFromDisk('cache_metadata');
  });

  group('CacheService - Initialization', () {
    test('should initialize successfully', () async {
      // Arrange
      final newCacheService = CacheServiceImpl();

      // Act
      await newCacheService.initialize();

      // Assert
      final value = await newCacheService.get<String>('test-key');
      expect(value, isNull);

      await newCacheService.dispose();
    });

    test('should throw exception when not initialized', () async {
      // Arrange
      final uninitializedService = CacheServiceImpl();

      // Act & Assert
      expect(
        () => uninitializedService.set('key', 'value'),
        throwsException,
      );
    });
  });

  group('CacheService - Set and Get', () {
    test('should set and get string value', () async {
      // Arrange
      const key = 'test-key';
      const value = 'test-value';

      // Act
      await cacheService.set(key, value);
      final result = await cacheService.get<String>(key);

      // Assert
      expect(result, value);
    });

    test('should set and get integer value', () async {
      // Arrange
      const key = 'number-key';
      const value = 42;

      // Act
      await cacheService.set(key, value);
      final result = await cacheService.get<int>(key);

      // Assert
      expect(result, value);
    });

    test('should set and get map value', () async {
      // Arrange
      const key = 'map-key';
      final value = {'name': 'John', 'age': 30};

      // Act
      await cacheService.set(key, value);
      final result = await cacheService.get<Map<String, dynamic>>(key);

      // Assert
      expect(result, isNotNull);
      expect(result!['name'], 'John');
      expect(result['age'], 30);
    });

    test('should set and get list value', () async {
      // Arrange
      const key = 'list-key';
      final value = [1, 2, 3, 4, 5];

      // Act
      await cacheService.set(key, value);
      final result = await cacheService.get<List<int>>(key);

      // Assert
      expect(result, value);
    });

    test('should return null for non-existent key', () async {
      // Act
      final result = await cacheService.get<String>('non-existent-key');

      // Assert
      expect(result, isNull);
    });

    test('should overwrite existing value', () async {
      // Arrange
      const key = 'test-key';
      const value1 = 'first-value';
      const value2 = 'second-value';

      // Act
      await cacheService.set(key, value1);
      await cacheService.set(key, value2);
      final result = await cacheService.get<String>(key);

      // Assert
      expect(result, value2);
    });
  });

  group('CacheService - TTL (Time To Live)', () {
    test('should respect custom TTL', () async {
      // Arrange
      const key = 'ttl-key';
      const value = 'ttl-value';
      const ttl = Duration(milliseconds: 100);

      // Act
      await cacheService.set(key, value, ttl: ttl);

      // Wait for TTL to expire
      await Future.delayed(const Duration(milliseconds: 150));

      final result = await cacheService.get<String>(key);

      // Assert
      expect(result, isNull);
    });

    test('should not expire before TTL', () async {
      // Arrange
      const key = 'ttl-key';
      const value = 'ttl-value';
      const ttl = Duration(seconds: 10);

      // Act
      await cacheService.set(key, value, ttl: ttl);
      final result = await cacheService.get<String>(key);

      // Assert
      expect(result, value);
    });

    test('should check if key is expired', () async {
      // Arrange
      const key = 'expired-key';
      const value = 'expired-value';
      const ttl = Duration(milliseconds: 50);

      // Act
      await cacheService.set(key, value, ttl: ttl);

      // Check before expiration
      expect(cacheService.isExpired(key), isFalse);

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 100));

      // Check after expiration
      expect(cacheService.isExpired(key), isTrue);
    });
  });

  group('CacheService - Delete', () {
    test('should delete existing key', () async {
      // Arrange
      const key = 'delete-key';
      const value = 'delete-value';

      await cacheService.set(key, value);

      // Act
      await cacheService.delete(key);
      final result = await cacheService.get<String>(key);

      // Assert
      expect(result, isNull);
    });

    test('should not throw when deleting non-existent key', () async {
      // Act & Assert
      expect(
        () => cacheService.delete('non-existent-key'),
        returnsNormally,
      );
    });
  });

  group('CacheService - Clear', () {
    test('should clear all cached items', () async {
      // Arrange
      await cacheService.set('key1', 'value1');
      await cacheService.set('key2', 'value2');
      await cacheService.set('key3', 'value3');

      // Act
      await cacheService.clear();

      // Assert
      expect(await cacheService.get<String>('key1'), isNull);
      expect(await cacheService.get<String>('key2'), isNull);
      expect(await cacheService.get<String>('key3'), isNull);
    });

    test('should clear metadata along with cache', () async {
      // Arrange
      await cacheService.set('key1', 'value1');

      // Act
      await cacheService.clear();

      // Assert
      expect(cacheService.isExpired('key1'), isTrue);
    });
  });

  group('CacheService - LRU Eviction', () {
    test('should track access order', () async {
      // Arrange
      await cacheService.set('key1', 'value1');
      await cacheService.set('key2', 'value2');

      // Act - Access key1 to make it more recently used
      await cacheService.get<String>('key1');

      // Assert - Both keys should still exist
      expect(await cacheService.get<String>('key1'), 'value1');
      expect(await cacheService.get<String>('key2'), 'value2');
    });

    test('should update access order on get', () async {
      // Arrange
      await cacheService.set('key1', 'value1');
      await Future.delayed(const Duration(milliseconds: 10));
      await cacheService.set('key2', 'value2');

      // Act - Access key1 multiple times
      await cacheService.get<String>('key1');
      await cacheService.get<String>('key1');

      // Assert
      expect(await cacheService.get<String>('key1'), 'value1');
      expect(await cacheService.get<String>('key2'), 'value2');
    });
  });

  group('CacheService - Statistics', () {
    test('should return correct statistics', () async {
      // Arrange
      await cacheService.set('key1', 'value1');
      await cacheService.set('key2', 'value2');
      await cacheService.set('key3', 'value3');

      // Act
      final stats = await cacheService.getStatistics();

      // Assert
      expect(stats['totalEntries'], 3);
      expect(stats['maxSize'], 1000);
      expect(stats['utilizationPercent'], greaterThan(0));
    });

    test('should return zero statistics for empty cache', () async {
      // Act
      final stats = await cacheService.getStatistics();

      // Assert
      expect(stats['totalEntries'], 0);
      expect(stats['utilizationPercent'], 0.0);
    });
  });

  group('CacheService - Complex Data Types', () {
    test('should cache complex nested objects', () async {
      // Arrange
      const key = 'complex-key';
      final value = {
        'user': {
          'id': 1,
          'name': 'John Doe',
          'email': 'john@example.com',
          'roles': ['admin', 'user'],
        },
        'settings': {
          'theme': 'dark',
          'notifications': true,
        },
        'metadata': {
          'lastLogin': '2024-01-01T00:00:00Z',
          'loginCount': 42,
        },
      };

      // Act
      await cacheService.set(key, value);
      final result = await cacheService.get<Map<String, dynamic>>(key);

      // Assert
      expect(result, isNotNull);
      expect(result!['user']['name'], 'John Doe');
      expect(result['user']['roles'], contains('admin'));
      expect(result['settings']['theme'], 'dark');
      expect(result['metadata']['loginCount'], 42);
    });

    test('should cache list of maps', () async {
      // Arrange
      const key = 'list-of-maps';
      final value = [
        {'id': 1, 'name': 'Item 1'},
        {'id': 2, 'name': 'Item 2'},
        {'id': 3, 'name': 'Item 3'},
      ];

      // Act
      await cacheService.set(key, value);
      final result = await cacheService.get<List<dynamic>>(key);

      // Assert
      expect(result, isNotNull);
      expect(result!.length, 3);
      expect(result[0]['name'], 'Item 1');
      expect(result[2]['id'], 3);
    });
  });

  group('CacheService - Concurrent Operations', () {
    test('should handle concurrent set operations', () async {
      // Arrange
      final futures = <Future>[];

      // Act
      for (int i = 0; i < 10; i++) {
        futures.add(cacheService.set('key-$i', 'value-$i'));
      }

      await Future.wait(futures);

      // Assert
      for (int i = 0; i < 10; i++) {
        final value = await cacheService.get<String>('key-$i');
        expect(value, 'value-$i');
      }
    });

    test('should handle concurrent get operations', () async {
      // Arrange
      await cacheService.set('shared-key', 'shared-value');

      // Act
      final futures = <Future<String?>>[];
      for (int i = 0; i < 10; i++) {
        futures.add(cacheService.get<String>('shared-key'));
      }

      final results = await Future.wait(futures);

      // Assert
      for (final result in results) {
        expect(result, 'shared-value');
      }
    });
  });

  group('CacheService - Edge Cases', () {
    test('should handle empty string value', () async {
      // Arrange
      const key = 'empty-key';
      const value = '';

      // Act
      await cacheService.set(key, value);
      final result = await cacheService.get<String>(key);

      // Assert
      expect(result, value);
    });

    test('should handle null values in maps', () async {
      // Arrange
      const key = 'null-map-key';
      final value = {'name': 'John', 'age': null};

      // Act
      await cacheService.set(key, value);
      final result = await cacheService.get<Map<String, dynamic>>(key);

      // Assert
      expect(result, isNotNull);
      expect(result!['name'], 'John');
      expect(result['age'], isNull);
    });

    test('should handle very long keys', () async {
      // Arrange
      final longKey = 'k' * 1000;
      const value = 'test-value';

      // Act
      await cacheService.set(longKey, value);
      final result = await cacheService.get<String>(longKey);

      // Assert
      expect(result, value);
    });

    test('should handle special characters in keys', () async {
      // Arrange
      const key = 'key-with-special-chars-!@#\$%^&*()';
      const value = 'special-value';

      // Act
      await cacheService.set(key, value);
      final result = await cacheService.get<String>(key);

      // Assert
      expect(result, value);
    });
  });

  group('CacheService - Persistence', () {
    test('should persist data across service instances', () async {
      // Arrange
      const key = 'persist-key';
      const value = 'persist-value';

      await cacheService.set(key, value);
      await cacheService.dispose();

      // Act - Create new instance
      final newCacheService = CacheServiceImpl();
      await newCacheService.initialize();
      final result = await newCacheService.get<String>(key);

      // Assert
      expect(result, value);

      await newCacheService.dispose();
    });
  });
}

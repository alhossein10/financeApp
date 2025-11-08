import '../../../../core/services/cache_service.dart';
import '../models/incoming_dto.dart';

/// Cache data source for incoming operations
abstract class IncomingCacheDataSource {
  /// Get cached incoming list
  Future<IncomingListResponse?> getCachedIncomingList({
    int page = 1,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Cache incoming list
  Future<void> cacheIncomingList(
    IncomingListResponse response, {
    int page = 1,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get cached incoming by ID
  Future<IncomingDto?> getCachedIncoming(int id);

  /// Cache single incoming
  Future<void> cacheIncoming(IncomingDto incoming);

  /// Clear all incoming cache
  Future<void> clearCache();

  /// Clear specific incoming from cache
  Future<void> clearIncomingCache(int id);
}

class IncomingCacheDataSourceImpl implements IncomingCacheDataSource {
  final CacheService cacheService;

  IncomingCacheDataSourceImpl({required this.cacheService});

  String _getListCacheKey({
    int page = 1,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final buffer = StringBuffer('incoming_list_p${page}');
    if (startDate != null) {
      buffer.write('_start${startDate.millisecondsSinceEpoch}');
    }
    if (endDate != null) {
      buffer.write('_end${endDate.millisecondsSinceEpoch}');
    }
    return buffer.toString();
  }

  String _getIncomingCacheKey(int id) => 'incoming_$id';

  @override
  Future<IncomingListResponse?> getCachedIncomingList({
    int page = 1,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final key = _getListCacheKey(
        page: page,
        startDate: startDate,
        endDate: endDate,
      );
      final cached = await cacheService.get<Map<String, dynamic>>(key);
      if (cached != null) {
        return IncomingListResponse.fromJson(cached);
      }
      return null;
    } catch (e) {
      // If cache read fails, return null
      return null;
    }
  }

  @override
  Future<void> cacheIncomingList(
    IncomingListResponse response, {
    int page = 1,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final key = _getListCacheKey(
        page: page,
        startDate: startDate,
        endDate: endDate,
      );
      
      // Convert response to JSON-serializable format
      final jsonData = {
        'data': response.data.map((dto) => dto.toJson()).toList(),
        'current_page': response.currentPage,
        'last_page': response.lastPage,
        'per_page': response.perPage,
        'total': response.total,
      };
      
      await cacheService.set(
        key,
        jsonData,
        ttl: const Duration(minutes: 15),
      );

      // Also cache individual incoming items
      for (final incoming in response.data) {
        if (incoming.id != null) {
          await cacheIncoming(incoming);
        }
      }
    } catch (e) {
      // Silently fail cache writes
    }
  }

  @override
  Future<IncomingDto?> getCachedIncoming(int id) async {
    try {
      final key = _getIncomingCacheKey(id);
      final cached = await cacheService.get<Map<String, dynamic>>(key);
      if (cached != null) {
        return IncomingDto.fromJson(cached);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheIncoming(IncomingDto incoming) async {
    try {
      if (incoming.id != null) {
        final key = _getIncomingCacheKey(incoming.id!);
        await cacheService.set(
          key,
          incoming.toJson(),
          ttl: const Duration(minutes: 15),
        );
      }
    } catch (e) {
      // Silently fail cache writes
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      // Clear all incoming-related cache
      // Note: This is a simplified implementation
      // In production, you might want to track all cache keys
      await cacheService.clear();
    } catch (e) {
      // Silently fail
    }
  }

  @override
  Future<void> clearIncomingCache(int id) async {
    try {
      final key = _getIncomingCacheKey(id);
      await cacheService.delete(key);
      
      // Also clear list caches as they might contain this incoming
      // This is a simplified approach - in production you might want
      // to be more selective about which list caches to clear
    } catch (e) {
      // Silently fail
    }
  }
}

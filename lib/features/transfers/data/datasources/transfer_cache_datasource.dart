import '../../../../core/services/cache_service.dart';
import '../models/transfer_dto.dart';

/// Cache data source for transfer operations
abstract class TransferCacheDataSource {
  Future<List<TransferDto>?> getCachedTransfers(int userId);
  Future<void> cacheTransfers(int userId, List<TransferDto> transfers);
  Future<TransferDto?> getCachedTransfer(int id);
  Future<void> cacheTransfer(TransferDto transfer);
  Future<void> invalidateTransferCache(int userId);
  Future<void> invalidateTransfer(int id);
}

class TransferCacheDataSourceImpl implements TransferCacheDataSource {
  final CacheService cacheService;
  static const Duration _cacheDuration = Duration(hours: 1);

  TransferCacheDataSourceImpl({required this.cacheService});

  String _getUserTransfersKey(int userId) => 'transfers_user_$userId';
  String _getTransferKey(int id) => 'transfer_$id';

  @override
  Future<List<TransferDto>?> getCachedTransfers(int userId) async {
    try {
      final cached = await cacheService.get<List<dynamic>>(
        _getUserTransfersKey(userId),
      );

      if (cached == null) return null;

      return cached
          .map((item) => TransferDto.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheTransfers(int userId, List<TransferDto> transfers) async {
    try {
      final jsonList = transfers.map((t) => t.toJson()).toList();
      await cacheService.set(
        _getUserTransfersKey(userId),
        jsonList,
        ttl: _cacheDuration,
      );
    } catch (e) {
      // Silently fail cache operations
    }
  }

  @override
  Future<TransferDto?> getCachedTransfer(int id) async {
    try {
      final cached = await cacheService.get<Map<String, dynamic>>(
        _getTransferKey(id),
      );

      if (cached == null) return null;

      return TransferDto.fromJson(cached);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheTransfer(TransferDto transfer) async {
    try {
      if (transfer.id != null) {
        await cacheService.set(
          _getTransferKey(transfer.id!),
          transfer.toJson(),
          ttl: _cacheDuration,
        );
      }
    } catch (e) {
      // Silently fail cache operations
    }
  }

  @override
  Future<void> invalidateTransferCache(int userId) async {
    try {
      await cacheService.delete(_getUserTransfersKey(userId));
    } catch (e) {
      // Silently fail cache operations
    }
  }

  @override
  Future<void> invalidateTransfer(int id) async {
    try {
      await cacheService.delete(_getTransferKey(id));
    } catch (e) {
      // Silently fail cache operations
    }
  }
}

import 'dart:async';
import 'connectivity_service.dart';
import 'offline_cache_service.dart';
import 'offline_operation_queue.dart';
import '../../features/fund_box/data/models/fund_box_dto.dart';
import '../../features/expenses/data/models/expense_dto.dart';
import '../../features/transfers/data/models/transfer_dto.dart';
import '../../core/api/models/user_dto.dart';

/// Central manager for offline functionality
/// Coordinates caching, operation queuing, and sync
class OfflineManager {
  final ConnectivityService _connectivityService;
  final OfflineCacheService _cacheService;
  final OfflineOperationQueue _operationQueue;

  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  final _offlineStatusController = StreamController<OfflineStatus>.broadcast();

  Stream<OfflineStatus> get offlineStatusStream => _offlineStatusController.stream;

  OfflineManager({
    required ConnectivityService connectivityService,
    required OfflineCacheService cacheService,
    required OfflineOperationQueue operationQueue,
  })  : _connectivityService = connectivityService,
        _cacheService = cacheService,
        _operationQueue = operationQueue;

  /// Initialize offline manager
  Future<void> initialize() async {
    await _cacheService.initialize();
    await _operationQueue.initialize();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.statusStream.listen(
      (status) {
        _updateOfflineStatus();
      },
    );

    _updateOfflineStatus();
  }

  /// Update offline status
  void _updateOfflineStatus() {
    final isOffline = !_connectivityService.isOnline;
    final hasPendingOps = _operationQueue.isSyncing;

    if (isOffline) {
      _offlineStatusController.add(OfflineStatus.offline);
    } else if (hasPendingOps) {
      _offlineStatusController.add(OfflineStatus.syncing);
    } else {
      _offlineStatusController.add(OfflineStatus.online);
    }
  }

  // ==================== Connectivity ====================

  /// Check if currently online
  bool get isOnline => _connectivityService.isOnline;

  /// Check if currently offline
  bool get isOffline => !_connectivityService.isOnline;

  // ==================== Caching ====================

  /// Cache fund box data
  Future<void> cacheFundBox(String userId, FundBoxDto fundBox) async {
    await _cacheService.cacheFundBox(userId, fundBox);
  }

  /// Get cached fund box data
  Future<FundBoxDto?> getCachedFundBox(String userId) async {
    return await _cacheService.getCachedFundBox(userId);
  }

  /// Cache expenses
  Future<void> cacheExpenses(String userId, List<ExpenseDto> expenses) async {
    await _cacheService.cacheExpenses(userId, expenses);
  }

  /// Get cached expenses
  Future<List<ExpenseDto>> getCachedExpenses(String userId) async {
    return await _cacheService.getCachedExpenses(userId);
  }

  /// Cache transfers
  Future<void> cacheTransfers(String userId, List<TransferDto> transfers) async {
    await _cacheService.cacheTransfers(userId, transfers);
  }

  /// Get cached transfers
  Future<List<TransferDto>> getCachedTransfers(String userId) async {
    return await _cacheService.getCachedTransfers(userId);
  }

  /// Cache user profile
  Future<void> cacheUserProfile(String userId, UserDto user) async {
    await _cacheService.cacheUserProfile(userId, user);
  }

  /// Get cached user profile
  Future<UserDto?> getCachedUserProfile(String userId) async {
    return await _cacheService.getCachedUserProfile(userId);
  }

  /// Get cache timestamps
  DateTime? getFundBoxCacheTimestamp(String userId) {
    return _cacheService.getFundBoxCacheTimestamp(userId);
  }

  DateTime? getExpensesCacheTimestamp(String userId) {
    return _cacheService.getExpensesCacheTimestamp(userId);
  }

  DateTime? getTransfersCacheTimestamp(String userId) {
    return _cacheService.getTransfersCacheTimestamp(userId);
  }

  // ==================== Operation Queue ====================

  /// Queue expense creation
  Future<void> queueExpenseCreation(ExpenseDto expense) async {
    await _operationQueue.queueExpenseCreation(expense);
    // Also add to cache optimistically
    // Note: userId should be extracted from expense or passed separately
  }

  /// Queue expense update
  Future<void> queueExpenseUpdate(ExpenseDto expense) async {
    await _operationQueue.queueExpenseUpdate(expense);
  }

  /// Queue transfer creation
  Future<void> queueTransferCreation(TransferDto transfer) async {
    await _operationQueue.queueTransferCreation(transfer);
  }

  /// Sync queued operations
  Future<void> syncQueue() async {
    await _operationQueue.syncQueue();
  }

  /// Get pending operations count
  Future<int> getPendingOperationsCount() async {
    return await _operationQueue.getPendingCount();
  }

  /// Get failed operations count
  Future<int> getFailedOperationsCount() async {
    return await _operationQueue.getFailedCount();
  }

  /// Retry failed operations
  Future<void> retryFailedOperations() async {
    await _operationQueue.retryFailedOperations();
  }

  // ==================== Balance Operations ====================

  /// Check if balance-dependent operations can be performed
  /// Returns false when offline since balance verification requires real-time data
  bool canPerformBalanceOperation() {
    return isOnline;
  }

  /// Get reason why balance operation cannot be performed
  String? getBalanceOperationBlockReason() {
    if (isOffline) {
      return 'Cannot perform this operation offline. Real-time balance verification required.';
    }
    return null;
  }

  // ==================== Statistics ====================

  /// Get offline statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final cacheStats = await _cacheService.getCacheStatistics();
    final queueStats = await _operationQueue.getStatistics();

    return {
      'isOnline': isOnline,
      'cache': cacheStats,
      'queue': queueStats,
    };
  }

  // ==================== Cache Management ====================

  /// Clear all cached data for a user
  Future<void> clearUserCache(String userId) async {
    await _cacheService.clearUserCache(userId);
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    await _cacheService.clearAllCache();
  }

  // ==================== Disposal ====================

  /// Dispose resources
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _offlineStatusController.close();
    await _cacheService.dispose();
    await _operationQueue.dispose();
  }
}

/// Offline status enum
enum OfflineStatus {
  online,
  offline,
  syncing;

  bool get isOnline => this == OfflineStatus.online;
  bool get isOffline => this == OfflineStatus.offline;
  bool get isSyncing => this == OfflineStatus.syncing;

  String get displayText {
    switch (this) {
      case OfflineStatus.online:
        return 'Online';
      case OfflineStatus.offline:
        return 'Offline';
      case OfflineStatus.syncing:
        return 'Syncing';
    }
  }
}


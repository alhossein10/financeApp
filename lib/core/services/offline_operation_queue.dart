import 'dart:async';
import '../models/queue_item.dart';
import 'queue_manager.dart';
import 'connectivity_service.dart';
import '../../features/expenses/data/datasources/expense_api_datasource.dart';
import '../../features/transfers/data/datasources/transfer_api_datasource.dart';
import '../../features/fund_box/data/datasources/fund_box_api_datasource.dart';
import '../../features/expenses/data/models/expense_dto.dart';
import '../../features/transfers/data/models/transfer_dto.dart';

/// Service for managing offline operations queue
/// Queues create/update operations when offline and syncs when connection restores
class OfflineOperationQueue {
  final QueueManager _queueManager;
  final ConnectivityService _connectivityService;
  final ExpenseApiDataSource _expenseApi;
  final TransferApiDataSource _transferApi;
  final FundBoxApiDataSource _fundBoxApi;

  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  Timer? _retryTimer;
  bool _isProcessing = false;

  final _syncStatusController = StreamController<OfflineSyncStatus>.broadcast();
  Stream<OfflineSyncStatus> get syncStatusStream => _syncStatusController.stream;

  OfflineOperationQueue({
    required QueueManager queueManager,
    required ConnectivityService connectivityService,
    required ExpenseApiDataSource expenseApi,
    required TransferApiDataSource transferApi,
    required FundBoxApiDataSource fundBoxApi,
  })  : _queueManager = queueManager,
        _connectivityService = connectivityService,
        _expenseApi = expenseApi,
        _transferApi = transferApi,
        _fundBoxApi = fundBoxApi;

  /// Initialize the operation queue
  Future<void> initialize() async {
    await _queueManager.initialize();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.statusStream.listen(
      (status) {
        if (status.isOnline && !_isProcessing) {
          // Automatically sync when connection restores
          syncQueue();
        } else if (status.isOffline) {
          _syncStatusController.add(OfflineSyncStatus.offline);
        }
      },
    );

    // Process queue if already online
    if (_connectivityService.isOnline) {
      await syncQueue();
    }
  }

  // ==================== Queue Operations ====================

  /// Queue an expense creation operation
  Future<void> queueExpenseCreation(ExpenseDto expense) async {
    final item = QueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      operation: QueueOperation.create,
      resourceType: 'expense',
      data: expense.toJson(),
      status: QueueStatus.pending,
      createdAt: DateTime.now(),
      retryCount: 0,
    );
    await _queueManager.enqueue(item);
    _syncStatusController.add(OfflineSyncStatus.queued);
  }

  /// Queue an expense update operation
  Future<void> queueExpenseUpdate(ExpenseDto expense) async {
    final item = QueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      operation: QueueOperation.update,
      resourceType: 'expense',
      data: expense.toJson(),
      status: QueueStatus.pending,
      createdAt: DateTime.now(),
      retryCount: 0,
    );
    await _queueManager.enqueue(item);
    _syncStatusController.add(OfflineSyncStatus.queued);
  }

  /// Queue a transfer creation operation
  Future<void> queueTransferCreation(TransferDto transfer) async {
    final item = QueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      operation: QueueOperation.create,
      resourceType: 'transfer',
      data: transfer.toJson(),
      status: QueueStatus.pending,
      createdAt: DateTime.now(),
      retryCount: 0,
    );
    await _queueManager.enqueue(item);
    _syncStatusController.add(OfflineSyncStatus.queued);
  }

  // ==================== Sync Operations ====================

  /// Sync all queued operations
  Future<void> syncQueue() async {
    if (_isProcessing) {
      return; // Already processing
    }

    if (!_connectivityService.isOnline) {
      _syncStatusController.add(OfflineSyncStatus.offline);
      return;
    }

    _isProcessing = true;
    _syncStatusController.add(OfflineSyncStatus.syncing);

    try {
      final pendingItems = await _queueManager.getPendingItems();

      if (pendingItems.isEmpty) {
        _syncStatusController.add(OfflineSyncStatus.synced);
        _isProcessing = false;
        return;
      }

      int successCount = 0;
      int failureCount = 0;
      final List<String> errors = [];

      for (final item in pendingItems) {
        try {
          // Update status to processing
          await _queueManager.updateItemStatus(item.id, QueueStatus.processing);

          // Process the item based on operation type
          await _processQueueItem(item);

          // Remove from queue on success
          await _queueManager.dequeue(item.id);
          successCount++;
        } catch (e) {
          // Mark as failed
          await _queueManager.updateItemStatus(
            item.id,
            QueueStatus.failed,
            errorMessage: e.toString(),
          );
          failureCount++;
          errors.add('${item.operation.name}_${item.resourceType}: ${e.toString()}');

          // Schedule retry with exponential backoff
          _scheduleRetry(item);
        }
      }

      // Update sync status
      if (failureCount == 0) {
        _syncStatusController.add(OfflineSyncStatus.synced);
      } else if (successCount > 0) {
        _syncStatusController.add(OfflineSyncStatus.partialSync);
      } else {
        _syncStatusController.add(OfflineSyncStatus.failed);
      }

      print('[OfflineOperationQueue] Sync completed: $successCount succeeded, $failureCount failed');
      if (errors.isNotEmpty) {
        print('[OfflineOperationQueue] Errors: ${errors.join(', ')}');
      }
    } catch (e) {
      print('[OfflineOperationQueue] Sync error: $e');
      _syncStatusController.add(OfflineSyncStatus.failed);
    } finally {
      _isProcessing = false;
    }
  }

  /// Process a single queue item
  Future<void> _processQueueItem(QueueItem item) async {
    switch (item.resourceType) {
      case 'expense':
        final expense = ExpenseDto.fromJson(item.data);
        if (item.operation == QueueOperation.create) {
          await _expenseApi.createExpense(expense);
        } else if (item.operation == QueueOperation.update) {
          await _expenseApi.updateExpense(expense.id!, expense);
        }
        break;

      case 'transfer':
        final transfer = TransferDto.fromJson(item.data);
        if (item.operation == QueueOperation.create) {
          await _transferApi.createTransfer(transfer);
        }
        break;

      default:
        throw Exception('Unknown resource type: ${item.resourceType}');
    }
  }

  /// Schedule retry for failed item with exponential backoff
  void _scheduleRetry(QueueItem item) {
    if (!item.shouldRetry) {
      print('[OfflineOperationQueue] Max retries reached for item ${item.id}');
      return;
    }

    final delay = item.nextRetryDelay;
    print('[OfflineOperationQueue] Scheduling retry for item ${item.id} in ${delay.inSeconds}s');
    
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      syncQueue();
    });
  }

  // ==================== Conflict Resolution ====================

  /// Handle sync conflicts
  /// This is a simple implementation - can be enhanced based on requirements
  Future<void> handleConflict(QueueItem item, dynamic serverData) async {
    // For now, server data wins (last-write-wins strategy)
    // Can be enhanced to show conflict resolution UI to user
    print('[OfflineOperationQueue] Conflict detected for ${item.operation.name}_${item.resourceType}, using server data');
    await _queueManager.dequeue(item.id);
  }

  // ==================== Queue Management ====================

  /// Get pending operations count
  Future<int> getPendingCount() async {
    final items = await _queueManager.getPendingItems();
    return items.length;
  }

  /// Get failed operations count
  Future<int> getFailedCount() async {
    final items = await _queueManager.getFailedItems();
    return items.length;
  }

  /// Get all pending operations
  Future<List<QueueItem>> getPendingOperations() async {
    return await _queueManager.getPendingItems();
  }

  /// Get all failed operations
  Future<List<QueueItem>> getFailedOperations() async {
    return await _queueManager.getFailedItems();
  }

  /// Manually retry failed operations
  Future<void> retryFailedOperations() async {
    await _queueManager.retryFailedItems();
    await syncQueue();
  }

  /// Clear all queued operations
  Future<void> clearQueue() async {
    await _queueManager.clearQueue();
    _syncStatusController.add(OfflineSyncStatus.synced);
  }

  /// Get queue statistics
  Future<Map<String, dynamic>> getStatistics() async {
    return await _queueManager.getStatistics();
  }

  // ==================== Status Checks ====================

  /// Check if there are pending operations
  Future<bool> hasPendingOperations() async {
    final count = await getPendingCount();
    return count > 0;
  }

  /// Check if currently syncing
  bool get isSyncing => _isProcessing;

  /// Check if online
  bool get isOnline => _connectivityService.isOnline;

  // ==================== Disposal ====================

  /// Dispose resources
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
    await _syncStatusController.close();
    await _queueManager.dispose();
  }
}

/// Offline sync status
enum OfflineSyncStatus {
  synced,
  syncing,
  offline,
  failed,
  partialSync,
  queued;

  bool get isSynced => this == OfflineSyncStatus.synced;
  bool get isSyncing => this == OfflineSyncStatus.syncing;
  bool get isOffline => this == OfflineSyncStatus.offline;
  bool get isFailed => this == OfflineSyncStatus.failed;
  bool get isPartialSync => this == OfflineSyncStatus.partialSync;
  bool get isQueued => this == OfflineSyncStatus.queued;

  String get displayText {
    switch (this) {
      case OfflineSyncStatus.synced:
        return 'All changes synced';
      case OfflineSyncStatus.syncing:
        return 'Syncing changes...';
      case OfflineSyncStatus.offline:
        return 'Offline - changes will sync when online';
      case OfflineSyncStatus.failed:
        return 'Sync failed - will retry';
      case OfflineSyncStatus.partialSync:
        return 'Some changes synced';
      case OfflineSyncStatus.queued:
        return 'Changes queued for sync';
    }
  }

  String get icon {
    switch (this) {
      case OfflineSyncStatus.synced:
        return '✓';
      case OfflineSyncStatus.syncing:
        return '↻';
      case OfflineSyncStatus.offline:
        return '⚠';
      case OfflineSyncStatus.failed:
        return '✗';
      case OfflineSyncStatus.partialSync:
        return '⚠';
      case OfflineSyncStatus.queued:
        return '⋯';
    }
  }
}


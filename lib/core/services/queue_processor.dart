import 'dart:async';
import '../models/queue_item.dart';
import 'queue_manager.dart';
import 'connectivity_monitor.dart';

/// Callback for processing queue items
typedef QueueItemProcessor = Future<void> Function(QueueItem item);

/// Queue processor with connectivity monitoring and exponential backoff
class QueueProcessor {
  final QueueManager _queueManager;
  final ConnectivityMonitor _connectivityMonitor;
  final QueueItemProcessor _processor;

  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  Timer? _retryTimer;
  bool _isProcessing = false;

  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  QueueProcessor({
    required QueueManager queueManager,
    required ConnectivityMonitor connectivityMonitor,
    required QueueItemProcessor processor,
  })  : _queueManager = queueManager,
        _connectivityMonitor = connectivityMonitor,
        _processor = processor;

  /// Initialize queue processor
  Future<void> initialize() async {
    // Listen to connectivity changes
    _connectivitySubscription = _connectivityMonitor.connectivityStream.listen(
      (status) {
        if (status.isOnline && !_isProcessing) {
          // Trigger queue processing when coming online
          processQueue();
        }
      },
    );

    // Process queue if already online
    if (await _connectivityMonitor.isOnline) {
      await processQueue();
    }
  }

  /// Process all pending items in the queue
  Future<void> processQueue() async {
    if (_isProcessing) {
      return; // Already processing
    }

    _isProcessing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      // Check connectivity
      if (!(await _connectivityMonitor.isOnline)) {
        _syncStatusController.add(SyncStatus.offline);
        _isProcessing = false;
        return;
      }

      final pendingItems = await _queueManager.getPendingItems();

      if (pendingItems.isEmpty) {
        _syncStatusController.add(SyncStatus.synced);
        _isProcessing = false;
        return;
      }

      int successCount = 0;
      int failureCount = 0;

      for (final item in pendingItems) {
        try {
          // Update status to processing
          await _queueManager.updateItemStatus(item.id, QueueStatus.processing);

          // Process the item using the provided processor
          await _processor(item);

          // Remove from queue on success
          await _queueManager.dequeue(item.id);
          successCount++;
        } catch (e) {
          // Mark as failed with exponential backoff
          await _queueManager.updateItemStatus(
            item.id,
            QueueStatus.failed,
            errorMessage: e.toString(),
          );
          failureCount++;

          // Schedule retry with exponential backoff
          _scheduleRetry(item);
        }
      }

      // Update sync status
      if (failureCount == 0) {
        _syncStatusController.add(SyncStatus.synced);
      } else if (successCount > 0) {
        _syncStatusController.add(SyncStatus.partialSync);
      } else {
        _syncStatusController.add(SyncStatus.failed);
      }
    } catch (e) {
      _syncStatusController.add(SyncStatus.failed);
    } finally {
      _isProcessing = false;
    }
  }

  /// Schedule retry for failed item with exponential backoff
  void _scheduleRetry(QueueItem item) {
    if (!item.shouldRetry) {
      return;
    }

    final delay = item.nextRetryDelay;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      processQueue();
    });
  }

  /// Manually retry failed items
  Future<void> retryFailedItems() async {
    await _queueManager.retryFailedItems();
    await processQueue();
  }

  /// Get queue statistics
  Future<Map<String, dynamic>> getStatistics() async {
    return await _queueManager.getStatistics();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
    await _syncStatusController.close();
  }
}

/// Sync status for UI updates
enum SyncStatus {
  synced,
  syncing,
  offline,
  failed,
  partialSync;

  bool get isSynced => this == SyncStatus.synced;
  bool get isSyncing => this == SyncStatus.syncing;
  bool get isOffline => this == SyncStatus.offline;
  bool get isFailed => this == SyncStatus.failed;
  bool get isPartialSync => this == SyncStatus.partialSync;

  String get displayText {
    switch (this) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.failed:
        return 'Sync Failed';
      case SyncStatus.partialSync:
        return 'Partially Synced';
    }
  }
}

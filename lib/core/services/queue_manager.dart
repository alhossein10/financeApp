import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/queue_item.dart';

/// Queue manager for offline operations
abstract class QueueManager {
  Future<void> enqueue(QueueItem item);
  Future<void> dequeue(String id);
  Future<void> processQueue();
  Future<List<QueueItem>> getPendingItems();
  Future<List<QueueItem>> getFailedItems();
  Future<void> clearQueue();
  Future<void> retryFailedItems();
  Future<Map<String, dynamic>> getStatistics();
  Stream<QueueStatus> get queueStatus;
  Future<void> initialize();
  Future<void> dispose();
}

class QueueManagerImpl implements QueueManager {
  static const String _boxName = 'offline_queue';
  Box? _queueBox;
  final _uuid = const Uuid();
  final _statusController = StreamController<QueueStatus>.broadcast();

  @override
  Stream<QueueStatus> get queueStatus => _statusController.stream;

  @override
  Future<void> initialize() async {
    await Hive.initFlutter();
    _queueBox = await Hive.openBox(_boxName);
  }

  @override
  Future<void> enqueue(QueueItem item) async {
    if (_queueBox == null) {
      throw Exception('QueueManager not initialized. Call initialize() first.');
    }

    // Generate UUID if not provided
    final queueItem = item.id.isEmpty
        ? item.copyWith(id: _uuid.v4())
        : item;

    await _queueBox!.put(queueItem.id, queueItem.toJson());
    _statusController.add(QueueStatus.pending);
  }

  @override
  Future<void> dequeue(String id) async {
    if (_queueBox == null) {
      throw Exception('QueueManager not initialized. Call initialize() first.');
    }

    await _queueBox!.delete(id);
  }

  @override
  Future<void> processQueue() async {
    if (_queueBox == null) {
      throw Exception('QueueManager not initialized. Call initialize() first.');
    }

    final pendingItems = await getPendingItems();
    
    for (final item in pendingItems) {
      try {
        // Update status to processing
        final processingItem = item.copyWith(status: QueueStatus.processing);
        await _queueBox!.put(item.id, processingItem.toJson());
        _statusController.add(QueueStatus.processing);

        // Note: Actual API call will be handled by the caller
        // This method just manages the queue state
        // The caller should call dequeue() after successful API call
        
      } catch (e) {
        // Mark as failed and increment retry count
        final failedItem = item.copyWith(
          status: QueueStatus.failed,
          retryCount: item.retryCount + 1,
          errorMessage: e.toString(),
        );
        await _queueBox!.put(item.id, failedItem.toJson());
        _statusController.add(QueueStatus.failed);
      }
    }
  }

  @override
  Future<List<QueueItem>> getPendingItems() async {
    if (_queueBox == null) {
      throw Exception('QueueManager not initialized. Call initialize() first.');
    }

    final items = <QueueItem>[];
    for (final key in _queueBox!.keys) {
      final data = _queueBox!.get(key);
      if (data != null) {
        final item = QueueItem.fromJson(Map<String, dynamic>.from(data as Map));
        if (item.status == QueueStatus.pending) {
          items.add(item);
        }
      }
    }

    // Sort by creation date (oldest first)
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  @override
  Future<List<QueueItem>> getFailedItems() async {
    if (_queueBox == null) {
      throw Exception('QueueManager not initialized. Call initialize() first.');
    }

    final items = <QueueItem>[];
    for (final key in _queueBox!.keys) {
      final data = _queueBox!.get(key);
      if (data != null) {
        final item = QueueItem.fromJson(Map<String, dynamic>.from(data as Map));
        if (item.status == QueueStatus.failed) {
          items.add(item);
        }
      }
    }

    return items;
  }

  @override
  Future<void> clearQueue() async {
    if (_queueBox == null) {
      throw Exception('QueueManager not initialized. Call initialize() first.');
    }

    await _queueBox!.clear();
  }

  @override
  Future<void> retryFailedItems() async {
    if (_queueBox == null) {
      throw Exception('QueueManager not initialized. Call initialize() first.');
    }

    final failedItems = await getFailedItems();
    
    for (final item in failedItems) {
      if (item.shouldRetry) {
        // Reset to pending status for retry
        final retryItem = item.copyWith(
          status: QueueStatus.pending,
          errorMessage: null,
        );
        await _queueBox!.put(item.id, retryItem.toJson());
        _statusController.add(QueueStatus.pending);
      }
    }
  }

  @override
  Future<void> dispose() async {
    await _statusController.close();
    await _queueBox?.close();
  }

  /// Get queue statistics
  @override
  Future<Map<String, dynamic>> getStatistics() async {
    if (_queueBox == null) {
      return {
        'total': 0,
        'pending': 0,
        'processing': 0,
        'failed': 0,
      };
    }

    int total = 0;
    int pending = 0;
    int processing = 0;
    int failed = 0;

    for (final key in _queueBox!.keys) {
      final data = _queueBox!.get(key);
      if (data != null) {
        total++;
        final item = QueueItem.fromJson(Map<String, dynamic>.from(data as Map));
        switch (item.status) {
          case QueueStatus.pending:
            pending++;
            break;
          case QueueStatus.processing:
            processing++;
            break;
          case QueueStatus.failed:
            failed++;
            break;
        }
      }
    }

    return {
      'total': total,
      'pending': pending,
      'processing': processing,
      'failed': failed,
    };
  }

  /// Update queue item status
  Future<void> updateItemStatus(
    String id,
    QueueStatus status, {
    String? errorMessage,
  }) async {
    if (_queueBox == null) {
      throw Exception('QueueManager not initialized. Call initialize() first.');
    }

    final data = _queueBox!.get(id);
    if (data != null) {
      final item = QueueItem.fromJson(Map<String, dynamic>.from(data as Map));
      final updatedItem = item.copyWith(
        status: status,
        errorMessage: errorMessage,
        retryCount: status == QueueStatus.failed ? item.retryCount + 1 : item.retryCount,
      );
      await _queueBox!.put(id, updatedItem.toJson());
      _statusController.add(status);
    }
  }
}

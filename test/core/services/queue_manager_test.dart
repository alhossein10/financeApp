import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finance_app/core/models/queue_item.dart';
import 'package:finance_app/core/services/queue_manager.dart';

void main() {
  late QueueManagerImpl queueManager;

  setUp(() async {
    // Initialize Hive with temporary directory for testing
    await Hive.initFlutter();
    
    // Delete any existing test boxes
    try {
      await Hive.deleteBoxFromDisk('offline_queue');
    } catch (e) {
      // Box doesn't exist, ignore
    }

    queueManager = QueueManagerImpl();
    await queueManager.initialize();
  });

  tearDown(() async {
    await queueManager.dispose();
    await Hive.deleteBoxFromDisk('offline_queue');
  });

  group('QueueManager - Initialization', () {
    test('should initialize successfully', () async {
      // Arrange
      final newQueueManager = QueueManagerImpl();

      // Act
      await newQueueManager.initialize();

      // Assert
      final items = await newQueueManager.getPendingItems();
      expect(items, isEmpty);

      await newQueueManager.dispose();
    });

    test('should throw exception when not initialized', () async {
      // Arrange
      final uninitializedManager = QueueManagerImpl();

      // Act & Assert
      expect(
        () => uninitializedManager.enqueue(
          QueueItem(
            id: '',
            operation: QueueOperation.create,
            resourceType: 'expense',
            data: {},
            createdAt: DateTime.now(),
          ),
        ),
        throwsException,
      );
    });
  });

  group('QueueManager - Enqueue', () {
    test('should enqueue item successfully', () async {
      // Arrange
      final queueItem = QueueItem(
        id: '',
        operation: QueueOperation.create,
        resourceType: 'expense',
        data: {'description': 'Test expense', 'amount': 100.0},
        createdAt: DateTime.now(),
      );

      // Act
      await queueManager.enqueue(queueItem);

      // Assert
      final items = await queueManager.getPendingItems();
      expect(items.length, 1);
      expect(items.first.resourceType, 'expense');
      expect(items.first.operation, QueueOperation.create);
      expect(items.first.data['description'], 'Test expense');
    });

    test('should generate UUID when id is empty', () async {
      // Arrange
      final queueItem = QueueItem(
        id: '',
        operation: QueueOperation.update,
        resourceType: 'transfer',
        data: {'amount': 50.0},
        createdAt: DateTime.now(),
      );

      // Act
      await queueManager.enqueue(queueItem);

      // Assert
      final items = await queueManager.getPendingItems();
      expect(items.first.id, isNotEmpty);
      expect(items.first.id.length, 36); // UUID length
    });

    test('should preserve provided id', () async {
      // Arrange
      const customId = 'custom-id-123';
      final queueItem = QueueItem(
        id: customId,
        operation: QueueOperation.delete,
        resourceType: 'incoming',
        data: {'id': 1},
        createdAt: DateTime.now(),
      );

      // Act
      await queueManager.enqueue(queueItem);

      // Assert
      final items = await queueManager.getPendingItems();
      expect(items.first.id, customId);
    });

    test('should enqueue multiple items', () async {
      // Arrange
      final items = [
        QueueItem(
          id: '',
          operation: QueueOperation.create,
          resourceType: 'expense',
          data: {'amount': 100.0},
          createdAt: DateTime.now(),
        ),
        QueueItem(
          id: '',
          operation: QueueOperation.update,
          resourceType: 'transfer',
          data: {'amount': 200.0},
          createdAt: DateTime.now().add(const Duration(seconds: 1)),
        ),
        QueueItem(
          id: '',
          operation: QueueOperation.delete,
          resourceType: 'incoming',
          data: {'id': 1},
          createdAt: DateTime.now().add(const Duration(seconds: 2)),
        ),
      ];

      // Act
      for (final item in items) {
        await queueManager.enqueue(item);
      }

      // Assert
      final pendingItems = await queueManager.getPendingItems();
      expect(pendingItems.length, 3);
    });
  });

  group('QueueManager - Dequeue', () {
    test('should dequeue item successfully', () async {
      // Arrange
      final queueItem = QueueItem(
        id: 'test-id-1',
        operation: QueueOperation.create,
        resourceType: 'expense',
        data: {'amount': 100.0},
        createdAt: DateTime.now(),
      );

      await queueManager.enqueue(queueItem);

      // Act
      await queueManager.dequeue('test-id-1');

      // Assert
      final items = await queueManager.getPendingItems();
      expect(items, isEmpty);
    });

    test('should not throw when dequeuing non-existent item', () async {
      // Act & Assert
      expect(
        () => queueManager.dequeue('non-existent-id'),
        returnsNormally,
      );
    });
  });

  group('QueueManager - Get Pending Items', () {
    test('should return empty list when no items', () async {
      // Act
      final items = await queueManager.getPendingItems();

      // Assert
      expect(items, isEmpty);
    });

    test('should return only pending items', () async {
      // Arrange
      final pendingItem = QueueItem(
        id: 'pending-1',
        operation: QueueOperation.create,
        resourceType: 'expense',
        data: {},
        createdAt: DateTime.now(),
        status: QueueStatus.pending,
      );

      final processingItem = QueueItem(
        id: 'processing-1',
        operation: QueueOperation.update,
        resourceType: 'transfer',
        data: {},
        createdAt: DateTime.now(),
        status: QueueStatus.processing,
      );

      final failedItem = QueueItem(
        id: 'failed-1',
        operation: QueueOperation.delete,
        resourceType: 'incoming',
        data: {},
        createdAt: DateTime.now(),
        status: QueueStatus.failed,
      );

      await queueManager.enqueue(pendingItem);
      await queueManager.enqueue(processingItem);
      await queueManager.enqueue(failedItem);

      // Act
      final items = await queueManager.getPendingItems();

      // Assert
      expect(items.length, 1);
      expect(items.first.status, QueueStatus.pending);
    });

    test('should sort items by creation date (oldest first)', () async {
      // Arrange
      final now = DateTime.now();
      final items = [
        QueueItem(
          id: 'item-3',
          operation: QueueOperation.create,
          resourceType: 'expense',
          data: {},
          createdAt: now.add(const Duration(seconds: 2)),
        ),
        QueueItem(
          id: 'item-1',
          operation: QueueOperation.create,
          resourceType: 'expense',
          data: {},
          createdAt: now,
        ),
        QueueItem(
          id: 'item-2',
          operation: QueueOperation.create,
          resourceType: 'expense',
          data: {},
          createdAt: now.add(const Duration(seconds: 1)),
        ),
      ];

      for (final item in items) {
        await queueManager.enqueue(item);
      }

      // Act
      final pendingItems = await queueManager.getPendingItems();

      // Assert
      expect(pendingItems[0].id, 'item-1');
      expect(pendingItems[1].id, 'item-2');
      expect(pendingItems[2].id, 'item-3');
    });
  });

  group('QueueManager - Get Failed Items', () {
    test('should return only failed items', () async {
      // Arrange
      final pendingItem = QueueItem(
        id: 'pending-1',
        operation: QueueOperation.create,
        resourceType: 'expense',
        data: {},
        createdAt: DateTime.now(),
        status: QueueStatus.pending,
      );

      final failedItem = QueueItem(
        id: 'failed-1',
        operation: QueueOperation.update,
        resourceType: 'transfer',
        data: {},
        createdAt: DateTime.now(),
        status: QueueStatus.failed,
        errorMessage: 'Network error',
      );

      await queueManager.enqueue(pendingItem);
      await queueManager.enqueue(failedItem);

      // Act
      final items = await queueManager.getFailedItems();

      // Assert
      expect(items.length, 1);
      expect(items.first.status, QueueStatus.failed);
      expect(items.first.errorMessage, 'Network error');
    });
  });

  group('QueueManager - Clear Queue', () {
    test('should clear all items from queue', () async {
      // Arrange
      for (int i = 0; i < 5; i++) {
        await queueManager.enqueue(
          QueueItem(
            id: 'item-$i',
            operation: QueueOperation.create,
            resourceType: 'expense',
            data: {},
            createdAt: DateTime.now(),
          ),
        );
      }

      // Act
      await queueManager.clearQueue();

      // Assert
      final items = await queueManager.getPendingItems();
      expect(items, isEmpty);
    });
  });

  group('QueueManager - Retry Failed Items', () {
    test('should reset failed items to pending status', () async {
      // Arrange
      final failedItem = QueueItem(
        id: 'failed-1',
        operation: QueueOperation.create,
        resourceType: 'expense',
        data: {},
        createdAt: DateTime.now(),
        status: QueueStatus.failed,
        retryCount: 1,
        errorMessage: 'Network error',
      );

      await queueManager.enqueue(failedItem);

      // Act
      await queueManager.retryFailedItems();

      // Assert
      final pendingItems = await queueManager.getPendingItems();
      expect(pendingItems.length, 1);
      expect(pendingItems.first.status, QueueStatus.pending);
      expect(pendingItems.first.errorMessage, isNull);
    });

    test('should not retry items that exceeded max retries', () async {
      // Arrange
      final failedItem = QueueItem(
        id: 'failed-1',
        operation: QueueOperation.create,
        resourceType: 'expense',
        data: {},
        createdAt: DateTime.now(),
        status: QueueStatus.failed,
        retryCount: 3, // Max retries reached
        errorMessage: 'Network error',
      );

      await queueManager.enqueue(failedItem);

      // Act
      await queueManager.retryFailedItems();

      // Assert
      final pendingItems = await queueManager.getPendingItems();
      expect(pendingItems, isEmpty);

      final failedItems = await queueManager.getFailedItems();
      expect(failedItems.length, 1);
    });
  });

  group('QueueManager - Statistics', () {
    test('should return correct statistics', () async {
      // Arrange
      await queueManager.enqueue(
        QueueItem(
          id: 'pending-1',
          operation: QueueOperation.create,
          resourceType: 'expense',
          data: {},
          createdAt: DateTime.now(),
          status: QueueStatus.pending,
        ),
      );

      await queueManager.enqueue(
        QueueItem(
          id: 'processing-1',
          operation: QueueOperation.update,
          resourceType: 'transfer',
          data: {},
          createdAt: DateTime.now(),
          status: QueueStatus.processing,
        ),
      );

      await queueManager.enqueue(
        QueueItem(
          id: 'failed-1',
          operation: QueueOperation.delete,
          resourceType: 'incoming',
          data: {},
          createdAt: DateTime.now(),
          status: QueueStatus.failed,
        ),
      );

      // Act
      final stats = await queueManager.getStatistics();

      // Assert
      expect(stats['total'], 3);
      expect(stats['pending'], 1);
      expect(stats['processing'], 1);
      expect(stats['failed'], 1);
    });

    test('should return zero statistics for empty queue', () async {
      // Act
      final stats = await queueManager.getStatistics();

      // Assert
      expect(stats['total'], 0);
      expect(stats['pending'], 0);
      expect(stats['processing'], 0);
      expect(stats['failed'], 0);
    });
  });

  group('QueueManager - Update Item Status', () {
    test('should update item status successfully', () async {
      // Arrange
      final queueItem = QueueItem(
        id: 'test-id',
        operation: QueueOperation.create,
        resourceType: 'expense',
        data: {},
        createdAt: DateTime.now(),
        status: QueueStatus.pending,
      );

      await queueManager.enqueue(queueItem);

      // Act
      await queueManager.updateItemStatus(
        'test-id',
        QueueStatus.processing,
      );

      // Assert
      final stats = await queueManager.getStatistics();
      expect(stats['processing'], 1);
      expect(stats['pending'], 0);
    });

    test('should increment retry count when marking as failed', () async {
      // Arrange
      final queueItem = QueueItem(
        id: 'test-id',
        operation: QueueOperation.create,
        resourceType: 'expense',
        data: {},
        createdAt: DateTime.now(),
        status: QueueStatus.pending,
        retryCount: 0,
      );

      await queueManager.enqueue(queueItem);

      // Act
      await queueManager.updateItemStatus(
        'test-id',
        QueueStatus.failed,
        errorMessage: 'Test error',
      );

      // Assert
      final failedItems = await queueManager.getFailedItems();
      expect(failedItems.first.retryCount, 1);
      expect(failedItems.first.errorMessage, 'Test error');
    });
  });

  group('QueueManager - Queue Status Stream', () {
    test('should emit status updates', () async {
      // Arrange
      final statusUpdates = <QueueStatus>[];
      final subscription = queueManager.queueStatus.listen((status) {
        statusUpdates.add(status);
      });

      // Act
      await queueManager.enqueue(
        QueueItem(
          id: 'test-id',
          operation: QueueOperation.create,
          resourceType: 'expense',
          data: {},
          createdAt: DateTime.now(),
        ),
      );

      // Wait for stream to emit
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(statusUpdates, contains(QueueStatus.pending));

      await subscription.cancel();
    });
  });
}

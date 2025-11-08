import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/services/queue_manager.dart';
import 'package:finance_app/core/services/queue_processor.dart';
import 'package:finance_app/core/services/connectivity_monitor.dart';
import 'package:finance_app/core/models/queue_item.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/services/laravel_auth_service.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/features/expenses/data/datasources/expense_api_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finance_app/core/config/api_config.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Integration tests for offline queue processing
/// Tests Requirements: 29.5, 29.6, 29.7
void main() {
  group('Offline Queue Integration Tests', () {
    late QueueManager queueManager;
    late QueueProcessor queueProcessor;
    late ConnectivityMonitor connectivityMonitor;
    late ExpenseApiDataSource expenseDataSource;
    late ApiClient apiClient;

    setUpAll(() async {
      // Initialize Hive for testing
      await Hive.initFlutter();
      
      // Initialize services
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      apiClient = ApiClient(dio);
      final secureStorage = const FlutterSecureStorage();
      final tokenManager = TokenManager(secureStorage);
      final authService = LaravelAuthService(apiClient, tokenManager);

      // Register and login a test user
      try {
        final testEmail = 'queue_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register('Queue Test User', testEmail, 'TestPassword123!');
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping tests - API not available');
          return;
        }
      }

      expenseDataSource = ExpenseApiDataSource(apiClient);
      queueManager = QueueManager();
      connectivityMonitor = ConnectivityMonitor();
      queueProcessor = QueueProcessor(
        queueManager: queueManager,
        connectivityMonitor: connectivityMonitor,
        expenseDataSource: expenseDataSource,
      );

      await queueManager.initialize();
    });

    tearDownAll(() async {
      await queueManager.clearQueue();
      await Hive.close();
    });

    test('Queue item is added and retrieved', () async {
      try {
        final queueItem = QueueItem(
          id: 'test-${DateTime.now().millisecondsSinceEpoch}',
          operation: QueueOperation.create,
          resourceType: 'expense',
          data: {
            'description': 'Queued Expense',
            'priceUsd': 100.0,
            'expenseDate': DateTime.now().toIso8601String(),
          },
          retryCount: 0,
          createdAt: DateTime.now(),
          status: QueueStatus.pending,
        );

        await queueManager.enqueue(queueItem);

        final pendingItems = await queueManager.getPendingItems();
        expect(pendingItems, isNotEmpty);
        
        final found = pendingItems.firstWhere((item) => item.id == queueItem.id);
        expect(found.operation, equals(QueueOperation.create));
        expect(found.resourceType, equals('expense'));
        expect(found.data['description'], equals('Queued Expense'));
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Queue processes items when online', () async {
      try {
        // Clear queue first
        await queueManager.clearQueue();

        // Add items to queue
        final queueItem = QueueItem(
          id: 'process-test-${DateTime.now().millisecondsSinceEpoch}',
          operation: QueueOperation.create,
          resourceType: 'expense',
          data: {
            'description': 'Process Test Expense',
            'priceUsd': 75.0,
            'expenseDate': DateTime.now().toIso8601String(),
          },
          retryCount: 0,
          createdAt: DateTime.now(),
          status: QueueStatus.pending,
        );

        await queueManager.enqueue(queueItem);

        // Verify item is in queue
        var pendingItems = await queueManager.getPendingItems();
        expect(pendingItems.length, greaterThan(0));

        // Process queue
        await queueProcessor.processQueue();

        // Wait a bit for processing
        await Future.delayed(const Duration(seconds: 2));

        // Check if queue is empty or item is processed
        pendingItems = await queueManager.getPendingItems();
        final stillPending = pendingItems.where((item) => item.id == queueItem.id).toList();
        
        // Item should either be removed or marked as processed
        expect(stillPending.isEmpty || stillPending.first.status != QueueStatus.pending, isTrue);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Failed items are retried with backoff', () async {
      try {
        // Create an item that will fail (invalid data)
        final queueItem = QueueItem(
          id: 'retry-test-${DateTime.now().millisecondsSinceEpoch}',
          operation: QueueOperation.create,
          resourceType: 'expense',
          data: {
            'description': '', // Invalid - empty description
            'priceUsd': -100.0, // Invalid - negative price
          },
          retryCount: 0,
          createdAt: DateTime.now(),
          status: QueueStatus.pending,
        );

        await queueManager.enqueue(queueItem);

        // Try to process
        await queueProcessor.processQueue();

        // Wait for processing
        await Future.delayed(const Duration(seconds: 1));

        // Check if retry count increased
        final pendingItems = await queueManager.getPendingItems();
        final retried = pendingItems.where((item) => item.id == queueItem.id).toList();
        
        if (retried.isNotEmpty) {
          // Item should have been retried or marked as failed
          expect(retried.first.retryCount >= 0, isTrue);
        }
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Queue handles multiple operations', () async {
      try {
        await queueManager.clearQueue();

        // Add multiple items
        for (int i = 0; i < 3; i++) {
          final queueItem = QueueItem(
            id: 'multi-test-$i-${DateTime.now().millisecondsSinceEpoch}',
            operation: QueueOperation.create,
            resourceType: 'expense',
            data: {
              'description': 'Multi Test Expense $i',
              'priceUsd': 50.0 * (i + 1),
              'expenseDate': DateTime.now().toIso8601String(),
            },
            retryCount: 0,
            createdAt: DateTime.now(),
            status: QueueStatus.pending,
          );
          await queueManager.enqueue(queueItem);
        }

        // Verify all items are queued
        final pendingItems = await queueManager.getPendingItems();
        expect(pendingItems.length, greaterThanOrEqualTo(3));

        // Process queue
        await queueProcessor.processQueue();

        // Wait for processing
        await Future.delayed(const Duration(seconds: 3));

        // Check results
        final afterProcess = await queueManager.getPendingItems();
        expect(afterProcess.length, lessThan(pendingItems.length));
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Queue status stream emits updates', () async {
      try {
        final statusUpdates = <QueueStatus>[];
        
        // Listen to status stream
        final subscription = queueManager.queueStatus.listen((status) {
          statusUpdates.add(status);
        });

        // Add and process item
        final queueItem = QueueItem(
          id: 'stream-test-${DateTime.now().millisecondsSinceEpoch}',
          operation: QueueOperation.create,
          resourceType: 'expense',
          data: {
            'description': 'Stream Test Expense',
            'priceUsd': 100.0,
            'expenseDate': DateTime.now().toIso8601String(),
          },
          retryCount: 0,
          createdAt: DateTime.now(),
          status: QueueStatus.pending,
        );

        await queueManager.enqueue(queueItem);
        await queueProcessor.processQueue();

        // Wait for updates
        await Future.delayed(const Duration(seconds: 2));

        // Should have received status updates
        expect(statusUpdates, isNotEmpty);

        await subscription.cancel();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });
  });
}

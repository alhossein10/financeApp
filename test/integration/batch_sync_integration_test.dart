import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/services/batch_sync_service.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/services/laravel_auth_service.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/features/expenses/data/datasources/expense_api_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finance_app/core/config/api_config.dart';

/// Integration tests for batch synchronization
/// Tests Requirements: 29.5, 29.6, 29.7
void main() {
  group('Batch Sync Integration Tests', () {
    late BatchSyncService batchSyncService;
    late ExpenseApiDataSource expenseDataSource;
    late ApiClient apiClient;
    late LaravelAuthService authService;

    setUpAll(() async {
      // Initialize services
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      apiClient = ApiClient(dio);
      final secureStorage = const FlutterSecureStorage();
      final tokenManager = TokenManager(secureStorage);
      authService = LaravelAuthService(apiClient, tokenManager);

      // Register and login a test user
      try {
        final testEmail = 'batch_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register('Batch Test User', testEmail, 'TestPassword123!');
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping tests - API not available');
          return;
        }
      }

      batchSyncService = BatchSyncService(apiClient);
      expenseDataSource = ExpenseApiDataSource(apiClient);
    });

    tearDownAll() async {
      await authService.logout();
    });

    test('Batch create multiple expenses', () async {
      try {
        final records = <BatchRecord>[];

        // Create batch of 5 expenses
        for (int i = 0; i < 5; i++) {
          records.add(BatchRecord(
            type: 'expense',
            action: 'create',
            id: null,
            data: {
              'description': 'Batch Expense $i',
              'priceUsd': 50.0 * (i + 1),
              'expenseDate': DateTime.now().toIso8601String(),
            },
          ));
        }

        final request = BatchSyncRequest(records: records);
        final response = await batchSyncService.syncBatch(request);

        expect(response.results, isNotEmpty);
        expect(response.results.length, equals(5));

        // Verify all succeeded
        final allSucceeded = response.results.every((r) => r.success);
        expect(allSucceeded, isTrue);

        // Verify expenses were created
        for (final result in response.results) {
          expect(result.serverId, isNotNull);
        }

        // Clean up - delete created expenses
        for (final result in response.results) {
          if (result.serverId != null) {
            await expenseDataSource.deleteExpense(result.serverId!);
          }
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

    test('Batch handles partial failures', () async {
      try {
        final records = <BatchRecord>[
          // Valid record
          BatchRecord(
            type: 'expense',
            action: 'create',
            id: null,
            data: {
              'description': 'Valid Expense',
              'priceUsd': 100.0,
              'expenseDate': DateTime.now().toIso8601String(),
            },
          ),
          // Invalid record - missing required fields
          BatchRecord(
            type: 'expense',
            action: 'create',
            id: null,
            data: {
              'description': '', // Invalid - empty
            },
          ),
          // Another valid record
          BatchRecord(
            type: 'expense',
            action: 'create',
            id: null,
            data: {
              'description': 'Another Valid Expense',
              'priceUsd': 200.0,
              'expenseDate': DateTime.now().toIso8601String(),
            },
          ),
        ];

        final request = BatchSyncRequest(records: records);
        final response = await batchSyncService.syncBatch(request);

        expect(response.results.length, equals(3));

        // Check that some succeeded and some failed
        final succeeded = response.results.where((r) => r.success).toList();
        final failed = response.results.where((r) => !r.success).toList();

        expect(succeeded, isNotEmpty);
        expect(failed, isNotEmpty);

        // Clean up successful creates
        for (final result in succeeded) {
          if (result.serverId != null) {
            await expenseDataSource.deleteExpense(result.serverId!);
          }
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

    test('Batch update multiple expenses', () async {
      try {
        // First create some expenses
        final createdIds = <int>[];
        for (int i = 0; i < 3; i++) {
          final records = [
            BatchRecord(
              type: 'expense',
              action: 'create',
              id: null,
              data: {
                'description': 'Update Test $i',
                'priceUsd': 100.0,
                'expenseDate': DateTime.now().toIso8601String(),
              },
            ),
          ];

          final response = await batchSyncService.syncBatch(
            BatchSyncRequest(records: records),
          );

          if (response.results.first.success && response.results.first.serverId != null) {
            createdIds.add(response.results.first.serverId!);
          }
        }

        expect(createdIds.length, equals(3));

        // Now batch update them
        final updateRecords = createdIds.map((id) => BatchRecord(
          type: 'expense',
          action: 'update',
          id: id,
          data: {
            'description': 'Updated Expense $id',
            'priceUsd': 150.0,
            'expenseDate': DateTime.now().toIso8601String(),
          },
        )).toList();

        final updateResponse = await batchSyncService.syncBatch(
          BatchSyncRequest(records: updateRecords),
        );

        expect(updateResponse.results.length, equals(3));
        
        final allUpdated = updateResponse.results.every((r) => r.success);
        expect(allUpdated, isTrue);

        // Verify updates
        final expenses = await expenseDataSource.getExpenses(page: 1, perPage: 100);
        for (final id in createdIds) {
          final expense = expenses.firstWhere((e) => e.id == id);
          expect(expense.description, contains('Updated Expense'));
          expect(expense.priceUsd, equals(150.0));
        }

        // Clean up
        for (final id in createdIds) {
          await expenseDataSource.deleteExpense(id);
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

    test('Batch delete multiple expenses', () async {
      try {
        // Create expenses to delete
        final createdIds = <int>[];
        for (int i = 0; i < 3; i++) {
          final records = [
            BatchRecord(
              type: 'expense',
              action: 'create',
              id: null,
              data: {
                'description': 'Delete Test $i',
                'priceUsd': 100.0,
                'expenseDate': DateTime.now().toIso8601String(),
              },
            ),
          ];

          final response = await batchSyncService.syncBatch(
            BatchSyncRequest(records: records),
          );

          if (response.results.first.success && response.results.first.serverId != null) {
            createdIds.add(response.results.first.serverId!);
          }
        }

        expect(createdIds.length, equals(3));

        // Batch delete them
        final deleteRecords = createdIds.map((id) => BatchRecord(
          type: 'expense',
          action: 'delete',
          id: id,
          data: {},
        )).toList();

        final deleteResponse = await batchSyncService.syncBatch(
          BatchSyncRequest(records: deleteRecords),
        );

        expect(deleteResponse.results.length, equals(3));
        
        final allDeleted = deleteResponse.results.every((r) => r.success);
        expect(allDeleted, isTrue);

        // Verify deletions
        final expenses = await expenseDataSource.getExpenses(page: 1, perPage: 100);
        for (final id in createdIds) {
          final found = expenses.where((e) => e.id == id).isEmpty;
          expect(found, isTrue);
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

    test('Batch respects size limit', () async {
      try {
        final records = <BatchRecord>[];

        // Create 60 records (exceeds 50 limit)
        for (int i = 0; i < 60; i++) {
          records.add(BatchRecord(
            type: 'expense',
            action: 'create',
            id: null,
            data: {
              'description': 'Limit Test $i',
              'priceUsd': 10.0,
              'expenseDate': DateTime.now().toIso8601String(),
            },
          ));
        }

        // Should split into multiple batches
        final batches = batchSyncService.splitIntoBatches(records);
        expect(batches.length, greaterThan(1));
        expect(batches.first.length, lessThanOrEqualTo(50));

        // Process first batch only for testing
        final firstBatch = batches.first;
        final response = await batchSyncService.syncBatch(
          BatchSyncRequest(records: firstBatch),
        );

        expect(response.results.length, equals(firstBatch.length));

        // Clean up
        for (final result in response.results) {
          if (result.success && result.serverId != null) {
            await expenseDataSource.deleteExpense(result.serverId!);
          }
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

    test('Batch handles mixed operations', () async {
      try {
        // Create an expense first
        final createRecords = [
          BatchRecord(
            type: 'expense',
            action: 'create',
            id: null,
            data: {
              'description': 'Mixed Test',
              'priceUsd': 100.0,
              'expenseDate': DateTime.now().toIso8601String(),
            },
          ),
        ];

        final createResponse = await batchSyncService.syncBatch(
          BatchSyncRequest(records: createRecords),
        );

        final createdId = createResponse.results.first.serverId;
        expect(createdId, isNotNull);

        // Now do mixed operations
        final mixedRecords = [
          // Create new
          BatchRecord(
            type: 'expense',
            action: 'create',
            id: null,
            data: {
              'description': 'New Expense',
              'priceUsd': 50.0,
              'expenseDate': DateTime.now().toIso8601String(),
            },
          ),
          // Update existing
          BatchRecord(
            type: 'expense',
            action: 'update',
            id: createdId,
            data: {
              'description': 'Updated Mixed Test',
              'priceUsd': 150.0,
              'expenseDate': DateTime.now().toIso8601String(),
            },
          ),
        ];

        final mixedResponse = await batchSyncService.syncBatch(
          BatchSyncRequest(records: mixedRecords),
        );

        expect(mixedResponse.results.length, equals(2));
        
        final allSucceeded = mixedResponse.results.every((r) => r.success);
        expect(allSucceeded, isTrue);

        // Clean up
        await expenseDataSource.deleteExpense(createdId!);
        if (mixedResponse.results.first.serverId != null) {
          await expenseDataSource.deleteExpense(mixedResponse.results.first.serverId!);
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
  });
}

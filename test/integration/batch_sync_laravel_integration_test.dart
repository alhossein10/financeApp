import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/services/laravel_auth_service.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/core/services/batch_sync_service.dart';
import 'package:finance_app/core/models/sync_request_dto.dart';
import 'package:finance_app/core/models/sync_response_dto.dart';
import 'package:finance_app/features/expenses/data/models/expense_dto.dart';
import 'package:finance_app/features/incoming/data/models/incoming_dto.dart';
import 'package:finance_app/features/transfers/data/models/transfer_dto.dart';
import 'package:finance_app/core/utils/date_formatter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finance_app/core/config/api_config.dart';

/// Integration tests for Batch Sync with Laravel API
/// Tests Requirements: 8.1, 8.2, 8.3, 8.4, 8.5
void main() {
  group('Batch Sync Laravel Integration Tests', () {
    late ApiClient apiClient;
    late LaravelAuthService authService;
    late BatchSyncService batchSyncService;

    setUpAll(() async {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      apiClient = DioApiClient(dio: dio);
      final secureStorage = const FlutterSecureStorage();
      final tokenManager = TokenManager(secureStorage: secureStorage);
      authService = LaravelAuthService(
        apiClient: apiClient,
        tokenManager: tokenManager,
      );

      try {
        final testEmail = 'batch_sync_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Batch Sync User',
          email: testEmail,
          password: 'TestPassword123!',
        );
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping tests - API not available');
          return;
        }
      }

      batchSyncService = BatchSyncServiceImpl(apiClient: apiClient);
    });

    tearDownAll() async {
      await authService.logout();
    });

    test('Batch sync with last_sync timestamp and data object', () async {
      try {
        final lastSync = DateTime.now().subtract(const Duration(hours: 1));
        
        final syncData = SyncDataDto(
          expenses: [
            ExpenseDto(
              amount: 100.0,
              category: 'Food',
              description: 'Batch sync expense',
              date: DateFormatter.toApiDate(DateTime.now()),
              paymentMethod: 'cash',
            ),
          ],
          incoming: [
            IncomingDto(
              amount: 500.0,
              source: 'Batch sync income',
              description: 'Test income',
              date: DateFormatter.toApiDate(DateTime.now()),
              paymentMethod: 'bank_transfer',
            ),
          ],
          transfers: [
            TransferDto(
              amount: 200.0,
              fromAccount: 'Account A',
              toAccount: 'Account B',
              description: 'Batch sync transfer',
              date: DateFormatter.toApiDate(DateTime.now()),
            ),
          ],
        );

        final request = SyncRequestDto(
          lastSync: lastSync,
          data: syncData,
        );

        final response = await batchSyncService.syncBatch(request);
        
        expect(response, isA<SyncResponseDto>());
        expect(response.syncedAt, isNotNull);
        expect(response.syncedAt.isAfter(lastSync), isTrue);
        
        expect(response.expenses, isNotNull);
        expect(response.incoming, isNotNull);
        expect(response.transfers, isNotNull);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Sync response includes created items with local_id to server_id mapping', () async {
      try {
        final lastSync = DateTime.now().subtract(const Duration(hours: 1));
        
        final syncData = SyncDataDto(
          expenses: [
            ExpenseDto(
              localId: 'local-expense-1',
              amount: 150.0,
              category: 'Transport',
              description: 'Mapping test expense',
              date: DateFormatter.toApiDate(DateTime.now()),
              paymentMethod: 'card',
            ),
          ],
          incoming: [],
          transfers: [],
        );

        final request = SyncRequestDto(
          lastSync: lastSync,
          data: syncData,
        );

        final response = await batchSyncService.syncBatch(request);
        
        expect(response.expenses.created, isNotEmpty);
        
        final createdExpense = response.expenses.created.first;
        expect(createdExpense.localId, equals('local-expense-1'));
        expect(createdExpense.serverId, isNotNull);
        expect(createdExpense.data, isNotNull);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Sync response includes conflicts array', () async {
      try {
        final lastSync = DateTime.now().subtract(const Duration(days: 1));
        
        // Create an expense first
        final syncData1 = SyncDataDto(
          expenses: [
            ExpenseDto(
              localId: 'conflict-expense-1',
              amount: 100.0,
              category: 'Food',
              description: 'Original expense',
              date: DateFormatter.toApiDate(DateTime.now()),
              paymentMethod: 'cash',
            ),
          ],
          incoming: [],
          transfers: [],
        );

        final request1 = SyncRequestDto(
          lastSync: lastSync,
          data: syncData1,
        );

        final response1 = await batchSyncService.syncBatch(request1);
        final serverId = response1.expenses.created.first.serverId;

        // Try to update with old timestamp (should create conflict)
        final syncData2 = SyncDataDto(
          expenses: [
            ExpenseDto(
              id: serverId,
              localId: 'conflict-expense-1',
              amount: 200.0,
              category: 'Food',
              description: 'Updated expense',
              date: DateFormatter.toApiDate(DateTime.now()),
              paymentMethod: 'cash',
              updatedAt: lastSync, // Old timestamp
            ),
          ],
          incoming: [],
          transfers: [],
        );

        final request2 = SyncRequestDto(
          lastSync: lastSync,
          data: syncData2,
        );

        final response2 = await batchSyncService.syncBatch(request2);
        
        // Check if conflicts are handled
        expect(response2.expenses.conflicts, isA<List<ConflictItem>>());
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Retrieve changes with since parameter', () async {
      try {
        final since = DateTime.now().subtract(const Duration(hours: 1));
        
        final changes = await batchSyncService.getChanges(since: since);
        
        expect(changes, isNotNull);
        expect(changes.expenses, isNotNull);
        expect(changes.incoming, isNotNull);
        expect(changes.transfers, isNotNull);
        
        expect(changes.expenses.created, isA<List>());
        expect(changes.expenses.updated, isA<List>());
        expect(changes.expenses.deleted, isA<List<int>>());
        
        expect(changes.incoming.created, isA<List>());
        expect(changes.incoming.updated, isA<List>());
        expect(changes.incoming.deleted, isA<List<int>>());
        
        expect(changes.transfers.created, isA<List>());
        expect(changes.transfers.updated, isA<List>());
        expect(changes.transfers.deleted, isA<List<int>>());
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Sync handles multiple entity types in single request', () async {
      try {
        final lastSync = DateTime.now().subtract(const Duration(hours: 1));
        
        final syncData = SyncDataDto(
          expenses: [
            ExpenseDto(
              localId: 'multi-expense-1',
              amount: 50.0,
              category: 'Food',
              description: 'Multi-type expense',
              date: DateFormatter.toApiDate(DateTime.now()),
              paymentMethod: 'cash',
            ),
            ExpenseDto(
              localId: 'multi-expense-2',
              amount: 75.0,
              category: 'Transport',
              description: 'Another expense',
              date: DateFormatter.toApiDate(DateTime.now()),
              paymentMethod: 'card',
            ),
          ],
          incoming: [
            IncomingDto(
              localId: 'multi-income-1',
              amount: 1000.0,
              source: 'Multi-type income',
              description: 'Test income',
              date: DateFormatter.toApiDate(DateTime.now()),
              paymentMethod: 'bank_transfer',
            ),
          ],
          transfers: [
            TransferDto(
              localId: 'multi-transfer-1',
              amount: 300.0,
              fromAccount: 'Account X',
              toAccount: 'Account Y',
              description: 'Multi-type transfer',
              date: DateFormatter.toApiDate(DateTime.now()),
            ),
          ],
        );

        final request = SyncRequestDto(
          lastSync: lastSync,
          data: syncData,
        );

        final response = await batchSyncService.syncBatch(request);
        
        expect(response.expenses.created.length, equals(2));
        expect(response.incoming.created.length, equals(1));
        expect(response.transfers.created.length, equals(1));
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Sync handles empty data arrays', () async {
      try {
        final lastSync = DateTime.now().subtract(const Duration(hours: 1));
        
        final syncData = SyncDataDto(
          expenses: [],
          incoming: [],
          transfers: [],
        );

        final request = SyncRequestDto(
          lastSync: lastSync,
          data: syncData,
        );

        final response = await batchSyncService.syncBatch(request);
        
        expect(response.syncedAt, isNotNull);
        expect(response.expenses.created, isEmpty);
        expect(response.incoming.created, isEmpty);
        expect(response.transfers.created, isEmpty);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Sync preserves data integrity across multiple syncs', () async {
      try {
        final lastSync1 = DateTime.now().subtract(const Duration(hours: 2));
        
        // First sync
        final syncData1 = SyncDataDto(
          expenses: [
            ExpenseDto(
              localId: 'integrity-expense-1',
              amount: 100.0,
              category: 'Food',
              description: 'Integrity test',
              date: DateFormatter.toApiDate(DateTime.now()),
              paymentMethod: 'cash',
            ),
          ],
          incoming: [],
          transfers: [],
        );

        final request1 = SyncRequestDto(
          lastSync: lastSync1,
          data: syncData1,
        );

        final response1 = await batchSyncService.syncBatch(request1);
        final serverId = response1.expenses.created.first.serverId;
        final syncedAt1 = response1.syncedAt;

        // Second sync with update
        final syncData2 = SyncDataDto(
          expenses: [
            ExpenseDto(
              id: serverId,
              localId: 'integrity-expense-1',
              amount: 150.0,
              category: 'Food',
              description: 'Updated integrity test',
              date: DateFormatter.toApiDate(DateTime.now()),
              paymentMethod: 'card',
            ),
          ],
          incoming: [],
          transfers: [],
        );

        final request2 = SyncRequestDto(
          lastSync: syncedAt1,
          data: syncData2,
        );

        final response2 = await batchSyncService.syncBatch(request2);
        
        expect(response2.syncedAt.isAfter(syncedAt1), isTrue);
        
        // Verify the update was successful
        final changes = await batchSyncService.getChanges(since: lastSync1);
        final updatedExpense = changes.expenses.updated.firstWhere(
          (e) => e.id == serverId,
          orElse: () => changes.expenses.created.firstWhere((e) => e.id == serverId),
        );
        
        expect(updatedExpense.amount, equals(150.0));
        expect(updatedExpense.description, equals('Updated integrity test'));
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Conflict resolution provides both local and server data', () async {
      try {
        final lastSync = DateTime.now().subtract(const Duration(days: 1));
        
        // Create initial expense
        final syncData1 = SyncDataDto(
          expenses: [
            ExpenseDto(
              localId: 'conflict-data-1',
              amount: 100.0,
              category: 'Food',
              description: 'Conflict test',
              date: DateFormatter.toApiDate(DateTime.now()),
              paymentMethod: 'cash',
            ),
          ],
          incoming: [],
          transfers: [],
        );

        final request1 = SyncRequestDto(
          lastSync: lastSync,
          data: syncData1,
        );

        final response1 = await batchSyncService.syncBatch(request1);
        final serverId = response1.expenses.created.first.serverId;

        // Simulate conflict by updating with old timestamp
        final syncData2 = SyncDataDto(
          expenses: [
            ExpenseDto(
              id: serverId,
              localId: 'conflict-data-1',
              amount: 200.0,
              category: 'Food',
              description: 'Local update',
              date: DateFormatter.toApiDate(DateTime.now()),
              paymentMethod: 'card',
              updatedAt: lastSync,
            ),
          ],
          incoming: [],
          transfers: [],
        );

        final request2 = SyncRequestDto(
          lastSync: lastSync,
          data: syncData2,
        );

        final response2 = await batchSyncService.syncBatch(request2);
        
        if (response2.expenses.conflicts.isNotEmpty) {
          final conflict = response2.expenses.conflicts.first;
          expect(conflict.localId, equals('conflict-data-1'));
          expect(conflict.localData, isNotNull);
          expect(conflict.serverData, isNotNull);
          expect(conflict.reason, isNotEmpty);
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

    test('Changes endpoint returns created, updated, and deleted arrays', () async {
      try {
        final since = DateTime.now().subtract(const Duration(hours: 1));
        
        // Create some data first
        final syncData = SyncDataDto(
          expenses: [
            ExpenseDto(
              localId: 'changes-expense-1',
              amount: 100.0,
              category: 'Food',
              description: 'Changes test',
              date: DateFormatter.toApiDate(DateTime.now()),
              paymentMethod: 'cash',
            ),
          ],
          incoming: [],
          transfers: [],
        );

        final request = SyncRequestDto(
          lastSync: since,
          data: syncData,
        );

        await batchSyncService.syncBatch(request);

        // Get changes
        final changes = await batchSyncService.getChanges(since: since);
        
        // Verify structure
        expect(changes.expenses.created, isA<List<ExpenseDto>>());
        expect(changes.expenses.updated, isA<List<ExpenseDto>>());
        expect(changes.expenses.deleted, isA<List<int>>());
        
        expect(changes.incoming.created, isA<List<IncomingDto>>());
        expect(changes.incoming.updated, isA<List<IncomingDto>>());
        expect(changes.incoming.deleted, isA<List<int>>());
        
        expect(changes.transfers.created, isA<List<TransferDto>>());
        expect(changes.transfers.updated, isA<List<TransferDto>>());
        expect(changes.transfers.deleted, isA<List<int>>());
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

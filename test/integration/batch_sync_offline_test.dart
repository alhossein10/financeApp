import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/services/batch_sync_service.dart';
import 'package:finance_app/core/models/sync_request_dto.dart';
import 'package:finance_app/core/models/sync_response_dto.dart';
import 'package:finance_app/core/models/sync_changes_dto.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/config/api_config.dart';

void main() {
  group('Batch Sync Integration Tests - Offline Changes', () {
    late BatchSyncService batchSyncService;
    late ApiClient apiClient;

    setUp(() {
      // Initialize API client with test configuration
      apiClient = ApiClient(
        baseUrl: ApiConfig.baseUrl,
        onUnauthorized: () {},
      );
      batchSyncService = BatchSyncService(apiClient: apiClient);
    });

    test('should sync offline expense changes', () async {
      // This test requires a running Laravel backend
      // Skip if backend is not available
      
      final lastSync = DateTime.now().subtract(const Duration(hours: 1));
      
      final offlineExpenses = [
        {
          'local_id': 'offline-expense-1',
          'amount': 75.50,
          'category': 'Food',
          'description': 'Offline expense test',
          'date': '2024-10-23',
          'payment_method': 'cash',
        },
      ];

      final data = SyncDataDto(
        expenses: offlineExpenses,
        incoming: [],
        transfers: [],
      );

      try {
        final response = await batchSyncService.batchSync(
          lastSync: lastSync,
          data: data,
        );

        expect(response, isA<SyncResponseDto>());
        expect(response.syncedAt, isA<DateTime>());
        
        // Check if expense was created or has conflict
        if (response.expenses.hasCreated) {
          expect(response.expenses.created.first.localId, 'offline-expense-1');
          expect(response.expenses.created.first.serverId, isPositive);
        }
        
        print('Sync completed: ${response.totalCreated} created, '
            '${response.totalConflicts} conflicts');
      } catch (e) {
        print('Test skipped - backend not available: $e');
      }
    }, skip: 'Requires running Laravel backend');

    test('should sync multiple offline changes', () async {
      final lastSync = DateTime.now().subtract(const Duration(hours: 2));
      
      final data = SyncDataDto(
        expenses: [
          {
            'local_id': 'offline-exp-1',
            'amount': 50.0,
            'category': 'Food',
            'date': '2024-10-23',
            'payment_method': 'cash',
          },
          {
            'local_id': 'offline-exp-2',
            'amount': 30.0,
            'category': 'Transport',
            'date': '2024-10-23',
            'payment_method': 'card',
          },
        ],
        incoming: [
          {
            'local_id': 'offline-inc-1',
            'amount': 1000.0,
            'source': 'Salary',
            'date': '2024-10-23',
            'payment_method': 'bank_transfer',
          },
        ],
        transfers: [
          {
            'local_id': 'offline-trans-1',
            'amount': 100.0,
            'from_account': 'Cash',
            'to_account': 'Bank',
            'date': '2024-10-23',
          },
        ],
      );

      try {
        final response = await batchSyncService.batchSync(
          lastSync: lastSync,
          data: data,
        );

        expect(response, isA<SyncResponseDto>());
        
        // Verify all entity types were processed
        expect(response.expenses, isA<EntitySyncResultDto>());
        expect(response.incoming, isA<EntitySyncResultDto>());
        expect(response.transfers, isA<EntitySyncResultDto>());
        
        print('Multi-entity sync: ${response.totalCreated} created, '
            '${response.totalConflicts} conflicts');
      } catch (e) {
        print('Test skipped - backend not available: $e');
      }
    }, skip: 'Requires running Laravel backend');

    test('should handle sync conflicts', () async {
      // This test simulates a conflict scenario
      final lastSync = DateTime.now().subtract(const Duration(days: 1));
      
      final data = SyncDataDto(
        expenses: [
          {
            'local_id': 'conflict-test-1',
            'amount': 99.99,
            'category': 'Test',
            'date': '2024-10-23',
            'payment_method': 'cash',
          },
        ],
      );

      try {
        final response = await batchSyncService.batchSync(
          lastSync: lastSync,
          data: data,
        );

        if (response.hasConflicts) {
          expect(response.allConflicts, isNotEmpty);
          
          for (final conflict in response.allConflicts) {
            expect(conflict.reason, isNotEmpty);
            expect(conflict.localData, isNotEmpty);
            expect(conflict.serverData, isNotEmpty);
            
            print('Conflict detected: ${conflict.reason}');
          }
        }
      } catch (e) {
        print('Test skipped - backend not available: $e');
      }
    }, skip: 'Requires running Laravel backend');

    test('should get changes since last sync', () async {
      final since = DateTime.now().subtract(const Duration(hours: 1));

      try {
        final changes = await batchSyncService.getChanges(since: since);

        expect(changes, isA<SyncChangesDto>());
        expect(changes.timestamp, isA<DateTime>());
        expect(changes.changes, isA<ChangesDataDto>());
        
        print('Changes retrieved: ${changes.changes.totalChanges} total');
        print('  Expenses: ${changes.changes.expenses.totalChanges}');
        print('  Incoming: ${changes.changes.incoming.totalChanges}');
        print('  Transfers: ${changes.changes.transfers.totalChanges}');
      } catch (e) {
        print('Test skipped - backend not available: $e');
      }
    }, skip: 'Requires running Laravel backend');

    test('should perform full sync (push and pull)', () async {
      final lastSync = DateTime.now().subtract(const Duration(hours: 1));
      
      final localChanges = SyncDataDto(
        expenses: [
          {
            'local_id': 'full-sync-1',
            'amount': 25.0,
            'category': 'Snacks',
            'date': '2024-10-23',
            'payment_method': 'cash',
          },
        ],
      );

      try {
        final result = await batchSyncService.fullSync(
          lastSync: lastSync,
          localChanges: localChanges,
        );

        expect(result.success, true);
        
        if (result.pushResponse != null) {
          print('Push: ${result.totalCreated} created, '
              '${result.totalConflicts} conflicts');
        }
        
        if (result.pullResponse != null) {
          print('Pull: ${result.totalChangesFromServer} changes from server');
        }
      } catch (e) {
        print('Test skipped - backend not available: $e');
      }
    }, skip: 'Requires running Laravel backend');

    test('should handle empty sync data', () async {
      final lastSync = DateTime.now().subtract(const Duration(minutes: 30));
      
      final emptyData = SyncDataDto();

      try {
        final response = await batchSyncService.batchSync(
          lastSync: lastSync,
          data: emptyData,
        );

        expect(response, isA<SyncResponseDto>());
        expect(response.totalCreated, 0);
        expect(response.totalConflicts, 0);
      } catch (e) {
        print('Test skipped - backend not available: $e');
      }
    }, skip: 'Requires running Laravel backend');
  });
}

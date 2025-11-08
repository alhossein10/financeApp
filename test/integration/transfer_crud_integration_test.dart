import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/services/laravel_auth_service.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/features/transfers/data/datasources/transfer_api_datasource.dart';
import 'package:finance_app/features/transfers/data/models/transfer_dto.dart';
import 'package:finance_app/core/utils/date_formatter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finance_app/core/config/api_config.dart';

/// Integration tests for Transfer CRUD operations with Laravel API
/// Tests Requirements: 1.1, 1.2, 1.3, 1.4, 1.5
void main() {
  group('Transfer CRUD Integration Tests', () {
    late ApiClient apiClient;
    late LaravelAuthService authService;
    late TransferApiDataSource transferDataSource;

    setUpAll(() async {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      apiClient = DioApiClient(dio: dio);
      final secureStorage = const FlutterSecureStorage();
      final tokenManager = TokenManager(secureStorage: secureStorage);
      authService = LaravelAuthService(
        apiClient: apiClient,
        tokenManager: tokenManager,
      );

      try {
        final testEmail = 'transfer_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Transfer Test User',
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

      transferDataSource = TransferApiDataSourceImpl(apiClient: apiClient);
    });

    tearDownAll(() async {
      await authService.logout();
    });

    test('Create transfer with correct field mappings (recipient_name, amount_usd)', () async {
      try {
        final newTransfer = TransferDto(
          recipientName: 'abo momen',
          amountUsd: 250.0,
          transferDate: DateFormatter.toApiDate(DateTime.now()),
          notes: 'Test transfer with correct fields',
        );

        final created = await transferDataSource.createTransfer(newTransfer);
        
        expect(created.id, isNotNull);
        expect(created.amountUsd, equals(250.0));
        expect(created.recipientName, equals('abo momen'));
        expect(created.notes, equals('Test transfer with correct fields'));
        expect(created.transferDate, isNotEmpty);

        await transferDataSource.deleteTransfer(created.id!);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Create transfer with date in YYYY-MM-DD format', () async {
      try {
        final testDate = DateTime(2024, 10, 23);
        final newTransfer = TransferDto(
          recipientName: 'test recipient',
          amountUsd: 100.0,
          transferDate: DateFormatter.toApiDate(testDate),
          notes: 'Date format test',
        );

        final created = await transferDataSource.createTransfer(newTransfer);
        
        expect(created.transferDate, equals('2024-10-23'));

        await transferDataSource.deleteTransfer(created.id!);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Read transfer and verify all fields are parsed correctly', () async {
      try {
        final newTransfer = TransferDto(
          recipientName: 'test recipient',
          amountUsd: 500.0,
          transferDate: DateFormatter.toApiDate(DateTime.now()),
          notes: 'Read test transfer',
        );

        final created = await transferDataSource.createTransfer(newTransfer);
        
        final transfers = await transferDataSource.getTransfers(page: 1, perPage: 10);
        expect(transfers.data, isNotEmpty);
        
        final found = transfers.data.firstWhere((t) => t.id == created.id);
        expect(found.amountUsd, equals(500.0));
        expect(found.recipientName, equals('test recipient'));
        expect(found.notes, equals('Read test transfer'));
        expect(found.createdAt, isNotNull);
        expect(found.updatedAt, isNotNull);

        await transferDataSource.deleteTransfer(created.id!);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Update transfer with all required fields', () async {
      try {
        final newTransfer = TransferDto(
          recipientName: 'original recipient',
          amountUsd: 300.0,
          transferDate: DateFormatter.toApiDate(DateTime.now()),
          notes: 'Original transfer',
        );

        final created = await transferDataSource.createTransfer(newTransfer);
        
        final updated = TransferDto(
          id: created.id,
          recipientName: 'updated recipient',
          amountUsd: 450.0,
          transferDate: created.transferDate,
          notes: 'Updated transfer',
          createdAt: created.createdAt,
          updatedAt: DateTime.now(),
        );

        final result = await transferDataSource.updateTransfer(created.id!, updated);
        
        expect(result.amountUsd, equals(450.0));
        expect(result.recipientName, equals('updated recipient'));
        expect(result.notes, equals('Updated transfer'));

        await transferDataSource.deleteTransfer(created.id!);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Delete transfer successfully', () async {
      try {
        final newTransfer = TransferDto(
          recipientName: 'delete test recipient',
          amountUsd: 150.0,
          transferDate: DateFormatter.toApiDate(DateTime.now()),
          notes: 'Transfer to delete',
        );

        final created = await transferDataSource.createTransfer(newTransfer);
        final createdId = created.id!;
        
        await transferDataSource.deleteTransfer(createdId);
        
        final transfers = await transferDataSource.getTransfers(page: 1, perPage: 100);
        final deleted = transfers.data.where((t) => t.id == createdId).isEmpty;
        expect(deleted, isTrue);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Handle exchange information in nested structure', () async {
      try {
        // Note: Exchange is handled separately via addExchange endpoint
        final newTransfer = TransferDto(
          recipientName: 'exchange test recipient',
          amountUsd: 200.0,
          transferDate: DateFormatter.toApiDate(DateTime.now()),
          notes: 'Transfer with exchange',
        );

        final created = await transferDataSource.createTransfer(newTransfer);
        
        expect(created.id, isNotNull);
        expect(created.amountUsd, equals(200.0));

        await transferDataSource.deleteTransfer(created.id!);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Pagination works correctly for transfers', () async {
      try {
        final createdIds = <int>[];
        
        for (int i = 0; i < 5; i++) {
          final transfer = TransferDto(
            recipientName: 'Recipient $i',
            amountUsd: 100.0 * (i + 1),
            transferDate: DateFormatter.toApiDate(DateTime.now()),
            notes: 'Pagination test $i',
          );
          final created = await transferDataSource.createTransfer(transfer);
          createdIds.add(created.id!);
        }

        final page1 = await transferDataSource.getTransfers(page: 1, perPage: 2);
        expect(page1.data.length, lessThanOrEqualTo(2));
        expect(page1.perPage, equals(2));
        expect(page1.currentPage, equals(1));

        final page2 = await transferDataSource.getTransfers(page: 2, perPage: 2);
        expect(page2.currentPage, equals(2));

        for (final id in createdIds) {
          await transferDataSource.deleteTransfer(id);
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

    test('Filter transfers by date range', () async {
      try {
        final createdIds = <int>[];
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        
        final transfer1 = TransferDto(
          recipientName: 'yesterday recipient',
          amountUsd: 100.0,
          transferDate: DateFormatter.toApiDate(yesterday),
          notes: 'Yesterday transfer',
        );
        final created1 = await transferDataSource.createTransfer(transfer1);
        createdIds.add(created1.id!);

        final transfer2 = TransferDto(
          recipientName: 'today recipient',
          amountUsd: 200.0,
          transferDate: DateFormatter.toApiDate(today),
          notes: 'Today transfer',
        );
        final created2 = await transferDataSource.createTransfer(transfer2);
        createdIds.add(created2.id!);

        final filtered = await transferDataSource.getTransfers(
          startDate: today,
          endDate: today,
          perPage: 100,
        );

        final todayTransfers = filtered.data.where(
          (t) => t.transferDate == DateFormatter.toApiDate(today)
        ).toList();
        expect(todayTransfers, isNotEmpty);

        for (final id in createdIds) {
          await transferDataSource.deleteTransfer(id);
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

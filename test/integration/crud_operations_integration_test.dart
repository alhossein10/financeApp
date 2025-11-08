import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/services/laravel_auth_service.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/features/expenses/data/datasources/expense_api_datasource.dart';
import 'package:finance_app/features/transfers/data/datasources/transfer_api_datasource.dart';
import 'package:finance_app/features/incoming/data/datasources/incoming_api_datasource.dart';
import 'package:finance_app/features/expenses/data/models/expense_dto.dart';
import 'package:finance_app/features/transfers/data/models/transfer_dto.dart';
import 'package:finance_app/features/incoming/data/models/incoming_dto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finance_app/core/config/api_config.dart';

/// Integration tests for CRUD operations on all resources
/// Tests Requirements: 29.5, 29.6, 29.7
void main() {
  group('CRUD Operations Integration Tests', () {
    late ApiClient apiClient;
    late LaravelAuthService authService;
    late ExpenseApiDataSource expenseDataSource;
    late TransferApiDataSource transferDataSource;
    late IncomingApiDataSource incomingDataSource;

    setUpAll(() async {
      // Initialize services
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

      // Register and login a test user
      try {
        final testEmail = 'crud_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'CRUD Test User',
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

      expenseDataSource = ExpenseApiDataSourceImpl(apiClient: apiClient);
      transferDataSource = TransferApiDataSourceImpl(apiClient: apiClient);
      incomingDataSource = IncomingApiDataSourceImpl(apiClient: apiClient);
    });

    tearDownAll(() async {
      await authService.logout();
    });

    group('Expense CRUD Operations', () {
      test('Create, Read, Update, Delete expense with cash payment', () async {
        try {
          // Create expense with cash payment
          final newExpense = ExpenseDto(
            amount: 100.0,
            category: 'Food',
            description: 'Test Expense - Cash',
            date: '2024-10-23',
            paymentMethod: 'cash',
          );

          final created = await expenseDataSource.createExpense(newExpense);
          expect(created.id, isNotNull);
          expect(created.description, equals('Test Expense - Cash'));
          expect(created.amount, equals(100.0));
          expect(created.paymentMethod, equals('cash'));

          // Read expense
          final expenses = await expenseDataSource.getExpenses(page: 1, perPage: 10);
          expect(expenses.data, isNotEmpty);
          final found = expenses.data.firstWhere((e) => e.id == created.id);
          expect(found.description, equals('Test Expense - Cash'));

          // Update expense
          final updated = ExpenseDto(
            id: created.id,
            amount: 150.0,
            category: 'Food',
            description: 'Updated Test Expense',
            date: created.date,
            paymentMethod: 'card',
          );

          final result = await expenseDataSource.updateExpense(created.id!, updated);
          expect(result.description, equals('Updated Test Expense'));
          expect(result.amount, equals(150.0));
          expect(result.paymentMethod, equals('card'));

          // Delete expense
          await expenseDataSource.deleteExpense(created.id!);

          // Verify deletion
          final afterDelete = await expenseDataSource.getExpenses(page: 1, perPage: 100);
          final deleted = afterDelete.data.where((e) => e.id == created.id).isEmpty;
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

      test('Create expenses with all payment methods', () async {
        try {
          final paymentMethods = ['cash', 'card', 'bank_transfer'];
          final createdIds = <int>[];

          // Create expense with each payment method
          for (final method in paymentMethods) {
            final expense = ExpenseDto(
              amount: 50.0,
              category: 'Test',
              description: 'Test $method payment',
              date: '2024-10-23',
              paymentMethod: method,
            );

            final created = await expenseDataSource.createExpense(expense);
            expect(created.id, isNotNull);
            expect(created.paymentMethod, equals(method));
            createdIds.add(created.id!);
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

      test('Pagination and filtering work correctly', () async {
        try {
          final createdIds = <int>[];
          
          // Create multiple expenses with different categories
          for (int i = 0; i < 5; i++) {
            final expense = ExpenseDto(
              amount: 10.0 * (i + 1),
              category: i % 2 == 0 ? 'Food' : 'Transport',
              description: 'Pagination Test $i',
              date: '2024-10-23',
              paymentMethod: 'cash',
            );
            final created = await expenseDataSource.createExpense(expense);
            createdIds.add(created.id!);
          }

          // Test pagination
          final page1 = await expenseDataSource.getExpenses(page: 1, perPage: 2);
          expect(page1.data.length, lessThanOrEqualTo(2));
          expect(page1.perPage, equals(2));

          final page2 = await expenseDataSource.getExpenses(page: 2, perPage: 2);
          expect(page2.data.length, greaterThan(0));

          // Test category filter
          final foodExpenses = await expenseDataSource.getExpenses(
            category: 'Food',
            perPage: 10,
          );
          expect(foodExpenses.data.every((e) => e.category == 'Food'), isTrue);

          // Test date filter
          final filteredByDate = await expenseDataSource.getExpenses(
            startDate: DateTime(2024, 10, 23),
            endDate: DateTime(2024, 10, 24),
            perPage: 10,
          );
          expect(filteredByDate.data, isNotEmpty);

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
    });

    group('Transfer CRUD Operations', () {
      test('Create, Read, Update, Delete transfer', () async {
        try {
          // Create transfer
          final newTransfer = TransferDto(
            id: null,
            recipientName: 'Test Recipient',
            amountUsd: 200.0,
            transferDate: DateTime.now(),
            notes: 'Test transfer',
            exchange: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final created = await transferDataSource.createTransfer(newTransfer);
          expect(created.id, isNotNull);
          expect(created.recipientName, equals('Test Recipient'));
          expect(created.amountUsd, equals(200.0));

          // Read transfer
          final transfers = await transferDataSource.getTransfers(page: 1, perPage: 10);
          expect(transfers, isNotEmpty);

          // Update transfer
          final updated = TransferDto(
            id: created.id,
            recipientName: 'Updated Recipient',
            amountUsd: 250.0,
            transferDate: created.transferDate,
            notes: 'Updated notes',
            exchange: null,
            createdAt: created.createdAt,
            updatedAt: DateTime.now(),
          );

          final result = await transferDataSource.updateTransfer(updated);
          expect(result.recipientName, equals('Updated Recipient'));
          expect(result.amountUsd, equals(250.0));

          // Delete transfer
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
    });

    group('Incoming CRUD Operations', () {
      test('Create, Read, Update, Delete incoming', () async {
        try {
          // Create incoming
          final newIncoming = IncomingDto(
            id: null,
            description: 'Test Income',
            amountUsd: 500.0,
            incomingDate: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final created = await incomingDataSource.createIncoming(newIncoming);
          expect(created.id, isNotNull);
          expect(created.description, equals('Test Income'));
          expect(created.amountUsd, equals(500.0));

          // Read incoming
          final incoming = await incomingDataSource.getIncoming(page: 1, perPage: 10);
          expect(incoming, isNotEmpty);

          // Update incoming
          final updated = IncomingDto(
            id: created.id,
            description: 'Updated Income',
            amountUsd: 600.0,
            incomingDate: created.incomingDate,
            createdAt: created.createdAt,
            updatedAt: DateTime.now(),
          );

          final result = await incomingDataSource.updateIncoming(updated);
          expect(result.description, equals('Updated Income'));
          expect(result.amountUsd, equals(600.0));

          // Delete incoming
          await incomingDataSource.deleteIncoming(created.id!);
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
  });
}

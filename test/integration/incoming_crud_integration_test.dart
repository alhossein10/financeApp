import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/services/laravel_auth_service.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/features/incoming/data/datasources/incoming_api_datasource.dart';
import 'package:finance_app/features/incoming/data/models/incoming_dto.dart';
import 'package:finance_app/core/utils/date_formatter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finance_app/core/config/api_config.dart';

/// Integration tests for Incoming CRUD operations with Laravel API
/// Tests Requirements: 2.1, 2.2, 2.3, 2.4, 2.5
void main() {
  group('Incoming CRUD Integration Tests', () {
    late ApiClient apiClient;
    late LaravelAuthService authService;
    late IncomingApiDataSource incomingDataSource;

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
        final testEmail = 'incoming_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Incoming Test User',
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

      incomingDataSource = IncomingApiDataSourceImpl(apiClient: apiClient);
    });

    tearDownAll(() async {
      await authService.logout();
    });

    test('Create incoming with source and payment_method fields', () async {
      try {
        final newIncoming = IncomingDto(
          amount: 1000.0,
          source: 'Salary Payment',
          description: 'Monthly salary',
          date: DateFormatter.toApiDate(DateTime.now()),
          paymentMethod: 'bank_transfer',
        );

        final created = await incomingDataSource.createIncoming(newIncoming);
        
        expect(created.id, isNotNull);
        expect(created.amount, equals(1000.0));
        expect(created.source, equals('Salary Payment'));
        expect(created.description, equals('Monthly salary'));
        expect(created.paymentMethod, equals('bank_transfer'));
        expect(created.date, isNotEmpty);

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

    test('Create incoming with cash payment method', () async {
      try {
        final newIncoming = IncomingDto(
          amount: 500.0,
          source: 'Freelance Work',
          description: 'Project payment',
          date: DateFormatter.toApiDate(DateTime.now()),
          paymentMethod: 'cash',
        );

        final created = await incomingDataSource.createIncoming(newIncoming);
        
        expect(created.paymentMethod, equals('cash'));

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

    test('Create incoming with card payment method', () async {
      try {
        final newIncoming = IncomingDto(
          amount: 750.0,
          source: 'Consulting Fee',
          description: 'Client payment',
          date: DateFormatter.toApiDate(DateTime.now()),
          paymentMethod: 'card',
        );

        final created = await incomingDataSource.createIncoming(newIncoming);
        
        expect(created.paymentMethod, equals('card'));

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

    test('Validate payment method is one of: cash, card, bank_transfer', () async {
      try {
        final validMethods = ['cash', 'card', 'bank_transfer'];
        final createdIds = <int>[];

        for (final method in validMethods) {
          final incoming = IncomingDto(
            amount: 100.0,
            source: 'Test Source',
            description: 'Payment method test: $method',
            date: DateFormatter.toApiDate(DateTime.now()),
            paymentMethod: method,
          );

          final created = await incomingDataSource.createIncoming(incoming);
          expect(created.paymentMethod, equals(method));
          createdIds.add(created.id!);
        }

        for (final id in createdIds) {
          await incomingDataSource.deleteIncoming(id);
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

    test('Read incoming and verify source field is parsed', () async {
      try {
        final newIncoming = IncomingDto(
          amount: 2000.0,
          source: 'Investment Returns',
          description: 'Quarterly dividends',
          date: DateFormatter.toApiDate(DateTime.now()),
          paymentMethod: 'bank_transfer',
        );

        final created = await incomingDataSource.createIncoming(newIncoming);
        
        final incoming = await incomingDataSource.getIncoming(page: 1, perPage: 10);
        expect(incoming.data, isNotEmpty);
        
        final found = incoming.data.firstWhere((i) => i.id == created.id);
        expect(found.source, equals('Investment Returns'));
        expect(found.amount, equals(2000.0));
        expect(found.description, equals('Quarterly dividends'));
        expect(found.paymentMethod, equals('bank_transfer'));
        expect(found.createdAt, isNotNull);
        expect(found.updatedAt, isNotNull);

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

    test('Update incoming with all required fields', () async {
      try {
        final newIncoming = IncomingDto(
          amount: 800.0,
          source: 'Original Source',
          description: 'Original description',
          date: DateFormatter.toApiDate(DateTime.now()),
          paymentMethod: 'cash',
        );

        final created = await incomingDataSource.createIncoming(newIncoming);
        
        final updated = IncomingDto(
          id: created.id,
          amount: 1200.0,
          source: 'Updated Source',
          description: 'Updated description',
          date: created.date,
          paymentMethod: 'card',
          createdAt: created.createdAt,
          updatedAt: DateTime.now(),
        );

        final result = await incomingDataSource.updateIncoming(created.id!, updated);
        
        expect(result.amount, equals(1200.0));
        expect(result.source, equals('Updated Source'));
        expect(result.description, equals('Updated description'));
        expect(result.paymentMethod, equals('card'));

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

    test('Delete incoming successfully', () async {
      try {
        final newIncoming = IncomingDto(
          amount: 300.0,
          source: 'Delete Test Source',
          description: 'Income to delete',
          date: DateFormatter.toApiDate(DateTime.now()),
          paymentMethod: 'cash',
        );

        final created = await incomingDataSource.createIncoming(newIncoming);
        final createdId = created.id!;
        
        await incomingDataSource.deleteIncoming(createdId);
        
        final incoming = await incomingDataSource.getIncoming(page: 1, perPage: 100);
        final deleted = incoming.data.where((i) => i.id == createdId).isEmpty;
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

    test('Pagination with per_page parameter works correctly', () async {
      try {
        final createdIds = <int>[];
        
        for (int i = 0; i < 5; i++) {
          final incoming = IncomingDto(
            amount: 100.0 * (i + 1),
            source: 'Source $i',
            description: 'Pagination test $i',
            date: DateFormatter.toApiDate(DateTime.now()),
            paymentMethod: 'cash',
          );
          final created = await incomingDataSource.createIncoming(incoming);
          createdIds.add(created.id!);
        }

        final page1 = await incomingDataSource.getIncoming(page: 1, perPage: 2);
        expect(page1.data.length, lessThanOrEqualTo(2));
        expect(page1.perPage, equals(2));
        expect(page1.currentPage, equals(1));

        final page2 = await incomingDataSource.getIncoming(page: 2, perPage: 2);
        expect(page2.currentPage, equals(2));

        for (final id in createdIds) {
          await incomingDataSource.deleteIncoming(id);
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

    test('Filter incoming by date range', () async {
      try {
        final createdIds = <int>[];
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        
        final incoming1 = IncomingDto(
          amount: 500.0,
          source: 'Yesterday Source',
          description: 'Yesterday income',
          date: DateFormatter.toApiDate(yesterday),
          paymentMethod: 'cash',
        );
        final created1 = await incomingDataSource.createIncoming(incoming1);
        createdIds.add(created1.id!);

        final incoming2 = IncomingDto(
          amount: 600.0,
          source: 'Today Source',
          description: 'Today income',
          date: DateFormatter.toApiDate(today),
          paymentMethod: 'card',
        );
        final created2 = await incomingDataSource.createIncoming(incoming2);
        createdIds.add(created2.id!);

        final filtered = await incomingDataSource.getIncoming(
          startDate: today,
          endDate: today,
          perPage: 100,
        );

        final todayIncoming = filtered.data.where(
          (i) => i.date == DateFormatter.toApiDate(today)
        ).toList();
        expect(todayIncoming, isNotEmpty);

        for (final id in createdIds) {
          await incomingDataSource.deleteIncoming(id);
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

    test('Filter incoming by payment method', () async {
      try {
        final createdIds = <int>[];
        
        final incoming1 = IncomingDto(
          amount: 100.0,
          source: 'Cash Source',
          description: 'Cash payment',
          date: DateFormatter.toApiDate(DateTime.now()),
          paymentMethod: 'cash',
        );
        final created1 = await incomingDataSource.createIncoming(incoming1);
        createdIds.add(created1.id!);

        final incoming2 = IncomingDto(
          amount: 200.0,
          source: 'Card Source',
          description: 'Card payment',
          date: DateFormatter.toApiDate(DateTime.now()),
          paymentMethod: 'card',
        );
        final created2 = await incomingDataSource.createIncoming(incoming2);
        createdIds.add(created2.id!);

        final cashFiltered = await incomingDataSource.getIncoming(
          paymentMethod: 'cash',
          perPage: 100,
        );

        final cashIncoming = cashFiltered.data.where(
          (i) => i.paymentMethod == 'cash'
        ).toList();
        expect(cashIncoming, isNotEmpty);

        for (final id in createdIds) {
          await incomingDataSource.deleteIncoming(id);
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

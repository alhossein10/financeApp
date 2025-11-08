import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/api_response.dart';
import 'package:finance_app/core/utils/date_formatter.dart';
import 'package:finance_app/features/expenses/data/datasources/expense_api_datasource.dart';
import 'package:finance_app/features/expenses/data/models/expense_dto.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'expense_api_datasource_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  late ExpenseApiDataSourceImpl dataSource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = ExpenseApiDataSourceImpl(apiClient: mockApiClient);
  });

  group('ExpenseApiDataSource', () {
    group('createExpense', () {
      test('should send correct request body with proper field mappings', () async {
        // Arrange
        final expenseDto = ExpenseDto(
          userId: 123,
          amount: 150.0,
          category: 'Food',
          description: 'Lunch',
          date: '2024-10-23',
          paymentMethod: 'card',
        );

        final responseData = {
          'success': true,
          'data': {
            'id': 1,
            'amount': 150.0,
            'category': 'Food',
            'description': 'Lunch',
            'date': '2024-10-23',
            'payment_method': 'card',
            'created_at': '2024-10-23T10:00:00.000000Z',
          },
        };

        when(mockApiClient.post(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => ApiResponse(
              statusCode: 201,
              data: responseData,
            ));

        // Act
        final result = await dataSource.createExpense(expenseDto);

        // Assert
        final captured = verify(mockApiClient.post(
          '/expenses',
          body: captureAnyNamed('body'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['amount'], 150.0);
        expect(captured['category'], 'Food');
        expect(captured['description'], 'Lunch');
        expect(captured['date'], '2024-10-23');
        expect(captured['payment_method'], 'card');
        expect(result.id, 1);
      });

      test('should exclude description if null or empty', () async {
        // Arrange
        final expenseDto = ExpenseDto(
          amount: 150.0,
          category: 'Food',
          date: '2024-10-23',
          paymentMethod: 'cash',
        );

        final responseData = {
          'success': true,
          'data': {
            'id': 1,
            'amount': 150.0,
            'category': 'Food',
            'date': '2024-10-23',
            'payment_method': 'cash',
          },
        };

        when(mockApiClient.post(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => ApiResponse(
              statusCode: 201,
              data: responseData,
            ));

        // Act
        await dataSource.createExpense(expenseDto);

        // Assert
        final captured = verify(mockApiClient.post(
          '/expenses',
          body: captureAnyNamed('body'),
        )).captured.single as Map<String, dynamic>;

        expect(captured.containsKey('description'), false);
      });

      test('should validate payment method before sending', () async {
        // Arrange
        final expenseDto = ExpenseDto(
          amount: 150.0,
          category: 'Food',
          date: '2024-10-23',
          paymentMethod: 'invalid_method',
        );

        // Act & Assert
        expect(
          () => dataSource.createExpense(expenseDto),
          throwsArgumentError,
        );
        verifyNever(mockApiClient.post(any, body: anyNamed('body')));
      });
    });

    group('updateExpense', () {
      test('should send correct request body with all required fields', () async {
        // Arrange
        final expenseDto = ExpenseDto(
          id: 1,
          amount: 200.0,
          category: 'Food',
          description: 'Updated lunch',
          date: '2024-10-24',
          paymentMethod: 'bank_transfer',
        );

        final responseData = {
          'success': true,
          'data': {
            'id': 1,
            'amount': 200.0,
            'category': 'Food',
            'description': 'Updated lunch',
            'date': '2024-10-24',
            'payment_method': 'bank_transfer',
          },
        };

        when(mockApiClient.put(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        await dataSource.updateExpense(1, expenseDto);

        // Assert
        final captured = verify(mockApiClient.put(
          '/expenses/1',
          body: captureAnyNamed('body'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['amount'], 200.0);
        expect(captured['category'], 'Food');
        expect(captured['date'], '2024-10-24');
        expect(captured['payment_method'], 'bank_transfer');
      });

      test('should validate payment method before updating', () async {
        // Arrange
        final expenseDto = ExpenseDto(
          id: 1,
          amount: 200.0,
          category: 'Food',
          date: '2024-10-24',
          paymentMethod: 'invalid_method',
        );

        // Act & Assert
        expect(
          () => dataSource.updateExpense(1, expenseDto),
          throwsArgumentError,
        );
        verifyNever(mockApiClient.put(any, body: anyNamed('body')));
      });
    });

    group('getExpenses', () {
      test('should use correct query parameters with date formatting', () async {
        // Arrange
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 12, 31);

        final responseData = {
          'data': [],
          'current_page': 1,
          'last_page': 1,
          'per_page': 15,
          'total': 0,
        };

        when(mockApiClient.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        await dataSource.getExpenses(
          page: 1,
          perPage: 15,
          category: 'Food',
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        final captured = verify(mockApiClient.get(
          '/expenses',
          queryParams: captureAnyNamed('queryParams'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['page'], 1);
        expect(captured['per_page'], 15);
        expect(captured['category'], 'Food');
        expect(captured['date_from'], '2024-01-01');
        expect(captured['date_to'], '2024-12-31');
      });

      test('should exclude optional filters when not provided', () async {
        // Arrange
        final responseData = {
          'data': [],
          'current_page': 1,
          'last_page': 1,
          'per_page': 15,
          'total': 0,
        };

        when(mockApiClient.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        await dataSource.getExpenses();

        // Assert
        final captured = verify(mockApiClient.get(
          '/expenses',
          queryParams: captureAnyNamed('queryParams'),
        )).captured.single as Map<String, dynamic>;

        expect(captured.containsKey('category'), false);
        expect(captured.containsKey('date_from'), false);
        expect(captured.containsKey('date_to'), false);
      });
    });

    group('getExpense', () {
      test('should fetch single expense by ID', () async {
        // Arrange
        final responseData = {
          'success': true,
          'data': {
            'id': 1,
            'amount': 150.0,
            'category': 'Food',
            'date': '2024-10-23',
            'payment_method': 'card',
          },
        };

        when(mockApiClient.get(any)).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        final result = await dataSource.getExpense(1);

        // Assert
        verify(mockApiClient.get('/expenses/1'));
        expect(result.id, 1);
        expect(result.amount, 150.0);
      });
    });

    group('deleteExpense', () {
      test('should delete expense by ID', () async {
        // Arrange
        when(mockApiClient.delete(any)).thenAnswer((_) async => ApiResponse(
              statusCode: 204,
              data: null,
            ));

        // Act
        await dataSource.deleteExpense(1);

        // Assert
        verify(mockApiClient.delete('/expenses/1'));
      });
    });

    group('Date formatting', () {
      test('should format dates as YYYY-MM-DD', () {
        // Arrange
        final date = DateTime(2024, 1, 5);

        // Act
        final formatted = DateFormatter.toApiDate(date);

        // Assert
        expect(formatted, '2024-01-05');
      });

      test('should parse YYYY-MM-DD dates correctly', () {
        // Arrange
        const dateStr = '2024-01-05';

        // Act
        final parsed = DateFormatter.fromApiDate(dateStr);

        // Assert
        expect(parsed.year, 2024);
        expect(parsed.month, 1);
        expect(parsed.day, 5);
      });
    });
  });
}

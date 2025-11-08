import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/admin/data/datasources/admin_api_datasource.dart';
import 'package:finance_app/features/admin/data/models/admin_stats_dto.dart';
import 'package:finance_app/features/admin/data/models/user_activity_dto.dart';
import 'package:finance_app/features/admin/data/models/expense_summary_dto.dart';
import 'package:finance_app/features/admin/data/models/analytics_dto.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/api_exception.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([ApiClient])
import 'admin_api_datasource_test.mocks.dart';

void main() {
  late AdminApiDataSourceImpl dataSource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = AdminApiDataSourceImpl(apiClient: mockApiClient);
  });

  group('getStats', () {
    test('should return AdminStatsDto when API call is successful', () async {
      // Arrange
      final responseData = {
        'data': {
          'total_users': 150,
          'total_expenses': 5420,
          'total_income': 2100,
          'total_transfers': 890,
          'total_amount_expenses': 125000.50,
          'total_amount_income': 450000.00,
          'fund_box_balance': 10000.00,
        },
      };

      when(mockApiClient.get('/admin/dashboard/stats')).thenAnswer(
        (_) async => ApiResponse(
          statusCode: 200,
          data: responseData,
        ),
      );

      // Act
      final result = await dataSource.getStats();

      // Assert
      expect(result, isA<AdminStatsDto>());
      expect(result.totalUsers, 150);
      expect(result.totalExpenses, 5420);
      verify(mockApiClient.get('/admin/dashboard/stats')).called(1);
    });

    test('should throw ApiException with 403 when access is denied', () async {
      // Arrange
      when(mockApiClient.get('/admin/dashboard/stats')).thenAnswer(
        (_) async => ApiResponse(
          statusCode: 403,
          data: {'message': 'Forbidden'},
        ),
      );

      // Act & Assert
      expect(
        () => dataSource.getStats(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', contains('Admin privileges required')),
        ),
      );
    });
  });

  group('getUserActivity', () {
    test('should return list of UserActivityDto when API call is successful', () async {
      // Arrange
      final responseData = {
        'data': [
          {
            'id': 1,
            'name': 'John Doe',
            'email': 'john@example.com',
            'role': 'user',
            'created_at': '2024-01-01T00:00:00.000000Z',
            'last_login': '2024-10-23T10:00:00.000000Z',
          },
        ],
      };

      when(mockApiClient.get('/admin/dashboard/users')).thenAnswer(
        (_) async => ApiResponse(
          statusCode: 200,
          data: responseData,
        ),
      );

      // Act
      final result = await dataSource.getUserActivity();

      // Assert
      expect(result, isA<List<UserActivityDto>>());
      expect(result.length, 1);
      expect(result[0].name, 'John Doe');
      verify(mockApiClient.get('/admin/dashboard/users')).called(1);
    });

    test('should throw ApiException with 403 when access is denied', () async {
      // Arrange
      when(mockApiClient.get('/admin/dashboard/users')).thenAnswer(
        (_) async => ApiResponse(
          statusCode: 403,
          data: {'message': 'Forbidden'},
        ),
      );

      // Act & Assert
      expect(
        () => dataSource.getUserActivity(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', contains('Admin privileges required')),
        ),
      );
    });
  });

  group('getExpenseSummaries', () {
    test('should return ExpenseSummaryDto when API call is successful', () async {
      // Arrange
      final responseData = {
        'data': {
          'by_category': [
            {
              'category': 'Food',
              'total': 45000.00,
              'count': 320,
            },
          ],
          'by_payment_method': [
            {
              'payment_method': 'cash',
              'total': 35000.00,
            },
          ],
        },
      };

      when(mockApiClient.get('/admin/dashboard/expenses')).thenAnswer(
        (_) async => ApiResponse(
          statusCode: 200,
          data: responseData,
        ),
      );

      // Act
      final result = await dataSource.getExpenseSummaries();

      // Assert
      expect(result, isA<ExpenseSummaryDto>());
      expect(result.byCategory.length, 1);
      expect(result.byPaymentMethod.length, 1);
      verify(mockApiClient.get('/admin/dashboard/expenses')).called(1);
    });

    test('should throw ApiException with 403 when access is denied', () async {
      // Arrange
      when(mockApiClient.get('/admin/dashboard/expenses')).thenAnswer(
        (_) async => ApiResponse(
          statusCode: 403,
          data: {'message': 'Forbidden'},
        ),
      );

      // Act & Assert
      expect(
        () => dataSource.getExpenseSummaries(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', contains('Admin privileges required')),
        ),
      );
    });
  });

  group('getAnalytics', () {
    test('should return AnalyticsDto when API call is successful', () async {
      // Arrange
      final dateFrom = DateTime(2024, 1, 1);
      final dateTo = DateTime(2024, 12, 31);
      final responseData = {
        'data': {
          'period': {
            'from': '2024-01-01',
            'to': '2024-12-31',
          },
          'expenses': {
            'total': 125000.50,
            'count': 5420,
            'average': 23.06,
          },
          'income': {
            'total': 450000.00,
            'count': 2100,
            'average': 214.29,
          },
          'net_balance': 325000.50,
          'trends': {
            'monthly': [],
          },
        },
      };

      when(mockApiClient.get(
        '/admin/dashboard/analytics',
        queryParams: anyNamed('queryParams'),
      )).thenAnswer(
        (_) async => ApiResponse(
          statusCode: 200,
          data: responseData,
        ),
      );

      // Act
      final result = await dataSource.getAnalytics(
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

      // Assert
      expect(result, isA<AnalyticsDto>());
      expect(result.period.from, '2024-01-01');
      expect(result.period.to, '2024-12-31');
      expect(result.expenses.total, 125000.50);
      verify(mockApiClient.get(
        '/admin/dashboard/analytics',
        queryParams: {
          'date_from': '2024-01-01',
          'date_to': '2024-12-31',
        },
      )).called(1);
    });

    test('should throw ApiException with 403 when access is denied', () async {
      // Arrange
      final dateFrom = DateTime(2024, 1, 1);
      final dateTo = DateTime(2024, 12, 31);

      when(mockApiClient.get(
        '/admin/dashboard/analytics',
        queryParams: anyNamed('queryParams'),
      )).thenAnswer(
        (_) async => ApiResponse(
          statusCode: 403,
          data: {'message': 'Forbidden'},
        ),
      );

      // Act & Assert
      expect(
        () => dataSource.getAnalytics(dateFrom: dateFrom, dateTo: dateTo),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', contains('Admin privileges required')),
        ),
      );
    });
  });
}

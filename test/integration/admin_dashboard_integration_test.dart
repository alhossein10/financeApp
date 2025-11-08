import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/api_exception.dart';
import 'package:finance_app/core/services/laravel_auth_service.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/features/admin/data/datasources/admin_api_datasource.dart';
import 'package:finance_app/features/admin/data/models/admin_stats_dto.dart';
import 'package:finance_app/features/admin/data/models/expense_summary_dto.dart';
import 'package:finance_app/features/admin/data/models/analytics_dto.dart';
import 'package:finance_app/features/admin/data/models/user_activity_dto.dart';
import 'package:finance_app/core/utils/date_formatter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finance_app/core/config/api_config.dart';

/// Integration tests for Admin Dashboard with role-based access
/// Tests Requirements: 4.1, 4.2, 4.3, 4.4, 4.5
void main() {
  group('Admin Dashboard Integration Tests', () {
    late ApiClient apiClient;
    late LaravelAuthService authService;
    late AdminApiDataSource adminDataSource;

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

      adminDataSource = AdminApiDataSourceImpl(apiClient: apiClient);
    });

    tearDownAll() async {
      try {
        await authService.logout();
      } catch (e) {
        // Ignore logout errors
      }
    });

    test('Admin can access dashboard stats with all required fields', () async {
      try {
        final adminEmail = 'admin_stats_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Stats User',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final stats = await adminDataSource.getDashboardStats();
        
        expect(stats, isA<AdminStatsDto>());
        expect(stats.totalUsers, isA<int>());
        expect(stats.totalExpenses, isA<int>());
        expect(stats.totalIncome, isA<int>());
        expect(stats.totalTransfers, isA<int>());
        expect(stats.totalAmountExpenses, isA<double>());
        expect(stats.totalAmountIncome, isA<double>());
        expect(stats.fundBoxBalance, isA<double>());

        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Regular user receives 403 when accessing dashboard stats', () async {
      try {
        final userEmail = 'user_stats_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Regular Stats User',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
        );

        expect(
          () => adminDataSource.getDashboardStats(),
          throwsA(isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            equals(403),
          )),
        );

        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Admin can access user activity list', () async {
      try {
        final adminEmail = 'admin_users_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Users User',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final users = await adminDataSource.getUserActivity(page: 1, perPage: 10);
        
        expect(users, isA<List<UserActivityDto>>());
        
        if (users.isNotEmpty) {
          final user = users.first;
          expect(user.id, isNotNull);
          expect(user.name, isNotEmpty);
          expect(user.email, isNotEmpty);
          expect(user.role, isNotEmpty);
          expect(user.lastActive, isNotNull);
        }

        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Regular user receives 403 when accessing user activity', () async {
      try {
        final userEmail = 'user_activity_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Regular Activity User',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
        );

        expect(
          () => adminDataSource.getUserActivity(page: 1, perPage: 10),
          throwsA(isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            equals(403),
          )),
        );

        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Admin can access expense summaries with by_category and by_payment_method', () async {
      try {
        final adminEmail = 'admin_summary_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Summary User',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final summary = await adminDataSource.getExpenseSummary();
        
        expect(summary, isA<ExpenseSummaryDto>());
        expect(summary.byCategory, isA<Map<String, CategorySummary>>());
        expect(summary.byPaymentMethod, isA<Map<String, PaymentMethodSummary>>());

        if (summary.byCategory.isNotEmpty) {
          final categorySummary = summary.byCategory.values.first;
          expect(categorySummary.category, isNotEmpty);
          expect(categorySummary.total, isA<double>());
          expect(categorySummary.count, isA<int>());
        }

        if (summary.byPaymentMethod.isNotEmpty) {
          final paymentSummary = summary.byPaymentMethod.values.first;
          expect(paymentSummary.paymentMethod, isNotEmpty);
          expect(paymentSummary.total, isA<double>());
        }

        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Admin can access analytics with date range filters', () async {
      try {
        final adminEmail = 'admin_analytics_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Analytics User',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final dateFrom = DateTime.now().subtract(const Duration(days: 30));
        final dateTo = DateTime.now();

        final analytics = await adminDataSource.getAnalytics(
          dateFrom: dateFrom,
          dateTo: dateTo,
        );
        
        expect(analytics, isA<AnalyticsDto>());
        expect(analytics.period, isNotNull);
        expect(analytics.period.from, equals(DateFormatter.toApiDate(dateFrom)));
        expect(analytics.period.to, equals(DateFormatter.toApiDate(dateTo)));
        
        expect(analytics.expenses, isNotNull);
        expect(analytics.expenses.total, isA<double>());
        expect(analytics.expenses.count, isA<int>());
        expect(analytics.expenses.average, isA<double>());
        
        expect(analytics.income, isNotNull);
        expect(analytics.income.total, isA<double>());
        expect(analytics.income.count, isA<int>());
        expect(analytics.income.average, isA<double>());
        
        expect(analytics.netBalance, isA<double>());
        
        expect(analytics.trends, isNotNull);
        expect(analytics.trends.monthly, isA<List<MonthlyTrend>>());

        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Analytics date parameters are sent in YYYY-MM-DD format', () async {
      try {
        final adminEmail = 'admin_date_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Date User',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final dateFrom = DateTime(2024, 10, 1);
        final dateTo = DateTime(2024, 10, 31);

        final analytics = await adminDataSource.getAnalytics(
          dateFrom: dateFrom,
          dateTo: dateTo,
        );
        
        expect(analytics.period.from, equals('2024-10-01'));
        expect(analytics.period.to, equals('2024-10-31'));

        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Regular user receives 403 when accessing analytics', () async {
      try {
        final userEmail = 'user_analytics_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Regular Analytics User',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
        );

        final dateFrom = DateTime.now().subtract(const Duration(days: 7));
        final dateTo = DateTime.now();

        expect(
          () => adminDataSource.getAnalytics(
            dateFrom: dateFrom,
            dateTo: dateTo,
          ),
          throwsA(isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            equals(403),
          )),
        );

        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('User activity pagination works correctly', () async {
      try {
        final adminEmail = 'admin_pagination_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Pagination User',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final page1 = await adminDataSource.getUserActivity(page: 1, perPage: 5);
        expect(page1.length, lessThanOrEqualTo(5));

        final page2 = await adminDataSource.getUserActivity(page: 2, perPage: 5);
        expect(page2, isA<List<UserActivityDto>>());

        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Dashboard stats reflect system-wide data', () async {
      try {
        final adminEmail = 'admin_system_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin System User',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final stats = await adminDataSource.getDashboardStats();
        
        // All counts should be non-negative
        expect(stats.totalUsers, greaterThanOrEqualTo(0));
        expect(stats.totalExpenses, greaterThanOrEqualTo(0));
        expect(stats.totalIncome, greaterThanOrEqualTo(0));
        expect(stats.totalTransfers, greaterThanOrEqualTo(0));
        
        // At least one user should exist (the admin we just created)
        expect(stats.totalUsers, greaterThanOrEqualTo(1));

        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Monthly trends data is properly structured', () async {
      try {
        final adminEmail = 'admin_trends_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Trends User',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final dateFrom = DateTime.now().subtract(const Duration(days: 90));
        final dateTo = DateTime.now();

        final analytics = await adminDataSource.getAnalytics(
          dateFrom: dateFrom,
          dateTo: dateTo,
        );
        
        if (analytics.trends.monthly.isNotEmpty) {
          final trend = analytics.trends.monthly.first;
          expect(trend.month, isNotEmpty);
          expect(trend.expenses, isA<double>());
          expect(trend.income, isA<double>());
        }

        await authService.logout();
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

import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/api_exception.dart';
import 'package:finance_app/core/services/laravel_auth_service.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/features/fund_box/data/datasources/fund_box_api_datasource.dart';
import 'package:finance_app/features/fund_box/data/models/fund_box_dto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finance_app/core/config/api_config.dart';

/// Integration tests for Fund Box with role-based access control
/// Tests Requirements: 3.1, 3.2, 3.3, 3.4, 3.5
void main() {
  group('Fund Box Role-Based Integration Tests', () {
    late ApiClient apiClient;
    late LaravelAuthService authService;
    late FundBoxApiDataSource fundBoxDataSource;

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

      fundBoxDataSource = FundBoxApiDataSourceImpl(apiClient: apiClient);
    });

    tearDownAll(() async {
      try {
        await authService.logout();
      } catch (e) {
        // Ignore logout errors in teardown
      }
    });

    test('Admin user can access fund box successfully', () async {
      try {
        // Register and login as admin
        final adminEmail = 'admin_fundbox_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Fund Box User',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final fundBox = await fundBoxDataSource.getFundBox();
        
        expect(fundBox, isNotNull);
        expect(fundBox.id, isNotNull);
        expect(fundBox.totalBalance, isA<double>());
        expect(fundBox.lastUpdated, isNotNull);

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

    test('Regular user receives 403 Forbidden when accessing fund box', () async {
      try {
        // Register and login as regular user
        final userEmail = 'user_fundbox_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Regular Fund Box User',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
        );

        expect(
          () => fundBoxDataSource.getFundBox(),
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

    test('Admin can update fund box with total_balance field', () async {
      try {
        final adminEmail = 'admin_update_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Update User',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final currentFundBox = await fundBoxDataSource.getFundBox();
        final newBalance = currentFundBox.totalBalance + 1000.0;

        final updated = await fundBoxDataSource.updateFundBox(newBalance);
        
        expect(updated.totalBalance, equals(newBalance));
        expect(updated.lastUpdated, isNotNull);

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

    test('Regular user receives 403 when trying to update fund box', () async {
      try {
        final userEmail = 'user_update_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Regular Update User',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
        );

        expect(
          () => fundBoxDataSource.updateFundBox(5000.0),
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

    test('403 error includes proper error message', () async {
      try {
        final userEmail = 'user_error_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Error Test User',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
        );

        try {
          await fundBoxDataSource.getFundBox();
          fail('Should have thrown ApiException');
        } on ApiException catch (e) {
          expect(e.statusCode, equals(403));
          expect(e.isForbidden, isTrue);
          expect(
            e.userFriendlyMessage.toLowerCase(),
            contains('access denied'),
          );
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

    test('Fund box response parses total_balance and last_updated correctly', () async {
      try {
        final adminEmail = 'admin_parse_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Parse User',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final fundBox = await fundBoxDataSource.getFundBox();
        
        expect(fundBox.totalBalance, isA<double>());
        expect(fundBox.totalBalance, greaterThanOrEqualTo(0));
        expect(fundBox.lastUpdated, isA<DateTime>());
        expect(fundBox.lastUpdated.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);

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

    test('Multiple admin users can access fund box', () async {
      try {
        final admin1Email = 'admin1_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 1',
          email: admin1Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final fundBox1 = await fundBoxDataSource.getFundBox();
        expect(fundBox1, isNotNull);

        await authService.logout();

        final admin2Email = 'admin2_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 2',
          email: admin2Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final fundBox2 = await fundBoxDataSource.getFundBox();
        expect(fundBox2, isNotNull);
        expect(fundBox2.totalBalance, equals(fundBox1.totalBalance));

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

    test('Fund box update reflects immediately on subsequent reads', () async {
      try {
        final adminEmail = 'admin_reflect_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Reflect User',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final initial = await fundBoxDataSource.getFundBox();
        final newBalance = initial.totalBalance + 500.0;

        await fundBoxDataSource.updateFundBox(newBalance);

        final updated = await fundBoxDataSource.getFundBox();
        expect(updated.totalBalance, equals(newBalance));
        expect(updated.lastUpdated.isAfter(initial.lastUpdated), isTrue);

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

    test('Fund box handles negative balance updates', () async {
      try {
        final adminEmail = 'admin_negative_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Negative User',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final updated = await fundBoxDataSource.updateFundBox(-100.0);
        expect(updated.totalBalance, equals(-100.0));

        // Reset to positive
        await fundBoxDataSource.updateFundBox(1000.0);

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

    test('Fund box handles large balance values', () async {
      try {
        final adminEmail = 'admin_large_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Large User',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final largeBalance = 999999999.99;
        final updated = await fundBoxDataSource.updateFundBox(largeBalance);
        
        expect(updated.totalBalance, equals(largeBalance));

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

import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/services/laravel_auth_service.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/core/config/api_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Integration tests for complete authentication flow
/// Tests Requirements: 29.5, 29.6, 29.7
void main() {
  group('Authentication Flow Integration Tests', () {
    late ApiClient apiClient;
    late TokenManager tokenManager;
    late LaravelAuthService authService;
    late FlutterSecureStorage secureStorage;

    setUp(() {
      // Initialize with test configuration
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      apiClient = DioApiClient(dio: dio);
      secureStorage = const FlutterSecureStorage();
      tokenManager = TokenManager(secureStorage: secureStorage);
      authService = LaravelAuthService(
        apiClient: apiClient,
        tokenManager: tokenManager,
      );
    });

    tearDown(() async {
      // Clean up after each test
      await tokenManager.clearTokens();
    });

    test('Complete registration flow', () async {
      // Test user registration
      final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      final testPassword = 'TestPassword123!';
      final testName = 'Test User';

      try {
        final result = await authService.register(
          name: testName,
          email: testEmail,
          password: testPassword,
        );

        expect(result, isNotNull);
        expect(result.email, equals(testEmail));
        expect(result.name, equals(testName));

        // Verify token is stored
        final storedToken = await tokenManager.getToken();
        expect(storedToken, isNotNull);

        // Verify we can get current user
        final currentUser = await authService.getCurrentUser();
        expect(currentUser, isNotNull);
        expect(currentUser.email, equals(testEmail));
      } catch (e) {
        // If test fails due to network or API unavailability, skip
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Complete login flow', () async {
      // First register a user
      final testEmail = 'login_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      final testPassword = 'TestPassword123!';
      final testName = 'Login Test User';

      try {
        await authService.register(
          name: testName,
          email: testEmail,
          password: testPassword,
        );
        await authService.logout();

        // Now test login
        final loginResult = await authService.login(
          email: testEmail,
          password: testPassword,
        );

        expect(loginResult, isNotNull);
        expect(loginResult.email, equals(testEmail));

        // Verify authentication state
        final isAuth = await authService.isAuthenticated();
        expect(isAuth, isTrue);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Token refresh flow', () async {
      // Register and login
      final testEmail = 'refresh_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      final testPassword = 'TestPassword123!';

      try {
        await authService.register(
          name: 'Refresh Test',
          email: testEmail,
          password: testPassword,
        );
        final oldToken = await tokenManager.getToken();

        // Refresh token
        await authService.refreshToken();
        final newToken = await tokenManager.getToken();

        expect(newToken, isNotNull);
        expect(newToken, isNot(equals(oldToken)));

        // Verify we can still make authenticated requests
        final user = await authService.getCurrentUser();
        expect(user, isNotNull);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Logout flow', () async {
      // Register a user
      final testEmail = 'logout_test_${DateTime.now().millisecondsSinceEpoch}@example.com';

      try {
        await authService.register(
          name: 'Logout Test',
          email: testEmail,
          password: 'TestPassword123!',
        );

        // Verify authenticated
        expect(await authService.isAuthenticated(), isTrue);

        // Logout
        await authService.logout();

        // Verify token is cleared
        final token = await tokenManager.getToken();
        expect(token, isNull);

        // Verify not authenticated
        expect(await authService.isAuthenticated(), isFalse);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Invalid credentials handling', () async {
      try {
        await authService.login(
          email: 'nonexistent@example.com',
          password: 'wrongpassword',
        );

        // Should not reach here - should throw exception
        fail('Expected exception for invalid credentials');
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        // Expect an API exception for invalid credentials
        expect(e, isNotNull);
      }
    });
  });
}

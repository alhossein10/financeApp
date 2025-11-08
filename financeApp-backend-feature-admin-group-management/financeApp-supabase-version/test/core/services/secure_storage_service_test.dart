import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finance_app/core/services/secure_storage_service.dart';

void main() {
  late SecureStorageService secureStorageService;
  late FlutterSecureStorage mockSecureStorage;

  setUp(() {
    // Note: In a real test, you would use a mock
    // For this example, we're using the actual FlutterSecureStorage
    // which requires platform-specific setup
    mockSecureStorage = const FlutterSecureStorage();
    secureStorageService = SecureStorageService(mockSecureStorage);
  });

  group('SecureStorageService', () {
    group('Auth Token Methods', () {
      test('should store and retrieve auth token', () async {
        // Arrange
        const testToken = 'test-auth-token-123';

        // Act
        await secureStorageService.storeAuthToken(testToken);
        final retrievedToken = await secureStorageService.getAuthToken();

        // Assert
        expect(retrievedToken, equals(testToken));
      });

      test('should check if auth token exists', () async {
        // Arrange
        const testToken = 'test-auth-token-456';

        // Act
        await secureStorageService.storeAuthToken(testToken);
        final hasToken = await secureStorageService.hasAuthToken();

        // Assert
        expect(hasToken, isTrue);
      });
    });

    group('User ID Methods', () {
      test('should store and retrieve user ID', () async {
        // Arrange
        const testUserId = 42;

        // Act
        await secureStorageService.storeUserId(testUserId);
        final retrievedUserId = await secureStorageService.getUserId();

        // Assert
        expect(retrievedUserId, equals(testUserId));
      });
    });

    group('Credentials Methods', () {
      test('should store and retrieve credentials with encryption', () async {
        // Arrange
        const testEmail = 'test@example.com';
        const testPassword = 'securePassword123';

        // Act
        await secureStorageService.storeCredentials(
          email: testEmail,
          password: testPassword,
        );
        final credentials = await secureStorageService.getStoredCredentials();

        // Assert
        expect(credentials, isNotNull);
        expect(credentials!['email'], equals(testEmail));
        expect(credentials['password'], equals(testPassword));
      });

      test('should check if remember me is enabled', () async {
        // Arrange
        const testEmail = 'test@example.com';
        const testPassword = 'password';

        // Act
        await secureStorageService.storeCredentials(
          email: testEmail,
          password: testPassword,
        );
        final isEnabled = await secureStorageService.isRememberMeEnabled();

        // Assert
        expect(isEnabled, isTrue);
      });

      test('should clear stored credentials', () async {
        // Arrange
        await secureStorageService.storeCredentials(
          email: 'test@example.com',
          password: 'password',
        );

        // Act
        await secureStorageService.clearStoredCredentials();
        final credentials = await secureStorageService.getStoredCredentials();

        // Assert
        expect(credentials, isNull);
      });
    });

    group('Generic Storage Methods', () {
      test('should store and retrieve value without encryption', () async {
        // Arrange
        const testKey = 'test_key';
        const testValue = 'test_value';

        // Act
        await secureStorageService.storeValue(
          key: testKey,
          value: testValue,
          encrypt: false,
        );
        final retrievedValue = await secureStorageService.getValue(
          key: testKey,
          encrypted: false,
        );

        // Assert
        expect(retrievedValue, equals(testValue));
      });

      test('should store and retrieve value with encryption', () async {
        // Arrange
        const testKey = 'encrypted_key';
        const testValue = 'sensitive_data';

        // Act
        await secureStorageService.storeValue(
          key: testKey,
          value: testValue,
          encrypt: true,
        );
        final retrievedValue = await secureStorageService.getValue(
          key: testKey,
          encrypted: true,
        );

        // Assert
        expect(retrievedValue, equals(testValue));
      });

      test('should check if key exists', () async {
        // Arrange
        const testKey = 'existing_key';
        const testValue = 'value';

        // Act
        await secureStorageService.storeValue(
          key: testKey,
          value: testValue,
        );
        final exists = await secureStorageService.containsKey(testKey);

        // Assert
        expect(exists, isTrue);
      });

      test('should delete specific value', () async {
        // Arrange
        const testKey = 'deletable_key';
        await secureStorageService.storeValue(
          key: testKey,
          value: 'value',
        );

        // Act
        await secureStorageService.deleteValue(testKey);
        final exists = await secureStorageService.containsKey(testKey);

        // Assert
        expect(exists, isFalse);
      });
    });

    group('Clear Methods', () {
      test('should clear auth data only', () async {
        // Arrange
        await secureStorageService.storeAuthToken('token');
        await secureStorageService.storeUserId(123);
        await secureStorageService.storeValue(
          key: 'other_data',
          value: 'should_remain',
        );

        // Act
        await secureStorageService.clearAuthData();

        // Assert
        final token = await secureStorageService.getAuthToken();
        final userId = await secureStorageService.getUserId();
        final otherData = await secureStorageService.getValue(
          key: 'other_data',
        );

        expect(token, isNull);
        expect(userId, isNull);
        expect(otherData, equals('should_remain'));
      });

      test('should clear all data', () async {
        // Arrange
        await secureStorageService.storeAuthToken('token');
        await secureStorageService.storeUserId(123);
        await secureStorageService.storeValue(
          key: 'other_data',
          value: 'value',
        );

        // Act
        await secureStorageService.clearAll();

        // Assert
        final token = await secureStorageService.getAuthToken();
        final userId = await secureStorageService.getUserId();
        final otherData = await secureStorageService.getValue(
          key: 'other_data',
        );

        expect(token, isNull);
        expect(userId, isNull);
        expect(otherData, isNull);
      });
    });
  });
}

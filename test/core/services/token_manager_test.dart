import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:finance_app/core/services/token_manager.dart';

@GenerateMocks([FlutterSecureStorage])
import 'token_manager_test.mocks.dart';

void main() {
  late TokenManager tokenManager;
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    tokenManager = TokenManager(secureStorage: mockSecureStorage);
  });

  group('TokenManager - Save and Retrieve Token', () {
    test('should save token with all parameters', () async {
      // Arrange
      const token = 'test_token_123';
      const tokenType = 'Bearer';
      final expiresAt = DateTime.now().add(const Duration(hours: 1));
      const refreshToken = 'refresh_token_123';

      when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async => {});

      // Act
      await tokenManager.saveToken(
        token: token,
        tokenType: tokenType,
        expiresAt: expiresAt,
        refreshToken: refreshToken,
      );

      // Assert
      verify(mockSecureStorage.write(key: 'auth_token', value: token)).called(1);
      verify(mockSecureStorage.write(key: 'token_type', value: tokenType)).called(1);
      verify(mockSecureStorage.write(
        key: 'token_expires_at',
        value: expiresAt.toIso8601String(),
      )).called(1);
      verify(mockSecureStorage.write(key: 'refresh_token', value: refreshToken)).called(1);
    });

    test('should retrieve stored token', () async {
      // Arrange
      const token = 'test_token_123';
      when(mockSecureStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => token);

      // Act
      final result = await tokenManager.getToken();

      // Assert
      expect(result, token);
      verify(mockSecureStorage.read(key: 'auth_token')).called(1);
    });

    test('should return null when no token is stored', () async {
      // Arrange
      when(mockSecureStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => null);

      // Act
      final result = await tokenManager.getToken();

      // Assert
      expect(result, null);
    });
  });

  group('TokenManager - Token Validation', () {
    test('should return true when token exists and is not expired', () async {
      // Arrange
      const token = 'test_token_123';
      final expiresAt = DateTime.now().add(const Duration(hours: 1));

      when(mockSecureStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => token);
      when(mockSecureStorage.read(key: 'token_expires_at'))
          .thenAnswer((_) async => expiresAt.toIso8601String());

      // Act
      final result = await tokenManager.isTokenValid();

      // Assert
      expect(result, true);
    });

    test('should return false when token is expired', () async {
      // Arrange
      const token = 'test_token_123';
      final expiresAt = DateTime.now().subtract(const Duration(hours: 1));

      when(mockSecureStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => token);
      when(mockSecureStorage.read(key: 'token_expires_at'))
          .thenAnswer((_) async => expiresAt.toIso8601String());

      // Act
      final result = await tokenManager.isTokenValid();

      // Assert
      expect(result, false);
    });

    test('should return false when no token exists', () async {
      // Arrange
      when(mockSecureStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => null);

      // Act
      final result = await tokenManager.isTokenValid();

      // Assert
      expect(result, false);
    });
  });

  group('TokenManager - Token Expiration', () {
    test('should detect when token will expire soon', () async {
      // Arrange
      final expiresAt = DateTime.now().add(const Duration(minutes: 3));

      when(mockSecureStorage.read(key: 'token_expires_at'))
          .thenAnswer((_) async => expiresAt.toIso8601String());

      // Act
      final result = await tokenManager.willTokenExpireSoon();

      // Assert
      expect(result, true);
    });

    test('should return false when token will not expire soon', () async {
      // Arrange
      final expiresAt = DateTime.now().add(const Duration(hours: 1));

      when(mockSecureStorage.read(key: 'token_expires_at'))
          .thenAnswer((_) async => expiresAt.toIso8601String());

      // Act
      final result = await tokenManager.willTokenExpireSoon();

      // Assert
      expect(result, false);
    });

    test('should return true when token needs refresh (expired)', () async {
      // Arrange
      const token = 'test_token_123';
      final expiresAt = DateTime.now().subtract(const Duration(hours: 1));

      when(mockSecureStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => token);
      when(mockSecureStorage.read(key: 'token_expires_at'))
          .thenAnswer((_) async => expiresAt.toIso8601String());

      // Act
      final result = await tokenManager.needsRefresh();

      // Assert
      expect(result, true);
    });

    test('should return true when token needs refresh (expiring soon)', () async {
      // Arrange
      const token = 'test_token_123';
      final expiresAt = DateTime.now().add(const Duration(minutes: 3));

      when(mockSecureStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => token);
      when(mockSecureStorage.read(key: 'token_expires_at'))
          .thenAnswer((_) async => expiresAt.toIso8601String());

      // Act
      final result = await tokenManager.needsRefresh();

      // Assert
      expect(result, true);
    });
  });

  group('TokenManager - Authorization Header', () {
    test('should generate correct authorization header', () async {
      // Arrange
      const token = 'test_token_123';
      const tokenType = 'Bearer';

      when(mockSecureStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => token);
      when(mockSecureStorage.read(key: 'token_type'))
          .thenAnswer((_) async => tokenType);

      // Act
      final result = await tokenManager.getAuthorizationHeader();

      // Assert
      expect(result, 'Bearer test_token_123');
    });

    test('should return null when no token exists', () async {
      // Arrange
      when(mockSecureStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => null);

      // Act
      final result = await tokenManager.getAuthorizationHeader();

      // Assert
      expect(result, null);
    });
  });

  group('TokenManager - Clear Tokens', () {
    test('should clear all tokens', () async {
      // Arrange
      when(mockSecureStorage.delete(key: anyNamed('key')))
          .thenAnswer((_) async => {});

      // Act
      await tokenManager.clearTokens();

      // Assert
      verify(mockSecureStorage.delete(key: 'auth_token')).called(1);
      verify(mockSecureStorage.delete(key: 'token_type')).called(1);
      verify(mockSecureStorage.delete(key: 'token_expires_at')).called(1);
      verify(mockSecureStorage.delete(key: 'refresh_token')).called(1);
      verify(mockSecureStorage.delete(key: 'token_last_validated')).called(1);
    });
  });

  group('TokenManager - Token Info', () {
    test('should return complete token info', () async {
      // Arrange
      const token = 'test_token_123';
      final expiresAt = DateTime.now().add(const Duration(hours: 1));

      when(mockSecureStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => token);
      when(mockSecureStorage.read(key: 'token_expires_at'))
          .thenAnswer((_) async => expiresAt.toIso8601String());
      when(mockSecureStorage.read(key: 'token_last_validated'))
          .thenAnswer((_) async => null);

      // Act
      final result = await tokenManager.getTokenInfo();

      // Assert
      expect(result['hasToken'], true);
      expect(result['isExpired'], false);
      expect(result['willExpireSoon'], false);
      expect(result['needsRefresh'], false);
      expect(result['expiresAt'], isNotNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finance_app/core/services/token_manager.dart';

/// Integration test for Token Management
/// Tests the complete token lifecycle without mocks
void main() {
  group('Token Management Integration Tests', () {
    late TokenManager tokenManager;
    late FlutterSecureStorage secureStorage;

    setUp(() {
      // Use real secure storage for integration testing
      FlutterSecureStorage.setMockInitialValues({});
      secureStorage = const FlutterSecureStorage();
      tokenManager = TokenManager(secureStorage: secureStorage);
    });

    tearDown(() async {
      // Clean up after each test
      await tokenManager.clearAll();
    });

    test('Complete token lifecycle - save, retrieve, validate, clear', () async {
      // 1. Initially no token should exist
      expect(await tokenManager.hasToken(), false);
      expect(await tokenManager.isTokenValid(), false);

      // 2. Save a token
      const token = 'test_jwt_token_12345';
      final expiresAt = DateTime.now().add(const Duration(hours: 1));
      
      await tokenManager.saveToken(
        token: token,
        tokenType: 'Bearer',
        expiresAt: expiresAt,
        refreshToken: 'refresh_token_12345',
      );

      // 3. Verify token was saved
      expect(await tokenManager.hasToken(), true);
      expect(await tokenManager.getToken(), token);
      expect(await tokenManager.getTokenType(), 'Bearer');

      // 4. Verify token is valid
      expect(await tokenManager.isTokenValid(), true);
      expect(await tokenManager.isTokenExpired(), false);

      // 5. Verify authorization header
      final authHeader = await tokenManager.getAuthorizationHeader();
      expect(authHeader, 'Bearer $token');

      // 6. Get token info
      final tokenInfo = await tokenManager.getTokenInfo();
      expect(tokenInfo['hasToken'], true);
      expect(tokenInfo['isExpired'], false);
      expect(tokenInfo['needsRefresh'], false);

      // 7. Clear tokens
      await tokenManager.clearTokens();

      // 8. Verify tokens were cleared
      expect(await tokenManager.hasToken(), false);
      expect(await tokenManager.getToken(), null);
    });

    test('Token expiration detection', () async {
      // Save an expired token
      const token = 'expired_token';
      final expiresAt = DateTime.now().subtract(const Duration(hours: 1));
      
      await tokenManager.saveToken(
        token: token,
        expiresAt: expiresAt,
      );

      // Verify token exists but is expired
      expect(await tokenManager.hasToken(), true);
      expect(await tokenManager.isTokenExpired(), true);
      expect(await tokenManager.isTokenValid(), false);
      expect(await tokenManager.needsRefresh(), true);
    });

    test('Token refresh threshold detection', () async {
      // Save a token that will expire soon (3 minutes)
      const token = 'expiring_soon_token';
      final expiresAt = DateTime.now().add(const Duration(minutes: 3));
      
      await tokenManager.saveToken(
        token: token,
        expiresAt: expiresAt,
      );

      // Verify token needs refresh
      expect(await tokenManager.willTokenExpireSoon(), true);
      expect(await tokenManager.needsRefresh(), true);
      expect(await tokenManager.isTokenValid(), true); // Still valid, just needs refresh
    });

    test('Token without expiration date', () async {
      // Save a token without expiration
      const token = 'no_expiry_token';
      
      await tokenManager.saveToken(token: token);

      // Verify token is valid and doesn't need refresh
      expect(await tokenManager.hasToken(), true);
      expect(await tokenManager.isTokenValid(), true);
      expect(await tokenManager.isTokenExpired(), false);
      expect(await tokenManager.willTokenExpireSoon(), false);
      expect(await tokenManager.needsRefresh(), false);
    });

    test('Token validation caching', () async {
      // Save a valid token
      const token = 'cached_token';
      final expiresAt = DateTime.now().add(const Duration(hours: 1));
      
      await tokenManager.saveToken(
        token: token,
        expiresAt: expiresAt,
      );

      // Mark as validated
      await tokenManager.markAsValidated();

      // Check cached validation
      expect(await tokenManager.isTokenValidCached(), true);

      // Get token info to verify last validated timestamp
      final tokenInfo = await tokenManager.getTokenInfo();
      expect(tokenInfo['lastValidated'], isNotNull);
    });

    test('Multiple token updates', () async {
      // Save first token
      await tokenManager.saveToken(token: 'token1');
      expect(await tokenManager.getToken(), 'token1');

      // Update with second token
      await tokenManager.saveToken(token: 'token2');
      expect(await tokenManager.getToken(), 'token2');

      // Update with third token
      await tokenManager.saveToken(token: 'token3');
      expect(await tokenManager.getToken(), 'token3');
    });

    test('Refresh token storage and retrieval', () async {
      // Save token with refresh token
      const token = 'access_token';
      const refreshToken = 'refresh_token_xyz';
      
      await tokenManager.saveToken(
        token: token,
        refreshToken: refreshToken,
      );

      // Verify both tokens are stored
      expect(await tokenManager.getToken(), token);
      expect(await tokenManager.getRefreshToken(), refreshToken);
    });
  });
}

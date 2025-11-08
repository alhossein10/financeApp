import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token Manager for handling authentication tokens
/// Stores tokens securely and manages token lifecycle
/// 
/// Features:
/// - Secure token storage using flutter_secure_storage
/// - Token validation on app start
/// - Automatic token refresh logic
/// - Token expiration checking
/// - Bearer token header generation
class TokenManager {
  final FlutterSecureStorage _secureStorage;

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _tokenTypeKey = 'token_type';
  static const String _expiresAtKey = 'token_expires_at';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _lastValidatedKey = 'token_last_validated';

  // Token refresh threshold (5 minutes before expiration)
  static const Duration _refreshThreshold = Duration(minutes: 5);
  
  // Token validation cache duration (1 minute)
  static const Duration _validationCacheDuration = Duration(minutes: 1);

  TokenManager({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Store authentication token with secure storage
  /// 
  /// Parameters:
  /// - token: JWT token string
  /// - tokenType: Token type (default: 'Bearer')
  /// - expiresAt: Token expiration timestamp
  /// - refreshToken: Optional refresh token for token renewal
  Future<void> saveToken({
    required String token,
    String tokenType = 'Bearer',
    DateTime? expiresAt,
    String? refreshToken,
  }) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
      await _secureStorage.write(key: _tokenTypeKey, value: tokenType);
      
      if (expiresAt != null) {
        await _secureStorage.write(
          key: _expiresAtKey,
          value: expiresAt.toIso8601String(),
        );
      }
      
      if (refreshToken != null) {
        await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      }
      
      // Mark token as validated now
      await _updateLastValidated();
      
      print('🔑 [TokenManager] Token saved successfully');
    } catch (e) {
      print('🔴 [TokenManager] Error saving token: $e');
      rethrow;
    }
  }

  /// Get stored authentication token
  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      print('🔴 [TokenManager] Error reading token: $e');
      return null;
    }
  }

  /// Get token type (usually 'Bearer')
  Future<String?> getTokenType() async {
    try {
      return await _secureStorage.read(key: _tokenTypeKey);
    } catch (e) {
      print('🔴 [TokenManager] Error reading token type: $e');
      return null;
    }
  }

  /// Get token expiration date
  Future<DateTime?> getExpiresAt() async {
    try {
      final expiresAtStr = await _secureStorage.read(key: _expiresAtKey);
      if (expiresAtStr == null) return null;
      
      return DateTime.parse(expiresAtStr);
    } catch (e) {
      print('🔴 [TokenManager] Error reading expiration date: $e');
      return null;
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      print('🔴 [TokenManager] Error reading refresh token: $e');
      return null;
    }
  }

  /// Get full authorization header value
  /// Returns "Bearer {token}" format for API requests
  Future<String?> getAuthorizationHeader() async {
    final token = await getToken();
    if (token == null) return null;
    
    final tokenType = await getTokenType() ?? 'Bearer';
    return '$tokenType $token';
  }

  /// Check if token exists in secure storage
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Check if token is expired based on stored expiration date
  Future<bool> isTokenExpired() async {
    final expiresAt = await getExpiresAt();
    if (expiresAt == null) {
      // If no expiration date, check if token exists
      // Tokens without expiration should be validated with server
      return !await hasToken();
    }
    
    final now = DateTime.now();
    final isExpired = now.isAfter(expiresAt);
    
    if (isExpired) {
      print('⚠️ [TokenManager] Token expired at $expiresAt (now: $now)');
    }
    
    return isExpired;
  }

  /// Check if token will expire soon (within refresh threshold)
  /// Used to trigger automatic token refresh
  Future<bool> willTokenExpireSoon() async {
    final expiresAt = await getExpiresAt();
    if (expiresAt == null) {
      // If no expiration date, assume token doesn't expire soon
      return false;
    }
    
    final thresholdTime = DateTime.now().add(_refreshThreshold);
    final willExpire = thresholdTime.isAfter(expiresAt);
    
    if (willExpire) {
      print('⚠️ [TokenManager] Token will expire soon at $expiresAt');
    }
    
    return willExpire;
  }

  /// Check if token needs refresh based on expiration time
  /// Returns true if token will expire within refresh threshold
  Future<bool> needsRefresh() async {
    if (!await hasToken()) return false;
    if (await isTokenExpired()) return true;
    return await willTokenExpireSoon();
  }

  /// Check if token is valid (exists and not expired)
  /// This is a quick local check without server validation
  Future<bool> isTokenValid() async {
    if (!await hasToken()) {
      print('⚠️ [TokenManager] No token found');
      return false;
    }
    
    if (await isTokenExpired()) {
      print('⚠️ [TokenManager] Token is expired');
      return false;
    }
    
    return true;
  }

  /// Validate token with cached result
  /// Returns true if token was recently validated or is valid locally
  /// Use this for quick validation checks without server calls
  Future<bool> isTokenValidCached() async {
    // First check local validity
    if (!await isTokenValid()) {
      return false;
    }
    
    // Check if recently validated with server
    final lastValidated = await _getLastValidated();
    if (lastValidated != null) {
      final cacheExpiry = lastValidated.add(_validationCacheDuration);
      if (DateTime.now().isBefore(cacheExpiry)) {
        print('✅ [TokenManager] Token validation cached (validated at $lastValidated)');
        return true;
      }
    }
    
    // Token exists and not expired, but needs server validation
    return true;
  }

  /// Update last validated timestamp
  Future<void> _updateLastValidated() async {
    try {
      await _secureStorage.write(
        key: _lastValidatedKey,
        value: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('🔴 [TokenManager] Error updating last validated: $e');
    }
  }

  /// Get last validated timestamp
  Future<DateTime?> _getLastValidated() async {
    try {
      final lastValidatedStr = await _secureStorage.read(key: _lastValidatedKey);
      if (lastValidatedStr == null) return null;
      
      return DateTime.parse(lastValidatedStr);
    } catch (e) {
      print('🔴 [TokenManager] Error reading last validated: $e');
      return null;
    }
  }

  /// Mark token as validated (called after successful server validation)
  Future<void> markAsValidated() async {
    await _updateLastValidated();
    print('✅ [TokenManager] Token marked as validated');
  }

  /// Clear all stored tokens and validation data
  /// Called on logout or when token becomes invalid
  Future<void> clearTokens() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _tokenTypeKey);
      await _secureStorage.delete(key: _expiresAtKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _lastValidatedKey);
      
      print('🔑 [TokenManager] All tokens cleared');
    } catch (e) {
      print('🔴 [TokenManager] Error clearing tokens: $e');
      rethrow;
    }
  }

  /// Clear all secure storage (use with caution)
  /// This will remove ALL data from secure storage, not just tokens
  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
      print('🔑 [TokenManager] All secure storage cleared');
    } catch (e) {
      print('🔴 [TokenManager] Error clearing all storage: $e');
      rethrow;
    }
  }

  /// Get token info for debugging
  /// Returns a map with token status information (without exposing token value)
  Future<Map<String, dynamic>> getTokenInfo() async {
    final hasToken = await this.hasToken();
    final expiresAt = await getExpiresAt();
    final isExpired = await isTokenExpired();
    final willExpireSoon = await willTokenExpireSoon();
    final lastValidated = await _getLastValidated();
    
    return {
      'hasToken': hasToken,
      'expiresAt': expiresAt?.toIso8601String(),
      'isExpired': isExpired,
      'willExpireSoon': willExpireSoon,
      'lastValidated': lastValidated?.toIso8601String(),
      'needsRefresh': await needsRefresh(),
    };
  }
}

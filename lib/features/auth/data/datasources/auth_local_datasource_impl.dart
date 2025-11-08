import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../models/session_model.dart';
import '../models/user_model.dart';
import 'auth_local_datasource.dart';

/// Implementation of [AuthLocalDataSource] using secure storage
/// NOTE: This is for Laravel version - auth handled by backend, local storage for caching only
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;
  final Uuid _uuid = const Uuid();

  // Secure storage keys
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'username';
  static const String _keyEmail = 'email';

  AuthLocalDataSourceImpl({
    required this.secureStorage,
  });

  /// Hash password using SHA-256 with salt
  /// Note: In production, consider using a more robust solution like bcrypt via FFI
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate a random salt for password hashing
  String _generateSalt() {
    return _uuid.v4();
  }

  /// Verify password against stored hash
  bool _verifyPassword(String password, String storedHash) {
    // Extract salt from stored hash (format: salt:hash)
    final parts = storedHash.split(':');
    if (parts.length != 2) {
      return false;
    }
    final salt = parts[0];
    final hash = parts[1];
    final computedHash = _hashPassword(password, salt);
    return computedHash == hash;
  }

  /// Create password hash with salt (format: salt:hash)
  String _createPasswordHash(String password) {
    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);
    return '$salt:$hash';
  }

  /// Generate a secure random token
  String _generateToken() {
    return _uuid.v4();
  }

  @override
  Future<UserModel> login(String email, String password) async {
    // NOTE: For Laravel version, actual login is handled by API
    // This is just a stub for compatibility
    throw app_exceptions.AuthenticationException('Local login not supported. Use API login.');
  }

  @override
  Future<UserModel> register(
    String username,
    String email,
    String password,
  ) async {
    // NOTE: For Laravel version, actual registration is handled by API
    // This is just a stub for compatibility
    throw app_exceptions.AuthenticationException('Local registration not supported. Use API registration.');
  }

  @override
  Future<void> logout() async {
    try {
      await clearAuthData();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to logout: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final userId = await secureStorage.read(key: _keyUserId);
      if (userId == null) return null;

      final username = await secureStorage.read(key: _keyUsername);
      final email = await secureStorage.read(key: _keyEmail);

      if (username == null || email == null) return null;

      // Get full user data from database
      return await getUserById(int.parse(userId));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      await secureStorage.write(key: _keyUserId, value: user.id.toString());
      await secureStorage.write(key: _keyUsername, value: user.username);
      await secureStorage.write(key: _keyEmail, value: user.email);
    } catch (e) {
      throw app_exceptions.CacheException('Failed to cache user: ${e.toString()}');
    }
  }

  @override
  Future<void> cacheAuthToken(String token) async {
    try {
      await secureStorage.write(key: _keyAuthToken, value: token);
    } catch (e) {
      throw app_exceptions.CacheException('Failed to cache auth token: ${e.toString()}');
    }
  }

  @override
  Future<String?> getAuthToken() async {
    try {
      return await secureStorage.read(key: _keyAuthToken);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearAuthData() async {
    try {
      await secureStorage.delete(key: _keyAuthToken);
      await secureStorage.delete(key: _keyUserId);
      await secureStorage.delete(key: _keyUsername);
      await secureStorage.delete(key: _keyEmail);
    } catch (e) {
      throw app_exceptions.CacheException('Failed to clear auth data: ${e.toString()}');
    }
  }

  @override
  Future<SessionModel> createSession(
    int userId,
    String token,
    Duration duration,
  ) async {
    // NOTE: For Laravel version, sessions are handled by API
    final now = DateTime.now();
    final expiresAt = now.add(duration);
    
    return SessionModel(
      id: 0,
      userId: userId,
      token: token,
      createdAt: now,
      expiresAt: expiresAt,
      lastActivity: now,
    );
  }

  @override
  Future<SessionModel?> getSessionByToken(String token) async {
    // NOTE: For Laravel version, sessions are handled by API
    return null;
  }

  @override
  Future<void> updateSessionActivity(String token) async {
    // NOTE: For Laravel version, sessions are handled by API
  }

  @override
  Future<void> deleteSession(String token) async {
    // NOTE: For Laravel version, sessions are handled by API
  }

  @override
  Future<void> deleteAllUserSessions(int userId) async {
    // NOTE: For Laravel version, sessions are handled by API
  }

  @override
  Future<UserModel> getUserById(int userId) async {
    // NOTE: For Laravel version, user data is fetched from API
    throw app_exceptions.NotFoundException('User not found in local storage');
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    // NOTE: For Laravel version, user data is fetched from API
    return null;
  }

  @override
  Future<UserModel?> getUserByUsername(String username) async {
    // NOTE: For Laravel version, user data is fetched from API
    return null;
  }

  @override
  Future<void> updateLastLogin(int userId) async {
    // NOTE: For Laravel version, user data is managed by API
  }

  @override
  Future<void> updatePassword(int userId, String newPasswordHash) async {
    // NOTE: For Laravel version, password updates are handled by API
  }

  @override
  Future<String> createPasswordResetToken(int userId) async {
    // NOTE: For Laravel version, password reset tokens are handled by API
    return _generateToken();
  }

  @override
  Future<int> validatePasswordResetToken(String token) async {
    // NOTE: For Laravel version, password reset tokens are handled by API
    throw app_exceptions.ValidationException('Token validation not supported locally');
  }

  @override
  Future<void> markPasswordResetTokenAsUsed(String token) async {
    // NOTE: For Laravel version, password reset tokens are handled by API
  }

  @override
  String hashPassword(String password) {
    return _createPasswordHash(password);
  }
}


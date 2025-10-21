import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../../../../core/services/security_audit_service.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import 'auth_local_datasource.dart';

/// Implementation of [AuthLocalDataSource] using SQLite and secure storage
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final Database database;
  final FlutterSecureStorage secureStorage;
  final SecurityAuditService? securityAuditService;
  final Uuid _uuid = const Uuid();

  // Secure storage keys
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'username';
  static const String _keyEmail = 'email';

  AuthLocalDataSourceImpl({
    required this.database,
    required this.secureStorage,
    this.securityAuditService,
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
    try {
      // Check if account is locked due to too many failed attempts
      if (securityAuditService != null) {
        final isLocked = await securityAuditService!.isAccountLocked(email: email);
        if (isLocked) {
          final remainingTime = await securityAuditService!.getRemainingLockoutTime(email: email);
          final minutes = remainingTime?.inMinutes ?? 15;
          
          await securityAuditService!.logSecurityEvent(
            eventType: 'LOGIN_BLOCKED',
            description: 'Login attempt blocked due to account lockout for email: $email',
            severity: 'WARNING',
          );
          
          throw app_exceptions.AuthenticationException(
            'Account temporarily locked due to too many failed attempts. Please try again in $minutes minutes.'
          );
        }
      }

      // Query user by email (using parameterized query to prevent SQL injection)
      final results = await database.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (results.isEmpty) {
        // Record failed attempt
        if (securityAuditService != null) {
          await securityAuditService!.recordLoginAttempt(
            email: email,
            success: false,
            failureReason: 'User not found',
          );
        }
        throw app_exceptions.AuthenticationException('Invalid credentials');
      }

      final userMap = results.first;
      final storedHash = userMap['password_hash'] as String;

      // Verify password
      if (!_verifyPassword(password, storedHash)) {
        // Record failed attempt
        if (securityAuditService != null) {
          await securityAuditService!.recordLoginAttempt(
            email: email,
            success: false,
            failureReason: 'Invalid password',
          );
        }
        throw app_exceptions.AuthenticationException('Invalid credentials');
      }

      // Successful login - clear failed attempts and record success
      if (securityAuditService != null) {
        await securityAuditService!.clearFailedAttempts(email);
        await securityAuditService!.recordLoginAttempt(
          email: email,
          success: true,
        );
        await securityAuditService!.logSecurityEvent(
          userId: userMap['id'] as int,
          eventType: 'LOGIN_SUCCESS',
          description: 'User logged in successfully',
          severity: 'INFO',
        );
      }

      // Update last login
      await updateLastLogin(userMap['id'] as int);

      // Return user model
      return UserModel.fromMap(userMap);
    } catch (e) {
      if (e is app_exceptions.AuthenticationException) rethrow;
      throw app_exceptions.DatabaseException('Failed to login: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      // Check if email already exists (using parameterized query to prevent SQL injection)
      final emailExists = await database.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (emailExists.isNotEmpty) {
        if (securityAuditService != null) {
          await securityAuditService!.logSecurityEvent(
            eventType: 'REGISTRATION_FAILED',
            description: 'Registration attempt with existing email: $email',
            severity: 'INFO',
          );
        }
        throw app_exceptions.ValidationException('Email already exists');
      }

      // Check if username already exists (using parameterized query to prevent SQL injection)
      final usernameExists = await database.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (usernameExists.isNotEmpty) {
        if (securityAuditService != null) {
          await securityAuditService!.logSecurityEvent(
            eventType: 'REGISTRATION_FAILED',
            description: 'Registration attempt with existing username: $username',
            severity: 'INFO',
          );
        }
        throw app_exceptions.ValidationException('Username already exists');
      }

      // Hash password (never store plain text passwords)
      final passwordHash = _createPasswordHash(password);

      // Insert new user
      final now = DateTime.now().millisecondsSinceEpoch;
      final userId = await database.insert('users', {
        'username': username,
        'email': email,
        'password_hash': passwordHash,
        'created_at': now,
        'updated_at': now,
      });

      // Create fund box for new user
      await database.insert('fund_box', {
        'user_id': userId,
        'balance_usd': 0.0,
        'updated_at': now,
      });

      // Log successful registration
      if (securityAuditService != null) {
        await securityAuditService!.logSecurityEvent(
          userId: userId,
          eventType: 'REGISTRATION_SUCCESS',
          description: 'New user registered successfully',
          severity: 'INFO',
        );
      }

      // Query and return the created user
      final results = await database.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      return UserModel.fromMap(results.first);
    } catch (e) {
      if (e is app_exceptions.ValidationException) rethrow;
      throw app_exceptions.DatabaseException('Failed to register: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Get user ID before clearing auth data
      final userId = await secureStorage.read(key: _keyUserId);
      
      // Log logout event
      if (securityAuditService != null && userId != null) {
        await securityAuditService!.logSecurityEvent(
          userId: int.tryParse(userId),
          eventType: 'LOGOUT',
          description: 'User logged out',
          severity: 'INFO',
        );
      }
      
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
    try {
      final now = DateTime.now();
      final expiresAt = now.add(duration);

      final sessionId = await database.insert('sessions', {
        'user_id': userId,
        'token': token,
        'created_at': now.millisecondsSinceEpoch,
        'expires_at': expiresAt.millisecondsSinceEpoch,
        'last_activity': now.millisecondsSinceEpoch,
      });

      return SessionModel(
        id: sessionId,
        userId: userId,
        token: token,
        createdAt: now,
        expiresAt: expiresAt,
        lastActivity: now,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to create session: ${e.toString()}');
    }
  }

  @override
  Future<SessionModel?> getSessionByToken(String token) async {
    try {
      final results = await database.query(
        'sessions',
        where: 'token = ?',
        whereArgs: [token],
      );

      if (results.isEmpty) return null;

      return SessionModel.fromMap(results.first);
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get session: ${e.toString()}');
    }
  }

  @override
  Future<void> updateSessionActivity(String token) async {
    try {
      await database.update(
        'sessions',
        {'last_activity': DateTime.now().millisecondsSinceEpoch},
        where: 'token = ?',
        whereArgs: [token],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to update session activity: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteSession(String token) async {
    try {
      await database.delete(
        'sessions',
        where: 'token = ?',
        whereArgs: [token],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete session: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAllUserSessions(int userId) async {
    try {
      await database.delete(
        'sessions',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete user sessions: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> getUserById(int userId) async {
    try {
      final results = await database.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (results.isEmpty) {
        throw app_exceptions.NotFoundException('User not found');
      }

      return UserModel.fromMap(results.first);
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException('Failed to get user: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final results = await database.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (results.isEmpty) return null;

      return UserModel.fromMap(results.first);
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get user by email: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getUserByUsername(String username) async {
    try {
      final results = await database.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (results.isEmpty) return null;

      return UserModel.fromMap(results.first);
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get user by username: ${e.toString()}');
    }
  }

  @override
  Future<void> updateLastLogin(int userId) async {
    try {
      await database.update(
        'users',
        {
          'last_login': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to update last login: ${e.toString()}');
    }
  }

  @override
  Future<void> updatePassword(int userId, String newPasswordHash) async {
    try {
      await database.update(
        'users',
        {
          'password_hash': newPasswordHash,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      // Log password change
      if (securityAuditService != null) {
        await securityAuditService!.logSecurityEvent(
          userId: userId,
          eventType: 'PASSWORD_CHANGED',
          description: 'User password was changed',
          severity: 'WARNING',
        );
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to update password: ${e.toString()}');
    }
  }

  @override
  Future<String> createPasswordResetToken(int userId) async {
    try {
      final token = _generateToken();
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 1)); // Token valid for 1 hour

      await database.insert('password_reset_tokens', {
        'user_id': userId,
        'token': token,
        'created_at': now.millisecondsSinceEpoch,
        'expires_at': expiresAt.millisecondsSinceEpoch,
        'used': 0,
      });

      return token;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to create password reset token: ${e.toString()}');
    }
  }

  @override
  Future<int> validatePasswordResetToken(String token) async {
    try {
      final results = await database.query(
        'password_reset_tokens',
        where: 'token = ? AND used = 0',
        whereArgs: [token],
      );

      if (results.isEmpty) {
        throw app_exceptions.ValidationException('Invalid or already used token');
      }

      final tokenData = results.first;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        tokenData['expires_at'] as int,
      );

      if (DateTime.now().isAfter(expiresAt)) {
        throw app_exceptions.ValidationException('Token has expired');
      }

      return tokenData['user_id'] as int;
    } catch (e) {
      if (e is app_exceptions.ValidationException) rethrow;
      throw app_exceptions.DatabaseException('Failed to validate password reset token: ${e.toString()}');
    }
  }

  @override
  Future<void> markPasswordResetTokenAsUsed(String token) async {
    try {
      await database.update(
        'password_reset_tokens',
        {'used': 1},
        where: 'token = ?',
        whereArgs: [token],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to mark token as used: ${e.toString()}');
    }
  }

  @override
  String hashPassword(String password) {
    return _createPasswordHash(password);
  }
}


import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// Removed sqflite - using alternative storage
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';
import '../../features/auth/data/models/session_model.dart';
import '../error/exceptions.dart' as app_exceptions;

// Type alias for compatibility - this version doesn't use sqflite
typedef Database = dynamic;

/// Service for managing user sessions
/// Handles session creation, validation, refresh, and clearing
/// NOTE: This is a stub for Laravel version - sessions handled by backend
class SessionManager {
  final Database database;
  final FlutterSecureStorage secureStorage;
  final Duration sessionDuration;
  final Duration inactivityTimeout;

  SessionManager({
    required this.database,
    required this.secureStorage,
    Duration? sessionDuration,
    Duration? inactivityTimeout,
  })  : sessionDuration = sessionDuration ??
            const Duration(days: AppConstants.sessionDurationDays),
        inactivityTimeout = inactivityTimeout ??
            const Duration(minutes: AppConstants.inactivityTimeoutMinutes);

  /// Create a new session for a user
  /// Generates a unique token and stores it in the database and secure storage
  Future<SessionModel> createSession(int userId) async {
    try {
      // Generate unique session token
      final token = _generateSessionToken();
      final now = DateTime.now();
      final expiresAt = now.add(sessionDuration);

      // Create session in database
      final sessionId = await database.insert(
        'sessions',
        {
          'user_id': userId,
          'token': token,
          'created_at': now.millisecondsSinceEpoch,
          'expires_at': expiresAt.millisecondsSinceEpoch,
          'last_activity': now.millisecondsSinceEpoch,
        },
        // conflictAlgorithm: ConflictAlgorithm.replace, // Not available without sqflite
      );

      final session = SessionModel(
        id: sessionId,
        userId: userId,
        token: token,
        createdAt: now,
        expiresAt: expiresAt,
        lastActivity: now,
      );

      // Store token in secure storage
      await _cacheSessionToken(token);
      await _cacheUserId(userId);

      return session;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to create session: ${e.toString()}');
    }
  }

  /// Validate if a session is still valid
  /// Checks expiration time and inactivity timeout
  Future<bool> isSessionValid() async {
    try {
      final token = await getSessionToken();
      if (token == null) {
        return false;
      }

      final session = await _getSessionByToken(token);
      if (session == null) {
        return false;
      }

      // Check if session is expired
      if (session.isExpired) {
        await clearSession();
        return false;
      }

      // Check inactivity timeout
      final inactiveDuration = DateTime.now().difference(session.lastActivity);
      if (inactiveDuration > inactivityTimeout) {
        await clearSession();
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Refresh the session by updating last activity time
  /// Should be called on user interactions to prevent inactivity timeout
  Future<void> refreshSession() async {
    try {
      final token = await getSessionToken();
      if (token == null) {
        throw app_exceptions.AuthenticationException('No active session found');
      }

      final now = DateTime.now();
      await database.update(
        'sessions',
        {'last_activity': now.millisecondsSinceEpoch},
        where: 'token = ?',
        whereArgs: [token],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to refresh session: ${e.toString()}');
    }
  }

  /// Clear the current session
  /// Removes session from database and secure storage
  Future<void> clearSession() async {
    try {
      final token = await getSessionToken();
      if (token != null) {
        // Delete session from database
        await database.delete(
          'sessions',
          where: 'token = ?',
          whereArgs: [token],
        );
      }

      // Clear secure storage
      await secureStorage.delete(key: AppConstants.authTokenKey);
      await secureStorage.delete(key: AppConstants.userIdKey);
      await secureStorage.delete(key: AppConstants.lastActivityKey);
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to clear session: ${e.toString()}');
    }
  }

  /// Get the current session token from secure storage
  Future<String?> getSessionToken() async {
    try {
      return await secureStorage.read(key: AppConstants.authTokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Get the current user ID from secure storage
  Future<int?> getUserId() async {
    try {
      final userIdStr = await secureStorage.read(key: AppConstants.userIdKey);
      if (userIdStr == null) {
        return null;
      }
      return int.tryParse(userIdStr);
    } catch (e) {
      return null;
    }
  }

  /// Get the current session from the database
  Future<SessionModel?> getCurrentSession() async {
    try {
      final token = await getSessionToken();
      if (token == null) {
        return null;
      }
      return await _getSessionByToken(token);
    } catch (e) {
      return null;
    }
  }

  /// Clear all sessions for a specific user
  /// Useful when implementing single device login or logout from all devices
  Future<void> clearAllUserSessions(int userId) async {
    try {
      await database.delete(
        'sessions',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to clear user sessions: ${e.toString()}');
    }
  }

  /// Clean up expired sessions from the database
  /// Should be called periodically to maintain database hygiene
  Future<void> cleanupExpiredSessions() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await database.delete(
        'sessions',
        where: 'expires_at < ?',
        whereArgs: [now],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to cleanup expired sessions: ${e.toString()}');
    }
  }

  /// Extend the current session expiration time
  /// Useful for "remember me" functionality
  Future<void> extendSession({Duration? extension}) async {
    try {
      final token = await getSessionToken();
      if (token == null) {
        throw app_exceptions.AuthenticationException('No active session found');
      }

      final session = await _getSessionByToken(token);
      if (session == null) {
        throw app_exceptions.AuthenticationException('Session not found');
      }

      final extensionDuration = extension ?? sessionDuration;
      final newExpiresAt = DateTime.now().add(extensionDuration);

      await database.update(
        'sessions',
        {'expires_at': newExpiresAt.millisecondsSinceEpoch},
        where: 'token = ?',
        whereArgs: [token],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to extend session: ${e.toString()}');
    }
  }

  /// Check if user has an active session
  Future<bool> hasActiveSession() async {
    return await isSessionValid();
  }

  // ==================== Private Helper Methods ====================

  /// Generate a cryptographically secure session token
  String _generateSessionToken() {
    const uuid = Uuid();
    return uuid.v4();
  }

  /// Get session by token from database
  Future<SessionModel?> _getSessionByToken(String token) async {
    try {
      final results = await database.query(
        'sessions',
        where: 'token = ?',
        whereArgs: [token],
        limit: 1,
      );

      if (results.isEmpty) {
        return null;
      }

      return SessionModel.fromMap(results.first);
    } catch (e) {
      return null;
    }
  }

  /// Cache session token in secure storage
  Future<void> _cacheSessionToken(String token) async {
    await secureStorage.write(
      key: AppConstants.authTokenKey,
      value: token,
    );
  }

  /// Cache user ID in secure storage
  Future<void> _cacheUserId(int userId) async {
    await secureStorage.write(
      key: AppConstants.userIdKey,
      value: userId.toString(),
    );
  }
}

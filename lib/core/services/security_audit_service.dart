// Removed sqflite - using alternative storage

// Type alias for compatibility - this version doesn't use sqflite
typedef Database = dynamic;

/// Service for security auditing and monitoring
/// Tracks login attempts, failed authentications, and suspicious activities
/// NOTE: This is a stub for Laravel version - security auditing handled by backend
class SecurityAuditService {
  final Database database;

  SecurityAuditService({required this.database});

  /// Initialize security audit tables if they don't exist
  Future<void> initialize() async {
    await _createLoginAttemptsTable();
    await _createSecurityEventsTable();
  }

  /// Create login attempts tracking table
  Future<void> _createLoginAttemptsTable() async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS login_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        ip_address TEXT,
        success INTEGER NOT NULL,
        attempt_time INTEGER NOT NULL,
        failure_reason TEXT
      )
    ''');

    // Create index for faster lookups
    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_login_attempts_email_time 
      ON login_attempts(email, attempt_time)
    ''');
  }

  /// Create security events table for audit logging
  Future<void> _createSecurityEventsTable() async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS security_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        event_type TEXT NOT NULL,
        event_description TEXT NOT NULL,
        ip_address TEXT,
        event_time INTEGER NOT NULL,
        severity TEXT NOT NULL
      )
    ''');

    // Create index for faster lookups
    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_security_events_user_time 
      ON security_events(user_id, event_time)
    ''');
  }

  /// Record a login attempt
  Future<void> recordLoginAttempt({
    required String email,
    required bool success,
    String? ipAddress,
    String? failureReason,
  }) async {
    try {
      await database.insert('login_attempts', {
        'email': email,
        'ip_address': ipAddress,
        'success': success ? 1 : 0,
        'attempt_time': DateTime.now().millisecondsSinceEpoch,
        'failure_reason': failureReason,
      });
    } catch (e) {
      // Don't throw - logging should not break authentication flow
      print('Failed to record login attempt: $e');
    }
  }

  /// Get failed login attempts for an email within a time window
  Future<int> getFailedLoginAttempts({
    required String email,
    Duration timeWindow = const Duration(minutes: 15),
  }) async {
    try {
      final cutoffTime =
          DateTime.now().subtract(timeWindow).millisecondsSinceEpoch;

      final results = await database.rawQuery('''
        SELECT COUNT(*) as count 
        FROM login_attempts 
        WHERE email = ? 
        AND success = 0 
        AND attempt_time > ?
      ''', [email, cutoffTime]);

      return results.first['count'] as int;
    } catch (e) {
      return 0;
    }
  }

  /// Check if an account is locked due to too many failed attempts
  Future<bool> isAccountLocked({
    required String email,
    int maxAttempts = 5,
    Duration lockoutDuration = const Duration(minutes: 15),
  }) async {
    final failedAttempts = await getFailedLoginAttempts(
      email: email,
      timeWindow: lockoutDuration,
    );

    return failedAttempts >= maxAttempts;
  }

  /// Get remaining lockout time for an account
  Future<Duration?> getRemainingLockoutTime({
    required String email,
    int maxAttempts = 5,
    Duration lockoutDuration = const Duration(minutes: 15),
  }) async {
    try {
      final cutoffTime =
          DateTime.now().subtract(lockoutDuration).millisecondsSinceEpoch;

      final results = await database.rawQuery('''
        SELECT attempt_time 
        FROM login_attempts 
        WHERE email = ? 
        AND success = 0 
        AND attempt_time > ?
        ORDER BY attempt_time ASC
        LIMIT 1
      ''', [email, cutoffTime]);

      if (results.isEmpty) {
        return null;
      }

      final failedAttempts = await getFailedLoginAttempts(
        email: email,
        timeWindow: lockoutDuration,
      );

      if (failedAttempts < maxAttempts) {
        return null;
      }

      final firstAttemptTime =
          DateTime.fromMillisecondsSinceEpoch(results.first['attempt_time'] as int);
      final unlockTime = firstAttemptTime.add(lockoutDuration);
      final remaining = unlockTime.difference(DateTime.now());

      return remaining.isNegative ? null : remaining;
    } catch (e) {
      return null;
    }
  }

  /// Clear failed login attempts for an email (called after successful login)
  Future<void> clearFailedAttempts(String email) async {
    try {
      await database.delete(
        'login_attempts',
        where: 'email = ? AND success = 0',
        whereArgs: [email],
      );
    } catch (e) {
      // Don't throw - logging should not break authentication flow
      print('Failed to clear login attempts: $e');
    }
  }

  /// Log a security event
  Future<void> logSecurityEvent({
    int? userId,
    required String eventType,
    required String description,
    String? ipAddress,
    String severity = 'INFO',
  }) async {
    try {
      await database.insert('security_events', {
        'user_id': userId,
        'event_type': eventType,
        'event_description': description,
        'ip_address': ipAddress,
        'event_time': DateTime.now().millisecondsSinceEpoch,
        'severity': severity,
      });
    } catch (e) {
      // Don't throw - logging should not break application flow
      print('Failed to log security event: $e');
    }
  }

  /// Clean up old login attempts (older than 30 days)
  Future<void> cleanupOldLoginAttempts({
    Duration retentionPeriod = const Duration(days: 30),
  }) async {
    try {
      final cutoffTime =
          DateTime.now().subtract(retentionPeriod).millisecondsSinceEpoch;

      await database.delete(
        'login_attempts',
        where: 'attempt_time < ?',
        whereArgs: [cutoffTime],
      );
    } catch (e) {
      print('Failed to cleanup old login attempts: $e');
    }
  }

  /// Clean up old security events (older than 90 days)
  Future<void> cleanupOldSecurityEvents({
    Duration retentionPeriod = const Duration(days: 90),
  }) async {
    try {
      final cutoffTime =
          DateTime.now().subtract(retentionPeriod).millisecondsSinceEpoch;

      await database.delete(
        'security_events',
        where: 'event_time < ?',
        whereArgs: [cutoffTime],
      );
    } catch (e) {
      print('Failed to cleanup old security events: $e');
    }
  }

  /// Get recent security events for a user
  Future<List<Map<String, dynamic>>> getUserSecurityEvents({
    required int userId,
    int limit = 50,
  }) async {
    try {
      return await database.query(
        'security_events',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'event_time DESC',
        limit: limit,
      );
    } catch (e) {
      return [];
    }
  }

  /// Check for suspicious activity patterns
  Future<bool> detectSuspiciousActivity({
    required String email,
    Duration timeWindow = const Duration(minutes: 5),
    int threshold = 10,
  }) async {
    try {
      final cutoffTime =
          DateTime.now().subtract(timeWindow).millisecondsSinceEpoch;

      final results = await database.rawQuery('''
        SELECT COUNT(*) as count 
        FROM login_attempts 
        WHERE email = ? 
        AND attempt_time > ?
      ''', [email, cutoffTime]);

      final attemptCount = results.first['count'] as int;
      return attemptCount >= threshold;
    } catch (e) {
      return false;
    }
  }
}

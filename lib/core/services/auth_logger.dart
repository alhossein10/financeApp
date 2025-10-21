import 'package:flutter/foundation.dart';

/// Service for logging authentication and authorization events
class AuthLogger {
  static const String _tag = 'AuthLogger';

  /// Log an unauthorized access attempt
  static void logUnauthorizedAccess({
    required String operation,
    required int attemptedUserId,
    required int? resourceOwnerId,
    String? resourceType,
    int? resourceId,
    String? additionalInfo,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final message = '''
[$_tag] UNAUTHORIZED ACCESS ATTEMPT
Timestamp: $timestamp
Operation: $operation
Attempted by User ID: $attemptedUserId
Resource Owner ID: ${resourceOwnerId ?? 'N/A'}
Resource Type: ${resourceType ?? 'N/A'}
Resource ID: ${resourceId ?? 'N/A'}
Additional Info: ${additionalInfo ?? 'N/A'}
''';

    if (kDebugMode) {
      debugPrint(message);
    }

    // In production, you might want to send this to a logging service
    // or store it in a local database for security auditing
  }

  /// Log a successful authorization check
  static void logAuthorizedAccess({
    required String operation,
    required int userId,
    String? resourceType,
    int? resourceId,
  }) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('''
[$_tag] AUTHORIZED ACCESS
Timestamp: $timestamp
Operation: $operation
User ID: $userId
Resource Type: ${resourceType ?? 'N/A'}
Resource ID: ${resourceId ?? 'N/A'}
''');
    }
  }

  /// Log a validation failure
  static void logValidationFailure({
    required String operation,
    required int userId,
    required String validationError,
  }) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('''
[$_tag] VALIDATION FAILURE
Timestamp: $timestamp
Operation: $operation
User ID: $userId
Error: $validationError
''');
    }
  }

  /// Log a database operation failure
  static void logDatabaseError({
    required String operation,
    required int userId,
    required String error,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final message = '''
[$_tag] DATABASE ERROR
Timestamp: $timestamp
Operation: $operation
User ID: $userId
Error: $error
''';

    if (kDebugMode) {
      debugPrint(message);
    }

    // In production, you might want to send this to an error tracking service
  }
}

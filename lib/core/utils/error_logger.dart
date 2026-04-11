import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../error/failures.dart';

/// Error logger for debugging purposes
/// Implements requirement 29.8 - log all errors for debugging
class ErrorLogger {
  static const String _tag = 'ErrorLogger';

  /// Log an error with context
  static void logError(
    String context,
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final errorMessage = _formatError(error);
    final stackTraceStr = stackTrace?.toString() ?? 'No stack trace';

    // Log to console in debug mode
    if (kDebugMode) {
      developer.log(
        '[$timestamp] ERROR in $context: $errorMessage',
        name: _tag,
        error: error,
        stackTrace: stackTrace,
      );

      if (additionalData != null && additionalData.isNotEmpty) {
        developer.log(
          'Additional data: $additionalData',
          name: _tag,
        );
      }
    }

    // In production, you would send this to a logging service
    // Example: Firebase Crashlytics, Sentry, etc.
    _logToService(
      context: context,
      error: errorMessage,
      stackTrace: stackTraceStr,
      additionalData: additionalData,
      timestamp: timestamp,
    );
  }

  /// Log a failure
  static void logFailure(
    String context,
    Failure failure, {
    Map<String, dynamic>? additionalData,
  }) {
    logError(
      context,
      failure,
      additionalData: {
        'failureType': failure.runtimeType.toString(),
        'failureMessage': failure.message,
        ...?additionalData,
      },
    );
  }

  /// Log a network error
  static void logNetworkError(
    String endpoint,
    dynamic error, {
    int? statusCode,
    Map<String, dynamic>? requestData,
  }) {
    logError(
      'Network Request: $endpoint',
      error,
      additionalData: {
        'endpoint': endpoint,
        'statusCode': statusCode,
        'requestData': requestData,
      },
    );
  }

  /// Log a validation error
  static void logValidationError(
    String field,
    String errorMessage, {
    dynamic value,
  }) {
    logError(
      'Validation Error',
      errorMessage,
      additionalData: {
        'field': field,
        'value': value?.toString(),
      },
    );
  }

  /// Log an authentication error
  static void logAuthError(
    String operation,
    dynamic error, {
    String? userId,
  }) {
    logError(
      'Authentication: $operation',
      error,
      additionalData: {
        'operation': operation,
        'userId': userId,
      },
    );
  }

  /// Log a database error
  static void logDatabaseError(
    String operation,
    dynamic error, {
    String? table,
    Map<String, dynamic>? data,
  }) {
    logError(
      'Database: $operation',
      error,
      additionalData: {
        'operation': operation,
        'table': table,
        'data': data,
      },
    );
  }

  /// Format error message
  static String _formatError(dynamic error) {
    if (error is Failure) {
      return '${error.runtimeType}: ${error.message}';
    } else if (error is Exception) {
      return error.toString();
    } else if (error is Error) {
      return error.toString();
    } else {
      return error?.toString() ?? 'Unknown error';
    }
  }

  /// Log to external service (placeholder)
  static void _logToService({
    required String context,
    required String error,
    required String stackTrace,
    Map<String, dynamic>? additionalData,
    required String timestamp,
  }) {
    // In production, implement logging to external service
    // Example implementations:
    
    // Firebase Crashlytics:
    // FirebaseCrashlytics.instance.recordError(
    //   error,
    //   stackTrace,
    //   reason: context,
    //   information: additionalData?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
    // );

    // Sentry:
    // Sentry.captureException(
    //   error,
    //   stackTrace: stackTrace,
    //   hint: Hint.withMap({
    //     'context': context,
    //     ...?additionalData,
    //   }),
    // );

    // For now, just ensure it's logged in debug mode
    if (kDebugMode) {
      developer.log(
        'Would log to service: $context - $error',
        name: _tag,
      );
    }
  }

  /// Log a warning (non-critical)
  static void logWarning(
    String context,
    String message, {
    Map<String, dynamic>? additionalData,
  }) {
    final timestamp = DateTime.now().toIso8601String();

    if (kDebugMode) {
      developer.log(
        '[$timestamp] WARNING in $context: $message',
        name: _tag,
      );

      if (additionalData != null && additionalData.isNotEmpty) {
        developer.log(
          'Additional data: $additionalData',
          name: _tag,
        );
      }
    }
  }

  /// Log an info message
  static void logInfo(
    String context,
    String message, {
    Map<String, dynamic>? additionalData,
  }) {
    if (kDebugMode) {
      developer.log(
        'INFO in $context: $message',
        name: _tag,
      );

      if (additionalData != null && additionalData.isNotEmpty) {
        developer.log(
          'Additional data: $additionalData',
          name: _tag,
        );
      }
    }
  }
}

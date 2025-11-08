import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../config/api_config.dart';

/// API Logger for debugging and monitoring API requests/responses
/// 
/// This logger provides structured logging for API operations with
/// security considerations (never logs sensitive data like tokens or passwords).
class ApiLogger {
  // Private constructor to prevent instantiation
  ApiLogger._();

  /// Log levels
  static const String _levelInfo = 'INFO';
  static const String _levelWarning = 'WARNING';
  static const String _levelError = 'ERROR';
  static const String _levelDebug = 'DEBUG';

  /// Sensitive field names that should never be logged
  static const List<String> _sensitiveFields = [
    'password',
    'token',
    'authorization',
    'api_key',
    'apiKey',
    'secret',
    'access_token',
    'refresh_token',
    'bearer',
    'auth',
  ];

  /// Check if logging is enabled
  static bool get isEnabled => ApiConfig.enableRequestLogging;

  /// Log API request
  static void logRequest(RequestOptions options) {
    if (!isEnabled) return;

    final buffer = StringBuffer();
    buffer.writeln('┌─────────────────────────────────────────────────────');
    buffer.writeln('│ 📤 API REQUEST');
    buffer.writeln('├─────────────────────────────────────────────────────');
    buffer.writeln('│ Method: ${options.method}');
    buffer.writeln('│ URL: ${options.uri}');

    // Log headers (sanitized)
    if (options.headers.isNotEmpty) {
      buffer.writeln('│ Headers:');
      options.headers.forEach((key, value) {
        if (_isSensitiveField(key)) {
          buffer.writeln('│   $key: [REDACTED]');
        } else {
          buffer.writeln('│   $key: $value');
        }
      });
    }

    // Log query parameters
    if (options.queryParameters.isNotEmpty) {
      buffer.writeln('│ Query Parameters:');
      options.queryParameters.forEach((key, value) {
        buffer.writeln('│   $key: $value');
      });
    }

    // Log request body (sanitized)
    if (options.data != null) {
      buffer.writeln('│ Body:');
      final sanitizedData = _sanitizeData(options.data);
      buffer.writeln('│   $sanitizedData');
    }

    buffer.writeln('└─────────────────────────────────────────────────────');

    _log(buffer.toString(), level: _levelDebug);
  }

  /// Log API response
  static void logResponse(Response response) {
    if (!isEnabled) return;

    final buffer = StringBuffer();
    buffer.writeln('┌─────────────────────────────────────────────────────');
    buffer.writeln('│ 📥 API RESPONSE');
    buffer.writeln('├─────────────────────────────────────────────────────');
    buffer.writeln('│ Status Code: ${response.statusCode}');
    buffer.writeln('│ URL: ${response.requestOptions.uri}');
    buffer.writeln('│ Method: ${response.requestOptions.method}');

    // Log response headers
    if (response.headers.map.isNotEmpty) {
      buffer.writeln('│ Headers:');
      response.headers.map.forEach((key, value) {
        if (_isSensitiveField(key)) {
          buffer.writeln('│   $key: [REDACTED]');
        } else {
          buffer.writeln('│   $key: ${value.join(', ')}');
        }
      });
    }

    // Log response data (sanitized)
    if (response.data != null) {
      buffer.writeln('│ Response Data:');
      final sanitizedData = _sanitizeData(response.data);
      buffer.writeln('│   $sanitizedData');
    }

    buffer.writeln('└─────────────────────────────────────────────────────');

    _log(buffer.toString(), level: _levelDebug);
  }

  /// Log API error
  static void logError(
    DioException error, {
    StackTrace? stackTrace,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('┌─────────────────────────────────────────────────────');
    buffer.writeln('│ ❌ API ERROR');
    buffer.writeln('├─────────────────────────────────────────────────────');
    buffer.writeln('│ Type: ${error.type}');
    buffer.writeln('│ Message: ${error.message}');

    buffer.writeln('│ URL: ${error.requestOptions.uri}');
    buffer.writeln('│ Method: ${error.requestOptions.method}');
  
    if (error.response != null) {
      buffer.writeln('│ Status Code: ${error.response?.statusCode}');
      buffer.writeln('│ Response Data:');
      final sanitizedData = _sanitizeData(error.response?.data);
      buffer.writeln('│   $sanitizedData');
    }

    if (stackTrace != null && ApiConfig.enableDebugLogging) {
      buffer.writeln('│ Stack Trace:');
      final stackLines = stackTrace.toString().split('\n');
      for (var line in stackLines.take(5)) {
        // Only show first 5 lines
        buffer.writeln('│   $line');
      }
    }

    buffer.writeln('└─────────────────────────────────────────────────────');

    _log(buffer.toString(), level: _levelError, error: error, stackTrace: stackTrace);
  }

  /// Log general information
  static void logInfo(String message) {
    if (!isEnabled) return;
    _log('ℹ️ $message', level: _levelInfo);
  }

  /// Log warning
  static void logWarning(String message) {
    if (!isEnabled) return;
    _log('⚠️ $message', level: _levelWarning);
  }

  /// Log debug message
  static void logDebug(String message) {
    if (!isEnabled) return;
    _log('🔍 $message', level: _levelDebug);
  }

  /// Log retry attempt
  static void logRetry(RequestOptions options, int attemptNumber, Duration delay) {
    if (!isEnabled) return;

    final buffer = StringBuffer();
    buffer.writeln('┌─────────────────────────────────────────────────────');
    buffer.writeln('│ 🔄 RETRY ATTEMPT #$attemptNumber');
    buffer.writeln('├─────────────────────────────────────────────────────');
    buffer.writeln('│ URL: ${options.uri}');
    buffer.writeln('│ Method: ${options.method}');
    buffer.writeln('│ Delay: ${delay.inMilliseconds}ms');
    buffer.writeln('└─────────────────────────────────────────────────────');

    _log(buffer.toString(), level: _levelWarning);
  }

  /// Internal logging method
  static void _log(
    String message, {
    required String level,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Use developer.log for better debugging in Flutter DevTools
    developer.log(
      message,
      name: 'ApiLogger',
      level: _getLogLevel(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Get numeric log level for developer.log
  static int _getLogLevel(String level) {
    switch (level) {
      case _levelDebug:
        return 500;
      case _levelInfo:
        return 800;
      case _levelWarning:
        return 900;
      case _levelError:
        return 1000;
      default:
        return 800;
    }
  }

  /// Check if a field name is sensitive
  static bool _isSensitiveField(String fieldName) {
    final lowerFieldName = fieldName.toLowerCase();
    return _sensitiveFields.any((sensitive) => 
      lowerFieldName.contains(sensitive.toLowerCase())
    );
  }

  /// Sanitize data by removing sensitive fields
  static dynamic _sanitizeData(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      final sanitized = <String, dynamic>{};
      data.forEach((key, value) {
        if (_isSensitiveField(key.toString())) {
          sanitized[key] = '[REDACTED]';
        } else if (value is Map || value is List) {
          sanitized[key] = _sanitizeData(value);
        } else {
          sanitized[key] = value;
        }
      });
      return sanitized;
    } else if (data is List) {
      return data.map((item) => _sanitizeData(item)).toList();
    }

    return data;
  }

  /// Format duration for logging
  static String formatDuration(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}ms';
    } else if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
  }

  /// Log performance metrics
  static void logPerformance(
    String endpoint,
    Duration duration,
    int statusCode,
  ) {
    if (!isEnabled) return;

    final buffer = StringBuffer();
    buffer.writeln('┌─────────────────────────────────────────────────────');
    buffer.writeln('│ ⏱️ PERFORMANCE METRICS');
    buffer.writeln('├─────────────────────────────────────────────────────');
    buffer.writeln('│ Endpoint: $endpoint');
    buffer.writeln('│ Duration: ${formatDuration(duration)}');
    buffer.writeln('│ Status: $statusCode');
    buffer.writeln('└─────────────────────────────────────────────────────');

    _log(buffer.toString(), level: _levelInfo);
  }

  /// Log cache hit/miss
  static void logCache(String key, bool hit) {
    if (!isEnabled) return;
    final status = hit ? '✅ HIT' : '❌ MISS';
    _log('💾 Cache $status: $key', level: _levelDebug);
  }

  /// Log queue operation
  static void logQueue(String operation, String resourceType, {String? id}) {
    if (!isEnabled) return;
    final idStr = id != null ? ' (ID: $id)' : '';
    _log('📋 Queue $operation: $resourceType$idStr', level: _levelInfo);
  }

  /// Log authentication event
  static void logAuth(String event) {
    if (!isEnabled) return;
    _log('🔐 Auth: $event', level: _levelInfo);
  }

  /// Log sync operation
  static void logSync(String operation, {int? count}) {
    if (!isEnabled) return;
    final countStr = count != null ? ' ($count items)' : '';
    _log('🔄 Sync: $operation$countStr', level: _levelInfo);
  }
}

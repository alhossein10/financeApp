import 'package:flutter/foundation.dart';

/// Secure logging utility that prevents sensitive data from being logged in production.
/// Only logs in debug mode (kDebugMode).
class SecureLogger {
  static const String _tag = '[SecureLogger]';

  /// Log a debug message (only in debug mode)
  static void debug(String tag, String message) {
    if (kDebugMode) {
      print('🔵 [$tag] $message');
    }
  }

  /// Log a success message (only in debug mode)
  static void success(String tag, String message) {
    if (kDebugMode) {
      print('✅ [$tag] $message');
    }
  }

  /// Log a warning message (only in debug mode)
  static void warning(String tag, String message) {
    if (kDebugMode) {
      print('⚠️ [$tag] $message');
    }
  }

  /// Log an error message (only in debug mode)
  /// Errors are logged with sanitized data
  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('🔴 [$tag] $message');
      if (error != null) {
        print('🔴 [$tag] Error: ${_sanitizeError(error.toString())}');
      }
      if (stackTrace != null) {
        print('🔴 [$tag] Stack trace: $stackTrace');
      }
    }
  }

  /// Log an info message (only in debug mode)
  static void info(String tag, String message) {
    if (kDebugMode) {
      print('🟢 [$tag] $message');
    }
  }

  /// Log a network request (sanitized - only in debug mode)
  static void request(String tag, String method, String endpoint) {
    if (kDebugMode) {
      print('🔵 [$tag] $method $endpoint');
    }
  }

  /// Log a network response (sanitized - only in debug mode)
  static void response(String tag, int? statusCode) {
    if (kDebugMode) {
      print('🟢 [$tag] Response: $statusCode');
    }
  }

  /// Log authentication event without sensitive data
  static void authEvent(String event) {
    if (kDebugMode) {
      print('🔐 [AUTH] $event');
    }
  }

  /// Sanitize error messages to remove potentially sensitive data
  static String _sanitizeError(String error) {
    // Remove potential email addresses
    error = error.replaceAll(RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'), '[EMAIL]');
    // Remove potential tokens (long alphanumeric strings)
    error = error.replaceAll(RegExp(r'\b[a-zA-Z0-9]{32,}\b'), '[TOKEN]');
    // Remove potential passwords in JSON
    error = error.replaceAll(RegExp(r'"password"\s*:\s*"[^"]*"'), '"password": "[REDACTED]"');
    error = error.replaceAll(RegExp(r'"password_confirmation"\s*:\s*"[^"]*"'), '"password_confirmation": "[REDACTED]"');
    // Remove potential group codes (4-6 digit numbers)
    error = error.replaceAll(RegExp(r'"group_code"\s*:\s*"?\d{4,6}"?'), '"group_code": "[REDACTED]"');
    return error;
  }

  /// Mask sensitive strings (e.g., tokens, emails)
  static String mask(String? value, {int visibleChars = 4}) {
    if (value == null || value.isEmpty) return '[EMPTY]';
    if (value.length <= visibleChars * 2) return '***';
    return '${value.substring(0, visibleChars)}...${value.substring(value.length - visibleChars)}';
  }

  /// Mask email address
  static String maskEmail(String? email) {
    if (email == null || email.isEmpty) return '[EMPTY]';
    final parts = email.split('@');
    if (parts.length != 2) return '***@***';
    final name = parts[0];
    final domain = parts[1];
    final maskedName = name.length > 2
        ? '${name.substring(0, 2)}***'
        : '***';
    return '$maskedName@$domain';
  }
}

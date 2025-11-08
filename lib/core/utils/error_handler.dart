import '../error/failures.dart';

/// Enhanced error handler for BLoCs
/// 
/// Provides consistent error handling across all BLoCs with support for:
/// - 401 handling with automatic logout requirement
/// - 403 handling with access denied messages
/// - 422 handling with field-specific errors
/// - 429 rate limit handling
/// - User-friendly error messages
class ErrorHandler {
  /// Convert a Failure to a user-friendly error message
  static String getErrorMessage(Failure failure) {
    if (failure is ApiFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'No internet connection. Please check your network.';
    } else if (failure is UnauthorizedFailure) {
      return 'Session expired. Please login again.';
    } else if (failure is DatabaseFailure) {
      return failure.message;
    } else if (failure is ValidationFailure) {
      return failure.message;
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Check if the failure requires logout (401 Unauthorized)
  static bool requiresLogout(Failure failure) {
    return failure is UnauthorizedFailure || 
           failure.message.contains('401') ||
           failure.message.toLowerCase().contains('unauthorized');
  }

  /// Check if the failure is a forbidden error (403)
  static bool isForbidden(Failure failure) {
    return failure.message.contains('403') ||
           failure.message.toLowerCase().contains('forbidden');
  }

  /// Check if the failure is a validation error (422)
  static bool isValidationError(Failure failure) {
    return failure is ValidationFailure ||
           failure.message.contains('422') ||
           failure.message.toLowerCase().contains('validation');
  }

  /// Check if the failure is a rate limit error (429)
  static bool isRateLimited(Failure failure) {
    return failure.message.contains('429') ||
           failure.message.toLowerCase().contains('rate limit');
  }

  /// Get formatted validation errors for 422 responses
  static String getFormattedValidationErrors(Failure failure) {
    return getErrorMessage(failure);
  }

  /// Get retry after duration for rate limit errors (429)
  static Duration? getRetryAfterDuration(Failure failure) {
    return null;
  }

  /// Create an enhanced error result with additional metadata
  static EnhancedErrorResult createEnhancedError(Failure failure) {
    return EnhancedErrorResult(
      message: getErrorMessage(failure),
      requiresLogout: requiresLogout(failure),
      isForbidden: isForbidden(failure),
      isValidationError: isValidationError(failure),
      isRateLimited: isRateLimited(failure),
      formattedValidationErrors: isValidationError(failure) 
          ? getFormattedValidationErrors(failure) 
          : null,
      retryAfterDuration: getRetryAfterDuration(failure),
      originalFailure: failure,
    );
  }
}

/// Enhanced error result with metadata
class EnhancedErrorResult {
  final String message;
  final bool requiresLogout;
  final bool isForbidden;
  final bool isValidationError;
  final bool isRateLimited;
  final String? formattedValidationErrors;
  final Duration? retryAfterDuration;
  final Failure originalFailure;

  const EnhancedErrorResult({
    required this.message,
    required this.requiresLogout,
    required this.isForbidden,
    required this.isValidationError,
    required this.isRateLimited,
    this.formattedValidationErrors,
    this.retryAfterDuration,
    required this.originalFailure,
  });

  /// Get display message (uses formatted validation errors if available)
  String get displayMessage => formattedValidationErrors ?? message;

  /// Get retry message for rate limit errors
  String? get retryMessage {
    if (isRateLimited && retryAfterDuration != null) {
      final seconds = retryAfterDuration!.inSeconds;
      return 'Please try again in $seconds seconds.';
    }
    return null;
  }
}

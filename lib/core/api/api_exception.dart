import 'package:dio/dio.dart';

/// Base API Exception class for all API-related errors
/// 
/// This exception provides structured error handling for HTTP responses
/// and network errors, with user-friendly error messages.
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, dynamic>? errors;
  final dynamic originalError;
  final StackTrace? stackTrace;

  ApiException({
    this.statusCode,
    required this.message,
    this.errors,
    this.originalError,
    this.stackTrace,
  });

  /// Check if this is an authentication error (401)
  bool get isAuthError => statusCode == 401;
  
  /// Alias for isAuthError
  bool get isUnauthorized => statusCode == 401;

  /// Check if this is a forbidden error (403)
  bool get isForbiddenError => statusCode == 403;
  
  /// Alias for isForbiddenError
  bool get isForbidden => statusCode == 403;

  /// Check if this is a not found error (404)
  bool get isNotFoundError => statusCode == 404;
  
  /// Alias for isNotFoundError
  bool get isNotFound => statusCode == 404;

  /// Check if this is a validation error (422)
  bool get isValidationError => statusCode == 422;

  /// Check if this is a rate limit error (429)
  bool get isRateLimited => statusCode == 429;

  /// Check if this is a server error (5xx)
  bool get isServerError => statusCode != null && statusCode! >= 500;

  /// Check if this is a network error (no status code)
  bool get isNetworkError => statusCode == null;
  
  /// Check if this is a bad request error (400)
  bool get isBadRequest => statusCode == 400;

  @override
  String toString() {
    return 'ApiException(statusCode: $statusCode, message: $message, errors: $errors)';
  }

  /// Factory constructor to create ApiException from DioException
  factory ApiException.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return ConnectionTimeoutException(
          originalError: dioException,
          stackTrace: dioException.stackTrace,
        );

      case DioExceptionType.sendTimeout:
        return SendTimeoutException(
          originalError: dioException,
          stackTrace: dioException.stackTrace,
        );

      case DioExceptionType.receiveTimeout:
        return ReceiveTimeoutException(
          originalError: dioException,
          stackTrace: dioException.stackTrace,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(dioException);

      case DioExceptionType.cancel:
        return RequestCancelledException(
          originalError: dioException,
          stackTrace: dioException.stackTrace,
        );

      case DioExceptionType.connectionError:
        return NoInternetException(
          originalError: dioException,
          stackTrace: dioException.stackTrace,
        );

      case DioExceptionType.badCertificate:
        return BadCertificateException(
          originalError: dioException,
          stackTrace: dioException.stackTrace,
        );

      case DioExceptionType.unknown:
      default:
        return UnknownApiException(
          message: dioException.message ?? 'An unknown error occurred',
          originalError: dioException,
          stackTrace: dioException.stackTrace,
        );
    }
  }

  /// Handle bad response (4xx, 5xx status codes)
  static ApiException _handleBadResponse(DioException dioException) {
    final response = dioException.response;
    final statusCode = response?.statusCode;
    final data = response?.data;

    // Extract error message and validation errors from response
    String message = 'An error occurred';
    Map<String, dynamic>? errors;

    if (data is Map<String, dynamic>) {
      message = data['message'] ?? data['error'] ?? message;
      errors = data['errors'] as Map<String, dynamic>?;
    } else if (data is String) {
      message = data;
    }

    switch (statusCode) {
      case 400:
        return BadRequestException(
          message: message,
          errors: errors,
          originalError: dioException,
          stackTrace: dioException.stackTrace,
        );

      case 401:
        return UnauthorizedException(
          message: message,
          originalError: dioException,
          stackTrace: dioException.stackTrace,
        );

      case 403:
        return ForbiddenException(
          message: message,
          originalError: dioException,
          stackTrace: dioException.stackTrace,
        );

      case 404:
        return NotFoundException(
          message: message,
          originalError: dioException,
          stackTrace: dioException.stackTrace,
        );

      case 422:
        return ValidationException(
          message: message,
          errors: errors,
          originalError: dioException,
          stackTrace: dioException.stackTrace,
        );

      case 429:
        final retryAfter = response?.headers.value('retry-after');
        return RateLimitException(
          message: message,
          retryAfter: retryAfter != null ? int.tryParse(retryAfter) : null,
          originalError: dioException,
          stackTrace: dioException.stackTrace,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(
          statusCode: statusCode!,
          message: message,
          originalError: dioException,
          stackTrace: dioException.stackTrace,
        );

      default:
        return ApiException(
          statusCode: statusCode,
          message: message,
          errors: errors,
          originalError: dioException,
          stackTrace: dioException.stackTrace,
        );
    }
  }

  /// Get user-friendly error message with comprehensive error code handling
  String get userFriendlyMessage {
    // Handle specific status codes
    switch (statusCode) {
      case 400:
        return _formatValidationErrors() ?? 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'Access denied. You don\'t have permission for this action.';
      case 404:
        return 'Resource not found.';
      case 422:
        return _formatValidationErrors() ?? 'Validation failed. Please check your input.';
      case 429:
        final retryMsg = this is RateLimitException && (this as RateLimitException).retryAfter != null
            ? ' Please try again in ${(this as RateLimitException).retryAfter} seconds.'
            : ' Please try again later.';
        return 'Too many requests.$retryMsg';
      case 500:
        return 'Internal server error. Please try again later.';
      case 502:
        return 'Bad gateway. The server is temporarily unavailable.';
      case 503:
        return 'Service unavailable. Please try again later.';
      case 504:
        return 'Gateway timeout. The server took too long to respond.';
      default:
        if (isServerError) {
          return 'Server error. Please try again later.';
        } else if (isNetworkError) {
          return 'No internet connection. Please check your network.';
        }
        return message;
    }
  }
  
  /// Format validation errors into a user-friendly string
  String? _formatValidationErrors() {
    if (errors == null || errors!.isEmpty) return null;
    
    final errorMessages = <String>[];
    errors!.forEach((field, messages) {
      if (messages is List) {
        errorMessages.addAll(messages.cast<String>());
      } else if (messages is String) {
        errorMessages.add(messages);
      }
    });
    
    return errorMessages.isNotEmpty ? errorMessages.join('\n') : null;
  }
  
  /// Get validation errors as a formatted string with field names
  String getFormattedValidationErrors() {
    if (errors == null || errors!.isEmpty) return message;
    
    final errorMessages = <String>[];
    errors!.forEach((field, messages) {
      if (messages is List) {
        for (var msg in messages) {
          errorMessages.add('• $field: $msg');
        }
      } else if (messages is String) {
        errorMessages.add('• $field: $messages');
      }
    });
    
    return errorMessages.isNotEmpty ? errorMessages.join('\n') : message;
  }
  
  /// Legacy method for backward compatibility
  @Deprecated('Use userFriendlyMessage getter instead')
  String getUserFriendlyMessage() => userFriendlyMessage;
}

/// 400 Bad Request
class BadRequestException extends ApiException {
  BadRequestException({
    super.message = 'Bad request',
    super.errors,
    super.originalError,
    super.stackTrace,
  }) : super(
          statusCode: 400,
        );
}

/// 401 Unauthorized
class UnauthorizedException extends ApiException {
  UnauthorizedException({
    super.message = 'Unauthorized. Please log in.',
    super.originalError,
    super.stackTrace,
  }) : super(
          statusCode: 401,
        );
}

/// 403 Forbidden
class ForbiddenException extends ApiException {
  ForbiddenException({
    super.message = 'Access denied. Insufficient permissions.',
    super.originalError,
    super.stackTrace,
  }) : super(
          statusCode: 403,
        );
}

/// 404 Not Found
class NotFoundException extends ApiException {
  NotFoundException({
    super.message = 'Resource not found',
    super.originalError,
    super.stackTrace,
  }) : super(
          statusCode: 404,
        );
}

/// 422 Validation Error
class ValidationException extends ApiException {
  ValidationException({
    super.message = 'Validation failed',
    super.errors,
    super.originalError,
    super.stackTrace,
  }) : super(
          statusCode: 422,
        );

  /// Get validation errors as a list of strings
  List<String> getValidationErrors() {
    if (errors == null) return [message];

    final errorMessages = <String>[];
    errors!.forEach((field, messages) {
      if (messages is List) {
        errorMessages.addAll(messages.map((m) => '$field: $m'));
      } else {
        errorMessages.add('$field: $messages');
      }
    });

    return errorMessages;
  }
}

/// 429 Rate Limit Exceeded
class RateLimitException extends ApiException {
  final int? retryAfter; // seconds to wait before retrying

  RateLimitException({
    super.message = 'Too many requests. Please try again later.',
    this.retryAfter,
    super.originalError,
    super.stackTrace,
  }) : super(
          statusCode: 429,
        );

  /// Get retry after duration
  Duration? getRetryAfterDuration() {
    return retryAfter != null ? Duration(seconds: retryAfter!) : null;
  }
}

/// 5xx Server Error
class ServerException extends ApiException {
  ServerException({
    required int super.statusCode,
    super.message = 'Server error. Please try again later.',
    super.originalError,
    super.stackTrace,
  });
}

/// Connection Timeout
class ConnectionTimeoutException extends ApiException {
  ConnectionTimeoutException({
    super.message = 'Connection timeout. Please check your internet connection.',
    super.originalError,
    super.stackTrace,
  });
}

/// Send Timeout
class SendTimeoutException extends ApiException {
  SendTimeoutException({
    super.message = 'Request timeout. Please try again.',
    super.originalError,
    super.stackTrace,
  });
}

/// Receive Timeout
class ReceiveTimeoutException extends ApiException {
  ReceiveTimeoutException({
    super.message = 'Response timeout. Please try again.',
    super.originalError,
    super.stackTrace,
  });
}

/// Request Cancelled
class RequestCancelledException extends ApiException {
  RequestCancelledException({
    super.message = 'Request was cancelled',
    super.originalError,
    super.stackTrace,
  });
}

/// No Internet Connection
class NoInternetException extends ApiException {
  NoInternetException({
    super.message = 'No internet connection. Please check your network.',
    super.originalError,
    super.stackTrace,
  });
}

/// Bad Certificate (SSL/TLS Error)
class BadCertificateException extends ApiException {
  BadCertificateException({
    super.message = 'Security certificate error. Connection refused.',
    super.originalError,
    super.stackTrace,
  });
}

/// Unknown Error
class UnknownApiException extends ApiException {
  UnknownApiException({
    super.message = 'An unknown error occurred',
    super.originalError,
    super.stackTrace,
  });
}

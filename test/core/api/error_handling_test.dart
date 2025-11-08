import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_exception.dart';

void main() {
  group('Error Handling Tests', () {
    group('400 Bad Request', () {
      test('should create BadRequestException from 400 response', () {
        // Arrange
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
            data: {'message': 'Bad request'},
          ),
          type: DioExceptionType.badResponse,
        );

        // Act
        final exception = ApiException.fromDioException(dioException);

        // Assert
        expect(exception, isA<BadRequestException>());
        expect(exception.statusCode, 400);
        expect(exception.getUserFriendlyMessage(), contains('Invalid request'));
      });

      test('should handle 400 with validation errors', () {
        // Arrange
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
            data: {
              'message': 'Validation failed',
              'errors': {
                'field1': ['Error 1'],
                'field2': ['Error 2'],
              },
            },
          ),
          type: DioExceptionType.badResponse,
        );

        // Act
        final exception = ApiException.fromDioException(dioException);

        // Assert
        expect(exception.statusCode, 400);
        expect(exception.errors, isNotNull);
      });
    });

    group('401 Unauthorized', () {
      test('should create UnauthorizedException from 401 response', () {
        // Arrange
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 401,
            data: {'message': 'Unauthorized'},
          ),
          type: DioExceptionType.badResponse,
        );

        // Act
        final exception = ApiException.fromDioException(dioException);

        // Assert
        expect(exception, isA<UnauthorizedException>());
        expect(exception.statusCode, 401);
        expect(exception.isAuthError, true);
        expect(exception.getUserFriendlyMessage(), contains('session has expired'));
      });

      test('should indicate authentication is required', () {
        // Arrange
        final exception = UnauthorizedException();

        // Assert
        expect(exception.isAuthError, true);
        expect(exception.requiresReauthentication, true);
      });
    });

    group('403 Forbidden', () {
      test('should create ForbiddenException from 403 response', () {
        // Arrange
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/admin'),
          response: Response(
            requestOptions: RequestOptions(path: '/admin'),
            statusCode: 403,
            data: {'message': 'Access denied'},
          ),
          type: DioExceptionType.badResponse,
        );

        // Act
        final exception = ApiException.fromDioException(dioException);

        // Assert
        expect(exception, isA<ForbiddenException>());
        expect(exception.statusCode, 403);
        expect(exception.isForbiddenError, true);
        expect(exception.getUserFriendlyMessage(), contains('do not have permission'));
      });

      test('should indicate insufficient permissions', () {
        // Arrange
        final exception = ForbiddenException();

        // Assert
        expect(exception.isForbiddenError, true);
        expect(exception.getUserFriendlyMessage(), contains('permission'));
      });
    });

    group('404 Not Found', () {
      test('should create NotFoundException from 404 response', () {
        // Arrange
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/users/999'),
          response: Response(
            requestOptions: RequestOptions(path: '/users/999'),
            statusCode: 404,
            data: {'message': 'User not found'},
          ),
          type: DioExceptionType.badResponse,
        );

        // Act
        final exception = ApiException.fromDioException(dioException);

        // Assert
        expect(exception, isA<NotFoundException>());
        expect(exception.statusCode, 404);
        expect(exception.isNotFoundError, true);
        expect(exception.getUserFriendlyMessage(), contains('not found'));
      });
    });

    group('422 Unprocessable Entity', () {
      test('should create ValidationException from 422 response', () {
        // Arrange
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/users'),
          response: Response(
            requestOptions: RequestOptions(path: '/users'),
            statusCode: 422,
            data: {
              'message': 'Validation failed',
              'errors': {
                'email': ['Email is required', 'Email must be valid'],
                'password': ['Password must be at least 8 characters'],
              },
            },
          ),
          type: DioExceptionType.badResponse,
        );

        // Act
        final exception = ApiException.fromDioException(dioException);

        // Assert
        expect(exception, isA<ValidationException>());
        expect(exception.statusCode, 422);
        expect(exception.isValidationError, true);
        expect(exception.errors, isNotNull);
        expect(exception.errors!['email'], isNotNull);
        expect(exception.errors!['password'], isNotNull);
      });

      test('should format validation errors for display', () {
        // Arrange
        final exception = ValidationException(
          errors: {
            'email': ['Email is required'],
            'password': ['Password must be at least 8 characters'],
          },
        );

        // Act
        final message = exception.getUserFriendlyMessage();

        // Assert
        expect(message, contains('Email is required'));
        expect(message, contains('Password must be at least 8 characters'));
      });

      test('should handle single validation error', () {
        // Arrange
        final exception = ValidationException(
          errors: {
            'email': ['Email is required'],
          },
        );

        // Act
        final message = exception.getUserFriendlyMessage();

        // Assert
        expect(message, contains('Email is required'));
      });

      test('should handle empty validation errors', () {
        // Arrange
        final exception = ValidationException(errors: {});

        // Act
        final message = exception.getUserFriendlyMessage();

        // Assert
        expect(message, contains('check your input'));
      });
    });

    group('429 Too Many Requests', () {
      test('should create RateLimitException from 429 response', () {
        // Arrange
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 429,
            data: {'message': 'Too many requests'},
            headers: Headers.fromMap({
              'retry-after': ['60'],
            }),
          ),
          type: DioExceptionType.badResponse,
        );

        // Act
        final exception = ApiException.fromDioException(dioException);

        // Assert
        expect(exception, isA<RateLimitException>());
        expect(exception.statusCode, 429);
        expect(exception.isRateLimited, true);
        final rateLimitException = exception as RateLimitException;
        expect(rateLimitException.retryAfter, 60);
      });

      test('should handle missing retry-after header', () {
        // Arrange
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 429,
            data: {'message': 'Too many requests'},
          ),
          type: DioExceptionType.badResponse,
        );

        // Act
        final exception = ApiException.fromDioException(dioException);

        // Assert
        expect(exception, isA<RateLimitException>());
        final rateLimitException = exception as RateLimitException;
        expect(rateLimitException.retryAfter, isNull);
      });

      test('should provide user-friendly rate limit message', () {
        // Arrange
        final exception = RateLimitException(retryAfter: 60);

        // Act
        final message = exception.getUserFriendlyMessage();

        // Assert
        expect(message, contains('Too many requests'));
        expect(message, contains('try again later'));
      });
    });

    group('500 Internal Server Error', () {
      test('should create ServerException from 500 response', () {
        // Arrange
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 500,
            data: {'message': 'Internal server error'},
          ),
          type: DioExceptionType.badResponse,
        );

        // Act
        final exception = ApiException.fromDioException(dioException);

        // Assert
        expect(exception, isA<ServerException>());
        expect(exception.statusCode, 500);
        expect(exception.isServerError, true);
        expect(exception.getUserFriendlyMessage(), contains('Server error'));
      });

      test('should handle 502 Bad Gateway', () {
        // Arrange
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 502,
            data: {'message': 'Bad gateway'},
          ),
          type: DioExceptionType.badResponse,
        );

        // Act
        final exception = ApiException.fromDioException(dioException);

        // Assert
        expect(exception, isA<ServerException>());
        expect(exception.statusCode, 502);
        expect(exception.isServerError, true);
      });

      test('should handle 503 Service Unavailable', () {
        // Arrange
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 503,
            data: {'message': 'Service unavailable'},
          ),
          type: DioExceptionType.badResponse,
        );

        // Act
        final exception = ApiException.fromDioException(dioException);

        // Assert
        expect(exception, isA<ServerException>());
        expect(exception.statusCode, 503);
        expect(exception.isServerError, true);
      });
    });

    group('Network Errors', () {
      test('should create ConnectionTimeoutException from timeout', () {
        // Arrange
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        );

        // Act
        final exception = ApiException.fromDioException(dioException);

        // Assert
        expect(exception, isA<ConnectionTimeoutException>());
        expect(exception.isNetworkError, true);
        expect(exception.getUserFriendlyMessage(), contains('connection timed out'));
      });

      test('should create NoInternetException from connection error', () {
        // Arrange
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
        );

        // Act
        final exception = ApiException.fromDioException(dioException);

        // Assert
        expect(exception, isA<NoInternetException>());
        expect(exception.isNetworkError, true);
        expect(exception.getUserFriendlyMessage(), contains('No internet connection'));
      });

      test('should handle receive timeout', () {
        // Arrange
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.receiveTimeout,
        );

        // Act
        final exception = ApiException.fromDioException(dioException);

        // Assert
        expect(exception.isNetworkError, true);
        expect(exception.getUserFriendlyMessage(), contains('timed out'));
      });

      test('should handle send timeout', () {
        // Arrange
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.sendTimeout,
        );

        // Act
        final exception = ApiException.fromDioException(dioException);

        // Assert
        expect(exception.isNetworkError, true);
        expect(exception.getUserFriendlyMessage(), contains('timed out'));
      });
    });

    group('Error Properties', () {
      test('should correctly identify auth errors', () {
        final authException = UnauthorizedException();
        expect(authException.isAuthError, true);
        expect(authException.isForbiddenError, false);
        expect(authException.isValidationError, false);
        expect(authException.isServerError, false);
        expect(authException.isNetworkError, false);
      });

      test('should correctly identify forbidden errors', () {
        final forbiddenException = ForbiddenException();
        expect(forbiddenException.isForbiddenError, true);
        expect(forbiddenException.isAuthError, false);
        expect(forbiddenException.isValidationError, false);
      });

      test('should correctly identify validation errors', () {
        final validationException = ValidationException();
        expect(validationException.isValidationError, true);
        expect(validationException.isAuthError, false);
        expect(validationException.isForbiddenError, false);
        expect(validationException.isServerError, false);
      });

      test('should correctly identify server errors', () {
        final serverException = ServerException(statusCode: 500);
        expect(serverException.isServerError, true);
        expect(serverException.isAuthError, false);
        expect(serverException.isValidationError, false);
        expect(serverException.isNetworkError, false);
      });

      test('should correctly identify network errors', () {
        final networkException = NoInternetException();
        expect(networkException.isNetworkError, true);
        expect(networkException.isAuthError, false);
        expect(networkException.isServerError, false);
      });

      test('should correctly identify rate limit errors', () {
        final rateLimitException = RateLimitException();
        expect(rateLimitException.isRateLimited, true);
        expect(rateLimitException.isAuthError, false);
        expect(rateLimitException.isServerError, false);
      });
    });

    group('User-Friendly Messages', () {
      test('should provide appropriate message for each error type', () {
        final testCases = [
          (UnauthorizedException(), 'session has expired'),
          (ForbiddenException(), 'do not have permission'),
          (NotFoundException(), 'not found'),
          (ValidationException(), 'check your input'),
          (RateLimitException(), 'Too many requests'),
          (ServerException(statusCode: 500), 'Server error'),
          (NoInternetException(), 'No internet connection'),
          (ConnectionTimeoutException(), 'connection timed out'),
        ];

        for (final (exception, expectedPhrase) in testCases) {
          final message = exception.getUserFriendlyMessage();
          expect(message.toLowerCase(), contains(expectedPhrase.toLowerCase()),
              reason: '${exception.runtimeType} should contain "$expectedPhrase"');
        }
      });

      test('should not expose technical details in user messages', () {
        final exception = ServerException(
          statusCode: 500,
          message: 'Database connection failed at line 123',
        );

        final userMessage = exception.getUserFriendlyMessage();
        
        // Should not contain technical details
        expect(userMessage, isNot(contains('Database')));
        expect(userMessage, isNot(contains('line 123')));
        expect(userMessage, contains('Server error'));
      });
    });

    group('Error Context', () {
      test('should preserve original error message', () {
        // Arrange
        const originalMessage = 'Custom error message';
        final exception = ServerException(
          statusCode: 500,
          message: originalMessage,
        );

        // Assert
        expect(exception.message, originalMessage);
      });

      test('should preserve status code', () {
        final testCases = [
          (400, BadRequestException()),
          (401, UnauthorizedException()),
          (403, ForbiddenException()),
          (404, NotFoundException()),
          (422, ValidationException()),
          (429, RateLimitException()),
          (500, ServerException(statusCode: 500)),
        ];

        for (final (expectedCode, exception) in testCases) {
          expect(exception.statusCode, expectedCode,
              reason: '${exception.runtimeType} should have status code $expectedCode');
        }
      });

      test('should preserve validation errors', () {
        // Arrange
        final errors = {
          'email': ['Email is required'],
          'password': ['Password too short'],
        };
        final exception = ValidationException(errors: errors);

        // Assert
        expect(exception.errors, errors);
        expect(exception.errors!['email'], ['Email is required']);
        expect(exception.errors!['password'], ['Password too short']);
      });
    });

    group('Error Recovery Hints', () {
      test('should indicate when re-authentication is required', () {
        final exception = UnauthorizedException();
        expect(exception.requiresReauthentication, true);
      });

      test('should provide retry-after for rate limits', () {
        final exception = RateLimitException(retryAfter: 120);
        expect(exception.retryAfter, 120);
      });

      test('should indicate retryable errors', () {
        // Network errors are typically retryable
        final networkException = NoInternetException();
        expect(networkException.isNetworkError, true);

        // Server errors might be retryable
        final serverException = ServerException(statusCode: 503);
        expect(serverException.isServerError, true);

        // Validation errors are not retryable without changes
        final validationException = ValidationException();
        expect(validationException.isValidationError, true);
      });
    });
  });
}

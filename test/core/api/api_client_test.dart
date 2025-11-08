import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/api_exception.dart';

void main() {
  late DioApiClient apiClient;

  setUp(() {
    apiClient = DioApiClient(baseUrl: 'https://api.test.com');
  });

  group('DioApiClient - Token Management', () {
    test('should set auth token correctly', () {
      // Act
      apiClient.setAuthToken('test-token-123');

      // Assert
      expect(apiClient.getAuthToken(), 'test-token-123');
    });

    test('should clear auth token correctly', () {
      // Arrange
      apiClient.setAuthToken('test-token-123');

      // Act
      apiClient.clearAuthToken();

      // Assert
      expect(apiClient.getAuthToken(), isNull);
    });

    test('should return null when no token is set', () {
      // Assert
      expect(apiClient.getAuthToken(), isNull);
    });
  });

  group('ApiException - Error Handling', () {
    test('should create UnauthorizedException from 401 DioException', () {
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
      expect(exception.isAuthError, isTrue);
    });

    test('should create ForbiddenException from 403 DioException', () {
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
      expect(exception.isForbiddenError, isTrue);
    });

    test('should create NotFoundException from 404 DioException', () {
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
      expect(exception.isNotFoundError, isTrue);
    });

    test('should create ValidationException from 422 DioException', () {
      // Arrange
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/users'),
        response: Response(
          requestOptions: RequestOptions(path: '/users'),
          statusCode: 422,
          data: {
            'message': 'Validation failed',
            'errors': {
              'email': ['Email is required'],
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
      expect(exception.isValidationError, isTrue);
      expect(exception.errors, isNotNull);
      expect(exception.errors!['email'], isNotNull);
    });

    test('should create RateLimitException from 429 DioException', () {
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
      expect(exception.isRateLimited, isTrue);
      final rateLimitException = exception as RateLimitException;
      expect(rateLimitException.retryAfter, 60);
    });

    test('should create ServerException from 500 DioException', () {
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
      expect(exception.isServerError, isTrue);
    });

    test('should create ConnectionTimeoutException from timeout DioException',
        () {
      // Arrange
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      // Act
      final exception = ApiException.fromDioException(dioException);

      // Assert
      expect(exception, isA<ConnectionTimeoutException>());
      expect(exception.isNetworkError, isTrue);
    });

    test('should create NoInternetException from connection error DioException',
        () {
      // Arrange
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );

      // Act
      final exception = ApiException.fromDioException(dioException);

      // Assert
      expect(exception, isA<NoInternetException>());
      expect(exception.isNetworkError, isTrue);
    });

    test('should provide user-friendly error messages', () {
      // Test various error types
      final authException = UnauthorizedException();
      expect(authException.getUserFriendlyMessage(),
          contains('session has expired'));

      final forbiddenException = ForbiddenException();
      expect(forbiddenException.getUserFriendlyMessage(),
          contains('do not have permission'));

      final notFoundException = NotFoundException();
      expect(notFoundException.getUserFriendlyMessage(),
          contains('not found'));

      final validationException = ValidationException();
      expect(validationException.getUserFriendlyMessage(),
          contains('check your input'));

      final rateLimitException = RateLimitException();
      expect(rateLimitException.getUserFriendlyMessage(),
          contains('Too many requests'));

      final serverException = ServerException(statusCode: 500);
      expect(serverException.getUserFriendlyMessage(),
          contains('Server error'));

      final networkException = NoInternetException();
      expect(networkException.getUserFriendlyMessage(),
          contains('No internet connection'));
    });
  });

  group('DioApiClient - Token Management', () {
    test('should set auth token correctly', () {
      // Act
      apiClient.setAuthToken('test-token-123');

      // Assert
      expect(apiClient.getAuthToken(), 'test-token-123');
    });

    test('should clear auth token correctly', () {
      // Arrange
      apiClient.setAuthToken('test-token-123');

      // Act
      apiClient.clearAuthToken();

      // Assert
      expect(apiClient.getAuthToken(), isNull);
    });

    test('should return null when no token is set', () {
      // Assert
      expect(apiClient.getAuthToken(), isNull);
    });

    test('should update token when set multiple times', () {
      // Arrange
      apiClient.setAuthToken('token-1');
      expect(apiClient.getAuthToken(), 'token-1');

      // Act
      apiClient.setAuthToken('token-2');

      // Assert
      expect(apiClient.getAuthToken(), 'token-2');
    });
  });
}

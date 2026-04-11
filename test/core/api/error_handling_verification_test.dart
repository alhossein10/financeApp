import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:finance_app/core/api/api_exception.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/services/token_manager.dart';

@GenerateMocks([Dio, TokenManager])
import 'error_handling_verification_test.mocks.dart';

/// Comprehensive test suite for verifying error handling across all endpoints
/// 
/// Tests Requirements 26.1-26.8:
/// - 400 Bad Request handling
/// - 401 Unauthorized handling (redirect to login)
/// - 403 Forbidden handling (access denied message)
/// - 404 Not Found handling
/// - 422 Validation Error handling (field-specific errors)
/// - 429 Rate Limit handling (wait and retry)
/// - 500 Server Error handling (retry option)
/// - Network timeout handling
void main() {
  late MockDio mockDio;
  late MockTokenManager mockTokenManager;
  late DioApiClient apiClient;

  setUp(() {
    mockDio = MockDio();
    mockTokenManager = MockTokenManager();
    
    // Configure mock Dio with default options
    when(mockDio.options).thenReturn(BaseOptions());
    when(mockDio.interceptors).thenReturn(Interceptors());
    
    apiClient = DioApiClient(
      dio: mockDio,
      tokenManager: mockTokenManager,
    );
  });

  group('Requirement 26.1: 400 Bad Request Handling', () {
    test('should handle 400 error with validation errors', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/test');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 400,
          data: {
            'message': 'Invalid request',
            'errors': {
              'field1': ['Field 1 is required'],
              'field2': ['Field 2 must be valid'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/test'),
        throwsA(isA<BadRequestException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.message, 'message', 'Invalid request')
            .having((e) => e.errors, 'errors', isNotNull)
            .having((e) => e.isBadRequest, 'isBadRequest', true)),
      );
    });

    test('should provide user-friendly message for 400 errors', () {
      // Arrange
      final exception = BadRequestException(
        message: 'Invalid request',
        errors: {'email': ['Email is invalid']},
      );

      // Act
      final userMessage = exception.userFriendlyMessage;

      // Assert
      expect(userMessage, contains('Email is invalid'));
    });
  });

  group('Requirement 26.2: 401 Unauthorized Handling', () {
    test('should handle 401 error and indicate auth failure', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/protected');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
          data: {'message': 'Unauthorized'},
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/protected'),
        throwsA(isA<UnauthorizedException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.isAuthError, 'isAuthError', true)
            .having((e) => e.isUnauthorized, 'isUnauthorized', true)),
      );
    });

    test('should provide redirect to login message for 401 errors', () {
      // Arrange
      final exception = UnauthorizedException();

      // Act
      final userMessage = exception.userFriendlyMessage;

      // Assert
      expect(userMessage, contains('Session expired'));
      expect(userMessage, contains('login'));
    });
  });

  group('Requirement 26.3: 403 Forbidden Handling', () {
    test('should handle 403 error with access denied message', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/admin');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 403,
          data: {'message': 'Access denied'},
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/admin'),
        throwsA(isA<ForbiddenException>()
            .having((e) => e.statusCode, 'statusCode', 403)
            .having((e) => e.isForbiddenError, 'isForbiddenError', true)
            .having((e) => e.isForbidden, 'isForbidden', true)),
      );
    });

    test('should provide access denied message for 403 errors', () {
      // Arrange
      final exception = ForbiddenException();

      // Act
      final userMessage = exception.userFriendlyMessage;

      // Assert
      expect(userMessage, contains('Access denied'));
      expect(userMessage, contains('permission'));
    });
  });

  group('Requirement 26.4: 404 Not Found Handling', () {
    test('should handle 404 error', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/nonexistent');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 404,
          data: {'message': 'Resource not found'},
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/nonexistent'),
        throwsA(isA<NotFoundException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.isNotFoundError, 'isNotFoundError', true)
            .having((e) => e.isNotFound, 'isNotFound', true)),
      );
    });

    test('should provide not found message for 404 errors', () {
      // Arrange
      final exception = NotFoundException();

      // Act
      final userMessage = exception.userFriendlyMessage;

      // Assert
      expect(userMessage, contains('not found'));
    });
  });

  group('Requirement 26.5: 422 Validation Error Handling', () {
    test('should handle 422 error with field-specific errors', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/create');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 422,
          data: {
            'message': 'Validation failed',
            'errors': {
              'email': ['The email field is required.', 'The email must be valid.'],
              'password': ['The password must be at least 8 characters.'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.post(any, data: anyNamed('data'), queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.post('/create', body: {}),
        throwsA(isA<ValidationException>()
            .having((e) => e.statusCode, 'statusCode', 422)
            .having((e) => e.isValidationError, 'isValidationError', true)
            .having((e) => e.errors, 'errors', isNotNull)),
      );
    });

    test('should format field-specific validation errors', () {
      // Arrange
      final exception = ValidationException(
        message: 'Validation failed',
        errors: {
          'email': ['The email field is required.'],
          'password': ['The password must be at least 8 characters.'],
        },
      );

      // Act
      final validationErrors = exception.getValidationErrors();
      final formattedErrors = exception.getFormattedValidationErrors();

      // Assert
      expect(validationErrors, hasLength(2));
      expect(validationErrors, contains(contains('email')));
      expect(validationErrors, contains(contains('password')));
      expect(formattedErrors, contains('email'));
      expect(formattedErrors, contains('password'));
    });

    test('should provide user-friendly validation error message', () {
      // Arrange
      final exception = ValidationException(
        message: 'Validation failed',
        errors: {
          'email': ['Invalid email format'],
        },
      );

      // Act
      final userMessage = exception.userFriendlyMessage;

      // Assert
      expect(userMessage, contains('Invalid email format'));
    });
  });

  group('Requirement 26.6: 429 Rate Limit Handling', () {
    test('should handle 429 error with retry-after header', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/api');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 429,
          data: {'message': 'Too many requests'},
          headers: Headers.fromMap({
            'retry-after': ['60'],
          }),
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/api'),
        throwsA(isA<RateLimitException>()
            .having((e) => e.statusCode, 'statusCode', 429)
            .having((e) => e.isRateLimited, 'isRateLimited', true)
            .having((e) => e.retryAfter, 'retryAfter', 60)),
      );
    });

    test('should provide retry duration for rate limit errors', () {
      // Arrange
      final exception = RateLimitException(retryAfter: 60);

      // Act
      final retryDuration = exception.getRetryAfterDuration();
      final userMessage = exception.userFriendlyMessage;

      // Assert
      expect(retryDuration, equals(Duration(seconds: 60)));
      expect(userMessage, contains('Too many requests'));
      expect(userMessage, contains('60 seconds'));
    });

    test('should handle rate limit without retry-after header', () {
      // Arrange
      final exception = RateLimitException();

      // Act
      final retryDuration = exception.getRetryAfterDuration();
      final userMessage = exception.userFriendlyMessage;

      // Assert
      expect(retryDuration, isNull);
      expect(userMessage, contains('try again later'));
    });
  });

  group('Requirement 26.7: 500 Server Error Handling', () {
    test('should handle 500 internal server error', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/api');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 500,
          data: {'message': 'Internal server error'},
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/api'),
        throwsA(isA<ServerException>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.isServerError, 'isServerError', true)),
      );
    });

    test('should handle 502 bad gateway error', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/api');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 502,
          data: {'message': 'Bad gateway'},
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/api'),
        throwsA(isA<ServerException>()
            .having((e) => e.statusCode, 'statusCode', 502)
            .having((e) => e.isServerError, 'isServerError', true)),
      );
    });

    test('should handle 503 service unavailable error', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/api');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 503,
          data: {'message': 'Service unavailable'},
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/api'),
        throwsA(isA<ServerException>()
            .having((e) => e.statusCode, 'statusCode', 503)
            .having((e) => e.isServerError, 'isServerError', true)),
      );
    });

    test('should handle 504 gateway timeout error', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/api');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 504,
          data: {'message': 'Gateway timeout'},
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/api'),
        throwsA(isA<ServerException>()
            .having((e) => e.statusCode, 'statusCode', 504)
            .having((e) => e.isServerError, 'isServerError', true)),
      );
    });

    test('should provide retry option message for server errors', () {
      // Arrange
      final exception500 = ServerException(statusCode: 500);
      final exception502 = ServerException(statusCode: 502);
      final exception503 = ServerException(statusCode: 503);
      final exception504 = ServerException(statusCode: 504);

      // Act & Assert
      expect(exception500.userFriendlyMessage, contains('try again'));
      expect(exception502.userFriendlyMessage, contains('temporarily unavailable'));
      expect(exception503.userFriendlyMessage, contains('try again'));
      expect(exception504.userFriendlyMessage, contains('took too long'));
    });
  });

  group('Requirement 26.8: Network Timeout Handling', () {
    test('should handle connection timeout', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/api');
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionTimeout,
        message: 'Connection timeout',
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/api'),
        throwsA(isA<ConnectionTimeoutException>()
            .having((e) => e.isNetworkError, 'isNetworkError', true)),
      );
    });

    test('should handle send timeout', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/api');
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.sendTimeout,
        message: 'Send timeout',
      );

      when(mockDio.post(any, data: anyNamed('data'), queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.post('/api', body: {}),
        throwsA(isA<SendTimeoutException>()
            .having((e) => e.isNetworkError, 'isNetworkError', true)),
      );
    });

    test('should handle receive timeout', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/api');
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.receiveTimeout,
        message: 'Receive timeout',
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/api'),
        throwsA(isA<ReceiveTimeoutException>()
            .having((e) => e.isNetworkError, 'isNetworkError', true)),
      );
    });

    test('should handle no internet connection', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/api');
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionError,
        message: 'No internet connection',
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/api'),
        throwsA(isA<NoInternetException>()
            .having((e) => e.isNetworkError, 'isNetworkError', true)),
      );
    });

    test('should provide connection timeout message', () {
      // Arrange
      final exception = ConnectionTimeoutException();

      // Act
      final userMessage = exception.userFriendlyMessage;

      // Assert
      expect(userMessage, contains('Connection timeout'));
      expect(userMessage, contains('internet connection'));
    });

    test('should provide no internet message', () {
      // Arrange
      final exception = NoInternetException();

      // Act
      final userMessage = exception.userFriendlyMessage;

      // Assert
      expect(userMessage, contains('No internet connection'));
      expect(userMessage, contains('network'));
    });
  });

  group('Additional Error Handling Tests', () {
    test('should handle request cancellation', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/api');
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.cancel,
        message: 'Request cancelled',
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/api'),
        throwsA(isA<RequestCancelledException>()),
      );
    });

    test('should handle bad certificate error', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/api');
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badCertificate,
        message: 'Bad certificate',
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/api'),
        throwsA(isA<BadCertificateException>()),
      );
    });

    test('should handle unknown errors', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/api');
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.unknown,
        message: 'Unknown error',
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/api'),
        throwsA(isA<UnknownApiException>()),
      );
    });
  });

  group('Error Message Formatting', () {
    test('should format validation errors with multiple fields', () {
      // Arrange
      final exception = ValidationException(
        message: 'Validation failed',
        errors: {
          'email': ['Required', 'Invalid format'],
          'password': ['Too short'],
          'name': ['Required'],
        },
      );

      // Act
      final formatted = exception.getFormattedValidationErrors();

      // Assert
      expect(formatted, contains('email'));
      expect(formatted, contains('password'));
      expect(formatted, contains('name'));
      expect(formatted, contains('Required'));
      expect(formatted, contains('Invalid format'));
      expect(formatted, contains('Too short'));
    });

    test('should handle empty validation errors', () {
      // Arrange
      final exception = ValidationException(
        message: 'Validation failed',
        errors: {},
      );

      // Act
      final formatted = exception.getFormattedValidationErrors();

      // Assert
      expect(formatted, equals('Validation failed'));
    });

    test('should handle null validation errors', () {
      // Arrange
      final exception = ValidationException(
        message: 'Validation failed',
      );

      // Act
      final formatted = exception.getFormattedValidationErrors();

      // Assert
      expect(formatted, equals('Validation failed'));
    });
  });
}

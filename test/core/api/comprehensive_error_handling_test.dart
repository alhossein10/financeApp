import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:finance_app/core/api/api_exception.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/bearer_token_interceptor.dart';
import 'package:finance_app/core/services/token_manager.dart';

// Reuse mocks from both test files
import 'error_handling_verification_test.mocks.dart';
import 'bearer_token_interceptor_test.mocks.dart' show MockErrorInterceptorHandler;

/// Comprehensive test suite for Task 17.3: Test Error Handling
/// 
/// Tests Requirements 29.7, 29.8:
/// - All HTTP status codes (400, 401, 403, 404, 422, 429, 500)
/// - Network timeout
/// - Token refresh failure
/// - Insufficient balance errors
/// - Validation errors
void main() {
  late MockDio mockDio;
  late MockTokenManager mockTokenManager;
  late DioApiClient apiClient;
  late BearerTokenInterceptor bearerTokenInterceptor;
  late MockErrorInterceptorHandler mockErrorHandler;

  setUp(() {
    mockDio = MockDio();
    mockTokenManager = MockTokenManager();
    mockErrorHandler = MockErrorInterceptorHandler();
    
    // Configure mock Dio with default options
    when(mockDio.options).thenReturn(BaseOptions());
    when(mockDio.interceptors).thenReturn(Interceptors());
    
    bearerTokenInterceptor = BearerTokenInterceptor(
      tokenManager: mockTokenManager,
      dio: mockDio,
    );
    
    apiClient = DioApiClient(
      dio: mockDio,
      tokenManager: mockTokenManager,
    );
  });

  group('Task 17.3: Token Refresh Failure', () {
    test('should handle token refresh failure and clear tokens', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/auth/refresh');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
          data: {'message': 'Invalid refresh token'},
        ),
        type: DioExceptionType.badResponse,
      );

      // Act
      await bearerTokenInterceptor.onError(dioException, mockErrorHandler);

      // Assert
      verify(mockTokenManager.clearTokens()).called(1);
      verify(mockErrorHandler.next(dioException)).called(1);
    });

    test('should handle expired refresh token', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/auth/refresh');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
          data: {
            'message': 'Refresh token expired',
            'error': 'token_expired',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      // Act
      await bearerTokenInterceptor.onError(dioException, mockErrorHandler);

      // Assert
      verify(mockTokenManager.clearTokens()).called(1);
      verify(mockErrorHandler.next(dioException)).called(1);
    });

    test('should handle invalid refresh token format', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/auth/refresh');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 400,
          data: {
            'message': 'Invalid token format',
            'errors': {
              'refresh_token': ['The refresh token is invalid'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.post(any, data: anyNamed('data'), queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.post('/auth/refresh', body: {'refresh_token': 'invalid'}),
        throwsA(isA<BadRequestException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.errors, 'errors', isNotNull)),
      );
    });

    test('should handle refresh token revoked', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/auth/refresh');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
          data: {
            'message': 'Token has been revoked',
            'error': 'token_revoked',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      // Act
      await bearerTokenInterceptor.onError(dioException, mockErrorHandler);

      // Assert
      verify(mockTokenManager.clearTokens()).called(1);
    });

    test('should handle network error during token refresh', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/auth/refresh');
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionTimeout,
        message: 'Connection timeout during refresh',
      );

      when(mockDio.post(any, data: anyNamed('data'), queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.post('/auth/refresh', body: {}),
        throwsA(isA<ConnectionTimeoutException>()),
      );
    });
  });

  group('Task 17.3: Insufficient Balance Errors', () {
    test('should handle insufficient USD balance for expense', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/expenses');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 422,
          data: {
            'message': 'Insufficient balance',
            'errors': {
              'price_usd': ['Insufficient USD balance. Available: \$50.00, Required: \$100.00'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.post(any, data: anyNamed('data'), queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.post('/expenses', body: {'price_usd': 100}),
        throwsA(isA<ValidationException>()
            .having((e) => e.statusCode, 'statusCode', 422)
            .having((e) => e.message, 'message', 'Insufficient balance')
            .having((e) => e.errors?['price_usd'], 'price_usd error', isNotNull)),
      );
    });

    test('should handle insufficient SYP balance for expense', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/expenses');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 422,
          data: {
            'message': 'Insufficient balance',
            'errors': {
              'price_syp': ['Insufficient SYP balance. Available: 10,000 SYP, Required: 50,000 SYP'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.post(any, data: anyNamed('data'), queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.post('/expenses', body: {'price_syp': 50000}),
        throwsA(isA<ValidationException>()
            .having((e) => e.errors?['price_syp'], 'price_syp error', isNotNull)),
      );
    });

    test('should handle insufficient TRY balance for expense', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/expenses');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 422,
          data: {
            'message': 'Insufficient balance',
            'errors': {
              'price_try': ['Insufficient TRY balance. Available: 100 TRY, Required: 500 TRY'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.post(any, data: anyNamed('data'), queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.post('/expenses', body: {'price_try': 500}),
        throwsA(isA<ValidationException>()
            .having((e) => e.errors?['price_try'], 'price_try error', isNotNull)),
      );
    });

    test('should handle insufficient balance for transfer', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/transfers');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 422,
          data: {
            'message': 'Insufficient balance',
            'errors': {
              'amount_usd': ['Insufficient USD balance for transfer'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.post(any, data: anyNamed('data'), queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.post('/transfers', body: {'amount_usd': 1000}),
        throwsA(isA<ValidationException>()
            .having((e) => e.errors?['amount_usd'], 'amount_usd error', isNotNull)),
      );
    });

    test('should handle insufficient USD balance for exchange', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/exchanges');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 422,
          data: {
            'message': 'Insufficient balance',
            'errors': {
              'amount_usd': ['Insufficient USD balance for exchange. Available: \$25.00, Required: \$100.00'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.post(any, data: anyNamed('data'), queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.post('/exchanges', body: {'amount_usd': 100}),
        throwsA(isA<ValidationException>()
            .having((e) => e.errors?['amount_usd'], 'amount_usd error', isNotNull)),
      );
    });

    test('should provide user-friendly insufficient balance message', () {
      // Arrange
      final exception = ValidationException(
        message: 'Insufficient balance',
        errors: {
          'price_usd': ['Insufficient USD balance. Available: \$50.00, Required: \$100.00'],
        },
      );

      // Act
      final userMessage = exception.userFriendlyMessage;

      // Assert
      expect(userMessage, contains('Insufficient'));
      expect(userMessage, contains('balance'));
    });
  });

  group('Task 17.3: Validation Errors', () {
    test('should handle multiple validation errors', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/expenses');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 422,
          data: {
            'message': 'Validation failed',
            'errors': {
              'description': ['The description field is required.'],
              'price_usd': ['The price must be greater than 0.'],
              'expense_date': ['The expense date must be a valid date.'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.post(any, data: anyNamed('data'), queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.post('/expenses', body: {}),
        throwsA(isA<ValidationException>()
            .having((e) => e.errors?.length, 'errors count', 3)
            .having((e) => e.errors?['description'], 'description error', isNotNull)
            .having((e) => e.errors?['price_usd'], 'price_usd error', isNotNull)
            .having((e) => e.errors?['expense_date'], 'expense_date error', isNotNull)),
      );
    });

    test('should handle email validation error', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/auth/register');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 422,
          data: {
            'message': 'Validation failed',
            'errors': {
              'email': ['The email must be a valid email address.', 'The email has already been taken.'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.post(any, data: anyNamed('data'), queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.post('/auth/register', body: {'email': 'invalid'}),
        throwsA(isA<ValidationException>()
            .having((e) => e.errors?['email']?.length, 'email errors count', 2)),
      );
    });

    test('should handle password validation error', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/auth/register');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 422,
          data: {
            'message': 'Validation failed',
            'errors': {
              'password': [
                'The password must be at least 8 characters.',
                'The password must contain at least one uppercase letter.',
                'The password must contain at least one number.',
              ],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.post(any, data: anyNamed('data'), queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.post('/auth/register', body: {'password': 'weak'}),
        throwsA(isA<ValidationException>()
            .having((e) => e.errors?['password']?.length, 'password errors count', 3)),
      );
    });

    test('should handle group code validation error', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/user/join-group');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 422,
          data: {
            'message': 'Validation failed',
            'errors': {
              'group_code': ['The group code must be 6 digits.', 'Invalid group code.'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.post(any, data: anyNamed('data'), queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.post('/user/join-group', body: {'group_code': '123'}),
        throwsA(isA<ValidationException>()
            .having((e) => e.errors?['group_code'], 'group_code error', isNotNull)),
      );
    });

    test('should handle exchange rate validation error', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/exchanges');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 422,
          data: {
            'message': 'Validation failed',
            'errors': {
              'exchange_rate': ['The exchange rate must be greater than 0.'],
              'target_currency': ['The target currency must be either SYP or TRY.'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.post(any, data: anyNamed('data'), queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.post('/exchanges', body: {'exchange_rate': -1}),
        throwsA(isA<ValidationException>()
            .having((e) => e.errors?['exchange_rate'], 'exchange_rate error', isNotNull)
            .having((e) => e.errors?['target_currency'], 'target_currency error', isNotNull)),
      );
    });

    test('should handle date validation error', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/expenses');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 422,
          data: {
            'message': 'Validation failed',
            'errors': {
              'expense_date': ['The expense date must be a valid date.', 'The expense date cannot be in the future.'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.post(any, data: anyNamed('data'), queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.post('/expenses', body: {'expense_date': 'invalid'}),
        throwsA(isA<ValidationException>()
            .having((e) => e.errors?['expense_date']?.length, 'expense_date errors count', 2)),
      );
    });
  });

  group('Task 17.3: Network Timeout Scenarios', () {
    test('should handle connection timeout with retry suggestion', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/expenses');
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionTimeout,
        message: 'Connection timeout',
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/expenses'),
        throwsA(isA<ConnectionTimeoutException>()
            .having((e) => e.isNetworkError, 'isNetworkError', true)
            .having((e) => e.message, 'message', contains('timeout'))),
      );
    });

    test('should handle send timeout during file upload', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/expenses/1/invoice');
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.sendTimeout,
        message: 'Send timeout',
      );

      when(mockDio.post(any, data: anyNamed('data'), queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.post('/expenses/1/invoice', body: {}),
        throwsA(isA<SendTimeoutException>()
            .having((e) => e.isNetworkError, 'isNetworkError', true)),
      );
    });

    test('should handle receive timeout during large data fetch', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/export/1/download');
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.receiveTimeout,
        message: 'Receive timeout',
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/export/1/download'),
        throwsA(isA<ReceiveTimeoutException>()
            .having((e) => e.isNetworkError, 'isNetworkError', true)),
      );
    });

    test('should handle no internet connection', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/expenses');
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionError,
        message: 'No internet connection',
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/expenses'),
        throwsA(isA<NoInternetException>()
            .having((e) => e.isNetworkError, 'isNetworkError', true)
            .having((e) => e.message, 'message', contains('internet'))),
      );
    });
  });

  group('Task 17.3: HTTP Status Code Coverage', () {
    test('should handle 400 Bad Request', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/test');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 400,
          data: {'message': 'Bad request'},
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/test'),
        throwsA(isA<BadRequestException>()
            .having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('should handle 401 Unauthorized', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/test');
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
        () => apiClient.get('/test'),
        throwsA(isA<UnauthorizedException>()
            .having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('should handle 403 Forbidden', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/test');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 403,
          data: {'message': 'Forbidden'},
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/test'),
        throwsA(isA<ForbiddenException>()
            .having((e) => e.statusCode, 'statusCode', 403)),
      );
    });

    test('should handle 404 Not Found', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/test');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 404,
          data: {'message': 'Not found'},
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/test'),
        throwsA(isA<NotFoundException>()
            .having((e) => e.statusCode, 'statusCode', 404)),
      );
    });

    test('should handle 422 Unprocessable Entity', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/test');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 422,
          data: {
            'message': 'Validation failed',
            'errors': {'field': ['Error']},
          },
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.post(any, data: anyNamed('data'), queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.post('/test', body: {}),
        throwsA(isA<ValidationException>()
            .having((e) => e.statusCode, 'statusCode', 422)),
      );
    });

    test('should handle 429 Too Many Requests', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/test');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 429,
          data: {'message': 'Too many requests'},
          headers: Headers.fromMap({'retry-after': ['30']}),
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
          .thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/test'),
        throwsA(isA<RateLimitException>()
            .having((e) => e.statusCode, 'statusCode', 429)
            .having((e) => e.retryAfter, 'retryAfter', 30)),
      );
    });

    test('should handle 500 Internal Server Error', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/test');
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
        () => apiClient.get('/test'),
        throwsA(isA<ServerException>()
            .having((e) => e.statusCode, 'statusCode', 500)),
      );
    });
  });
}

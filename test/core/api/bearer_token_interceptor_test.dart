import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:finance_app/core/api/bearer_token_interceptor.dart';
import 'package:finance_app/core/services/token_manager.dart';

import 'bearer_token_interceptor_test.mocks.dart';

@GenerateMocks([TokenManager, Dio, RequestInterceptorHandler, ErrorInterceptorHandler])
void main() {
  late BearerTokenInterceptor interceptor;
  late MockTokenManager mockTokenManager;
  late MockDio mockDio;
  late MockRequestInterceptorHandler mockRequestHandler;
  late MockErrorInterceptorHandler mockErrorHandler;

  setUp(() {
    mockTokenManager = MockTokenManager();
    mockDio = MockDio();
    mockRequestHandler = MockRequestInterceptorHandler();
    mockErrorHandler = MockErrorInterceptorHandler();
    
    interceptor = BearerTokenInterceptor(
      tokenManager: mockTokenManager,
      dio: mockDio,
    );
  });

  group('BearerTokenInterceptor', () {
    group('onRequest', () {
      test('should add Bearer token to protected endpoint', () async {
        // Arrange
        final options = RequestOptions(path: '/expenses');
        when(mockTokenManager.getToken()).thenAnswer((_) async => 'test-token-123');

        // Act
        await interceptor.onRequest(options, mockRequestHandler);

        // Assert
        expect(options.headers['Authorization'], 'Bearer test-token-123');
        verify(mockRequestHandler.next(options)).called(1);
      });

      test('should skip token for public /organizations endpoint', () async {
        // Arrange
        final options = RequestOptions(path: '/organizations');

        // Act
        await interceptor.onRequest(options, mockRequestHandler);

        // Assert
        expect(options.headers.containsKey('Authorization'), false);
        verify(mockRequestHandler.next(options)).called(1);
        verifyNever(mockTokenManager.getToken());
      });

      test('should skip token for /auth/register endpoint', () async {
        // Arrange
        final options = RequestOptions(path: '/auth/register');

        // Act
        await interceptor.onRequest(options, mockRequestHandler);

        // Assert
        expect(options.headers.containsKey('Authorization'), false);
        verifyNever(mockTokenManager.getToken());
      });

      test('should skip token for /auth/login endpoint', () async {
        // Arrange
        final options = RequestOptions(path: '/auth/login');

        // Act
        await interceptor.onRequest(options, mockRequestHandler);

        // Assert
        expect(options.headers.containsKey('Authorization'), false);
        verifyNever(mockTokenManager.getToken());
      });

      test('should skip token for /organizations/{id}/departments endpoint', () async {
        // Arrange
        final options = RequestOptions(path: '/organizations/1/departments');

        // Act
        await interceptor.onRequest(options, mockRequestHandler);

        // Assert
        expect(options.headers.containsKey('Authorization'), false);
        verifyNever(mockTokenManager.getToken());
      });

      test('should proceed without token when token is null', () async {
        // Arrange
        final options = RequestOptions(path: '/expenses');
        when(mockTokenManager.getToken()).thenAnswer((_) async => null);

        // Act
        await interceptor.onRequest(options, mockRequestHandler);

        // Assert
        expect(options.headers.containsKey('Authorization'), false);
        verify(mockRequestHandler.next(options)).called(1);
      });

      test('should proceed without token when token is empty', () async {
        // Arrange
        final options = RequestOptions(path: '/expenses');
        when(mockTokenManager.getToken()).thenAnswer((_) async => '');

        // Act
        await interceptor.onRequest(options, mockRequestHandler);

        // Assert
        expect(options.headers.containsKey('Authorization'), false);
        verify(mockRequestHandler.next(options)).called(1);
      });
    });

    group('onError - 401 Handling', () {
      test('should pass through non-401 errors', () async {
        // Arrange
        final error = DioException(
          requestOptions: RequestOptions(path: '/expenses'),
          response: Response(
            requestOptions: RequestOptions(path: '/expenses'),
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        );

        // Act
        await interceptor.onError(error, mockErrorHandler);

        // Assert
        verify(mockErrorHandler.next(error)).called(1);
      });

      test('should pass through 401 on public endpoint', () async {
        // Arrange
        final error = DioException(
          requestOptions: RequestOptions(path: '/organizations'),
          response: Response(
            requestOptions: RequestOptions(path: '/organizations'),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        );

        // Act
        await interceptor.onError(error, mockErrorHandler);

        // Assert
        verify(mockErrorHandler.next(error)).called(1);
      });

      test('should pass through 401 on refresh endpoint to prevent infinite loop', () async {
        // Arrange
        final error = DioException(
          requestOptions: RequestOptions(path: '/auth/refresh'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/refresh'),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        );

        // Act
        await interceptor.onError(error, mockErrorHandler);

        // Assert
        verify(mockTokenManager.clearTokens()).called(1);
        verify(mockErrorHandler.next(error)).called(1);
      });
    });

    group('Public Endpoint Detection', () {
      test('should detect /organizations as public', () async {
        // Arrange
        final options = RequestOptions(path: '/organizations');

        // Act
        await interceptor.onRequest(options, mockRequestHandler);

        // Assert
        verifyNever(mockTokenManager.getToken());
      });

      test('should detect /auth/register as public', () async {
        // Arrange
        final options = RequestOptions(path: '/auth/register');

        // Act
        await interceptor.onRequest(options, mockRequestHandler);

        // Assert
        verifyNever(mockTokenManager.getToken());
      });

      test('should detect /auth/login as public', () async {
        // Arrange
        final options = RequestOptions(path: '/auth/login');

        // Act
        await interceptor.onRequest(options, mockRequestHandler);

        // Assert
        verifyNever(mockTokenManager.getToken());
      });

      test('should detect /auth/forgot-password as public', () async {
        // Arrange
        final options = RequestOptions(path: '/auth/forgot-password');

        // Act
        await interceptor.onRequest(options, mockRequestHandler);

        // Assert
        verifyNever(mockTokenManager.getToken());
      });

      test('should detect /auth/reset-password as public', () async {
        // Arrange
        final options = RequestOptions(path: '/auth/reset-password');

        // Act
        await interceptor.onRequest(options, mockRequestHandler);

        // Assert
        verifyNever(mockTokenManager.getToken());
      });

      test('should detect /organizations/1/departments as public', () async {
        // Arrange
        final options = RequestOptions(path: '/organizations/1/departments');

        // Act
        await interceptor.onRequest(options, mockRequestHandler);

        // Assert
        verifyNever(mockTokenManager.getToken());
      });

      test('should treat /expenses as protected', () async {
        // Arrange
        final options = RequestOptions(path: '/expenses');
        when(mockTokenManager.getToken()).thenAnswer((_) async => 'token');

        // Act
        await interceptor.onRequest(options, mockRequestHandler);

        // Assert
        verify(mockTokenManager.getToken()).called(1);
        expect(options.headers['Authorization'], 'Bearer token');
      });

      test('should treat /super-admin/analytics as protected', () async {
        // Arrange
        final options = RequestOptions(path: '/super-admin/analytics');
        when(mockTokenManager.getToken()).thenAnswer((_) async => 'token');

        // Act
        await interceptor.onRequest(options, mockRequestHandler);

        // Assert
        verify(mockTokenManager.getToken()).called(1);
        expect(options.headers['Authorization'], 'Bearer token');
      });

      test('should treat /exchanges as protected', () async {
        // Arrange
        final options = RequestOptions(path: '/exchanges');
        when(mockTokenManager.getToken()).thenAnswer((_) async => 'token');

        // Act
        await interceptor.onRequest(options, mockRequestHandler);

        // Assert
        verify(mockTokenManager.getToken()).called(1);
        expect(options.headers['Authorization'], 'Bearer token');
      });
    });

    group('Path Normalization', () {
      test('should handle paths with query parameters', () async {
        // Arrange
        final options = RequestOptions(path: '/organizations?page=1');

        // Act
        await interceptor.onRequest(options, mockRequestHandler);

        // Assert
        verifyNever(mockTokenManager.getToken());
      });

      test('should handle paths with leading slash', () async {
        // Arrange
        final options = RequestOptions(path: '/auth/login');

        // Act
        await interceptor.onRequest(options, mockRequestHandler);

        // Assert
        verifyNever(mockTokenManager.getToken());
      });

      test('should handle paths without leading slash', () async {
        // Arrange
        final options = RequestOptions(path: 'auth/login');

        // Act
        await interceptor.onRequest(options, mockRequestHandler);

        // Assert
        verifyNever(mockTokenManager.getToken());
      });
    });
  });
}

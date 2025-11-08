import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/api_exception.dart';
import 'package:finance_app/core/services/laravel_auth_service.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/features/auth/domain/entities/user.dart';

@GenerateMocks([ApiClient, TokenManager])
import 'laravel_auth_service_test.mocks.dart';

void main() {
  late LaravelAuthService authService;
  late MockApiClient mockApiClient;
  late MockTokenManager mockTokenManager;

  setUp(() {
    mockApiClient = MockApiClient();
    mockTokenManager = MockTokenManager();
    authService = LaravelAuthService(
      apiClient: mockApiClient,
      tokenManager: mockTokenManager,
    );
  });

  group('LaravelAuthService - Register', () {
    const testName = 'John Doe';
    const testEmail = 'john@example.com';
    const testPassword = 'password123';
    const testToken = 'test-token-123';

    final mockResponse = Response(
      requestOptions: RequestOptions(path: '/auth/register'),
      statusCode: 201,
      data: {
        'user': {
          'id': 1,
          'name': testName,
          'email': testEmail,
          'role': 'user',
          'created_at': '2024-01-01T00:00:00Z',
        },
        'token': testToken,
        'token_type': 'Bearer',
        'expires_at': '2024-12-31T23:59:59Z',
      },
    );

    test('should register user successfully and store token', () async {
      // Arrange
      when(mockApiClient.post(
        '/auth/register',
        body: anyNamed('body'),
      )).thenAnswer((_) async => mockResponse);

      when(mockTokenManager.saveToken(
        token: anyNamed('token'),
        tokenType: anyNamed('tokenType'),
        expiresAt: anyNamed('expiresAt'),
      )).thenAnswer((_) async => {});

      // Act
      final result = await authService.register(
        name: testName,
        email: testEmail,
        password: testPassword,
      );

      // Assert
      expect(result.user, isA<User>());
      expect(result.user.email, testEmail);
      expect(result.user.username, testName);
      expect(result.user.role, UserRole.user);
      expect(result.groupCode, isNull);

      verify(mockApiClient.post(
        '/auth/register',
        body: {
          'name': testName,
          'email': testEmail,
          'password': testPassword,
          'password_confirmation': testPassword,
          'role': 'user',
        },
      )).called(1);

      verify(mockTokenManager.saveToken(
        token: testToken,
        tokenType: 'Bearer',
        expiresAt: anyNamed('expiresAt'),
      )).called(1);
    });

    test('should throw ApiException when registration fails', () async {
      // Arrange
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/register'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/register'),
          statusCode: 422,
          data: {
            'message': 'Validation failed',
            'errors': {'email': ['Email already exists']},
          },
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockApiClient.post(
        '/auth/register',
        body: anyNamed('body'),
      )).thenThrow(dioException);

      // Act & Assert
      expect(
        () => authService.register(
          name: testName,
          email: testEmail,
          password: testPassword,
        ),
        throwsA(isA<ApiException>()),
      );

      verifyNever(mockTokenManager.saveToken(
        token: anyNamed('token'),
        tokenType: anyNamed('tokenType'),
        expiresAt: anyNamed('expiresAt'),
      ));
    });
  });

  group('LaravelAuthService - Login', () {
    const testEmail = 'john@example.com';
    const testPassword = 'password123';
    const testToken = 'test-token-456';

    final mockResponse = Response(
      requestOptions: RequestOptions(path: '/auth/login'),
      statusCode: 200,
      data: {
        'user': {
          'id': 1,
          'name': 'John Doe',
          'email': testEmail,
          'role': 'admin',
          'created_at': '2024-01-01T00:00:00Z',
        },
        'token': testToken,
        'token_type': 'Bearer',
        'expires_at': '2024-12-31T23:59:59Z',
      },
    );

    test('should login user successfully and store token', () async {
      // Arrange
      when(mockApiClient.post(
        '/auth/login',
        body: anyNamed('body'),
      )).thenAnswer((_) async => mockResponse);

      when(mockTokenManager.saveToken(
        token: anyNamed('token'),
        tokenType: anyNamed('tokenType'),
        expiresAt: anyNamed('expiresAt'),
      )).thenAnswer((_) async => {});

      // Act
      final user = await authService.login(
        email: testEmail,
        password: testPassword,
      );

      // Assert
      expect(user, isA<User>());
      expect(user.email, testEmail);
      expect(user.role, UserRole.admin);
      expect(user.isAdmin, isTrue);

      verify(mockApiClient.post(
        '/auth/login',
        body: {
          'email': testEmail,
          'password': testPassword,
        },
      )).called(1);

      verify(mockTokenManager.saveToken(
        token: testToken,
        tokenType: 'Bearer',
        expiresAt: anyNamed('expiresAt'),
      )).called(1);
    });

    test('should throw UnauthorizedException for invalid credentials',
        () async {
      // Arrange
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
          data: {'message': 'Invalid credentials'},
        ),
        type: DioExceptionType.badResponse,
      );

      when(mockApiClient.post(
        '/auth/login',
        body: anyNamed('body'),
      )).thenThrow(dioException);

      // Act & Assert
      expect(
        () => authService.login(
          email: testEmail,
          password: testPassword,
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('LaravelAuthService - Logout', () {
    test('should logout successfully and clear tokens', () async {
      // Arrange
      when(mockApiClient.post('/auth/logout')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/logout'),
          statusCode: 200,
        ),
      );

      when(mockTokenManager.clearTokens()).thenAnswer((_) async => {});

      // Act
      await authService.logout();

      // Assert
      verify(mockApiClient.post('/auth/logout')).called(1);
      verify(mockTokenManager.clearTokens()).called(1);
    });

    test('should clear tokens even if API call fails', () async {
      // Arrange
      when(mockApiClient.post('/auth/logout')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/logout'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      when(mockTokenManager.clearTokens()).thenAnswer((_) async => {});

      // Act
      await authService.logout();

      // Assert
      verify(mockTokenManager.clearTokens()).called(1);
    });
  });

  group('LaravelAuthService - Get Current User', () {
    final mockResponse = Response(
      requestOptions: RequestOptions(path: '/auth/me'),
      statusCode: 200,
      data: {
        'id': 1,
        'name': 'John Doe',
        'email': 'john@example.com',
        'role': 'user',
        'created_at': '2024-01-01T00:00:00Z',
      },
    );

    test('should get current user successfully', () async {
      // Arrange
      when(mockApiClient.get('/auth/me'))
          .thenAnswer((_) async => mockResponse);

      // Act
      final user = await authService.getCurrentUser();

      // Assert
      expect(user, isA<User>());
      expect(user.email, 'john@example.com');
      verify(mockApiClient.get('/auth/me')).called(1);
    });

    test('should throw ApiException when user fetch fails', () async {
      // Arrange
      when(mockApiClient.get('/auth/me')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/me'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/me'),
            statusCode: 401,
            data: {'message': 'Unauthorized'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      // Act & Assert
      expect(
        () => authService.getCurrentUser(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('LaravelAuthService - Refresh Token', () {
    const newToken = 'new-token-789';

    final mockResponse = Response(
      requestOptions: RequestOptions(path: '/auth/refresh'),
      statusCode: 200,
      data: {
        'user': {
          'id': 1,
          'name': 'John Doe',
          'email': 'john@example.com',
          'role': 'user',
          'created_at': '2024-01-01T00:00:00Z',
        },
        'token': newToken,
        'token_type': 'Bearer',
        'expires_at': '2024-12-31T23:59:59Z',
      },
    );

    test('should refresh token successfully', () async {
      // Arrange
      when(mockApiClient.post('/auth/refresh'))
          .thenAnswer((_) async => mockResponse);

      when(mockTokenManager.saveToken(
        token: anyNamed('token'),
        tokenType: anyNamed('tokenType'),
        expiresAt: anyNamed('expiresAt'),
      )).thenAnswer((_) async => {});

      // Act
      final user = await authService.refreshToken();

      // Assert
      expect(user, isA<User>());
      verify(mockTokenManager.saveToken(
        token: newToken,
        tokenType: 'Bearer',
        expiresAt: anyNamed('expiresAt'),
      )).called(1);
    });

    test('should clear tokens when refresh fails', () async {
      // Arrange
      when(mockApiClient.post('/auth/refresh')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/refresh'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/refresh'),
            statusCode: 401,
            data: {'message': 'Token expired'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      when(mockTokenManager.clearTokens()).thenAnswer((_) async => {});

      // Act & Assert
      expect(
        () => authService.refreshToken(),
        throwsA(isA<ApiException>()),
      );

      verify(mockTokenManager.clearTokens()).called(1);
    });
  });

  group('LaravelAuthService - Authentication Status', () {
    test('should return true when token is valid', () async {
      // Arrange
      when(mockTokenManager.isTokenValid()).thenAnswer((_) async => true);

      // Act
      final isAuthenticated = await authService.isAuthenticated();

      // Assert
      expect(isAuthenticated, isTrue);
      verify(mockTokenManager.isTokenValid()).called(1);
    });

    test('should return false when token is invalid', () async {
      // Arrange
      when(mockTokenManager.isTokenValid()).thenAnswer((_) async => false);

      // Act
      final isAuthenticated = await authService.isAuthenticated();

      // Assert
      expect(isAuthenticated, isFalse);
    });
  });

  group('LaravelAuthService - Password Management', () {
    test('should send forgot password request successfully', () async {
      // Arrange
      const email = 'john@example.com';
      when(mockApiClient.post(
        '/auth/forgot-password',
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/forgot-password'),
          statusCode: 200,
        ),
      );

      // Act
      await authService.forgotPassword(email);

      // Assert
      verify(mockApiClient.post(
        '/auth/forgot-password',
        body: {'email': email},
      )).called(1);
    });

    test('should reset password successfully', () async {
      // Arrange
      const token = 'reset-token';
      const email = 'john@example.com';
      const password = 'newpassword123';

      when(mockApiClient.post(
        '/auth/reset-password',
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/reset-password'),
          statusCode: 200,
        ),
      );

      // Act
      await authService.resetPassword(
        token: token,
        email: email,
        password: password,
      );

      // Assert
      verify(mockApiClient.post(
        '/auth/reset-password',
        body: {
          'token': token,
          'email': email,
          'password': password,
          'password_confirmation': password,
        },
      )).called(1);
    });

    test('should change password successfully', () async {
      // Arrange
      const currentPassword = 'oldpassword';
      const newPassword = 'newpassword123';

      when(mockApiClient.put(
        '/profile/password',
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/profile/password'),
          statusCode: 200,
        ),
      );

      // Act
      await authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      // Assert
      verify(mockApiClient.put(
        '/profile/password',
        body: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPassword,
        },
      )).called(1);
    });
  });

  group('LaravelAuthService - Token Validation', () {
    test('should validate token successfully', () async {
      // Arrange
      when(mockApiClient.get('/auth/me')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/me'),
          statusCode: 200,
          data: {
            'id': 1,
            'name': 'John Doe',
            'email': 'john@example.com',
            'role': 'user',
            'created_at': '2024-01-01T00:00:00Z',
          },
        ),
      );

      // Act
      final isValid = await authService.validateToken();

      // Assert
      expect(isValid, isTrue);
    });

    test('should return false when token validation fails', () async {
      // Arrange
      when(mockApiClient.get('/auth/me')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/me'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/me'),
            statusCode: 401,
            data: {'message': 'Unauthorized'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      // Act
      final isValid = await authService.validateToken();

      // Assert
      expect(isValid, isFalse);
    });

    test('should check if token needs refresh', () async {
      // Arrange
      when(mockTokenManager.willTokenExpireSoon())
          .thenAnswer((_) async => true);

      // Act
      final needsRefresh = await authService.needsTokenRefresh();

      // Assert
      expect(needsRefresh, isTrue);
      verify(mockTokenManager.willTokenExpireSoon()).called(1);
    });
  });

  group('LaravelAuthService - Group Code Registration', () {
    const testName = 'John Doe';
    const testEmail = 'john@example.com';
    const testPassword = 'password123';
    const testToken = 'test-token-789';
    const testGroupCode = 'ABC123';

    test('should register admin and return group code', () async {
      // Arrange
      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/auth/register'),
        statusCode: 201,
        data: {
          'user': {
            'id': 1,
            'name': testName,
            'email': testEmail,
            'role': 'admin',
            'created_at': '2024-01-01T00:00:00Z',
          },
          'token': testToken,
          'token_type': 'Bearer',
          'expires_at': '2024-12-31T23:59:59Z',
          'group_code': testGroupCode,
        },
      );

      when(mockApiClient.post(
        '/auth/register',
        body: anyNamed('body'),
      )).thenAnswer((_) async => mockResponse);

      when(mockTokenManager.saveToken(
        token: anyNamed('token'),
        tokenType: anyNamed('tokenType'),
        expiresAt: anyNamed('expiresAt'),
      )).thenAnswer((_) async => {});

      // Act
      final result = await authService.register(
        name: testName,
        email: testEmail,
        password: testPassword,
        role: 'admin',
      );

      // Assert
      expect(result.user, isA<User>());
      expect(result.user.role, UserRole.admin);
      expect(result.groupCode, testGroupCode);

      verify(mockApiClient.post(
        '/auth/register',
        body: {
          'name': testName,
          'email': testEmail,
          'password': testPassword,
          'password_confirmation': testPassword,
          'role': 'admin',
        },
      )).called(1);
    });

    test('should register user with group code', () async {
      // Arrange
      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/auth/register'),
        statusCode: 201,
        data: {
          'user': {
            'id': 2,
            'name': testName,
            'email': testEmail,
            'role': 'user',
            'admin_group_id': 1,
            'created_at': '2024-01-01T00:00:00Z',
          },
          'token': testToken,
          'token_type': 'Bearer',
          'expires_at': '2024-12-31T23:59:59Z',
        },
      );

      when(mockApiClient.post(
        '/auth/register',
        body: anyNamed('body'),
      )).thenAnswer((_) async => mockResponse);

      when(mockTokenManager.saveToken(
        token: anyNamed('token'),
        tokenType: anyNamed('tokenType'),
        expiresAt: anyNamed('expiresAt'),
      )).thenAnswer((_) async => {});

      // Act
      final result = await authService.register(
        name: testName,
        email: testEmail,
        password: testPassword,
        groupCode: testGroupCode,
        role: 'user',
      );

      // Assert
      expect(result.user, isA<User>());
      expect(result.user.role, UserRole.user);
      expect(result.groupCode, isNull);

      verify(mockApiClient.post(
        '/auth/register',
        body: {
          'name': testName,
          'email': testEmail,
          'password': testPassword,
          'password_confirmation': testPassword,
          'role': 'user',
          'group_code': testGroupCode,
        },
      )).called(1);
    });

    test('should throw ApiException with invalid group code message', () async {
      // Arrange
      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/auth/register'),
        statusCode: 422,
        data: {
          'message': 'Validation failed',
          'errors': {
            'group_code': ['The selected group code is invalid.']
          },
        },
      );

      when(mockApiClient.post(
        '/auth/register',
        body: anyNamed('body'),
      )).thenAnswer((_) async => mockResponse);

      // Act & Assert
      try {
        await authService.register(
          name: testName,
          email: testEmail,
          password: testPassword,
          groupCode: 'INVALID',
          role: 'user',
        );
        fail('Should have thrown ApiException');
      } catch (e) {
        expect(e, isA<ApiException>());
        expect((e as ApiException).message, 'The selected group code is invalid');
        expect(e.statusCode, 422);
      }
    });

    test('should throw ApiException with required group code message', () async {
      // Arrange
      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/auth/register'),
        statusCode: 422,
        data: {
          'message': 'Validation failed',
          'errors': {
            'group_code': ['The group code field is required.']
          },
        },
      );

      when(mockApiClient.post(
        '/auth/register',
        body: anyNamed('body'),
      )).thenAnswer((_) async => mockResponse);

      // Act & Assert
      try {
        await authService.register(
          name: testName,
          email: testEmail,
          password: testPassword,
          role: 'user',
        );
        fail('Should have thrown ApiException');
      } catch (e) {
        expect(e, isA<ApiException>());
        expect((e as ApiException).message, 'The group code field is required');
        expect(e.statusCode, 422);
      }
    });

    test('should throw ApiException with already in group message', () async {
      // Arrange
      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/auth/register'),
        statusCode: 400,
        data: {
          'message': 'You are already in a group',
        },
      );

      when(mockApiClient.post(
        '/auth/register',
        body: anyNamed('body'),
      )).thenAnswer((_) async => mockResponse);

      // Act & Assert
      try {
        await authService.register(
          name: testName,
          email: testEmail,
          password: testPassword,
          groupCode: testGroupCode,
          role: 'user',
        );
        fail('Should have thrown ApiException');
      } catch (e) {
        expect(e, isA<ApiException>());
        expect((e as ApiException).message, 'You are already in a group');
        expect(e.statusCode, 400);
      }
    });

    test('should throw ApiException with admin cannot join message', () async {
      // Arrange
      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/auth/register'),
        statusCode: 400,
        data: {
          'message': 'Admins cannot join other groups',
        },
      );

      when(mockApiClient.post(
        '/auth/register',
        body: anyNamed('body'),
      )).thenAnswer((_) async => mockResponse);

      // Act & Assert
      try {
        await authService.register(
          name: testName,
          email: testEmail,
          password: testPassword,
          groupCode: testGroupCode,
          role: 'admin',
        );
        fail('Should have thrown ApiException');
      } catch (e) {
        expect(e, isA<ApiException>());
        expect((e as ApiException).message, 'Admins cannot join other groups');
        expect(e.statusCode, 400);
      }
    });

    test('should register with organization and department names', () async {
      // Arrange
      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/auth/register'),
        statusCode: 201,
        data: {
          'user': {
            'id': 1,
            'name': testName,
            'email': testEmail,
            'role': 'admin',
            'organization_name': 'Test Org',
            'department_name': 'Test Dept',
            'created_at': '2024-01-01T00:00:00Z',
          },
          'token': testToken,
          'token_type': 'Bearer',
          'expires_at': '2024-12-31T23:59:59Z',
          'group_code': testGroupCode,
        },
      );

      when(mockApiClient.post(
        '/auth/register',
        body: anyNamed('body'),
      )).thenAnswer((_) async => mockResponse);

      when(mockTokenManager.saveToken(
        token: anyNamed('token'),
        tokenType: anyNamed('tokenType'),
        expiresAt: anyNamed('expiresAt'),
      )).thenAnswer((_) async => {});

      // Act
      final result = await authService.register(
        name: testName,
        email: testEmail,
        password: testPassword,
        organizationName: 'Test Org',
        departmentName: 'Test Dept',
        role: 'admin',
      );

      // Assert
      expect(result.user, isA<User>());
      expect(result.groupCode, testGroupCode);

      verify(mockApiClient.post(
        '/auth/register',
        body: {
          'name': testName,
          'email': testEmail,
          'password': testPassword,
          'password_confirmation': testPassword,
          'role': 'admin',
          'organization_name': 'Test Org',
          'department_name': 'Test Dept',
        },
      )).called(1);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/api_exception.dart';
import 'package:finance_app/features/profile/data/datasources/profile_api_datasource.dart';
import 'package:finance_app/features/auth/domain/entities/user.dart';

@GenerateMocks([ApiClient])
import 'profile_api_datasource_test.mocks.dart';

void main() {
  late ProfileApiDataSourceImpl dataSource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = ProfileApiDataSourceImpl(apiClient: mockApiClient);
  });

  group('getProfile', () {
    test('should return User when API call is successful', () async {
      // Arrange
      final responseData = {
        'data': {
          'id': 1,
          'name': 'John Doe',
          'email': 'john@example.com',
          'role': 'user',
          'created_at': '2024-01-01T00:00:00.000000Z',
        }
      };

      when(mockApiClient.get('/profile')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/profile'),
          statusCode: 200,
          data: responseData,
        ),
      );

      // Act
      final result = await dataSource.getProfile();

      // Assert
      expect(result, isA<User>());
      expect(result.id, 1);
      expect(result.username, 'John Doe');
      expect(result.email, 'john@example.com');
      verify(mockApiClient.get('/profile')).called(1);
    });

    test('should throw ApiException when API returns error', () async {
      // Arrange
      when(mockApiClient.get('/profile')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/profile'),
          statusCode: 500,
          data: {'message': 'Internal server error'},
        ),
      );

      // Act & Assert
      expect(
        () => dataSource.getProfile(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('updateProfile', () {
    test('should return updated User when API call is successful', () async {
      // Arrange
      final responseData = {
        'data': {
          'id': 1,
          'name': 'Jane Doe',
          'email': 'jane@example.com',
          'role': 'user',
          'created_at': '2024-01-01T00:00:00.000000Z',
        }
      };

      when(mockApiClient.put(
        '/profile',
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/profile'),
          statusCode: 200,
          data: responseData,
        ),
      );

      // Act
      final result = await dataSource.updateProfile(
        name: 'Jane Doe',
        email: 'jane@example.com',
      );

      // Assert
      expect(result, isA<User>());
      expect(result.username, 'Jane Doe');
      expect(result.email, 'jane@example.com');

      // Verify request body
      final captured = verify(mockApiClient.put(
        '/profile',
        body: captureAnyNamed('body'),
      )).captured.single as Map<String, dynamic>;

      expect(captured['name'], 'Jane Doe');
      expect(captured['email'], 'jane@example.com');
    });

    test('should only send provided fields', () async {
      // Arrange
      final responseData = {
        'data': {
          'id': 1,
          'name': 'Jane Doe',
          'email': 'john@example.com',
          'role': 'user',
          'created_at': '2024-01-01T00:00:00.000000Z',
        }
      };

      when(mockApiClient.put(
        '/profile',
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/profile'),
          statusCode: 200,
          data: responseData,
        ),
      );

      // Act
      await dataSource.updateProfile(name: 'Jane Doe');

      // Assert
      final captured = verify(mockApiClient.put(
        '/profile',
        body: captureAnyNamed('body'),
      )).captured.single as Map<String, dynamic>;

      expect(captured['name'], 'Jane Doe');
      expect(captured.containsKey('email'), false);
    });

    test('should throw ApiException with 422 for validation errors', () async {
      // Arrange
      when(mockApiClient.put(
        '/profile',
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/profile'),
          statusCode: 422,
          data: {
            'message': 'Validation error',
            'errors': {
              'email': ['The email has already been taken.']
            }
          },
        ),
      );

      // Act & Assert
      expect(
        () => dataSource.updateProfile(email: 'taken@example.com'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.message, 'message', 'The email has already been taken.'),
        ),
      );
    });
  });

  group('changePassword', () {
    test('should complete successfully when API call succeeds', () async {
      // Arrange
      when(mockApiClient.put(
        '/profile/password',
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/profile/password'),
          statusCode: 200,
          data: {'message': 'Password changed successfully'},
        ),
      );

      // Act & Assert
      await expectLater(
        dataSource.changePassword(
          currentPassword: 'oldpass123',
          newPassword: 'newpass123',
        ),
        completes,
      );

      // Verify request body
      final captured = verify(mockApiClient.put(
        '/profile/password',
        body: captureAnyNamed('body'),
      )).captured.single as Map<String, dynamic>;

      expect(captured['current_password'], 'oldpass123');
      expect(captured['new_password'], 'newpass123');
      expect(captured['new_password_confirmation'], 'newpass123');
    });

    test('should throw ApiException with 401 for incorrect current password', () async {
      // Arrange
      when(mockApiClient.put(
        '/profile/password',
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/profile/password'),
          statusCode: 401,
          data: {'message': 'Current password is incorrect'},
        ),
      );

      // Act & Assert
      expect(
        () => dataSource.changePassword(
          currentPassword: 'wrongpass',
          newPassword: 'newpass123',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', 'Current password is incorrect'),
        ),
      );
    });

    test('should throw ApiException with 422 for validation errors', () async {
      // Arrange
      when(mockApiClient.put(
        '/profile/password',
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/profile/password'),
          statusCode: 422,
          data: {
            'message': 'Validation error',
            'errors': {
              'new_password': ['The new password must be at least 8 characters.']
            }
          },
        ),
      );

      // Act & Assert
      expect(
        () => dataSource.changePassword(
          currentPassword: 'oldpass123',
          newPassword: 'short',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 422),
        ),
      );
    });
  });

  group('deleteAccount', () {
    test('should complete successfully when API returns 200', () async {
      // Arrange
      when(mockApiClient.delete('/profile')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/profile'),
          statusCode: 200,
          data: {'message': 'Account deleted successfully'},
        ),
      );

      // Act & Assert
      await expectLater(
        dataSource.deleteAccount(),
        completes,
      );
      verify(mockApiClient.delete('/profile')).called(1);
    });

    test('should complete successfully when API returns 204', () async {
      // Arrange
      when(mockApiClient.delete('/profile')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/profile'),
          statusCode: 204,
          data: null,
        ),
      );

      // Act & Assert
      await expectLater(
        dataSource.deleteAccount(),
        completes,
      );
    });

    test('should throw ApiException when API returns error', () async {
      // Arrange
      when(mockApiClient.delete('/profile')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/profile'),
          statusCode: 500,
          data: {'message': 'Internal server error'},
        ),
      );

      // Act & Assert
      expect(
        () => dataSource.deleteAccount(),
        throwsA(isA<ApiException>()),
      );
    });
  });
}

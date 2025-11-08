import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/api_exception.dart';
import 'package:finance_app/features/admin_group/data/datasources/admin_group_api_datasource.dart';
import 'package:finance_app/features/admin_group/data/models/admin_group_dto.dart';
import 'package:finance_app/features/admin_group/data/models/group_member_dto.dart';
import 'package:finance_app/features/admin_group/data/models/group_info_dto.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'admin_group_api_datasource_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  late AdminGroupApiDataSourceImpl dataSource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = AdminGroupApiDataSourceImpl(apiClient: mockApiClient);
  });

  group('AdminGroupApiDataSource', () {
    group('getAdminGroup', () {
      test('should return AdminGroupDto when API call is successful', () async {
        // Arrange
        final responseData = {
          'data': {
            'id': 1,
            'admin_user_id': 10,
            'group_code': 'ABC123',
            'group_name': 'Test Group',
            'is_active': true,
            'members_count': 5,
            'created_at': '2024-01-01T00:00:00.000000Z',
            'updated_at': '2024-01-01T00:00:00.000000Z',
          },
        };

        when(mockApiClient.get(any)).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/admin/group'),
            statusCode: 200,
            data: responseData,
          ),
        );

        // Act
        final result = await dataSource.getAdminGroup();

        // Assert
        verify(mockApiClient.get('/admin/group'));
        expect(result.id, 1);
        expect(result.groupCode, 'ABC123');
        expect(result.groupName, 'Test Group');
        expect(result.membersCount, 5);
      });

      test('should handle unwrapped response', () async {
        // Arrange
        final responseData = {
          'id': 1,
          'admin_user_id': 10,
          'group_code': 'ABC123',
          'group_name': 'Test Group',
          'is_active': true,
          'members_count': 5,
          'created_at': '2024-01-01T00:00:00.000000Z',
          'updated_at': '2024-01-01T00:00:00.000000Z',
        };

        when(mockApiClient.get(any)).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/admin/group'),
            statusCode: 200,
            data: responseData,
          ),
        );

        // Act
        final result = await dataSource.getAdminGroup();

        // Assert
        expect(result.id, 1);
        expect(result.groupCode, 'ABC123');
      });

      test('should throw ApiException when status code is not 200', () async {
        // Arrange
        when(mockApiClient.get(any)).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/admin/group'),
            statusCode: 403,
            data: {},
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getAdminGroup(),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('regenerateGroupCode', () {
      test('should return AdminGroupDto with new code', () async {
        // Arrange
        final responseData = {
          'data': {
            'id': 1,
            'admin_user_id': 10,
            'group_code': 'XYZ789',
            'group_name': 'Test Group',
            'is_active': true,
            'members_count': 5,
            'created_at': '2024-01-01T00:00:00.000000Z',
            'updated_at': '2024-01-02T00:00:00.000000Z',
          },
        };

        when(mockApiClient.post(any)).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/admin/group/regenerate'),
            statusCode: 200,
            data: responseData,
          ),
        );

        // Act
        final result = await dataSource.regenerateGroupCode();

        // Assert
        verify(mockApiClient.post('/admin/group/regenerate'));
        expect(result.groupCode, 'XYZ789');
      });

      test('should accept 201 status code', () async {
        // Arrange
        final responseData = {
          'data': {
            'id': 1,
            'admin_user_id': 10,
            'group_code': 'NEW123',
            'group_name': 'Test Group',
            'is_active': true,
            'created_at': '2024-01-01T00:00:00.000000Z',
            'updated_at': '2024-01-02T00:00:00.000000Z',
          },
        };

        when(mockApiClient.post(any)).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/admin/group/regenerate'),
            statusCode: 201,
            data: responseData,
          ),
        );

        // Act
        final result = await dataSource.regenerateGroupCode();

        // Assert
        expect(result.groupCode, 'NEW123');
      });
    });

    group('getGroupMembers', () {
      test('should return paginated list of members', () async {
        // Arrange
        final responseData = {
          'data': [
            {
              'id': 1,
              'name': 'John Doe',
              'email': 'john@example.com',
              'role': 'user',
              'organization_name': 'Org 1',
              'department_name': 'IT',
              'created_at': '2024-01-01T00:00:00.000000Z',
            },
            {
              'id': 2,
              'name': 'Jane Smith',
              'email': 'jane@example.com',
              'role': 'user',
              'organization_name': 'Org 1',
              'department_name': 'HR',
              'created_at': '2024-01-02T00:00:00.000000Z',
            },
          ],
          'current_page': 1,
          'last_page': 1,
          'per_page': 15,
          'total': 2,
        };

        when(mockApiClient.get(any, queryParams: anyNamed('queryParams')))
            .thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/admin/group/members'),
            statusCode: 200,
            data: responseData,
          ),
        );

        // Act
        final result = await dataSource.getGroupMembers();

        // Assert
        verify(mockApiClient.get('/admin/group/members', queryParams: anyNamed('queryParams')));
        expect(result.data.length, 2);
        expect(result.data[0].name, 'John Doe');
        expect(result.data[1].name, 'Jane Smith');
        expect(result.currentPage, 1);
        expect(result.total, 2);
      });

      test('should include pagination parameters in query', () async {
        // Arrange
        final responseData = {
          'data': [],
          'current_page': 2,
          'last_page': 5,
          'per_page': 25,
          'total': 100,
        };

        when(mockApiClient.get(any, queryParams: anyNamed('queryParams')))
            .thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/admin/group/members'),
            statusCode: 200,
            data: responseData,
          ),
        );

        // Act
        await dataSource.getGroupMembers(page: 2, perPage: 25);

        // Assert
        final captured = verify(mockApiClient.get(
          '/admin/group/members',
          queryParams: captureAnyNamed('queryParams'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['page'], 2);
        expect(captured['per_page'], 25);
      });

      test('should include search parameter when provided', () async {
        // Arrange
        final responseData = {
          'data': [],
          'current_page': 1,
          'last_page': 1,
          'per_page': 15,
          'total': 0,
        };

        when(mockApiClient.get(any, queryParams: anyNamed('queryParams')))
            .thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/admin/group/members'),
            statusCode: 200,
            data: responseData,
          ),
        );

        // Act
        await dataSource.getGroupMembers(search: 'john');

        // Assert
        final captured = verify(mockApiClient.get(
          '/admin/group/members',
          queryParams: captureAnyNamed('queryParams'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['search'], 'john');
      });

      test('should include department filter when provided', () async {
        // Arrange
        final responseData = {
          'data': [],
          'current_page': 1,
          'last_page': 1,
          'per_page': 15,
          'total': 0,
        };

        when(mockApiClient.get(any, queryParams: anyNamed('queryParams')))
            .thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/admin/group/members'),
            statusCode: 200,
            data: responseData,
          ),
        );

        // Act
        await dataSource.getGroupMembers(department: 'IT');

        // Assert
        final captured = verify(mockApiClient.get(
          '/admin/group/members',
          queryParams: captureAnyNamed('queryParams'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['department'], 'IT');
      });

      test('should not include empty search or department', () async {
        // Arrange
        final responseData = {
          'data': [],
          'current_page': 1,
          'last_page': 1,
          'per_page': 15,
          'total': 0,
        };

        when(mockApiClient.get(any, queryParams: anyNamed('queryParams')))
            .thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/admin/group/members'),
            statusCode: 200,
            data: responseData,
          ),
        );

        // Act
        await dataSource.getGroupMembers(search: '', department: '');

        // Assert
        final captured = verify(mockApiClient.get(
          '/admin/group/members',
          queryParams: captureAnyNamed('queryParams'),
        )).captured.single as Map<String, dynamic>;

        expect(captured.containsKey('search'), false);
        expect(captured.containsKey('department'), false);
      });
    });

    group('removeMember', () {
      test('should call delete endpoint with user ID', () async {
        // Arrange
        when(mockApiClient.delete(any)).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/admin/group/members/123'),
            statusCode: 200,
            data: {},
          ),
        );

        // Act
        await dataSource.removeMember(123);

        // Assert
        verify(mockApiClient.delete('/admin/group/members/123'));
      });

      test('should accept 204 status code', () async {
        // Arrange
        when(mockApiClient.delete(any)).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/admin/group/members/123'),
            statusCode: 204,
            data: null,
          ),
        );

        // Act & Assert
        expect(() => dataSource.removeMember(123), returnsNormally);
      });

      test('should throw ApiException for 403 forbidden', () async {
        // Arrange
        when(mockApiClient.delete(any)).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/admin/group/members/123'),
            statusCode: 403,
            data: {'message': 'Cannot remove yourself'},
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.removeMember(123),
          throwsA(isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Cannot remove yourself',
          )),
        );
      });

      test('should throw ApiException for 404 not found', () async {
        // Arrange
        when(mockApiClient.delete(any)).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/admin/group/members/123'),
            statusCode: 404,
            data: {},
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.removeMember(123),
          throwsA(isA<ApiException>().having(
            (e) => e.message,
            'message',
            'User not found or not in your group',
          )),
        );
      });
    });

    group('joinGroup', () {
      test('should send group code in request body', () async {
        // Arrange
        final responseData = {
          'data': {
            'group_code': 'ABC123',
            'group_name': 'Test Group',
            'admin_name': 'Admin User',
            'admin_email': 'admin@example.com',
            'members_count': 5,
            'joined_at': '2024-01-01T00:00:00.000000Z',
          },
        };

        when(mockApiClient.post(any, body: anyNamed('body'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/user/join-group'),
            statusCode: 200,
            data: responseData,
          ),
        );

        // Act
        final result = await dataSource.joinGroup('ABC123');

        // Assert
        final captured = verify(mockApiClient.post(
          '/user/join-group',
          body: captureAnyNamed('body'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['group_code'], 'ABC123');
        expect(result.groupCode, 'ABC123');
        expect(result.groupName, 'Test Group');
      });

      test('should accept 201 status code', () async {
        // Arrange
        final responseData = {
          'data': {
            'group_code': 'ABC123',
            'group_name': 'Test Group',
            'admin_name': 'Admin User',
            'admin_email': 'admin@example.com',
            'members_count': 5,
            'joined_at': '2024-01-01T00:00:00.000000Z',
          },
        };

        when(mockApiClient.post(any, body: anyNamed('body'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/user/join-group'),
            statusCode: 201,
            data: responseData,
          ),
        );

        // Act
        final result = await dataSource.joinGroup('ABC123');

        // Assert
        expect(result.groupCode, 'ABC123');
      });

      test('should throw ApiException for 422 validation error', () async {
        // Arrange
        when(mockApiClient.post(any, body: anyNamed('body'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/user/join-group'),
            statusCode: 422,
            data: {'message': 'Invalid group code'},
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.joinGroup('INVALID'),
          throwsA(isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Invalid group code',
          )),
        );
      });

      test('should throw ApiException for 400 bad request', () async {
        // Arrange
        when(mockApiClient.post(any, body: anyNamed('body'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/user/join-group'),
            statusCode: 400,
            data: {'message': 'Already in a group'},
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.joinGroup('ABC123'),
          throwsA(isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Already in a group',
          )),
        );
      });
    });

    group('getUserGroupInfo', () {
      test('should return GroupInfoDto when user is in a group', () async {
        // Arrange
        final responseData = {
          'data': {
            'group_code': 'ABC123',
            'group_name': 'Test Group',
            'admin_name': 'Admin User',
            'admin_email': 'admin@example.com',
            'members_count': 5,
            'joined_at': '2024-01-01T00:00:00.000000Z',
          },
        };

        when(mockApiClient.get(any)).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/user/group-info'),
            statusCode: 200,
            data: responseData,
          ),
        );

        // Act
        final result = await dataSource.getUserGroupInfo();

        // Assert
        verify(mockApiClient.get('/user/group-info'));
        expect(result.groupCode, 'ABC123');
        expect(result.adminName, 'Admin User');
        expect(result.membersCount, 5);
      });

      test('should handle unwrapped response', () async {
        // Arrange
        final responseData = {
          'group_code': 'ABC123',
          'group_name': 'Test Group',
          'admin_name': 'Admin User',
          'admin_email': 'admin@example.com',
          'members_count': 5,
          'joined_at': '2024-01-01T00:00:00.000000Z',
        };

        when(mockApiClient.get(any)).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/user/group-info'),
            statusCode: 200,
            data: responseData,
          ),
        );

        // Act
        final result = await dataSource.getUserGroupInfo();

        // Assert
        expect(result.groupCode, 'ABC123');
      });

      test('should throw ApiException for 404 when user not in group', () async {
        // Arrange
        when(mockApiClient.get(any)).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/user/group-info'),
            statusCode: 404,
            data: {},
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getUserGroupInfo(),
          throwsA(isA<ApiException>().having(
            (e) => e.message,
            'message',
            'You are not in any group',
          )),
        );
      });
    });
  });
}

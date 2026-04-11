import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/api_response.dart';
import 'package:finance_app/features/superadmin/data/datasources/superadmin_group_api_datasource.dart';

import 'superadmin_group_api_datasource_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  late SuperAdminGroupApiDatasource datasource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    datasource = SuperAdminGroupApiDatasource(apiClient: mockApiClient);
  });

  group('SuperAdminGroupApiDatasource', () {
    group('getGroupInfo', () {
      test('should fetch group info with Bearer token', () async {
        // Arrange
        final responseData = {
          'data': {
            'id': 1,
            'name': 'Test Group',
            'group_code': '123456',
            'member_count': 5,
            'created_at': '2024-11-16T10:00:00Z',
          },
        };

        when(mockApiClient.get(any)).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        final result = await datasource.getGroupInfo();

        // Assert
        verify(mockApiClient.get('/super-admin/group')).called(1);
        expect(result.id, 1);
        expect(result.name, 'Test Group');
        expect(result.groupCode, '123456');
        expect(result.memberCount, 5);
      });
    });

    group('getMembers', () {
      test('should fetch members with pagination', () async {
        // Arrange
        final responseData = {
          'data': [
            {
              'id': 1,
              'name': 'Admin 1',
              'email': 'admin1@test.com',
              'joined_at': '2024-11-16T10:00:00Z',
            },
            {
              'id': 2,
              'name': 'Admin 2',
              'email': 'admin2@test.com',
              'joined_at': '2024-11-15T10:00:00Z',
            },
          ],
          'meta': {
            'current_page': 1,
            'per_page': 10,
            'total': 2,
          },
        };

        when(mockApiClient.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        final result = await datasource.getMembers(page: 1, perPage: 10);

        // Assert
        verify(mockApiClient.get(
          '/super-admin/group/members',
          queryParams: {'page': 1, 'per_page': 10},
        )).called(1);
        expect(result.length, 2);
        expect(result[0].name, 'Admin 1');
      });

      test('should use default pagination values', () async {
        // Arrange
        final responseData = {
          'data': [],
        };

        when(mockApiClient.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        await datasource.getMembers();

        // Assert
        verify(mockApiClient.get(
          '/super-admin/group/members',
          queryParams: {'page': 1, 'per_page': 20},
        )).called(1);
      });
    });

    group('regenerateCode', () {
      test('should regenerate group code', () async {
        // Arrange
        final responseData = {
          'data': {
            'group_code': '654321',
            'message': 'Group code regenerated successfully',
          },
        };

        when(mockApiClient.post(any)).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        final result = await datasource.regenerateCode();

        // Assert
        verify(mockApiClient.post('/super-admin/group/regenerate-code')).called(1);
        expect(result, '654321');
      });
    });

    group('removeMember', () {
      test('should remove member by ID', () async {
        // Arrange
        final responseData = {
          'message': 'Member removed successfully',
        };

        when(mockApiClient.delete(any)).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        await datasource.removeMember(5);

        // Assert
        verify(mockApiClient.delete('/super-admin/group/members/5')).called(1);
      });

      test('should throw exception when member not found', () async {
        // Arrange
        when(mockApiClient.delete(any)).thenAnswer((_) async => ApiResponse(
              statusCode: 404,
              data: {'message': 'Member not found'},
            ));

        // Act & Assert
        expect(
          () => datasource.removeMember(999),
          throwsException,
        );
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/api_response.dart';
import 'package:finance_app/features/organizations/data/datasources/organizations_api_datasource.dart';

import 'organizations_api_datasource_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  late OrganizationsApiDatasource datasource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    datasource = OrganizationsApiDatasource(apiClient: mockApiClient);
  });

  group('OrganizationsApiDatasource', () {
    group('getOrganizations', () {
      test('should fetch organizations without Bearer token (public endpoint)', () async {
        // Arrange
        final responseData = {
          'data': [
            {
              'id': 1,
              'name': 'Organization A',
              'code': 'ORG_A',
            },
            {
              'id': 2,
              'name': 'Organization B',
              'code': 'ORG_B',
            },
          ],
        };

        when(mockApiClient.get(any)).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        final result = await datasource.getOrganizations();

        // Assert
        verify(mockApiClient.get('/organizations')).called(1);
        expect(result.length, 2);
        expect(result[0].name, 'Organization A');
        expect(result[1].name, 'Organization B');
      });

      test('should handle empty organizations list', () async {
        // Arrange
        final responseData = {
          'data': [],
        };

        when(mockApiClient.get(any)).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        final result = await datasource.getOrganizations();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('getDepartments', () {
      test('should fetch departments for organization without Bearer token', () async {
        // Arrange
        final responseData = {
          'data': [
            {
              'id': 1,
              'organization_id': 1,
              'name': 'Department A',
              'code': 'DEPT_A',
            },
            {
              'id': 2,
              'organization_id': 1,
              'name': 'Department B',
              'code': 'DEPT_B',
            },
          ],
        };

        when(mockApiClient.get(any)).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        final result = await datasource.getDepartments(1);

        // Assert
        verify(mockApiClient.get('/organizations/1/departments')).called(1);
        expect(result.length, 2);
        expect(result[0].name, 'Department A');
        expect(result[0].organizationId, 1);
      });

      test('should handle organization with no departments', () async {
        // Arrange
        final responseData = {
          'data': [],
        };

        when(mockApiClient.get(any)).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        final result = await datasource.getDepartments(5);

        // Assert
        verify(mockApiClient.get('/organizations/5/departments')).called(1);
        expect(result, isEmpty);
      });

      test('should throw exception when organization not found', () async {
        // Arrange
        when(mockApiClient.get(any)).thenAnswer((_) async => ApiResponse(
              statusCode: 404,
              data: {'message': 'Organization not found'},
            ));

        // Act & Assert
        expect(
          () => datasource.getDepartments(999),
          throwsException,
        );
      });
    });
  });
}

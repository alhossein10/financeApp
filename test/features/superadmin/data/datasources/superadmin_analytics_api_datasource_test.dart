import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/api_response.dart';
import 'package:finance_app/features/superadmin/data/datasources/superadmin_analytics_api_datasource.dart';
import 'package:finance_app/features/superadmin/data/models/superadmin_analytics_dto.dart';

import 'superadmin_analytics_api_datasource_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  late SuperAdminAnalyticsApiDatasource datasource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    datasource = SuperAdminAnalyticsApiDatasource(apiClient: mockApiClient);
  });

  group('SuperAdminAnalyticsApiDatasource', () {
    group('getAnalytics', () {
      test('should fetch analytics with Bearer token for 15days period', () async {
        // Arrange
        final responseData = {
          'data': {
            'period': '15days',
            'admin_groups': [
              {
                'admin_group_id': 1,
                'admin_group_name': 'Group A',
                'total_transfers': 10,
                'total_transfer_amount': 5000.0,
                'total_expenses': 20,
                'total_expense_amount': 3000.0,
              },
            ],
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
        final result = await datasource.getAnalytics(period: '15days');

        // Assert
        verify(mockApiClient.get(
          '/super-admin/analytics',
          queryParams: {'period': '15days'},
        )).called(1);
        expect(result.period, '15days');
        expect(result.adminGroups.length, 1);
        expect(result.adminGroups[0].adminGroupName, 'Group A');
      });

      test('should fetch analytics for month period', () async {
        // Arrange
        final responseData = {
          'data': {
            'period': 'month',
            'admin_groups': [],
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
        final result = await datasource.getAnalytics(period: 'month');

        // Assert
        verify(mockApiClient.get(
          '/super-admin/analytics',
          queryParams: {'period': 'month'},
        )).called(1);
        expect(result.period, 'month');
      });

      test('should fetch analytics for all period', () async {
        // Arrange
        final responseData = {
          'data': {
            'period': 'all',
            'admin_groups': [],
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
        final result = await datasource.getAnalytics(period: 'all');

        // Assert
        verify(mockApiClient.get(
          '/super-admin/analytics',
          queryParams: {'period': 'all'},
        )).called(1);
        expect(result.period, 'all');
      });

      test('should throw ArgumentError for invalid period', () async {
        // Act & Assert
        expect(
          () => datasource.getAnalytics(period: 'invalid'),
          throwsArgumentError,
        );
        verifyNever(mockApiClient.get(any, queryParams: anyNamed('queryParams')));
      });

      test('should handle response without data wrapper', () async {
        // Arrange
        final responseData = {
          'period': '15days',
          'admin_groups': [],
        };

        when(mockApiClient.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        final result = await datasource.getAnalytics(period: '15days');

        // Assert
        expect(result.period, '15days');
        expect(result.adminGroups, isEmpty);
      });

      test('should throw exception on non-200 status code', () async {
        // Arrange
        when(mockApiClient.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => ApiResponse(
              statusCode: 500,
              data: {'message': 'Server error'},
            ));

        // Act & Assert
        expect(
          () => datasource.getAnalytics(period: '15days'),
          throwsException,
        );
      });

      test('should throw exception on invalid response format', () async {
        // Arrange
        when(mockApiClient.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: 'invalid response',
            ));

        // Act & Assert
        expect(
          () => datasource.getAnalytics(period: '15days'),
          throwsException,
        );
      });
    });
  });
}

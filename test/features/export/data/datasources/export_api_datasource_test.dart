import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/api_exception.dart';
import 'package:finance_app/features/export/data/datasources/export_api_datasource.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late ExportApiDataSourceImpl dataSource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = ExportApiDataSourceImpl(apiClient: mockApiClient);
  });

  group('ExportApiDataSource', () {
    group('exportExpensesToPdf', () {
      test('should call POST /export/expenses/pdf with correct body', () async {
        // Arrange
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 12, 31);
        
        final responseData = {
          'success': true,
          'data': {
            'id': 1,
            'format': 'pdf',
            'status': 'processing',
            'download_url': null,
          },
        };

        when(() => mockApiClient.post(
              any(),
              body: any(named: 'body'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: responseData,
              statusCode: 200,
            ));

        // Act
        final result = await dataSource.exportExpensesToPdf(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        verify(() => mockApiClient.post(
              '/export/expenses/pdf',
              body: {
                'format': 'pdf',
                'date_from': '2024-01-01',
                'date_to': '2024-12-31',
              },
            )).called(1);

        expect(result.id, 1);
        expect(result.format, 'pdf');
        expect(result.status, 'processing');
      });

      test('should handle API exception', () async {
        // Arrange
        when(() => mockApiClient.post(
              any(),
              body: any(named: 'body'),
            )).thenThrow(ApiException(
              statusCode: 500,
              message: 'Server error',
            ));

        // Act & Assert
        expect(
          () => dataSource.exportExpensesToPdf(),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('exportExpensesToExcel', () {
      test('should call POST /export/expenses/excel with correct body', () async {
        // Arrange
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 12, 31);
        
        final responseData = {
          'success': true,
          'data': {
            'id': 2,
            'format': 'excel',
            'status': 'processing',
            'download_url': null,
          },
        };

        when(() => mockApiClient.post(
              any(),
              body: any(named: 'body'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: responseData,
              statusCode: 200,
            ));

        // Act
        final result = await dataSource.exportExpensesToExcel(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        verify(() => mockApiClient.post(
              '/export/expenses/excel',
              body: {
                'format': 'excel',
                'date_from': '2024-01-01',
                'date_to': '2024-12-31',
              },
            )).called(1);

        expect(result.id, 2);
        expect(result.format, 'excel');
        expect(result.status, 'processing');
      });
    });

    group('getExportStatus', () {
      test('should throw ApiException with 501 status', () async {
        // Act & Assert
        expect(
          () => dataSource.getExportStatus('1'),
          throwsA(isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            501,
          )),
        );
      });
    });
  });
}

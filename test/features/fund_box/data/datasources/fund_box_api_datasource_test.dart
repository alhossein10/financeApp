import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/api_exception.dart';
import 'package:finance_app/features/fund_box/data/datasources/fund_box_api_datasource.dart';
import 'package:finance_app/features/fund_box/data/models/fund_box_dto.dart';

@GenerateMocks([ApiClient])
import 'fund_box_api_datasource_test.mocks.dart';

void main() {
  late FundBoxApiDataSourceImpl dataSource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = FundBoxApiDataSourceImpl(apiClient: mockApiClient);
  });

  group('getFundBox', () {
    test('should return FundBoxDto when API call is successful', () async {
      // Arrange
      final responseData = {
        'data': {
          'id': 1,
          'total_balance': 15000.0,
          'last_updated': '2024-10-23T10:00:00.000000Z',
        }
      };
      
      when(mockApiClient.get('/fund-box')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/fund-box'),
          statusCode: 200,
          data: responseData,
        ),
      );

      // Act
      final result = await dataSource.getFundBox();

      // Assert
      expect(result, isA<FundBoxDto>());
      expect(result.id, 1);
      expect(result.totalBalance, 15000.0);
      verify(mockApiClient.get('/fund-box')).called(1);
    });

    test('should throw ApiException with 403 when user lacks admin privileges', () async {
      // Arrange
      when(mockApiClient.get('/fund-box')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/fund-box'),
          statusCode: 403,
          data: {'message': 'Forbidden'},
        ),
      );

      // Act & Assert
      expect(
        () => dataSource.getFundBox(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', 'Access denied. Admin privileges required.'),
        ),
      );
    });

    test('should throw ApiException when API returns error', () async {
      // Arrange
      when(mockApiClient.get('/fund-box')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/fund-box'),
          statusCode: 500,
          data: {'message': 'Internal server error'},
        ),
      );

      // Act & Assert
      expect(
        () => dataSource.getFundBox(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('updateFundBox', () {
    test('should return updated FundBoxDto when API call is successful', () async {
      // Arrange
      const newBalance = 20000.0;
      final responseData = {
        'data': {
          'id': 1,
          'total_balance': newBalance,
          'last_updated': '2024-10-23T11:00:00.000000Z',
        }
      };
      
      when(mockApiClient.put(
        '/fund-box',
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/fund-box'),
          statusCode: 200,
          data: responseData,
        ),
      );

      // Act
      final result = await dataSource.updateFundBox(newBalance);

      // Assert
      expect(result, isA<FundBoxDto>());
      expect(result.totalBalance, newBalance);
      
      // Verify both fields are sent
      final captured = verify(mockApiClient.put(
        '/fund-box',
        body: captureAnyNamed('body'),
      )).captured.single as Map<String, dynamic>;
      
      expect(captured['total_balance'], newBalance);
      expect(captured['balance_usd'], newBalance);
    });

    test('should throw ApiException with 403 when user lacks admin privileges', () async {
      // Arrange
      when(mockApiClient.put(
        '/fund-box',
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/fund-box'),
          statusCode: 403,
          data: {'message': 'Forbidden'},
        ),
      );

      // Act & Assert
      expect(
        () => dataSource.updateFundBox(20000.0),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', 'Access denied. Admin privileges required.'),
        ),
      );
    });

    test('should throw ApiException with 422 for validation errors', () async {
      // Arrange
      when(mockApiClient.put(
        '/fund-box',
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/fund-box'),
          statusCode: 422,
          data: {
            'message': 'Validation error',
            'errors': {
              'total_balance': ['The total balance must be a positive number.']
            }
          },
        ),
      );

      // Act & Assert
      expect(
        () => dataSource.updateFundBox(-1000.0),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.message, 'message', 'Validation error'),
        ),
      );
    });
  });
}

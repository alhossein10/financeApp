import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/api_response.dart';
import 'package:finance_app/core/api/api_exception.dart';
import 'package:finance_app/features/exchanges/data/datasources/exchange_api_datasource.dart';
import 'package:finance_app/features/exchanges/data/models/exchange_dto.dart';

import 'exchange_api_datasource_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  late ExchangeApiDataSourceImpl datasource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    datasource = ExchangeApiDataSourceImpl(apiClient: mockApiClient);
  });

  group('ExchangeApiDataSource', () {
    group('createExchange', () {
      test('should create exchange with exchangeRate', () async {
        // Arrange
        final responseData = {
          'data': {
            'id': 1,
            'target_currency': 'SYP',
            'amount_usd': 100.0,
            'exchange_rate': 15000.0,
            'converted_amount': 1500000.0,
            'exchange_date': '2024-11-16',
            'created_at': '2024-11-16T10:00:00Z',
          },
        };

        when(mockApiClient.post(any, body: anyNamed('body')))
            .thenAnswer((_) async => ApiResponse(
                  statusCode: 201,
                  data: responseData,
                ));

        // Act
        final result = await datasource.createExchange(
          targetCurrency: 'SYP',
          amountUsd: 100.0,
          exchangeRate: 15000.0,
          exchangeDate: '2024-11-16',
        );

        // Assert
        final captured = verify(mockApiClient.post(
          '/exchanges',
          body: captureAnyNamed('body'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['target_currency'], 'SYP');
        expect(captured['amount_usd'], 100.0);
        expect(captured['exchange_rate'], 15000.0);
        expect(captured['exchange_date'], '2024-11-16');
        expect(captured.containsKey('transfer_id'), false);
        expect(result.id, 1);
        expect(result.targetCurrency, 'SYP');
      });

      test('should create exchange with convertedAmount', () async {
        // Arrange
        final responseData = {
          'data': {
            'id': 2,
            'target_currency': 'TRY',
            'amount_usd': 100.0,
            'exchange_rate': 30.0,
            'converted_amount': 3000.0,
            'exchange_date': '2024-11-16',
            'created_at': '2024-11-16T10:00:00Z',
          },
        };

        when(mockApiClient.post(any, body: anyNamed('body')))
            .thenAnswer((_) async => ApiResponse(
                  statusCode: 201,
                  data: responseData,
                ));

        // Act
        final result = await datasource.createExchange(
          targetCurrency: 'TRY',
          amountUsd: 100.0,
          convertedAmount: 3000.0,
          exchangeDate: '2024-11-16',
        );

        // Assert
        final captured = verify(mockApiClient.post(
          '/exchanges',
          body: captureAnyNamed('body'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['converted_amount'], 3000.0);
        expect(captured.containsKey('exchange_rate'), false);
        expect(result.convertedAmount, 3000.0);
      });

      test('should create exchange with optional transferId', () async {
        // Arrange
        final responseData = {
          'data': {
            'id': 3,
            'transfer_id': 5,
            'target_currency': 'SYP',
            'amount_usd': 100.0,
            'exchange_rate': 15000.0,
            'converted_amount': 1500000.0,
            'exchange_date': '2024-11-16',
            'created_at': '2024-11-16T10:00:00Z',
          },
        };

        when(mockApiClient.post(any, body: anyNamed('body')))
            .thenAnswer((_) async => ApiResponse(
                  statusCode: 201,
                  data: responseData,
                ));

        // Act
        final result = await datasource.createExchange(
          transferId: 5,
          targetCurrency: 'SYP',
          amountUsd: 100.0,
          exchangeRate: 15000.0,
          exchangeDate: '2024-11-16',
        );

        // Assert
        final captured = verify(mockApiClient.post(
          '/exchanges',
          body: captureAnyNamed('body'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['transfer_id'], 5);
        expect(result.transferId, 5);
      });

      test('should include notes when provided', () async {
        // Arrange
        final responseData = {
          'data': {
            'id': 4,
            'target_currency': 'SYP',
            'amount_usd': 100.0,
            'exchange_rate': 15000.0,
            'converted_amount': 1500000.0,
            'exchange_date': '2024-11-16',
            'notes': 'Test exchange',
            'created_at': '2024-11-16T10:00:00Z',
          },
        };

        when(mockApiClient.post(any, body: anyNamed('body')))
            .thenAnswer((_) async => ApiResponse(
                  statusCode: 201,
                  data: responseData,
                ));

        // Act
        await datasource.createExchange(
          targetCurrency: 'SYP',
          amountUsd: 100.0,
          exchangeRate: 15000.0,
          exchangeDate: '2024-11-16',
          notes: 'Test exchange',
        );

        // Assert
        final captured = verify(mockApiClient.post(
          '/exchanges',
          body: captureAnyNamed('body'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['notes'], 'Test exchange');
      });

      test('should throw ApiException when neither exchangeRate nor convertedAmount provided',
          () async {
        // Act & Assert
        expect(
          () => datasource.createExchange(
            targetCurrency: 'SYP',
            amountUsd: 100.0,
            exchangeDate: '2024-11-16',
          ),
          throwsA(isA<ApiException>()),
        );
        verifyNever(mockApiClient.post(any, body: anyNamed('body')));
      });
    });

    group('getAllExchanges', () {
      test('should fetch all exchanges without currency filter', () async {
        // Arrange
        final responseData = {
          'data': [
            {
              'id': 1,
              'target_currency': 'SYP',
              'amount_usd': 100.0,
              'exchange_rate': 15000.0,
              'exchange_date': '2024-11-16',
              'created_at': '2024-11-16T10:00:00Z',
            },
          ],
        };

        when(mockApiClient.get(any)).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        final result = await datasource.getAllExchanges();

        // Assert
        verify(mockApiClient.get('/exchanges')).called(1);
        expect(result.length, 1);
        expect(result[0].targetCurrency, 'SYP');
      });

      test('should fetch exchanges with SYP currency filter', () async {
        // Arrange
        final responseData = {
          'data': [
            {
              'id': 1,
              'target_currency': 'SYP',
              'amount_usd': 100.0,
              'exchange_rate': 15000.0,
              'exchange_date': '2024-11-16',
              'created_at': '2024-11-16T10:00:00Z',
            },
          ],
        };

        when(mockApiClient.get(any)).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        final result = await datasource.getAllExchanges(currency: 'SYP');

        // Assert
        verify(mockApiClient.get('/exchanges?currency=SYP')).called(1);
        expect(result.length, 1);
      });

      test('should fetch exchanges with TRY currency filter', () async {
        // Arrange
        final responseData = {
          'data': [],
        };

        when(mockApiClient.get(any)).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        final result = await datasource.getAllExchanges(currency: 'TRY');

        // Assert
        verify(mockApiClient.get('/exchanges?currency=TRY')).called(1);
        expect(result, isEmpty);
      });

      test('should not add currency filter for "all"', () async {
        // Arrange
        final responseData = {'data': []};

        when(mockApiClient.get(any)).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        await datasource.getAllExchanges(currency: 'all');

        // Assert
        verify(mockApiClient.get('/exchanges')).called(1);
      });
    });

    group('getExchangeById', () {
      test('should fetch exchange by ID', () async {
        // Arrange
        final responseData = {
          'data': {
            'id': 1,
            'target_currency': 'SYP',
            'amount_usd': 100.0,
            'exchange_rate': 15000.0,
            'exchange_date': '2024-11-16',
            'created_at': '2024-11-16T10:00:00Z',
          },
        };

        when(mockApiClient.get(any)).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        final result = await datasource.getExchangeById(1);

        // Assert
        verify(mockApiClient.get('/exchanges/1')).called(1);
        expect(result.id, 1);
      });

      test('should throw ApiException when exchange not found', () async {
        // Arrange
        when(mockApiClient.get(any)).thenAnswer((_) async => ApiResponse(
              statusCode: 404,
              data: {'message': 'Exchange not found'},
            ));

        // Act & Assert
        expect(
          () => datasource.getExchangeById(999),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('getExchangesByTransfer', () {
      test('should fetch exchanges for a transfer', () async {
        // Arrange
        final responseData = {
          'data': [
            {
              'id': 1,
              'transfer_id': 5,
              'target_currency': 'SYP',
              'amount_usd': 100.0,
              'exchange_rate': 15000.0,
              'exchange_date': '2024-11-16',
              'created_at': '2024-11-16T10:00:00Z',
            },
          ],
        };

        when(mockApiClient.get(any)).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        final result = await datasource.getExchangesByTransfer(5);

        // Assert
        verify(mockApiClient.get('/exchanges/transfer/5')).called(1);
        expect(result.length, 1);
        expect(result[0].transferId, 5);
      });
    });

    group('getTransferBalance', () {
      test('should fetch transfer balance info', () async {
        // Arrange
        final responseData = {
          'data': {
            'transfer_id': 5,
            'original_amount': 1000.0,
            'exchanged_amount': 300.0,
            'remaining_amount': 700.0,
          },
        };

        when(mockApiClient.get(any)).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        final result = await datasource.getTransferBalance(5);

        // Assert
        verify(mockApiClient.get('/exchanges/transfer/5/balance')).called(1);
        expect(result.transferId, 5);
        expect(result.originalAmount, 1000.0);
        expect(result.exchangedAmount, 300.0);
        expect(result.remainingAmount, 700.0);
      });
    });
  });
}

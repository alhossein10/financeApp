import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:finance_app/features/exchanges/data/datasources/exchange_api_datasource.dart';
import 'package:finance_app/features/exchanges/data/repositories/exchange_repository_impl.dart';
import 'package:finance_app/features/exchanges/data/models/exchange_dto.dart';
import 'package:finance_app/core/error/failures.dart';
import 'package:dartz/dartz.dart';

import 'exchange_repository_impl_test.mocks.dart';

@GenerateMocks([ExchangeApiDataSourceImpl])
void main() {
  late ExchangeRepositoryImpl repository;
  late MockExchangeApiDataSourceImpl mockDatasource;

  setUp(() {
    mockDatasource = MockExchangeApiDataSourceImpl();
    repository = ExchangeRepositoryImpl(apiDatasource: mockDatasource);
  });

  group('ExchangeRepositoryImpl', () {
    group('createExchange', () {
      test('should return exchange when creation is successful', () async {
        // Arrange
        final exchangeDto = ExchangeDto(
          id: 1,
          targetCurrency: 'SYP',
          amountUsd: 100.0,
          exchangeRate: 15000.0,
          convertedAmount: 1500000.0,
          exchangeDate: '2024-11-16',
          createdAt: '2024-11-16T10:00:00Z',
        );

        when(mockDatasource.createExchange(
          targetCurrency: anyNamed('targetCurrency'),
          amountUsd: anyNamed('amountUsd'),
          exchangeRate: anyNamed('exchangeRate'),
          exchangeDate: anyNamed('exchangeDate'),
        )).thenAnswer((_) async => exchangeDto);

        // Act
        final result = await repository.createExchange(
          targetCurrency: 'SYP',
          amountUsd: 100.0,
          exchangeRate: 15000.0,
          exchangeDate: '2024-11-16',
        );

        // Assert
        expect(result, isA<Right>());
        result.fold(
          (failure) => fail('Should not return failure'),
          (exchange) {
            expect(exchange.id, 1);
            expect(exchange.targetCurrency, 'SYP');
          },
        );
      });

      test('should return ServerFailure when datasource throws exception', () async {
        // Arrange
        when(mockDatasource.createExchange(
          targetCurrency: anyNamed('targetCurrency'),
          amountUsd: anyNamed('amountUsd'),
          exchangeRate: anyNamed('exchangeRate'),
          exchangeDate: anyNamed('exchangeDate'),
        )).thenThrow(Exception('Server error'));

        // Act
        final result = await repository.createExchange(
          targetCurrency: 'SYP',
          amountUsd: 100.0,
          exchangeRate: 15000.0,
          exchangeDate: '2024-11-16',
        );

        // Assert
        expect(result, isA<Left>());
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (exchange) => fail('Should not return exchange'),
        );
      });
    });

    group('getAllExchanges', () {
      test('should return list of exchanges', () async {
        // Arrange
        final exchanges = [
          ExchangeDto(
            id: 1,
            targetCurrency: 'SYP',
            amountUsd: 100.0,
            exchangeRate: 15000.0,
            convertedAmount: 1500000.0,
            exchangeDate: '2024-11-16',
            createdAt: '2024-11-16T10:00:00Z',
          ),
        ];

        when(mockDatasource.getAllExchanges(currency: anyNamed('currency')))
            .thenAnswer((_) async => exchanges);

        // Act
        final result = await repository.getAllExchanges();

        // Assert
        expect(result, isA<Right>());
        result.fold(
          (failure) => fail('Should not return failure'),
          (list) => expect(list.length, 1),
        );
      });

      test('should return empty list when no exchanges', () async {
        // Arrange
        when(mockDatasource.getAllExchanges(currency: anyNamed('currency')))
            .thenAnswer((_) async => []);

        // Act
        final result = await repository.getAllExchanges();

        // Assert
        expect(result, isA<Right>());
        result.fold(
          (failure) => fail('Should not return failure'),
          (list) => expect(list, isEmpty),
        );
      });
    });

    group('getExchangeById', () {
      test('should return exchange when found', () async {
        // Arrange
        final exchangeDto = ExchangeDto(
          id: 1,
          targetCurrency: 'SYP',
          amountUsd: 100.0,
          exchangeRate: 15000.0,
          convertedAmount: 1500000.0,
          exchangeDate: '2024-11-16',
          createdAt: '2024-11-16T10:00:00Z',
        );

        when(mockDatasource.getExchangeById(any))
            .thenAnswer((_) async => exchangeDto);

        // Act
        final result = await repository.getExchangeById(1);

        // Assert
        expect(result, isA<Right>());
        result.fold(
          (failure) => fail('Should not return failure'),
          (exchange) => expect(exchange.id, 1),
        );
      });

      test('should return NotFoundFailure when exchange not found', () async {
        // Arrange
        when(mockDatasource.getExchangeById(any))
            .thenThrow(Exception('Not found'));

        // Act
        final result = await repository.getExchangeById(999);

        // Assert
        expect(result, isA<Left>());
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (exchange) => fail('Should not return exchange'),
        );
      });
    });

    group('getExchangesByTransfer', () {
      test('should return exchanges for transfer', () async {
        // Arrange
        final exchanges = [
          ExchangeDto(
            id: 1,
            transferId: 5,
            targetCurrency: 'SYP',
            amountUsd: 100.0,
            exchangeRate: 15000.0,
            convertedAmount: 1500000.0,
            exchangeDate: '2024-11-16',
            createdAt: '2024-11-16T10:00:00Z',
          ),
        ];

        when(mockDatasource.getExchangesByTransfer(any))
            .thenAnswer((_) async => exchanges);

        // Act
        final result = await repository.getExchangesByTransfer(5);

        // Assert
        expect(result, isA<Right>());
        result.fold(
          (failure) => fail('Should not return failure'),
          (list) {
            expect(list.length, 1);
            expect(list[0].transferId, 5);
          },
        );
      });
    });

    group('getTransferBalance', () {
      test('should return transfer balance info', () async {
        // Arrange
        final balanceInfo = TransferBalanceInfoDto(
          transferId: 5,
          originalAmount: 1000.0,
          exchangedAmount: 300.0,
          remainingAmount: 700.0,
        );

        when(mockDatasource.getTransferBalance(any))
            .thenAnswer((_) async => balanceInfo);

        // Act
        final result = await repository.getTransferBalance(5);

        // Assert
        expect(result, isA<Right>());
        result.fold(
          (failure) => fail('Should not return failure'),
          (info) {
            expect(info.transferId, 5);
            expect(info.remainingAmount, 700.0);
          },
        );
      });
    });
  });
}

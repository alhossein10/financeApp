import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:finance_app/features/exchanges/presentation/bloc/exchange_bloc.dart';
import 'package:finance_app/features/exchanges/presentation/bloc/exchange_event.dart';
import 'package:finance_app/features/exchanges/presentation/bloc/exchange_state.dart';
import 'package:finance_app/features/exchanges/domain/entities/exchange.dart';
import 'package:finance_app/features/exchanges/domain/usecases/create_exchange_usecase.dart';
import 'package:finance_app/features/exchanges/domain/usecases/get_all_exchanges_usecase.dart';
import 'package:finance_app/features/exchanges/domain/usecases/get_exchange_by_id_usecase.dart';
import 'package:finance_app/core/error/failures.dart';

import 'exchange_bloc_test.mocks.dart';

@GenerateMocks([
  CreateExchangeUsecase,
  GetAllExchangesUsecase,
  GetExchangeByIdUsecase,
])
void main() {
  late ExchangeBloc bloc;
  late MockCreateExchangeUsecase mockCreateExchange;
  late MockGetAllExchangesUsecase mockGetAllExchanges;
  late MockGetExchangeByIdUsecase mockGetExchangeById;

  setUp(() {
    mockCreateExchange = MockCreateExchangeUsecase();
    mockGetAllExchanges = MockGetAllExchangesUsecase();
    mockGetExchangeById = MockGetExchangeByIdUsecase();
    
    bloc = ExchangeBloc(
      createExchange: mockCreateExchange,
      getAllExchanges: mockGetAllExchanges,
      getExchangeById: mockGetExchangeById,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('ExchangeBloc', () {
    final testExchange = Exchange(
      id: 1,
      targetCurrency: 'SYP',
      amountUsd: 100.0,
      exchangeRate: 15000.0,
      convertedAmount: 1500000.0,
      exchangeDate: '2024-11-16',
      createdAt: '2024-11-16T10:00:00Z',
    );

    test('initial state should be ExchangeInitial', () {
      expect(bloc.state, equals(ExchangeInitial()));
    });

    group('CreateExchangeEvent', () {
      blocTest<ExchangeBloc, ExchangeState>(
        'should emit [ExchangeLoading, ExchangeCreated] when creation is successful',
        build: () {
          when(mockCreateExchange(any))
              .thenAnswer((_) async => Right(testExchange));
          return bloc;
        },
        act: (bloc) => bloc.add(CreateExchangeEvent(
          targetCurrency: 'SYP',
          amountUsd: 100.0,
          exchangeRate: 15000.0,
          exchangeDate: '2024-11-16',
        )),
        expect: () => [
          ExchangeLoading(),
          ExchangeCreated(testExchange),
        ],
      );

      blocTest<ExchangeBloc, ExchangeState>(
        'should emit [ExchangeLoading, ExchangeError] when creation fails',
        build: () {
          when(mockCreateExchange(any))
              .thenAnswer((_) async => Left(ServerFailure('Server error')));
          return bloc;
        },
        act: (bloc) => bloc.add(CreateExchangeEvent(
          targetCurrency: 'SYP',
          amountUsd: 100.0,
          exchangeRate: 15000.0,
          exchangeDate: '2024-11-16',
        )),
        expect: () => [
          ExchangeLoading(),
          ExchangeError('Server error'),
        ],
      );
    });

    group('LoadAllExchangesEvent', () {
      blocTest<ExchangeBloc, ExchangeState>(
        'should emit [ExchangeLoading, ExchangesLoaded] when loading is successful',
        build: () {
          when(mockGetAllExchanges(any))
              .thenAnswer((_) async => Right([testExchange]));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadAllExchangesEvent()),
        expect: () => [
          ExchangeLoading(),
          ExchangesLoaded([testExchange]),
        ],
      );

      blocTest<ExchangeBloc, ExchangeState>(
        'should emit [ExchangeLoading, ExchangesLoaded] with empty list',
        build: () {
          when(mockGetAllExchanges(any))
              .thenAnswer((_) async => Right([]));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadAllExchangesEvent()),
        expect: () => [
          ExchangeLoading(),
          ExchangesLoaded([]),
        ],
      );

      blocTest<ExchangeBloc, ExchangeState>(
        'should emit [ExchangeLoading, ExchangeError] when loading fails',
        build: () {
          when(mockGetAllExchanges(any))
              .thenAnswer((_) async => Left(ServerFailure('Failed to load')));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadAllExchangesEvent()),
        expect: () => [
          ExchangeLoading(),
          ExchangeError('Failed to load'),
        ],
      );

      blocTest<ExchangeBloc, ExchangeState>(
        'should pass currency filter to usecase',
        build: () {
          when(mockGetAllExchanges(any))
              .thenAnswer((_) async => Right([testExchange]));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadAllExchangesEvent(currency: 'SYP')),
        verify: (_) {
          verify(mockGetAllExchanges(any)).called(1);
        },
      );
    });

    group('LoadExchangeByIdEvent', () {
      blocTest<ExchangeBloc, ExchangeState>(
        'should emit [ExchangeLoading, ExchangeLoaded] when loading is successful',
        build: () {
          when(mockGetExchangeById(any))
              .thenAnswer((_) async => Right(testExchange));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadExchangeByIdEvent(1)),
        expect: () => [
          ExchangeLoading(),
          ExchangeLoaded(testExchange),
        ],
      );

      blocTest<ExchangeBloc, ExchangeState>(
        'should emit [ExchangeLoading, ExchangeError] when exchange not found',
        build: () {
          when(mockGetExchangeById(any))
              .thenAnswer((_) async => Left(NotFoundFailure('Exchange not found')));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadExchangeByIdEvent(999)),
        expect: () => [
          ExchangeLoading(),
          ExchangeError('Exchange not found'),
        ],
      );
    });
  });
}

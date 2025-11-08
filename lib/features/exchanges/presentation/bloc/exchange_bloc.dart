import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_exchange_usecase.dart';
import '../../domain/usecases/get_all_exchanges_usecase.dart';
import '../../domain/usecases/get_exchanges_by_transfer_usecase.dart';
import '../../domain/usecases/get_transfer_balance_usecase.dart';
import 'exchange_event.dart';
import 'exchange_state.dart';

class ExchangeBloc extends Bloc<ExchangeEvent, ExchangeState> {
  final CreateExchangeUseCase createExchangeUseCase;
  final GetAllExchangesUseCase getAllExchangesUseCase;
  final GetExchangesByTransferUseCase getExchangesByTransferUseCase;
  final GetTransferBalanceUseCase getTransferBalanceUseCase;

  ExchangeBloc({
    required this.createExchangeUseCase,
    required this.getAllExchangesUseCase,
    required this.getExchangesByTransferUseCase,
    required this.getTransferBalanceUseCase,
  }) : super(const ExchangeInitial()) {
    on<CreateExchangeEvent>(_onCreateExchange);
    on<LoadAllExchangesEvent>(_onLoadAllExchanges);
    on<LoadExchangesByTransferEvent>(_onLoadExchangesByTransfer);
    on<LoadTransferBalanceEvent>(_onLoadTransferBalance);
    on<ResetExchangeStateEvent>(_onResetState);
  }

  Future<void> _onCreateExchange(
    CreateExchangeEvent event,
    Emitter<ExchangeState> emit,
  ) async {
    emit(const ExchangeLoading());

    final result = await createExchangeUseCase(
      transferId: event.transferId,
      targetCurrency: event.targetCurrency,
      amountUsd: event.amountUsd,
      exchangeRate: event.exchangeRate,
      exchangeDate: event.exchangeDate,
      notes: event.notes,
    );

    result.fold(
      (failure) => emit(ExchangeError(failure.message)),
      (exchange) => emit(ExchangeCreated(exchange)),
    );
  }

  Future<void> _onLoadAllExchanges(
    LoadAllExchangesEvent event,
    Emitter<ExchangeState> emit,
  ) async {
    emit(const ExchangeLoading());

    final result = await getAllExchangesUseCase(currency: event.currency);

    result.fold(
      (failure) => emit(ExchangeError(failure.message)),
      (exchanges) => emit(ExchangesLoaded(exchanges)),
    );
  }

  Future<void> _onLoadExchangesByTransfer(
    LoadExchangesByTransferEvent event,
    Emitter<ExchangeState> emit,
  ) async {
    emit(const ExchangeLoading());

    final result = await getExchangesByTransferUseCase(event.transferId);

    result.fold(
      (failure) => emit(ExchangeError(failure.message)),
      (exchanges) => emit(ExchangesLoaded(exchanges)),
    );
  }

  Future<void> _onLoadTransferBalance(
    LoadTransferBalanceEvent event,
    Emitter<ExchangeState> emit,
  ) async {
    emit(const ExchangeLoading());

    final result = await getTransferBalanceUseCase(event.transferId);

    result.fold(
      (failure) => emit(ExchangeError(failure.message)),
      (balance) => emit(TransferBalanceLoaded(balance)),
    );
  }

  void _onResetState(
    ResetExchangeStateEvent event,
    Emitter<ExchangeState> emit,
  ) {
    emit(const ExchangeInitial());
  }
}

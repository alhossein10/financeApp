import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_transfer_usecase.dart';
import '../../domain/usecases/delete_transfer_usecase.dart';
import '../../domain/usecases/get_transfers_usecase.dart';
import '../../domain/usecases/update_transfer_usecase.dart';
import 'transfer_event.dart';
import 'transfer_state.dart';

class TransferBloc extends Bloc<TransferEvent, TransferState> {
  final CreateTransferUseCase createTransferUseCase;
  final GetTransfersUseCase getTransfersUseCase;
  final UpdateTransferUseCase updateTransferUseCase;
  final DeleteTransferUseCase deleteTransferUseCase;

  TransferBloc({
    required this.createTransferUseCase,
    required this.getTransfersUseCase,
    required this.updateTransferUseCase,
    required this.deleteTransferUseCase,
  }) : super(TransferInitial()) {
    on<CreateTransferEvent>(_onCreateTransfer);
    on<LoadTransfersEvent>(_onLoadTransfers);
    on<UpdateTransferEvent>(_onUpdateTransfer);
    on<DeleteTransferEvent>(_onDeleteTransfer);
  }

  Future<void> _onCreateTransfer(
    CreateTransferEvent event,
    Emitter<TransferState> emit,
  ) async {
    emit(TransferLoading());

    final result = await createTransferUseCase(
      CreateTransferParams(
        userId: event.userId,
        recipientName: event.recipientName,
        amountUsd: event.amountUsd,
        convertedAmountUsd: event.convertedAmountUsd,
        amountSypAtExchange: event.amountSypAtExchange,
        manualUsdToSypRate: event.manualUsdToSypRate,
        transactionDate: event.transactionDate,
      ),
    );

    result.fold(
      (failure) => emit(TransferError(failure.message)),
      (transfer) => emit(TransferCreated(transfer)),
    );
  }

  Future<void> _onLoadTransfers(
    LoadTransfersEvent event,
    Emitter<TransferState> emit,
  ) async {
    emit(TransferLoading());

    final result = await getTransfersUseCase(event.userId);

    result.fold(
      (failure) => emit(TransferError(failure.message)),
      (transfers) => emit(TransferLoaded(transfers)),
    );
  }

  Future<void> _onUpdateTransfer(
    UpdateTransferEvent event,
    Emitter<TransferState> emit,
  ) async {
    emit(TransferLoading());

    final result = await updateTransferUseCase(
      UpdateTransferParams(transfer: event.transfer),
    );

    result.fold(
      (failure) => emit(TransferError(failure.message)),
      (_) => emit(TransferUpdated()),
    );
  }

  Future<void> _onDeleteTransfer(
    DeleteTransferEvent event,
    Emitter<TransferState> emit,
  ) async {
    emit(TransferLoading());

    final result = await deleteTransferUseCase(
      DeleteTransferParams(
        transferId: event.transferId,
        userId: event.userId,
        refund: event.refund,
      ),
    );

    result.fold(
      (failure) => emit(TransferError(failure.message)),
      (_) => emit(TransferDeleted()),
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/connectivity_monitor.dart';
import '../../../../core/utils/error_handler.dart';
import '../../domain/entities/transfer.dart';
import '../../domain/entities/transfer_type.dart';
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
  final ConnectivityMonitor? connectivityMonitor;

  TransferBloc({
    required this.createTransferUseCase,
    required this.getTransfersUseCase,
    required this.updateTransferUseCase,
    required this.deleteTransferUseCase,
    this.connectivityMonitor,
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

    final isOnline = connectivityMonitor != null 
        ? await connectivityMonitor!.isOnline 
        : true;

    final result = await createTransferUseCase(
      CreateTransferParams(
        userId: event.userId,
        recipientName: event.recipientName,
        recipientUserId: event.recipientUserId,
        adminGroupId: event.adminGroupId,
        amountUsd: event.amountUsd,
        convertedAmountUsd: event.convertedAmountUsd,
        amountSypAtExchange: event.amountSypAtExchange,
        manualUsdToSypRate: event.manualUsdToSypRate,
        transactionDate: event.transactionDate,
      ),
    );

    result.fold(
      (failure) => _handleError(failure, emit, isOnline),
      (transfer) => emit(TransferCreated(
        transfer,
        isPending: !isOnline,
      )),
    );
  }

  Future<void> _onLoadTransfers(
    LoadTransfersEvent event,
    Emitter<TransferState> emit,
  ) async {
    emit(TransferLoading());

    final isOnline = connectivityMonitor != null 
        ? await connectivityMonitor!.isOnline 
        : true;

    final result = await getTransfersUseCase(event.userId);

    result.fold(
      (failure) => _handleError(failure, emit, isOnline),
      (transfers) {
        // Filter transfers based on type
        final filteredTransfers = _filterTransfersByType(transfers, event.type, event.userId);
        
        emit(TransferLoaded(
          filteredTransfers,
          isOffline: !isOnline,
          isSyncing: false,
        ));
      },
    );
  }

  /// Filter transfers by type (incoming, outgoing, or all)
  /// 
  /// - incoming: Transfers where recipientUserId matches the current userId
  /// - outgoing: Transfers where userId matches the current userId (sender)
  /// - all: No filtering
  List<Transfer> _filterTransfersByType(
    List<Transfer> transfers,
    TransferType type,
    int currentUserId,
  ) {
    switch (type) {
      case TransferType.incoming:
        // Incoming transfers are where the current user is the recipient
        return transfers.where((t) => t.recipientUserId == currentUserId).toList();
      
      case TransferType.outgoing:
        // Outgoing transfers are where the current user is the sender
        return transfers.where((t) => t.userId == currentUserId).toList();
      
      case TransferType.all:
        // Return all transfers
        return transfers;
    }
  }

  Future<void> _onUpdateTransfer(
    UpdateTransferEvent event,
    Emitter<TransferState> emit,
  ) async {
    emit(TransferLoading());

    final isOnline = connectivityMonitor != null 
        ? await connectivityMonitor!.isOnline 
        : true;

    final result = await updateTransferUseCase(
      UpdateTransferParams(transfer: event.transfer),
    );

    result.fold(
      (failure) => _handleError(failure, emit, isOnline),
      (_) => emit(TransferUpdated(isPending: !isOnline)),
    );
  }

  Future<void> _onDeleteTransfer(
    DeleteTransferEvent event,
    Emitter<TransferState> emit,
  ) async {
    emit(TransferLoading());

    final isOnline = connectivityMonitor != null 
        ? await connectivityMonitor!.isOnline 
        : true;

    final result = await deleteTransferUseCase(
      DeleteTransferParams(
        transferId: event.transferId,
        userId: event.userId,
        refund: event.refund,
      ),
    );

    result.fold(
      (failure) => _handleError(failure, emit, isOnline),
      (_) => emit(TransferDeleted(isPending: !isOnline)),
    );
  }

  /// Enhanced error handling with support for 401, 403, 422, 429
  void _handleError(Failure failure, Emitter<TransferState> emit, bool isOnline) {
    final errorResult = ErrorHandler.createEnhancedError(failure);
    
    emit(TransferError(
      errorResult.displayMessage,
      isOffline: !isOnline,
      requiresLogout: errorResult.requiresLogout,
      isForbidden: errorResult.isForbidden,
      isValidationError: errorResult.isValidationError,
      isRateLimited: errorResult.isRateLimited,
      retryAfterSeconds: errorResult.retryAfterDuration?.inSeconds,
    ));
  }
}

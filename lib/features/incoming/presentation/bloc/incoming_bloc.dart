import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/connectivity_monitor.dart';
import '../../../../core/services/queue_manager.dart';
import '../../../../core/utils/error_handler.dart';
import '../../domain/usecases/create_incoming_usecase.dart';
import '../../domain/usecases/delete_incoming_usecase.dart';
import '../../domain/usecases/get_incoming_usecase.dart';
import '../../domain/usecases/update_incoming_usecase.dart';
import 'incoming_event.dart';
import 'incoming_state.dart';

class IncomingBloc extends Bloc<IncomingEvent, IncomingState> {
  final CreateIncomingUseCase createIncomingUseCase;
  final GetIncomingUseCase getIncomingUseCase;
  final UpdateIncomingUseCase updateIncomingUseCase;
  final DeleteIncomingUseCase deleteIncomingUseCase;
  final ConnectivityMonitor connectivityMonitor;
  final QueueManager queueManager;

  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _queueStatusSubscription;
  bool _isOnline = true;
  int _pendingQueueCount = 0;

  IncomingBloc({
    required this.createIncomingUseCase,
    required this.getIncomingUseCase,
    required this.updateIncomingUseCase,
    required this.deleteIncomingUseCase,
    required this.connectivityMonitor,
    required this.queueManager,
  }) : super(const IncomingInitial()) {
    on<LoadIncoming>(_onLoadIncoming);
    on<CreateIncoming>(_onCreateIncoming);
    on<UpdateIncoming>(_onUpdateIncoming);
    on<DeleteIncoming>(_onDeleteIncoming);
    on<CheckConnectivityStatus>(_onCheckConnectivityStatus);
    on<ProcessOfflineQueue>(_onProcessOfflineQueue);

    // Listen to connectivity changes
    _connectivitySubscription = connectivityMonitor.connectivityStream.listen((status) {
      _isOnline = status.isOnline;
      add(const CheckConnectivityStatus());
      
      // Auto-process queue when coming online
      if (status.isOnline) {
        add(const ProcessOfflineQueue());
      }
    });

    // Listen to queue status changes
    _queueStatusSubscription = queueManager.queueStatus.listen((status) {
      _updateQueueCount();
    });

    // Initialize connectivity status
    _initializeConnectivity();
    _updateQueueCount();
  }

  Future<void> _initializeConnectivity() async {
    _isOnline = await connectivityMonitor.isOnline;
  }

  Future<void> _onLoadIncoming(
    LoadIncoming event,
    Emitter<IncomingState> emit,
  ) async {
    emit(IncomingLoading(
      isOnline: _isOnline,
      pendingQueueCount: _pendingQueueCount,
    ));

    final result = await getIncomingUseCase();

    result.fold(
      (failure) => _handleError(failure, emit),
      (incomingList) {
        // Calculate total amount
        final totalAmount = incomingList.fold<double>(
          0.0,
          (sum, incoming) => sum + incoming.amountUsd,
        );
        
        emit(IncomingLoaded(
          incomingList,
          totalAmountUsd: totalAmount,
          isOnline: _isOnline,
          pendingQueueCount: _pendingQueueCount,
        ));
      },
    );
  }

  Future<void> _onCreateIncoming(
    CreateIncoming event,
    Emitter<IncomingState> emit,
  ) async {
    emit(IncomingLoading(
      isOnline: _isOnline,
      pendingQueueCount: _pendingQueueCount,
    ));

    final result = await createIncomingUseCase(
      CreateIncomingParams(
        description: event.description,
        amountUsd: event.amountUsd,
        transactionDate: event.transactionDate,
      ),
    );

    await result.fold(
      (failure) async {
        _handleError(failure, emit);
      },
      (incoming) async {
        final message = _isOnline
            ? 'Incoming transaction created successfully'
            : 'Incoming transaction queued for sync';
        
        emit(IncomingOperationSuccess(
          message,
          isOnline: _isOnline,
          pendingQueueCount: _pendingQueueCount,
        ));
        
        // Update queue count
        await _updateQueueCount();
        
        // Reload the list
        add(const LoadIncoming());
      },
    );
  }

  Future<void> _onUpdateIncoming(
    UpdateIncoming event,
    Emitter<IncomingState> emit,
  ) async {
    emit(IncomingLoading(
      isOnline: _isOnline,
      pendingQueueCount: _pendingQueueCount,
    ));

    final result = await updateIncomingUseCase(event.incoming);

    await result.fold(
      (failure) async {
        _handleError(failure, emit);
      },
      (_) async {
        final message = _isOnline
            ? 'Incoming transaction updated successfully'
            : 'Incoming transaction update queued for sync';
        
        emit(IncomingOperationSuccess(
          message,
          isOnline: _isOnline,
          pendingQueueCount: _pendingQueueCount,
        ));
        
        // Update queue count
        await _updateQueueCount();
        
        // Reload the list
        add(const LoadIncoming());
      },
    );
  }

  Future<void> _onDeleteIncoming(
    DeleteIncoming event,
    Emitter<IncomingState> emit,
  ) async {
    emit(IncomingLoading(
      isOnline: _isOnline,
      pendingQueueCount: _pendingQueueCount,
    ));

    final result = await deleteIncomingUseCase(
      DeleteIncomingParams(
        id: event.id,
        refund: event.refund,
      ),
    );

    await result.fold(
      (failure) async {
        _handleError(failure, emit);
      },
      (_) async {
        final message = _isOnline
            ? 'Incoming transaction deleted successfully'
            : 'Incoming transaction deletion queued for sync';
        
        emit(IncomingOperationSuccess(
          message,
          isOnline: _isOnline,
          pendingQueueCount: _pendingQueueCount,
        ));
        
        // Update queue count
        await _updateQueueCount();
        
        // Reload the list
        add(const LoadIncoming());
      },
    );
  }

  Future<void> _onCheckConnectivityStatus(
    CheckConnectivityStatus event,
    Emitter<IncomingState> emit,
  ) async {
    // Update current state with new connectivity status
    final currentState = state;
    if (currentState is IncomingLoaded) {
      emit(IncomingLoaded(
        currentState.incomingList,
        totalAmountUsd: currentState.totalAmountUsd,
        isOnline: _isOnline,
        pendingQueueCount: _pendingQueueCount,
      ));
    }
  }

  Future<void> _onProcessOfflineQueue(
    ProcessOfflineQueue event,
    Emitter<IncomingState> emit,
  ) async {
    if (!_isOnline) {
      return; // Don't process queue if offline
    }

    try {
      await queueManager.processQueue();
      await _updateQueueCount();
      
      // Reload data after processing queue
      add(const LoadIncoming());
    } catch (e) {
      // Silently fail queue processing
    }
  }

  Future<void> _updateQueueCount() async {
    try {
      final stats = await queueManager.getStatistics();
      _pendingQueueCount = (stats['pending'] as int? ?? 0) + (stats['failed'] as int? ?? 0);
    } catch (e) {
      _pendingQueueCount = 0;
    }
  }

  /// Enhanced error handling with support for 401, 403, 422, 429
  void _handleError(Failure failure, Emitter<IncomingState> emit) {
    final errorResult = ErrorHandler.createEnhancedError(failure);
    
    emit(IncomingError(
      errorResult.displayMessage,
      isOnline: _isOnline,
      pendingQueueCount: _pendingQueueCount,
      requiresLogout: errorResult.requiresLogout,
      isForbidden: errorResult.isForbidden,
      isValidationError: errorResult.isValidationError,
      isRateLimited: errorResult.isRateLimited,
      retryAfterSeconds: errorResult.retryAfterDuration?.inSeconds,
    ));
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    _queueStatusSubscription?.cancel();
    return super.close();
  }
}

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/queue_manager.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/utils/error_handler.dart';
import '../../domain/entities/expense.dart';
import '../../domain/usecases/create_expense_usecase.dart';
import '../../domain/usecases/delete_expense_usecase.dart';
import '../../domain/usecases/get_expenses_usecase.dart';
import '../../domain/usecases/update_expense_usecase.dart';
import 'expense_event.dart';
import 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final CreateExpenseUseCase createExpenseUseCase;
  final GetExpensesUseCase getExpensesUseCase;
  final UpdateExpenseUseCase updateExpenseUseCase;
  final DeleteExpenseUseCase deleteExpenseUseCase;
  final SyncService syncService;
  final QueueManager queueManager;

  StreamSubscription? _syncStatusSubscription;
  StreamSubscription? _queueStatusSubscription;
  final Map<int, SyncStatus> _syncStatusMap = {};

  ExpenseBloc({
    required this.createExpenseUseCase,
    required this.getExpensesUseCase,
    required this.updateExpenseUseCase,
    required this.deleteExpenseUseCase,
    required this.syncService,
    required this.queueManager,
  }) : super(const ExpenseInitial()) {
    on<CreateExpenseRequested>(_onCreateExpenseRequested);
    on<LoadExpensesRequested>(_onLoadExpensesRequested);
    on<UpdateExpenseRequested>(_onUpdateExpenseRequested);
    on<DeleteExpenseRequested>(_onDeleteExpenseRequested);
    on<SyncExpenseRequested>(_onSyncExpenseRequested);
    on<SyncAllPendingRequested>(_onSyncAllPendingRequested);
    on<SyncStatusUpdated>(_onSyncStatusUpdated);
    on<CheckQueueStatusRequested>(_onCheckQueueStatusRequested);
    on<ProcessOfflineQueueRequested>(_onProcessOfflineQueueRequested);

    // Listen to queue status changes
    _queueStatusSubscription = queueManager.queueStatus.listen((status) {
      add(const CheckQueueStatusRequested());
    });
  }

  Future<void> _onCreateExpenseRequested(
    CreateExpenseRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    print('[ExpenseBloc] Creating expense: ${event.description}');
    emit(ExpenseLoading(syncStatusMap: _syncStatusMap));

    final params = CreateExpenseParams(
      userId: event.userId,
      description: event.description,
      priceUsd: event.priceUsd,
      priceSyp: event.priceSyp,
      priceTry: event.priceTry,
      invoiceStatus: event.invoiceStatus,
      invoiceFilePath: event.invoiceFilePath,
      expenseDate: event.expenseDate,
    );

    final result = await createExpenseUseCase(params);

    result.fold(
      (failure) {
        print('[ExpenseBloc] ❌ Failed to create expense: ${failure.message}');
        _handleError(failure, emit);
      },
      (expense) {
        print('[ExpenseBloc] ✅ Expense created successfully!');
        print('[ExpenseBloc]    ID: ${expense.id}');
        print('[ExpenseBloc]    Description: ${expense.description}');
        print('[ExpenseBloc]    USD: ${expense.priceUsd}, SYP: ${expense.priceSyp}, TRY: ${expense.priceTry}');
        
        // Start watching sync status for this expense
        if (expense.id != null) {
          _watchExpenseSyncStatus(expense.id!);
        }
        emit(ExpenseCreated(expense, syncStatusMap: _syncStatusMap));
      },
    );
  }

  Future<void> _onLoadExpensesRequested(
    LoadExpensesRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading(syncStatusMap: _syncStatusMap));

    final result = await getExpensesUseCase(event.userId);

    result.fold(
      (failure) => _handleError(failure, emit),
      (expenses) {
        // Watch sync status for all loaded expenses
        for (final expense in expenses) {
          if (expense.id != null) {
            _watchExpenseSyncStatus(expense.id!);
          }
        }
        emit(ExpenseLoaded(expenses, syncStatusMap: _syncStatusMap));
      },
    );
  }

  Future<void> _onUpdateExpenseRequested(
    UpdateExpenseRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading(syncStatusMap: _syncStatusMap));

    final params = UpdateExpenseParams(
      expense: event.expense,
      currentUserId: event.currentUserId,
    );

    final result = await updateExpenseUseCase(params);

    result.fold(
      (failure) => _handleError(failure, emit),
      (_) => emit(ExpenseUpdated(syncStatusMap: _syncStatusMap)),
    );
  }

  Future<void> _onDeleteExpenseRequested(
    DeleteExpenseRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading(syncStatusMap: _syncStatusMap));

    final params = DeleteExpenseParams(
      expenseId: event.expenseId,
      userId: event.userId,
    );

    final result = await deleteExpenseUseCase(params);

    result.fold(
      (failure) => _handleError(failure, emit),
      (_) => emit(ExpenseDeleted(syncStatusMap: _syncStatusMap)),
    );
  }

  Future<void> _onSyncExpenseRequested(
    SyncExpenseRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseSyncing(syncStatusMap: _syncStatusMap));

    final result = await syncService.syncExpense(event.expense);

    result.fold(
      (failure) => _handleError(failure, emit, isSyncError: true),
      (_) => emit(ExpenseSynced(syncStatusMap: _syncStatusMap)),
    );
  }

  Future<void> _onSyncAllPendingRequested(
    SyncAllPendingRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseSyncing(syncStatusMap: _syncStatusMap));

    final result = await syncService.syncPendingExpenses();

    result.fold(
      (failure) => _handleError(failure, emit, isSyncError: true),
      (_) => emit(ExpenseSynced(syncStatusMap: _syncStatusMap)),
    );
  }

  void _onSyncStatusUpdated(
    SyncStatusUpdated event,
    Emitter<ExpenseState> emit,
  ) {
    // Update internal sync status map
    _syncStatusMap.addAll(event.syncStatusMap);
    
    // Emit current state with updated sync status map
    final currentState = state;
    if (currentState is ExpenseLoaded) {
      emit(ExpenseLoaded(currentState.expenses, syncStatusMap: Map.from(_syncStatusMap)));
    } else if (currentState is ExpenseCreated) {
      emit(ExpenseCreated(currentState.expense, syncStatusMap: Map.from(_syncStatusMap)));
    } else {
      // For other states, just update the sync status map
      emit(ExpenseSynced(syncStatusMap: Map.from(_syncStatusMap)));
    }
  }

  /// Watch sync status for a specific expense
  void _watchExpenseSyncStatus(int expenseId) {
    syncService.watchSyncStatus(expenseId).listen((status) {
      add(SyncStatusUpdated({expenseId: status}));
    });
  }

  Future<void> _onCheckQueueStatusRequested(
    CheckQueueStatusRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      final stats = await queueManager.getStatistics();
      final pendingCount = stats['pending'] as int? ?? 0;
      final failedCount = stats['failed'] as int? ?? 0;

      emit(ExpenseQueueStatusUpdated(
        pendingCount: pendingCount,
        failedCount: failedCount,
        syncStatusMap: Map.from(_syncStatusMap),
      ));
    } catch (e) {
      // Silently fail queue status check
    }
  }

  Future<void> _onProcessOfflineQueueRequested(
    ProcessOfflineQueueRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseSyncing(syncStatusMap: _syncStatusMap));

    try {
      await queueManager.processQueue();
      
      // Check queue status after processing
      add(const CheckQueueStatusRequested());
      
      emit(ExpenseSynced(syncStatusMap: _syncStatusMap));
    } catch (e) {
      emit(ExpenseSyncError(
        'Failed to process offline queue: ${e.toString()}',
        syncStatusMap: _syncStatusMap,
      ));
    }
  }

  /// Enhanced error handling with support for 401, 403, 422, 429
  void _handleError(Failure failure, Emitter<ExpenseState> emit, {bool isSyncError = false}) {
    final errorResult = ErrorHandler.createEnhancedError(failure);
    
    if (isSyncError) {
      emit(ExpenseSyncError(
        errorResult.displayMessage,
        syncStatusMap: _syncStatusMap,
        requiresLogout: errorResult.requiresLogout,
        isForbidden: errorResult.isForbidden,
        isValidationError: errorResult.isValidationError,
        isRateLimited: errorResult.isRateLimited,
        retryAfterSeconds: errorResult.retryAfterDuration?.inSeconds,
      ));
    } else {
      emit(ExpenseError(
        errorResult.displayMessage,
        syncStatusMap: _syncStatusMap,
        requiresLogout: errorResult.requiresLogout,
        isForbidden: errorResult.isForbidden,
        isValidationError: errorResult.isValidationError,
        isRateLimited: errorResult.isRateLimited,
        retryAfterSeconds: errorResult.retryAfterDuration?.inSeconds,
      ));
    }
  }

  @override
  Future<void> close() {
    _syncStatusSubscription?.cancel();
    _queueStatusSubscription?.cancel();
    return super.close();
  }
}

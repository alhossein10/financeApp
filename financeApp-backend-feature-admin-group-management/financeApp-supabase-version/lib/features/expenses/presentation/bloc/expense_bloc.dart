import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/sync_service.dart';
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

  StreamSubscription? _syncStatusSubscription;
  final Map<int, SyncStatus> _syncStatusMap = {};

  ExpenseBloc({
    required this.createExpenseUseCase,
    required this.getExpensesUseCase,
    required this.updateExpenseUseCase,
    required this.deleteExpenseUseCase,
    required this.syncService,
  }) : super(const ExpenseInitial()) {
    on<CreateExpenseRequested>(_onCreateExpenseRequested);
    on<LoadExpensesRequested>(_onLoadExpensesRequested);
    on<UpdateExpenseRequested>(_onUpdateExpenseRequested);
    on<DeleteExpenseRequested>(_onDeleteExpenseRequested);
    on<SyncExpenseRequested>(_onSyncExpenseRequested);
    on<SyncAllPendingRequested>(_onSyncAllPendingRequested);
    on<SyncStatusUpdated>(_onSyncStatusUpdated);
  }

  Future<void> _onCreateExpenseRequested(
    CreateExpenseRequested event,
    Emitter<ExpenseState> emit,
  ) async {
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
      (failure) => emit(ExpenseError(failure.message, syncStatusMap: _syncStatusMap)),
      (expense) {
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
      (failure) => emit(ExpenseError(failure.message, syncStatusMap: _syncStatusMap)),
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
      (failure) => emit(ExpenseError(failure.message, syncStatusMap: _syncStatusMap)),
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
      (failure) => emit(ExpenseError(failure.message, syncStatusMap: _syncStatusMap)),
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
      (failure) => emit(ExpenseSyncError(failure.message, syncStatusMap: _syncStatusMap)),
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
      (failure) => emit(ExpenseSyncError(failure.message, syncStatusMap: _syncStatusMap)),
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

  @override
  Future<void> close() {
    _syncStatusSubscription?.cancel();
    return super.close();
  }
}

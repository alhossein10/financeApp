import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/sync_status.dart';
import '../../../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../../../features/expenses/domain/entities/expense.dart';
import '../../../../features/expenses/domain/usecases/fetch_admin_expenses_usecase.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final FetchAdminExpensesUseCase _fetchAdminExpensesUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  
  List<Expense> _allExpenses = [];

  AdminBloc({
    required FetchAdminExpensesUseCase fetchAdminExpensesUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  })  : _fetchAdminExpensesUseCase = fetchAdminExpensesUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        super(const AdminInitial()) {
    on<FetchAdminStatisticsRequested>(_onFetchAdminStatistics);
    on<FetchAllUserExpensesRequested>(_onFetchAllUserExpenses);
  }

  Future<void> _onFetchAllUserExpenses(
    FetchAllUserExpensesRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    
    // Get current user to pass their ID for authorization check
    final userResult = await _getCurrentUserUseCase();
    
    if (userResult.isLeft()) {
      emit(const AdminError('User not authenticated'));
      return;
    }
    
    final user = userResult.getOrElse(() => throw Exception());
    
    // Fetch admin expenses with role-based access control
    final result = await _fetchAdminExpensesUseCase(user.id);
    
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (expenses) {
        _allExpenses = expenses;
        _emitLoadedState(emit);
      },
    );
  }

  Future<void> _onFetchAdminStatistics(
    FetchAdminStatisticsRequested event,
    Emitter<AdminState> emit,
  ) async {
    // If we already have expenses loaded, just recalculate statistics
    if (_allExpenses.isNotEmpty) {
      _emitLoadedState(emit);
      return;
    }
    
    // Otherwise, fetch expenses first
    emit(const AdminLoading());
    
    // Get current user to pass their ID for authorization check
    final userResult = await _getCurrentUserUseCase();
    
    if (userResult.isLeft()) {
      emit(const AdminError('User not authenticated'));
      return;
    }
    
    final user = userResult.getOrElse(() => throw Exception());
    
    // Fetch admin expenses with role-based access control
    final result = await _fetchAdminExpensesUseCase(user.id);
    
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (expenses) {
        _allExpenses = expenses;
        _emitLoadedState(emit);
      },
    );
  }

  void _emitLoadedState(Emitter<AdminState> emit) {
    // Calculate statistics
    final uniqueUsers = <String>{};
    var totalAmount = 0.0;
    var pendingSync = 0;
    final userActivityMap = <String, int>{};
    
    for (final expense in _allExpenses) {
      // Count unique users
      final username = expense.creatorUsername ?? expense.creatorEmail ?? 'Unknown';
      uniqueUsers.add(username);
      
      // Calculate total amount (USD only for simplicity)
      if (expense.priceUsd != null) {
        totalAmount += expense.priceUsd!;
      }
      
      // Count pending sync
      if (expense.syncStatus == SyncStatus.pending) {
        pendingSync++;
      }
      
      // Track user activity
      userActivityMap[username] = (userActivityMap[username] ?? 0) + 1;
    }
    
    // Sort expenses by date (most recent first)
    final sortedExpenses = List<Expense>.from(_allExpenses)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    emit(AdminLoaded(
      totalUsers: uniqueUsers.length,
      totalExpenses: _allExpenses.length,
      pendingSync: pendingSync,
      totalAmount: totalAmount,
      recentExpenses: sortedExpenses,
      userActivityMap: userActivityMap,
    ));
  }
}

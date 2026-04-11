import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/services/role_service.dart';
import '../../../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../../../features/expenses/domain/entities/expense.dart';
import '../../../../features/expenses/domain/usecases/fetch_admin_expenses_usecase.dart';
import '../../data/datasources/admin_api_datasource.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final FetchAdminExpensesUseCase _fetchAdminExpensesUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final AdminApiDataSource _adminApiDataSource;
  final RoleService _roleService;
  
  List<Expense> _allExpenses = [];

  AdminBloc({
    required FetchAdminExpensesUseCase fetchAdminExpensesUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required AdminApiDataSource adminApiDataSource,
    required RoleService roleService,
  })  : _fetchAdminExpensesUseCase = fetchAdminExpensesUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        _adminApiDataSource = adminApiDataSource,
        _roleService = roleService,
        super(const AdminInitial()) {
    on<FetchAdminStatisticsRequested>(_onFetchAdminStatistics);
    on<FetchAllUserExpensesRequested>(_onFetchAllUserExpenses);
    on<FetchDashboardStatsRequested>(_onFetchDashboardStats);
    on<FetchUserActivityRequested>(_onFetchUserActivity);
    on<FetchExpenseSummariesRequested>(_onFetchExpenseSummaries);
    on<FetchAnalyticsRequested>(_onFetchAnalytics);
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
      (failure) => _handleFailureError(failure, emit),
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
      (failure) => _handleFailureError(failure, emit),
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

  /// Handle fetching dashboard statistics from API
  /// NOTE: Data scoping by admin_group_id is handled automatically by the Laravel backend.
  /// The API calculates statistics based only on users in the authenticated admin's group.
  /// This includes:
  /// - Total users in the admin group
  /// - Total expenses from group members
  /// - Total income from group members
  /// - Total transfers from group members
  /// - Fund box balance for the admin group
  Future<void> _onFetchDashboardStats(
    FetchDashboardStatsRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());

    try {
      // Validate admin permission before API call
      await _roleService.requireAdminPermission();
      
      final stats = await _adminApiDataSource.getStats();
      emit(AdminDashboardStatsLoaded(
        totalUsers: stats.totalUsers,
        totalExpenses: stats.totalExpenses,
        totalIncome: stats.totalIncome,
        totalTransfers: stats.totalTransfers,
        totalAmountExpenses: stats.totalAmountExpenses,
        totalAmountIncome: stats.totalAmountIncome,
        fundBoxBalance: stats.fundBoxBalance,
      ));
    } on InsufficientPermissionsException catch (e) {
      emit(AdminError(
        e.message,
        isForbidden: true,
      ));
    } on ApiException catch (e) {
      _handleApiException(e, emit);
    } catch (e) {
      emit(AdminError('Failed to load dashboard stats: ${e.toString()}'));
    }
  }

  /// Handle fetching user activity from API
  /// NOTE: The API returns user activity only for members of the authenticated admin's group.
  Future<void> _onFetchUserActivity(
    FetchUserActivityRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());

    try {
      // Validate admin permission before API call
      await _roleService.requireAdminPermission();
      
      final userActivity = await _adminApiDataSource.getUserActivity();
      emit(AdminUserActivityLoaded(userActivity: userActivity));
    } on InsufficientPermissionsException catch (e) {
      emit(AdminError(
        e.message,
        isForbidden: true,
      ));
    } on ApiException catch (e) {
      _handleApiException(e, emit);
    } catch (e) {
      emit(AdminError('Failed to load user activity: ${e.toString()}'));
    }
  }

  /// Handle fetching expense summaries from API
  /// NOTE: The API returns expense summaries only for members of the authenticated admin's group.
  Future<void> _onFetchExpenseSummaries(
    FetchExpenseSummariesRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());

    try {
      // Validate admin permission before API call
      await _roleService.requireAdminPermission();
      
      final summary = await _adminApiDataSource.getExpenseSummaries();
      emit(AdminExpenseSummariesLoaded(summary: summary));
    } on InsufficientPermissionsException catch (e) {
      emit(AdminError(
        e.message,
        isForbidden: true,
      ));
    } on ApiException catch (e) {
      _handleApiException(e, emit);
    } catch (e) {
      emit(AdminError('Failed to load expense summaries: ${e.toString()}'));
    }
  }

  /// Handle fetching analytics with date range filtering from API
  /// NOTE: The API returns analytics only for members of the authenticated admin's group.
  Future<void> _onFetchAnalytics(
    FetchAnalyticsRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());

    try {
      // Validate admin permission before API call
      await _roleService.requireAdminPermission();
      
      final analytics = await _adminApiDataSource.getAnalytics(
        dateFrom: event.startDate,
        dateTo: event.endDate,
      );
      emit(AdminAnalyticsLoaded(analytics: analytics));
    } on InsufficientPermissionsException catch (e) {
      emit(AdminError(
        e.message,
        isForbidden: true,
      ));
    } on ApiException catch (e) {
      _handleApiException(e, emit);
    } catch (e) {
      emit(AdminError('Failed to load analytics: ${e.toString()}'));
    }
  }

  /// Enhanced error handling for Failure objects
  void _handleFailureError(dynamic failure, Emitter<AdminState> emit) {
    final errorResult = ErrorHandler.createEnhancedError(failure);
    
    emit(AdminError(
      errorResult.displayMessage,
      requiresLogout: errorResult.requiresLogout,
      isForbidden: errorResult.isForbidden,
      isValidationError: errorResult.isValidationError,
      isRateLimited: errorResult.isRateLimited,
      retryAfterSeconds: errorResult.retryAfterDuration?.inSeconds,
    ));
  }

  /// Enhanced error handling for ApiException objects
  void _handleApiException(ApiException exception, Emitter<AdminState> emit) {
    emit(AdminError(
      exception.userFriendlyMessage,
      requiresLogout: exception.isUnauthorized,
      isForbidden: exception.isForbidden,
      isValidationError: exception.isValidationError,
      isRateLimited: exception.isRateLimited,
      retryAfterSeconds: exception is RateLimitException 
          ? exception.retryAfter 
          : null,
    ));
  }
}

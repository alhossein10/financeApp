import 'package:equatable/equatable.dart';
import '../../../../features/expenses/domain/entities/expense.dart';
import '../../data/models/analytics_dto.dart';
import '../../data/models/expense_summary_dto.dart';
import '../../data/models/user_activity_dto.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {
  const AdminInitial();
}

class AdminLoading extends AdminState {
  const AdminLoading();
}

class AdminLoaded extends AdminState {
  final int totalUsers;
  final int totalExpenses;
  final int pendingSync;
  final double totalAmount;
  final List<Expense> recentExpenses;
  final Map<String, int> userActivityMap;

  const AdminLoaded({
    required this.totalUsers,
    required this.totalExpenses,
    required this.pendingSync,
    required this.totalAmount,
    required this.recentExpenses,
    required this.userActivityMap,
  });

  @override
  List<Object?> get props => [
        totalUsers,
        totalExpenses,
        pendingSync,
        totalAmount,
        recentExpenses,
        userActivityMap,
      ];
}

/// State when dashboard statistics are loaded from API
class AdminDashboardStatsLoaded extends AdminState {
  final int totalUsers;
  final int totalExpenses;
  final int totalIncome;
  final int totalTransfers;
  final double totalAmountExpenses;
  final double totalAmountIncome;
  final double fundBoxBalance;

  const AdminDashboardStatsLoaded({
    required this.totalUsers,
    required this.totalExpenses,
    required this.totalIncome,
    required this.totalTransfers,
    required this.totalAmountExpenses,
    required this.totalAmountIncome,
    required this.fundBoxBalance,
  });

  @override
  List<Object?> get props => [
        totalUsers,
        totalExpenses,
        totalIncome,
        totalTransfers,
        totalAmountExpenses,
        totalAmountIncome,
        fundBoxBalance,
      ];
}

/// State when user activity is loaded from API
class AdminUserActivityLoaded extends AdminState {
  final List<UserActivityDto> userActivity;

  const AdminUserActivityLoaded({required this.userActivity});

  @override
  List<Object?> get props => [userActivity];
}

/// State when expense summaries are loaded from API
class AdminExpenseSummariesLoaded extends AdminState {
  final ExpenseSummaryDto summary;

  const AdminExpenseSummariesLoaded({required this.summary});

  @override
  List<Object?> get props => [summary];
}

/// State when analytics are loaded from API
class AdminAnalyticsLoaded extends AdminState {
  final AnalyticsDto analytics;

  const AdminAnalyticsLoaded({required this.analytics});

  @override
  List<Object?> get props => [analytics];
}

class AdminError extends AdminState {
  final String message;
  final bool requiresLogout;
  final bool isForbidden;
  final bool isValidationError;
  final bool isRateLimited;
  final int? retryAfterSeconds;

  const AdminError(
    this.message, {
    this.requiresLogout = false,
    this.isForbidden = false,
    this.isValidationError = false,
    this.isRateLimited = false,
    this.retryAfterSeconds,
  });

  @override
  List<Object?> get props => [
        message,
        requiresLogout,
        isForbidden,
        isValidationError,
        isRateLimited,
        retryAfterSeconds,
      ];
}

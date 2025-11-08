import 'package:equatable/equatable.dart';
import '../../domain/entities/expense.dart';

abstract class ExpenseState extends Equatable {
  final Map<int, SyncStatus> syncStatusMap;

  const ExpenseState({this.syncStatusMap = const {}});

  @override
  List<Object?> get props => [syncStatusMap];
}

class ExpenseInitial extends ExpenseState {
  const ExpenseInitial() : super();
}

class ExpenseLoading extends ExpenseState {
  const ExpenseLoading({super.syncStatusMap});
}

class ExpenseLoaded extends ExpenseState {
  final List<Expense> expenses;

  const ExpenseLoaded(this.expenses, {super.syncStatusMap});

  @override
  List<Object?> get props => [expenses, syncStatusMap];
}

class ExpenseCreated extends ExpenseState {
  final Expense expense;

  const ExpenseCreated(this.expense, {super.syncStatusMap});

  @override
  List<Object?> get props => [expense, syncStatusMap];
}

class ExpenseUpdated extends ExpenseState {
  const ExpenseUpdated({super.syncStatusMap});
}

class ExpenseDeleted extends ExpenseState {
  const ExpenseDeleted({super.syncStatusMap});
}

class ExpenseError extends ExpenseState {
  final String message;
  final bool requiresLogout;
  final bool isForbidden;
  final bool isValidationError;
  final bool isRateLimited;
  final int? retryAfterSeconds;

  const ExpenseError(
    this.message, {
    super.syncStatusMap,
    this.requiresLogout = false,
    this.isForbidden = false,
    this.isValidationError = false,
    this.isRateLimited = false,
    this.retryAfterSeconds,
  });

  @override
  List<Object?> get props => [
        message,
        syncStatusMap,
        requiresLogout,
        isForbidden,
        isValidationError,
        isRateLimited,
        retryAfterSeconds,
      ];
}

class ExpenseSyncing extends ExpenseState {
  const ExpenseSyncing({super.syncStatusMap});
}

class ExpenseSynced extends ExpenseState {
  const ExpenseSynced({super.syncStatusMap});
}

class ExpenseSyncError extends ExpenseState {
  final String message;
  final bool requiresLogout;
  final bool isForbidden;
  final bool isValidationError;
  final bool isRateLimited;
  final int? retryAfterSeconds;

  const ExpenseSyncError(
    this.message, {
    super.syncStatusMap,
    this.requiresLogout = false,
    this.isForbidden = false,
    this.isValidationError = false,
    this.isRateLimited = false,
    this.retryAfterSeconds,
  });

  @override
  List<Object?> get props => [
        message,
        syncStatusMap,
        requiresLogout,
        isForbidden,
        isValidationError,
        isRateLimited,
        retryAfterSeconds,
      ];
}

class ExpenseApiError extends ExpenseState {
  final String message;
  final int? statusCode;

  const ExpenseApiError(this.message, {this.statusCode, super.syncStatusMap});

  @override
  List<Object?> get props => [message, statusCode, syncStatusMap];
}

class ExpenseQueueStatusUpdated extends ExpenseState {
  final int pendingCount;
  final int failedCount;

  const ExpenseQueueStatusUpdated({
    required this.pendingCount,
    required this.failedCount,
    super.syncStatusMap,
  });

  @override
  List<Object?> get props => [pendingCount, failedCount, syncStatusMap];
}

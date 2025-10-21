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

  const ExpenseError(this.message, {super.syncStatusMap});

  @override
  List<Object?> get props => [message, syncStatusMap];
}

class ExpenseSyncing extends ExpenseState {
  const ExpenseSyncing({super.syncStatusMap});
}

class ExpenseSynced extends ExpenseState {
  const ExpenseSynced({super.syncStatusMap});
}

class ExpenseSyncError extends ExpenseState {
  final String message;

  const ExpenseSyncError(this.message, {super.syncStatusMap});

  @override
  List<Object?> get props => [message, syncStatusMap];
}

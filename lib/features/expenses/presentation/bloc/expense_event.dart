import 'package:equatable/equatable.dart';
import '../../domain/entities/expense.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

class CreateExpenseRequested extends ExpenseEvent {
  final int userId;
  final String description;
  final double? priceUsd;
  final double? priceSyp;
  final double? priceTry;
  final InvoiceStatus invoiceStatus;
  final String? invoiceFilePath;
  final DateTime expenseDate;

  const CreateExpenseRequested({
    required this.userId,
    required this.description,
    this.priceUsd,
    this.priceSyp,
    this.priceTry,
    required this.invoiceStatus,
    this.invoiceFilePath,
    required this.expenseDate,
  });

  @override
  List<Object?> get props => [
        userId,
        description,
        priceUsd,
        priceSyp,
        priceTry,
        invoiceStatus,
        invoiceFilePath,
        expenseDate,
      ];
}

class LoadExpensesRequested extends ExpenseEvent {
  final int userId;

  const LoadExpensesRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateExpenseRequested extends ExpenseEvent {
  final Expense expense;
  final int currentUserId;

  const UpdateExpenseRequested({
    required this.expense,
    required this.currentUserId,
  });

  @override
  List<Object?> get props => [expense, currentUserId];
}

class DeleteExpenseRequested extends ExpenseEvent {
  final int expenseId;
  final int userId;

  const DeleteExpenseRequested({
    required this.expenseId,
    required this.userId,
  });

  @override
  List<Object?> get props => [expenseId, userId];
}

class SyncExpenseRequested extends ExpenseEvent {
  final Expense expense;

  const SyncExpenseRequested(this.expense);

  @override
  List<Object?> get props => [expense];
}

class SyncAllPendingRequested extends ExpenseEvent {
  const SyncAllPendingRequested();
}

class SyncStatusUpdated extends ExpenseEvent {
  final Map<int, SyncStatus> syncStatusMap;

  const SyncStatusUpdated(this.syncStatusMap);

  @override
  List<Object?> get props => [syncStatusMap];
}

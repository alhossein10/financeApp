import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/sync_service.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class CreateExpenseUseCase {
  final ExpenseRepository repository;
  final SyncService syncService;

  CreateExpenseUseCase({
    required this.repository,
    required this.syncService,
  });

  Future<Either<Failure, Expense>> call(CreateExpenseParams params) async {
    // Validate that at least one price is provided
    if (params.priceUsd == null &&
        params.priceSyp == null &&
        params.priceTry == null) {
      return Left(ValidationFailure('At least one price must be provided'));
    }

    // Validate that prices are positive if provided
    if (params.priceUsd != null && params.priceUsd! <= 0) {
      return Left(ValidationFailure('USD price must be greater than zero'));
    }
    if (params.priceSyp != null && params.priceSyp! <= 0) {
      return Left(ValidationFailure('SYP price must be greater than zero'));
    }
    if (params.priceTry != null && params.priceTry! <= 0) {
      return Left(ValidationFailure('TRY price must be greater than zero'));
    }

    // Validate description
    if (params.description.trim().isEmpty) {
      return Left(ValidationFailure('Description cannot be empty'));
    }

    // Validate expense date is not in the future
    if (params.expenseDate.isAfter(DateTime.now())) {
      return Left(ValidationFailure('Expense date cannot be in the future'));
    }

    // Create expense locally with sync_status = pending
    final result = await repository.createExpense(
      userId: params.userId,
      description: params.description,
      priceUsd: params.priceUsd,
      priceSyp: params.priceSyp,
      priceTry: params.priceTry,
      invoiceStatus: params.invoiceStatus,
      invoiceFilePath: params.invoiceFilePath,
      expenseDate: params.expenseDate,
    );

    // Queue expense for sync (fire and forget - don't block on sync)
    result.fold(
      (failure) {
        // If creation failed, don't attempt sync
      },
      (expense) {
        // Queue for sync asynchronously - don't wait for result
        // Sync errors are handled gracefully by the sync service
        syncService.syncExpense(expense).then((syncResult) {
          syncResult.fold(
            (failure) {
              // Sync failed - error is already logged in sync service
              // The expense remains in pending/failed state for retry
            },
            (_) {
              // Sync succeeded - status updated by sync service
            },
          );
        });
      },
    );

    return result;
  }
}

class CreateExpenseParams {
  final int userId;
  final String description;
  final double? priceUsd;
  final double? priceSyp;
  final double? priceTry;
  final InvoiceStatus invoiceStatus;
  final String? invoiceFilePath;
  final DateTime expenseDate;

  CreateExpenseParams({
    required this.userId,
    required this.description,
    this.priceUsd,
    this.priceSyp,
    this.priceTry,
    required this.invoiceStatus,
    this.invoiceFilePath,
    required this.expenseDate,
  });
}

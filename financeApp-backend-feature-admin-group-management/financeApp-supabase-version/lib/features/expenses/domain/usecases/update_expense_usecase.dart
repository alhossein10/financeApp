import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/auth_logger.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class UpdateExpenseUseCase {
  final ExpenseRepository repository;

  UpdateExpenseUseCase(this.repository);

  Future<Either<Failure, void>> call(UpdateExpenseParams params) async {
    // Validate that at least one price is provided
    if (params.expense.priceUsd == null &&
        params.expense.priceSyp == null &&
        params.expense.priceTry == null) {
      AuthLogger.logValidationFailure(
        operation: 'updateExpense',
        userId: params.currentUserId,
        validationError: 'At least one price must be provided',
      );
      return Left(ValidationFailure('At least one price must be provided'));
    }

    // Validate that prices are positive if provided
    if (params.expense.priceUsd != null && params.expense.priceUsd! <= 0) {
      AuthLogger.logValidationFailure(
        operation: 'updateExpense',
        userId: params.currentUserId,
        validationError: 'USD price must be greater than zero',
      );
      return Left(ValidationFailure('USD price must be greater than zero'));
    }
    if (params.expense.priceSyp != null && params.expense.priceSyp! <= 0) {
      AuthLogger.logValidationFailure(
        operation: 'updateExpense',
        userId: params.currentUserId,
        validationError: 'SYP price must be greater than zero',
      );
      return Left(ValidationFailure('SYP price must be greater than zero'));
    }
    if (params.expense.priceTry != null && params.expense.priceTry! <= 0) {
      AuthLogger.logValidationFailure(
        operation: 'updateExpense',
        userId: params.currentUserId,
        validationError: 'TRY price must be greater than zero',
      );
      return Left(ValidationFailure('TRY price must be greater than zero'));
    }

    // Validate description
    if (params.expense.description.trim().isEmpty) {
      AuthLogger.logValidationFailure(
        operation: 'updateExpense',
        userId: params.currentUserId,
        validationError: 'Description cannot be empty',
      );
      return Left(ValidationFailure('Description cannot be empty'));
    }

    // Validate expense date is not in the future
    if (params.expense.expenseDate.isAfter(DateTime.now())) {
      AuthLogger.logValidationFailure(
        operation: 'updateExpense',
        userId: params.currentUserId,
        validationError: 'Expense date cannot be in the future',
      );
      return Left(ValidationFailure('Expense date cannot be in the future'));
    }

    // Validate user ownership
    if (params.expense.userId != params.currentUserId) {
      AuthLogger.logUnauthorizedAccess(
        operation: 'updateExpense',
        attemptedUserId: params.currentUserId,
        resourceOwnerId: params.expense.userId,
        resourceType: 'expense',
        resourceId: params.expense.id,
        additionalInfo: 'User attempting to update expense owned by another user',
      );
      return Left(UnauthorizedFailure('Cannot update expense owned by another user'));
    }

    return await repository.updateExpense(params.expense);
  }
}

class UpdateExpenseParams {
  final Expense expense;
  final int currentUserId;

  UpdateExpenseParams({
    required this.expense,
    required this.currentUserId,
  });
}

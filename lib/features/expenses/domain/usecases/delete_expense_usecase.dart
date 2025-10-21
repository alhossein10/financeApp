import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/auth_logger.dart';
import '../repositories/expense_repository.dart';

class DeleteExpenseUseCase {
  final ExpenseRepository repository;

  DeleteExpenseUseCase(this.repository);

  Future<Either<Failure, void>> call(DeleteExpenseParams params) async {
    // Validate expense ID
    if (params.expenseId <= 0) {
      AuthLogger.logValidationFailure(
        operation: 'deleteExpense',
        userId: params.userId,
        validationError: 'Invalid expense ID',
      );
      return Left(ValidationFailure('Invalid expense ID'));
    }

    // Validate user ID
    if (params.userId <= 0) {
      AuthLogger.logValidationFailure(
        operation: 'deleteExpense',
        userId: params.userId,
        validationError: 'Invalid user ID',
      );
      return Left(ValidationFailure('Invalid user ID'));
    }

    return await repository.deleteExpense(params.expenseId, params.userId);
  }
}

class DeleteExpenseParams {
  final int expenseId;
  final int userId;

  DeleteExpenseParams({
    required this.expenseId,
    required this.userId,
  });
}

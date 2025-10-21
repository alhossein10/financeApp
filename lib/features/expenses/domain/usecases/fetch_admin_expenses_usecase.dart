import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

/// Use case for fetching all expenses from all users (admin-only)
/// 
/// This use case enforces role-based access control by requiring
/// the requesting user's ID and delegating authorization to the repository.
class FetchAdminExpensesUseCase {
  final ExpenseRepository repository;

  FetchAdminExpensesUseCase(this.repository);

  /// Fetch all expenses from all users
  /// 
  /// Parameters:
  /// - [requestingUserId]: ID of the user making the request
  /// 
  /// Returns:
  /// - Right(List<Expense>): List of all expenses if user is admin
  /// - Left(UnauthorizedFailure): If user is not admin or not authenticated
  /// - Left(DatabaseFailure): If database operation fails
  Future<Either<Failure, List<Expense>>> call(int requestingUserId) async {
    return await repository.fetchAdminExpenses(requestingUserId);
  }
}

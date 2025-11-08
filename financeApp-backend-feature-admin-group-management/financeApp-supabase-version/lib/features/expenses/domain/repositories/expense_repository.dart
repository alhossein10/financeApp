import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/expense.dart';

abstract class ExpenseRepository {
  Future<Either<Failure, Expense>> createExpense({
    required int userId,
    required String description,
    double? priceUsd,
    double? priceSyp,
    double? priceTry,
    required InvoiceStatus invoiceStatus,
    String? invoiceFilePath,
    required DateTime expenseDate,
  });

  Future<Either<Failure, List<Expense>>> getExpensesByUser(int userId);

  Future<Either<Failure, void>> updateExpense(Expense expense);

  Future<Either<Failure, void>> deleteExpense(int id, int userId);

  /// Fetch all expenses from all users (admin-only operation)
  /// Returns UnauthorizedFailure if called by non-admin user
  Future<Either<Failure, List<Expense>>> fetchAdminExpenses(int requestingUserId);
}

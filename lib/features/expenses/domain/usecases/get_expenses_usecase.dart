import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class GetExpensesUseCase {
  final ExpenseRepository repository;

  GetExpensesUseCase(this.repository);

  Future<Either<Failure, List<Expense>>> call(int userId) async {
    return await repository.getExpensesByUser(userId);
  }
}

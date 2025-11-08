import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/auth_logger.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../features/auth/domain/entities/user.dart';
import '../../../../features/auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_datasource.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource localDataSource;
  final AuthRepository authRepository;
  final SyncService? syncService;

  ExpenseRepositoryImpl({
    required this.localDataSource,
    required this.authRepository,
    this.syncService,
  });

  @override
  Future<Either<Failure, Expense>> createExpense({
    required int userId,
    required String description,
    double? priceUsd,
    double? priceSyp,
    double? priceTry,
    required InvoiceStatus invoiceStatus,
    String? invoiceFilePath,
    required DateTime expenseDate,
  }) async {
    try {
      final expense = await localDataSource.createExpense(
        userId: userId,
        description: description,
        priceUsd: priceUsd,
        priceSyp: priceSyp,
        priceTry: priceTry,
        invoiceStatus: invoiceStatus,
        invoiceFilePath: invoiceFilePath,
        expenseDate: expenseDate,
      );
      return Right(expense);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpensesByUser(int userId) async {
    try {
      final expenses = await localDataSource.getExpensesByUser(userId);
      return Right(expenses);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateExpense(Expense expense) async {
    try {
      final expenseModel = ExpenseModel.fromEntity(expense);
      await localDataSource.updateExpense(expenseModel);
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(int id, int userId) async {
    try {
      await localDataSource.deleteExpense(id, userId);
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> fetchAdminExpenses(
    int requestingUserId,
  ) async {
    try {
      // Get the requesting user to check their role
      final userResult = await authRepository.getCurrentUser();
      
      if (userResult.isLeft()) {
        AuthLogger.logUnauthorizedAccess(
          operation: 'fetchAdminExpenses',
          attemptedUserId: requestingUserId,
          resourceOwnerId: null,
          resourceType: 'all_expenses',
          additionalInfo: 'User not authenticated',
        );
        return const Left(UnauthorizedFailure('User not authenticated'));
      }

      final user = userResult.getOrElse(() => throw Exception());

      // Verify user ID matches
      if (user.id != requestingUserId) {
        AuthLogger.logUnauthorizedAccess(
          operation: 'fetchAdminExpenses',
          attemptedUserId: requestingUserId,
          resourceOwnerId: user.id,
          resourceType: 'all_expenses',
          additionalInfo: 'User ID mismatch',
        );
        return const Left(UnauthorizedFailure('User ID mismatch'));
      }

      // Check if user has admin role
      if (!user.isAdmin) {
        AuthLogger.logUnauthorizedAccess(
          operation: 'fetchAdminExpenses',
          attemptedUserId: requestingUserId,
          resourceOwnerId: null,
          resourceType: 'all_expenses',
          additionalInfo: 'Non-admin user attempted to access admin-only operation',
        );
        return const Left(
          UnauthorizedFailure('Admin privileges required to fetch all expenses'),
        );
      }

      // User is admin - fetch expenses from sync service
      if (syncService == null) {
        return const Left(
          DatabaseFailure('Sync service not available'),
        );
      }

      final result = await syncService!.fetchAdminExpenses();
      
      if (result.isRight()) {
        AuthLogger.logAuthorizedAccess(
          operation: 'fetchAdminExpenses',
          userId: requestingUserId,
          resourceType: 'all_expenses',
        );
      }

      return result;
    } on DatabaseException catch (e) {
      AuthLogger.logDatabaseError(
        operation: 'fetchAdminExpenses',
        userId: requestingUserId,
        error: e.message,
      );
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      AuthLogger.logDatabaseError(
        operation: 'fetchAdminExpenses',
        userId: requestingUserId,
        error: e.toString(),
      );
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }
}

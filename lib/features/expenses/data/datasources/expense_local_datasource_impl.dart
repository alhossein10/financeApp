import 'package:sqflite/sqflite.dart';
import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../../../../core/services/auth_logger.dart';
import '../models/expense_model.dart';
import '../../domain/entities/expense.dart';
import 'expense_local_datasource.dart';

class ExpenseLocalDataSourceImpl implements ExpenseLocalDataSource {
  final Database database;

  ExpenseLocalDataSourceImpl({required this.database});

  @override
  Future<ExpenseModel> createExpense({
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
      final now = DateTime.now();
      final expenseMap = {
        'user_id': userId,
        'description': description,
        'price_usd': priceUsd,
        'price_syp': priceSyp,
        'price_try': priceTry,
        'invoice_status': invoiceStatus.index,
        'invoice_file_path': invoiceFilePath,
        'expense_date': expenseDate.millisecondsSinceEpoch,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      };

      final id = await database.insert(
        'expenses',
        expenseMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return ExpenseModel(
        id: id,
        userId: userId,
        description: description,
        priceUsd: priceUsd,
        priceSyp: priceSyp,
        priceTry: priceTry,
        invoiceStatus: invoiceStatus,
        invoiceFilePath: invoiceFilePath,
        expenseDate: expenseDate,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to create expense: ${e.toString()}');
    }
  }

  @override
  Future<List<ExpenseModel>> getExpensesByUser(int userId) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        'expenses',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'expense_date DESC, created_at DESC',
      );

      return maps.map((map) => ExpenseModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get expenses: ${e.toString()}');
    }
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      // First verify the expense exists and belongs to the user
      final existing = await database.query(
        'expenses',
        where: 'id = ? AND user_id = ?',
        whereArgs: [expense.id, expense.userId],
      );

      if (existing.isEmpty) {
        AuthLogger.logUnauthorizedAccess(
          operation: 'updateExpense',
          attemptedUserId: expense.userId,
          resourceOwnerId: null,
          resourceType: 'expense',
          resourceId: expense.id,
          additionalInfo: 'Expense not found or does not belong to user',
        );
        throw app_exceptions.UnauthorizedException('Expense not found or unauthorized');
      }

      // Log authorized access
      AuthLogger.logAuthorizedAccess(
        operation: 'updateExpense',
        userId: expense.userId,
        resourceType: 'expense',
        resourceId: expense.id,
      );

      final now = DateTime.now();
      final expenseMap = expense.toMap();
      expenseMap['updated_at'] = now.millisecondsSinceEpoch;

      final count = await database.update(
        'expenses',
        expenseMap,
        where: 'id = ? AND user_id = ?',
        whereArgs: [expense.id, expense.userId],
      );

      if (count == 0) {
        AuthLogger.logUnauthorizedAccess(
          operation: 'updateExpense',
          attemptedUserId: expense.userId,
          resourceOwnerId: null,
          resourceType: 'expense',
          resourceId: expense.id,
          additionalInfo: 'Update failed - expense not found or unauthorized',
        );
        throw app_exceptions.UnauthorizedException('Expense not found or unauthorized');
      }
    } catch (e) {
      if (e is app_exceptions.UnauthorizedException) rethrow;
      throw app_exceptions.DatabaseException('Failed to update expense: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteExpense(int id, int userId) async {
    try {
      // First verify the expense exists and belongs to the user
      final existing = await database.query(
        'expenses',
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );

      if (existing.isEmpty) {
        AuthLogger.logUnauthorizedAccess(
          operation: 'deleteExpense',
          attemptedUserId: userId,
          resourceOwnerId: null,
          resourceType: 'expense',
          resourceId: id,
          additionalInfo: 'Expense not found or does not belong to user',
        );
        throw app_exceptions.UnauthorizedException('Expense not found or unauthorized');
      }

      // Log authorized access
      AuthLogger.logAuthorizedAccess(
        operation: 'deleteExpense',
        userId: userId,
        resourceType: 'expense',
        resourceId: id,
      );

      final count = await database.delete(
        'expenses',
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );

      if (count == 0) {
        AuthLogger.logUnauthorizedAccess(
          operation: 'deleteExpense',
          attemptedUserId: userId,
          resourceOwnerId: null,
          resourceType: 'expense',
          resourceId: id,
          additionalInfo: 'Delete failed - expense not found or unauthorized',
        );
        throw app_exceptions.UnauthorizedException('Expense not found or unauthorized');
      }
    } catch (e) {
      if (e is app_exceptions.UnauthorizedException) rethrow;
      throw app_exceptions.DatabaseException('Failed to delete expense: ${e.toString()}');
    }
  }

  @override
  Future<void> updateSyncStatus(int expenseId, SyncStatus status) async {
    try {
      final now = DateTime.now();
      final updateMap = {
        'sync_status': status.index,
        'updated_at': now.millisecondsSinceEpoch,
      };

      // If status is synced, update synced_at timestamp
      if (status == SyncStatus.synced) {
        updateMap['synced_at'] = now.millisecondsSinceEpoch;
      }

      final count = await database.update(
        'expenses',
        updateMap,
        where: 'id = ?',
        whereArgs: [expenseId],
      );

      if (count == 0) {
        throw app_exceptions.NotFoundException('Expense not found');
      }
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException('Failed to update sync status: ${e.toString()}');
    }
  }

  @override
  Future<void> updateCloudFileId(int expenseId, String? fileId) async {
    try {
      final now = DateTime.now();
      final count = await database.update(
        'expenses',
        {
          'invoice_cloud_file_id': fileId,
          'updated_at': now.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [expenseId],
      );

      if (count == 0) {
        throw app_exceptions.NotFoundException('Expense not found');
      }
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException('Failed to update cloud file ID: ${e.toString()}');
    }
  }

  @override
  Future<List<ExpenseModel>> getExpensesBySyncStatus(SyncStatus status) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        'expenses',
        where: 'sync_status = ?',
        whereArgs: [status.index],
        orderBy: 'created_at ASC',
      );

      return maps.map((map) => ExpenseModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get expenses by sync status: ${e.toString()}');
    }
  }

  @override
  Future<void> incrementSyncRetryCount(int expenseId) async {
    try {
      final now = DateTime.now();
      
      // Get current retry count
      final result = await database.query(
        'expenses',
        columns: ['sync_retry_count'],
        where: 'id = ?',
        whereArgs: [expenseId],
      );

      if (result.isEmpty) {
        throw app_exceptions.NotFoundException('Expense not found');
      }

      final currentCount = result.first['sync_retry_count'] as int? ?? 0;
      
      final count = await database.update(
        'expenses',
        {
          'sync_retry_count': currentCount + 1,
          'updated_at': now.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [expenseId],
      );

      if (count == 0) {
        throw app_exceptions.NotFoundException('Expense not found');
      }
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException('Failed to increment sync retry count: ${e.toString()}');
    }
  }

  @override
  Future<void> updateSyncErrorMessage(int expenseId, String? errorMessage) async {
    try {
      final now = DateTime.now();
      final count = await database.update(
        'expenses',
        {
          'sync_error_message': errorMessage,
          'updated_at': now.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [expenseId],
      );

      if (count == 0) {
        throw app_exceptions.NotFoundException('Expense not found');
      }
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException('Failed to update sync error message: ${e.toString()}');
    }
  }
}


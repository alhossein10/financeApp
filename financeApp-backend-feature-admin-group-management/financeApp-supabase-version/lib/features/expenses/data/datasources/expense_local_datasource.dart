import '../models/expense_model.dart';
import '../../domain/entities/expense.dart';

abstract class ExpenseLocalDataSource {
  /// Creates a new expense in the database
  /// Throws [DatabaseException] if the operation fails
  Future<ExpenseModel> createExpense({
    required int userId,
    required String description,
    double? priceUsd,
    double? priceSyp,
    double? priceTry,
    required InvoiceStatus invoiceStatus,
    String? invoiceFilePath,
    required DateTime expenseDate,
  });

  /// Retrieves all expenses for a specific user
  /// Throws [DatabaseException] if the operation fails
  Future<List<ExpenseModel>> getExpensesByUser(int userId);

  /// Updates an existing expense
  /// Throws [DatabaseException] if the operation fails
  /// Throws [NotFoundException] if the expense doesn't exist
  Future<void> updateExpense(ExpenseModel expense);

  /// Deletes an expense by ID for a specific user
  /// Throws [DatabaseException] if the operation fails
  /// Throws [UnauthorizedException] if the expense doesn't belong to the user
  Future<void> deleteExpense(int id, int userId);

  /// Update the sync status of an expense
  /// Throws [DatabaseException] if the operation fails
  /// Throws [NotFoundException] if the expense doesn't exist
  Future<void> updateSyncStatus(int expenseId, SyncStatus status);

  /// Update the cloud file ID of an expense
  /// Throws [DatabaseException] if the operation fails
  /// Throws [NotFoundException] if the expense doesn't exist
  Future<void> updateCloudFileId(int expenseId, String? fileId);

  /// Get all expenses with a specific sync status
  /// Throws [DatabaseException] if the operation fails
  Future<List<ExpenseModel>> getExpensesBySyncStatus(SyncStatus status);

  /// Increment the sync retry count for an expense
  /// Throws [DatabaseException] if the operation fails
  /// Throws [NotFoundException] if the expense doesn't exist
  Future<void> incrementSyncRetryCount(int expenseId);

  /// Update the sync error message for an expense
  /// Throws [DatabaseException] if the operation fails
  /// Throws [NotFoundException] if the expense doesn't exist
  Future<void> updateSyncErrorMessage(int expenseId, String? errorMessage);
}

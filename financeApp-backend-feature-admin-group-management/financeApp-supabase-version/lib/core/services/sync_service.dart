import 'package:dartz/dartz.dart';
import '../../features/expenses/domain/entities/expense.dart';
import '../error/failures.dart';
import '../models/sync_status.dart';

/// Abstract interface for synchronization operations
/// Handles one-way sync from User version to Admin version via Supabase
abstract class SyncService {
  /// Synchronize a single expense to the cloud
  /// 
  /// This method uploads the expense data and any associated invoice image
  /// to Supabase, making it available to the Admin version.
  /// 
  /// Parameters:
  /// - [expense]: The expense to synchronize
  /// 
  /// Returns:
  /// - Right(void): Success
  /// - Left(Failure): Error if sync fails
  Future<Either<Failure, void>> syncExpense(Expense expense);
  
  /// Synchronize all pending expenses to the cloud
  /// 
  /// This method processes all expenses with sync_status = pending
  /// in batch mode with delays to avoid rate limiting.
  /// 
  /// Returns:
  /// - Right(void): Success (all or partial sync completed)
  /// - Left(Failure): Error if batch sync fails completely
  Future<Either<Failure, void>> syncPendingExpenses();
  
  /// Fetch all expenses from the cloud (Admin only)
  /// 
  /// This method retrieves all user-submitted expenses from Supabase.
  /// Only accessible when running in Admin flavor.
  /// 
  /// Returns:
  /// - Right(List<Expense>): List of all synced expenses
  /// - Left(Failure): Error if fetch fails or unauthorized
  Future<Either<Failure, List<Expense>>> fetchAdminExpenses();
  
  /// Watch the sync status of a specific expense
  /// 
  /// Returns a stream that emits sync status updates for the given expense.
  /// 
  /// Parameters:
  /// - [expenseId]: ID of the expense to watch
  /// 
  /// Returns:
  /// - Stream of SyncStatus updates
  Stream<SyncStatus> watchSyncStatus(int expenseId);
  
  /// Start automatic background synchronization
  /// 
  /// Starts a periodic timer that syncs pending expenses every 5 minutes.
  /// Should be called when the app starts or when connectivity is restored.
  Future<void> startAutoSync();
  
  /// Stop automatic background synchronization
  /// 
  /// Cancels the periodic sync timer.
  /// Should be called when the app is paused or closed.
  Future<void> stopAutoSync();
}

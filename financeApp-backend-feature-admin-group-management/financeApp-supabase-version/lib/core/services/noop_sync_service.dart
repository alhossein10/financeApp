import 'package:dartz/dartz.dart';
import '../../features/expenses/domain/entities/expense.dart';
import '../error/failures.dart';
import 'sync_service.dart';

/// No-op implementation of SyncService for testing and development
/// This service does nothing and is used as a placeholder until
/// the full CloudSyncService is properly configured with PocketBase
class NoOpSyncService implements SyncService {
  @override
  Future<Either<Failure, void>> syncExpense(Expense expense) async {
    // No-op: return success immediately
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> syncPendingExpenses() async {
    // No-op: return success immediately
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Expense>>> fetchAdminExpenses() async {
    // No-op: return empty list
    return const Right([]);
  }

  @override
  Stream<SyncStatus> watchSyncStatus(int expenseId) {
    // No-op: return stream that emits synced status
    return Stream.value(SyncStatus.synced);
  }

  @override
  Future<void> startAutoSync() async {
    // No-op: do nothing
  }

  @override
  Future<void> stopAutoSync() async {
    // No-op: do nothing
  }
}

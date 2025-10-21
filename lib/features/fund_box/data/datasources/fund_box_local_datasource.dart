import '../models/fund_box_model.dart';

/// Abstract interface for fund box local data source
/// Defines the contract for local database operations
abstract class FundBoxLocalDataSource {
  /// Get fund box for a specific user from the database
  /// Throws [DatabaseException] if operation fails
  Future<FundBoxModel> getFundBoxByUser(int userId);

  /// Update fund box balance for a specific user
  /// Throws [DatabaseException] if operation fails
  Future<FundBoxModel> updateFundBalance({
    required int userId,
    required double newBalance,
  });

  /// Initialize a new fund box for a user
  /// Throws [DatabaseException] if operation fails
  Future<FundBoxModel> initializeFundBox(int userId);

  /// Check if a fund box exists for a user
  /// Returns true if exists, false otherwise
  Future<bool> fundBoxExists(int userId);
}

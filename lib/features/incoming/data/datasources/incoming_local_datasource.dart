import '../models/incoming_model.dart';

abstract class IncomingLocalDataSource {
  /// Creates a new incoming transaction for a specific user
  /// Throws [DatabaseException] if the operation fails
  Future<IncomingModel> createIncoming({
    required int userId,
    required String description,
    required double amountUsd,
    DateTime? transactionDate,
  });

  /// Gets all incoming transactions for a specific user
  /// Throws [DatabaseException] if the operation fails
  Future<List<IncomingModel>> getIncomingByUser(int userId);

  /// Updates an existing incoming transaction
  /// Throws [DatabaseException] if the operation fails
  Future<void> updateIncoming(IncomingModel incoming);

  /// Deletes an incoming transaction
  /// If refund is true, adds the amount back to the user's fund box
  /// Throws [DatabaseException] if the operation fails
  Future<void> deleteIncoming(int id, int userId, {bool refund = false});
}

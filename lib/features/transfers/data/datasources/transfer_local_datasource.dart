import '../models/transfer_model.dart';

abstract class TransferLocalDataSource {
  /// Creates a new transfer for the specified user
  /// Throws [DatabaseException] if the operation fails
  Future<TransferModel> createTransfer({
    required int userId,
    required String recipientName,
    required double amountUsd,
    double? convertedAmountUsd,
    double? amountSypAtExchange,
    double? manualUsdToSypRate,
    DateTime? transactionDate,
  });

  /// Retrieves all transfers for the specified user
  /// Throws [DatabaseException] if the operation fails
  Future<List<TransferModel>> getTransfersByUser(int userId);

  /// Updates an existing transfer
  /// Throws [DatabaseException] if the operation fails
  /// Throws [UnauthorizedException] if the transfer doesn't belong to the user
  Future<void> updateTransfer(TransferModel transfer);

  /// Deletes a transfer by ID for the specified user
  /// Throws [DatabaseException] if the operation fails
  /// Throws [UnauthorizedException] if the transfer doesn't belong to the user
  Future<void> deleteTransfer(int id, int userId, {bool refund = false});

  /// Gets a single transfer by ID for the specified user
  /// Throws [DatabaseException] if the operation fails
  /// Throws [NotFoundException] if the transfer doesn't exist
  /// Throws [UnauthorizedException] if the transfer doesn't belong to the user
  Future<TransferModel> getTransferById(int id, int userId);
}

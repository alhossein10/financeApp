import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/transfer.dart';

abstract class TransferRepository {
  Future<Either<Failure, Transfer>> createTransfer({
    required int userId,
    required String recipientName,
    int? recipientUserId, // ID of the recipient user (required for SuperAdmin transfers to admins)
    int? adminGroupId, // Admin group ID for the transfer (should be set from recipient's admin_group_id for SuperAdmin transfers)
    required double amountUsd,
    double? convertedAmountUsd,
    double? amountSypAtExchange,
    double? manualUsdToSypRate,
    DateTime? transactionDate,
  });

  Future<Either<Failure, List<Transfer>>> getTransfersByUser(int userId);

  Future<Either<Failure, void>> updateTransfer(Transfer transfer);

  Future<Either<Failure, void>> deleteTransfer(
    int id,
    int userId, {
    bool refund = false,
  });
}

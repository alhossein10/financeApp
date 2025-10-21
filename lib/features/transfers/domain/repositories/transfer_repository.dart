import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/transfer.dart';

abstract class TransferRepository {
  Future<Either<Failure, Transfer>> createTransfer({
    required int userId,
    required String recipientName,
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

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/transfer.dart';
import '../repositories/transfer_repository.dart';

class CreateTransferUseCase {
  final TransferRepository repository;

  CreateTransferUseCase(this.repository);

  Future<Either<Failure, Transfer>> call(CreateTransferParams params) async {
    // Validate amount
    if (params.amountUsd <= 0) {
      return Left(ValidationFailure('Amount must be greater than zero'));
    }

    // Validate recipient name
    if (params.recipientName.trim().isEmpty) {
      return Left(ValidationFailure('Recipient name cannot be empty'));
    }

    // Validate converted amount doesn't exceed total
    if (params.convertedAmountUsd != null &&
        params.convertedAmountUsd! > params.amountUsd) {
      return Left(
          ValidationFailure('Converted amount cannot exceed total amount'));
    }

    // Validate manual rate is positive if provided
    if (params.manualUsdToSypRate != null && params.manualUsdToSypRate! <= 0) {
      return Left(ValidationFailure('Exchange rate must be greater than zero'));
    }

    // Create transfer
    return await repository.createTransfer(
      userId: params.userId,
      recipientName: params.recipientName,
      recipientUserId: params.recipientUserId,
      adminGroupId: params.adminGroupId,
      amountUsd: params.amountUsd,
      convertedAmountUsd: params.convertedAmountUsd,
      amountSypAtExchange: params.amountSypAtExchange,
      manualUsdToSypRate: params.manualUsdToSypRate,
      transactionDate: params.transactionDate,
    );
  }
}

class CreateTransferParams {
  final int userId;
  final String recipientName;
  final int? recipientUserId; // ID of the recipient user (required for SuperAdmin transfers to admins)
  final int? adminGroupId; // Admin group ID for the transfer (should be set from recipient's admin_group_id for SuperAdmin transfers)
  final double amountUsd;
  final double? convertedAmountUsd;
  final double? amountSypAtExchange;
  final double? manualUsdToSypRate;
  final DateTime? transactionDate;

  CreateTransferParams({
    required this.userId,
    required this.recipientName,
    this.recipientUserId,
    this.adminGroupId,
    required this.amountUsd,
    this.convertedAmountUsd,
    this.amountSypAtExchange,
    this.manualUsdToSypRate,
    this.transactionDate,
  });
}

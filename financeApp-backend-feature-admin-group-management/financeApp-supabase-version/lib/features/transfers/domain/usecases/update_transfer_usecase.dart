import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/auth_logger.dart';
import '../entities/transfer.dart';
import '../repositories/transfer_repository.dart';

class UpdateTransferUseCase {
  final TransferRepository repository;

  UpdateTransferUseCase(this.repository);

  Future<Either<Failure, void>> call(UpdateTransferParams params) async {
    // Validate transfer has an ID
    if (params.transfer.id == null) {
      AuthLogger.logValidationFailure(
        operation: 'updateTransfer',
        userId: params.transfer.userId,
        validationError: 'Transfer ID is required for update',
      );
      return Left(ValidationFailure('Transfer ID is required for update'));
    }

    // Validate user ID
    if (params.transfer.userId <= 0) {
      AuthLogger.logValidationFailure(
        operation: 'updateTransfer',
        userId: params.transfer.userId,
        validationError: 'Invalid user ID',
      );
      return Left(ValidationFailure('Invalid user ID'));
    }

    // Validate user ownership if currentUserId is provided
    if (params.currentUserId != null && params.transfer.userId != params.currentUserId) {
      AuthLogger.logUnauthorizedAccess(
        operation: 'updateTransfer',
        attemptedUserId: params.currentUserId!,
        resourceOwnerId: params.transfer.userId,
        resourceType: 'transfer',
        resourceId: params.transfer.id,
        additionalInfo: 'User attempting to update transfer owned by another user',
      );
      return Left(UnauthorizedFailure('Cannot update transfer owned by another user'));
    }

    // Validate amount
    if (params.transfer.amountUsd <= 0) {
      AuthLogger.logValidationFailure(
        operation: 'updateTransfer',
        userId: params.transfer.userId,
        validationError: 'Amount must be greater than zero',
      );
      return Left(ValidationFailure('Amount must be greater than zero'));
    }

    // Validate recipient name
    if (params.transfer.recipientName.trim().isEmpty) {
      AuthLogger.logValidationFailure(
        operation: 'updateTransfer',
        userId: params.transfer.userId,
        validationError: 'Recipient name cannot be empty',
      );
      return Left(ValidationFailure('Recipient name cannot be empty'));
    }

    // Validate converted amount doesn't exceed total
    if (params.transfer.convertedAmountUsd != null &&
        params.transfer.convertedAmountUsd! > params.transfer.amountUsd) {
      AuthLogger.logValidationFailure(
        operation: 'updateTransfer',
        userId: params.transfer.userId,
        validationError: 'Converted amount cannot exceed total amount',
      );
      return Left(
          ValidationFailure('Converted amount cannot exceed total amount'));
    }

    // Validate manual rate is positive if provided
    if (params.transfer.manualUsdToSypRate != null &&
        params.transfer.manualUsdToSypRate! <= 0) {
      AuthLogger.logValidationFailure(
        operation: 'updateTransfer',
        userId: params.transfer.userId,
        validationError: 'Exchange rate must be greater than zero',
      );
      return Left(ValidationFailure('Exchange rate must be greater than zero'));
    }

    return await repository.updateTransfer(params.transfer);
  }
}

class UpdateTransferParams {
  final Transfer transfer;
  final int? currentUserId;

  UpdateTransferParams({
    required this.transfer,
    this.currentUserId,
  });
}

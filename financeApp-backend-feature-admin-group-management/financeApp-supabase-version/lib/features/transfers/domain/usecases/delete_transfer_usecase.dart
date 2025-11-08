import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/auth_logger.dart';
import '../repositories/transfer_repository.dart';

class DeleteTransferUseCase {
  final TransferRepository repository;

  DeleteTransferUseCase(this.repository);

  Future<Either<Failure, void>> call(DeleteTransferParams params) async {
    if (params.transferId <= 0) {
      AuthLogger.logValidationFailure(
        operation: 'deleteTransfer',
        userId: params.userId,
        validationError: 'Invalid transfer ID',
      );
      return Left(ValidationFailure('Invalid transfer ID'));
    }

    if (params.userId <= 0) {
      AuthLogger.logValidationFailure(
        operation: 'deleteTransfer',
        userId: params.userId,
        validationError: 'Invalid user ID',
      );
      return Left(ValidationFailure('Invalid user ID'));
    }

    return await repository.deleteTransfer(
      params.transferId,
      params.userId,
      refund: params.refund,
    );
  }
}

class DeleteTransferParams {
  final int transferId;
  final int userId;
  final bool refund;

  DeleteTransferParams({
    required this.transferId,
    required this.userId,
    this.refund = false,
  });
}

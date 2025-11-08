import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/transfer.dart';
import '../repositories/transfer_repository.dart';

class GetTransfersUseCase {
  final TransferRepository repository;

  GetTransfersUseCase(this.repository);

  Future<Either<Failure, List<Transfer>>> call(int userId) async {
    if (userId <= 0) {
      return Left(ValidationFailure('Invalid user ID'));
    }

    return await repository.getTransfersByUser(userId);
  }
}

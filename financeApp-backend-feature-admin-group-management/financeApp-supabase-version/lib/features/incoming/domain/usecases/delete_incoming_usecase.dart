import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/incoming_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class DeleteIncomingUseCase {
  final IncomingRepository incomingRepository;
  final AuthRepository authRepository;

  DeleteIncomingUseCase({
    required this.incomingRepository,
    required this.authRepository,
  });

  Future<Either<Failure, void>> call(DeleteIncomingParams params) async {
    // Get current user
    final userResult = await authRepository.getCurrentUser();
    if (userResult.isLeft()) {
      return Left(UnauthorizedFailure());
    }

    final user = userResult.getOrElse(() => throw Exception());

    // Delete incoming transaction
    return await incomingRepository.deleteIncoming(
      params.id,
      user.id,
      refund: params.refund,
    );
  }
}

class DeleteIncomingParams {
  final int id;
  final bool refund;

  DeleteIncomingParams({
    required this.id,
    this.refund = false,
  });
}

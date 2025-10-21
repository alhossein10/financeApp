import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/incoming.dart';
import '../repositories/incoming_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class GetIncomingUseCase {
  final IncomingRepository incomingRepository;
  final AuthRepository authRepository;

  GetIncomingUseCase({
    required this.incomingRepository,
    required this.authRepository,
  });

  Future<Either<Failure, List<Incoming>>> call() async {
    // Get current user
    final userResult = await authRepository.getCurrentUser();
    if (userResult.isLeft()) {
      return Left(UnauthorizedFailure());
    }

    final user = userResult.getOrElse(() => throw Exception());

    // Get incoming transactions for the user
    return await incomingRepository.getIncomingByUser(user.id);
  }
}

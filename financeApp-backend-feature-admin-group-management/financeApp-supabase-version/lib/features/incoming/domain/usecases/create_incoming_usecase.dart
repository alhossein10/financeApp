import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/incoming.dart';
import '../../domain/repositories/incoming_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class CreateIncomingUseCase {
  final IncomingRepository incomingRepository;
  final AuthRepository authRepository;

  CreateIncomingUseCase({
    required this.incomingRepository,
    required this.authRepository,
  });

  Future<Either<Failure, Incoming>> call(CreateIncomingParams params) async {
    // Get current user
    final userResult = await authRepository.getCurrentUser();
    if (userResult.isLeft()) {
      return Left(UnauthorizedFailure());
    }

    final user = userResult.getOrElse(() => throw Exception());

    // Validate amount
    if (params.amountUsd <= 0) {
      return Left(ValidationFailure('Amount must be greater than zero'));
    }

    // Validate description
    if (params.description.trim().isEmpty) {
      return Left(ValidationFailure('Description cannot be empty'));
    }

    // Create incoming transaction
    return await incomingRepository.createIncoming(
      userId: user.id,
      description: params.description,
      amountUsd: params.amountUsd,
      transactionDate: params.transactionDate,
    );
  }
}

class CreateIncomingParams {
  final String description;
  final double amountUsd;
  final DateTime? transactionDate;

  CreateIncomingParams({
    required this.description,
    required this.amountUsd,
    this.transactionDate,
  });
}

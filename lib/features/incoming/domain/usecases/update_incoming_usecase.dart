import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/auth_logger.dart';
import '../entities/incoming.dart';
import '../repositories/incoming_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class UpdateIncomingUseCase {
  final IncomingRepository incomingRepository;
  final AuthRepository authRepository;

  UpdateIncomingUseCase({
    required this.incomingRepository,
    required this.authRepository,
  });

  Future<Either<Failure, void>> call(Incoming incoming) async {
    // Get current user
    final userResult = await authRepository.getCurrentUser();
    if (userResult.isLeft()) {
      AuthLogger.logUnauthorizedAccess(
        operation: 'updateIncoming',
        attemptedUserId: incoming.userId,
        resourceOwnerId: null,
        resourceType: 'incoming',
        resourceId: incoming.id,
        additionalInfo: 'No authenticated user found',
      );
      return Left(UnauthorizedFailure('User not authenticated'));
    }

    final user = userResult.getOrElse(() => throw Exception());

    // Verify user owns this incoming transaction
    if (incoming.userId != user.id) {
      AuthLogger.logUnauthorizedAccess(
        operation: 'updateIncoming',
        attemptedUserId: user.id,
        resourceOwnerId: incoming.userId,
        resourceType: 'incoming',
        resourceId: incoming.id,
        additionalInfo: 'User attempting to update incoming transaction owned by another user',
      );
      return Left(UnauthorizedFailure('Cannot update incoming transaction owned by another user'));
    }

    // Validate amount
    if (incoming.amountUsd <= 0) {
      AuthLogger.logValidationFailure(
        operation: 'updateIncoming',
        userId: user.id,
        validationError: 'Amount must be greater than zero',
      );
      return Left(ValidationFailure('Amount must be greater than zero'));
    }

    // Validate description
    if (incoming.description.trim().isEmpty) {
      AuthLogger.logValidationFailure(
        operation: 'updateIncoming',
        userId: user.id,
        validationError: 'Description cannot be empty',
      );
      return Left(ValidationFailure('Description cannot be empty'));
    }

    // Update incoming transaction
    return await incomingRepository.updateIncoming(incoming);
  }
}

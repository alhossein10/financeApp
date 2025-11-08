import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/validators.dart';
import '../repositories/auth_repository.dart';

/// Use case for password reset with validation
class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  /// Execute password reset for a user by email
  /// Validates email format before attempting reset
  Future<Either<Failure, void>> call(ResetPasswordParams params) async {
    // Validate email format
    if (!Validators.isValidEmail(params.email)) {
      return const Left(ValidationFailure('Invalid email format'));
    }

    // Attempt password reset
    return await repository.resetPassword(params.email);
  }
}

/// Parameters for reset password use case
class ResetPasswordParams {
  final String email;

  const ResetPasswordParams({
    required this.email,
  });
}

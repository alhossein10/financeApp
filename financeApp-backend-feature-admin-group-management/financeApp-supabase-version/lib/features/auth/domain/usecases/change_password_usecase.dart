import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/validators.dart';
import '../repositories/auth_repository.dart';

/// Use case for changing password with validation
class ChangePasswordUseCase {
  final AuthRepository repository;

  ChangePasswordUseCase(this.repository);

  /// Execute password change for the current user
  /// Validates passwords before attempting change
  Future<Either<Failure, void>> call(ChangePasswordParams params) async {
    // Validate old password is not empty
    if (params.oldPassword.isEmpty) {
      return const Left(ValidationFailure('Current password cannot be empty'));
    }

    // Validate new password strength
    if (!Validators.isStrongPassword(params.newPassword)) {
      return const Left(ValidationFailure(
        'Password must be at least 8 characters with uppercase, lowercase, and number',
      ));
    }

    // Validate passwords are different
    if (params.oldPassword == params.newPassword) {
      return const Left(ValidationFailure('New password must be different from current password'));
    }

    // Attempt password change
    return await repository.changePassword(
      params.oldPassword,
      params.newPassword,
    );
  }
}

/// Parameters for change password use case
class ChangePasswordParams {
  final String oldPassword;
  final String newPassword;

  const ChangePasswordParams({
    required this.oldPassword,
    required this.newPassword,
  });
}

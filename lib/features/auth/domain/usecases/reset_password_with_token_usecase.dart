import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/validators.dart';
import '../repositories/auth_repository.dart';

/// Use case for resetting password with token
class ResetPasswordWithTokenUseCase {
  final AuthRepository repository;

  ResetPasswordWithTokenUseCase(this.repository);

  /// Execute password reset with token from email
  /// Validates inputs before attempting reset
  Future<Either<Failure, void>> call(ResetPasswordWithTokenParams params) async {
    // Validate email format
    if (!Validators.isValidEmail(params.email)) {
      return const Left(ValidationFailure('Invalid email format'));
    }

    // Validate token
    if (params.token.isEmpty) {
      return const Left(ValidationFailure('Reset token is required'));
    }

    // Validate password
    final passwordError = Validators.validatePassword(params.password);
    if (passwordError != null) {
      return Left(ValidationFailure(passwordError));
    }

    // Reset password with token
    return await repository.resetPasswordWithToken(
      params.token,
      params.email,
      params.password,
    );
  }
}

/// Parameters for reset password with token use case
class ResetPasswordWithTokenParams {
  final String token;
  final String email;
  final String password;

  const ResetPasswordWithTokenParams({
    required this.token,
    required this.email,
    required this.password,
  });
}

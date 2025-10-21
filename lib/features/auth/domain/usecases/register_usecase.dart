import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/validators.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for user registration with validation
class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  /// Execute registration with username, email, and password
  /// Validates all inputs before attempting registration
  Future<Either<Failure, User>> call(RegisterParams params) async {
    // Validate username
    if (params.username.isEmpty) {
      return const Left(ValidationFailure('Username cannot be empty'));
    }

    if (params.username.length < 3) {
      return const Left(
          ValidationFailure('Username must be at least 3 characters'));
    }

    if (params.username.length > 30) {
      return const Left(
          ValidationFailure('Username must not exceed 30 characters'));
    }

    // Validate email format
    if (!Validators.isValidEmail(params.email)) {
      return const Left(ValidationFailure('Invalid email format'));
    }

    // Validate password strength
    final passwordValidation = Validators.validatePassword(params.password);
    if (passwordValidation != null) {
      return Left(ValidationFailure(passwordValidation));
    }

    // Validate password confirmation
    if (params.password != params.confirmPassword) {
      return const Left(ValidationFailure('Passwords do not match'));
    }

    // Attempt registration
    return await repository.register(
      params.username,
      params.email,
      params.password,
    );
  }
}

/// Parameters for register use case
class RegisterParams {
  final String username;
  final String email;
  final String password;
  final String confirmPassword;

  const RegisterParams({
    required this.username,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });
}

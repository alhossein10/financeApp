import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/validators.dart';
import '../entities/registration_result.dart';
import '../repositories/auth_repository.dart';

/// Use case for user registration with validation
class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  /// Execute registration with username, email, and password
  /// Validates all inputs before attempting registration
  Future<Either<Failure, RegistrationResult>> call(RegisterParams params) async {
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

    // Validate group code for regular users
    if (params.role == 'user') {
      if (params.groupCode == null || params.groupCode!.isEmpty) {
        return const Left(ValidationFailure('Group code is required for users'));
      }
      
      if (params.groupCode!.length != 6) {
        return const Left(ValidationFailure('Group code must be exactly 6 characters'));
      }
      
      // Validate alphanumeric
      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(params.groupCode!)) {
        return const Left(ValidationFailure('Group code must contain only letters and numbers'));
      }
    }

    // Attempt registration
    return await repository.register(
      params.username,
      params.email,
      params.password,
      organizationName: params.organizationName,
      departmentName: params.departmentName,
      adminGroupName: params.adminGroupName,
      groupCode: params.groupCode,
      superAdminGroupCode: params.superAdminGroupCode,
      role: params.role,
    );
  }
}

/// Parameters for register use case
class RegisterParams {
  final String username;
  final String email;
  final String password;
  final String confirmPassword;
  final String? organizationName;
  final String? departmentName;
  final String? adminGroupName; // SuperAdmin group name (for SuperAdmin registration)
  final String? groupCode; // Admin group code (for users joining admin groups)
  final String? superAdminGroupCode; // SuperAdmin group code (for admins joining SuperAdmin groups)
  final String role;

  const RegisterParams({
    required this.username,
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.organizationName,
    this.departmentName,
    this.adminGroupName,
    this.groupCode,
    this.superAdminGroupCode,
    this.role = 'user',
  });
}

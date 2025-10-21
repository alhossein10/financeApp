import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/pocketbase_service.dart';
import '../../../../core/utils/validators.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for user login with validation
class LoginUseCase {
  final AuthRepository repository;
  final SecureStorageService secureStorageService;

  LoginUseCase(this.repository, this.secureStorageService);

  /// Execute login with email and password
  /// Validates input before attempting login
  Future<Either<Failure, User>> call(LoginParams params) async {
    // Validate email format
    if (!Validators.isValidEmail(params.email)) {
      return const Left(ValidationFailure('Invalid email format'));
    }

    // Validate password is not empty
    if (params.password.isEmpty) {
      return const Left(ValidationFailure('Password cannot be empty'));
    }

    // Attempt local login first
    final result = await repository.login(params.email, params.password);
    
    // If local login successful, try to authenticate with PocketBase
    if (result.isRight()) {
      // If remember me is checked, store credentials
      if (params.rememberMe) {
        await secureStorageService.storeCredentials(
          email: params.email,
          password: params.password,
        );
      } else {
        // If remember me is not checked, clear any stored credentials
        await secureStorageService.clearStoredCredentials();
      }
      
      // Try PocketBase login (non-blocking)
      try {
        final pbService = PocketBaseService();
        final pbAuth = await pbService.login(params.email, params.password);
        print('[Login] PocketBase authentication successful');
        print('[Login] PocketBase user role: ${pbAuth.record?.data['role']}');
      } catch (e) {
        // PocketBase login failed, but local login succeeded
        // Continue with local authentication only
        print('[Login] PocketBase login failed (non-critical): $e');
        print('[Login] Continuing with local authentication only');
      }
    }
    
    return result;
  }
}

/// Parameters for login use case
class LoginParams {
  final String email;
  final String password;
  final bool rememberMe;

  const LoginParams({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });
}

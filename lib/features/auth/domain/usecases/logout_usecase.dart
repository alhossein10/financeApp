import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../repositories/auth_repository.dart';

/// Use case for user logout
class LogoutUseCase {
  final AuthRepository repository;
  final SecureStorageService secureStorageService;

  LogoutUseCase(this.repository, this.secureStorageService);

  /// Execute logout
  /// Clears session and authentication data including secure storage and Supabase
  Future<Either<Failure, void>> call() async {
    // Clear local data first
    await secureStorageService.clearAll();
    
    // Logout from repository (clears Laravel session)
    final result = await repository.logout();
    
    return result;
  }
}

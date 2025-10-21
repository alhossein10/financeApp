import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/pocketbase_service.dart';
import '../repositories/auth_repository.dart';

/// Use case for user logout
class LogoutUseCase {
  final AuthRepository repository;
  final SecureStorageService secureStorageService;

  LogoutUseCase(this.repository, this.secureStorageService);

  /// Execute logout
  /// Clears session and authentication data including secure storage and PocketBase
  Future<Either<Failure, void>> call() async {
    // ALWAYS clear local data first - this ensures user is logged out locally
    // even if cloud logout fails
    await secureStorageService.clearAll();
    
    // Try to logout from PocketBase (non-critical, don't block on failure)
    try {
      final pbService = PocketBaseService();
      if (pbService.isAuthenticated) {
        pbService.logout();
        print('[Logout] PocketBase logout successful');
      } else {
        print('[Logout] PocketBase not authenticated, skipping cloud logout');
      }
    } catch (e) {
      // Ignore PocketBase logout errors - local logout is what matters
      print('[Logout] PocketBase logout failed (non-critical): $e');
    }
    
    // Now logout from local repository
    final result = await repository.logout();
    
    return result;
  }
}

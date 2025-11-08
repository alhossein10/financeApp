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
    // ALWAYS clear local data first - this ensures user is logged out locally
    // even if cloud logout fails
    await secureStorageService.clearAll();
    
    // Try to logout from Supabase (non-critical, don't block on failure)
    try {
      final supabaseService = SupabaseService();
      if (supabaseService.isAuthenticated) {
        await supabaseService.signOut();
        print('[Logout] Supabase logout successful');
      } else {
        print('[Logout] Supabase not authenticated, skipping cloud logout');
      }
    } catch (e) {
      // Ignore Supabase logout errors - local logout is what matters
      print('[Logout] Supabase logout failed (non-critical): $e');
    }
    
    // Now logout from local repository
    final result = await repository.logout();
    
    return result;
  }
}

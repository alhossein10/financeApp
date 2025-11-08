import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

/// Service for managing role-based access control
/// Checks user permissions before allowing access to features
class RoleService {
  final AuthRepository _authRepository;

  RoleService({required AuthRepository authRepository})
      : _authRepository = authRepository;

  /// Check if current user is an admin
  /// Returns true if user has admin role
  Future<bool> isAdmin() async {
    print('🔵 [ROLE_SERVICE] Checking if user is admin...');
    final userResult = await _authRepository.getCurrentUser();
    return userResult.fold(
      (failure) {
        print('🔴 [ROLE_SERVICE] Failed to get user: ${failure.message}');
        return false;
      },
      (user) {
        print('🟢 [ROLE_SERVICE] User: ${user.email}, role: ${user.role}, isAdmin: ${user.isAdmin}');
        return user.isAdmin;
      },
    );
  }

  /// Check if current user is a regular user
  /// Returns true if user has user role
  Future<bool> isUser() async {
    final userResult = await _authRepository.getCurrentUser();
    return userResult.fold(
      (_) => false,
      (user) => user.role == UserRole.user,
    );
  }

  /// Get current user role
  /// Returns UserRole or null if not authenticated
  Future<UserRole?> getCurrentUserRole() async {
    final userResult = await _authRepository.getCurrentUser();
    return userResult.fold(
      (_) => null,
      (user) => user.role,
    );
  }

  /// Check if user has permission to access admin features
  /// Returns true if user is admin
  Future<bool> canAccessAdminFeatures() async {
    return await isAdmin();
  }

  /// Check if user has permission to access fund box
  /// Returns true for both admin and regular users (users can access their own fund box)
  Future<bool> canAccessFundBox() async {
    final userResult = await _authRepository.getCurrentUser();
    return userResult.fold(
      (_) => false,
      (user) => true, // Both admin and user can access fund box
    );
  }

  /// Check if user has permission to access admin dashboard
  /// Returns true if user is admin
  Future<bool> canAccessAdminDashboard() async {
    return await isAdmin();
  }

  /// Check if user has permission to access audit logs
  /// Returns true if user is admin
  Future<bool> canAccessAuditLogs() async {
    return await isAdmin();
  }

  /// Check if user has permission to view all users' data
  /// Returns true if user is admin
  Future<bool> canViewAllUsersData() async {
    return await isAdmin();
  }

  /// Validate permission before making API call
  /// Throws exception if user doesn't have permission
  Future<void> requireAdminPermission() async {
    print('🔵 [ROLE_SERVICE] Validating admin permission...');
    final hasPermission = await isAdmin();
    if (!hasPermission) {
      print('🔴 [ROLE_SERVICE] Permission denied - user is not admin');
      throw InsufficientPermissionsException(
        'Admin permission required for this action',
      );
    }
    print('✅ [ROLE_SERVICE] Admin permission validated');
  }

  /// Get user role synchronously from cached user
  /// Returns null if user is not cached
  UserRole? getCachedUserRole(User? user) {
    return user?.role;
  }

  /// Check if cached user is admin
  bool isCachedUserAdmin(User? user) {
    return user?.isAdmin ?? false;
  }
}

/// Exception thrown when user doesn't have sufficient permissions
class InsufficientPermissionsException implements Exception {
  final String message;

  InsufficientPermissionsException(this.message);

  @override
  String toString() => 'InsufficientPermissionsException: $message';
}

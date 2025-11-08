import '../../features/auth/domain/entities/user.dart';

/// Utility class for checking user roles and permissions
/// Used to control UI visibility and feature access
class RoleChecker {
  /// Check if user is an admin
  static bool isAdmin(User? user) {
    return user?.isAdmin ?? false;
  }

  /// Check if user is a regular user
  static bool isUser(User? user) {
    return user?.role == UserRole.user;
  }

  /// Check if user has access to admin features
  /// Returns true only if user is authenticated and is an admin
  static bool canAccessAdminFeatures(User? user) {
    return user != null && user.isAdmin;
  }

  /// Check if user has access to fund box
  /// Only admins can access fund box
  static bool canAccessFundBox(User? user) {
    return canAccessAdminFeatures(user);
  }

  /// Check if user has access to admin dashboard
  /// Only admins can access admin dashboard
  static bool canAccessAdminDashboard(User? user) {
    return canAccessAdminFeatures(user);
  }

  /// Check if user has access to audit logs
  /// Only admins can access audit logs
  static bool canAccessAuditLogs(User? user) {
    return canAccessAdminFeatures(user);
  }

  /// Check if user can view all users' data
  /// Only admins can view all users' data
  static bool canViewAllUsersData(User? user) {
    return canAccessAdminFeatures(user);
  }
}

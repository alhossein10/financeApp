import 'user.dart';

/// Result of a registration operation
/// Contains the registered user and optional group codes
class RegistrationResult {
  final User user;
  final String? groupCode; // Admin group code (for admin registration)
  final String? superAdminGroupCode; // SuperAdmin group code (for SuperAdmin registration)
  final String? adminGroupName; // Admin group name (for SuperAdmin registration)

  const RegistrationResult({
    required this.user,
    this.groupCode,
    this.superAdminGroupCode,
    this.adminGroupName,
  });

  @override
  String toString() {
    return 'RegistrationResult(user: ${user.email}, groupCode: $groupCode, superAdminGroupCode: $superAdminGroupCode, adminGroupName: $adminGroupName)';
  }
}

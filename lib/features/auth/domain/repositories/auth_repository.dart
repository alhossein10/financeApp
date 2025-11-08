import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../entities/registration_result.dart';
import '../entities/organization.dart';
import '../entities/department.dart';

/// Authentication repository interface defining contracts for auth operations
abstract class AuthRepository {
  /// Login with email and password
  /// Returns [User] on success or [Failure] on error
  Future<Either<Failure, User>> login(String email, String password);

  /// Register a new user with username, email, and password
  /// Returns [RegistrationResult] on success or [Failure] on error
  /// For SuperAdmins: creates a new SuperAdmin group and returns SuperAdmin group code
  /// For admins: creates a new admin group (or joins SuperAdmin group if superAdminGroupCode provided) and returns admin group code
  /// For users: joins existing admin group using group code
  Future<Either<Failure, RegistrationResult>> register(
    String username,
    String email,
    String password, {
    String? organizationName,
    String? departmentName,
    String? groupCode, // Admin group code (for users joining admin groups)
    String? superAdminGroupCode, // SuperAdmin group code (for admins joining SuperAdmin groups)
    String role = 'user',
  });

  /// Logout the current user
  /// Returns [void] on success or [Failure] on error
  Future<Either<Failure, void>> logout();

  /// Get the currently authenticated user
  /// Returns [User] on success or [Failure] on error
  Future<Either<Failure, User>> getCurrentUser();

  /// Check if a user is currently authenticated
  /// Returns [bool] indicating authentication status or [Failure] on error
  Future<Either<Failure, bool>> isAuthenticated();

  /// Reset password for a user by email
  /// Returns [void] on success or [Failure] on error
  Future<Either<Failure, void>> resetPassword(String email);

  /// Change password for the current user
  /// Returns [void] on success or [Failure] on error
  Future<Either<Failure, void>> changePassword(
    String oldPassword,
    String newPassword,
  );

  /// Reset password with token from email
  /// Returns [void] on success or [Failure] on error
  Future<Either<Failure, void>> resetPasswordWithToken(
    String token,
    String email,
    String password,
  );

  /// Get list of all organizations
  /// Returns [List<Organization>] on success or [Failure] on error
  Future<Either<Failure, List<Organization>>> getOrganizations();

  /// Get list of departments for a specific organization
  /// Returns [List<Department>] on success or [Failure] on error
  Future<Either<Failure, List<Department>>> getDepartments(int organizationId);
}

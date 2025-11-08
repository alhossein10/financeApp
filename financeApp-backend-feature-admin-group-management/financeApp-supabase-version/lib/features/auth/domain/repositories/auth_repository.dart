import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

/// Authentication repository interface defining contracts for auth operations
abstract class AuthRepository {
  /// Login with email and password
  /// Returns [User] on success or [Failure] on error
  Future<Either<Failure, User>> login(String email, String password);

  /// Register a new user with username, email, and password
  /// Returns [User] on success or [Failure] on error
  Future<Either<Failure, User>> register(
    String username,
    String email,
    String password,
  );

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
}

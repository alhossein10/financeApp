import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/config/flavor_config.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

/// Implementation of [AuthRepository]
/// Handles authentication operations and error mapping
/// Integrates both local SQLite and Supabase authentication
class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  final SupabaseService supabaseService;
  final FlavorConfig flavorConfig;

  // Default session duration: 7 days
  static const Duration _sessionDuration = Duration(days: 7);

  AuthRepositoryImpl({
    required this.localDataSource,
    required this.supabaseService,
    required this.flavorConfig,
  });

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      // Attempt local login first
      final user = await localDataSource.login(email, password);

      // Generate session token
      final token = _generateSessionToken();

      // Create session in database
      await localDataSource.createSession(
        user.id,
        token,
        _sessionDuration,
      );

      // Cache user and token
      await localDataSource.cacheUser(user);
      await localDataSource.cacheAuthToken(token);

      // Authenticate with Supabase (for sync functionality)
      // Wait for Supabase auth to complete for better sync reliability
      final supabaseResult = await _authenticateWithSupabase(email, password);
      supabaseResult.fold(
        (failure) {
          print('[AuthRepository] Supabase auth failed: ${failure.message}');
          // Continue with local auth - sync will be unavailable
        },
        (_) {
          print('[AuthRepository] Supabase auth successful');
        },
      );

      return Right(user);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error during login: ${e.toString()}'));
    }
  }

  /// Authenticate with Supabase for sync functionality
  Future<Either<Failure, void>> _authenticateWithSupabase(
    String email,
    String password,
  ) async {
    try {
      await supabaseService.signIn(email, password);
      return const Right(null);
    } catch (e) {
      return Left(AuthenticationFailure('Supabase auth failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      // Try to register with Supabase first (this creates the auth user)
      print('[AuthRepository] Attempting Supabase registration: $email');
      final supabaseResult = await _registerWithSupabase(username, email, password);
      
      bool supabaseSuccess = false;
      if (supabaseResult.isRight()) {
        supabaseSuccess = true;
        print('[AuthRepository] Supabase registration successful');
      } else {
        // Supabase registration failed - check if it's a network error
        final failure = supabaseResult.fold((l) => l, (r) => throw Exception());
        print('[AuthRepository] Supabase registration failed: ${failure.message}');
        
        // If it's a network error, continue with local registration
        // Otherwise, return the error
        if (!_isNetworkError(failure.message)) {
          return Left(failure);
        }
        
        print('[AuthRepository] Network error detected - continuing with local-only registration');
      }

      // Register in local database
      print('[AuthRepository] Registering locally: $email');
      final user = await localDataSource.register(username, email, password);

      // Generate session token
      final token = _generateSessionToken();

      // Create session in database
      await localDataSource.createSession(
        user.id,
        token,
        _sessionDuration,
      );

      // Cache user and token
      await localDataSource.cacheUser(user);
      await localDataSource.cacheAuthToken(token);

      if (supabaseSuccess) {
        print('[AuthRepository] Registration complete (with Supabase sync): $email');
      } else {
        print('[AuthRepository] Registration complete (local only - sync will retry later): $email');
      }
      
      return Right(user);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error during registration: ${e.toString()}'));
    }
  }

  /// Check if the error is a network-related error
  bool _isNetworkError(String errorMessage) {
    final networkErrorKeywords = [
      'SocketException',
      'Failed host lookup',
      'No address associated with hostname',
      'Network is unreachable',
      'Connection refused',
      'Connection timed out',
      'ClientException',
      'errno = 7',
    ];
    
    return networkErrorKeywords.any((keyword) => 
      errorMessage.toLowerCase().contains(keyword.toLowerCase())
    );
  }

  /// Register with Supabase with timeout
  Future<Either<Failure, void>> _registerWithSupabase(
    String username,
    String email,
    String password,
  ) async {
    try {
      // Add timeout to prevent hanging on network issues
      await supabaseService.signUp(
        email: email,
        password: password,
        username: username,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Supabase registration timeout - network may be unavailable');
        },
      );
      print('[AuthRepository] Supabase registration successful');
      return const Right(null);
    } catch (e) {
      final errorMessage = e.toString();
      print('[AuthRepository] Supabase registration error: $errorMessage');
      
      // Check for rate limit error
      if (errorMessage.contains('429') || errorMessage.contains('rate_limit')) {
        return Left(AuthenticationFailure(
          'Too many registration attempts. Please wait a few seconds and try again.'
        ));
      }
      
      // Check for email already exists
      if (errorMessage.contains('already registered') || errorMessage.contains('already exists')) {
        return Left(AuthenticationFailure(
          'This email is already registered. Please login instead.'
        ));
      }
      
      return Left(AuthenticationFailure('Failed to register with Supabase: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Get current token
      final token = await localDataSource.getAuthToken();

      // Delete session from database if token exists
      if (token != null) {
        await localDataSource.deleteSession(token);
      }

      // Clear cached data
      await localDataSource.logout();

      // Sign out from Supabase
      try {
        await supabaseService.signOut();
      } catch (e) {
        print('[AuthRepository] Supabase sign out failed: $e');
        // Continue with local logout even if Supabase fails
      }

      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error during logout: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      // Try to get cached user
      final cachedUser = await localDataSource.getCachedUser();

      if (cachedUser != null) {
        // Verify session is still valid
        final token = await localDataSource.getAuthToken();
        if (token != null) {
          final session = await localDataSource.getSessionByToken(token);
          if (session != null && session.isActive) {
            // Update session activity
            await localDataSource.updateSessionActivity(token);
            return Right(cachedUser);
          }
        }
      }

      // No valid cached user or session
      return Left(AuthenticationFailure('No authenticated user'));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error getting current user: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      // Check if we have a cached token
      final token = await localDataSource.getAuthToken();
      if (token == null) {
        return const Right(false);
      }

      // Check if session exists and is valid
      final session = await localDataSource.getSessionByToken(token);
      if (session == null || session.isExpired) {
        // Clean up invalid session
        await localDataSource.clearAuthData();
        return const Right(false);
      }

      return const Right(true);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error checking authentication: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      // Get user by email
      final user = await localDataSource.getUserByEmail(email);
      if (user == null) {
        // Don't reveal if email exists for security
        return const Right(null);
      }

      // Create password reset token
      final token = await localDataSource.createPasswordResetToken(user.id);

      // In a real app, you would send this token via email
      // For now, we'll just return success
      // The token can be retrieved and displayed to the user in the UI

      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error during password reset: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      // Get current user
      final userResult = await getCurrentUser();
      if (userResult.isLeft()) {
        return Left(AuthenticationFailure('User not authenticated'));
      }

      final user = userResult.getOrElse(() => throw Exception());

      // Verify old password by attempting login
      await localDataSource.login(user.email, oldPassword);
      // If login succeeds, old password is correct

      // Hash new password and update
      final newPasswordHash = localDataSource.hashPassword(newPassword);
      await localDataSource.updatePassword(user.id, newPasswordHash);

      // Invalidate all other sessions for security
      await localDataSource.deleteAllUserSessions(user.id);

      // Create new session
      final token = _generateSessionToken();
      await localDataSource.createSession(user.id, token, _sessionDuration);
      await localDataSource.cacheAuthToken(token);

      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure('Current password is incorrect'));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error changing password: ${e.toString()}'));
    }
  }

  /// Generate a session token
  /// This is a simple implementation - in production use a more secure method
  String _generateSessionToken() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        '_' +
        (DateTime.now().microsecond * 1000).toString();
  }
}

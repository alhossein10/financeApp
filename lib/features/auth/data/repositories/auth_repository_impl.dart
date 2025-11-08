import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart' hide ValidationException;
import '../../../../core/error/failures.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../injection_container.dart' as di;
import '../../../admin_group/data/datasources/admin_group_cache_datasource.dart';
import '../../../expenses/data/datasources/expense_cache_datasource.dart';
import '../../../incoming/data/datasources/incoming_cache_datasource.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/registration_result.dart';
import '../../domain/entities/organization.dart';
import '../../domain/entities/department.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_api_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/user_model.dart';

/// Implementation of [AuthRepository]
/// Handles authentication operations and error mapping
/// Uses Laravel API for authentication
class AuthRepositoryImpl implements AuthRepository {
  final AuthApiDataSource apiDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.apiDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      // Clear all caches before login to prevent showing previous user's data
      await _clearAllCaches();
      
      // Login via API
      final user = await apiDataSource.login(email, password);

      // Cache user locally
      final userModel = UserModel.fromEntity(user);
      await localDataSource.cacheUser(userModel);

      return Right(user);
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(AuthenticationFailure('Unexpected error during login: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, RegistrationResult>> register(
    String username,
    String email,
    String password, {
    String? organizationName,
    String? departmentName,
    String? groupCode,
    String? superAdminGroupCode,
    String role = 'user',
  }) async {
    try {
      // Register via API with new fields
      final result = await apiDataSource.register(
        name: username,
        email: email,
        password: password,
        organizationName: organizationName,
        departmentName: departmentName,
        groupCode: groupCode,
        superAdminGroupCode: superAdminGroupCode,
        role: role,
      );

      // Cache user locally
      final userModel = UserModel.fromEntity(result.user);
      await localDataSource.cacheUser(userModel);

      return Right(result);
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(AuthenticationFailure('Unexpected error during registration: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Logout via API (revokes token on server)
      await apiDataSource.logout();

      // Clear local auth cache
      await localDataSource.clearAuthData();
      
      // Clear ALL data caches to prevent showing wrong user's data on next login
      // This is critical for data security and privacy
      await _clearAllCaches();

      return const Right(null);
    } on ApiException catch (e) {
      // Even if API logout fails, clear local data
      await _clearAllCaches();
      await localDataSource.clearAuthData();
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      // Always clear local data on logout
      await _clearAllCaches();
      await localDataSource.clearAuthData();
      return Left(AuthenticationFailure('Unexpected error during logout: ${e.toString()}'));
    }
  }

  /// Helper method to clear all data caches
  /// This ensures no user data persists after logout, preventing data leakage
  Future<void> _clearAllCaches() async {
    try {
      // Use cache service to clear everything - this is the safest approach
      // It ensures ALL cached data (expenses, transfers, incoming, etc.) is cleared
      final cacheService = di.sl<CacheService>();
      await cacheService.clear();
      print('✅ [AUTH_REPO] Cleared all caches');
    } catch (e) {
      print('⚠️ [AUTH_REPO] Failed to clear caches: $e');
      // Try individual caches as fallback
      try {
        final adminGroupCache = di.sl<AdminGroupCacheDataSource>();
        await adminGroupCache.clearAllCache();
      } catch (e2) {
        print('⚠️ [AUTH_REPO] Failed to clear admin group cache: $e2');
      }
      try {
        final expenseCache = di.sl<ExpenseCacheDataSource>();
        await expenseCache.clearAllCache();
      } catch (e2) {
        print('⚠️ [AUTH_REPO] Failed to clear expense cache: $e2');
      }
      try {
        final incomingCache = di.sl<IncomingCacheDataSource>();
        await incomingCache.clearCache();
      } catch (e2) {
        print('⚠️ [AUTH_REPO] Failed to clear incoming cache: $e2');
      }
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      print('🔵 [AUTH_REPO] Getting current user...');
      
      // Check if we have a valid token first
      final isAuth = await apiDataSource.isAuthenticated();
      if (!isAuth) {
        print('⚠️ [AUTH_REPO] No valid token found, user not authenticated');
        return Left(AuthenticationFailure('Not authenticated'));
      }
      
      // Always fetch from API to ensure we have the latest user data including role
      // This is important for role-based access control
      final user = await apiDataSource.getCurrentUser();
      
      print('🟢 [AUTH_REPO] User fetched from API: ${user.email}, role: ${user.role}');
      
      // Update cache with fresh data
      final userModel = UserModel.fromEntity(user);
      await localDataSource.cacheUser(userModel);
      
      print('✅ [AUTH_REPO] User cached successfully');

      return Right(user);
    } on ApiException catch (e) {
      print('🔴 [AUTH_REPO] API error getting user: ${e.message}');
      
      // If API fails, try to return cached user as fallback
      try {
        final cachedUser = await localDataSource.getCachedUser();
        if (cachedUser != null) {
          print('⚠️ [AUTH_REPO] Returning cached user as fallback');
          return Right(cachedUser);
        }
      } catch (cacheError) {
        print('🔴 [AUTH_REPO] Cache error: $cacheError');
      }
      
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      print('🔴 [AUTH_REPO] Unexpected error: $e');
      
      // Try to return cached user as last resort
      try {
        final cachedUser = await localDataSource.getCachedUser();
        if (cachedUser != null) {
          print('⚠️ [AUTH_REPO] Returning cached user after unexpected error');
          return Right(cachedUser);
        }
      } catch (cacheError) {
        print('🔴 [AUTH_REPO] Cache error: $cacheError');
      }
      
      return Left(AuthenticationFailure('Failed to get current user. Please log in again.'));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final isAuth = await apiDataSource.isAuthenticated();
      return Right(isAuth);
    } catch (e) {
      return Left(AuthenticationFailure('Unexpected error checking authentication: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await apiDataSource.forgotPassword(email);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      return Left(AuthenticationFailure('Unexpected error during password reset: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      await apiDataSource.changePassword(
        currentPassword: oldPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      return Left(AuthenticationFailure('Unexpected error changing password: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPasswordWithToken(
    String token,
    String email,
    String password,
  ) async {
    try {
      await apiDataSource.resetPassword(
        token: token,
        email: email,
        password: password,
      );
      return const Right(null);
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      return Left(AuthenticationFailure('Unexpected error resetting password: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Organization>>> getOrganizations() async {
    try {
      final organizations = await apiDataSource.getOrganizations();
      return Right(organizations);
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure('Unexpected error fetching organizations: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Department>>> getDepartments(int organizationId) async {
    try {
      final departments = await apiDataSource.getDepartments(organizationId);
      return Right(departments);
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure('Unexpected error fetching departments: ${e.toString()}'));
    }
  }

  /// Map ApiException to appropriate Failure type
  Failure _mapApiExceptionToFailure(ApiException exception) {
    if (exception.isAuthError) {
      return AuthenticationFailure(exception.message);
    } else if (exception.isValidationError) {
      return ValidationFailure(exception.message);
    } else if (exception.isNetworkError) {
      return NetworkFailure(exception.message);
    } else {
      return ServerFailure(exception.message);
    }
  }
}

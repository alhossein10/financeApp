import 'package:dartz/dartz.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/user_statistics.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_api_datasource.dart';

/// Implementation of profile repository
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileApiDataSource apiDataSource;

  ProfileRepositoryImpl({required this.apiDataSource});

  @override
  Future<Either<Failure, UserStatistics>> getUserStatistics(int userId) async {
    try {
      final statistics = await apiDataSource.getUserStatistics();
      return Right(statistics);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        return Left(UnauthorizedFailure());
      } else if (e.statusCode == 403) {
        return const Left(AuthorizationFailure('Access denied'));
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get user statistics: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> updateUserProfile({
    required int userId,
    String? username,
    String? email,
  }) async {
    try {
      final updatedUser = await apiDataSource.updateProfile(
        name: username,
        email: email,
      );
      return Right(updatedUser);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        return Left(UnauthorizedFailure());
      } else if (e.statusCode == 422) {
        return Left(ValidationFailure(e.message));
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to update user profile: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfilePicture({
    required int userId,
    required String imagePath,
  }) async {
    try {
      // Note: Profile picture upload will be implemented when file upload is integrated
      // For now, return the current user profile
      final user = await apiDataSource.getProfile();
      return Right(user);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        return Left(UnauthorizedFailure());
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to update profile picture: ${e.toString()}'));
    }
  }

  /// Change user password
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await apiDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        return const Left(ValidationFailure('Current password is incorrect'));
      } else if (e.statusCode == 422) {
        return Left(ValidationFailure(e.message));
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to change password: ${e.toString()}'));
    }
  }

  /// Delete user account
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      await apiDataSource.deleteAccount();
      return const Right(null);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        return Left(UnauthorizedFailure());
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to delete account: ${e.toString()}'));
    }
  }
}
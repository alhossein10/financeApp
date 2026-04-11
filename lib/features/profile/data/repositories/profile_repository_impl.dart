import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/profile_image_upload_service.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/user_statistics.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_api_datasource.dart';

/// Implementation of profile repository
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileApiDataSource apiDataSource;
  final ProfileImageUploadService imageUploadService;

  ProfileRepositoryImpl({
    required this.apiDataSource,
    required this.imageUploadService,
  });

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
      // Validate image file
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        return const Left(ValidationFailure('Image file does not exist'));
      }

      if (!imageUploadService.isValidImageFile(imageFile)) {
        return const Left(ValidationFailure('Invalid image file format'));
      }

      // Upload profile image
      final imageUrl = await imageUploadService.uploadProfileImage(imageFile);

      // Update profile with new image URL via API
      final updatedUser = await apiDataSource.updateProfileImage(imageUrl);
      
      return Right(updatedUser);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        return Left(UnauthorizedFailure());
      } else if (e.statusCode == 422) {
        return Left(ValidationFailure(e.message));
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to update profile picture: ${e.toString()}'));
    }
  }

  /// Change user password
  @override
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
  @override
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

  /// Upload profile photo
  @override
  Future<Either<Failure, Map<String, String>>> uploadProfilePhoto(String filePath) async {
    try {
      final photoData = await apiDataSource.uploadProfilePhoto(filePath);
      return Right(photoData);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        return Left(UnauthorizedFailure());
      } else if (e.statusCode == 422) {
        return Left(ValidationFailure(e.message));
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to upload profile photo: ${e.toString()}'));
    }
  }

  /// Delete profile photo
  @override
  Future<Either<Failure, void>> deleteProfilePhoto() async {
    try {
      await apiDataSource.deleteProfilePhoto();
      return const Right(null);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        return Left(UnauthorizedFailure());
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to delete profile photo: ${e.toString()}'));
    }
  }
}
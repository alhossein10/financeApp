import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../entities/user_statistics.dart';

/// Repository interface for profile operations
abstract class ProfileRepository {
  /// Get user statistics (expenses, transfers, account age, etc.)
  Future<Either<Failure, UserStatistics>> getUserStatistics(int userId);
  
  /// Update user profile information
  Future<Either<Failure, User>> updateUserProfile({
    required int userId,
    String? username,
    String? email,
  });
  
  /// Update user profile picture
  Future<Either<Failure, User>> updateProfilePicture({
    required int userId,
    required String imagePath,
  });
  
  /// Change user password
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  
  /// Delete user account
  Future<Either<Failure, void>> deleteAccount();

  /// Upload profile photo
  Future<Either<Failure, Map<String, String>>> uploadProfilePhoto(String filePath);

  /// Delete profile photo
  Future<Either<Failure, void>> deleteProfilePhoto();
}
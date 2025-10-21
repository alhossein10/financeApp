import '../../../auth/data/models/user_model.dart';
import '../models/user_statistics_model.dart';

/// Abstract interface for profile local data source
abstract class ProfileLocalDataSource {
  /// Get user statistics from database
  Future<UserStatisticsModel> getUserStatistics(int userId);
  
  /// Update user profile information
  Future<UserModel> updateUserProfile({
    required int userId,
    String? username,
    String? email,
  });
  
  /// Update user profile picture
  Future<UserModel> updateProfilePicture({
    required int userId,
    required String imagePath,
  });
}
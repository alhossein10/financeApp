import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../entities/user_statistics.dart';
import '../repositories/profile_repository.dart';

/// Use case for getting user profile with statistics
class GetUserProfileUseCase {
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;

  GetUserProfileUseCase({
    required this.authRepository,
    required this.profileRepository,
  });

  /// Get current user profile with statistics
  Future<Either<Failure, UserProfileData>> call() async {
    try {
      // Get current user
      final userResult = await authRepository.getCurrentUser();
      if (userResult.isLeft()) {
        print('[GetUserProfileUseCase] Failed to get current user');
        return Left(UnauthorizedFailure());
      }

      final user = userResult.getOrElse(() => throw Exception());
      print('[GetUserProfileUseCase] Got user: ${user.username} (ID: ${user.id})');

      // Get user statistics - don't fail if statistics fail
      final statisticsResult = await profileRepository.getUserStatistics(user.id);
      
      final statistics = statisticsResult.fold(
        (failure) {
          // Return empty statistics instead of failing
          print('[GetUserProfileUseCase] Failed to load statistics: ${failure.message}');
          print('[GetUserProfileUseCase] Using empty statistics as fallback');
          return const UserStatistics(
            totalExpenses: 0.0,
            totalTransfers: 0.0,
            totalTransactions: 0,
            accountAgeDays: 0,
            lastActivity: null,
          );
        },
        (stats) {
          print('[GetUserProfileUseCase] Loaded statistics successfully');
          return stats;
        },
      );

      return Right(UserProfileData(
        user: user,
        statistics: statistics,
      ));
    } catch (e) {
      print('[GetUserProfileUseCase] Unexpected error: $e');
      return Left(ServerFailure('Failed to load profile: ${e.toString()}'));
    }
  }
}

/// Combined user profile data
class UserProfileData {
  final User user;
  final UserStatistics statistics;

  const UserProfileData({
    required this.user,
    required this.statistics,
  });
}
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
    // Get current user
    final userResult = await authRepository.getCurrentUser();
    if (userResult.isLeft()) {
      return Left(UnauthorizedFailure());
    }

    final user = userResult.getOrElse(() => throw Exception());

    // Get user statistics
    final statisticsResult = await profileRepository.getUserStatistics(user.id);
    
    return statisticsResult.fold(
      (failure) => Left(failure),
      (statistics) => Right(UserProfileData(
        user: user,
        statistics: statistics,
      )),
    );
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
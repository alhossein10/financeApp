import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';

/// Use case for updating user profile picture
class UpdateProfilePictureUseCase {
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;

  UpdateProfilePictureUseCase({
    required this.authRepository,
    required this.profileRepository,
  });

  /// Update user profile picture
  Future<Either<Failure, User>> call(UpdateProfilePictureParams params) async {
    // Get current user
    final userResult = await authRepository.getCurrentUser();
    if (userResult.isLeft()) {
      return Left(UnauthorizedFailure());
    }

    final currentUser = userResult.getOrElse(() => throw Exception());

    // Validate image path
    if (params.imagePath.isEmpty) {
      return const Left(ValidationFailure('Image path cannot be empty'));
    }

    // Update profile picture
    return await profileRepository.updateProfilePicture(
      userId: currentUser.id,
      imagePath: params.imagePath,
    );
  }
}

/// Parameters for updating profile picture
class UpdateProfilePictureParams {
  final String imagePath;

  const UpdateProfilePictureParams({
    required this.imagePath,
  });
}
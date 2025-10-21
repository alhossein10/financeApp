import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';

/// Use case for updating user profile information
class UpdateUserProfileUseCase {
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;

  UpdateUserProfileUseCase({
    required this.authRepository,
    required this.profileRepository,
  });

  /// Update user profile with validation
  Future<Either<Failure, User>> call(UpdateProfileParams params) async {
    // Get current user
    final userResult = await authRepository.getCurrentUser();
    if (userResult.isLeft()) {
      return Left(UnauthorizedFailure());
    }

    final currentUser = userResult.getOrElse(() => throw Exception());

    // Validate username if provided
    if (params.username != null) {
      if (params.username!.isEmpty) {
        return const Left(ValidationFailure('Username cannot be empty'));
      }

      if (params.username!.length < 3) {
        return const Left(
            ValidationFailure('Username must be at least 3 characters'));
      }

      if (params.username!.length > 30) {
        return const Left(
            ValidationFailure('Username must not exceed 30 characters'));
      }
    }

    // Validate email if provided
    if (params.email != null) {
      if (!Validators.isValidEmail(params.email!)) {
        return const Left(ValidationFailure('Invalid email format'));
      }
    }

    // Update profile
    return await profileRepository.updateUserProfile(
      userId: currentUser.id,
      username: params.username,
      email: params.email,
    );
  }
}

/// Parameters for updating user profile
class UpdateProfileParams {
  final String? username;
  final String? email;

  const UpdateProfileParams({
    this.username,
    this.email,
  });
}
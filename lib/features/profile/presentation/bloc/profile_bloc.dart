import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_user_profile_usecase.dart';
import '../../domain/usecases/update_user_profile_usecase.dart';
import '../../domain/usecases/update_profile_picture_usecase.dart';
import 'profile_event.dart';
import 'profile_state.dart';

/// BLoC for managing profile state
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetUserProfileUseCase getUserProfileUseCase;
  final UpdateUserProfileUseCase updateUserProfileUseCase;
  final UpdateProfilePictureUseCase updateProfilePictureUseCase;
  final ProfileRepository profileRepository;

  ProfileBloc({
    required this.getUserProfileUseCase,
    required this.updateUserProfileUseCase,
    required this.updateProfilePictureUseCase,
    required this.profileRepository,
  }) : super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfilePictureUpdateRequested>(_onProfilePictureUpdateRequested);
    on<ProfilePasswordChangeRequested>(_onPasswordChangeRequested);
    on<ProfileDeleteAccountRequested>(_onDeleteAccountRequested);
  }

  Future<void> _onProfileLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await getUserProfileUseCase();

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (profileData) => emit(ProfileLoaded(profileData: profileData)),
    );
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await updateUserProfileUseCase(
      UpdateProfileParams(
        username: event.username,
        email: event.email,
      ),
    );

    await result.fold(
      (failure) async {
        emit(ProfileError(message: failure.message));
      },
      (updatedUser) async {
        // Reload profile data to get updated statistics
        final profileResult = await getUserProfileUseCase();
        profileResult.fold(
          (failure) => emit(ProfileError(message: failure.message)),
          (profileData) => emit(ProfileUpdateSuccess(
            profileData: profileData,
            message: 'Profile updated successfully',
          )),
        );
      },
    );
  }

  Future<void> _onProfilePictureUpdateRequested(
    ProfilePictureUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await updateProfilePictureUseCase(
      UpdateProfilePictureParams(imagePath: event.imagePath),
    );

    await result.fold(
      (failure) async {
        emit(ProfileError(message: failure.message));
      },
      (updatedUser) async {
        // Reload profile data to get updated user info
        final profileResult = await getUserProfileUseCase();
        profileResult.fold(
          (failure) => emit(ProfileError(message: failure.message)),
          (profileData) => emit(ProfilePictureUpdateSuccess(
            profileData: profileData,
          )),
        );
      },
    );
  }

  Future<void> _onPasswordChangeRequested(
    ProfilePasswordChangeRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await profileRepository.changePassword(
      currentPassword: event.currentPassword,
      newPassword: event.newPassword,
    );

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (_) => emit(const ProfilePasswordChangeSuccess()),
    );
  }

  Future<void> _onDeleteAccountRequested(
    ProfileDeleteAccountRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await profileRepository.deleteAccount();

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (_) => emit(const ProfileAccountDeleted()),
    );
  }
}
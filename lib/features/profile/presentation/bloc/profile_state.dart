import 'package:equatable/equatable.dart';
import '../../domain/usecases/get_user_profile_usecase.dart';

/// Base class for profile states
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Loading state
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Profile loaded successfully
class ProfileLoaded extends ProfileState {
  final UserProfileData profileData;

  const ProfileLoaded({required this.profileData});

  @override
  List<Object?> get props => [profileData];
}

/// Profile update successful
class ProfileUpdateSuccess extends ProfileState {
  final UserProfileData profileData;
  final String message;

  const ProfileUpdateSuccess({
    required this.profileData,
    required this.message,
  });

  @override
  List<Object?> get props => [profileData, message];
}

/// Profile picture update successful
class ProfilePictureUpdateSuccess extends ProfileState {
  final UserProfileData profileData;

  const ProfilePictureUpdateSuccess({required this.profileData});

  @override
  List<Object?> get props => [profileData];
}

/// Error state
class ProfileError extends ProfileState {
  final String message;

  const ProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Password change successful
class ProfilePasswordChangeSuccess extends ProfileState {
  final String message;

  const ProfilePasswordChangeSuccess({
    this.message = 'Password changed successfully',
  });

  @override
  List<Object?> get props => [message];
}

/// Account deleted successfully
class ProfileAccountDeleted extends ProfileState {
  const ProfileAccountDeleted();
}
import 'package:equatable/equatable.dart';

/// Base class for profile events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load user profile data
class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested();
}

/// Event to update user profile information
class ProfileUpdateRequested extends ProfileEvent {
  final String? username;
  final String? email;

  const ProfileUpdateRequested({
    this.username,
    this.email,
  });

  @override
  List<Object?> get props => [username, email];
}

/// Event to update profile picture
class ProfilePictureUpdateRequested extends ProfileEvent {
  final String imagePath;

  const ProfilePictureUpdateRequested({
    required this.imagePath,
  });

  @override
  List<Object?> get props => [imagePath];
}

/// Event to change password
class ProfilePasswordChangeRequested extends ProfileEvent {
  final String currentPassword;
  final String newPassword;

  const ProfilePasswordChangeRequested({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

/// Event to delete account
class ProfileDeleteAccountRequested extends ProfileEvent {
  const ProfileDeleteAccountRequested();
}
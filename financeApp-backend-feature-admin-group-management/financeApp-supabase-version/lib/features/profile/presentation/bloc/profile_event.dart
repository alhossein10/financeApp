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
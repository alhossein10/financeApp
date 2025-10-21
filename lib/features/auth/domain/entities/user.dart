import 'package:equatable/equatable.dart';

/// User role enum
enum UserRole {
  user,
  admin;

  bool get isAdmin => this == UserRole.admin;
  bool get isUser => this == UserRole.user;
}

/// User entity representing a user in the domain layer
class User extends Equatable {
  final int id;
  final String username;
  final String email;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? profilePicturePath;
  final DateTime? lastLogin;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.role = UserRole.user,
    required this.createdAt,
    this.updatedAt,
    this.profilePicturePath,
    this.lastLogin,
  });

  bool get isAdmin => role.isAdmin;

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        role,
        createdAt,
        updatedAt,
        profilePicturePath,
        lastLogin,
      ];
}

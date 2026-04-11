import 'package:equatable/equatable.dart';
import 'organization.dart';
import 'department.dart';

/// User role enum
enum UserRole {
  user,
  admin,
  superAdmin;

  bool get isAdmin => this == UserRole.admin;
  bool get isUser => this == UserRole.user;
  bool get isSuperAdmin => this == UserRole.superAdmin;
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
  final String? profileImageUrl; // URL for profile image from API
  final DateTime? lastLogin;
  
  // New fields for admin group management
  final String? organizationName;
  final String? departmentName;
  final int? adminGroupId;
  final int? superAdminGroupId;
  
  // Deprecated but kept for backward compatibility
  final int organizationId;
  final int? departmentId;
  final Organization? organization;
  final Department? department;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.role = UserRole.user,
    required this.createdAt,
    this.updatedAt,
    this.profilePicturePath,
    this.profileImageUrl,
    this.lastLogin,
    this.organizationName,
    this.departmentName,
    this.adminGroupId,
    this.superAdminGroupId,
    required this.organizationId,
    this.departmentId,
    this.organization,
    this.department,
  });

  bool get isAdmin => role.isAdmin;
  bool get isSuperAdmin => role.isSuperAdmin;

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        role,
        createdAt,
        updatedAt,
        profilePicturePath,
        profileImageUrl,
        lastLogin,
        organizationName,
        departmentName,
        adminGroupId,
        superAdminGroupId,
        organizationId,
        departmentId,
        organization,
        department,
      ];
}

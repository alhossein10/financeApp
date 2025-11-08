import '../../../../core/utils/date_formatter.dart';
import '../../../auth/domain/entities/user.dart';

/// Profile Data Transfer Object for API communication
/// Maps between API JSON and domain User entity
class ProfileDto {
  final int id;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? profilePicturePath;
  final DateTime? lastLogin;

  const ProfileDto({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.updatedAt,
    this.profilePicturePath,
    this.lastLogin,
  });

  /// Create ProfileDto from JSON response
  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    return ProfileDto(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      createdAt: DateFormatter.fromApiTimestamp(json['created_at'] as String),
      updatedAt: DateFormatter.fromApiTimestampNullable(json['updated_at'] as String?),
      profilePicturePath: json['profile_picture_path'] as String?,
      lastLogin: DateFormatter.fromApiTimestampNullable(json['last_login'] as String?),
    );
  }

  /// Convert ProfileDto to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'created_at': DateFormatter.toApiTimestamp(createdAt),
      'updated_at': DateFormatter.toApiTimestampNullable(updatedAt),
      'profile_picture_path': profilePicturePath,
      'last_login': DateFormatter.toApiTimestampNullable(lastLogin),
    };
  }

  /// Convert ProfileDto to domain User entity
  User toEntity() {
    return User(
      id: id,
      username: name,
      email: email,
      role: _mapRole(role),
      createdAt: createdAt,
      updatedAt: updatedAt,
      profilePicturePath: profilePicturePath,
      lastLogin: lastLogin,
      organizationId: 1, // Default organization ID - TODO: get from API
    );
  }

  /// Create ProfileDto from domain User entity
  factory ProfileDto.fromEntity(User user) {
    return ProfileDto(
      id: user.id,
      name: user.username,
      email: user.email,
      role: user.role == UserRole.admin ? 'admin' : 'user',
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      profilePicturePath: user.profilePicturePath,
      lastLogin: user.lastLogin,
    );
  }

  /// Map string role to UserRole enum
  static UserRole _mapRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  /// Check if user is admin
  bool get isAdmin => role.toLowerCase() == 'admin';

  @override
  String toString() {
    return 'ProfileDto(id: $id, name: $name, email: $email, role: $role)';
  }
}

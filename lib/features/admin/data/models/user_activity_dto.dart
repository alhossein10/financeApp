import '../../../../core/utils/date_formatter.dart';

/// Data Transfer Object for user activity information
/// Maps between API JSON and domain entities
/// Matches Laravel API spec: /admin/dashboard/users
class UserActivityDto {
  final int id;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const UserActivityDto({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.lastLogin,
  });

  /// Create UserActivityDto from JSON response
  factory UserActivityDto.fromJson(Map<String, dynamic> json) {
    return UserActivityDto(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      createdAt: DateFormatter.fromApiTimestamp(json['created_at'] as String),
      lastLogin: DateFormatter.fromApiTimestampNullable(json['last_login'] as String?),
    );
  }

  /// Convert UserActivityDto to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'created_at': DateFormatter.toApiTimestamp(createdAt),
      'last_login': DateFormatter.toApiTimestampNullable(lastLogin),
    };
  }

  @override
  String toString() {
    return 'UserActivityDto(id: $id, name: $name, email: $email, role: $role, lastLogin: $lastLogin)';
  }
}

import '../../domain/entities/user.dart';

/// User model for data layer, extends User entity
/// Handles serialization/deserialization to/from database
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.email,
    super.role = UserRole.user,
    required super.createdAt,
    super.updatedAt,
    super.profilePicturePath,
    super.lastLogin,
  });

  /// Create UserModel from database map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int,
      username: map['username'] as String,
      email: map['email'] as String,
      role: UserRole.values[(map['role'] as int?) ?? 0],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
      profilePicturePath: map['profile_picture_path'] as String?,
      lastLogin: map['last_login'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_login'] as int)
          : null,
    );
  }

  /// Convert UserModel to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role.index,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
      'profile_picture_path': profilePicturePath,
      'last_login': lastLogin?.millisecondsSinceEpoch,
    };
  }

  /// Create UserModel from User entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      username: user.username,
      email: user.email,
      role: user.role,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      profilePicturePath: user.profilePicturePath,
      lastLogin: user.lastLogin,
    );
  }

  /// Create a copy of UserModel with updated fields
  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profilePicturePath,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}

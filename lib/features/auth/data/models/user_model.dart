import '../../domain/entities/user.dart';
import '../../domain/entities/organization.dart';
import '../../domain/entities/department.dart';
import 'organization_model.dart';
import 'department_model.dart';

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
    super.organizationName,
    super.departmentName,
    super.adminGroupId,
    super.superAdminGroupId,
    required super.organizationId,
    super.departmentId,
    super.organization,
    super.department,
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
      organizationName: map['organization_name'] as String?,
      departmentName: map['department_name'] as String?,
      adminGroupId: map['admin_group_id'] as int?,
      superAdminGroupId: map['super_admin_group_id'] as int?,
      organizationId: map['organization_id'] as int,
      departmentId: map['department_id'] as int?,
      organization: map['organization'] != null
          ? OrganizationModel.fromJson(map['organization'] as Map<String, dynamic>)
          : null,
      department: map['department'] != null
          ? DepartmentModel.fromJson(map['department'] as Map<String, dynamic>)
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
      'organization_name': organizationName,
      'department_name': departmentName,
      'admin_group_id': adminGroupId,
      'super_admin_group_id': superAdminGroupId,
      'organization_id': organizationId,
      'department_id': departmentId,
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
      organizationName: user.organizationName,
      departmentName: user.departmentName,
      adminGroupId: user.adminGroupId,
      superAdminGroupId: user.superAdminGroupId,
      organizationId: user.organizationId,
      departmentId: user.departmentId,
      organization: user.organization,
      department: user.department,
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
    String? organizationName,
    String? departmentName,
    int? adminGroupId,
    int? superAdminGroupId,
    int? organizationId,
    int? departmentId,
    Organization? organization,
    Department? department,
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
      organizationName: organizationName ?? this.organizationName,
      departmentName: departmentName ?? this.departmentName,
      adminGroupId: adminGroupId ?? this.adminGroupId,
      superAdminGroupId: superAdminGroupId ?? this.superAdminGroupId,
      organizationId: organizationId ?? this.organizationId,
      departmentId: departmentId ?? this.departmentId,
      organization: organization ?? this.organization,
      department: department ?? this.department,
    );
  }
}

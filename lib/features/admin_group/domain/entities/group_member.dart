import 'package:equatable/equatable.dart';

/// GroupMember entity representing a member of an admin group
class GroupMember extends Equatable {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? organizationName;
  final String? departmentName;
  final DateTime createdAt;

  const GroupMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.organizationName,
    this.departmentName,
    required this.createdAt,
  });

  /// Check if member is admin
  bool get isAdmin => role.toLowerCase() == 'admin';

  /// Create a copy of GroupMember with updated fields
  GroupMember copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    String? organizationName,
    String? departmentName,
    DateTime? createdAt,
  }) {
    return GroupMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      organizationName: organizationName ?? this.organizationName,
      departmentName: departmentName ?? this.departmentName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        role,
        organizationName,
        departmentName,
        createdAt,
      ];
}

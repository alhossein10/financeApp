import 'package:equatable/equatable.dart';

/// AdminGroup entity representing an admin's group in the domain layer
/// An admin group is a collection of users managed by an admin user
class AdminGroup extends Equatable {
  final int id;
  final int adminUserId;
  final String groupCode;
  final String? groupName;
  final bool isActive;
  final int? membersCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminGroup({
    required this.id,
    required this.adminUserId,
    required this.groupCode,
    this.groupName,
    required this.isActive,
    this.membersCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of AdminGroup with updated fields
  AdminGroup copyWith({
    int? id,
    int? adminUserId,
    String? groupCode,
    String? groupName,
    bool? isActive,
    int? membersCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminGroup(
      id: id ?? this.id,
      adminUserId: adminUserId ?? this.adminUserId,
      groupCode: groupCode ?? this.groupCode,
      groupName: groupName ?? this.groupName,
      isActive: isActive ?? this.isActive,
      membersCount: membersCount ?? this.membersCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        adminUserId,
        groupCode,
        groupName,
        isActive,
        membersCount,
        createdAt,
        updatedAt,
      ];
}

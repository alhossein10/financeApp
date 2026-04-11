import 'package:equatable/equatable.dart';

/// SuperadminGroup entity representing a superadmin's group in the domain layer
/// A superadmin group is a collection of admins managed by a superadmin user
class SuperadminGroup extends Equatable {
  final int id;
  final String name;
  final String groupCode;
  final int memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SuperadminGroup({
    required this.id,
    required this.name,
    required this.groupCode,
    required this.memberCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of SuperadminGroup with updated fields
  SuperadminGroup copyWith({
    int? id,
    String? name,
    String? groupCode,
    int? memberCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SuperadminGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      groupCode: groupCode ?? this.groupCode,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        groupCode,
        memberCount,
        createdAt,
        updatedAt,
      ];
}

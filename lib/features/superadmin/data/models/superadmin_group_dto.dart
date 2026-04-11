import '../../domain/entities/superadmin_group.dart';

/// Data Transfer Object for SuperAdmin Group
class SuperAdminGroupDto {
  final int id;
  final String name;
  final String groupCode;
  final int memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SuperAdminGroupDto({
    required this.id,
    required this.name,
    required this.groupCode,
    required this.memberCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON response
  factory SuperAdminGroupDto.fromJson(Map<String, dynamic> json) {
    return SuperAdminGroupDto(
      id: json['id'] as int,
      name: json['name'] as String,
      groupCode: json['group_code'] as String,
      memberCount: json['member_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'group_code': groupCode,
      'member_count': memberCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert DTO to domain entity
  SuperadminGroup toEntity() {
    return SuperadminGroup(
      id: id,
      name: name,
      groupCode: groupCode,
      memberCount: memberCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create DTO from domain entity
  factory SuperAdminGroupDto.fromEntity(SuperadminGroup entity) {
    return SuperAdminGroupDto(
      id: entity.id,
      name: entity.name,
      groupCode: entity.groupCode,
      memberCount: entity.memberCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SuperAdminGroupDto(id: $id, name: $name, code: $groupCode, members: $memberCount)';
  }
}

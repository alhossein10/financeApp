import '../../domain/entities/group_info.dart';

/// Data Transfer Object for GroupInfo API communication
/// Handles JSON serialization/deserialization for Laravel API
class GroupInfoDto {
  final String groupCode;
  final String? groupName;
  final String adminName;
  final String adminEmail;
  final int membersCount;
  final String joinedAt;

  const GroupInfoDto({
    required this.groupCode,
    this.groupName,
    required this.adminName,
    required this.adminEmail,
    required this.membersCount,
    required this.joinedAt,
  });

  /// Create DTO from JSON response from Laravel API
  factory GroupInfoDto.fromJson(Map<String, dynamic> json) {
    return GroupInfoDto(
      groupCode: json['group_code'] as String? ?? '',
      groupName: json['group_name'] as String?,
      adminName: json['admin_name'] as String? ?? 'Unknown',
      adminEmail: json['admin_email'] as String? ?? '',
      membersCount: json['members_count'] as int? ?? 0,
      joinedAt: json['joined_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  /// Convert DTO to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'group_code': groupCode,
      if (groupName != null) 'group_name': groupName,
      'admin_name': adminName,
      'admin_email': adminEmail,
      'members_count': membersCount,
      'joined_at': joinedAt,
    };
  }

  /// Convert DTO to domain entity
  GroupInfo toEntity() {
    return GroupInfo(
      groupCode: groupCode,
      groupName: groupName,
      adminName: adminName,
      adminEmail: adminEmail,
      membersCount: membersCount,
      joinedAt: DateTime.parse(joinedAt),
    );
  }

  /// Create DTO from domain entity
  factory GroupInfoDto.fromEntity(GroupInfo entity) {
    return GroupInfoDto(
      groupCode: entity.groupCode,
      groupName: entity.groupName,
      adminName: entity.adminName,
      adminEmail: entity.adminEmail,
      membersCount: entity.membersCount,
      joinedAt: entity.joinedAt.toIso8601String(),
    );
  }

  GroupInfoDto copyWith({
    String? groupCode,
    String? groupName,
    String? adminName,
    String? adminEmail,
    int? membersCount,
    String? joinedAt,
  }) {
    return GroupInfoDto(
      groupCode: groupCode ?? this.groupCode,
      groupName: groupName ?? this.groupName,
      adminName: adminName ?? this.adminName,
      adminEmail: adminEmail ?? this.adminEmail,
      membersCount: membersCount ?? this.membersCount,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

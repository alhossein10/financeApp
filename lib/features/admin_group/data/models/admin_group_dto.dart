import '../../domain/entities/admin_group.dart';

/// Data Transfer Object for AdminGroup API communication
/// Handles JSON serialization/deserialization for Laravel API
class AdminGroupDto {
  final int id;
  final int adminUserId;
  final String groupCode;
  final String? groupName;
  final bool isActive;
  final int? membersCount;
  final String createdAt;
  final String updatedAt;

  const AdminGroupDto({
    required this.id,
    required this.adminUserId,
    required this.groupCode,
    this.groupName,
    required this.isActive,
    this.membersCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create DTO from JSON response from Laravel API
  factory AdminGroupDto.fromJson(Map<String, dynamic> json) {
    // Handle is_active as either int (0/1) or bool
    bool isActive;
    final isActiveValue = json['is_active'];
    if (isActiveValue is int) {
      isActive = isActiveValue == 1;
    } else if (isActiveValue is bool) {
      isActive = isActiveValue;
    } else {
      isActive = true; // Default to true if not provided
    }

    // Handle admin_user_id - may be missing for superadmin groups
    final adminUserId = json['admin_user_id'] as int? ?? json['user_id'] as int? ?? 0;
    
    // Handle group_name - may be 'name' in response
    final groupName = json['group_name'] as String? ?? json['name'] as String?;
    
    // Handle members_count - API may return 'member_count' (singular) or 'members_count' (plural)
    final membersCount = json['members_count'] as int? ?? 
                         json['member_count'] as int?;
    
    // Handle updated_at - may be missing, use created_at as fallback
    final updatedAt = json['updated_at'] as String? ?? json['created_at'] as String;

    return AdminGroupDto(
      id: json['id'] as int,
      adminUserId: adminUserId,
      groupCode: json['group_code'] as String,
      groupName: groupName,
      isActive: isActive,
      membersCount: membersCount,
      createdAt: json['created_at'] as String,
      updatedAt: updatedAt,
    );
  }

  /// Convert DTO to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_user_id': adminUserId,
      'group_code': groupCode,
      if (groupName != null) 'group_name': groupName,
      'is_active': isActive ? 1 : 0,
      if (membersCount != null) 'members_count': membersCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Convert DTO to domain entity
  AdminGroup toEntity() {
    return AdminGroup(
      id: id,
      adminUserId: adminUserId,
      groupCode: groupCode,
      groupName: groupName,
      isActive: isActive,
      membersCount: membersCount,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  /// Create DTO from domain entity
  factory AdminGroupDto.fromEntity(AdminGroup entity) {
    return AdminGroupDto(
      id: entity.id,
      adminUserId: entity.adminUserId,
      groupCode: entity.groupCode,
      groupName: entity.groupName,
      isActive: entity.isActive,
      membersCount: entity.membersCount,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }

  AdminGroupDto copyWith({
    int? id,
    int? adminUserId,
    String? groupCode,
    String? groupName,
    bool? isActive,
    int? membersCount,
    String? createdAt,
    String? updatedAt,
  }) {
    return AdminGroupDto(
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
}

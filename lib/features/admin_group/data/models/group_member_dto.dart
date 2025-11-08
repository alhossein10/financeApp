import '../../domain/entities/group_member.dart';

/// Data Transfer Object for GroupMember API communication
/// Handles JSON serialization/deserialization for Laravel API
class GroupMemberDto {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? organizationName;
  final String? departmentName;
  final String createdAt;

  const GroupMemberDto({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.organizationName,
    this.departmentName,
    required this.createdAt,
  });

  /// Create DTO from JSON response from Laravel API
  factory GroupMemberDto.fromJson(Map<String, dynamic> json) {
    return GroupMemberDto(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      organizationName: json['organization_name'] as String?,
      departmentName: json['department_name'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  /// Convert DTO to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      if (organizationName != null) 'organization_name': organizationName,
      if (departmentName != null) 'department_name': departmentName,
      'created_at': createdAt,
    };
  }

  /// Convert DTO to domain entity
  GroupMember toEntity() {
    return GroupMember(
      id: id,
      name: name,
      email: email,
      role: role,
      organizationName: organizationName,
      departmentName: departmentName,
      createdAt: DateTime.parse(createdAt),
    );
  }

  /// Create DTO from domain entity
  factory GroupMemberDto.fromEntity(GroupMember entity) {
    return GroupMemberDto(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      role: entity.role,
      organizationName: entity.organizationName,
      departmentName: entity.departmentName,
      createdAt: entity.createdAt.toIso8601String(),
    );
  }

  GroupMemberDto copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    String? organizationName,
    String? departmentName,
    String? createdAt,
  }) {
    return GroupMemberDto(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      organizationName: organizationName ?? this.organizationName,
      departmentName: departmentName ?? this.departmentName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Response wrapper for paginated group members list
class GroupMemberListResponse {
  final List<GroupMemberDto> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const GroupMemberListResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  /// Create response from JSON
  factory GroupMemberListResponse.fromJson(Map<String, dynamic> json) {
    print('[GroupMemberListResponse] Parsing JSON response...');
    print('[GroupMemberListResponse] JSON structure: ${json.keys.toList()}');
    
    List<dynamic> membersList = [];
    Map<String, dynamic> paginationInfo = {
      'current_page': 1,
      'last_page': 1,
      'per_page': 15,
      'total': 0,
    };
    
    // Handle nested response structure: {success: true, data: {members: {data: [], current_page: 1, ...}}}
    if (json.containsKey('data') && json['data'] is Map) {
      final data = json['data'] as Map<String, dynamic>;
      print('[GroupMemberListResponse] Found data key, type: ${data.runtimeType}');
      print('[GroupMemberListResponse] Data keys: ${data.keys.toList()}');
      
      // Check if members is a nested object with data array inside
      if (data.containsKey('members')) {
        final members = data['members'];
        print('[GroupMemberListResponse] Found members key, type: ${members.runtimeType}');
        
        if (members is Map<String, dynamic>) {
          // Structure: data.members.data is the array, data.members contains pagination
          print('[GroupMemberListResponse] Members is a Map (paginated structure)');
          final membersMap = members;
          
          // Extract members list from data.members.data
          if (membersMap.containsKey('data') && membersMap['data'] is List) {
            membersList = membersMap['data'] as List<dynamic>;
            print('[GroupMemberListResponse] ✅ Found ${membersList.length} members in data.members.data');
          } else {
            print('[GroupMemberListResponse] ⚠️ Warning: data.members.data is not a List or not found');
          }
          
          // Use members object itself for pagination info
          paginationInfo = membersMap;
          print('[GroupMemberListResponse] Pagination info: current_page=${paginationInfo['current_page']}, total=${paginationInfo['total']}');
        } else if (members is List) {
          // Structure: data.members is directly the array
          print('[GroupMemberListResponse] Members is a List (flat structure)');
          membersList = members;
          print('[GroupMemberListResponse] ✅ Found ${membersList.length} members in data.members');
          
          // Extract pagination from data level
          paginationInfo = data;
        } else {
          print('[GroupMemberListResponse] ⚠️ Warning: members is neither Map nor List, type: ${members.runtimeType}');
        }
      } else if (data.containsKey('data') && data['data'] is List) {
        // Alternative structure: data.data is the list
        print('[GroupMemberListResponse] Found data.data as List');
        membersList = data['data'] as List<dynamic>;
        print('[GroupMemberListResponse] ✅ Found ${membersList.length} members in data.data');
        paginationInfo = data;
      } else {
        // Fallback: check if data itself contains pagination info
        if (data.containsKey('current_page') || data.containsKey('per_page')) {
          // Pagination info is directly in data, but no members found
          print('[GroupMemberListResponse] ⚠️ Warning: Found pagination info but no members list');
          paginationInfo = data;
        } else {
          print('[GroupMemberListResponse] ⚠️ Warning: Using default pagination values');
        }
      }
    } else {
      // Handle flat structure: {data: [], current_page: 1, ...}
      print('[GroupMemberListResponse] Handling flat structure');
      if (json.containsKey('data') && json['data'] is List) {
        membersList = json['data'] as List<dynamic>;
        print('[GroupMemberListResponse] ✅ Found ${membersList.length} members in flat data');
      }
      paginationInfo = json;
    }
    
    print('[GroupMemberListResponse] Final members count: ${membersList.length}');
    print('[GroupMemberListResponse] Final pagination: page=${paginationInfo['current_page']}, total=${paginationInfo['total']}');
    
    try {
      final result = GroupMemberListResponse(
        data: membersList.map((item) {
          try {
            return GroupMemberDto.fromJson(item as Map<String, dynamic>);
          } catch (e) {
            print('[GroupMemberListResponse] ❌ Error parsing member: $e');
            print('[GroupMemberListResponse] Member data: $item');
            rethrow;
          }
        }).toList(),
        currentPage: paginationInfo['current_page'] as int? ?? 1,
        lastPage: paginationInfo['last_page'] as int? ?? 1,
        perPage: paginationInfo['per_page'] as int? ?? 15,
        total: paginationInfo['total'] as int? ?? 0,
      );
      
      print('[GroupMemberListResponse] ✅ Successfully parsed ${result.data.length} members');
      return result;
    } catch (e, stackTrace) {
      print('[GroupMemberListResponse] ❌ Error creating GroupMemberListResponse: $e');
      print('[GroupMemberListResponse] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Convert response to JSON
  Map<String, dynamic> toJson() {
    return {
      'data': data.map((dto) => dto.toJson()).toList(),
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
    };
  }
}

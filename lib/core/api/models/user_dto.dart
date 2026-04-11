import '../../../features/auth/domain/entities/user.dart';

/// User Data Transfer Object for API communication
/// Maps between API JSON and domain User entity
class UserDto {
  final int id;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? profileImageUrl; // URL for profile image from API
  
  // New fields for admin group management
  final String? organizationName;
  final String? departmentName;
  final int? adminGroupId;
  final int? superAdminGroupId;
  
  // Deprecated but kept for backward compatibility
  final int? organizationId;
  final int? departmentId;

  const UserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.updatedAt,
    this.profileImageUrl,
    this.organizationName,
    this.departmentName,
    this.adminGroupId,
    this.superAdminGroupId,
    this.organizationId,
    this.departmentId,
  });

  /// Create UserDto from JSON response
  factory UserDto.fromJson(Map<String, dynamic> json) {
    print('🔵 [UserDTO] Parsing JSON: $json');
    
    // Check if this is an error response (has 'message' but no user data)
    if (json.containsKey('message') && !json.containsKey('data') && !json.containsKey('id')) {
      print('🔴 [UserDTO] Error response detected: ${json['message']}');
      throw Exception('API Error: ${json['message']}');
    }
    
    // Handle nested 'data.user' wrapper (for /auth/me endpoint)
    Map<String, dynamic> userData;
    if (json.containsKey('data') && json['data'] is Map) {
      final data = json['data'] as Map<String, dynamic>;
      if (data.containsKey('user')) {
        userData = data['user'] as Map<String, dynamic>;
        print('🔵 [UserDTO] Found nested data.user structure');
      } else {
        userData = data;
        print('🔵 [UserDTO] Found data structure');
      }
    } else {
      userData = json;
      print('🔵 [UserDTO] Using direct JSON structure');
    }
    
    print('🔵 [UserDTO] User data to parse: $userData');
    
    try {
      // Extract admin_group_id from either direct field or managed_group relationship
      int? adminGroupId = userData['admin_group_id'] as int?;
      
      // If admin_group_id is null but managed_group exists, extract from there
      if (adminGroupId == null && userData['managed_group'] != null) {
        final managedGroup = userData['managed_group'] as Map<String, dynamic>;
        adminGroupId = managedGroup['id'] as int?;
        print('🔵 [UserDTO] Extracted admin_group_id from managed_group: $adminGroupId');
      }
      
      // Extract super_admin_group_id
      int? superAdminGroupId = userData['super_admin_group_id'] as int?;
      
      // If super_admin_group_id is null but super_admin_group exists, extract from there
      if (superAdminGroupId == null && userData['super_admin_group'] != null) {
        final superAdminGroup = userData['super_admin_group'] as Map<String, dynamic>;
        superAdminGroupId = superAdminGroup['id'] as int?;
        print('🔵 [UserDTO] Extracted super_admin_group_id from super_admin_group: $superAdminGroupId');
      }
      
      // Safely parse ID - handle both int and string types, with fallback
      final dynamic rawId = userData['id'];
      int? userId;
      if (rawId is int) {
        userId = rawId;
      } else if (rawId is String) {
        userId = int.tryParse(rawId);
      }
      
      // If ID is still null, try to get from other sources or use a default
      if (userId == null) {
        print('⚠️ [UserDTO] User ID is null, checking alternative sources');
        // Try to get from user_id field
        final altId = userData['user_id'];
        if (altId is int) {
          userId = altId;
        } else if (altId is String) {
          userId = int.tryParse(altId);
        }
        
        // If still null, check if we're in a nested structure
        if (userId == null && json.containsKey('user')) {
          final nestedUser = json['user'] as Map<String, dynamic>?;
          if (nestedUser != null) {
            final nestedId = nestedUser['id'];
            if (nestedId is int) {
              userId = nestedId;
            } else if (nestedId is String) {
              userId = int.tryParse(nestedId);
            }
          }
        }
        
        // If still null, this is a critical error
        if (userId == null) {
          print('🔴 [UserDTO] Cannot find valid user ID in response');
          print('🔴 [UserDTO] Available keys: ${userData.keys.toList()}');
          print('🔴 [UserDTO] Full JSON: $json');
          throw Exception('User ID is null and cannot be determined from response. Please ensure the backend is returning user data correctly.');
        }
      }
      
      final userDto = UserDto(
        id: userId,
        name: userData['name'] as String? ?? '',
        email: userData['email'] as String? ?? '',
        role: (userData['role'] as String?) ?? 'user', // Default to 'user' if role is null
        createdAt: userData['created_at'] != null 
            ? DateTime.parse(userData['created_at'] as String)
            : DateTime.now(),
        updatedAt: userData['updated_at'] != null
            ? DateTime.parse(userData['updated_at'] as String)
            : null,
        profileImageUrl: userData['profile_photo_url'] as String? ?? userData['profile_image_url'] as String?,
        // New fields - prioritize new format over old
        organizationName: userData['organization_name'] as String?,
        departmentName: userData['department_name'] as String?,
        adminGroupId: adminGroupId,
        superAdminGroupId: superAdminGroupId,
        // Backward compatibility fields
        organizationId: userData['organization_id'] as int?,
        departmentId: userData['department_id'] as int?,
      );
      
      print('✅ [UserDTO] Parsed successfully: id=${userDto.id}, email=${userDto.email}, role=${userDto.role}, adminGroupId=${userDto.adminGroupId}');
      return userDto;
    } catch (e, stackTrace) {
      print('🔴 [UserDTO] Parse error: $e');
      print('🔴 [UserDTO] Stack trace: $stackTrace');
      print('🔴 [UserDTO] JSON keys: ${userData.keys.toList()}');
      if (userData.containsKey('id')) {
        print('🔴 [UserDTO] ID value: ${userData['id']} (${userData['id'].runtimeType})');
      }
      rethrow;
    }
  }

  /// Convert UserDto to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      if (organizationName != null) 'organization_name': organizationName,
      if (departmentName != null) 'department_name': departmentName,
      if (adminGroupId != null) 'admin_group_id': adminGroupId,
      if (superAdminGroupId != null) 'super_admin_group_id': superAdminGroupId,
      // Include old fields for backward compatibility
      if (organizationId != null) 'organization_id': organizationId,
      if (departmentId != null) 'department_id': departmentId,
    };
  }

  /// Convert UserDto to domain User entity
  User toEntity() {
    return User(
      id: id,
      username: name,
      email: email,
      role: _mapRole(role),
      createdAt: createdAt,
      updatedAt: updatedAt,
      profileImageUrl: profileImageUrl,
      // Prioritize new fields over old fields
      organizationName: organizationName,
      departmentName: departmentName,
      adminGroupId: adminGroupId,
      superAdminGroupId: superAdminGroupId,
      // Fallback to old fields for backward compatibility
      organizationId: organizationId ?? 1, // Default organization ID if not provided
      departmentId: departmentId,
    );
  }

  /// Create UserDto from domain User entity
  factory UserDto.fromEntity(User user) {
    return UserDto(
      id: user.id,
      name: user.username,
      email: user.email,
      role: user.role == UserRole.admin 
          ? 'admin' 
          : user.role == UserRole.superAdmin 
              ? 'superAdmin' 
              : 'user',
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      profileImageUrl: user.profileImageUrl,
      organizationName: user.organizationName,
      departmentName: user.departmentName,
      adminGroupId: user.adminGroupId,
      superAdminGroupId: user.superAdminGroupId,
      organizationId: user.organizationId,
      departmentId: user.departmentId,
    );
  }

  /// Map string role to UserRole enum
  static UserRole _mapRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'superadmin':
        return UserRole.superAdmin;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  /// Check if user is admin
  bool get isAdmin => role.toLowerCase() == 'admin';
  
  /// Check if user is superAdmin
  bool get isSuperAdmin => role.toLowerCase() == 'superadmin';

  @override
  String toString() {
    return 'UserDto(id: $id, name: $name, email: $email, role: $role)';
  }
}

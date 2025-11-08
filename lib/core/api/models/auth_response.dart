import 'user_dto.dart';

/// Authentication response from Laravel API
/// Contains user data and authentication token
class AuthResponse {
  final UserDto user;
  final String token;
  final String tokenType;
  final DateTime? expiresAt;
  final String? groupCode; // Admin group code (for admin registration)
  final String? superAdminGroupCode; // SuperAdmin group code (for SuperAdmin registration)
  final String? adminGroupName; // Admin group name (for SuperAdmin registration)

  const AuthResponse({
    required this.user,
    required this.token,
    this.tokenType = 'Bearer',
    this.expiresAt,
    this.groupCode,
    this.superAdminGroupCode,
    this.adminGroupName,
  });

  /// Create AuthResponse from JSON
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Handle both direct response and nested 'data' response
    final data = json.containsKey('data') ? json['data'] as Map<String, dynamic> : json;
    
    // Extract admin group code from either direct field or admin_group relationship
    String? groupCode = (data['group_code'] ?? json['group_code']) as String?;
    
    // Extract SuperAdmin group code from either direct field or super_admin_group relationship
    String? superAdminGroupCode = (data['super_admin_group_code'] ?? json['super_admin_group_code']) as String?;
    
    // Extract admin group name
    String? adminGroupName = (data['admin_group_name'] ?? json['admin_group_name']) as String?;
    
    // If group_code is null, try to extract from user.managed_group or admin_group
    if (groupCode == null) {
      final userData = data['user'] is Map<String, dynamic> 
          ? (data['user'] as Map<String, dynamic>)
          : data;
      
      if (userData['managed_group'] != null) {
        final managedGroup = userData['managed_group'] as Map<String, dynamic>;
        groupCode = managedGroup['group_code'] as String?;
        print('🔵 [AuthResponse] Extracted group_code from managed_group: $groupCode');
      } else if (data['admin_group'] != null) {
        final adminGroup = data['admin_group'] as Map<String, dynamic>;
        groupCode = adminGroup['group_code'] as String?;
        print('🔵 [AuthResponse] Extracted group_code from admin_group: $groupCode');
      }
    }
    
    // If superAdminGroupCode is null, try to extract from super_admin_group
    if (superAdminGroupCode == null && data['super_admin_group'] != null) {
      final superAdminGroup = data['super_admin_group'] as Map<String, dynamic>;
      superAdminGroupCode = superAdminGroup['group_code'] as String?;
      print('🔵 [AuthResponse] Extracted super_admin_group_code from super_admin_group: $superAdminGroupCode');
    }
    
    // If adminGroupName is null, try to extract from super_admin_group or admin_group
    if (adminGroupName == null) {
      if (data['super_admin_group'] != null) {
        final superAdminGroup = data['super_admin_group'] as Map<String, dynamic>;
        adminGroupName = superAdminGroup['name'] as String?;
        print('🔵 [AuthResponse] Extracted admin_group_name from super_admin_group: $adminGroupName');
      } else if (data['admin_group'] != null) {
        final adminGroup = data['admin_group'] as Map<String, dynamic>;
        adminGroupName = adminGroup['name'] as String?;
        print('🔵 [AuthResponse] Extracted admin_group_name from admin_group: $adminGroupName');
      }
    }
    
    return AuthResponse(
      user: UserDto.fromJson(
        data['user'] is Map<String, dynamic> 
          ? (data['user'] as Map<String, dynamic>)
          : data
      ),
      token: (data['token'] ?? data['access_token'] ?? json['token'] ?? json['access_token']) as String,
      tokenType: (data['token_type'] ?? json['token_type']) as String? ?? 'Bearer',
      expiresAt: (data['expires_at'] ?? json['expires_at']) != null
          ? DateTime.parse((data['expires_at'] ?? json['expires_at']) as String)
          : null,
      groupCode: groupCode,
      superAdminGroupCode: superAdminGroupCode,
      adminGroupName: adminGroupName,
    );
  }

  /// Convert AuthResponse to JSON
  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
      'token_type': tokenType,
      'expires_at': expiresAt?.toIso8601String(),
      if (groupCode != null) 'group_code': groupCode,
      if (superAdminGroupCode != null) 'super_admin_group_code': superAdminGroupCode,
      if (adminGroupName != null) 'admin_group_name': adminGroupName,
    };
  }

  /// Check if token is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if token will expire soon (within 5 minutes)
  bool get willExpireSoon {
    if (expiresAt == null) return false;
    final fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5));
    return fiveMinutesFromNow.isAfter(expiresAt!);
  }

  @override
  String toString() {
    return 'AuthResponse(user: ${user.email}, token: ${token.substring(0, 10)}..., expiresAt: $expiresAt)';
  }
}

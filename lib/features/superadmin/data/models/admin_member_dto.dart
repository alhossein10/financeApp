/// Data Transfer Object for Admin Member in SuperAdmin Group
class AdminMemberDto {
  final int id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final int? adminGroupId;
  final String? adminGroupName;
  final int userCount;
  final DateTime createdAt;

  const AdminMemberDto({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.adminGroupId,
    this.adminGroupName,
    required this.userCount,
    required this.createdAt,
  });

  /// Create from JSON response
  factory AdminMemberDto.fromJson(Map<String, dynamic> json) {
    // Debug logging for profile photo
    print('[AdminMemberDto] Parsing member: ${json['name']}');
    print('[AdminMemberDto]   - profile_photo_url: ${json['profile_photo_url']}');
    print('[AdminMemberDto]   - profile_image_url: ${json['profile_image_url']}');
    print('[AdminMemberDto]   - All keys: ${json.keys.toList()}');
    
    final profileUrl = json['profile_photo_url'] as String? ?? json['profile_image_url'] as String?;
    print('[AdminMemberDto]   - Final profileImageUrl: $profileUrl');
    
    return AdminMemberDto(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      // Support both profile_photo_url (new Laravel accessor) and profile_image_url (old) for compatibility
      profileImageUrl: profileUrl,
      adminGroupId: json['admin_group_id'] as int?,
      adminGroupName: json['admin_group_name'] as String?,
      userCount: json['user_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      if (adminGroupId != null) 'admin_group_id': adminGroupId,
      if (adminGroupName != null) 'admin_group_name': adminGroupName,
      'user_count': userCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AdminMemberDto(id: $id, name: $name, email: $email, users: $userCount)';
  }
}

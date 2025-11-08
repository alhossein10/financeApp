import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/services/role_service.dart';
import '../../../../core/services/token_manager.dart';
import '../../../auth/domain/entities/user.dart';
import '../models/admin_group_dto.dart';
import '../models/group_member_dto.dart';
import '../models/group_info_dto.dart';

/// API data source for admin group operations
/// 
/// This data source handles all HTTP requests related to admin group management,
/// including group information retrieval, member management, and group joining.
abstract class AdminGroupApiDataSource {
  /// Get admin's group information
  /// 
  /// Endpoint: GET /api/v1/admin/group
  /// 
  /// Returns the admin group details including group code, name, and member count.
  /// 
  /// Throws [ApiException] if the request fails or user is not an admin.
  /// 
  /// Requirements: 6.1
  Future<AdminGroupDto> getAdminGroup();

  /// Regenerate group code for admin's group
  /// 
  /// Endpoint: POST /api/v1/admin/group/regenerate
  /// 
  /// Generates a new 6-character group code and invalidates the old one.
  /// Returns the updated admin group with the new code.
  /// 
  /// Throws [ApiException] if the request fails or user is not an admin.
  /// 
  /// Requirements: 6.2
  Future<AdminGroupDto> regenerateGroupCode();

  /// Get list of group members with pagination and filters
  /// 
  /// Endpoint: GET /api/v1/admin/group/members
  /// 
  /// Query Parameters:
  /// - page: Page number (default: 1)
  /// - per_page: Items per page (default: 15)
  /// - search: Search term for name or email (optional)
  /// - department: Filter by department name (optional)
  /// 
  /// Returns a paginated list of group members with their details.
  /// 
  /// Throws [ApiException] if the request fails or user is not an admin.
  /// 
  /// Requirements: 6.3
  Future<GroupMemberListResponse> getGroupMembers({
    int page = 1,
    int perPage = 15,
    String? search,
    String? department,
  });

  /// Remove a member from the admin's group
  /// 
  /// Endpoint: DELETE /api/v1/admin/group/members/{id}
  /// 
  /// Removes the specified user from the group. Admin cannot remove themselves.
  /// 
  /// Throws [ApiException] if:
  /// - Request fails
  /// - User is not an admin
  /// - Member not found
  /// - Admin tries to remove themselves
  /// 
  /// Requirements: 6.4
  Future<void> removeMember(int userId);

  /// Join a group using a group code
  /// 
  /// Endpoint: POST /api/v1/user/join-group
  /// 
  /// Request Body:
  /// - group_code: 6-character alphanumeric code (case-insensitive)
  /// 
  /// Allows a regular user to join an admin's group using the group code.
  /// 
  /// Throws [ApiException] if:
  /// - Request fails
  /// - Group code is invalid
  /// - User is already in a group
  /// - User is an admin (admins cannot join groups)
  /// 
  /// Requirements: 6.5
  Future<GroupInfoDto> joinGroup(String groupCode);

  /// Get user's group information
  /// 
  /// Endpoint: GET /api/v1/user/group-info
  /// 
  /// Returns information about the group the user belongs to,
  /// including group code, admin details, and member count.
  /// 
  /// Throws [ApiException] if:
  /// - Request fails
  /// - User is not in any group
  /// 
  /// Requirements: 6.6
  Future<GroupInfoDto> getUserGroupInfo();

  /// Join a SuperAdmin group using a group code (for admin users)
  /// 
  /// Endpoint: POST /api/v1/admin/join-superadmin-group
  /// 
  /// Request Body:
  /// - super_admin_group_code: 6-character alphanumeric code (case-insensitive)
  /// 
  /// Allows an admin user to join a SuperAdmin group using the group code.
  /// This is separate from the admin's own group (adminGroupId).
  /// 
  /// Throws [ApiException] if:
  /// - Request fails
  /// - Group code is invalid
  /// - Admin is already in a SuperAdmin group
  /// - User is not an admin
  /// 
  /// Requirements: Admin joining SuperAdmin group
  Future<GroupInfoDto> joinSuperAdminGroup(String groupCode);
}


/// Implementation of [AdminGroupApiDataSource] using HTTP API
class AdminGroupApiDataSourceImpl implements AdminGroupApiDataSource {
  final ApiClient apiClient;
  final RoleService roleService;
  final TokenManager? tokenManager;
  
  // Cache the role to avoid repeated API calls
  UserRole? _cachedRole;
  DateTime? _roleCacheTime;
  static const _roleCacheDuration = Duration(minutes: 5); // Cache role for 5 minutes

  AdminGroupApiDataSourceImpl({
    required this.apiClient,
    required this.roleService,
    this.tokenManager,
  });

  /// Get the appropriate base path based on user role
  /// Uses cached role to avoid repeated API calls
  Future<String> get _basePath async {
    // Check if cached role is still valid
    if (_cachedRole != null && 
        _roleCacheTime != null && 
        DateTime.now().difference(_roleCacheTime!) < _roleCacheDuration) {
      print('[AdminGroupApiDataSource] Using cached role: $_cachedRole');
      return _cachedRole == UserRole.superAdmin ? '/superadmin' : '/admin';
    }
    
    // Fetch role and cache it
    print('[AdminGroupApiDataSource] Fetching role from RoleService...');
    _cachedRole = await roleService.getCurrentUserRole();
    _roleCacheTime = DateTime.now();
    print('[AdminGroupApiDataSource] Cached role: $_cachedRole');
    
    return _cachedRole == UserRole.superAdmin ? '/superadmin' : '/admin';
  }
  
  /// Clear role cache (call this on logout or role change)
  void clearRoleCache() {
    _cachedRole = null;
    _roleCacheTime = null;
    print('[AdminGroupApiDataSource] Role cache cleared');
  }

  @override
  Future<AdminGroupDto> getAdminGroup() async {
    try {
      // Ensure authentication token is set on ApiClient
      // First, check if token is already set on ApiClient
      var token = apiClient.getAuthToken();
      
      // If token is not set on ApiClient, try to retrieve it from TokenManager
      if ((token == null || token.isEmpty) && tokenManager != null) {
        print('[AdminGroupApiDataSource] ⚠️ No token found on ApiClient, retrieving from TokenManager...');
        try {
          final storedToken = await tokenManager!.getToken();
          if (storedToken != null && storedToken.isNotEmpty) {
            // Set the token on ApiClient
            apiClient.setAuthToken(storedToken);
            token = storedToken;
            print('[AdminGroupApiDataSource] ✅ Token retrieved from TokenManager and set on ApiClient');
            print('[AdminGroupApiDataSource] ✅ Token preview: ${token.substring(0, 20)}...');
          } else {
            print('[AdminGroupApiDataSource] ⚠️ Warning: No authentication token found in TokenManager');
            print('[AdminGroupApiDataSource] ⚠️ The request may fail without authentication');
          }
        } catch (e) {
          print('[AdminGroupApiDataSource] ❌ Error retrieving token from TokenManager: $e');
          print('[AdminGroupApiDataSource] ⚠️ The request may fail without authentication');
        }
      } else if (token != null && token.isNotEmpty) {
        print('[AdminGroupApiDataSource] ✅ Authentication token is set on ApiClient');
        print('[AdminGroupApiDataSource] ✅ Token preview: ${token.substring(0, 20)}...');
      } else {
        print('[AdminGroupApiDataSource] ⚠️ Warning: No authentication token found');
        print('[AdminGroupApiDataSource] ⚠️ The request may fail without authentication');
      }
      
      final basePath = await _basePath;
      final endpoint = '$basePath/group';
      print('[AdminGroupApiDataSource] Fetching admin group from: $endpoint');
      print('[AdminGroupApiDataSource] Full URL will be: $endpoint');
      
      // Make the request - ApiClient will automatically add Bearer token via interceptor
      final response = await apiClient.get(endpoint);
      print('[AdminGroupApiDataSource] Response status: ${response.statusCode}');
      print('[AdminGroupApiDataSource] Response data: ${response.data}');

      if (response.statusCode == 200) {
        try {
          final responseData = response.data as Map<String, dynamic>;
          
          // Handle nested response structure: data.group
          if (responseData.containsKey('data')) {
            final data = responseData['data'] as Map<String, dynamic>;
            
            // Check if group is nested inside data
            if (data.containsKey('group')) {
              return AdminGroupDto.fromJson(data['group'] as Map<String, dynamic>);
            } else {
              return AdminGroupDto.fromJson(data);
            }
          } else {
            return AdminGroupDto.fromJson(responseData);
          }
        } catch (e) {
          print('[AdminGroupApiDataSource] Error parsing response: $e');
          throw ApiException(
            message: 'Failed to parse admin group response: ${e.toString()}',
            statusCode: 500,
          );
        }
      } else {
        // Extract error message from response if available
        String errorMessage = 'Failed to fetch admin group';
        if (response.data is Map<String, dynamic>) {
          final errorData = response.data as Map<String, dynamic>;
          errorMessage = errorData['message'] as String? ?? 
                        errorData['error'] as String? ?? 
                        errorMessage;
        }
        
        throw ApiException(
          message: errorMessage,
          statusCode: response.statusCode,
        );
      }
    } on ApiException catch (e) {
      print('[AdminGroupApiDataSource] ApiException: ${e.message}, status: ${e.statusCode}');
      rethrow;
    } catch (e, stackTrace) {
      print('[AdminGroupApiDataSource] Unexpected error: $e');
      print('[AdminGroupApiDataSource] Stack trace: $stackTrace');
      throw ApiException(
        message: 'Failed to fetch admin group: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AdminGroupDto> regenerateGroupCode() async {
    try {
      final basePath = await _basePath;
      // SuperAdmin uses different endpoint path
      final role = await roleService.getCurrentUserRole();
      final endpoint = role == UserRole.superAdmin
          ? '$basePath/group/regenerate-code'
          : '$basePath/group/regenerate';
      final response = await apiClient.post(endpoint);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>;
        
        // Handle nested response structure: data.group
        if (responseData.containsKey('data')) {
          final data = responseData['data'] as Map<String, dynamic>;
          
          // Check if group is nested inside data
          if (data.containsKey('group')) {
            return AdminGroupDto.fromJson(data['group'] as Map<String, dynamic>);
          } else {
            return AdminGroupDto.fromJson(data);
          }
        } else {
          return AdminGroupDto.fromJson(responseData);
        }
      } else {
        throw ApiException(
          message: 'Failed to regenerate group code',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to regenerate group code: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<GroupMemberListResponse> getGroupMembers({
    int page = 1,
    int perPage = 15,
    String? search,
    String? department,
  }) async {
    try {
      // Ensure authentication token is set on ApiClient
      // First, check if token is already set on ApiClient
      var token = apiClient.getAuthToken();
      
      // If token is not set on ApiClient, try to retrieve it from TokenManager
      if ((token == null || token.isEmpty) && tokenManager != null) {
        print('[AdminGroupApiDataSource] ⚠️ No token found on ApiClient, retrieving from TokenManager...');
        try {
          final storedToken = await tokenManager!.getToken();
          if (storedToken != null && storedToken.isNotEmpty) {
            // Set the token on ApiClient
            apiClient.setAuthToken(storedToken);
            token = storedToken;
            print('[AdminGroupApiDataSource] ✅ Token retrieved from TokenManager and set on ApiClient');
            print('[AdminGroupApiDataSource] ✅ Token preview: ${token.substring(0, 20)}...');
          } else {
            print('[AdminGroupApiDataSource] ⚠️ Warning: No authentication token found in TokenManager');
            print('[AdminGroupApiDataSource] ⚠️ The request may fail without authentication');
          }
        } catch (e) {
          print('[AdminGroupApiDataSource] ❌ Error retrieving token from TokenManager: $e');
          print('[AdminGroupApiDataSource] ⚠️ The request may fail without authentication');
        }
      } else if (token != null && token.isNotEmpty) {
        print('[AdminGroupApiDataSource] ✅ Authentication token is set on ApiClient');
        print('[AdminGroupApiDataSource] ✅ Token preview: ${token.substring(0, 20)}...');
      } else {
        print('[AdminGroupApiDataSource] ⚠️ Warning: No authentication token found');
        print('[AdminGroupApiDataSource] ⚠️ The request may fail without authentication');
      }
      
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      // Add search filter if provided
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      // Add department filter if provided
      if (department != null && department.isNotEmpty) {
        queryParams['department'] = department;
      }

      final basePath = await _basePath;
      final endpoint = '$basePath/group/members';
      print('[AdminGroupApiDataSource] Fetching group members from: $endpoint');
      print('[AdminGroupApiDataSource] Query params: $queryParams');
      print('[AdminGroupApiDataSource] Full URL will be: ${basePath}/group/members with query params');
      
      // Make the request - ApiClient will automatically add Bearer token via interceptor
      final response = await apiClient.get(
        endpoint,
        queryParams: queryParams,
      );
      
      print('[AdminGroupApiDataSource] Response status: ${response.statusCode}');
      print('[AdminGroupApiDataSource] Response data: ${response.data}');

      if (response.statusCode == 200) {
        try {
          final responseData = response.data as Map<String, dynamic>;
          
          // Handle both wrapped and unwrapped responses
          if (responseData.containsKey('success') && responseData['success'] == true) {
            return GroupMemberListResponse.fromJson(responseData);
          } else {
            return GroupMemberListResponse.fromJson(responseData);
          }
        } catch (e) {
          print('[AdminGroupApiDataSource] Error parsing group members response: $e');
          throw ApiException(
            message: 'Failed to parse group members response: ${e.toString()}',
            statusCode: 500,
          );
        }
      } else {
        // Extract error message from response if available
        String errorMessage = 'Failed to fetch group members';
        if (response.data is Map<String, dynamic>) {
          final errorData = response.data as Map<String, dynamic>;
          errorMessage = errorData['message'] as String? ?? 
                        errorData['error'] as String? ?? 
                        errorMessage;
        }
        
        throw ApiException(
          message: errorMessage,
          statusCode: response.statusCode,
        );
      }
    } on ApiException catch (e) {
      print('[AdminGroupApiDataSource] ApiException: ${e.message}, status: ${e.statusCode}');
      rethrow;
    } catch (e, stackTrace) {
      print('[AdminGroupApiDataSource] Unexpected error: $e');
      print('[AdminGroupApiDataSource] Stack trace: $stackTrace');
      throw ApiException(
        message: 'Failed to fetch group members: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> removeMember(int userId) async {
    try {
      final basePath = await _basePath;
      final response = await apiClient.delete('$basePath/group/members/$userId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        // Check for specific error messages
        if (response.statusCode == 403) {
          final data = response.data as Map<String, dynamic>?;
          final message = data?['message'] as String? ?? 'Cannot remove this member';
          throw ApiException(
            message: message,
            statusCode: response.statusCode,
          );
        } else if (response.statusCode == 404) {
          throw ApiException(
            message: 'User not found or not in your group',
            statusCode: response.statusCode,
          );
        } else {
          throw ApiException(
            message: 'Failed to remove member',
            statusCode: response.statusCode,
          );
        }
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to remove member: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<GroupInfoDto> joinGroup(String groupCode) async {
    try {
      final response = await apiClient.post(
        '/user/join-group',
        body: {'group_code': groupCode},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        
        // Handle both wrapped and unwrapped responses
        if (data.containsKey('data')) {
          return GroupInfoDto.fromJson(data['data'] as Map<String, dynamic>);
        } else {
          return GroupInfoDto.fromJson(data);
        }
      } else {
        // Handle specific error cases
        if (response.statusCode == 422) {
          final data = response.data as Map<String, dynamic>?;
          final message = data?['message'] as String? ?? 'Invalid group code';
          throw ApiException(
            message: message,
            statusCode: response.statusCode,
          );
        } else if (response.statusCode == 400) {
          final data = response.data as Map<String, dynamic>?;
          final message = data?['message'] as String? ?? 'Bad request';
          throw ApiException(
            message: message,
            statusCode: response.statusCode,
          );
        } else {
          throw ApiException(
            message: 'Failed to join group',
            statusCode: response.statusCode,
          );
        }
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to join group: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<GroupInfoDto> getUserGroupInfo() async {
    try {
      final response = await apiClient.get('/user/group-info');

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        
        // Handle the actual API response structure:
        // { "success": true, "data": { "group": { ... }, "admin": { ... } } }
        if (responseData.containsKey('data')) {
          final data = responseData['data'] as Map<String, dynamic>;
          
          // Extract group and admin data
          final groupData = data['group'] as Map<String, dynamic>?;
          
          if (groupData == null) {
            throw ApiException(
              message: 'Invalid response structure: missing group data',
              statusCode: 500,
            );
          }
          
          // Transform the nested structure to match DTO expectations
          final transformedData = <String, dynamic>{
            'group_code': groupData['group_code'] as String? ?? '',
            'group_name': groupData['group_name'] as String?,
            'members_count': groupData['members_count'] as int? ?? 0,
            'joined_at': data['joined_at'] as String? ?? DateTime.now().toIso8601String(),
          };
          
          // Handle nested admin object
          if (groupData.containsKey('admin')) {
            final adminData = groupData['admin'] as Map<String, dynamic>;
            transformedData['admin_name'] = adminData['name'] as String;
            transformedData['admin_email'] = adminData['email'] as String;
          } else {
            // Fallback if admin is at root level
            transformedData['admin_name'] = data['admin_name'] as String? ?? 'Unknown';
            transformedData['admin_email'] = data['admin_email'] as String? ?? '';
          }
          
          return GroupInfoDto.fromJson(transformedData);
        } else {
          return GroupInfoDto.fromJson(responseData);
        }
      } else if (response.statusCode == 404) {
        throw ApiException(
          message: 'You are not in any group',
          statusCode: response.statusCode,
        );
      } else {
        throw ApiException(
          message: 'Failed to fetch group information',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch group information: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<GroupInfoDto> joinSuperAdminGroup(String groupCode) async {
    try {
      final response = await apiClient.post(
        '/admin/join-superadmin-group',
        body: {'super_admin_group_code': groupCode},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        
        // Handle both wrapped and unwrapped responses
        if (data.containsKey('data')) {
          return GroupInfoDto.fromJson(data['data'] as Map<String, dynamic>);
        } else {
          return GroupInfoDto.fromJson(data);
        }
      } else {
        // Handle specific error cases
        if (response.statusCode == 422) {
          final data = response.data as Map<String, dynamic>?;
          final message = data?['message'] as String? ?? 'Invalid SuperAdmin group code';
          throw ApiException(
            message: message,
            statusCode: response.statusCode,
          );
        } else if (response.statusCode == 400) {
          final data = response.data as Map<String, dynamic>?;
          final message = data?['message'] as String? ?? 'Bad request';
          throw ApiException(
            message: message,
            statusCode: response.statusCode,
          );
        } else if (response.statusCode == 403) {
          final data = response.data as Map<String, dynamic>?;
          final message = data?['message'] as String? ?? 'Access denied. Admin privileges required.';
          throw ApiException(
            message: message,
            statusCode: response.statusCode,
          );
        } else {
          throw ApiException(
            message: 'Failed to join SuperAdmin group',
            statusCode: response.statusCode,
          );
        }
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to join SuperAdmin group: ${e.toString()}',
        statusCode: 500,
      );
    }
  }
}

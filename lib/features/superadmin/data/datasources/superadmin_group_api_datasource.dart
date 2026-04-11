import '../../../../core/api/api_client.dart';
import '../../../../core/utils/pagination_helper.dart';
import '../models/superadmin_group_dto.dart';
import '../models/admin_member_dto.dart';

/// API datasource for SuperAdmin Group Management
/// Handles SuperAdmin group operations and member management
class SuperAdminGroupApiDatasource {
  final ApiClient _apiClient;

  SuperAdminGroupApiDatasource({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  /// Get SuperAdmin group information
  /// 
  /// Returns [SuperAdminGroupDto] with group details
  /// 
  /// Requires Bearer token authentication (automatically added by interceptor)
  /// 
  /// Throws ApiException on failure
  Future<SuperAdminGroupDto> getGroupInfo() async {
    try {
      print('🔵 [SUPERADMIN_GROUP] Fetching group info...');
      
      final response = await _apiClient.get('/superadmin/group');

      print('🟢 [SUPERADMIN_GROUP] Group info response received');
      print('🟢 [SUPERADMIN_GROUP] Response status: ${response.statusCode}');
      
      // Check if response is successful
      if (response.statusCode != 200) {
        print('❌ [SUPERADMIN_GROUP] Non-200 status code: ${response.statusCode}');
        throw Exception('Failed to load group info: ${response.statusCode}');
      }

      // Parse response data
      final data = response.data;
      
      if (data is! Map<String, dynamic>) {
        print('❌ [SUPERADMIN_GROUP] Invalid response format - expected Map, got ${data.runtimeType}');
        throw Exception('Invalid response format');
      }

      // Extract group info from response
      // Handle both direct data and nested 'data' wrapper
      final groupData = data.containsKey('data') 
          ? data['data'] as Map<String, dynamic>
          : data;
      
      final groupInfo = SuperAdminGroupDto.fromJson(groupData);
      
      print('✅ [SUPERADMIN_GROUP] Successfully loaded group info: ${groupInfo.name}');
      
      return groupInfo;
    } catch (e, stackTrace) {
      print('🔴 [SUPERADMIN_GROUP] Error fetching group info: $e');
      print('🔴 [SUPERADMIN_GROUP] Error type: ${e.runtimeType}');
      print('🔴 [SUPERADMIN_GROUP] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get paginated list of admin members in the SuperAdmin group
  /// 
  /// [page] - Page number (default: 1)
  /// [perPage] - Items per page (default: 15)
  /// 
  /// Returns [PaginatedResponse<AdminMemberDto>] with member list and pagination info
  /// 
  /// Requires Bearer token authentication (automatically added by interceptor)
  /// 
  /// Throws ApiException on failure
  Future<PaginatedResponse<AdminMemberDto>> getMembers({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      print('🔵 [SUPERADMIN_GROUP] Fetching members (page: $page, perPage: $perPage)...');
      
      final response = await _apiClient.get(
        '/superadmin/group/members',
        queryParams: {
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );

      print('🟢 [SUPERADMIN_GROUP] Members response received');
      print('🟢 [SUPERADMIN_GROUP] Response status: ${response.statusCode}');
      
      // Check if response is successful
      if (response.statusCode != 200) {
        print('❌ [SUPERADMIN_GROUP] Non-200 status code: ${response.statusCode}');
        throw Exception('Failed to load members: ${response.statusCode}');
      }

      // Parse response data
      final data = response.data;
      
      if (data is! Map<String, dynamic>) {
        print('❌ [SUPERADMIN_GROUP] Invalid response format - expected Map, got ${data.runtimeType}');
        throw Exception('Invalid response format');
      }

      // Parse paginated response
      final paginatedResponse = PaginatedResponse.fromJson(
        data,
        (json) => AdminMemberDto.fromJson(json as Map<String, dynamic>),
      );
      
      print('✅ [SUPERADMIN_GROUP] Successfully loaded ${paginatedResponse.data.length} members');
      
      return paginatedResponse;
    } catch (e, stackTrace) {
      print('🔴 [SUPERADMIN_GROUP] Error fetching members: $e');
      print('🔴 [SUPERADMIN_GROUP] Error type: ${e.runtimeType}');
      print('🔴 [SUPERADMIN_GROUP] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Regenerate the SuperAdmin group code
  /// 
  /// Returns [SuperAdminGroupDto] with new group code
  /// 
  /// Requires Bearer token authentication (automatically added by interceptor)
  /// 
  /// Throws ApiException on failure
  Future<SuperAdminGroupDto> regenerateCode() async {
    try {
      print('🔵 [SUPERADMIN_GROUP] Regenerating group code...');
      
      final response = await _apiClient.post('/superadmin/group/regenerate-code');

      print('🟢 [SUPERADMIN_GROUP] Regenerate code response received');
      print('🟢 [SUPERADMIN_GROUP] Response status: ${response.statusCode}');
      
      // Check if response is successful
      if (response.statusCode != 200) {
        print('❌ [SUPERADMIN_GROUP] Non-200 status code: ${response.statusCode}');
        throw Exception('Failed to regenerate code: ${response.statusCode}');
      }

      // Parse response data
      final data = response.data;
      
      if (data is! Map<String, dynamic>) {
        print('❌ [SUPERADMIN_GROUP] Invalid response format - expected Map, got ${data.runtimeType}');
        throw Exception('Invalid response format');
      }

      // Extract group info from response
      // Handle both direct data and nested 'data' wrapper
      final groupData = data.containsKey('data') 
          ? data['data'] as Map<String, dynamic>
          : data;
      
      final groupInfo = SuperAdminGroupDto.fromJson(groupData);
      
      print('✅ [SUPERADMIN_GROUP] Successfully regenerated code: ${groupInfo.groupCode}');
      
      return groupInfo;
    } catch (e, stackTrace) {
      print('🔴 [SUPERADMIN_GROUP] Error regenerating code: $e');
      print('🔴 [SUPERADMIN_GROUP] Error type: ${e.runtimeType}');
      print('🔴 [SUPERADMIN_GROUP] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Remove an admin member from the SuperAdmin group
  /// 
  /// [adminId] - ID of the admin to remove
  /// 
  /// Requires Bearer token authentication (automatically added by interceptor)
  /// 
  /// Throws ApiException on failure
  Future<void> removeMember(int adminId) async {
    try {
      print('🔵 [SUPERADMIN_GROUP] Removing member: $adminId...');
      
      final response = await _apiClient.delete('/superadmin/group/members/$adminId');

      print('🟢 [SUPERADMIN_GROUP] Remove member response received');
      print('🟢 [SUPERADMIN_GROUP] Response status: ${response.statusCode}');
      
      // Check if response is successful (200 or 204)
      if (response.statusCode != 200 && response.statusCode != 204) {
        print('❌ [SUPERADMIN_GROUP] Non-success status code: ${response.statusCode}');
        throw Exception('Failed to remove member: ${response.statusCode}');
      }
      
      print('✅ [SUPERADMIN_GROUP] Successfully removed member: $adminId');
    } catch (e, stackTrace) {
      print('🔴 [SUPERADMIN_GROUP] Error removing member: $e');
      print('🔴 [SUPERADMIN_GROUP] Error type: ${e.runtimeType}');
      print('🔴 [SUPERADMIN_GROUP] Stack trace: $stackTrace');
      rethrow;
    }
  }
}

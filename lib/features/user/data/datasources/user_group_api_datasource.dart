import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../../admin_group/data/models/group_info_dto.dart';

/// API data source for user group operations
/// 
/// This data source handles all HTTP requests related to user group management,
/// specifically for regular users (not admins) to join and view group information.
abstract class UserGroupApiDataSource {
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
  /// Requirements: 3.1, 3.2, 3.3
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
  /// Requirements: 3.6, 3.7, 3.8
  Future<GroupInfoDto> getUserGroupInfo();
}

/// Implementation of [UserGroupApiDataSource] using HTTP API
class UserGroupApiDataSourceImpl implements UserGroupApiDataSource {
  final ApiClient apiClient;

  UserGroupApiDataSourceImpl({
    required this.apiClient,
  });

  @override
  Future<GroupInfoDto> joinGroup(String groupCode) async {
    try {
      print('[UserGroupApiDataSource] Joining group with code: $groupCode');
      
      final response = await apiClient.post(
        '/user/join-group',
        body: {'group_code': groupCode},
      );

      print('[UserGroupApiDataSource] Response status: ${response.statusCode}');
      print('[UserGroupApiDataSource] Response data: ${response.data}');

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
          final message = data?['message'] as String? ?? 'Already in a group';
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
      print('[UserGroupApiDataSource] Error: $e');
      throw ApiException(
        message: 'Failed to join group: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<GroupInfoDto> getUserGroupInfo() async {
    try {
      print('[UserGroupApiDataSource] Fetching user group info');
      
      final response = await apiClient.get('/user/group-info');

      print('[UserGroupApiDataSource] Response status: ${response.statusCode}');
      print('[UserGroupApiDataSource] Response data: ${response.data}');

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
      print('[UserGroupApiDataSource] Error: $e');
      throw ApiException(
        message: 'Failed to fetch group information: ${e.toString()}',
        statusCode: 500,
      );
    }
  }
}

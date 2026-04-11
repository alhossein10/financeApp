import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../models/organization_dto.dart';
import '../models/department_dto.dart';

/// Organizations API Datasource
/// 
/// Handles API calls for public organization and department endpoints.
/// These are PUBLIC endpoints that do NOT require Bearer token authentication.
/// 
/// Endpoints:
/// - GET /api/v1/organizations - Get all organizations
/// - GET /api/v1/organizations/{id}/departments - Get departments for an organization
class OrganizationsApiDatasource {
  final ApiClient _apiClient;

  OrganizationsApiDatasource({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  /// Get all organizations
  /// 
  /// This is a PUBLIC endpoint - no authentication required.
  /// The BearerTokenInterceptor will automatically skip token injection for this endpoint.
  /// 
  /// Returns a list of all available organizations.
  /// 
  /// Throws [ApiException] if the request fails.
  Future<List<OrganizationDto>> getOrganizations() async {
    try {
      print('[OrganizationsApiDatasource] 🌐 Fetching organizations (public endpoint)...');

      final response = await _apiClient.get('/organizations');

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle both direct array and wrapped response
        List<dynamic> organizationsJson;
        if (data is List) {
          organizationsJson = data;
        } else if (data is Map<String, dynamic> && data.containsKey('data')) {
          organizationsJson = data['data'] as List;
        } else {
          throw ApiException(
            message: 'Invalid response format',
            statusCode: response.statusCode,
          );
        }

        final organizations = organizationsJson
            .map((json) => OrganizationDto.fromJson(json as Map<String, dynamic>))
            .toList();

        print('[OrganizationsApiDatasource] ✅ Fetched ${organizations.length} organizations');
        return organizations;
      } else {
        throw ApiException(
          message: 'Failed to fetch organizations',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      print('[OrganizationsApiDatasource] 🔴 Error fetching organizations: $e');
      print('[OrganizationsApiDatasource] Stack trace: $stackTrace');
      throw ApiException(
        message: 'Failed to fetch organizations: $e',
        statusCode: null,
      );
    }
  }

  /// Get departments for a specific organization
  /// 
  /// This is a PUBLIC endpoint - no authentication required.
  /// The BearerTokenInterceptor will automatically skip token injection for this endpoint.
  /// 
  /// Parameters:
  /// - [organizationId]: The ID of the organization
  /// 
  /// Returns a list of departments for the specified organization.
  /// 
  /// Throws [ApiException] if the request fails.
  Future<List<DepartmentDto>> getDepartments(int organizationId) async {
    try {
      print('[OrganizationsApiDatasource] 🌐 Fetching departments for organization $organizationId (public endpoint)...');

      final response = await _apiClient.get('/organizations/$organizationId/departments');

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle both direct array and wrapped response
        List<dynamic> departmentsJson;
        if (data is List) {
          departmentsJson = data;
        } else if (data is Map<String, dynamic> && data.containsKey('data')) {
          departmentsJson = data['data'] as List;
        } else {
          throw ApiException(
            message: 'Invalid response format',
            statusCode: response.statusCode,
          );
        }

        final departments = departmentsJson
            .map((json) => DepartmentDto.fromJson(json as Map<String, dynamic>))
            .toList();

        print('[OrganizationsApiDatasource] ✅ Fetched ${departments.length} departments');
        return departments;
      } else if (response.statusCode == 404) {
        // Organization not found or has no departments
        print('[OrganizationsApiDatasource] ⚠️ Organization $organizationId not found or has no departments');
        return [];
      } else {
        throw ApiException(
          message: 'Failed to fetch departments',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      print('[OrganizationsApiDatasource] 🔴 Error fetching departments: $e');
      print('[OrganizationsApiDatasource] Stack trace: $stackTrace');
      throw ApiException(
        message: 'Failed to fetch departments: $e',
        statusCode: null,
      );
    }
  }
}

import 'dart:async';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/laravel_auth_service.dart';
import '../../domain/entities/organization.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/registration_result.dart';
import '../models/organization_model.dart';
import '../models/department_model.dart';

/// Abstract interface for authentication API data source
abstract class AuthApiDataSource {
  /// Login with email and password
  Future<User> login(String email, String password);

  /// Register a new user
  Future<RegistrationResult> register({
    required String name,
    required String email,
    required String password,
    String? organizationName,
    String? departmentName,
    String? groupCode, // Admin group code (for users joining admin groups)
    String? superAdminGroupCode, // SuperAdmin group code (for admins joining SuperAdmin groups)
    String role = 'user',
  });

  /// Logout current user
  Future<void> logout();

  /// Get current authenticated user
  Future<User> getCurrentUser();

  /// Refresh authentication token
  Future<User> refreshToken();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();

  /// Validate token with server
  Future<bool> validateToken();

  /// Request password reset
  Future<void> forgotPassword(String email);

  /// Reset password with token
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
  });

  /// Change password for authenticated user
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Get list of all organizations
  Future<List<Organization>> getOrganizations();

  /// Get list of departments for a specific organization
  Future<List<Department>> getDepartments(int organizationId);
}

/// Implementation of AuthApiDataSource using Laravel backend
class AuthApiDataSourceImpl implements AuthApiDataSource {
  final LaravelAuthService _authService;
  final ApiClient _apiClient;

  AuthApiDataSourceImpl({
    required LaravelAuthService authService,
    required ApiClient apiClient,
  })  : _authService = authService,
        _apiClient = apiClient;

  @override
  Future<User> login(String email, String password) async {
    return await _authService.login(email: email, password: password);
  }

  @override
  Future<RegistrationResult> register({
    required String name,
    required String email,
    required String password,
    String? organizationName,
    String? departmentName,
    String? groupCode,
    String? superAdminGroupCode,
    String role = 'user',
  }) async {
    return await _authService.register(
      name: name,
      email: email,
      password: password,
      organizationName: organizationName,
      departmentName: departmentName,
      groupCode: groupCode,
      superAdminGroupCode: superAdminGroupCode,
      role: role,
    );
  }

  @override
  Future<void> logout() async {
    await _authService.logout();
  }

  @override
  Future<User> getCurrentUser() async {
    return await _authService.getCurrentUser();
  }

  @override
  Future<User> refreshToken() async {
    return await _authService.refreshToken();
  }

  @override
  Future<bool> isAuthenticated() async {
    return await _authService.isAuthenticated();
  }

  @override
  Future<bool> validateToken() async {
    return await _authService.validateToken();
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _authService.forgotPassword(email);
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
  }) async {
    await _authService.resetPassword(
      token: token,
      email: email,
      password: password,
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<List<Organization>> getOrganizations() async {
    try {
      print('🔵 [AUTH_API] Fetching organizations...');
      
      final response = await _apiClient.get('/organizations').timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ [AUTH_API] Request timed out after 10 seconds');
          throw TimeoutException('Organizations request timed out');
        },
      );

      print('🔵 [AUTH_API] Response received!');
      print('🔵 [AUTH_API] Response status: ${response.statusCode}');
      print('🔵 [AUTH_API] Response data: ${response.data}');

      // Check if response is successful
      if (response.statusCode != 200) {
        print('❌ [AUTH_API] Non-200 status code: ${response.statusCode}');
        throw Exception('Failed to load organizations: ${response.statusCode}');
      }

      // Parse response data
      final data = response.data;
      print('🔵 [AUTH_API] Data type: ${data.runtimeType}');
      
      if (data is! Map<String, dynamic>) {
        print('❌ [AUTH_API] Invalid response format - expected Map, got ${data.runtimeType}');
        throw Exception('Invalid response format');
      }

      // Extract organizations list from response
      if (!data.containsKey('data')) {
        print('❌ [AUTH_API] Response missing "data" key. Keys: ${data.keys}');
        throw Exception('Response missing data key');
      }
      
      final organizationsList = data['data'] as List<dynamic>;
      
      print('✅ [AUTH_API] Successfully loaded ${organizationsList.length} organizations');
      
      return organizationsList
          .map((json) => OrganizationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      // If API endpoint fails, return default organization as fallback
      print('⚠️ [AUTH_API] Organizations endpoint error: $e');
      print('⚠️ [AUTH_API] Error type: ${e.runtimeType}');
      print('⚠️ [AUTH_API] Stack trace: $stackTrace');
      print('⚠️ [AUTH_API] Returning default organization as fallback');
      return [
        const Organization(
          id: 1,
          name: 'Default Organization',
        ),
      ];
    }
  }

  @override
  Future<List<Department>> getDepartments(int organizationId) async {
    try {
      print('🔵 [AUTH_API] Fetching departments for organization $organizationId...');
      
      final response = await _apiClient.get('/organizations/$organizationId/departments').timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ [AUTH_API] Request timed out after 10 seconds');
          throw TimeoutException('Departments request timed out');
        },
      );

      print('🔵 [AUTH_API] Response received!');
      print('🔵 [AUTH_API] Response status: ${response.statusCode}');
      print('🔵 [AUTH_API] Response data: ${response.data}');

      // Check if response is successful
      if (response.statusCode != 200) {
        print('❌ [AUTH_API] Non-200 status code: ${response.statusCode}');
        throw Exception('Failed to load departments: ${response.statusCode}');
      }

      // Parse response data
      final data = response.data;
      print('🔵 [AUTH_API] Data type: ${data.runtimeType}');
      
      if (data is! Map<String, dynamic>) {
        print('❌ [AUTH_API] Invalid response format - expected Map, got ${data.runtimeType}');
        throw Exception('Invalid response format');
      }

      // Extract departments list from response
      if (!data.containsKey('data')) {
        print('❌ [AUTH_API] Response missing "data" key. Keys: ${data.keys}');
        throw Exception('Response missing data key');
      }
      
      final departmentsList = data['data'] as List<dynamic>;
      
      print('✅ [AUTH_API] Successfully loaded ${departmentsList.length} departments');
      
      return departmentsList
          .map((json) => DepartmentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      // If API endpoint fails, return default department as fallback
      print('⚠️ [AUTH_API] Departments endpoint error: $e');
      print('⚠️ [AUTH_API] Error type: ${e.runtimeType}');
      print('⚠️ [AUTH_API] Stack trace: $stackTrace');
      print('⚠️ [AUTH_API] Returning default department as fallback');
      return [
        Department(
          id: 1,
          name: 'Default Department',
          organizationId: organizationId,
        ),
      ];
    }
  }
}

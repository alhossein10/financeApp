import 'dart:async';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/services/laravel_auth_service.dart';
import '../../../../core/utils/secure_logger.dart';
import '../../domain/entities/organization.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/registration_result.dart';
import '../models/organization_model.dart';
import '../models/department_model.dart';

const String _logTag = 'AUTH_API';

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
    String? adminGroupName, // SuperAdmin group name (for SuperAdmin registration)
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
    String? adminGroupName,
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
      adminGroupName: adminGroupName,
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
      SecureLogger.request(_logTag, 'GET', '/organizations');

      final response = await _apiClient.get('/organizations').timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Organizations request timed out');
        },
      );

      SecureLogger.response(_logTag, response.statusCode);

      // Check if response is successful
      if (response.statusCode != 200) {
        throw ApiException(
          statusCode: response.statusCode ?? 0,
          message: 'Failed to load organizations',
        );
      }

      // Parse response data
      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw ApiException(
          statusCode: 0,
          message: 'Invalid response format',
        );
      }

      // Extract organizations list from response
      if (!data.containsKey('data')) {
        throw ApiException(
          statusCode: 0,
          message: 'Response missing data key',
        );
      }

      final organizationsList = data['data'] as List<dynamic>;

      SecureLogger.success(_logTag, 'Loaded ${organizationsList.length} organizations');

      return organizationsList
          .map((json) => OrganizationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      SecureLogger.error(_logTag, 'Organizations request timed out');
      // Return empty list on timeout - let UI handle empty state
      return [];
    } on ApiException {
      rethrow;
    } catch (e) {
      SecureLogger.error(_logTag, 'Failed to load organizations', e);
      // Return empty list on error - do NOT return fake data
      return [];
    }
  }

  @override
  Future<List<Department>> getDepartments(int organizationId) async {
    try {
      SecureLogger.request(_logTag, 'GET', '/organizations/$organizationId/departments');

      final response = await _apiClient.get('/organizations/$organizationId/departments').timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Departments request timed out');
        },
      );

      SecureLogger.response(_logTag, response.statusCode);

      // Check if response is successful
      if (response.statusCode != 200) {
        throw ApiException(
          statusCode: response.statusCode ?? 0,
          message: 'Failed to load departments',
        );
      }

      // Parse response data
      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw ApiException(
          statusCode: 0,
          message: 'Invalid response format',
        );
      }

      // Extract departments list from response
      if (!data.containsKey('data')) {
        throw ApiException(
          statusCode: 0,
          message: 'Response missing data key',
        );
      }

      final departmentsList = data['data'] as List<dynamic>;

      SecureLogger.success(_logTag, 'Loaded ${departmentsList.length} departments');

      return departmentsList
          .map((json) => DepartmentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      SecureLogger.error(_logTag, 'Departments request timed out');
      // Return empty list on timeout - let UI handle empty state
      return [];
    } on ApiException {
      rethrow;
    } catch (e) {
      SecureLogger.error(_logTag, 'Failed to load departments', e);
      // Return empty list on error - do NOT return fake data
      return [];
    }
  }
}

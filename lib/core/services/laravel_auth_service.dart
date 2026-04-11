import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/models/auth_response.dart';
import '../api/models/user_dto.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/domain/entities/registration_result.dart';
import '../utils/secure_logger.dart';
import 'token_manager.dart';

const String _logTag = 'AUTH';

/// Laravel Authentication Service
/// Handles user authentication with Laravel backend
class LaravelAuthService {
  final ApiClient _apiClient;
  final TokenManager _tokenManager;

  LaravelAuthService({
    required ApiClient apiClient,
    required TokenManager tokenManager,
  })  : _apiClient = apiClient,
        _tokenManager = tokenManager;

  /// Register a new user
  ///
  /// For SuperAdmin registration:
  /// - Creates a new SuperAdmin group automatically
  /// - Returns SuperAdmin group code in RegistrationResult for sharing with admins
  /// - adminGroupName is required for SuperAdmin
  /// - organizationName and departmentName are optional
  ///
  /// For admin registration:
  /// - Creates a new admin group automatically (or joins SuperAdmin group if superAdminGroupCode provided)
  /// - Returns group code in RegistrationResult for sharing with team
  /// - organizationName and departmentName are optional
  ///
  /// For user registration:
  /// - Requires valid groupCode to join admin's group
  /// - organizationName and departmentName are optional
  ///
  /// Returns RegistrationResult with user and optional group code on success
  ///
  /// Throws ApiException with specific messages for:
  /// - Invalid group code: "The selected group code is invalid"
  /// - Missing group code: "The group code field is required"
  /// - Already in group: "You are already in a group"
  /// - Admin joining group: "Admins cannot join other groups"
  /// - Other validation errors: Detailed field-specific messages
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
    try {
      SecureLogger.debug(_logTag, 'Starting registration with role: $role');

      // Build request body
      final Map<String, dynamic> requestBody = {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'role': role,
      };

      // Add optional fields if provided
      if (organizationName != null && organizationName.isNotEmpty) {
        requestBody['organization_name'] = organizationName;
      }

      if (departmentName != null && departmentName.isNotEmpty) {
        requestBody['department_name'] = departmentName;
      }

      // Add SuperAdmin group name for SuperAdmin registration
      if (adminGroupName != null && adminGroupName.isNotEmpty) {
        requestBody['admin_group_name'] = adminGroupName;
      }

      if (groupCode != null && groupCode.isNotEmpty) {
        requestBody['group_code'] = groupCode;
      }

      // Add SuperAdmin group code for Admin registration
      if (superAdminGroupCode != null && superAdminGroupCode.isNotEmpty) {
        requestBody['super_admin_group_code'] = superAdminGroupCode;
      }

      SecureLogger.request(_logTag, 'POST', '/auth/register');

      final response = await _apiClient.post(
        '/auth/register',
        body: requestBody,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          SecureLogger.error(_logTag, 'Request timed out after 15 seconds');
          throw ApiException(
            statusCode: 0,
            message: 'Connection timeout. Please check:\n'
                '1. Server is running\n'
                '2. Network connection is available\n'
                '3. Firewall is not blocking',
          );
        },
      );

      SecureLogger.response(_logTag, response.statusCode);

      // Check if response is successful
      if (response.statusCode == 422) {
        SecureLogger.error(_logTag, 'Validation error (422)');

        // Extract error messages with special handling for group code errors
        String errorMessage = 'Validation failed';
        Map<String, dynamic>? validationErrors;

        if (response.data is Map && response.data['errors'] != null) {
          validationErrors = response.data['errors'] as Map<String, dynamic>;

          // Check for specific group code validation errors
          if (validationErrors.containsKey('group_code')) {
            final groupCodeErrors = validationErrors['group_code'];
            if (groupCodeErrors is List && groupCodeErrors.isNotEmpty) {
              final firstError = groupCodeErrors.first.toString();

              // Map backend error messages to user-friendly messages
              if (firstError.contains('invalid') || firstError.contains('does not exist')) {
                errorMessage = 'The selected group code is invalid';
              } else if (firstError.contains('required')) {
                errorMessage = 'The group code field is required';
              } else if (firstError.contains('already in a group')) {
                errorMessage = 'You are already in a group';
              } else if (firstError.contains('cannot join')) {
                errorMessage = 'Admins cannot join other groups';
              } else {
                errorMessage = firstError;
              }
            }
          } else {
            // General validation errors
            errorMessage = validationErrors.values
                .map((e) => e is List ? e.join(', ') : e.toString())
                .join('\n');
          }
        } else if (response.data is Map && response.data['message'] != null) {
          errorMessage = response.data['message'].toString();

          // Check message for group code specific errors
          if (errorMessage.contains('group code') && errorMessage.contains('invalid')) {
            errorMessage = 'The selected group code is invalid';
          } else if (errorMessage.contains('already in a group')) {
            errorMessage = 'You are already in a group';
          } else if (errorMessage.contains('Admins cannot join')) {
            errorMessage = 'Admins cannot join other groups';
          }
        }

        throw ApiException(
          statusCode: 422,
          message: errorMessage,
          errors: validationErrors,
        );
      } else if (response.statusCode == 400) {
        SecureLogger.error(_logTag, 'Bad request (400)');

        String errorMessage = 'Invalid request';
        if (response.data is Map && response.data['message'] != null) {
          errorMessage = response.data['message'].toString();

          // Check for group code specific errors in message
          if (errorMessage.contains('already in a group')) {
            errorMessage = 'You are already in a group';
          } else if (errorMessage.contains('Admins cannot join')) {
            errorMessage = 'Admins cannot join other groups';
          }
        }

        throw ApiException(
          statusCode: 400,
          message: errorMessage,
        );
      } else if (response.statusCode != 200 && response.statusCode != 201) {
        SecureLogger.error(_logTag, 'Unexpected status code: ${response.statusCode}');
        throw ApiException(
          statusCode: response.statusCode ?? 0,
          message: 'Registration failed with status ${response.statusCode}',
        );
      }

      final authResponse = AuthResponse.fromJson(response.data);

      SecureLogger.debug(_logTag, 'Storing registration token...');

      // Store token in secure storage
      await _tokenManager.saveToken(
        token: authResponse.token,
        tokenType: authResponse.tokenType,
        expiresAt: authResponse.expiresAt,
      );

      // Set token in API client for subsequent requests
      _apiClient.setAuthToken(authResponse.token);

      SecureLogger.success(_logTag, 'Registration completed for role: ${authResponse.user.role}');

      return RegistrationResult(
        user: authResponse.user.toEntity(),
        groupCode: authResponse.groupCode,
        superAdminGroupCode: authResponse.superAdminGroupCode,
        adminGroupName: authResponse.adminGroupName,
      );
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      SecureLogger.error(_logTag, 'DioException during registration', e);
      throw ApiException.fromDioException(e);
    } catch (e, stackTrace) {
      SecureLogger.error(_logTag, 'Unexpected error during registration', e, stackTrace);
      throw ApiException(
        statusCode: 0,
        message: 'Registration failed: ${e.toString()}',
      );
    }
  }

  /// Login with email and password
  /// Returns User entity on success
  /// Throws ApiException on failure
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      SecureLogger.debug(_logTag, 'Starting login...');
      SecureLogger.request(_logTag, 'POST', '/auth/login');

      final response = await _apiClient.post(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      SecureLogger.response(_logTag, response.statusCode);

      final authResponse = AuthResponse.fromJson(response.data);

      // Store token in secure storage
      await _tokenManager.saveToken(
        token: authResponse.token,
        tokenType: authResponse.tokenType,
        expiresAt: authResponse.expiresAt,
      );

      // Set token in API client for subsequent requests
      _apiClient.setAuthToken(authResponse.token);

      SecureLogger.success(_logTag, 'Login completed');

      return authResponse.user.toEntity();
    } on DioException catch (e) {
      SecureLogger.error(_logTag, 'DioException during login', e);
      throw ApiException.fromDioException(e);
    } catch (e, stackTrace) {
      SecureLogger.error(_logTag, 'Unexpected error during login', e, stackTrace);
      throw ApiException(
        statusCode: 0,
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  // Flag to prevent multiple simultaneous logout calls
  bool _isLoggingOut = false;

  /// Logout current user
  /// Revokes token on server and clears local storage
  /// Always clears local tokens even if server call fails
  Future<void> logout() async {
    // Prevent multiple simultaneous logout calls
    if (_isLoggingOut) {
      SecureLogger.warning(_logTag, 'Logout already in progress, skipping duplicate call');
      return;
    }

    _isLoggingOut = true;
    SecureLogger.debug(_logTag, 'Starting logout process...');

    try {
      SecureLogger.request(_logTag, 'POST', '/auth/logout');
      await _apiClient.post('/auth/logout');
      SecureLogger.success(_logTag, 'Logout API call successful');
    } on DioException catch (e) {
      SecureLogger.warning(_logTag, 'Logout API call failed: ${e.response?.statusCode}');
    } catch (e) {
      SecureLogger.warning(_logTag, 'Logout error occurred');
    } finally {
      // Always clear local tokens regardless of API call result
      await _tokenManager.clearTokens();
      _apiClient.clearAuthToken();

      SecureLogger.success(_logTag, 'Logout complete - all tokens cleared');
      _isLoggingOut = false;
    }
  }

  /// Get current authenticated user from server
  /// Returns User entity on success
  /// Throws ApiException on failure
  Future<User> getCurrentUser() async {
    try {
      SecureLogger.debug(_logTag, 'Fetching current user...');

      // Ensure token is set in API client before making request
      final token = await _tokenManager.getToken();
      if (token != null) {
        _apiClient.setAuthToken(token);
      } else {
        SecureLogger.warning(_logTag, 'No token available');
        throw ApiException(
          statusCode: 401,
          message: 'No authentication token available',
        );
      }

      SecureLogger.request(_logTag, 'GET', '/auth/me');
      final response = await _apiClient.get('/auth/me');

      SecureLogger.response(_logTag, response.statusCode);

      final userDto = UserDto.fromJson(response.data);
      final user = userDto.toEntity();

      SecureLogger.success(_logTag, 'User fetched, role: ${user.role}');
      return user;
    } on DioException catch (e) {
      SecureLogger.error(_logTag, 'DioException getting current user', e);

      // If 401, clear tokens as they're invalid
      if (e.response?.statusCode == 401) {
        SecureLogger.warning(_logTag, 'Token invalid, clearing...');
        await _tokenManager.clearTokens();
        _apiClient.clearAuthToken();
      }

      throw ApiException.fromDioException(e);
    } catch (e, stackTrace) {
      SecureLogger.error(_logTag, 'Error getting current user', e, stackTrace);
      throw ApiException(
        statusCode: 0,
        message: 'Failed to get current user: ${e.toString()}',
      );
    }
  }

  /// Refresh authentication token
  /// Returns new User entity with updated token
  /// Throws ApiException on failure
  Future<User> refreshToken() async {
    try {
      SecureLogger.debug(_logTag, 'Refreshing authentication token...');
      SecureLogger.request(_logTag, 'POST', '/auth/refresh');

      final response = await _apiClient.post('/auth/refresh');
      final authResponse = AuthResponse.fromJson(response.data);

      // Store new token in TokenManager
      await _tokenManager.saveToken(
        token: authResponse.token,
        tokenType: authResponse.tokenType,
        expiresAt: authResponse.expiresAt,
      );

      // Update token on ApiClient
      _apiClient.setAuthToken(authResponse.token);
      SecureLogger.success(_logTag, 'Token refreshed successfully');

      return authResponse.user.toEntity();
    } on DioException catch (e) {
      SecureLogger.error(_logTag, 'Token refresh failed', e);
      await _tokenManager.clearTokens();
      _apiClient.clearAuthToken();
      throw ApiException.fromDioException(e);
    } catch (e) {
      SecureLogger.error(_logTag, 'Token refresh failed', e);
      await _tokenManager.clearTokens();
      _apiClient.clearAuthToken();
      throw ApiException(
        statusCode: 0,
        message: 'Token refresh failed: ${e.toString()}',
      );
    }
  }

  /// Check if user is authenticated
  /// Validates token existence and expiration locally
  /// For server validation, use validateToken()
  Future<bool> isAuthenticated() async {
    return await _tokenManager.isTokenValid();
  }

  /// Get stored authentication token
  Future<String?> getToken() async {
    return await _tokenManager.getToken();
  }

  /// Validate stored token by checking with server
  /// Returns true if token is valid on server
  /// Automatically refreshes token if needed
  Future<bool> validateToken() async {
    try {
      // Check if token needs refresh before validation
      if (await _tokenManager.needsRefresh()) {
        SecureLogger.debug(_logTag, 'Token needs refresh, attempting refresh...');
        try {
          await refreshToken();
          SecureLogger.success(_logTag, 'Token refreshed successfully');
        } catch (e) {
          SecureLogger.error(_logTag, 'Token refresh failed', e);
          // Continue with validation even if refresh fails
        }
      }

      // Validate with server
      await getCurrentUser();

      // Mark token as validated
      await _tokenManager.markAsValidated();

      SecureLogger.success(_logTag, 'Token validated successfully');
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        SecureLogger.warning(_logTag, 'Token validation failed: Unauthorized');
        await _tokenManager.clearTokens();
        _apiClient.clearAuthToken();
      }
      return false;
    } catch (e) {
      SecureLogger.error(_logTag, 'Token validation error', e);
      return false;
    }
  }

  /// Check if token needs refresh
  /// Returns true if token will expire soon or is expired
  Future<bool> needsTokenRefresh() async {
    return await _tokenManager.needsRefresh();
  }

  /// Automatically refresh token if needed
  /// Returns true if token was refreshed or doesn't need refresh
  /// Returns false if refresh failed
  Future<bool> autoRefreshToken() async {
    try {
      if (!await needsTokenRefresh()) {
        SecureLogger.debug(_logTag, 'Token doesn\'t need refresh');
        return true;
      }

      SecureLogger.debug(_logTag, 'Auto-refreshing token...');
      await refreshToken();
      SecureLogger.success(_logTag, 'Token auto-refreshed successfully');
      return true;
    } catch (e) {
      SecureLogger.error(_logTag, 'Auto-refresh failed', e);
      return false;
    }
  }

  /// Forgot password - request password reset
  /// Sends reset link to user's email
  Future<void> forgotPassword(String email) async {
    try {
      SecureLogger.request(_logTag, 'POST', '/auth/forgot-password');
      await _apiClient.post(
        '/auth/forgot-password',
        body: {'email': email},
      );
      SecureLogger.success(_logTag, 'Password reset email sent');
    } on DioException catch (e) {
      SecureLogger.error(_logTag, 'Password reset request failed', e);
      throw ApiException.fromDioException(e);
    } catch (e) {
      SecureLogger.error(_logTag, 'Password reset request failed', e);
      throw ApiException(
        statusCode: 0,
        message: 'Password reset request failed: ${e.toString()}',
      );
    }
  }

  /// Reset password with token
  /// Uses token from email link to set new password
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
  }) async {
    try {
      SecureLogger.request(_logTag, 'POST', '/auth/reset-password');
      await _apiClient.post(
        '/auth/reset-password',
        body: {
          'token': token,
          'email': email,
          'password': password,
          'password_confirmation': password,
        },
      );
      SecureLogger.success(_logTag, 'Password reset successful');
    } on DioException catch (e) {
      SecureLogger.error(_logTag, 'Password reset failed', e);
      throw ApiException.fromDioException(e);
    } catch (e) {
      SecureLogger.error(_logTag, 'Password reset failed', e);
      throw ApiException(
        statusCode: 0,
        message: 'Password reset failed: ${e.toString()}',
      );
    }
  }

  /// Change password for authenticated user
  /// Requires current password for verification
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      SecureLogger.request(_logTag, 'PUT', '/profile/password');
      await _apiClient.put(
        '/profile/password',
        body: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPassword,
        },
      );
      SecureLogger.success(_logTag, 'Password changed successfully');
    } on DioException catch (e) {
      SecureLogger.error(_logTag, 'Password change failed', e);
      throw ApiException.fromDioException(e);
    } catch (e) {
      SecureLogger.error(_logTag, 'Password change failed', e);
      throw ApiException(
        statusCode: 0,
        message: 'Password change failed: ${e.toString()}',
      );
    }
  }
}

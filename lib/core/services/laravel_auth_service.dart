import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/models/auth_response.dart';
import '../api/models/user_dto.dart';
import '../config/api_config.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/domain/entities/registration_result.dart';
import 'token_manager.dart';

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
  /// For admin registration:
  /// - Creates a new admin group automatically
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
    String? groupCode, // Admin group code (for users joining admin groups)
    String? superAdminGroupCode, // SuperAdmin group code (for admins joining SuperAdmin groups)
    String role = 'user',
  }) async {
    try {
      print('🔵 [AUTH] Starting registration for: $email with role: $role');
      print('🔵 [AUTH] Organization Name: $organizationName, Department Name: $departmentName');
      print('🔵 [AUTH] Group Code: $groupCode');
      print('🔵 [AUTH] SuperAdmin Group Code: $superAdminGroupCode');
      print('🔵 [AUTH] API URL: ${ApiConfig.apiUrl}/auth/register');
      
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
      
      if (groupCode != null && groupCode.isNotEmpty) {
        requestBody['group_code'] = groupCode;
      }
      
      // Add SuperAdmin group code for Admin registration
      if (superAdminGroupCode != null && superAdminGroupCode.isNotEmpty) {
        requestBody['super_admin_group_code'] = superAdminGroupCode;
      }
      
      print('🔵 [AUTH] Request body: $requestBody');
      
      final response = await _apiClient.post(
        '/auth/register',
        body: requestBody,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('🔴 [AUTH] Request timed out after 15 seconds');
          throw ApiException(
            statusCode: 0,
            message: 'Connection timeout. Please check:\n'
                '1. Laravel is running\n'
                '2. IP address is correct\n'
                '3. Firewall is not blocking',
          );
        },
      );

      print('🟢 [AUTH] Registration response received: ${response.statusCode}');
      print('🟢 [AUTH] Response data type: ${response.data.runtimeType}');
      print('🟢 [AUTH] Response data: ${response.data}');

      // Check if response is successful
      if (response.statusCode == 422) {
        // Validation error - show the actual errors
        print('🔴 [AUTH] Validation error (422)');
        print('🔴 [AUTH] Validation errors: ${response.data}');
        
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
        // Bad request - may contain group code specific errors
        print('🔴 [AUTH] Bad request (400)');
        print('🔴 [AUTH] Response data: ${response.data}');
        
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
        print('🔴 [AUTH] Unexpected status code: ${response.statusCode}');
        throw ApiException(
          statusCode: response.statusCode ?? 0,
          message: 'Registration failed with status ${response.statusCode}',
        );
      }

      final authResponse = AuthResponse.fromJson(response.data);
      
      print('🔵 [AUTH] Storing registration token...');
      
      // Store token in secure storage
      await _tokenManager.saveToken(
        token: authResponse.token,
        tokenType: authResponse.tokenType,
        expiresAt: authResponse.expiresAt,
      );

      // Set token in API client for subsequent requests
      // This ensures all future API calls include the Bearer token
      _apiClient.setAuthToken(authResponse.token);

      print('✅ [AUTH] Registration token stored and set in API client');
      print('🔑 [AUTH] Token type: ${authResponse.tokenType}');
      print('👤 [AUTH] User role: ${authResponse.user.role}');
      if (authResponse.expiresAt != null) {
        print('⏰ [AUTH] Token expires at: ${authResponse.expiresAt}');
      }
      if (authResponse.superAdminGroupCode != null) {
        print('🔑 [AUTH] SuperAdmin group code generated: ${authResponse.superAdminGroupCode}');
        print('📋 [AUTH] SuperAdmin group code should be displayed for sharing with admins');
      } else if (authResponse.groupCode != null) {
        print('🔑 [AUTH] Admin group code generated: ${authResponse.groupCode}');
        print('📋 [AUTH] Group code should be displayed to admin for sharing');
      } else if (role == 'admin') {
        print('⚠️ [AUTH] Warning: Admin registered but no group code in response');
      } else if (role == 'superAdmin') {
        print('⚠️ [AUTH] Warning: SuperAdmin registered but no group code in response');
      } else if (groupCode != null) {
        print('✅ [AUTH] User successfully joined group with code: $groupCode');
      }
      
      return RegistrationResult(
        user: authResponse.user.toEntity(),
        groupCode: authResponse.groupCode,
        superAdminGroupCode: authResponse.superAdminGroupCode,
        adminGroupName: authResponse.adminGroupName,
      );
    } on ApiException {
      // Re-throw ApiException as-is (from our custom error handling above)
      rethrow;
    } on DioException catch (e) {
      print('🔴 [AUTH] DioException during registration');
      print('🔴 [AUTH] Type: ${e.type}');
      print('🔴 [AUTH] Message: ${e.message}');
      print('🔴 [AUTH] Response: ${e.response?.data}');
      print('🔴 [AUTH] Status code: ${e.response?.statusCode}');
      throw ApiException.fromDioException(e);
    } catch (e, stackTrace) {
      print('🔴 [AUTH] Unexpected error during registration: $e');
      print('🔴 [AUTH] Error type: ${e.runtimeType}');
      print('🔴 [AUTH] Stack trace: $stackTrace');
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
      print('🔵 [AUTH] Starting login for: $email');
      
      final response = await _apiClient.post(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      print('🟢 [AUTH] Login response received: ${response.statusCode}');
      print('🟢 [AUTH] Response data: ${response.data}');

      final authResponse = AuthResponse.fromJson(response.data);
      
      print('🔵 [AUTH] Storing login token...');
      
      // Store token in secure storage
      await _tokenManager.saveToken(
        token: authResponse.token,
        tokenType: authResponse.tokenType,
        expiresAt: authResponse.expiresAt,
      );

      // Set token in API client for subsequent requests
      // This ensures all future API calls include the Bearer token
      _apiClient.setAuthToken(authResponse.token);

      print('✅ [AUTH] Login token stored and set in API client');
      print('🔑 [AUTH] Token type: ${authResponse.tokenType}');
      if (authResponse.expiresAt != null) {
        print('⏰ [AUTH] Token expires at: ${authResponse.expiresAt}');
      }
      
      return authResponse.user.toEntity();
    } on DioException catch (e) {
      print('🔴 [AUTH] DioException during login: ${e.message}');
      print('🔴 [AUTH] Response: ${e.response?.data}');
      print('🔴 [AUTH] Status code: ${e.response?.statusCode}');
      throw ApiException.fromDioException(e);
    } catch (e, stackTrace) {
      print('🔴 [AUTH] Unexpected error during login: $e');
      print('🔴 [AUTH] Stack trace: $stackTrace');
      throw ApiException(
        statusCode: 0,
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  /// Logout current user
  /// Revokes token on server and clears local storage
  /// Always clears local tokens even if server call fails
  Future<void> logout() async {
    print('🔵 [AUTH] Starting logout process...');
    
    try {
      // Try to revoke token on server
      print('🔵 [AUTH] Calling logout API...');
      await _apiClient.post('/auth/logout');
      print('✅ [AUTH] Logout API call successful');
    } on DioException catch (e) {
      // Log error but continue with local logout
      print('⚠️ [AUTH] Logout API call failed: ${e.message}');
      print('⚠️ [AUTH] Status code: ${e.response?.statusCode}');
    } catch (e) {
      print('⚠️ [AUTH] Logout error: ${e.toString()}');
    } finally {
      // Always clear local tokens regardless of API call result
      print('🔵 [AUTH] Clearing local tokens...');
      await _tokenManager.clearTokens();
      
      // Clear token from API client
      _apiClient.clearAuthToken();
      
      print('✅ [AUTH] Logout complete - all tokens cleared');
    }
  }

  /// Get current authenticated user from server
  /// Returns User entity on success
  /// Throws ApiException on failure
  Future<User> getCurrentUser() async {
    try {
      print('🔵 [AUTH] Fetching current user from /auth/me...');
      
      // Ensure token is set in API client before making request
      final token = await _tokenManager.getToken();
      if (token != null) {
        _apiClient.setAuthToken(token);
        print('🔵 [AUTH] Token restored to API client');
      } else {
        print('⚠️ [AUTH] No token available');
        throw ApiException(
          statusCode: 401,
          message: 'No authentication token available',
        );
      }
      
      final response = await _apiClient.get('/auth/me');
      
      print('🟢 [AUTH] Response status: ${response.statusCode}');
      print('🟢 [AUTH] Response data type: ${response.data.runtimeType}');
      print('🟢 [AUTH] Response data: ${response.data}');
      
      final userDto = UserDto.fromJson(response.data);
      final user = userDto.toEntity();
      
      print('✅ [AUTH] User fetched: ${user.email}, role: ${user.role}');
      return user;
    } on DioException catch (e) {
      print('🔴 [AUTH] DioException getting current user: ${e.message}');
      print('🔴 [AUTH] Response: ${e.response?.data}');
      
      // If 401, clear tokens as they're invalid
      if (e.response?.statusCode == 401) {
        print('🔴 [AUTH] Token invalid, clearing...');
        await _tokenManager.clearTokens();
        _apiClient.clearAuthToken();
      }
      
      throw ApiException.fromDioException(e);
    } catch (e, stackTrace) {
      print('🔴 [AUTH] Error getting current user: $e');
      print('🔴 [AUTH] Stack trace: $stackTrace');
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
      print('🔄 [AUTH] Refreshing authentication token...');
      final response = await _apiClient.post('/auth/refresh');
      final authResponse = AuthResponse.fromJson(response.data);
      
      print('🔄 [AUTH] Token refresh response received');
      print('🔄 [AUTH] New token: ${authResponse.token.substring(0, 20)}...');
      
      // Store new token in TokenManager
      await _tokenManager.saveToken(
        token: authResponse.token,
        tokenType: authResponse.tokenType,
        expiresAt: authResponse.expiresAt,
      );
      
      // IMPORTANT: Update token on ApiClient so it's used for subsequent requests
      _apiClient.setAuthToken(authResponse.token);
      print('✅ [AUTH] Token saved to TokenManager and set on ApiClient');

      return authResponse.user.toEntity();
    } on DioException catch (e) {
      print('🔴 [AUTH] Token refresh failed with DioException: ${e.message}');
      // If refresh fails, clear tokens
      await _tokenManager.clearTokens();
      _apiClient.clearAuthToken();
      throw ApiException.fromDioException(e);
    } catch (e) {
      print('🔴 [AUTH] Token refresh failed: $e');
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
        print('🔄 [AUTH] Token needs refresh, attempting refresh...');
        try {
          await refreshToken();
          print('✅ [AUTH] Token refreshed successfully');
        } catch (e) {
          print('🔴 [AUTH] Token refresh failed: $e');
          // Continue with validation even if refresh fails
          // Server will return 401 if token is invalid
        }
      }
      
      // Validate with server
      await getCurrentUser();
      
      // Mark token as validated
      await _tokenManager.markAsValidated();
      
      print('✅ [AUTH] Token validated successfully');
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        print('🔴 [AUTH] Token validation failed: Unauthorized');
        // Clear invalid token
        await _tokenManager.clearTokens();
        _apiClient.clearAuthToken();
      }
      return false;
    } catch (e) {
      print('🔴 [AUTH] Token validation error: $e');
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
        print('✅ [AUTH] Token doesn\'t need refresh');
        return true;
      }
      
      print('🔄 [AUTH] Auto-refreshing token...');
      await refreshToken();
      print('✅ [AUTH] Token auto-refreshed successfully');
      return true;
    } catch (e) {
      print('🔴 [AUTH] Auto-refresh failed: $e');
      return false;
    }
  }

  /// Forgot password - request password reset
  /// Sends reset link to user's email
  Future<void> forgotPassword(String email) async {
    try {
      await _apiClient.post(
        '/auth/forgot-password',
        body: {'email': email},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
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
      await _apiClient.post(
        '/auth/reset-password',
        body: {
          'token': token,
          'email': email,
          'password': password,
          'password_confirmation': password,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
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
      await _apiClient.put(
        '/profile/password',
        body: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPassword,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Password change failed: ${e.toString()}',
      );
    }
  }
}

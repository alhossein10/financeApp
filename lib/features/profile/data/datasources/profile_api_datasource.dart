import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/services/token_manager.dart';
import '../../../auth/domain/entities/user.dart';
import '../models/user_statistics_model.dart';
import '../models/profile_dto.dart';

/// Abstract interface for profile API data source
abstract class ProfileApiDataSource {
  /// Get user profile from API
  Future<User> getProfile();

  /// Update user profile
  Future<User> updateProfile({
    String? name,
    String? email,
  });

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Delete user account
  Future<void> deleteAccount();

  /// Get user statistics from API
  Future<UserStatisticsModel> getUserStatistics();

  /// Update profile image
  Future<User> updateProfileImage(String imageUrl);

  /// Upload profile photo
  Future<Map<String, String>> uploadProfilePhoto(String filePath);

  /// Delete profile photo
  Future<void> deleteProfilePhoto();
}

/// Implementation of ProfileApiDataSource using Laravel backend
class ProfileApiDataSourceImpl implements ProfileApiDataSource {
  final ApiClient _apiClient;
  final TokenManager _tokenManager;

  ProfileApiDataSourceImpl({
    required ApiClient apiClient,
    required TokenManager tokenManager,
  })  : _apiClient = apiClient,
        _tokenManager = tokenManager;

  @override
  Future<User> getProfile() async {
    try {
      final response = await _apiClient.get('/profile');

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final profileDto = ProfileDto.fromJson(data);
        return profileDto.toEntity();
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: 'Failed to get profile',
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 500,
        message: 'Failed to get profile: ${e.toString()}',
      );
    }
  }

  @override
  Future<User> updateProfile({
    String? name,
    String? email,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;

      final response = await _apiClient.put('/profile', body: body);

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final profileDto = ProfileDto.fromJson(data);
        return profileDto.toEntity();
      } else if (response.statusCode == 422) {
        // Validation error
        final errors = response.data['errors'] as Map<String, dynamic>?;
        final errorMessage = errors?.values.first.first ?? 'Validation failed';
        throw ApiException(
          statusCode: 422,
          message: errorMessage,
          errors: errors,
        );
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: 'Failed to update profile',
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 500,
        message: 'Failed to update profile: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.put(
        '/profile/password',
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPassword,
        },
      );

      if (response.statusCode != 200) {
        if (response.statusCode == 422) {
          // Validation error
          final errors = response.data['errors'] as Map<String, dynamic>?;
          final errorMessage = errors?.values.first.first ?? 'Validation failed';
          throw ApiException(
            statusCode: 422,
            message: errorMessage,
            errors: errors,
          );
        } else if (response.statusCode == 401) {
          throw ApiException(
            statusCode: 401,
            message: 'Current password is incorrect',
          );
        } else {
          throw ApiException(
            statusCode: response.statusCode ?? 500,
            message: 'Failed to change password',
          );
        }
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 500,
        message: 'Failed to change password: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final response = await _apiClient.delete('/profile');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: 'Failed to delete account',
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 500,
        message: 'Failed to delete account: ${e.toString()}',
      );
    }
  }

  @override
  Future<UserStatisticsModel> getUserStatistics() async {
    try {
      final response = await _apiClient.get('/profile/statistics');

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return UserStatisticsModel.fromApiJson(data);
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: 'Failed to get user statistics',
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 500,
        message: 'Failed to get user statistics: ${e.toString()}',
      );
    }
  }

  @override
  Future<User> updateProfileImage(String imageUrl) async {
    try {
      final response = await _apiClient.put(
        '/profile/image',
        body: {'profile_image_url': imageUrl},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final profileDto = ProfileDto.fromJson(data);
        return profileDto.toEntity();
      } else if (response.statusCode == 422) {
        // Validation error
        final errors = response.data['errors'] as Map<String, dynamic>?;
        final errorMessage = errors?.values.first.first ?? 'Validation failed';
        throw ApiException(
          statusCode: 422,
          message: errorMessage,
          errors: errors,
        );
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: 'Failed to update profile image',
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 500,
        message: 'Failed to update profile image: ${e.toString()}',
      );
    }
  }

  @override
  Future<Map<String, String>> uploadProfilePhoto(String filePath) async {
    try {
      final token = await _tokenManager.getToken();
      if (token == null) {
        throw ApiException(
          statusCode: 401,
          message: 'No authentication token available',
        );
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw ApiException(
          statusCode: 400,
          message: 'File does not exist',
        );
      }

      // Get base URL from ApiConfig
      final baseUrl = _apiClient.getAuthToken() != null 
          ? ApiConfig.apiUrl 
          : ApiConfig.apiUrl;
      final uri = Uri.parse('$baseUrl/profile/photo');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      
      request.files.add(
        await http.MultipartFile.fromPath('photo', filePath),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final photoData = data['data'] as Map<String, dynamic>;
        
        return {
          'profile_photo_path': photoData['profile_photo_path'] as String,
          'profile_photo_url': photoData['profile_photo_url'] as String,
        };
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final errors = data['errors'] as Map<String, dynamic>?;
        final errorMessage = errors?.values.first.first ?? 'Validation failed';
        throw ApiException(
          statusCode: 422,
          message: errorMessage,
          errors: errors,
        );
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Failed to upload profile photo',
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 500,
        message: 'Failed to upload profile photo: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteProfilePhoto() async {
    try {
      final response = await _apiClient.delete('/profile/photo');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: 'Failed to delete profile photo',
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 500,
        message: 'Failed to delete profile photo: ${e.toString()}',
      );
    }
  }
}


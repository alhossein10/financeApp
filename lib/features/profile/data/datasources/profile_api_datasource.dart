import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
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
}

/// Implementation of ProfileApiDataSource using Laravel backend
class ProfileApiDataSourceImpl implements ProfileApiDataSource {
  final ApiClient _apiClient;

  ProfileApiDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

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
}

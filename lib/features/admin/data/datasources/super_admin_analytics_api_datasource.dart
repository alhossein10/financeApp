import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../models/super_admin_analytics_dto.dart';

/// API Data Source for SuperAdmin Analytics
abstract class SuperAdminAnalyticsApiDataSource {
  /// Get analytics for SuperAdmin
  /// [period] must be '15days', 'month', or 'all'
  Future<SuperAdminAnalyticsDto> getAnalytics(String period);
}

class SuperAdminAnalyticsApiDataSourceImpl implements SuperAdminAnalyticsApiDataSource {
  final ApiClient apiClient;

  SuperAdminAnalyticsApiDataSourceImpl({required this.apiClient});

  @override
  Future<SuperAdminAnalyticsDto> getAnalytics(String period) async {
    try {
      // Validate period
      if (!['15days', 'month', 'all'].contains(period)) {
        throw ApiException(
          statusCode: 400,
          message: 'Invalid period. Must be "15days", "month", or "all"',
        );
      }

      final response = await apiClient.get('/super-admin/analytics?period=$period');

      if (response.statusCode == 200) {
        return SuperAdminAnalyticsDto.fromJson(response.data);
      } else if (response.statusCode == 403) {
        throw ApiException(
          statusCode: 403,
          message: 'Access denied. SuperAdmin privileges required.',
        );
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: response.data['message'] ?? 'Failed to get analytics',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }
}


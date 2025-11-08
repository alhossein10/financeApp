import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../models/admin_stats_dto.dart';
import '../models/user_activity_dto.dart';
import '../models/expense_summary_dto.dart';
import '../models/analytics_dto.dart';

/// API data source for admin dashboard operations
/// Handles all admin-related API communication with Laravel backend
/// 
/// NOTE: All endpoints automatically filter data by admin_group_id based on the
/// authenticated user's token. Admins only see data from members of their admin group.
abstract class AdminApiDataSource {
  /// Get dashboard statistics for the admin's group
  /// Returns statistics calculated only from group members' data
  /// Throws [ApiException] if operation fails
  Future<AdminStatsDto> getStats();

  /// Get user activity list for the admin's group
  /// Returns activity only for members of the admin's group
  /// Throws [ApiException] if operation fails
  Future<List<UserActivityDto>> getUserActivity();

  /// Get expense summaries for the admin's group
  /// Returns summaries calculated only from group members' expenses
  /// Throws [ApiException] if operation fails
  Future<ExpenseSummaryDto> getExpenseSummaries();

  /// Get analytics data for a date range for the admin's group
  /// Returns analytics calculated only from group members' data
  /// Throws [ApiException] if operation fails
  Future<AnalyticsDto> getAnalytics({
    required DateTime dateFrom,
    required DateTime dateTo,
  });
}

/// Implementation of AdminApiDataSource
class AdminApiDataSourceImpl implements AdminApiDataSource {
  final ApiClient apiClient;

  AdminApiDataSourceImpl({required this.apiClient});

  @override
  Future<AdminStatsDto> getStats() async {
    try {
      final response = await apiClient.get('/admin/dashboard/stats');

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return AdminStatsDto.fromJson(data);
      } else if (response.statusCode == 403) {
        throw ApiException(
          statusCode: 403,
          message: 'Access denied. Admin privileges required.',
        );
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: response.data['message'] ?? 'Failed to get dashboard stats',
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

  @override
  Future<List<UserActivityDto>> getUserActivity() async {
    try {
      final response = await apiClient.get('/admin/dashboard/users');

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>;
        return data
            .map((json) => UserActivityDto.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 403) {
        throw ApiException(
          statusCode: 403,
          message: 'Access denied. Admin privileges required.',
        );
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: response.data['message'] ?? 'Failed to get user activity',
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

  @override
  Future<ExpenseSummaryDto> getExpenseSummaries() async {
    try {
      final response = await apiClient.get('/admin/dashboard/expenses');

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return ExpenseSummaryDto.fromJson(data);
      } else if (response.statusCode == 403) {
        throw ApiException(
          statusCode: 403,
          message: 'Access denied. Admin privileges required.',
        );
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: response.data['message'] ?? 'Failed to get expense summaries',
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

  @override
  Future<AnalyticsDto> getAnalytics({
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    try {
      final response = await apiClient.get(
        '/admin/dashboard/analytics',
        queryParams: {
          'date_from': DateFormatter.toApiDate(dateFrom),
          'date_to': DateFormatter.toApiDate(dateTo),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return AnalyticsDto.fromJson(data);
      } else if (response.statusCode == 403) {
        throw ApiException(
          statusCode: 403,
          message: 'Access denied. Admin privileges required.',
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

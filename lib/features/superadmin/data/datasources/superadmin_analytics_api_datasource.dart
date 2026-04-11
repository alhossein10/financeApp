import '../../../../core/api/api_client.dart';
import '../models/superadmin_analytics_dto.dart';

/// API datasource for SuperAdmin analytics
/// Handles fetching aggregated analytics for all admin groups
class SuperAdminAnalyticsApiDatasource {
  final ApiClient _apiClient;

  SuperAdminAnalyticsApiDatasource({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  /// Get analytics for all admin groups
  /// 
  /// [period] can be '15days', 'month', or 'all'
  /// 
  /// Returns [SuperAdminAnalyticsDto] with aggregated statistics
  /// 
  /// Requires Bearer token authentication (automatically added by interceptor)
  /// 
  /// Throws ApiException on failure
  Future<SuperAdminAnalyticsDto> getAnalytics({
    required String period,
  }) async {
    try {
      print('🔵 [SUPERADMIN_ANALYTICS] Fetching analytics for period: $period');
      
      // Validate period parameter
      if (!['15days', 'month', 'all'].contains(period)) {
        throw ArgumentError('Invalid period: $period. Must be one of: 15days, month, all');
      }
      
      final response = await _apiClient.get(
        '/super-admin/analytics',
        queryParams: {'period': period},
      );

      print('🟢 [SUPERADMIN_ANALYTICS] Analytics response received');
      print('🟢 [SUPERADMIN_ANALYTICS] Response status: ${response.statusCode}');
      print('🟢 [SUPERADMIN_ANALYTICS] Response data type: ${response.data.runtimeType}');
      
      // Check if response is successful
      if (response.statusCode != 200) {
        print('❌ [SUPERADMIN_ANALYTICS] Non-200 status code: ${response.statusCode}');
        print('❌ [SUPERADMIN_ANALYTICS] Response data: ${response.data}');
        throw Exception('Failed to load analytics: ${response.statusCode}');
      }

      // Parse response data
      final data = response.data;
      
      if (data is! Map<String, dynamic>) {
        print('❌ [SUPERADMIN_ANALYTICS] Invalid response format - expected Map, got ${data.runtimeType}');
        print('❌ [SUPERADMIN_ANALYTICS] Response data: $data');
        throw Exception('Invalid response format');
      }

      print('🟡 [SUPERADMIN_ANALYTICS] Response data keys: ${data.keys.toList()}');
      
      // Check for success field
      if (data.containsKey('success') && data['success'] != true) {
        print('❌ [SUPERADMIN_ANALYTICS] API returned success=false');
        throw Exception('API returned error: ${data['message'] ?? 'Unknown error'}');
      }

      // Extract analytics from response
      // Handle both direct data and nested 'data' wrapper
      final analyticsData = data.containsKey('data') 
          ? data['data'] as Map<String, dynamic>
          : data;
      
      print('🟡 [SUPERADMIN_ANALYTICS] Analytics data keys: ${analyticsData.keys.toList()}');
      
      if (analyticsData.containsKey('admin_groups')) {
        final adminGroups = analyticsData['admin_groups'];
        print('🟡 [SUPERADMIN_ANALYTICS] Admin groups type: ${adminGroups.runtimeType}');
        if (adminGroups is List) {
          print('🟡 [SUPERADMIN_ANALYTICS] Admin groups count: ${adminGroups.length}');
          if (adminGroups.isNotEmpty) {
            print('🟡 [SUPERADMIN_ANALYTICS] First admin group keys: ${(adminGroups[0] as Map<String, dynamic>).keys.toList()}');
          }
        }
      } else {
        print('⚠️ [SUPERADMIN_ANALYTICS] No admin_groups key found in response');
      }
      
      final analytics = SuperAdminAnalyticsDto.fromJson(analyticsData);
      
      print('✅ [SUPERADMIN_ANALYTICS] Successfully loaded analytics for ${analytics.adminGroups.length} admin groups');
      
      return analytics;
    } catch (e, stackTrace) {
      print('🔴 [SUPERADMIN_ANALYTICS] Error fetching analytics: $e');
      print('🔴 [SUPERADMIN_ANALYTICS] Error type: ${e.runtimeType}');
      print('🔴 [SUPERADMIN_ANALYTICS] Stack trace: $stackTrace');
      rethrow;
    }
  }
}

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../models/audit_log_dto.dart';

/// API data source for audit log operations
/// Handles all audit log API communication with Laravel backend
abstract class AuditLogApiDataSource {
  /// Get audit logs with pagination and filtering
  /// Throws [ApiException] if operation fails
  Future<AuditLogListDto> getAuditLogs({
    int page = 1,
    int perPage = 15,
    int? userId,
    String? action,
    String? resourceType,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get audit log details by ID
  /// Throws [ApiException] if operation fails
  Future<AuditLogDto> getAuditLogDetails(int id);
}

/// Implementation of AuditLogApiDataSource
class AuditLogApiDataSourceImpl implements AuditLogApiDataSource {
  final ApiClient apiClient;

  AuditLogApiDataSourceImpl({required this.apiClient});

  @override
  Future<AuditLogListDto> getAuditLogs({
    int page = 1,
    int perPage = 15,
    int? userId,
    String? action,
    String? resourceType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (userId != null) queryParams['user_id'] = userId;
      if (action != null) queryParams['action'] = action;
      if (resourceType != null) queryParams['entity_type'] = resourceType;
      if (startDate != null) {
        queryParams['start_date'] = DateFormatter.toApiDate(startDate);
      }
      if (endDate != null) {
        queryParams['end_date'] = DateFormatter.toApiDate(endDate);
      }

      final response = await apiClient.get(
        '/audit-logs',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        return AuditLogListDto.fromJson(response.data as Map<String, dynamic>);
      } else if (response.statusCode == 403) {
        throw ApiException(
          statusCode: 403,
          message: 'Access denied. Admin privileges required.',
        );
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: response.data['message'] ?? 'Failed to get audit logs',
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
  Future<AuditLogDto> getAuditLogDetails(int id) async {
    try {
      final response = await apiClient.get('/audit-logs/$id');

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return AuditLogDto.fromJson(data);
      } else if (response.statusCode == 403) {
        throw ApiException(
          statusCode: 403,
          message: 'Access denied. Admin privileges required.',
        );
      } else if (response.statusCode == 404) {
        throw ApiException(
          statusCode: 404,
          message: 'Audit log not found',
        );
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: response.data['message'] ?? 'Failed to get audit log details',
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

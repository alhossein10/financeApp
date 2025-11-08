import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/sync_request_dto.dart';
import '../models/sync_response_dto.dart';
import '../models/sync_changes_dto.dart';
import '../utils/api_logger.dart';
import '../utils/date_formatter.dart';

/// Service for batch synchronization of records
/// Implements Laravel API specification for /sync/batch and /sync/changes
class BatchSyncService {
  final ApiClient apiClient;
  static const int maxBatchSize = 50;

  BatchSyncService({required this.apiClient});

  /// Batch sync multiple records according to Laravel API specification
  /// POST /sync/batch
  /// 
  /// Request format:
  /// {
  ///   "last_sync": "2024-10-23T09:00:00.000000Z",
  ///   "data": {
  ///     "expenses": [...],
  ///     "incoming": [...],
  ///     "transfers": [...]
  ///   }
  /// }
  Future<SyncResponseDto> batchSync({
    required DateTime lastSync,
    required SyncDataDto data,
  }) async {
    try {
      ApiLogger.logInfo('Starting batch sync with ${data.totalCount} records');

      final request = SyncRequestDto(
        lastSync: lastSync,
        data: data,
      );

      final response = await apiClient.post(
        '/sync/batch',
        body: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final syncResponse = SyncResponseDto.fromJson(response.data['data']);
        
        ApiLogger.logInfo(
          'Batch sync completed: ${syncResponse.totalCreated} created, '
          '${syncResponse.totalConflicts} conflicts',
        );

        return syncResponse;
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: response.data['message'] ?? 'Batch sync failed',
          errors: response.data['errors'],
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      ApiLogger.logInfo('Batch sync error: $e');
      throw ApiException(
        statusCode: 500,
        message: 'Batch sync failed: $e',
      );
    }
  }

  /// Get changes since last sync according to Laravel API specification
  /// GET /sync/changes?since=2024-10-23T09:00:00.000000Z
  /// 
  /// Response format:
  /// {
  ///   "timestamp": "2024-10-23T10:00:00.000000Z",
  ///   "changes": {
  ///     "expenses": {
  ///       "created": [...],
  ///       "updated": [...],
  ///       "deleted": [123, 456]
  ///     },
  ///     "incoming": {...},
  ///     "transfers": {...}
  ///   }
  /// }
  Future<SyncChangesDto> getChanges({required DateTime since}) async {
    try {
      ApiLogger.logInfo('Fetching changes since ${since.toIso8601String()}');

      final response = await apiClient.get(
        '/sync/changes',
        queryParams: {
          'since': DateFormatter.toApiTimestamp(since),
        },
      );

      if (response.statusCode == 200) {
        final changes = SyncChangesDto.fromJson(response.data['data']);
        
        ApiLogger.logInfo(
          'Retrieved ${changes.changes.totalChanges} changes',
        );

        return changes;
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: response.data['message'] ?? 'Failed to get changes',
          errors: response.data['errors'],
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      ApiLogger.logInfo('Get changes error: $e');
      throw ApiException(
        statusCode: 500,
        message: 'Failed to get changes: $e',
      );
    }
  }

  /// Sync offline changes with the server
  /// This is a convenience method that handles the common use case
  Future<SyncResponseDto> syncOfflineChanges({
    required DateTime lastSync,
    List<Map<String, dynamic>> expenses = const [],
    List<Map<String, dynamic>> incoming = const [],
    List<Map<String, dynamic>> transfers = const [],
  }) async {
    final data = SyncDataDto(
      expenses: expenses,
      incoming: incoming,
      transfers: transfers,
    );

    return await batchSync(lastSync: lastSync, data: data);
  }

  /// Pull changes from server and return them
  /// This is useful for syncing down server changes to local database
  Future<SyncChangesDto> pullChanges({required DateTime since}) async {
    return await getChanges(since: since);
  }

  /// Full sync: push local changes and pull server changes
  Future<FullSyncResult> fullSync({
    required DateTime lastSync,
    required SyncDataDto localChanges,
  }) async {
    try {
      // Push local changes
      final pushResponse = await batchSync(
        lastSync: lastSync,
        data: localChanges,
      );

      // Pull server changes
      final pullResponse = await getChanges(since: lastSync);

      return FullSyncResult(
        pushResponse: pushResponse,
        pullResponse: pullResponse,
        success: true,
      );
    } catch (e) {
      ApiLogger.logInfo('Full sync error: $e');
      return FullSyncResult(
        pushResponse: null,
        pullResponse: null,
        success: false,
        error: e.toString(),
      );
    }
  }
}

/// Result of a full sync operation (push + pull)
class FullSyncResult {
  final SyncResponseDto? pushResponse;
  final SyncChangesDto? pullResponse;
  final bool success;
  final String? error;

  FullSyncResult({
    this.pushResponse,
    this.pullResponse,
    required this.success,
    this.error,
  });

  bool get hasConflicts => pushResponse?.hasConflicts ?? false;
  int get totalConflicts => pushResponse?.totalConflicts ?? 0;
  int get totalCreated => pushResponse?.totalCreated ?? 0;
  int get totalChangesFromServer => pullResponse?.changes.totalChanges ?? 0;
}

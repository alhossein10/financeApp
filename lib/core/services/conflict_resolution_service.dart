import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/conflict_resolution.dart';
import '../utils/api_logger.dart';

/// Service for handling sync conflicts
class ConflictResolutionService {
  final ApiClient apiClient;

  ConflictResolutionService({required this.apiClient});

  /// Resolve a conflict using the specified strategy
  Future<ConflictResolutionResponse> resolveConflict(
    SyncConflict conflict,
    ConflictStrategy strategy, {
    Map<String, dynamic>? manualResolution,
  }) async {
    try {
      final request = ConflictResolutionRequest(
        type: conflict.type,
        serverId: conflict.serverId,
        localId: conflict.localId,
        strategy: strategy,
        resolvedData: strategy == ConflictStrategy.manual 
            ? manualResolution 
            : null,
      );

      final response = await apiClient.post(
        '/api/v1/sync/resolve',
        body: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ConflictResolutionResponse.fromJson(response.data);
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: response.data['message'] ?? 'Conflict resolution failed',
          errors: response.data['errors'],
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: 'Conflict resolution failed: $e',
      );
    }
  }

  /// Resolve conflict using server wins strategy
  Future<ConflictResolutionResponse> resolveWithServerWins(
    SyncConflict conflict,
  ) async {
    ApiLogger.logInfo('Resolving conflict with server_wins strategy');
    return await resolveConflict(conflict, ConflictStrategy.serverWins);
  }

  /// Resolve conflict using client wins strategy
  Future<ConflictResolutionResponse> resolveWithClientWins(
    SyncConflict conflict,
  ) async {
    ApiLogger.logInfo('Resolving conflict with client_wins strategy');
    return await resolveConflict(conflict, ConflictStrategy.clientWins);
  }

  /// Resolve conflict with manual resolution
  Future<ConflictResolutionResponse> resolveManually(
    SyncConflict conflict,
    Map<String, dynamic> resolvedData,
  ) async {
    ApiLogger.logInfo('Resolving conflict manually');
    return await resolveConflict(
      conflict,
      ConflictStrategy.manual,
      manualResolution: resolvedData,
    );
  }

  /// Resolve multiple conflicts
  Future<List<ConflictResolutionResponse>> resolveMultipleConflicts(
    List<SyncConflict> conflicts,
    ConflictStrategy defaultStrategy,
  ) async {
    final responses = <ConflictResolutionResponse>[];

    for (final conflict in conflicts) {
      try {
        final response = await resolveConflict(conflict, defaultStrategy);
        responses.add(response);
      } catch (e) {
        ApiLogger.logError(e);
        // Add failed response
        responses.add(ConflictResolutionResponse(
          success: false,
          type: conflict.type,
          id: conflict.serverId,
          localId: conflict.localId,
          data: {},
          error: e.toString(),
        ));
      }
    }

    return responses;
  }

  /// Auto-resolve conflicts based on timestamp
  Future<ConflictResolutionResponse> autoResolveByTimestamp(
    SyncConflict conflict,
  ) async {
    // Use server wins if server is newer, otherwise client wins
    final strategy = conflict.serverIsNewer 
        ? ConflictStrategy.serverWins 
        : ConflictStrategy.clientWins;

    ApiLogger.logInfo(
      'Auto-resolving conflict by timestamp: ${strategy.name}',
    );

    return await resolveConflict(conflict, strategy);
  }

  /// Get list of conflicts from server
  Future<List<SyncConflict>> getConflicts() async {
    try {
      final response = await apiClient.get('/api/v1/sync/conflicts');

      if (response.statusCode == 200) {
        final conflictsJson = response.data['conflicts'] as List;
        return conflictsJson
            .map((c) => SyncConflict.fromJson(c as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: response.data['message'] ?? 'Failed to get conflicts',
          errors: response.data['errors'],
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: 'Failed to get conflicts: $e',
      );
    }
  }
}

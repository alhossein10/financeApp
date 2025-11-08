/// Conflict resolution strategy
enum ConflictStrategy {
  serverWins,
  clientWins,
  manual,
}

/// Model for a sync conflict
class SyncConflict {
  final String type; // 'expense', 'transfer', 'incoming'
  final int? serverId;
  final String? localId;
  final Map<String, dynamic> serverData;
  final Map<String, dynamic> clientData;
  final DateTime serverUpdatedAt;
  final DateTime clientUpdatedAt;

  SyncConflict({
    required this.type,
    this.serverId,
    this.localId,
    required this.serverData,
    required this.clientData,
    required this.serverUpdatedAt,
    required this.clientUpdatedAt,
  });

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      type: json['type'] as String,
      serverId: json['server_id'] as int?,
      localId: json['local_id'] as String?,
      serverData: json['server_data'] as Map<String, dynamic>,
      clientData: json['client_data'] as Map<String, dynamic>,
      serverUpdatedAt: DateTime.parse(json['server_updated_at'] as String),
      clientUpdatedAt: DateTime.parse(json['client_updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (serverId != null) 'server_id': serverId,
      if (localId != null) 'local_id': localId,
      'server_data': serverData,
      'client_data': clientData,
      'server_updated_at': serverUpdatedAt.toIso8601String(),
      'client_updated_at': clientUpdatedAt.toIso8601String(),
    };
  }

  bool get serverIsNewer => serverUpdatedAt.isAfter(clientUpdatedAt);
  bool get clientIsNewer => clientUpdatedAt.isAfter(serverUpdatedAt);
}

/// Model for conflict resolution request
class ConflictResolutionRequest {
  final String type;
  final int? serverId;
  final String? localId;
  final ConflictStrategy strategy;
  final Map<String, dynamic>? resolvedData;

  ConflictResolutionRequest({
    required this.type,
    this.serverId,
    this.localId,
    required this.strategy,
    this.resolvedData,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (serverId != null) 'server_id': serverId,
      if (localId != null) 'local_id': localId,
      'strategy': strategy.name,
      if (resolvedData != null) 'resolved_data': resolvedData,
    };
  }
}

/// Model for conflict resolution response
class ConflictResolutionResponse {
  final bool success;
  final String type;
  final int? id;
  final String? localId;
  final Map<String, dynamic> data;
  final String? error;

  ConflictResolutionResponse({
    required this.success,
    required this.type,
    this.id,
    this.localId,
    required this.data,
    this.error,
  });

  factory ConflictResolutionResponse.fromJson(Map<String, dynamic> json) {
    return ConflictResolutionResponse(
      success: json['success'] as bool,
      type: json['type'] as String,
      id: json['id'] as int?,
      localId: json['local_id'] as String?,
      data: json['data'] as Map<String, dynamic>,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'type': type,
      if (id != null) 'id': id,
      if (localId != null) 'local_id': localId,
      'data': data,
      if (error != null) 'error': error,
    };
  }
}

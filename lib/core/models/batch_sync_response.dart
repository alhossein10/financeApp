/// Model for individual result in batch sync response
class BatchSyncResult {
  final String? localId;
  final int? id;
  final String type;
  final String action;
  final bool success;
  final String? error;
  final Map<String, dynamic>? data;

  BatchSyncResult({
    this.localId,
    this.id,
    required this.type,
    required this.action,
    required this.success,
    this.error,
    this.data,
  });

  factory BatchSyncResult.fromJson(Map<String, dynamic> json) {
    return BatchSyncResult(
      localId: json['local_id'] as String?,
      id: json['id'] as int?,
      type: json['type'] as String,
      action: json['action'] as String,
      success: json['success'] as bool,
      error: json['error'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      'type': type,
      'action': action,
      'success': success,
      if (error != null) 'error': error,
      if (data != null) 'data': data,
    };
  }
}

/// Model for batch sync response
class BatchSyncResponse {
  final List<BatchSyncResult> results;
  final int successCount;
  final int failureCount;

  BatchSyncResponse({
    required this.results,
    required this.successCount,
    required this.failureCount,
  });

  factory BatchSyncResponse.fromJson(Map<String, dynamic> json) {
    return BatchSyncResponse(
      results: (json['results'] as List)
          .map((r) => BatchSyncResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      successCount: json['success_count'] as int,
      failureCount: json['failure_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'results': results.map((r) => r.toJson()).toList(),
      'success_count': successCount,
      'failure_count': failureCount,
    };
  }

  bool get hasFailures => failureCount > 0;
  bool get allSucceeded => failureCount == 0;
}

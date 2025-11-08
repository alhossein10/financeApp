import 'package:equatable/equatable.dart';

/// Queue operation types
enum QueueOperation {
  create,
  update,
  delete;

  String toJson() => name;

  static QueueOperation fromJson(String json) {
    return QueueOperation.values.firstWhere((e) => e.name == json);
  }
}

/// Queue item status
enum QueueStatus {
  pending,
  processing,
  failed;

  String toJson() => name;

  static QueueStatus fromJson(String json) {
    return QueueStatus.values.firstWhere((e) => e.name == json);
  }
}

/// Queue item for offline operations
class QueueItem extends Equatable {
  final String id; // UUID
  final QueueOperation operation;
  final String resourceType; // 'expense', 'transfer', 'incoming'
  final Map<String, dynamic> data;
  final int retryCount;
  final DateTime createdAt;
  final QueueStatus status;
  final String? errorMessage;

  const QueueItem({
    required this.id,
    required this.operation,
    required this.resourceType,
    required this.data,
    this.retryCount = 0,
    required this.createdAt,
    this.status = QueueStatus.pending,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        id,
        operation,
        resourceType,
        data,
        retryCount,
        createdAt,
        status,
        errorMessage,
      ];

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation': operation.toJson(),
      'resourceType': resourceType,
      'data': data,
      'retryCount': retryCount,
      'createdAt': createdAt.toIso8601String(),
      'status': status.toJson(),
      'errorMessage': errorMessage,
    };
  }

  /// Create from JSON
  factory QueueItem.fromJson(Map<String, dynamic> json) {
    return QueueItem(
      id: json['id'] as String,
      operation: QueueOperation.fromJson(json['operation'] as String),
      resourceType: json['resourceType'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      retryCount: json['retryCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: QueueStatus.fromJson(json['status'] as String),
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// Copy with updated fields
  QueueItem copyWith({
    String? id,
    QueueOperation? operation,
    String? resourceType,
    Map<String, dynamic>? data,
    int? retryCount,
    DateTime? createdAt,
    QueueStatus? status,
    String? errorMessage,
  }) {
    return QueueItem(
      id: id ?? this.id,
      operation: operation ?? this.operation,
      resourceType: resourceType ?? this.resourceType,
      data: data ?? this.data,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Check if item should be retried
  bool get shouldRetry => retryCount < 3 && status == QueueStatus.failed;

  /// Get next retry delay using exponential backoff
  Duration get nextRetryDelay {
    // Exponential backoff: 2^retryCount seconds
    final seconds = 2 << retryCount; // 2, 4, 8 seconds
    return Duration(seconds: seconds);
  }
}

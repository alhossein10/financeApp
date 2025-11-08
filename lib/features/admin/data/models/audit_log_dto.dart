import '../../../../core/utils/date_formatter.dart';

/// Data Transfer Object for audit log information
/// Maps between API JSON and domain entities
class AuditLogDto {
  final int id;
  final int userId;
  final String? userName; // Only in detail view
  final String action;
  final String entityType; // Changed from resourceType
  final int entityId; // Changed from resourceId
  final String ipAddress;
  final String userAgent;
  final Map<String, dynamic>? changes; // Only in detail view
  final DateTime createdAt;

  const AuditLogDto({
    required this.id,
    required this.userId,
    this.userName, // Optional, only in detail view
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.ipAddress,
    required this.userAgent,
    this.changes, // Optional, only in detail view
    required this.createdAt,
  });

  /// Create AuditLogDto from JSON response
  factory AuditLogDto.fromJson(Map<String, dynamic> json) {
    return AuditLogDto(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String?, // Optional, only in detail view
      action: json['action'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as int,
      ipAddress: json['ip_address'] as String,
      userAgent: json['user_agent'] as String,
      changes: json['changes'] as Map<String, dynamic>?, // Optional, only in detail view
      createdAt: DateFormatter.fromApiTimestamp(json['created_at'] as String),
    );
  }

  /// Convert AuditLogDto to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      if (userName != null) 'user_name': userName,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      if (changes != null) 'changes': changes,
      'created_at': DateFormatter.toApiTimestamp(createdAt),
    };
  }

  @override
  String toString() {
    return 'AuditLogDto(id: $id, userId: $userId, action: $action, '
        'entityType: $entityType, entityId: $entityId, createdAt: $createdAt)';
  }
}

/// Data Transfer Object for paginated audit log list
class AuditLogListDto {
  final List<AuditLogDto> logs;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  const AuditLogListDto({
    required this.logs,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });

  /// Create AuditLogListDto from JSON response
  factory AuditLogListDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final logs = data
        .map((item) => AuditLogDto.fromJson(item as Map<String, dynamic>))
        .toList();

    final meta = json['meta'] as Map<String, dynamic>? ?? json;

    return AuditLogListDto(
      logs: logs,
      currentPage: (meta['current_page'] as int?) ?? 1,
      lastPage: (meta['last_page'] as int?) ?? 1,
      total: (meta['total'] as int?) ?? 0,
      perPage: (meta['per_page'] as int?) ?? 15,
    );
  }

  /// Convert AuditLogListDto to JSON
  Map<String, dynamic> toJson() {
    return {
      'data': logs.map((log) => log.toJson()).toList(),
      'meta': {
        'current_page': currentPage,
        'last_page': lastPage,
        'total': total,
        'per_page': perPage,
      },
    };
  }

  bool get hasMorePages => currentPage < lastPage;

  @override
  String toString() {
    return 'AuditLogListDto(total: $total, currentPage: $currentPage, '
        'lastPage: $lastPage, logs: ${logs.length})';
  }
}

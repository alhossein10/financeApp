import 'package:equatable/equatable.dart';

/// Domain entity for audit log
class AuditLog extends Equatable {
  final int id;
  final int userId;
  final String? userName;
  final String action;
  final String entityType;
  final int entityId;
  final String ipAddress;
  final String userAgent;
  final Map<String, dynamic>? changes;
  final DateTime createdAt;

  const AuditLog({
    required this.id,
    required this.userId,
    this.userName,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.ipAddress,
    required this.userAgent,
    this.changes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        action,
        entityType,
        entityId,
        ipAddress,
        userAgent,
        changes,
        createdAt,
      ];
}

/// Paginated audit log list
class AuditLogList extends Equatable {
  final List<AuditLog> logs;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  const AuditLogList({
    required this.logs,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });

  bool get hasMorePages => currentPage < lastPage;

  @override
  List<Object?> get props => [logs, currentPage, lastPage, total, perPage];
}

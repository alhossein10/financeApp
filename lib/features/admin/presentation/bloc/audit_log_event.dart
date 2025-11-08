import 'package:equatable/equatable.dart';

/// Base class for audit log events
abstract class AuditLogEvent extends Equatable {
  const AuditLogEvent();

  @override
  List<Object?> get props => [];
}

/// Event to fetch audit logs with pagination and filters
class FetchAuditLogsRequested extends AuditLogEvent {
  final int page;
  final int perPage;
  final int? userId;
  final String? action;
  final String? entityType;
  final DateTime? startDate;
  final DateTime? endDate;

  const FetchAuditLogsRequested({
    this.page = 1,
    this.perPage = 15,
    this.userId,
    this.action,
    this.entityType,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [
        page,
        perPage,
        userId,
        action,
        entityType,
        startDate,
        endDate,
      ];
}

/// Event to load more audit logs (pagination)
class LoadMoreAuditLogsRequested extends AuditLogEvent {
  const LoadMoreAuditLogsRequested();
}

/// Event to fetch audit log details
class FetchAuditLogDetailsRequested extends AuditLogEvent {
  final int id;

  const FetchAuditLogDetailsRequested(this.id);

  @override
  List<Object?> get props => [id];
}

/// Event to refresh audit logs
class RefreshAuditLogsRequested extends AuditLogEvent {
  const RefreshAuditLogsRequested();
}

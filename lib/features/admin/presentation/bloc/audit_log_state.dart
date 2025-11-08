import 'package:equatable/equatable.dart';
import '../../domain/entities/audit_log.dart';

/// Base class for audit log states
abstract class AuditLogState extends Equatable {
  const AuditLogState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AuditLogInitial extends AuditLogState {
  const AuditLogInitial();
}

/// Loading state
class AuditLogLoading extends AuditLogState {
  const AuditLogLoading();
}

/// Loading more state (for pagination)
class AuditLogLoadingMore extends AuditLogState {
  final List<AuditLog> currentLogs;
  final int currentPage;

  const AuditLogLoadingMore({
    required this.currentLogs,
    required this.currentPage,
  });

  @override
  List<Object?> get props => [currentLogs, currentPage];
}

/// Loaded state with audit logs
class AuditLogLoaded extends AuditLogState {
  final List<AuditLog> logs;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool hasMorePages;

  const AuditLogLoaded({
    required this.logs,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.hasMorePages,
  });

  @override
  List<Object?> get props => [logs, currentPage, lastPage, total, hasMorePages];

  AuditLogLoaded copyWith({
    List<AuditLog>? logs,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? hasMorePages,
  }) {
    return AuditLogLoaded(
      logs: logs ?? this.logs,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      hasMorePages: hasMorePages ?? this.hasMorePages,
    );
  }
}

/// Audit log details loaded state
class AuditLogDetailsLoaded extends AuditLogState {
  final AuditLog auditLog;

  const AuditLogDetailsLoaded(this.auditLog);

  @override
  List<Object?> get props => [auditLog];
}

/// Error state
class AuditLogError extends AuditLogState {
  final String message;
  final bool requiresLogin;

  const AuditLogError(
    this.message, {
    this.requiresLogin = false,
  });

  @override
  List<Object?> get props => [message, requiresLogin];
}

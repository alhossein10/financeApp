import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/audit_log.dart';

/// Repository interface for audit log operations
abstract class AuditLogRepository {
  /// Get audit logs with pagination and filtering
  Future<Either<Failure, AuditLogList>> getAuditLogs({
    int page = 1,
    int perPage = 15,
    int? userId,
    String? action,
    String? entityType,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get audit log details by ID
  Future<Either<Failure, AuditLog>> getAuditLogDetails(int id);
}

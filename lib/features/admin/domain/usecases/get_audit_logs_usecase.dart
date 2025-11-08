import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/audit_log.dart';
import '../repositories/audit_log_repository.dart';

/// Use case for getting audit logs with pagination and filtering
class GetAuditLogsUseCase {
  final AuditLogRepository repository;

  GetAuditLogsUseCase(this.repository);

  Future<Either<Failure, AuditLogList>> call({
    int page = 1,
    int perPage = 15,
    int? userId,
    String? action,
    String? entityType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await repository.getAuditLogs(
      page: page,
      perPage: perPage,
      userId: userId,
      action: action,
      entityType: entityType,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

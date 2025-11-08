import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/audit_log.dart';
import '../repositories/audit_log_repository.dart';

/// Use case for getting audit log details by ID
class GetAuditLogDetailsUseCase {
  final AuditLogRepository repository;

  GetAuditLogDetailsUseCase(this.repository);

  Future<Either<Failure, AuditLog>> call(int id) async {
    return await repository.getAuditLogDetails(id);
  }
}

import 'package:dartz/dartz.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../datasources/audit_log_api_datasource.dart';
import '../models/audit_log_dto.dart';

/// Implementation of AuditLogRepository
class AuditLogRepositoryImpl implements AuditLogRepository {
  final AuditLogApiDataSource apiDataSource;

  AuditLogRepositoryImpl({required this.apiDataSource});

  @override
  Future<Either<Failure, AuditLogList>> getAuditLogs({
    int page = 1,
    int perPage = 15,
    int? userId,
    String? action,
    String? entityType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final result = await apiDataSource.getAuditLogs(
        page: page,
        perPage: perPage,
        userId: userId,
        action: action,
        resourceType: entityType,
        startDate: startDate,
        endDate: endDate,
      );

      final logs = result.logs.map(_dtoToEntity).toList();

      return Right(AuditLogList(
        logs: logs,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        total: result.total,
        perPage: result.perPage,
      ));
    } on ApiException catch (e) {
      if (e.isForbidden) {
        return Left(AuthorizationFailure('Admin privileges required'));
      } else if (e.isUnauthorized) {
        return Left(AuthenticationFailure('Session expired'));
      } else {
        return Left(ServerFailure(e.userFriendlyMessage));
      }
    } catch (e) {
      return Left(ServerFailure('Failed to get audit logs: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AuditLog>> getAuditLogDetails(int id) async {
    try {
      final result = await apiDataSource.getAuditLogDetails(id);
      return Right(_dtoToEntity(result));
    } on ApiException catch (e) {
      if (e.isForbidden) {
        return Left(AuthorizationFailure('Admin privileges required'));
      } else if (e.isUnauthorized) {
        return Left(AuthenticationFailure('Session expired'));
      } else if (e.isNotFound) {
        return Left(NotFoundFailure('Audit log not found'));
      } else {
        return Left(ServerFailure(e.userFriendlyMessage));
      }
    } catch (e) {
      return Left(ServerFailure('Failed to get audit log details: ${e.toString()}'));
    }
  }

  /// Convert DTO to domain entity
  AuditLog _dtoToEntity(AuditLogDto dto) {
    return AuditLog(
      id: dto.id,
      userId: dto.userId,
      userName: dto.userName,
      action: dto.action,
      entityType: dto.entityType,
      entityId: dto.entityId,
      ipAddress: dto.ipAddress,
      userAgent: dto.userAgent,
      changes: dto.changes,
      createdAt: dto.createdAt,
    );
  }
}

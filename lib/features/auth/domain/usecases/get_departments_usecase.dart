import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/department.dart';
import '../repositories/auth_repository.dart';

/// Use case for fetching departments for a specific organization
class GetDepartmentsUseCase {
  final AuthRepository repository;

  GetDepartmentsUseCase(this.repository);

  /// Execute the use case to retrieve departments for an organization
  /// Returns [List<Department>] on success or [Failure] on error
  Future<Either<Failure, List<Department>>> call(int organizationId) async {
    return await repository.getDepartments(organizationId);
  }
}

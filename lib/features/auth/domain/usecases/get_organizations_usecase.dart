import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/organization.dart';
import '../repositories/auth_repository.dart';

/// Use case for fetching the list of available organizations
class GetOrganizationsUseCase {
  final AuthRepository repository;

  GetOrganizationsUseCase(this.repository);

  /// Execute the use case to retrieve all organizations
  /// Returns [List<Organization>] on success or [Failure] on error
  Future<Either<Failure, List<Organization>>> call() async {
    return await repository.getOrganizations();
  }
}

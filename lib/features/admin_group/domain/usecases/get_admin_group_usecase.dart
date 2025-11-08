import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/admin_group.dart';
import '../repositories/admin_group_repository.dart';

/// Use case for retrieving admin's group information
/// 
/// This use case fetches the admin's group details including the group code,
/// group name, and member count. It's used by admins to view their group
/// information in the group management section.
/// 
/// Requirements: 2.1
class GetAdminGroupUseCase {
  final AdminGroupRepository repository;

  GetAdminGroupUseCase({required this.repository});

  /// Execute the use case to get admin group information
  /// 
  /// Returns [Right(AdminGroup)] on success with the admin's group details.
  /// Returns [Left(Failure)] on error:
  /// - [UnauthorizedFailure] if user is not authenticated
  /// - [AuthorizationFailure] if user is not an admin
  /// - [NotFoundFailure] if admin has no group
  /// - [NetworkFailure] if network error occurs
  /// - [ServerFailure] if server error occurs
  Future<Either<Failure, AdminGroup>> call() async {
    return await repository.getAdminGroup();
  }
}

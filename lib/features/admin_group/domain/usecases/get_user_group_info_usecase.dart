import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/group_info.dart';
import '../repositories/admin_group_repository.dart';

/// Use case for retrieving user's group information
/// 
/// This use case fetches the group information for a regular user, including
/// the group code, group name, admin details, member count, and join date.
/// It's used by regular users to view their group information.
/// 
/// Requirements: 3.1-3.6
class GetUserGroupInfoUseCase {
  final AdminGroupRepository repository;

  GetUserGroupInfoUseCase({required this.repository});

  /// Execute the use case to get user's group information
  /// 
  /// Returns [Right(GroupInfo)] on success with the user's group details.
  /// Returns [Left(Failure)] on error:
  /// - [UnauthorizedFailure] if user is not authenticated
  /// - [NotFoundFailure] if user is not in any group
  /// - [NetworkFailure] if network error occurs
  /// - [ServerFailure] if server error occurs
  Future<Either<Failure, GroupInfo>> call() async {
    return await repository.getUserGroupInfo();
  }
}

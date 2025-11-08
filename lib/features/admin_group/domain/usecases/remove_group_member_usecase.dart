import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/admin_group_cache_datasource.dart';
import '../repositories/admin_group_repository.dart';

/// Use case for removing a member from the admin's group
/// 
/// This use case allows admins to remove users from their group. The removed
/// user will lose access to the group's shared financial data.
/// 
/// After successful removal, the member cache is invalidated to ensure the
/// member list is refreshed.
/// 
/// Requirements: 2.4, 2.5
class RemoveGroupMemberUseCase {
  final AdminGroupRepository repository;
  final AdminGroupCacheDataSource cacheDataSource;

  RemoveGroupMemberUseCase({
    required this.repository,
    required this.cacheDataSource,
  });

  /// Execute the use case to remove a group member
  /// 
  /// Parameters:
  /// - userId: ID of the user to remove from the group
  /// 
  /// Returns [Right(void)] on success.
  /// Returns [Left(Failure)] on error:
  /// - [UnauthorizedFailure] if user is not authenticated
  /// - [AuthorizationFailure] if user is not an admin or tries to remove themselves
  /// - [NotFoundFailure] if member not found or not in group
  /// - [NetworkFailure] if network error occurs
  /// - [ServerFailure] if server error occurs
  /// 
  /// Side effects:
  /// - Invalidates the group members cache after successful removal
  Future<Either<Failure, void>> call(int userId) async {
    final result = await repository.removeMember(userId);
    
    // Invalidate member cache after successful removal
    result.fold(
      (failure) {
        // Don't invalidate cache on failure
      },
      (_) async {
        // Invalidate cache to ensure fresh member list is fetched next time
        await cacheDataSource.invalidateGroupMembersCache();
      },
    );
    
    return result;
  }
}

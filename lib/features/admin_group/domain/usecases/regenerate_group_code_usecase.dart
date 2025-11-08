import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/admin_group_cache_datasource.dart';
import '../entities/admin_group.dart';
import '../repositories/admin_group_repository.dart';

/// Use case for regenerating admin's group code
/// 
/// This use case generates a new 6-character group code for the admin's group
/// and invalidates the old code. This is useful when the admin wants to revoke
/// access using the old code or if the code has been compromised.
/// 
/// After regeneration, the cache is invalidated to ensure fresh data is fetched.
/// 
/// Requirements: 2.7
class RegenerateGroupCodeUseCase {
  final AdminGroupRepository repository;
  final AdminGroupCacheDataSource cacheDataSource;

  RegenerateGroupCodeUseCase({
    required this.repository,
    required this.cacheDataSource,
  });

  /// Execute the use case to regenerate the group code
  /// 
  /// Returns [Right(AdminGroup)] on success with the new group code.
  /// Returns [Left(Failure)] on error:
  /// - [UnauthorizedFailure] if user is not authenticated
  /// - [AuthorizationFailure] if user is not an admin
  /// - [NotFoundFailure] if admin has no group
  /// - [NetworkFailure] if network error occurs
  /// - [ServerFailure] if server error occurs
  /// 
  /// Side effects:
  /// - Invalidates the admin group cache after successful regeneration
  Future<Either<Failure, AdminGroup>> call() async {
    final result = await repository.regenerateGroupCode();
    
    // Invalidate cache after successful regeneration
    result.fold(
      (failure) {
        // Don't invalidate cache on failure
      },
      (adminGroup) async {
        // Invalidate cache to ensure fresh data is fetched next time
        await cacheDataSource.invalidateAdminGroupCache();
      },
    );
    
    return result;
  }
}

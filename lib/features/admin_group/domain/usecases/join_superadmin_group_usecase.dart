import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/admin_group_cache_datasource.dart';
import '../entities/group_info.dart';
import '../repositories/admin_group_repository.dart';

/// Use case for joining a SuperAdmin group using a group code (for admin users)
/// 
/// This use case allows admin users to join a SuperAdmin group by entering
/// the 6-character SuperAdmin group code. The code is validated for format before
/// attempting to join.
/// 
/// After successful join, the user group info cache is invalidated to ensure
/// fresh data is fetched.
/// 
/// Note: This is separate from the admin's own group (adminGroupId).
/// An admin can manage their own group with users AND be part of a SuperAdmin group.
class JoinSuperAdminGroupUseCase {
  final AdminGroupRepository repository;
  final AdminGroupCacheDataSource cacheDataSource;

  JoinSuperAdminGroupUseCase({
    required this.repository,
    required this.cacheDataSource,
  });

  /// Execute the use case to join a SuperAdmin group
  /// 
  /// Parameters:
  /// - groupCode: 6-character alphanumeric SuperAdmin group code (case-insensitive)
  /// 
  /// Returns [Right(GroupInfo)] on success with the joined SuperAdmin group information.
  /// Returns [Left(Failure)] on error:
  /// - [ValidationFailure] if group code format is invalid or empty
  /// - [UnauthorizedFailure] if user is not authenticated
  /// - [AuthorizationFailure] if user is not an admin
  /// - [ApiFailure] if admin is already in a SuperAdmin group
  /// - [NotFoundFailure] if SuperAdmin group code doesn't exist
  /// - [NetworkFailure] if network error occurs
  /// - [ServerFailure] if server error occurs
  /// 
  /// Side effects:
  /// - Invalidates the user group info cache after successful join
  Future<Either<Failure, GroupInfo>> call(String groupCode) async {
    // Validate group code is not empty
    if (groupCode.trim().isEmpty) {
      return const Left(ValidationFailure('The SuperAdmin group code field is required'));
    }

    // Validate group code format (exactly 6 alphanumeric characters)
    final trimmedCode = groupCode.trim();
    if (!_isValidGroupCodeFormat(trimmedCode)) {
      return const Left(
        ValidationFailure('SuperAdmin group code must be exactly 6 alphanumeric characters'),
      );
    }

    // Attempt to join the SuperAdmin group
    final result = await repository.joinSuperAdminGroup(trimmedCode);
    
    // Invalidate cache after successful join
    result.fold(
      (failure) {
        // Don't invalidate cache on failure
      },
      (groupInfo) async {
        // Invalidate cache to ensure fresh group info is fetched next time
        await cacheDataSource.invalidateUserGroupInfoCache();
      },
    );
    
    return result;
  }

  /// Validate group code format
  /// 
  /// Group code must be exactly 6 alphanumeric characters (case-insensitive).
  /// Allowed characters: A-Z, a-z, 0-9
  bool _isValidGroupCodeFormat(String code) {
    if (code.length != 6) {
      return false;
    }

    // Check if all characters are alphanumeric
    final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
    return alphanumericRegex.hasMatch(code);
  }
}


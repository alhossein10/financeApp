import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/admin_group_cache_datasource.dart';
import '../entities/group_info.dart';
import '../repositories/admin_group_repository.dart';

/// Use case for joining a group using a group code
/// 
/// This use case allows regular users to join an admin's group by entering
/// the 6-character group code. The code is validated for format before
/// attempting to join.
/// 
/// After successful join, the user group info cache is invalidated to ensure
/// fresh data is fetched.
/// 
/// Requirements: 4.1-4.6
class JoinGroupUseCase {
  final AdminGroupRepository repository;
  final AdminGroupCacheDataSource cacheDataSource;

  JoinGroupUseCase({
    required this.repository,
    required this.cacheDataSource,
  });

  /// Execute the use case to join a group
  /// 
  /// Parameters:
  /// - groupCode: 6-character alphanumeric code (case-insensitive)
  /// 
  /// Returns [Right(GroupInfo)] on success with the joined group information.
  /// Returns [Left(Failure)] on error:
  /// - [ValidationFailure] if group code format is invalid or empty
  /// - [UnauthorizedFailure] if user is not authenticated
  /// - [AuthorizationFailure] if user is an admin (admins cannot join groups)
  /// - [ApiFailure] if user is already in a group
  /// - [NotFoundFailure] if group code doesn't exist
  /// - [NetworkFailure] if network error occurs
  /// - [ServerFailure] if server error occurs
  /// 
  /// Side effects:
  /// - Invalidates the user group info cache after successful join
  Future<Either<Failure, GroupInfo>> call(String groupCode) async {
    // Validate group code is not empty
    if (groupCode.trim().isEmpty) {
      return const Left(ValidationFailure('The group code field is required'));
    }

    // Validate group code format (exactly 6 alphanumeric characters)
    final trimmedCode = groupCode.trim();
    if (!_isValidGroupCodeFormat(trimmedCode)) {
      return const Left(
        ValidationFailure('Group code must be exactly 6 alphanumeric characters'),
      );
    }

    // Attempt to join the group
    final result = await repository.joinGroup(trimmedCode);
    
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

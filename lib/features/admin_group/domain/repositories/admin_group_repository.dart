import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/admin_group.dart';
import '../entities/group_member.dart';
import '../entities/group_info.dart';

/// Repository interface for admin group operations
/// 
/// This repository follows the Clean Architecture pattern and returns
/// Either<Failure, T> to handle errors in a functional way.
abstract class AdminGroupRepository {
  /// Get admin's group information
  /// 
  /// Returns [Right(AdminGroup)] on success.
  /// Returns [Left(Failure)] on error:
  /// - [UnauthorizedFailure] if user is not authenticated
  /// - [AuthorizationFailure] if user is not an admin
  /// - [NotFoundFailure] if admin has no group
  /// - [NetworkFailure] if network error occurs
  /// - [ServerFailure] if server error occurs
  /// 
  /// Requirements: 6.1
  Future<Either<Failure, AdminGroup>> getAdminGroup();

  /// Regenerate group code for admin's group
  /// 
  /// Generates a new 6-character group code and invalidates the old one.
  /// 
  /// Returns [Right(AdminGroup)] with new code on success.
  /// Returns [Left(Failure)] on error:
  /// - [UnauthorizedFailure] if user is not authenticated
  /// - [AuthorizationFailure] if user is not an admin
  /// - [NotFoundFailure] if admin has no group
  /// - [NetworkFailure] if network error occurs
  /// - [ServerFailure] if server error occurs
  /// 
  /// Requirements: 6.2
  Future<Either<Failure, AdminGroup>> regenerateGroupCode();

  /// Get list of group members with pagination and filters
  /// 
  /// Parameters:
  /// - page: Page number (default: 1)
  /// - perPage: Items per page (default: 15)
  /// - search: Search term for name or email (optional)
  /// - department: Filter by department name (optional)
  /// 
  /// Returns [Right(List<GroupMember>)] on success.
  /// Returns [Left(Failure)] on error:
  /// - [UnauthorizedFailure] if user is not authenticated
  /// - [AuthorizationFailure] if user is not an admin
  /// - [NetworkFailure] if network error occurs
  /// - [ServerFailure] if server error occurs
  /// 
  /// Requirements: 6.3
  Future<Either<Failure, List<GroupMember>>> getGroupMembers({
    int page = 1,
    int perPage = 15,
    String? search,
    String? department,
  });

  /// Remove a member from the admin's group
  /// 
  /// Parameters:
  /// - userId: ID of the user to remove
  /// 
  /// Returns [Right(void)] on success.
  /// Returns [Left(Failure)] on error:
  /// - [UnauthorizedFailure] if user is not authenticated
  /// - [AuthorizationFailure] if user is not an admin or tries to remove themselves
  /// - [NotFoundFailure] if member not found or not in group
  /// - [NetworkFailure] if network error occurs
  /// - [ServerFailure] if server error occurs
  /// 
  /// Requirements: 6.4
  Future<Either<Failure, void>> removeMember(int userId);

  /// Join a group using a group code
  /// 
  /// Parameters:
  /// - groupCode: 6-character alphanumeric code (case-insensitive)
  /// 
  /// Returns [Right(GroupInfo)] on success.
  /// Returns [Left(Failure)] on error:
  /// - [UnauthorizedFailure] if user is not authenticated
  /// - [ValidationFailure] if group code is invalid or required
  /// - [AuthorizationFailure] if user is an admin (admins cannot join groups)
  /// - [ApiFailure] if user is already in a group
  /// - [NotFoundFailure] if group code doesn't exist
  /// - [NetworkFailure] if network error occurs
  /// - [ServerFailure] if server error occurs
  /// 
  /// Requirements: 6.5
  Future<Either<Failure, GroupInfo>> joinGroup(String groupCode);

  /// Get user's group information
  /// 
  /// Returns [Right(GroupInfo)] on success.
  /// Returns [Left(Failure)] on error:
  /// - [UnauthorizedFailure] if user is not authenticated
  /// - [NotFoundFailure] if user is not in any group
  /// - [NetworkFailure] if network error occurs
  /// - [ServerFailure] if server error occurs
  /// 
  /// Requirements: 6.6
  Future<Either<Failure, GroupInfo>> getUserGroupInfo();

  /// Join a SuperAdmin group using a group code (for admin users)
  /// 
  /// Parameters:
  /// - groupCode: 6-character alphanumeric SuperAdmin group code (case-insensitive)
  /// 
  /// Returns [Right(GroupInfo)] on success.
  /// Returns [Left(Failure)] on error:
  /// - [UnauthorizedFailure] if user is not authenticated
  /// - [ValidationFailure] if group code is invalid or required
  /// - [AuthorizationFailure] if user is not an admin
  /// - [ApiFailure] if admin is already in a SuperAdmin group
  /// - [NotFoundFailure] if SuperAdmin group code doesn't exist
  /// - [NetworkFailure] if network error occurs
  /// - [ServerFailure] if server error occurs
  /// 
  /// Note: This is separate from the admin's own group (adminGroupId).
  /// An admin can manage their own group with users AND be part of a SuperAdmin group.
  Future<Either<Failure, GroupInfo>> joinSuperAdminGroup(String groupCode);
}

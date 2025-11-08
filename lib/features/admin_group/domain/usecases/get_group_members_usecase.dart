import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/group_member.dart';
import '../repositories/admin_group_repository.dart';

/// Use case for retrieving group members with pagination and filters
/// 
/// This use case fetches the list of members in the admin's group with support
/// for pagination, search, and department filtering. It's used by admins to
/// view and manage their group members.
/// 
/// Requirements: 2.3
class GetGroupMembersUseCase {
  final AdminGroupRepository repository;

  GetGroupMembersUseCase({required this.repository});

  /// Execute the use case to get group members
  /// 
  /// Parameters:
  /// - params: Contains pagination and filter parameters
  /// 
  /// Returns [Right(List<GroupMember>)] on success with the list of members.
  /// Returns [Left(Failure)] on error:
  /// - [UnauthorizedFailure] if user is not authenticated
  /// - [AuthorizationFailure] if user is not an admin
  /// - [NetworkFailure] if network error occurs
  /// - [ServerFailure] if server error occurs
  Future<Either<Failure, List<GroupMember>>> call(
    GetGroupMembersParams params,
  ) async {
    return await repository.getGroupMembers(
      page: params.page,
      perPage: params.perPage,
      search: params.search,
      department: params.department,
    );
  }
}

/// Parameters for getting group members
class GetGroupMembersParams {
  /// Page number (default: 1)
  final int page;

  /// Items per page (default: 15)
  final int perPage;

  /// Search term for name or email (optional)
  final String? search;

  /// Filter by department name (optional)
  final String? department;

  const GetGroupMembersParams({
    this.page = 1,
    this.perPage = 15,
    this.search,
    this.department,
  });

  /// Create a copy with updated parameters
  GetGroupMembersParams copyWith({
    int? page,
    int? perPage,
    String? search,
    String? department,
  }) {
    return GetGroupMembersParams(
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      search: search ?? this.search,
      department: department ?? this.department,
    );
  }
}

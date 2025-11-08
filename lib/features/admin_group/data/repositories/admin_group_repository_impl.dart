import 'package:dartz/dartz.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_group.dart';
import '../../domain/entities/group_member.dart';
import '../../domain/entities/group_info.dart';
import '../../domain/repositories/admin_group_repository.dart';
import '../datasources/admin_group_api_datasource.dart';
import '../datasources/admin_group_cache_datasource.dart';

/// Implementation of [AdminGroupRepository]
/// 
/// This repository implements a cache-first strategy with fallback to API.
/// It handles error mapping from API exceptions to domain failures.
class AdminGroupRepositoryImpl implements AdminGroupRepository {
  final AdminGroupApiDataSource apiDataSource;
  final AdminGroupCacheDataSource cacheDataSource;

  AdminGroupRepositoryImpl({
    required this.apiDataSource,
    required this.cacheDataSource,
  });

  @override
  Future<Either<Failure, AdminGroup>> getAdminGroup() async {
    try {
      // Try cache first
      final cachedGroup = await cacheDataSource.getCachedAdminGroup();
      if (cachedGroup != null) {
        return Right(cachedGroup.toEntity());
      }

      // Fetch from API
      final groupDto = await apiDataSource.getAdminGroup();
      
      // Cache the result
      await cacheDataSource.cacheAdminGroup(groupDto);
      
      return Right(groupDto.toEntity());
    } on ApiException catch (e) {
      // Error is logged in _mapApiExceptionToFailure
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      // Log unexpected errors
      print('Unexpected error getting admin group: $e');
      return Left(ServerFailure('Failed to get admin group: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AdminGroup>> regenerateGroupCode() async {
    try {
      // Call API to regenerate code
      final groupDto = await apiDataSource.regenerateGroupCode();
      
      // Invalidate old cache and cache new data
      await cacheDataSource.invalidateAdminGroupCache();
      await cacheDataSource.cacheAdminGroup(groupDto);
      
      return Right(groupDto.toEntity());
    } on ApiException catch (e) {
      // Error is logged in _mapApiExceptionToFailure
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      // Log unexpected errors
      print('Unexpected error regenerating group code: $e');
      return Left(ServerFailure('Failed to regenerate group code: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<GroupMember>>> getGroupMembers({
    int page = 1,
    int perPage = 15,
    String? search,
    String? department,
  }) async {
    try {
      // Try cache first (only for first page without filters)
      if (page == 1 && search == null && department == null) {
        final cachedMembers = await cacheDataSource.getCachedGroupMembers(
          page: page,
          perPage: perPage,
        );
        if (cachedMembers != null) {
          return Right(cachedMembers.data.map((dto) => dto.toEntity()).toList());
        }
      }

      // Fetch from API
      print('[AdminGroupRepository] Fetching group members from API...');
      final response = await apiDataSource.getGroupMembers(
        page: page,
        perPage: perPage,
        search: search,
        department: department,
      );
      
      print('[AdminGroupRepository] Received response with ${response.data.length} members');
      print('[AdminGroupRepository] Response pagination: page=${response.currentPage}, total=${response.total}');
      
      // Cache the result (only for first page without filters)
      if (page == 1 && search == null && department == null) {
        await cacheDataSource.cacheGroupMembers(response, page: page, perPage: perPage);
      }
      
      final entities = response.data.map((dto) {
        print('[AdminGroupRepository] Converting DTO to entity: id=${dto.id}, name=${dto.name}');
        return dto.toEntity();
      }).toList();
      
      print('[AdminGroupRepository] ✅ Successfully converted ${entities.length} members to entities');
      return Right(entities);
    } on ApiException catch (e) {
      // Error is logged in _mapApiExceptionToFailure
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      // Log unexpected errors
      print('Unexpected error getting group members: $e');
      return Left(ServerFailure('Failed to get group members: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> removeMember(int userId) async {
    try {
      // Call API to remove member
      await apiDataSource.removeMember(userId);
      
      // Invalidate member cache
      await cacheDataSource.invalidateGroupMembersCache();
      
      // Also invalidate admin group cache to update member count
      await cacheDataSource.invalidateAdminGroupCache();
      
      return const Right(null);
    } on ApiException catch (e) {
      // Error is logged in _mapApiExceptionToFailure
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      // Log unexpected errors
      print('Unexpected error removing member: $e');
      return Left(ServerFailure('Failed to remove member: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, GroupInfo>> joinGroup(String groupCode) async {
    try {
      // Validate group code format
      if (groupCode.isEmpty) {
        return const Left(GroupCodeRequiredFailure());
      }
      
      if (groupCode.length != 6) {
        return const Left(GroupCodeInvalidFailure('Group code must be exactly 6 characters'));
      }

      // Call API to join group
      final groupInfoDto = await apiDataSource.joinGroup(groupCode);
      
      // Cache the result
      await cacheDataSource.cacheUserGroupInfo(groupInfoDto);
      
      return Right(groupInfoDto.toEntity());
    } on ApiException catch (e) {
      // Error is logged in _mapApiExceptionToFailure
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      // Log unexpected errors
      print('Unexpected error joining group: $e');
      return Left(ServerFailure('Failed to join group: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, GroupInfo>> getUserGroupInfo() async {
    try {
      // Try cache first
      final cachedInfo = await cacheDataSource.getCachedUserGroupInfo();
      if (cachedInfo != null) {
        return Right(cachedInfo.toEntity());
      }

      // Fetch from API
      final groupInfoDto = await apiDataSource.getUserGroupInfo();
      
      // Cache the result
      await cacheDataSource.cacheUserGroupInfo(groupInfoDto);
      
      return Right(groupInfoDto.toEntity());
    } on ApiException catch (e) {
      // Error is logged in _mapApiExceptionToFailure
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      // Log unexpected errors
      print('Unexpected error getting user group info: $e');
      return Left(ServerFailure('Failed to get user group info: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, GroupInfo>> joinSuperAdminGroup(String groupCode) async {
    try {
      // Validate group code format
      if (groupCode.isEmpty) {
        return const Left(GroupCodeRequiredFailure());
      }
      
      if (groupCode.length != 6) {
        return const Left(GroupCodeInvalidFailure('SuperAdmin group code must be exactly 6 characters'));
      }

      // Call API to join SuperAdmin group
      final groupInfoDto = await apiDataSource.joinSuperAdminGroup(groupCode);
      
      // Invalidate user cache to refresh user data (superAdminGroupId will be updated)
      await cacheDataSource.invalidateUserGroupInfoCache();
      
      return Right(groupInfoDto.toEntity());
    } on ApiException catch (e) {
      // Error is logged in _mapApiExceptionToFailure
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      // Log unexpected errors
      print('Unexpected error joining SuperAdmin group: $e');
      return Left(ServerFailure('Failed to join SuperAdmin group: ${e.toString()}'));
    }
  }

  /// Map API exceptions to domain failures
  /// 
  /// This method maps HTTP status codes and error messages to specific domain failures.
  /// It handles network errors, authentication errors, and business logic errors.
  Failure _mapApiExceptionToFailure(ApiException exception) {
    // Errors are logged by ApiClient, no need to log again here
    
    final message = exception.message.toLowerCase();
    
    // Handle network errors (no status code)
    if (exception.statusCode == null) {
      return const NetworkFailure('Network error occurred. Please check your connection.');
    }
    
    switch (exception.statusCode) {
      case 401:
        return const UnauthorizedFailure('Authentication required. Please log in again.');
        
      case 403:
        // Check for specific authorization errors
        if (message.contains('cannot remove yourself') || message.contains('remove yourself')) {
          return CannotRemoveSelfFailure(exception.message);
        }
        if (message.contains('admins cannot join') || message.contains('admin') && message.contains('join')) {
          return AdminCannotJoinFailure(exception.message);
        }
        return AuthorizationFailure(exception.message);
        
      case 404:
        // Check for member not found
        if (message.contains('user not found') || message.contains('not in your group') || message.contains('member')) {
          return MemberNotFoundFailure(exception.message);
        }
        return NotFoundFailure(exception.message);
        
      case 422:
        // Validation errors - map to specific failures
        if (message.contains('group code') && message.contains('invalid')) {
          return GroupCodeInvalidFailure(exception.message);
        }
        if (message.contains('group code') && message.contains('required')) {
          return GroupCodeRequiredFailure(exception.message);
        }
        if (message.contains('already in a group') || message.contains('already in group')) {
          return AlreadyInGroupFailure(exception.message);
        }
        return ValidationFailure(exception.message);
        
      case 400:
        // Bad request - check for business logic errors
        if (message.contains('already in a group') || message.contains('already in group')) {
          return AlreadyInGroupFailure(exception.message);
        }
        if (message.contains('admins cannot join') || message.contains('admin') && message.contains('join')) {
          return AdminCannotJoinFailure(exception.message);
        }
        if (message.contains('invalid') && message.contains('code')) {
          return GroupCodeInvalidFailure(exception.message);
        }
        return ApiFailure(exception.message);
        
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerFailure('Server error occurred. Please try again later.');
        
      default:
        if (exception.statusCode! >= 500) {
          return ServerFailure(exception.message);
        }
        return ApiFailure(exception.message);
    }
  }
}

import '../../../../core/services/cache_service.dart';
import '../models/admin_group_dto.dart';
import '../models/group_member_dto.dart';
import '../models/group_info_dto.dart';

/// Cache data source for admin group operations
/// 
/// This data source handles caching of admin group data to improve performance
/// and reduce API calls. Implements TTL (time-to-live) for cached data.
abstract class AdminGroupCacheDataSource {
  /// Get cached admin group information
  /// 
  /// Returns cached admin group if available and not expired.
  /// Returns null if cache is empty or expired.
  Future<AdminGroupDto?> getCachedAdminGroup();

  /// Cache admin group information
  /// 
  /// Stores admin group data with TTL of 5 minutes.
  /// Automatically expires after the TTL period.
  Future<void> cacheAdminGroup(AdminGroupDto group);

  /// Get cached group members list
  /// 
  /// Returns cached members list for the specified page if available and not expired.
  /// Returns null if cache is empty or expired.
  /// 
  /// Parameters:
  /// - page: Page number
  /// - perPage: Items per page
  Future<GroupMemberListResponse?> getCachedGroupMembers({
    int page = 1,
    int perPage = 15,
  });

  /// Cache group members list
  /// 
  /// Stores group members list with TTL of 2 minutes.
  /// Automatically expires after the TTL period.
  /// 
  /// Parameters:
  /// - response: The member list response to cache
  /// - page: Page number
  /// - perPage: Items per page
  Future<void> cacheGroupMembers(
    GroupMemberListResponse response, {
    int page = 1,
    int perPage = 15,
  });

  /// Get cached user group information
  /// 
  /// Returns cached user group info if available and not expired.
  /// Returns null if cache is empty or expired.
  Future<GroupInfoDto?> getCachedUserGroupInfo();

  /// Cache user group information
  /// 
  /// Stores user group info with TTL of 10 minutes.
  /// Automatically expires after the TTL period.
  Future<void> cacheUserGroupInfo(GroupInfoDto groupInfo);

  /// Invalidate admin group cache
  /// 
  /// Clears cached admin group data.
  /// Should be called after regenerating group code.
  Future<void> invalidateAdminGroupCache();

  /// Invalidate group members cache
  /// 
  /// Clears all cached member lists.
  /// Should be called after removing a member.
  Future<void> invalidateGroupMembersCache();

  /// Invalidate user group info cache
  /// 
  /// Clears cached user group information.
  /// Should be called after joining a group.
  Future<void> invalidateUserGroupInfoCache();

  /// Clear all group-related cache
  /// 
  /// Removes all cached data related to admin groups.
  /// Useful for logout or when switching users.
  Future<void> clearAllCache();
}

/// Implementation of [AdminGroupCacheDataSource] using CacheService
class AdminGroupCacheDataSourceImpl implements AdminGroupCacheDataSource {
  final CacheService cacheService;

  // Cache keys
  static const String _adminGroupKey = 'admin_group';
  static const String _userGroupInfoKey = 'user_group_info';
  static const String _groupMembersPrefix = 'group_members';

  // Cache TTL durations as per design document
  static const Duration _adminGroupTTL = Duration(minutes: 5);
  static const Duration _groupMembersTTL = Duration(minutes: 2);
  static const Duration _userGroupInfoTTL = Duration(minutes: 10);

  AdminGroupCacheDataSourceImpl({required this.cacheService});

  /// Generate cache key for group members list
  String _getGroupMembersKey(int page, int perPage) {
    return '${_groupMembersPrefix}_${page}_$perPage';
  }

  @override
  Future<AdminGroupDto?> getCachedAdminGroup() async {
    try {
      final cached = await cacheService.get<Map<String, dynamic>>(_adminGroupKey);
      
      if (cached != null) {
        return AdminGroupDto.fromJson(cached);
      }
      return null;
    } catch (e) {
      // Silently fail cache operations
      return null;
    }
  }

  @override
  Future<void> cacheAdminGroup(AdminGroupDto group) async {
    try {
      await cacheService.set(
        _adminGroupKey,
        group.toJson(),
        ttl: _adminGroupTTL,
      );
    } catch (e) {
      // Silently fail cache operations
    }
  }

  @override
  Future<GroupMemberListResponse?> getCachedGroupMembers({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final key = _getGroupMembersKey(page, perPage);
      final cached = await cacheService.get<Map<String, dynamic>>(key);
      
      if (cached != null) {
        return GroupMemberListResponse.fromJson(cached);
      }
      return null;
    } catch (e) {
      // Silently fail cache operations
      return null;
    }
  }

  @override
  Future<void> cacheGroupMembers(
    GroupMemberListResponse response, {
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final key = _getGroupMembersKey(page, perPage);
      final json = {
        'data': response.data.map((e) => e.toJson()).toList(),
        'current_page': response.currentPage,
        'last_page': response.lastPage,
        'per_page': response.perPage,
        'total': response.total,
      };
      
      await cacheService.set(key, json, ttl: _groupMembersTTL);
    } catch (e) {
      // Silently fail cache operations
    }
  }

  @override
  Future<GroupInfoDto?> getCachedUserGroupInfo() async {
    try {
      final cached = await cacheService.get<Map<String, dynamic>>(_userGroupInfoKey);
      
      if (cached != null) {
        return GroupInfoDto.fromJson(cached);
      }
      return null;
    } catch (e) {
      // Silently fail cache operations
      return null;
    }
  }

  @override
  Future<void> cacheUserGroupInfo(GroupInfoDto groupInfo) async {
    try {
      await cacheService.set(
        _userGroupInfoKey,
        groupInfo.toJson(),
        ttl: _userGroupInfoTTL,
      );
    } catch (e) {
      // Silently fail cache operations
    }
  }

  @override
  Future<void> invalidateAdminGroupCache() async {
    try {
      await cacheService.delete(_adminGroupKey);
    } catch (e) {
      // Silently fail cache operations
    }
  }

  @override
  Future<void> invalidateGroupMembersCache() async {
    try {
      // Clear common member list cache keys
      for (int page = 1; page <= 10; page++) {
        for (int perPage in [15, 25, 50]) {
          final key = _getGroupMembersKey(page, perPage);
          await cacheService.delete(key);
        }
      }
    } catch (e) {
      // Silently fail cache operations
    }
  }

  @override
  Future<void> invalidateUserGroupInfoCache() async {
    try {
      await cacheService.delete(_userGroupInfoKey);
    } catch (e) {
      // Silently fail cache operations
    }
  }

  @override
  Future<void> clearAllCache() async {
    try {
      await invalidateAdminGroupCache();
      await invalidateGroupMembersCache();
      await invalidateUserGroupInfoCache();
    } catch (e) {
      // Silently fail cache operations
    }
  }
}

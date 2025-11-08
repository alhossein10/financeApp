import 'package:equatable/equatable.dart';

/// Base class for all AdminGroup events
abstract class AdminGroupEvent extends Equatable {
  const AdminGroupEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load admin's group information
/// 
/// This event triggers fetching the admin's group details including
/// the group code, group name, and member count.
/// 
/// Requirements: 2.1
class LoadAdminGroupEvent extends AdminGroupEvent {
  const LoadAdminGroupEvent();
}

/// Event to regenerate the admin's group code
/// 
/// This event triggers generation of a new 6-character group code.
/// The old code will be invalidated and users will need the new code to join.
/// 
/// Requirements: 2.7, 2.8
class RegenerateGroupCodeEvent extends AdminGroupEvent {
  const RegenerateGroupCodeEvent();
}

/// Event to load group members with pagination and filters
/// 
/// This event triggers fetching the list of members in the admin's group.
/// Supports pagination, search by name/email, and filtering by department.
/// 
/// Requirements: 2.3
class LoadGroupMembersEvent extends AdminGroupEvent {
  /// Page number (default: 1)
  final int page;

  /// Items per page (default: 15)
  final int perPage;

  /// Search term for name or email (optional)
  final String? search;

  /// Filter by department name (optional)
  final String? department;

  /// Whether to load more (append to existing list) or refresh (replace list)
  final bool loadMore;

  const LoadGroupMembersEvent({
    this.page = 1,
    this.perPage = 15,
    this.search,
    this.department,
    this.loadMore = false,
  });

  @override
  List<Object?> get props => [page, perPage, search, department, loadMore];
}

/// Event to remove a member from the admin's group
/// 
/// This event triggers removal of a user from the group.
/// The removed user will lose access to the group's shared data.
/// 
/// Requirements: 2.4, 2.5
class RemoveGroupMemberEvent extends AdminGroupEvent {
  /// ID of the user to remove from the group
  final int userId;

  const RemoveGroupMemberEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Event to join a group using a group code
/// 
/// This event triggers joining an admin's group by entering the
/// 6-character group code. The code is validated before attempting to join.
/// 
/// Requirements: 4.1-4.6
class JoinGroupEvent extends AdminGroupEvent {
  /// 6-character alphanumeric group code (case-insensitive)
  final String groupCode;

  const JoinGroupEvent({required this.groupCode});

  @override
  List<Object?> get props => [groupCode];
}

/// Event to load user's group information
/// 
/// This event triggers fetching the group information for a regular user,
/// including the group code, group name, admin details, and member count.
/// 
/// Requirements: 3.1-3.6
class LoadUserGroupInfoEvent extends AdminGroupEvent {
  const LoadUserGroupInfoEvent();
}

/// Event to copy group code to clipboard
/// 
/// This event triggers copying the group code to the system clipboard
/// and shows a confirmation message to the user.
/// 
/// Requirements: 7.1, 7.2
class CopyGroupCodeEvent extends AdminGroupEvent {
  /// The group code to copy to clipboard
  final String groupCode;

  const CopyGroupCodeEvent({required this.groupCode});

  @override
  List<Object?> get props => [groupCode];
}

/// Event to join a SuperAdmin group using a group code (for admin users)
/// 
/// This event triggers joining a SuperAdmin group by entering the
/// 6-character SuperAdmin group code. This is separate from the admin's own group.
/// 
/// Note: An admin can manage their own group with users AND be part of a SuperAdmin group.
class JoinSuperAdminGroupEvent extends AdminGroupEvent {
  /// 6-character alphanumeric SuperAdmin group code (case-insensitive)
  final String groupCode;

  const JoinSuperAdminGroupEvent({required this.groupCode});

  @override
  List<Object?> get props => [groupCode];
}
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_admin_group_usecase.dart';
import '../../domain/usecases/regenerate_group_code_usecase.dart';
import '../../domain/usecases/get_group_members_usecase.dart';
import '../../domain/usecases/remove_group_member_usecase.dart';
import '../../domain/usecases/join_group_usecase.dart';
import '../../domain/usecases/get_user_group_info_usecase.dart';
import '../../domain/usecases/join_superadmin_group_usecase.dart';
import 'admin_group_event.dart';
import 'admin_group_state.dart';

/// BLoC for managing admin group state and operations
/// 
/// This BLoC handles all admin group management operations including:
/// - Loading admin group information
/// - Regenerating group codes
/// - Loading and managing group members
/// - Removing members from groups
/// - Joining groups with codes
/// - Loading user group information
/// - Copying group codes to clipboard
/// 
/// Requirements: 2.1-2.8, 3.1-3.6, 4.1-4.6
class AdminGroupBloc extends Bloc<AdminGroupEvent, AdminGroupState> {
  final GetAdminGroupUseCase getAdminGroupUseCase;
  final RegenerateGroupCodeUseCase regenerateGroupCodeUseCase;
  final GetGroupMembersUseCase getGroupMembersUseCase;
  final RemoveGroupMemberUseCase removeGroupMemberUseCase;
  final JoinGroupUseCase joinGroupUseCase;
  final GetUserGroupInfoUseCase getUserGroupInfoUseCase;
  final JoinSuperAdminGroupUseCase joinSuperAdminGroupUseCase;

  AdminGroupBloc({
    required this.getAdminGroupUseCase,
    required this.regenerateGroupCodeUseCase,
    required this.getGroupMembersUseCase,
    required this.removeGroupMemberUseCase,
    required this.joinGroupUseCase,
    required this.getUserGroupInfoUseCase,
    required this.joinSuperAdminGroupUseCase,
  }) : super(const AdminGroupInitial()) {
    on<LoadAdminGroupEvent>(_onLoadAdminGroup);
    on<RegenerateGroupCodeEvent>(_onRegenerateGroupCode);
    on<LoadGroupMembersEvent>(_onLoadGroupMembers);
    on<RemoveGroupMemberEvent>(_onRemoveGroupMember);
    on<JoinGroupEvent>(_onJoinGroup);
    on<LoadUserGroupInfoEvent>(_onLoadUserGroupInfo);
    on<CopyGroupCodeEvent>(_onCopyGroupCode);
    on<JoinSuperAdminGroupEvent>(_onJoinSuperAdminGroup);
  }

  /// Handle loading admin group information
  /// 
  /// Fetches the admin's group details including group code, name, and member count.
  /// 
  /// Requirements: 2.1
  Future<void> _onLoadAdminGroup(
    LoadAdminGroupEvent event,
    Emitter<AdminGroupState> emit,
  ) async {
    print('[AdminGroupBloc] Loading admin group...');
    emit(AdminGroupLoading(
      members: state.members,
      currentPage: state.currentPage,
      hasMoreMembers: state.hasMoreMembers,
      searchTerm: state.searchTerm,
      departmentFilter: state.departmentFilter,
    ));

    final result = await getAdminGroupUseCase();

    result.fold(
      (failure) {
        print('[AdminGroupBloc] ❌ Failed to load admin group: ${failure.message}');
        emit(AdminGroupError(
          errorMessage: _formatErrorMessage(failure.message),
          members: state.members,
          currentPage: state.currentPage,
          hasMoreMembers: state.hasMoreMembers,
          searchTerm: state.searchTerm,
          departmentFilter: state.departmentFilter,
        ));
      },
      (adminGroup) {
        print('[AdminGroupBloc] ✅ Admin group loaded successfully');
        print('[AdminGroupBloc]    Group Code: ${adminGroup.groupCode}');
        print('[AdminGroupBloc]    Group Name: ${adminGroup.groupName ?? "N/A"}');
        print('[AdminGroupBloc]    Members: ${adminGroup.membersCount ?? 0}');
        emit(AdminGroupLoaded(
          adminGroup: adminGroup,
          members: state.members,
          currentPage: state.currentPage,
          hasMoreMembers: state.hasMoreMembers,
          searchTerm: state.searchTerm,
          departmentFilter: state.departmentFilter,
        ));
      },
    );
  }

  /// Handle regenerating group code
  /// 
  /// Generates a new 6-character group code and invalidates the old one.
  /// 
  /// Requirements: 2.7, 2.8
  Future<void> _onRegenerateGroupCode(
    RegenerateGroupCodeEvent event,
    Emitter<AdminGroupState> emit,
  ) async {
    print('[AdminGroupBloc] Regenerating group code...');
    emit(AdminGroupLoading(
      adminGroup: state.adminGroup,
      members: state.members,
      currentPage: state.currentPage,
      hasMoreMembers: state.hasMoreMembers,
      searchTerm: state.searchTerm,
      departmentFilter: state.departmentFilter,
    ));

    final result = await regenerateGroupCodeUseCase();

    result.fold(
      (failure) {
        print('[AdminGroupBloc] ❌ Failed to regenerate group code: ${failure.message}');
        emit(AdminGroupError(
          errorMessage: _formatErrorMessage(failure.message),
          adminGroup: state.adminGroup,
          members: state.members,
          currentPage: state.currentPage,
          hasMoreMembers: state.hasMoreMembers,
          searchTerm: state.searchTerm,
          departmentFilter: state.departmentFilter,
        ));
      },
      (adminGroup) {
        print('[AdminGroupBloc] ✅ Group code regenerated successfully');
        print('[AdminGroupBloc]    New Group Code: ${adminGroup.groupCode}');
        emit(GroupCodeRegenerated(
          adminGroup: adminGroup,
          members: state.members,
          currentPage: state.currentPage,
          hasMoreMembers: state.hasMoreMembers,
          searchTerm: state.searchTerm,
          departmentFilter: state.departmentFilter,
        ));
      },
    );
  }

  /// Handle loading group members
  /// 
  /// Fetches the list of members with pagination and optional filters.
  /// Supports both initial load and loading more (pagination).
  /// 
  /// Requirements: 2.3
  Future<void> _onLoadGroupMembers(
    LoadGroupMembersEvent event,
    Emitter<AdminGroupState> emit,
  ) async {
    print('[AdminGroupBloc] Loading group members (page ${event.page})...');
    
    // Determine loading state based on whether we're loading more or refreshing
    if (event.loadMore) {
      emit(state.copyWith(isLoadingMoreMembers: true));
    } else {
      emit(state.copyWith(
        isLoadingMembers: true,
        searchTerm: event.search,
        departmentFilter: event.department,
      ));
    }

    final params = GetGroupMembersParams(
      page: event.page,
      perPage: event.perPage,
      search: event.search,
      department: event.department,
    );

    final result = await getGroupMembersUseCase(params);

    result.fold(
      (failure) {
        print('[AdminGroupBloc] ❌ Failed to load group members: ${failure.message}');
        emit(AdminGroupError(
          errorMessage: _formatErrorMessage(failure.message),
          adminGroup: state.adminGroup,
          members: state.members,
          currentPage: state.currentPage,
          hasMoreMembers: state.hasMoreMembers,
          searchTerm: event.search,
          departmentFilter: event.department,
        ));
      },
      (members) {
        print('[AdminGroupBloc] ✅ Loaded ${members.length} group members');
        
        // Determine if there are more members to load
        final hasMore = members.length >= event.perPage;
        
        // Combine with existing members if loading more, otherwise replace
        final updatedMembers = event.loadMore 
            ? [...state.members, ...members]
            : members;
        
        emit(GroupMembersLoaded(
          adminGroup: state.adminGroup,
          members: updatedMembers,
          currentPage: event.page,
          hasMoreMembers: hasMore,
          searchTerm: event.search,
          departmentFilter: event.department,
        ));
      },
    );
  }

  /// Handle removing a group member
  /// 
  /// Removes a user from the admin's group. The removed user will lose
  /// access to the group's shared financial data.
  /// 
  /// Requirements: 2.4, 2.5
  Future<void> _onRemoveGroupMember(
    RemoveGroupMemberEvent event,
    Emitter<AdminGroupState> emit,
  ) async {
    print('[AdminGroupBloc] Removing member ${event.userId}...');
    emit(AdminGroupLoading(
      adminGroup: state.adminGroup,
      members: state.members,
      currentPage: state.currentPage,
      hasMoreMembers: state.hasMoreMembers,
      searchTerm: state.searchTerm,
      departmentFilter: state.departmentFilter,
    ));

    final result = await removeGroupMemberUseCase(event.userId);

    result.fold(
      (failure) {
        print('[AdminGroupBloc] ❌ Failed to remove member: ${failure.message}');
        emit(AdminGroupError(
          errorMessage: _formatErrorMessage(failure.message),
          adminGroup: state.adminGroup,
          members: state.members,
          currentPage: state.currentPage,
          hasMoreMembers: state.hasMoreMembers,
          searchTerm: state.searchTerm,
          departmentFilter: state.departmentFilter,
        ));
      },
      (_) {
        print('[AdminGroupBloc] ✅ Member removed successfully');
        
        // Remove the member from the local list
        final updatedMembers = state.members
            .where((member) => member.id != event.userId)
            .toList();
        
        // Update admin group member count if available
        final updatedAdminGroup = state.adminGroup?.copyWith(
          membersCount: (state.adminGroup?.membersCount ?? 0) - 1,
        );
        
        emit(MemberRemoved(
          adminGroup: updatedAdminGroup,
          members: updatedMembers,
          currentPage: state.currentPage,
          hasMoreMembers: state.hasMoreMembers,
          searchTerm: state.searchTerm,
          departmentFilter: state.departmentFilter,
        ));
      },
    );
  }

  /// Handle joining a group
  /// 
  /// Allows a regular user to join an admin's group using a 6-character code.
  /// The code is validated before attempting to join.
  /// 
  /// Requirements: 4.1-4.6
  Future<void> _onJoinGroup(
    JoinGroupEvent event,
    Emitter<AdminGroupState> emit,
  ) async {
    print('[AdminGroupBloc] Joining group with code: ${event.groupCode}');
    emit(const AdminGroupLoading());

    final result = await joinGroupUseCase(event.groupCode);

    result.fold(
      (failure) {
        print('[AdminGroupBloc] ❌ Failed to join group: ${failure.message}');
        emit(AdminGroupError(
          errorMessage: _formatErrorMessage(failure.message),
        ));
      },
      (groupInfo) {
        print('[AdminGroupBloc] ✅ Successfully joined group');
        print('[AdminGroupBloc]    Group Name: ${groupInfo.groupName ?? "N/A"}');
        print('[AdminGroupBloc]    Admin: ${groupInfo.adminName}');
        emit(GroupJoined(userGroupInfo: groupInfo));
      },
    );
  }

  /// Handle loading user group information
  /// 
  /// Fetches the group information for a regular user, including
  /// group code, name, admin details, and member count.
  /// 
  /// Requirements: 3.1-3.6
  Future<void> _onLoadUserGroupInfo(
    LoadUserGroupInfoEvent event,
    Emitter<AdminGroupState> emit,
  ) async {
    print('[AdminGroupBloc] Loading user group info...');
    emit(const AdminGroupLoading());

    final result = await getUserGroupInfoUseCase();

    result.fold(
      (failure) {
        print('[AdminGroupBloc] ❌ Failed to load user group info: ${failure.message}');
        emit(AdminGroupError(
          errorMessage: _formatErrorMessage(failure.message),
        ));
      },
      (groupInfo) {
        print('[AdminGroupBloc] ✅ User group info loaded successfully');
        print('[AdminGroupBloc]    Group Code: ${groupInfo.groupCode}');
        print('[AdminGroupBloc]    Group Name: ${groupInfo.groupName ?? "N/A"}');
        print('[AdminGroupBloc]    Admin: ${groupInfo.adminName}');
        emit(UserGroupInfoLoaded(userGroupInfo: groupInfo));
      },
    );
  }

  /// Handle copying group code to clipboard
  /// 
  /// Copies the group code to the system clipboard and shows a
  /// confirmation message.
  /// 
  /// Requirements: 7.1, 7.2
  Future<void> _onCopyGroupCode(
    CopyGroupCodeEvent event,
    Emitter<AdminGroupState> emit,
  ) async {
    print('[AdminGroupBloc] Copying group code to clipboard: ${event.groupCode}');
    
    try {
      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: event.groupCode));
      
      print('[AdminGroupBloc] ✅ Group code copied to clipboard');
      emit(GroupCodeCopied(
        adminGroup: state.adminGroup,
        userGroupInfo: state.userGroupInfo,
        members: state.members,
        currentPage: state.currentPage,
        hasMoreMembers: state.hasMoreMembers,
        searchTerm: state.searchTerm,
        departmentFilter: state.departmentFilter,
      ));
    } catch (e) {
      print('[AdminGroupBloc] ❌ Failed to copy to clipboard: $e');
      emit(AdminGroupError(
        errorMessage: 'Failed to copy group code to clipboard',
        adminGroup: state.adminGroup,
        userGroupInfo: state.userGroupInfo,
        members: state.members,
        currentPage: state.currentPage,
        hasMoreMembers: state.hasMoreMembers,
        searchTerm: state.searchTerm,
        departmentFilter: state.departmentFilter,
      ));
    }
  }

  /// Handle joining a SuperAdmin group
  /// 
  /// Allows an admin user to join a SuperAdmin group using a 6-character code.
  /// This is separate from the admin's own group (adminGroupId).
  /// 
  /// Note: An admin can manage their own group with users AND be part of a SuperAdmin group.
  Future<void> _onJoinSuperAdminGroup(
    JoinSuperAdminGroupEvent event,
    Emitter<AdminGroupState> emit,
  ) async {
    print('[AdminGroupBloc] Joining SuperAdmin group with code: ${event.groupCode}');
    emit(const AdminGroupLoading());

    final result = await joinSuperAdminGroupUseCase(event.groupCode);

    result.fold(
      (failure) {
        print('[AdminGroupBloc] ❌ Failed to join SuperAdmin group: ${failure.message}');
        emit(AdminGroupError(
          errorMessage: _formatErrorMessage(failure.message),
        ));
      },
      (groupInfo) {
        print('[AdminGroupBloc] ✅ Successfully joined SuperAdmin group');
        print('[AdminGroupBloc]    Group Name: ${groupInfo.groupName ?? "N/A"}');
        print('[AdminGroupBloc]    Admin: ${groupInfo.adminName}');
        emit(SuperAdminGroupJoined(userGroupInfo: groupInfo));
      },
    );
  }

  /// Format error messages for better user experience
  /// 
  /// Converts technical error messages into user-friendly messages
  /// that are appropriate for display in the UI.
  String _formatErrorMessage(String message) {
    // Handle specific error cases
    if (message.toLowerCase().contains('group code is invalid') ||
        message.toLowerCase().contains('invalid group code')) {
      return 'The selected group code is invalid';
    } else if (message.toLowerCase().contains('group code field is required') ||
               message.toLowerCase().contains('group code is required')) {
      return 'The group code field is required';
    } else if (message.toLowerCase().contains('already in a group') ||
               message.toLowerCase().contains('already in group')) {
      return 'You are already in a group';
    } else if (message.toLowerCase().contains('admins cannot join') ||
               message.toLowerCase().contains('admin cannot join')) {
      return 'Admins cannot join other groups';
    } else if (message.toLowerCase().contains('user not found') ||
               message.toLowerCase().contains('not in your group') ||
               message.toLowerCase().contains('member not found')) {
      return 'User not found or not in your group';
    } else if (message.toLowerCase().contains('cannot remove yourself') ||
               message.toLowerCase().contains('cannot remove self')) {
      return 'You cannot remove yourself from the group';
    } else if (message.contains('401') || 
               message.toLowerCase().contains('unauthorized') ||
               message.toLowerCase().contains('unauthenticated')) {
      return 'You are not authorized. Please log in again.';
    } else if (message.contains('403') || 
               message.toLowerCase().contains('forbidden')) {
      return 'You do not have permission to perform this action';
    } else if (message.contains('404') || 
               message.toLowerCase().contains('not found')) {
      return 'The requested resource was not found';
    } else if (message.contains('422') || 
               message.toLowerCase().contains('validation')) {
      return message; // Validation messages are usually already user-friendly
    } else if (message.contains('429') || 
               message.toLowerCase().contains('rate limit')) {
      return 'Too many requests. Please wait a moment and try again.';
    } else if (message.contains('500') || 
               message.toLowerCase().contains('server error')) {
      return 'Server error. Please try again later.';
    } else if (message.toLowerCase().contains('network') || 
               message.toLowerCase().contains('connection')) {
      return 'Network error. Please check your internet connection.';
    } else if (message.toLowerCase().contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    // Return original message if no specific formatting applies
    return message;
  }
}

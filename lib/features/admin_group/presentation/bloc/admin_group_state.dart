import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_group.dart';
import '../../domain/entities/group_member.dart';
import '../../domain/entities/group_info.dart';

/// State class for AdminGroup feature
/// 
/// This state manages all data related to admin group management,
/// including admin group information, group members, user group info,
/// loading states, and error/success messages.
class AdminGroupState extends Equatable {
  /// Admin's group information (for admins only)
  final AdminGroup? adminGroup;

  /// List of group members (for admins only)
  final List<GroupMember> members;

  /// User's group information (for regular users)
  final GroupInfo? userGroupInfo;

  /// Whether the main content is loading
  final bool isLoading;

  /// Whether group members are being loaded
  final bool isLoadingMembers;

  /// Whether more members are being loaded (pagination)
  final bool isLoadingMoreMembers;

  /// Error message to display
  final String? errorMessage;

  /// Success message to display
  final String? successMessage;

  /// Current page number for member pagination
  final int currentPage;

  /// Whether there are more members to load
  final bool hasMoreMembers;

  /// Search term for filtering members
  final String? searchTerm;

  /// Department filter for members
  final String? departmentFilter;

  const AdminGroupState({
    this.adminGroup,
    this.members = const [],
    this.userGroupInfo,
    this.isLoading = false,
    this.isLoadingMembers = false,
    this.isLoadingMoreMembers = false,
    this.errorMessage,
    this.successMessage,
    this.currentPage = 1,
    this.hasMoreMembers = true,
    this.searchTerm,
    this.departmentFilter,
  });

  /// Create a copy of the state with updated fields
  AdminGroupState copyWith({
    AdminGroup? adminGroup,
    List<GroupMember>? members,
    GroupInfo? userGroupInfo,
    bool? isLoading,
    bool? isLoadingMembers,
    bool? isLoadingMoreMembers,
    String? errorMessage,
    String? successMessage,
    int? currentPage,
    bool? hasMoreMembers,
    String? searchTerm,
    String? departmentFilter,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearAdminGroup = false,
    bool clearUserGroupInfo = false,
    bool clearSearchTerm = false,
    bool clearDepartmentFilter = false,
  }) {
    return AdminGroupState(
      adminGroup: clearAdminGroup ? null : (adminGroup ?? this.adminGroup),
      members: members ?? this.members,
      userGroupInfo: clearUserGroupInfo ? null : (userGroupInfo ?? this.userGroupInfo),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMembers: isLoadingMembers ?? this.isLoadingMembers,
      isLoadingMoreMembers: isLoadingMoreMembers ?? this.isLoadingMoreMembers,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      currentPage: currentPage ?? this.currentPage,
      hasMoreMembers: hasMoreMembers ?? this.hasMoreMembers,
      searchTerm: clearSearchTerm ? null : (searchTerm ?? this.searchTerm),
      departmentFilter: clearDepartmentFilter ? null : (departmentFilter ?? this.departmentFilter),
    );
  }

  @override
  List<Object?> get props => [
        adminGroup,
        members,
        userGroupInfo,
        isLoading,
        isLoadingMembers,
        isLoadingMoreMembers,
        errorMessage,
        successMessage,
        currentPage,
        hasMoreMembers,
        searchTerm,
        departmentFilter,
      ];
}

/// Initial state when the BLoC is first created
class AdminGroupInitial extends AdminGroupState {
  const AdminGroupInitial();
}

/// State when admin group is successfully loaded
class AdminGroupLoaded extends AdminGroupState {
  const AdminGroupLoaded({
    required AdminGroup super.adminGroup,
    super.members,
    super.isLoadingMembers,
    super.isLoadingMoreMembers,
    super.errorMessage,
    super.successMessage,
    super.currentPage,
    super.hasMoreMembers,
    super.searchTerm,
    super.departmentFilter,
  }) : super(
          isLoading: false,
        );
}

/// State when group members are successfully loaded
class GroupMembersLoaded extends AdminGroupState {
  const GroupMembersLoaded({
    super.adminGroup,
    required super.members,
    super.errorMessage,
    super.successMessage,
    super.currentPage,
    super.hasMoreMembers,
    super.searchTerm,
    super.departmentFilter,
  }) : super(
          isLoading: false,
          isLoadingMembers: false,
          isLoadingMoreMembers: false,
        );
}

/// State when user group info is successfully loaded
class UserGroupInfoLoaded extends AdminGroupState {
  const UserGroupInfoLoaded({
    required GroupInfo super.userGroupInfo,
    super.errorMessage,
    super.successMessage,
  }) : super(
          isLoading: false,
        );
}

/// State when group code is successfully regenerated
class GroupCodeRegenerated extends AdminGroupState {
  const GroupCodeRegenerated({
    required AdminGroup super.adminGroup,
    super.members,
    super.currentPage,
    super.hasMoreMembers,
    super.searchTerm,
    super.departmentFilter,
  }) : super(
          isLoading: false,
          successMessage: 'Group code regenerated successfully',
        );
}

/// State when a member is successfully removed
class MemberRemoved extends AdminGroupState {
  const MemberRemoved({
    super.adminGroup,
    super.members,
    super.currentPage,
    super.hasMoreMembers,
    super.searchTerm,
    super.departmentFilter,
  }) : super(
          isLoading: false,
          successMessage: 'Member removed successfully',
        );
}

/// State when user successfully joins a group
class GroupJoined extends AdminGroupState {
  const GroupJoined({
    required GroupInfo userGroupInfo,
  }) : super(
          userGroupInfo: userGroupInfo,
          isLoading: false,
          successMessage: 'Successfully joined the group',
        );
}

/// State when admin successfully joins a SuperAdmin group
class SuperAdminGroupJoined extends AdminGroupState {
  const SuperAdminGroupJoined({
    required GroupInfo userGroupInfo,
  }) : super(
          userGroupInfo: userGroupInfo,
          isLoading: false,
          successMessage: 'Successfully joined the SuperAdmin group',
        );
}

/// State when group code is copied to clipboard
class GroupCodeCopied extends AdminGroupState {
  const GroupCodeCopied({
    super.adminGroup,
    super.userGroupInfo,
    super.members,
    super.currentPage,
    super.hasMoreMembers,
    super.searchTerm,
    super.departmentFilter,
  }) : super(
          isLoading: false,
          successMessage: 'Group code copied to clipboard',
        );
}

/// State when an error occurs
class AdminGroupError extends AdminGroupState {
  const AdminGroupError({
    required String super.errorMessage,
    super.adminGroup,
    super.userGroupInfo,
    super.members,
    super.currentPage,
    super.hasMoreMembers,
    super.searchTerm,
    super.departmentFilter,
  }) : super(
          isLoading: false,
          isLoadingMembers: false,
          isLoadingMoreMembers: false,
        );

  String get message => errorMessage ?? 'Unknown error';
}

/// State when content is loading
class AdminGroupLoading extends AdminGroupState {
  const AdminGroupLoading({
    super.adminGroup,
    super.userGroupInfo,
    super.members,
    super.currentPage,
    super.hasMoreMembers,
    super.searchTerm,
    super.departmentFilter,
  }) : super(
          isLoading: true,
        );
}

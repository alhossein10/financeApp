import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/error/failures.dart';
import 'package:finance_app/features/admin_group/domain/entities/admin_group.dart';
import 'package:finance_app/features/admin_group/domain/entities/group_member.dart';
import 'package:finance_app/features/admin_group/domain/entities/group_info.dart';
import 'package:finance_app/features/admin_group/domain/usecases/get_admin_group_usecase.dart';
import 'package:finance_app/features/admin_group/domain/usecases/regenerate_group_code_usecase.dart';
import 'package:finance_app/features/admin_group/domain/usecases/get_group_members_usecase.dart';
import 'package:finance_app/features/admin_group/domain/usecases/remove_group_member_usecase.dart';
import 'package:finance_app/features/admin_group/domain/usecases/join_group_usecase.dart';
import 'package:finance_app/features/admin_group/domain/usecases/get_user_group_info_usecase.dart';
import 'package:finance_app/features/admin_group/presentation/bloc/admin_group_bloc.dart';
import 'package:finance_app/features/admin_group/presentation/bloc/admin_group_event.dart';
import 'package:finance_app/features/admin_group/presentation/bloc/admin_group_state.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockGetAdminGroupUseCase extends Mock implements GetAdminGroupUseCase {}
class MockRegenerateGroupCodeUseCase extends Mock implements RegenerateGroupCodeUseCase {}
class MockGetGroupMembersUseCase extends Mock implements GetGroupMembersUseCase {}
class MockRemoveGroupMemberUseCase extends Mock implements RemoveGroupMemberUseCase {}
class MockJoinGroupUseCase extends Mock implements JoinGroupUseCase {}
class MockGetUserGroupInfoUseCase extends Mock implements GetUserGroupInfoUseCase {}

void main() {
  late AdminGroupBloc bloc;
  late MockGetAdminGroupUseCase mockGetAdminGroupUseCase;
  late MockRegenerateGroupCodeUseCase mockRegenerateGroupCodeUseCase;
  late MockGetGroupMembersUseCase mockGetGroupMembersUseCase;
  late MockRemoveGroupMemberUseCase mockRemoveGroupMemberUseCase;
  late MockJoinGroupUseCase mockJoinGroupUseCase;
  late MockGetUserGroupInfoUseCase mockGetUserGroupInfoUseCase;

  // Test data
  final tAdminGroup = AdminGroup(
    id: 1,
    adminUserId: 10,
    groupCode: 'ABC123',
    groupName: 'Test Group',
    isActive: true,
    membersCount: 5,
    createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
    updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
  );

  final tUpdatedAdminGroup = AdminGroup(
    id: 1,
    adminUserId: 10,
    groupCode: 'XYZ789',
    groupName: 'Test Group',
    isActive: true,
    membersCount: 5,
    createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
    updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
  );

  final tGroupMembers = [
    GroupMember(
      id: 1,
      name: 'John Doe',
      email: 'john@example.com',
      role: 'user',
      organizationName: 'Test Org',
      departmentName: 'IT',
      createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
    ),
    GroupMember(
      id: 2,
      name: 'Jane Smith',
      email: 'jane@example.com',
      role: 'user',
      organizationName: 'Test Org',
      departmentName: 'HR',
      createdAt: DateTime.parse('2024-01-02T00:00:00.000Z'),
    ),
  ];

  final tGroupInfo = GroupInfo(
    groupCode: 'ABC123',
    groupName: 'Test Group',
    adminName: 'Admin User',
    adminEmail: 'admin@example.com',
    membersCount: 5,
    joinedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
  );

  setUp(() {
    mockGetAdminGroupUseCase = MockGetAdminGroupUseCase();
    mockRegenerateGroupCodeUseCase = MockRegenerateGroupCodeUseCase();
    mockGetGroupMembersUseCase = MockGetGroupMembersUseCase();
    mockRemoveGroupMemberUseCase = MockRemoveGroupMemberUseCase();
    mockJoinGroupUseCase = MockJoinGroupUseCase();
    mockGetUserGroupInfoUseCase = MockGetUserGroupInfoUseCase();

    // Register fallback for GetGroupMembersParams
    registerFallbackValue(const GetGroupMembersParams());

    bloc = AdminGroupBloc(
      getAdminGroupUseCase: mockGetAdminGroupUseCase,
      regenerateGroupCodeUseCase: mockRegenerateGroupCodeUseCase,
      getGroupMembersUseCase: mockGetGroupMembersUseCase,
      removeGroupMemberUseCase: mockRemoveGroupMemberUseCase,
      joinGroupUseCase: mockJoinGroupUseCase,
      getUserGroupInfoUseCase: mockGetUserGroupInfoUseCase,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be AdminGroupInitial', () {
    expect(bloc.state, equals(const AdminGroupInitial()));
  });

  group('LoadAdminGroupEvent', () {
    test('should emit [AdminGroupLoading, AdminGroupLoaded] when successful', () async {
      // Arrange
      when(() => mockGetAdminGroupUseCase())
          .thenAnswer((_) async => Right(tAdminGroup));

      // Assert later
      final expected = [
        const AdminGroupLoading(),
        AdminGroupLoaded(adminGroup: tAdminGroup),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));

      // Act
      bloc.add(const LoadAdminGroupEvent());
    });

    test('should emit [AdminGroupLoading, AdminGroupError] when fails', () async {
      // Arrange
      const tFailure = UnauthorizedFailure('Authentication required');
      when(() => mockGetAdminGroupUseCase())
          .thenAnswer((_) async => const Left(tFailure));

      // Assert later
      final expected = [
        const AdminGroupLoading(),
        const AdminGroupError(errorMessage: 'Authentication required'),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));

      // Act
      bloc.add(const LoadAdminGroupEvent());
    });

    test('should emit formatted error message for network failure', () async {
      // Arrange
      const tFailure = NetworkFailure('Network error occurred');
      when(() => mockGetAdminGroupUseCase())
          .thenAnswer((_) async => const Left(tFailure));

      // Assert later
      final expected = [
        const AdminGroupLoading(),
        const AdminGroupError(errorMessage: 'Network error. Please check your internet connection.'),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));

      // Act
      bloc.add(const LoadAdminGroupEvent());
    });

    test('should preserve existing members when loading admin group', () async {
      // Arrange
      bloc.emit(GroupMembersLoaded(members: tGroupMembers));
      when(() => mockGetAdminGroupUseCase())
          .thenAnswer((_) async => Right(tAdminGroup));

      // Assert later
      final expected = [
        AdminGroupLoading(members: tGroupMembers),
        AdminGroupLoaded(adminGroup: tAdminGroup, members: tGroupMembers),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));

      // Act
      bloc.add(const LoadAdminGroupEvent());
    });
  });

  group('RegenerateGroupCodeEvent', () {
    test('should emit [AdminGroupLoading, GroupCodeRegenerated] when successful', () async {
      // Arrange
      when(() => mockRegenerateGroupCodeUseCase())
          .thenAnswer((_) async => Right(tUpdatedAdminGroup));

      // Assert later
      final expected = [
        const AdminGroupLoading(),
        GroupCodeRegenerated(adminGroup: tUpdatedAdminGroup),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));

      // Act
      bloc.add(const RegenerateGroupCodeEvent());
    });

    test('should emit [AdminGroupLoading, AdminGroupError] when fails', () async {
      // Arrange
      const tFailure = ServerFailure('Server error occurred');
      when(() => mockRegenerateGroupCodeUseCase())
          .thenAnswer((_) async => const Left(tFailure));

      // Assert later
      final expected = [
        const AdminGroupLoading(),
        const AdminGroupError(errorMessage: 'Server error. Please try again later.'),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));

      // Act
      bloc.add(const RegenerateGroupCodeEvent());
    });

    test('should preserve existing admin group and members when regenerating', () async {
      // Arrange
      bloc.emit(AdminGroupLoaded(adminGroup: tAdminGroup, members: tGroupMembers));
      when(() => mockRegenerateGroupCodeUseCase())
          .thenAnswer((_) async => Right(tUpdatedAdminGroup));

      // Assert later
      final expected = [
        AdminGroupLoading(adminGroup: tAdminGroup, members: tGroupMembers),
        GroupCodeRegenerated(adminGroup: tUpdatedAdminGroup, members: tGroupMembers),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));

      // Act
      bloc.add(const RegenerateGroupCodeEvent());
    });
  });

  group('LoadGroupMembersEvent', () {
    test('should emit [state with isLoadingMembers, GroupMembersLoaded] when successful', () async {
      // Arrange
      when(() => mockGetGroupMembersUseCase(any()))
          .thenAnswer((_) async => Right(tGroupMembers));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AdminGroupState>((state) => state.isLoadingMembers == true),
          predicate<GroupMembersLoaded>((state) => 
            state.members == tGroupMembers && 
            state.currentPage == 1 &&
            state.hasMoreMembers == false // Less than perPage
          ),
        ]),
      );

      // Act
      bloc.add(const LoadGroupMembersEvent(page: 1, perPage: 15));
    });

    test('should set hasMoreMembers to true when members count equals perPage', () async {
      // Arrange
      when(() => mockGetGroupMembersUseCase(any()))
          .thenAnswer((_) async => Right(tGroupMembers)); // 2 members

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AdminGroupState>((state) => state.isLoadingMembers == true),
          predicate<GroupMembersLoaded>((state) => 
            state.members == tGroupMembers && 
            state.hasMoreMembers == true // Equals perPage
          ),
        ]),
      );

      // Act
      bloc.add(const LoadGroupMembersEvent(page: 1, perPage: 2));
    });

    test('should append members when loadMore is true', () async {
      // Arrange
      final existingMembers = [tGroupMembers[0]];
      final newMembers = [tGroupMembers[1]];
      bloc.emit(GroupMembersLoaded(members: existingMembers, currentPage: 1));
      
      when(() => mockGetGroupMembersUseCase(any()))
          .thenAnswer((_) async => Right(newMembers));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AdminGroupState>((state) => state.isLoadingMoreMembers == true),
          predicate<GroupMembersLoaded>((state) => 
            state.members.length == 2 &&
            state.currentPage == 2
          ),
        ]),
      );

      // Act
      bloc.add(const LoadGroupMembersEvent(page: 2, perPage: 15, loadMore: true));
    });

    test('should replace members when loadMore is false', () async {
      // Arrange
      final existingMembers = [tGroupMembers[0]];
      bloc.emit(GroupMembersLoaded(members: existingMembers, currentPage: 1));
      
      when(() => mockGetGroupMembersUseCase(any()))
          .thenAnswer((_) async => Right(tGroupMembers));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AdminGroupState>((state) => state.isLoadingMembers == true),
          predicate<GroupMembersLoaded>((state) => 
            state.members == tGroupMembers &&
            state.currentPage == 1
          ),
        ]),
      );

      // Act
      bloc.add(const LoadGroupMembersEvent(page: 1, perPage: 15, loadMore: false));
    });

    test('should apply search and department filters', () async {
      // Arrange
      when(() => mockGetGroupMembersUseCase(any()))
          .thenAnswer((_) async => Right([tGroupMembers[0]]));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AdminGroupState>((state) => 
            state.isLoadingMembers == true &&
            state.searchTerm == 'John' &&
            state.departmentFilter == 'IT'
          ),
          predicate<GroupMembersLoaded>((state) => 
            state.members.length == 1 &&
            state.searchTerm == 'John' &&
            state.departmentFilter == 'IT'
          ),
        ]),
      );

      // Act
      bloc.add(const LoadGroupMembersEvent(
        page: 1, 
        perPage: 15, 
        search: 'John',
        department: 'IT',
      ));
    });

    test('should emit AdminGroupError when fails', () async {
      // Arrange
      const tFailure = AuthorizationFailure('Access denied');
      when(() => mockGetGroupMembersUseCase(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AdminGroupState>((state) => state.isLoadingMembers == true),
          const AdminGroupError(errorMessage: 'Access denied'),
        ]),
      );

      // Act
      bloc.add(const LoadGroupMembersEvent(page: 1, perPage: 15));
    });
  });

  group('RemoveGroupMemberEvent', () {
    test('should emit [AdminGroupLoading, MemberRemoved] when successful', () async {
      // Arrange
      bloc.emit(AdminGroupLoaded(adminGroup: tAdminGroup, members: tGroupMembers));
      when(() => mockRemoveGroupMemberUseCase(1))
          .thenAnswer((_) async => const Right(null));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          AdminGroupLoading(adminGroup: tAdminGroup, members: tGroupMembers),
          predicate<MemberRemoved>((state) => 
            state.members.length == 1 &&
            state.members.first.id == 2 &&
            state.adminGroup?.membersCount == 4
          ),
        ]),
      );

      // Act
      bloc.add(const RemoveGroupMemberEvent(userId: 1));
    });

    test('should update member count in admin group', () async {
      // Arrange
      bloc.emit(AdminGroupLoaded(adminGroup: tAdminGroup, members: tGroupMembers));
      when(() => mockRemoveGroupMemberUseCase(1))
          .thenAnswer((_) async => const Right(null));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          AdminGroupLoading(adminGroup: tAdminGroup, members: tGroupMembers),
          predicate<MemberRemoved>((state) => 
            state.adminGroup?.membersCount == 4 // 5 - 1
          ),
        ]),
      );

      // Act
      bloc.add(const RemoveGroupMemberEvent(userId: 1));
    });

    test('should emit AdminGroupError when fails', () async {
      // Arrange
      bloc.emit(AdminGroupLoaded(adminGroup: tAdminGroup, members: tGroupMembers));
      const tFailure = ValidationFailure('You cannot remove yourself from the group');
      when(() => mockRemoveGroupMemberUseCase(1))
          .thenAnswer((_) async => const Left(tFailure));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          AdminGroupLoading(adminGroup: tAdminGroup, members: tGroupMembers),
          AdminGroupError(
            errorMessage: 'You cannot remove yourself from the group',
            adminGroup: tAdminGroup,
            members: tGroupMembers,
          ),
        ]),
      );

      // Act
      bloc.add(const RemoveGroupMemberEvent(userId: 1));
    });

    test('should format "cannot remove self" error message', () async {
      // Arrange
      const tFailure = ValidationFailure('Cannot remove yourself');
      when(() => mockRemoveGroupMemberUseCase(1))
          .thenAnswer((_) async => const Left(tFailure));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          const AdminGroupLoading(),
          const AdminGroupError(errorMessage: 'You cannot remove yourself from the group'),
        ]),
      );

      // Act
      bloc.add(const RemoveGroupMemberEvent(userId: 1));
    });
  });

  group('JoinGroupEvent', () {
    test('should emit [AdminGroupLoading, GroupJoined] when successful', () async {
      // Arrange
      when(() => mockJoinGroupUseCase('ABC123'))
          .thenAnswer((_) async => Right(tGroupInfo));

      // Assert later
      final expected = [
        const AdminGroupLoading(),
        GroupJoined(userGroupInfo: tGroupInfo),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));

      // Act
      bloc.add(const JoinGroupEvent(groupCode: 'ABC123'));
    });

    test('should emit AdminGroupError with formatted message for invalid code', () async {
      // Arrange
      const tFailure = ValidationFailure('The selected group code is invalid');
      when(() => mockJoinGroupUseCase('INVALID'))
          .thenAnswer((_) async => const Left(tFailure));

      // Assert later
      final expected = [
        const AdminGroupLoading(),
        const AdminGroupError(errorMessage: 'The selected group code is invalid'),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));

      // Act
      bloc.add(const JoinGroupEvent(groupCode: 'INVALID'));
    });

    test('should emit AdminGroupError when already in group', () async {
      // Arrange
      const tFailure = ValidationFailure('You are already in a group');
      when(() => mockJoinGroupUseCase('ABC123'))
          .thenAnswer((_) async => const Left(tFailure));

      // Assert later
      final expected = [
        const AdminGroupLoading(),
        const AdminGroupError(errorMessage: 'You are already in a group'),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));

      // Act
      bloc.add(const JoinGroupEvent(groupCode: 'ABC123'));
    });

    test('should emit AdminGroupError when admin tries to join', () async {
      // Arrange
      const tFailure = ValidationFailure('Admins cannot join other groups');
      when(() => mockJoinGroupUseCase('ABC123'))
          .thenAnswer((_) async => const Left(tFailure));

      // Assert later
      final expected = [
        const AdminGroupLoading(),
        const AdminGroupError(errorMessage: 'Admins cannot join other groups'),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));

      // Act
      bloc.add(const JoinGroupEvent(groupCode: 'ABC123'));
    });

    test('should emit AdminGroupError for network failure', () async {
      // Arrange
      const tFailure = NetworkFailure('Connection timeout');
      when(() => mockJoinGroupUseCase('ABC123'))
          .thenAnswer((_) async => const Left(tFailure));

      // Assert later
      final expected = [
        const AdminGroupLoading(),
        const AdminGroupError(errorMessage: 'Network error. Please check your internet connection.'),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));

      // Act
      bloc.add(const JoinGroupEvent(groupCode: 'ABC123'));
    });
  });

  group('LoadUserGroupInfoEvent', () {
    test('should emit [AdminGroupLoading, UserGroupInfoLoaded] when successful', () async {
      // Arrange
      when(() => mockGetUserGroupInfoUseCase())
          .thenAnswer((_) async => Right(tGroupInfo));

      // Assert later
      final expected = [
        const AdminGroupLoading(),
        UserGroupInfoLoaded(userGroupInfo: tGroupInfo),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));

      // Act
      bloc.add(const LoadUserGroupInfoEvent());
    });

    test('should emit AdminGroupError when fails', () async {
      // Arrange
      const tFailure = NotFoundFailure('User is not in any group');
      when(() => mockGetUserGroupInfoUseCase())
          .thenAnswer((_) async => const Left(tFailure));

      // Assert later
      final expected = [
        const AdminGroupLoading(),
        const AdminGroupError(errorMessage: 'User is not in any group'),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));

      // Act
      bloc.add(const LoadUserGroupInfoEvent());
    });

    test('should emit AdminGroupError for unauthorized access', () async {
      // Arrange
      const tFailure = UnauthorizedFailure('Token expired');
      when(() => mockGetUserGroupInfoUseCase())
          .thenAnswer((_) async => const Left(tFailure));

      // Assert later
      final expected = [
        const AdminGroupLoading(),
        const AdminGroupError(errorMessage: 'Token expired'),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));

      // Act
      bloc.add(const LoadUserGroupInfoEvent());
    });
  });

  group('CopyGroupCodeEvent', () {
    setUp(() {
      // Set up the method channel for clipboard
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          return null;
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('should emit GroupCodeCopied when clipboard operation succeeds', () async {
      // Arrange
      bloc.emit(AdminGroupLoaded(adminGroup: tAdminGroup));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<GroupCodeCopied>((state) => 
            state.adminGroup == tAdminGroup &&
            state.successMessage == 'Group code copied to clipboard'
          ),
        ]),
      );

      // Act
      bloc.add(const CopyGroupCodeEvent(groupCode: 'ABC123'));
      
      // Wait for async operation
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('should preserve user group info when copying code', () async {
      // Arrange
      bloc.emit(UserGroupInfoLoaded(userGroupInfo: tGroupInfo));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<GroupCodeCopied>((state) => 
            state.userGroupInfo == tGroupInfo &&
            state.successMessage == 'Group code copied to clipboard'
          ),
        ]),
      );

      // Act
      bloc.add(const CopyGroupCodeEvent(groupCode: 'ABC123'));
      
      // Wait for async operation
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('should emit AdminGroupError when clipboard operation fails', () async {
      // Arrange
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          throw PlatformException(code: 'error', message: 'Clipboard error');
        }
        return null;
      });

      bloc.emit(AdminGroupLoaded(adminGroup: tAdminGroup));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AdminGroupError>((state) => 
            state.errorMessage == 'Failed to copy group code to clipboard' &&
            state.adminGroup == tAdminGroup
          ),
        ]),
      );

      // Act
      bloc.add(const CopyGroupCodeEvent(groupCode: 'ABC123'));
      
      // Wait for async operation
      await Future.delayed(const Duration(milliseconds: 100));
    });
  });

  group('Error Message Formatting', () {
    test('should format group code invalid error', () async {
      // Arrange
      const tFailure = ValidationFailure('invalid group code');
      when(() => mockJoinGroupUseCase('TEST'))
          .thenAnswer((_) async => const Left(tFailure));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          const AdminGroupLoading(),
          const AdminGroupError(errorMessage: 'The selected group code is invalid'),
        ]),
      );

      // Act
      bloc.add(const JoinGroupEvent(groupCode: 'TEST'));
    });

    test('should format group code required error', () async {
      // Arrange
      const tFailure = ValidationFailure('group code is required');
      when(() => mockJoinGroupUseCase(''))
          .thenAnswer((_) async => const Left(tFailure));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          const AdminGroupLoading(),
          const AdminGroupError(errorMessage: 'The group code field is required'),
        ]),
      );

      // Act
      bloc.add(const JoinGroupEvent(groupCode: ''));
    });

    test('should format member not found error', () async {
      // Arrange
      const tFailure = NotFoundFailure('user not found');
      when(() => mockRemoveGroupMemberUseCase(999))
          .thenAnswer((_) async => const Left(tFailure));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          const AdminGroupLoading(),
          const AdminGroupError(errorMessage: 'User not found or not in your group'),
        ]),
      );

      // Act
      bloc.add(const RemoveGroupMemberEvent(userId: 999));
    });

    test('should format rate limit error', () async {
      // Arrange
      const tFailure = ServerFailure('429 Too Many Requests');
      when(() => mockGetAdminGroupUseCase())
          .thenAnswer((_) async => const Left(tFailure));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          const AdminGroupLoading(),
          const AdminGroupError(errorMessage: 'Too many requests. Please wait a moment and try again.'),
        ]),
      );

      // Act
      bloc.add(const LoadAdminGroupEvent());
    });

    test('should return original message for unrecognized errors', () async {
      // Arrange
      const tFailure = ServerFailure('Some custom error message');
      when(() => mockGetAdminGroupUseCase())
          .thenAnswer((_) async => const Left(tFailure));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          const AdminGroupLoading(),
          const AdminGroupError(errorMessage: 'Some custom error message'),
        ]),
      );

      // Act
      bloc.add(const LoadAdminGroupEvent());
    });
  });

  group('State Transitions', () {
    test('should maintain state properties through transitions', () async {
      // Arrange
      bloc.emit(AdminGroupLoaded(
        adminGroup: tAdminGroup,
        members: tGroupMembers,
        currentPage: 2,
        hasMoreMembers: true,
        searchTerm: 'test',
        departmentFilter: 'IT',
      ));

      when(() => mockRegenerateGroupCodeUseCase())
          .thenAnswer((_) async => Right(tUpdatedAdminGroup));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AdminGroupLoading>((state) => 
            state.adminGroup == tAdminGroup &&
            state.members == tGroupMembers &&
            state.currentPage == 2 &&
            state.hasMoreMembers == true &&
            state.searchTerm == 'test' &&
            state.departmentFilter == 'IT'
          ),
          predicate<GroupCodeRegenerated>((state) => 
            state.adminGroup == tUpdatedAdminGroup &&
            state.members == tGroupMembers &&
            state.currentPage == 2 &&
            state.hasMoreMembers == true &&
            state.searchTerm == 'test' &&
            state.departmentFilter == 'IT'
          ),
        ]),
      );

      // Act
      bloc.add(const RegenerateGroupCodeEvent());
    });

    test('should clear loading states after success', () async {
      // Arrange
      when(() => mockGetAdminGroupUseCase())
          .thenAnswer((_) async => Right(tAdminGroup));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AdminGroupLoading>((state) => state.isLoading == true),
          predicate<AdminGroupLoaded>((state) => 
            state.isLoading == false &&
            state.isLoadingMembers == false &&
            state.isLoadingMoreMembers == false
          ),
        ]),
      );

      // Act
      bloc.add(const LoadAdminGroupEvent());
    });

    test('should clear loading states after error', () async {
      // Arrange
      const tFailure = ServerFailure('Error');
      when(() => mockGetAdminGroupUseCase())
          .thenAnswer((_) async => const Left(tFailure));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AdminGroupLoading>((state) => state.isLoading == true),
          predicate<AdminGroupError>((state) => 
            state.isLoading == false &&
            state.isLoadingMembers == false &&
            state.isLoadingMoreMembers == false
          ),
        ]),
      );

      // Act
      bloc.add(const LoadAdminGroupEvent());
    });
  });

  group('Success Messages', () {
    test('GroupCodeRegenerated should have success message', () async {
      // Arrange
      when(() => mockRegenerateGroupCodeUseCase())
          .thenAnswer((_) async => Right(tUpdatedAdminGroup));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          const AdminGroupLoading(),
          predicate<GroupCodeRegenerated>((state) => 
            state.successMessage == 'Group code regenerated successfully'
          ),
        ]),
      );

      // Act
      bloc.add(const RegenerateGroupCodeEvent());
    });

    test('MemberRemoved should have success message', () async {
      // Arrange
      bloc.emit(GroupMembersLoaded(members: tGroupMembers));
      when(() => mockRemoveGroupMemberUseCase(1))
          .thenAnswer((_) async => const Right(null));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          AdminGroupLoading(members: tGroupMembers),
          predicate<MemberRemoved>((state) => 
            state.successMessage == 'Member removed successfully'
          ),
        ]),
      );

      // Act
      bloc.add(const RemoveGroupMemberEvent(userId: 1));
    });

    test('GroupJoined should have success message', () async {
      // Arrange
      when(() => mockJoinGroupUseCase('ABC123'))
          .thenAnswer((_) async => Right(tGroupInfo));

      // Assert later
      expectLater(
        bloc.stream,
        emitsInOrder([
          const AdminGroupLoading(),
          predicate<GroupJoined>((state) => 
            state.successMessage == 'Successfully joined the group'
          ),
        ]),
      );

      // Act
      bloc.add(const JoinGroupEvent(groupCode: 'ABC123'));
    });
  });
}

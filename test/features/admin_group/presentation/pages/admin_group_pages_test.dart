import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finance_app/features/admin_group/presentation/pages/group_management_page.dart';
import 'package:finance_app/features/admin_group/presentation/pages/group_info_page.dart';
import 'package:finance_app/features/admin_group/presentation/pages/join_group_page.dart';
import 'package:finance_app/features/admin_group/presentation/bloc/admin_group_bloc.dart';
import 'package:finance_app/features/admin_group/presentation/bloc/admin_group_event.dart';
import 'package:finance_app/features/admin_group/presentation/bloc/admin_group_state.dart';
import 'package:finance_app/features/admin_group/domain/entities/admin_group.dart';
import 'package:finance_app/features/admin_group/domain/entities/group_member.dart';
import 'package:finance_app/features/admin_group/domain/entities/group_info.dart';
import 'package:finance_app/l10n/app_localizations.dart';

// Mock BLoC
class MockAdminGroupBloc extends Mock implements AdminGroupBloc {}

// Helper function to create a MaterialApp with BLoC and localization support
Widget createTestApp(Widget child, AdminGroupBloc bloc) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: const [
      Locale('ar'),
      Locale('en'),
    ],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: BlocProvider<AdminGroupBloc>.value(
      value: bloc,
      child: child,
    ),
    routes: {
      '/group-info': (context) => const Scaffold(body: Text('Group Info Page')),
      '/join-group': (context) => const Scaffold(body: Text('Join Group Page')),
    },
  );
}

void main() {
  late MockAdminGroupBloc mockBloc;

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
    mockBloc = MockAdminGroupBloc();
    
    // Default stream behavior
    when(() => mockBloc.stream).thenAnswer(
      (_) => Stream<AdminGroupState>.fromIterable([]),
    );
  });

  group('GroupManagementPage Widget Tests', () {
    testWidgets('should display loading indicator on initial load', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        const AdminGroupState(isLoading: true),
      );

      // Act
      await tester.pumpWidget(createTestApp(const GroupManagementPage(), mockBloc));
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should trigger LoadAdminGroupEvent and LoadGroupMembersEvent on init', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(const AdminGroupState());

      // Act
      await tester.pumpWidget(createTestApp(const GroupManagementPage(), mockBloc));
      await tester.pump();

      // Assert
      verify(() => mockBloc.add(LoadAdminGroupEvent())).called(1);
      verify(() => mockBloc.add(LoadGroupMembersEvent())).called(1);
    });

    testWidgets('should display group code and group information when loaded', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        AdminGroupState(
          adminGroup: tAdminGroup,
          members: tGroupMembers,
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(const GroupManagementPage(), mockBloc));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('ABC123'), findsOneWidget);
      expect(find.text('Test Group'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // Members count
    });

    testWidgets('should display member list when loaded', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        AdminGroupState(
          adminGroup: tAdminGroup,
          members: tGroupMembers,
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(const GroupManagementPage(), mockBloc));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
    });

    testWidgets('should show regenerate confirmation dialog when regenerate button is tapped', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        AdminGroupState(
          adminGroup: tAdminGroup,
          members: tGroupMembers,
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(const GroupManagementPage(), mockBloc));
      await tester.pumpAndSettle();

      // Find and tap regenerate button
      final regenerateButton = find.widgetWithText(OutlinedButton, 'Regenerate Code');
      expect(regenerateButton, findsOneWidget);
      await tester.tap(regenerateButton);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Regenerating will invalidate the old code. Continue?'), findsOneWidget);
    });

    testWidgets('should trigger RegenerateGroupCodeEvent when regenerate is confirmed', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        AdminGroupState(
          adminGroup: tAdminGroup,
          members: tGroupMembers,
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(const GroupManagementPage(), mockBloc));
      await tester.pumpAndSettle();

      // Tap regenerate button
      await tester.tap(find.widgetWithText(OutlinedButton, 'Regenerate Code'));
      await tester.pumpAndSettle();

      // Confirm in dialog
      final confirmButton = find.widgetWithText(ElevatedButton, 'Regenerate');
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockBloc.add(RegenerateGroupCodeEvent())).called(1);
    });

    testWidgets('should display error state when error occurs', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        const AdminGroupState(
          errorMessage: 'Failed to load group',
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(const GroupManagementPage(), mockBloc));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to load group'), findsOneWidget);
    });

    testWidgets('should display no group state when adminGroup is null', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        const AdminGroupState(
          adminGroup: null,
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(const GroupManagementPage(), mockBloc));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.group_off), findsOneWidget);
      expect(find.text('No group found'), findsOneWidget);
    });

    testWidgets('should refresh data when pull to refresh', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        AdminGroupState(
          adminGroup: tAdminGroup,
          members: tGroupMembers,
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(const GroupManagementPage(), mockBloc));
      await tester.pumpAndSettle();

      // Pull to refresh
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Assert - should trigger load events again
      verify(() => mockBloc.add(LoadAdminGroupEvent())).called(greaterThanOrEqualTo(2));
      verify(() => mockBloc.add(LoadGroupMembersEvent())).called(greaterThanOrEqualTo(2));
    });
  });

  group('GroupInfoPage Widget Tests', () {
    testWidgets('should display loading indicator on initial load', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        const AdminGroupState(isLoading: true),
      );

      // Act
      await tester.pumpWidget(createTestApp(const GroupInfoPage(), mockBloc));
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should trigger LoadUserGroupInfoEvent on init', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(const AdminGroupState());

      // Act
      await tester.pumpWidget(createTestApp(const GroupInfoPage(), mockBloc));
      await tester.pump();

      // Assert
      verify(() => mockBloc.add(LoadUserGroupInfoEvent())).called(1);
    });

    testWidgets('should display group information when loaded', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        AdminGroupState(
          userGroupInfo: tGroupInfo,
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(const GroupInfoPage(), mockBloc));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('ABC123'), findsOneWidget);
      expect(find.text('Test Group'), findsOneWidget);
      expect(find.text('Admin User'), findsOneWidget);
      expect(find.text('admin@example.com'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // Members count
    });

    testWidgets('should display help text about contacting admin', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        AdminGroupState(
          userGroupInfo: tGroupInfo,
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(const GroupInfoPage(), mockBloc));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Contact your admin to leave the group'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('should display not in group state when userGroupInfo is null', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        const AdminGroupState(
          userGroupInfo: null,
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(const GroupInfoPage(), mockBloc));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.group_off), findsOneWidget);
      expect(find.text('You are not in a group'), findsOneWidget);
    });

    testWidgets('should navigate to join group page when join button is tapped', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        const AdminGroupState(
          userGroupInfo: null,
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(const GroupInfoPage(), mockBloc));
      await tester.pumpAndSettle();

      // Tap join group button
      final joinButton = find.widgetWithText(ElevatedButton, 'Join Group');
      expect(joinButton, findsOneWidget);
      await tester.tap(joinButton);
      await tester.pumpAndSettle();

      // Assert - should navigate to join group page
      expect(find.text('Join Group Page'), findsOneWidget);
    });

    testWidgets('should display error state when error occurs', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        const AdminGroupState(
          errorMessage: 'Failed to load group info',
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(const GroupInfoPage(), mockBloc));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to load group info'), findsOneWidget);
    });

    testWidgets('should refresh data when pull to refresh', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        AdminGroupState(
          userGroupInfo: tGroupInfo,
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(const GroupInfoPage(), mockBloc));
      await tester.pumpAndSettle();

      // Pull to refresh
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Assert - should trigger load event again
      verify(() => mockBloc.add(LoadUserGroupInfoEvent())).called(greaterThanOrEqualTo(2));
    });
  });

  group('JoinGroupPage Widget Tests', () {
    testWidgets('should display page title and description', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(const AdminGroupState());

      // Act
      await tester.pumpWidget(createTestApp(const JoinGroupPage(), mockBloc));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Join Group'), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.group_add), findsAtLeastNWidgets(1));
    });

    testWidgets('should display join group form', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(const AdminGroupState());

      // Act
      await tester.pumpWidget(createTestApp(const JoinGroupPage(), mockBloc));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should display help text', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(const AdminGroupState());

      // Act
      await tester.pumpWidget(createTestApp(const JoinGroupPage(), mockBloc));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      expect(find.text('Need Help?'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsAtLeastNWidgets(1));
    });

    testWidgets('should trigger JoinGroupEvent when form is submitted', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(const AdminGroupState());

      // Act
      await tester.pumpWidget(createTestApp(const JoinGroupPage(), mockBloc));
      await tester.pumpAndSettle();

      // Enter group code
      await tester.enterText(find.byType(TextField), 'ABC123');
      await tester.pumpAndSettle();

      // Tap submit button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockBloc.add(JoinGroupEvent(groupCode: 'ABC123'))).called(1);
    });

    testWidgets('should navigate to group info page on successful join', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(const AdminGroupState());
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream<AdminGroupState>.fromIterable([
          GroupJoined(userGroupInfo: tGroupInfo),
        ]),
      );

      // Act
      await tester.pumpWidget(createTestApp(const JoinGroupPage(), mockBloc));
      await tester.pumpAndSettle();

      // Wait for state change
      await tester.pump();
      await tester.pumpAndSettle();

      // Assert - should navigate to group info page
      expect(find.text('Group Info Page'), findsOneWidget);
    });

    testWidgets('should display loading indicator when isLoading is true', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        const AdminGroupState(isLoading: true),
      );

      // Act
      await tester.pumpWidget(createTestApp(const JoinGroupPage(), mockBloc));
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error message when error occurs', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        const AdminGroupState(
          errorMessage: 'Invalid group code',
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(const JoinGroupPage(), mockBloc));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Invalid group code'), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.error_outline), findsAtLeastNWidgets(1));
    });
  });

  group('Navigation Tests', () {
    testWidgets('GroupManagementPage should have back button in app bar', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        AdminGroupState(
          adminGroup: tAdminGroup,
          members: tGroupMembers,
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(const GroupManagementPage(), mockBloc));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Group Management'), findsOneWidget);
    });

    testWidgets('GroupInfoPage should have back button in app bar', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        AdminGroupState(
          userGroupInfo: tGroupInfo,
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(const GroupInfoPage(), mockBloc));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('My Group'), findsOneWidget);
    });

    testWidgets('JoinGroupPage should have back button in app bar', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(const AdminGroupState());

      // Act
      await tester.pumpWidget(createTestApp(const JoinGroupPage(), mockBloc));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Join Group'), findsAtLeastNWidgets(1));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finance_app/core/widgets/role_based_widget.dart';
import 'package:finance_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:finance_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:finance_app/features/auth/domain/entities/user.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  final adminUser = User(
    id: 1,
    username: 'admin',
    email: 'admin@test.com',
    role: UserRole.admin,
    createdAt: DateTime.now(),
  );

  final regularUser = User(
    id: 2,
    username: 'user',
    email: 'user@test.com',
    role: UserRole.user,
    createdAt: DateTime.now(),
  );

  Widget createTestWidget({
    required AuthState authState,
    required Widget child,
    Widget? fallback,
    bool adminOnly = false,
    bool userOnly = false,
  }) {
    when(() => mockAuthBloc.state).thenReturn(authState);
    when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(authState));

    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: Scaffold(
          body: RoleBasedWidget(
            adminOnly: adminOnly,
            userOnly: userOnly,
            fallback: fallback,
            child: child,
          ),
        ),
      ),
    );
  }

  group('Role-Based Widget Visibility Tests', () {
    group('Admin-Only Widgets', () {
      testWidgets('should show admin-only widget to admin user', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            authState: AuthAuthenticated(user: adminUser),
            adminOnly: true,
            child: const Text('Admin Dashboard'),
          ),
        );

        expect(find.text('Admin Dashboard'), findsOneWidget);
      });

      testWidgets('should hide admin-only widget from regular user', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            authState: AuthAuthenticated(user: regularUser),
            adminOnly: true,
            child: const Text('Admin Dashboard'),
          ),
        );

        expect(find.text('Admin Dashboard'), findsNothing);
      });

      testWidgets('should show fallback to regular user for admin-only widget', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            authState: AuthAuthenticated(user: regularUser),
            adminOnly: true,
            child: const Text('Admin Dashboard'),
            fallback: const Text('Access Denied'),
          ),
        );

        expect(find.text('Admin Dashboard'), findsNothing);
        expect(find.text('Access Denied'), findsOneWidget);
      });

      testWidgets('should hide admin-only widget when unauthenticated', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            authState: const AuthUnauthenticated(),
            adminOnly: true,
            child: const Text('Admin Dashboard'),
          ),
        );

        expect(find.text('Admin Dashboard'), findsNothing);
      });
    });

    group('User-Only Widgets', () {
      testWidgets('should show user-only widget to regular user', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            authState: AuthAuthenticated(user: regularUser),
            userOnly: true,
            child: const Text('User Profile'),
          ),
        );

        expect(find.text('User Profile'), findsOneWidget);
      });

      testWidgets('should hide user-only widget from admin', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            authState: AuthAuthenticated(user: adminUser),
            userOnly: true,
            child: const Text('User Profile'),
          ),
        );

        expect(find.text('User Profile'), findsNothing);
      });

      testWidgets('should show fallback to admin for user-only widget', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            authState: AuthAuthenticated(user: adminUser),
            userOnly: true,
            child: const Text('User Profile'),
            fallback: const Text('Admin View'),
          ),
        );

        expect(find.text('User Profile'), findsNothing);
        expect(find.text('Admin View'), findsOneWidget);
      });
    });

    group('Navigation Menu Items', () {
      testWidgets('should show admin menu items only to admin', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(user: adminUser));
        when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(AuthAuthenticated(user: adminUser)));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: Scaffold(
                body: ListView(
                  children: [
                    const ListTile(title: Text('Home')),
                    const ListTile(title: Text('Expenses')),
                    RoleBasedWidget.adminOnly(
                      child: const ListTile(
                        leading: Icon(Icons.admin_panel_settings),
                        title: Text('Admin Dashboard'),
                      ),
                    ),
                    RoleBasedWidget.adminOnly(
                      child: const ListTile(
                        leading: Icon(Icons.people),
                        title: Text('User Management'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Admin Dashboard'), findsOneWidget);
        expect(find.text('User Management'), findsOneWidget);
        expect(find.byIcon(Icons.admin_panel_settings), findsOneWidget);
        expect(find.byIcon(Icons.people), findsOneWidget);
      });

      testWidgets('should hide admin menu items from regular user', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(user: regularUser));
        when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(AuthAuthenticated(user: regularUser)));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: Scaffold(
                body: ListView(
                  children: [
                    const ListTile(title: Text('Home')),
                    const ListTile(title: Text('Expenses')),
                    RoleBasedWidget.adminOnly(
                      child: const ListTile(
                        leading: Icon(Icons.admin_panel_settings),
                        title: Text('Admin Dashboard'),
                      ),
                    ),
                    RoleBasedWidget.adminOnly(
                      child: const ListTile(
                        leading: Icon(Icons.people),
                        title: Text('User Management'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Expenses'), findsOneWidget);
        expect(find.text('Admin Dashboard'), findsNothing);
        expect(find.text('User Management'), findsNothing);
      });
    });

    group('Action Buttons', () {
      testWidgets('should show delete button only to admin', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            authState: AuthAuthenticated(user: adminUser),
            adminOnly: true,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.delete),
              label: const Text('Delete User'),
            ),
          ),
        );

        expect(find.text('Delete User'), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);
      });

      testWidgets('should hide delete button from regular user', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            authState: AuthAuthenticated(user: regularUser),
            adminOnly: true,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.delete),
              label: const Text('Delete User'),
            ),
          ),
        );

        expect(find.text('Delete User'), findsNothing);
        expect(find.byIcon(Icons.delete), findsNothing);
      });

      testWidgets('should show edit button to both admin and user', (tester) async {
        // Test with admin
        await tester.pumpWidget(
          createTestWidget(
            authState: AuthAuthenticated(user: adminUser),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
            ),
          ),
        );

        expect(find.text('Edit'), findsOneWidget);

        // Test with regular user
        await tester.pumpWidget(
          createTestWidget(
            authState: AuthAuthenticated(user: regularUser),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
            ),
          ),
        );

        expect(find.text('Edit'), findsOneWidget);
      });
    });

    group('Statistics and Reports', () {
      testWidgets('should show system-wide statistics only to admin', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(user: adminUser));
        when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(AuthAuthenticated(user: adminUser)));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: Scaffold(
                body: Column(
                  children: [
                    const Card(
                      child: ListTile(
                        title: Text('My Expenses'),
                        subtitle: Text('\$500'),
                      ),
                    ),
                    RoleBasedWidget.adminOnly(
                      child: const Card(
                        child: ListTile(
                          title: Text('Total System Expenses'),
                          subtitle: Text('\$50,000'),
                        ),
                      ),
                    ),
                    RoleBasedWidget.adminOnly(
                      child: const Card(
                        child: ListTile(
                          title: Text('Total Users'),
                          subtitle: Text('150'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('My Expenses'), findsOneWidget);
        expect(find.text('Total System Expenses'), findsOneWidget);
        expect(find.text('Total Users'), findsOneWidget);
      });

      testWidgets('should show only personal statistics to regular user', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(user: regularUser));
        when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(AuthAuthenticated(user: regularUser)));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: Scaffold(
                body: Column(
                  children: [
                    const Card(
                      child: ListTile(
                        title: Text('My Expenses'),
                        subtitle: Text('\$500'),
                      ),
                    ),
                    RoleBasedWidget.adminOnly(
                      child: const Card(
                        child: ListTile(
                          title: Text('Total System Expenses'),
                          subtitle: Text('\$50,000'),
                        ),
                      ),
                    ),
                    RoleBasedWidget.adminOnly(
                      child: const Card(
                        child: ListTile(
                          title: Text('Total Users'),
                          subtitle: Text('150'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('My Expenses'), findsOneWidget);
        expect(find.text('Total System Expenses'), findsNothing);
        expect(find.text('Total Users'), findsNothing);
      });
    });

    group('Settings and Configuration', () {
      testWidgets('should show system settings only to admin', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(user: adminUser));
        when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(AuthAuthenticated(user: adminUser)));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: Scaffold(
                body: ListView(
                  children: [
                    const ListTile(title: Text('Profile Settings')),
                    const ListTile(title: Text('Notification Settings')),
                    RoleBasedWidget.adminOnly(
                      child: const ListTile(
                        leading: Icon(Icons.settings),
                        title: Text('System Configuration'),
                      ),
                    ),
                    RoleBasedWidget.adminOnly(
                      child: const ListTile(
                        leading: Icon(Icons.security),
                        title: Text('Security Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('System Configuration'), findsOneWidget);
        expect(find.text('Security Settings'), findsOneWidget);
      });
    });

    group('Conditional UI Elements', () {
      testWidgets('should show admin content to admin user', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(user: adminUser));
        when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(AuthAuthenticated(user: adminUser)));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: Scaffold(
                body: Column(
                  children: [
                    RoleBasedWidget.adminOnly(
                      fallback: const Text('Welcome, User'),
                      child: const Text('Welcome, Administrator'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Welcome, Administrator'), findsOneWidget);
        expect(find.text('Welcome, User'), findsNothing);
      });

      testWidgets('should show user content to regular user', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(user: regularUser));
        when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(AuthAuthenticated(user: regularUser)));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: Scaffold(
                body: Column(
                  children: [
                    RoleBasedWidget.adminOnly(
                      fallback: const Text('Welcome, User'),
                      child: const Text('Welcome, Administrator'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Welcome, Administrator'), findsNothing);
        expect(find.text('Welcome, User'), findsOneWidget);
      });

      testWidgets('should handle multiple role-based widgets in same screen', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(user: adminUser));
        when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(AuthAuthenticated(user: adminUser)));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: Scaffold(
                body: Column(
                  children: [
                    RoleBasedWidget.adminOnly(
                      child: const Text('Admin Feature 1'),
                    ),
                    const Text('Common Feature'),
                    RoleBasedWidget.adminOnly(
                      child: const Text('Admin Feature 2'),
                    ),
                    RoleBasedWidget.userOnly(
                      child: const Text('User Feature'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Admin Feature 1'), findsOneWidget);
        expect(find.text('Common Feature'), findsOneWidget);
        expect(find.text('Admin Feature 2'), findsOneWidget);
        expect(find.text('User Feature'), findsNothing);
      });
    });

    group('Error States', () {
      testWidgets('should hide protected content when auth error occurs', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            authState: const AuthError(message: 'Authentication failed'),
            adminOnly: true,
            child: const Text('Admin Dashboard'),
            fallback: const Text('Please login'),
          ),
        );

        expect(find.text('Admin Dashboard'), findsNothing);
        expect(find.text('Please login'), findsOneWidget);
      });

      testWidgets('should hide protected content during loading', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            authState: const AuthLoading(),
            adminOnly: true,
            child: const Text('Admin Dashboard'),
          ),
        );

        expect(find.text('Admin Dashboard'), findsNothing);
      });
    });

    group('Dynamic Role Changes', () {
      testWidgets('should show user content initially for regular user', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(user: regularUser));
        when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(AuthAuthenticated(user: regularUser)));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: Scaffold(
                body: RoleBasedWidget.adminOnly(
                  fallback: const Text('User Content'),
                  child: const Text('Admin Content'),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('User Content'), findsOneWidget);
        expect(find.text('Admin Content'), findsNothing);
      });

      testWidgets('should show admin content for admin user', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(user: adminUser));
        when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(AuthAuthenticated(user: adminUser)));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: Scaffold(
                body: RoleBasedWidget.adminOnly(
                  fallback: const Text('User Content'),
                  child: const Text('Admin Content'),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Admin Content'), findsOneWidget);
        expect(find.text('User Content'), findsNothing);
      });
    });
  });
}

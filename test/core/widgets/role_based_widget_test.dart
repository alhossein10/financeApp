import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/widgets/role_based_widget.dart';
import 'package:finance_app/features/auth/domain/entities/user.dart';

void main() {
  group('RoleBasedWidget', () {
    Widget createTestWidget({
      required User? user,
      required Widget child,
      Widget? fallback,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: RoleBasedWidget(
            user: user,
            requiredRole: UserRole.admin,
            fallback: fallback,
            child: child,
          ),
        ),
      );
    }

    final adminUser = User(
      id: 1,
      email: 'admin@test.com',
      name: 'Admin User',
      role: UserRole.admin,
      createdAt: DateTime.now(),
    );

    final regularUser = User(
      id: 2,
      email: 'user@test.com',
      name: 'Regular User',
      role: UserRole.user,
      createdAt: DateTime.now(),
    );

    group('Admin Role Requirements', () {
      testWidgets('should show child widget when user is admin', (tester) async {
        // Arrange
        const childText = 'Admin Content';
        final widget = createTestWidget(
          user: adminUser,
          child: const Text(childText),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text(childText), findsOneWidget);
      });

      testWidgets('should hide child widget when user is not admin', (tester) async {
        // Arrange
        const childText = 'Admin Content';
        final widget = createTestWidget(
          user: regularUser,
          child: const Text(childText),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text(childText), findsNothing);
      });

      testWidgets('should show fallback when user is not admin', (tester) async {
        // Arrange
        const childText = 'Admin Content';
        const fallbackText = 'Access Denied';
        final widget = createTestWidget(
          user: regularUser,
          child: const Text(childText),
          fallback: const Text(fallbackText),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text(childText), findsNothing);
        expect(find.text(fallbackText), findsOneWidget);
      });

      testWidgets('should hide content when user is null', (tester) async {
        // Arrange
        const childText = 'Admin Content';
        final widget = createTestWidget(
          user: null,
          child: const Text(childText),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text(childText), findsNothing);
      });
    });

    group('User Role Requirements', () {
      testWidgets('should show child widget when user has user role', (tester) async {
        // Arrange
        const childText = 'User Content';
        final widget = MaterialApp(
          home: Scaffold(
            body: RoleBasedWidget(
              user: regularUser,
              requiredRole: UserRole.user,
              child: const Text(childText),
            ),
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text(childText), findsOneWidget);
      });

      testWidgets('should show child widget when admin accesses user content', (tester) async {
        // Arrange
        const childText = 'User Content';
        final widget = MaterialApp(
          home: Scaffold(
            body: RoleBasedWidget(
              user: adminUser,
              requiredRole: UserRole.user,
              child: const Text(childText),
            ),
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text(childText), findsOneWidget);
      });
    });

    group('Multiple Role-Based Widgets', () {
      testWidgets('should handle multiple role-based widgets correctly', (tester) async {
        // Arrange
        final widget = MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RoleBasedWidget(
                  user: adminUser,
                  requiredRole: UserRole.admin,
                  child: const Text('Admin Only'),
                ),
                RoleBasedWidget(
                  user: adminUser,
                  requiredRole: UserRole.user,
                  child: const Text('All Users'),
                ),
              ],
            ),
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text('Admin Only'), findsOneWidget);
        expect(find.text('All Users'), findsOneWidget);
      });

      testWidgets('should show only appropriate content for regular user', (tester) async {
        // Arrange
        final widget = MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RoleBasedWidget(
                  user: regularUser,
                  requiredRole: UserRole.admin,
                  child: const Text('Admin Only'),
                ),
                RoleBasedWidget(
                  user: regularUser,
                  requiredRole: UserRole.user,
                  child: const Text('All Users'),
                ),
              ],
            ),
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text('Admin Only'), findsNothing);
        expect(find.text('All Users'), findsOneWidget);
      });
    });

    group('Conditional Rendering', () {
      testWidgets('should render complex widgets based on role', (tester) async {
        // Arrange
        final widget = MaterialApp(
          home: Scaffold(
            body: RoleBasedWidget(
              user: adminUser,
              requiredRole: UserRole.admin,
              child: Column(
                children: const [
                  Text('Admin Dashboard'),
                  Text('User Management'),
                  Text('System Settings'),
                ],
              ),
            ),
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text('Admin Dashboard'), findsOneWidget);
        expect(find.text('User Management'), findsOneWidget);
        expect(find.text('System Settings'), findsOneWidget);
      });

      testWidgets('should handle buttons with role restrictions', (tester) async {
        // Arrange
        var buttonPressed = false;
        final widget = MaterialApp(
          home: Scaffold(
            body: RoleBasedWidget(
              user: adminUser,
              requiredRole: UserRole.admin,
              child: ElevatedButton(
                onPressed: () => buttonPressed = true,
                child: const Text('Admin Action'),
              ),
            ),
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.tap(find.text('Admin Action'));
        await tester.pump();

        // Assert
        expect(buttonPressed, true);
      });

      testWidgets('should not render buttons for unauthorized users', (tester) async {
        // Arrange
        var buttonPressed = false;
        final widget = MaterialApp(
          home: Scaffold(
            body: RoleBasedWidget(
              user: regularUser,
              requiredRole: UserRole.admin,
              child: ElevatedButton(
                onPressed: () => buttonPressed = true,
                child: const Text('Admin Action'),
              ),
            ),
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text('Admin Action'), findsNothing);
        expect(buttonPressed, false);
      });
    });

    group('Fallback Behavior', () {
      testWidgets('should show default empty container when no fallback provided', (tester) async {
        // Arrange
        final widget = createTestWidget(
          user: regularUser,
          child: const Text('Admin Content'),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text('Admin Content'), findsNothing);
        expect(find.byType(SizedBox), findsWidgets);
      });

      testWidgets('should show custom fallback widget', (tester) async {
        // Arrange
        final widget = createTestWidget(
          user: regularUser,
          child: const Text('Admin Content'),
          fallback: const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('You need admin privileges'),
            ),
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text('Admin Content'), findsNothing);
        expect(find.text('You need admin privileges'), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle null user gracefully', (tester) async {
        // Arrange
        final widget = createTestWidget(
          user: null,
          child: const Text('Protected Content'),
          fallback: const Text('Please login'),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text('Protected Content'), findsNothing);
        expect(find.text('Please login'), findsOneWidget);
      });

      testWidgets('should update when user changes', (tester) async {
        // Arrange
        User? currentUser = regularUser;
        final widget = StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    RoleBasedWidget(
                      user: currentUser,
                      requiredRole: UserRole.admin,
                      fallback: const Text('User Content'),
                      child: const Text('Admin Content'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentUser = adminUser;
                        });
                      },
                      child: const Text('Promote to Admin'),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        // Act - Initial state
        await tester.pumpWidget(widget);
        expect(find.text('User Content'), findsOneWidget);
        expect(find.text('Admin Content'), findsNothing);

        // Act - Promote user
        await tester.tap(find.text('Promote to Admin'));
        await tester.pump();

        // Assert - Should now show admin content
        expect(find.text('Admin Content'), findsOneWidget);
        expect(find.text('User Content'), findsNothing);
      });
    });
  });
}

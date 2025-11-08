import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:finance_app/features/admin_group/presentation/widgets/group_code_display.dart';
import 'package:finance_app/features/admin_group/presentation/widgets/group_member_card.dart';
import 'package:finance_app/features/admin_group/presentation/widgets/group_member_list.dart';
import 'package:finance_app/features/admin_group/presentation/widgets/group_code_input.dart';
import 'package:finance_app/features/admin_group/presentation/widgets/join_group_form.dart';
import 'package:finance_app/features/admin_group/domain/entities/group_member.dart';
import 'package:finance_app/l10n/app_localizations.dart';

/// Helper function to create a MaterialApp with localization support for testing
Widget createTestApp(Widget child) {
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
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  group('GroupCodeDisplay Widget Tests', () {
    testWidgets('should display group code prominently', (tester) async {
      const testCode = 'ABC123';

      await tester.pumpWidget(
        createTestApp(const GroupCodeDisplay(groupCode: testCode)),
      );
      await tester.pumpAndSettle();

      // Verify group code is displayed in uppercase
      expect(find.text(testCode.toUpperCase()), findsOneWidget);
    });

    testWidgets('should display copy button when showCopyButton is true', (tester) async {
      const testCode = 'ABC123';

      await tester.pumpWidget(
        createTestApp(
          const GroupCodeDisplay(
            groupCode: testCode,
            showCopyButton: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify copy button is displayed
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('should hide copy button when showCopyButton is false', (tester) async {
      const testCode = 'ABC123';

      await tester.pumpWidget(
        createTestApp(
          const GroupCodeDisplay(
            groupCode: testCode,
            showCopyButton: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify copy button is not displayed
      expect(find.byIcon(Icons.copy), findsNothing);
    });

  });

  group('GroupMemberCard Widget Tests', () {
    final testMember = GroupMember(
      id: 1,
      name: 'John Doe',
      email: 'john@example.com',
      role: 'user',
      organizationName: 'Test Org',
      departmentName: 'Engineering',
      createdAt: DateTime.now(),
    );

    testWidgets('should display member name and email', (tester) async {
      await tester.pumpWidget(
        createTestApp(GroupMemberCard(member: testMember)),
      );
      await tester.pumpAndSettle();

      // Verify name and email are displayed
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
    });

    testWidgets('should display member initials in avatar', (tester) async {
      await tester.pumpWidget(
        createTestApp(GroupMemberCard(member: testMember)),
      );
      await tester.pumpAndSettle();

      // Verify initials are displayed (JD for John Doe)
      expect(find.text('JD'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('should display department and organization when available', (tester) async {
      await tester.pumpWidget(
        createTestApp(GroupMemberCard(member: testMember)),
      );
      await tester.pumpAndSettle();

      // Verify department and organization are displayed
      expect(find.text('Engineering'), findsOneWidget);
      expect(find.text('Test Org'), findsOneWidget);
    });

    testWidgets('should display remove button when showRemoveButton is true', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          GroupMemberCard(
            member: testMember,
            showRemoveButton: true,
            onRemove: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify remove button is displayed
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
    });

    testWidgets('should hide remove button when showRemoveButton is false', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          GroupMemberCard(
            member: testMember,
            showRemoveButton: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify remove button is not displayed
      expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
    });

    testWidgets('should show current user indicator when isCurrentUser is true', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          GroupMemberCard(
            member: testMember,
            isCurrentUser: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify person icon is displayed for current user
      expect(find.byIcon(Icons.person), findsOneWidget);
      // Remove button should not be shown for current user
      expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
    });

    testWidgets('should show confirmation dialog when remove button is tapped', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          GroupMemberCard(
            member: testMember,
            showRemoveButton: true,
            onRemove: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap remove button
      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();

      // Verify confirmation dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('should call onRemove when removal is confirmed', (tester) async {
      bool removeCalled = false;

      await tester.pumpWidget(
        createTestApp(
          GroupMemberCard(
            member: testMember,
            showRemoveButton: true,
            onRemove: () {
              removeCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap remove button
      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();

      // Find and tap confirm button in dialog
      final confirmButton = find.byType(TextButton).last;
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Verify onRemove was called
      expect(removeCalled, true);
    });
  });

  group('GroupMemberList Widget Tests', () {
    final testMembers = [
      GroupMember(
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        role: 'user',
        departmentName: 'Engineering',
        createdAt: DateTime.now(),
      ),
      GroupMember(
        id: 2,
        name: 'Jane Smith',
        email: 'jane@example.com',
        role: 'user',
        departmentName: 'Marketing',
        createdAt: DateTime.now(),
      ),
      GroupMember(
        id: 3,
        name: 'Bob Johnson',
        email: 'bob@example.com',
        role: 'admin',
        departmentName: 'Engineering',
        createdAt: DateTime.now(),
      ),
    ];

    testWidgets('should display all members in the list', (tester) async {
      await tester.pumpWidget(
        createTestApp(GroupMemberList(members: testMembers)),
      );
      await tester.pumpAndSettle();

      // Verify all members are displayed
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Bob Johnson'), findsOneWidget);
    });

    testWidgets('should display search field', (tester) async {
      await tester.pumpWidget(
        createTestApp(GroupMemberList(members: testMembers)),
      );
      await tester.pumpAndSettle();

      // Verify search field is displayed
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should filter members by search query', (tester) async {
      await tester.pumpWidget(
        createTestApp(GroupMemberList(members: testMembers)),
      );
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'John');
      await tester.pumpAndSettle();

      // Verify John Doe is displayed
      expect(find.text('John Doe'), findsOneWidget);
      // Jane Smith should not be visible (search filters her out)
      expect(find.text('Jane Smith'), findsNothing);
    });
  });

  group('GroupCodeInput Widget Tests', () {
    testWidgets('should display input field', (tester) async {
      await tester.pumpWidget(
        createTestApp(const GroupCodeInput()),
      );
      await tester.pumpAndSettle();

      // Verify input field is displayed
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should convert input to uppercase', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        createTestApp(GroupCodeInput(controller: controller)),
      );
      await tester.pumpAndSettle();

      // Enter lowercase text
      await tester.enterText(find.byType(TextField), 'abc123');
      await tester.pumpAndSettle();

      // Verify text is converted to uppercase
      expect(controller.text, 'ABC123');
    });

    testWidgets('should limit input to 6 characters', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        createTestApp(GroupCodeInput(controller: controller)),
      );
      await tester.pumpAndSettle();

      // Try to enter more than 6 characters
      await tester.enterText(find.byType(TextField), 'ABCDEFGH');
      await tester.pumpAndSettle();

      // Verify only 6 characters are accepted
      expect(controller.text.length, 6);
    });

    testWidgets('should display error text when provided', (tester) async {
      const errorMessage = 'Invalid group code';

      await tester.pumpWidget(
        createTestApp(
          const GroupCodeInput(
            errorText: errorMessage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('should disable input when enabled is false', (tester) async {
      await tester.pumpWidget(
        createTestApp(const GroupCodeInput(enabled: false)),
      );
      await tester.pumpAndSettle();

      // Verify input field is disabled
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, false);
    });

    testWidgets('should call onChanged callback when text changes', (tester) async {
      String? changedValue;

      await tester.pumpWidget(
        createTestApp(
          GroupCodeInput(
            onChanged: (value) {
              changedValue = value;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter text
      await tester.enterText(find.byType(TextField), 'ABC123');
      await tester.pumpAndSettle();

      // Verify callback was called with correct value
      expect(changedValue, 'ABC123');
    });
  });

  group('JoinGroupForm Widget Tests', () {
    testWidgets('should display GroupCodeInput widget', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          JoinGroupForm(
            onSubmit: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify GroupCodeInput is displayed
      expect(find.byType(GroupCodeInput), findsOneWidget);
    });

    testWidgets('should display submit button', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          JoinGroupForm(
            onSubmit: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify submit button is displayed
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byIcon(Icons.group_add), findsOneWidget);
    });

    testWidgets('should call onSubmit with valid code', (tester) async {
      String? submittedCode;

      await tester.pumpWidget(
        createTestApp(
          JoinGroupForm(
            onSubmit: (code) {
              submittedCode = code;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter valid code
      await tester.enterText(find.byType(TextField), 'ABC123');
      await tester.pumpAndSettle();

      // Tap submit button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify onSubmit was called with correct code
      expect(submittedCode, 'ABC123');
    });

    testWidgets('should not submit with invalid code', (tester) async {
      String? submittedCode;

      await tester.pumpWidget(
        createTestApp(
          JoinGroupForm(
            onSubmit: (code) {
              submittedCode = code;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter invalid code (too short)
      await tester.enterText(find.byType(TextField), 'ABC');
      await tester.pumpAndSettle();

      // Tap submit button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify onSubmit was not called
      expect(submittedCode, null);
    });

    testWidgets('should show loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          JoinGroupForm(
            onSubmit: (_) {},
            isLoading: true,
          ),
        ),
      );
      await tester.pump();

      // Verify loading indicator is displayed in button
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should disable submit button when isLoading is true', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          JoinGroupForm(
            onSubmit: (_) {},
            isLoading: true,
          ),
        ),
      );
      await tester.pump();

      // Verify button is disabled
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, null);
    });

    testWidgets('should display error message when provided', (tester) async {
      const errorMessage = 'Invalid group code';

      await tester.pumpWidget(
        createTestApp(
          JoinGroupForm(
            onSubmit: (_) {},
            errorMessage: errorMessage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.text(errorMessage), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}

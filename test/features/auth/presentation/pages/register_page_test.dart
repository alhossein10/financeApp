import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:finance_app/features/auth/presentation/pages/register_page.dart';
import 'package:finance_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:finance_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:finance_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:finance_app/features/auth/domain/entities/user.dart';
import 'package:finance_app/core/config/flavor_config.dart';
import 'package:finance_app/features/admin_group/presentation/widgets/group_code_input.dart';
import 'package:finance_app/features/auth/presentation/widgets/admin_registration_success_dialog.dart';
import 'package:finance_app/l10n/app_localizations.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
    when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(const AuthInitial()));
  });

  Widget createWidgetUnderTest({bool isAdmin = false}) {
    // Set flavor config for testing
    FlavorConfig.initialize(isAdmin ? AppFlavor.admin : AppFlavor.user);
    
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const RegisterPage(),
      ),
    );
  }

  group('RegisterPage Widget Tests', () {
    testWidgets('should display all required form fields for user registration', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isAdmin: false));

      // Verify username, email, password, confirm password, org name, dept name fields exist
      expect(find.byType(TextFormField), findsNWidgets(6));
      
      // Verify group code input exists for users
      expect(find.byType(GroupCodeInput), findsOneWidget);
      
      // Verify register button exists
      expect(find.text('Create Account'), findsAtLeastNWidgets(1));
      
      // Verify login link exists
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('should display all required form fields for admin registration', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isAdmin: true));

      // Verify username, email, password, confirm password, org name, dept name fields exist
      expect(find.byType(TextFormField), findsNWidgets(6));
      
      // Verify group code input does NOT exist for admins
      expect(find.byType(GroupCodeInput), findsNothing);
      
      // Verify register button exists
      expect(find.text('Create Account'), findsAtLeastNWidgets(1));
    });

    testWidgets('should show validation error for empty username', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Find and tap register button without entering data
      final registerButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Verify validation error is shown
      expect(find.text('Username is required'), findsOneWidget);
    });

    testWidgets('should show validation error for short username', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter short username
      await tester.enterText(find.byType(TextFormField).at(0), 'ab');
      
      // Tap register button
      final registerButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Verify validation error
      expect(find.text('Username must be at least 3 characters'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid email', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter valid username but invalid email
      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'invalid-email');
      
      // Tap register button
      final registerButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Verify validation error
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('should show validation error for weak password', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter valid username and email but weak password
      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'weak');
      
      // Tap register button
      final registerButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Verify validation error for password strength
      expect(find.textContaining('at least 8 characters'), findsOneWidget);
    });

    testWidgets('should show validation error for mismatched passwords', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter valid data but mismatched passwords
      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password456');
      
      // Tap register button
      final registerButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Verify validation error
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('should toggle password visibility for both password fields', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Find visibility toggle buttons (should be 2)
      final visibilityButtons = find.byIcon(Icons.visibility_off);
      expect(visibilityButtons, findsNWidgets(2));

      // Tap first visibility button (password field)
      await tester.tap(visibilityButtons.first);
      await tester.pump();

      // Verify icon changed for first field
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Tap second visibility button (confirm password field)
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      // Verify both icons changed
      expect(find.byIcon(Icons.visibility), findsNWidgets(2));
    });

    testWidgets('should dispatch register event with valid data', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter valid registration data
      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password123');
      await tester.pump();

      // Tap register button
      final registerButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.tap(registerButton);
      await tester.pump();

      // Verify register event was dispatched
      verify(() => mockAuthBloc.add(any(that: isA<AuthRegisterRequested>()))).called(1);
    });

    testWidgets('should show loading indicator when state is AuthLoading', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthLoading());
      when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(const AuthLoading()));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Verify register button is disabled
      final registerButton = find.widgetWithText(ElevatedButton, 'Create Account');
      final button = tester.widget<ElevatedButton>(registerButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('should show error snackbar when state is AuthError', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
      when(() => mockAuthBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const AuthInitial(),
          const AuthError(message: 'Email already exists'),
        ]),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify error message is shown in snackbar
      expect(find.text('Email already exists'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('should show success snackbar when registration succeeds', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
      when(() => mockAuthBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const AuthInitial(),
          AuthState(
            status: AuthStatus.authenticated,
            user: User(
              id: 1,
              username: 'testuser',
              email: 'test@example.com',
              role: UserRole.user,
              createdAt: DateTime.now(),
              organizationId: 1,
            ),
          ),
        ]),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify success message is shown
      expect(find.text('Account created successfully!'), findsOneWidget);
    });

    testWidgets('should display password requirements hint', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Verify password requirements text is displayed
      expect(
        find.textContaining('at least 8 characters'),
        findsOneWidget,
      );
    });

    testWidgets('should disable all fields when loading', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthLoading());
      when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(const AuthLoading()));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Verify register button is disabled
      final registerButton = find.widgetWithText(ElevatedButton, 'Create Account');
      final button = tester.widget<ElevatedButton>(registerButton);
      expect(button.onPressed, isNull);
    });
  });

  group('Admin Registration Flow Tests', () {
    testWidgets('should register admin without group code', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isAdmin: true));

      // Enter valid admin registration data
      await tester.enterText(find.byType(TextFormField).at(0), 'adminuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'admin@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password123');
      await tester.enterText(find.byType(TextFormField).at(4), 'Test Organization');
      await tester.enterText(find.byType(TextFormField).at(5), 'IT Department');
      await tester.pump();

      // Tap register button
      final registerButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.tap(registerButton);
      await tester.pump();

      // Verify register event was dispatched with admin role and no group code
      final captured = verify(() => mockAuthBloc.add(captureAny())).captured;
      expect(captured.length, 1);
      final event = captured.first as AuthRegisterRequested;
      expect(event.role, 'admin');
      expect(event.groupCode, isNull);
      expect(event.organizationName, 'Test Organization');
      expect(event.departmentName, 'IT Department');
    });

    testWidgets('should show admin registration success dialog with group code', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
      when(() => mockAuthBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const AuthInitial(),
          AuthState(
            status: AuthStatus.authenticated,
            user: User(
              id: 1,
              username: 'adminuser',
              email: 'admin@example.com',
              role: UserRole.admin,
              createdAt: DateTime.now(),
              organizationId: 1,
            ),
            groupCode: 'ABC123',
          ),
        ]),
      );

      await tester.pumpWidget(createWidgetUnderTest(isAdmin: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify admin registration success dialog is shown
      expect(find.byType(AdminRegistrationSuccessDialog), findsOneWidget);
      expect(find.text('ABC123'), findsOneWidget);
      expect(find.text('Registration Successful!'), findsOneWidget);
    });

    testWidgets('should copy group code to clipboard in success dialog', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
      when(() => mockAuthBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const AuthInitial(),
          AuthState(
            status: AuthStatus.authenticated,
            user: User(
              id: 1,
              username: 'adminuser',
              email: 'admin@example.com',
              role: UserRole.admin,
              createdAt: DateTime.now(),
              organizationId: 1,
            ),
            groupCode: 'XYZ789',
          ),
        ]),
      );

      await tester.pumpWidget(createWidgetUnderTest(isAdmin: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find and tap copy button
      final copyButton = find.byIcon(Icons.copy);
      expect(copyButton, findsOneWidget);
      await tester.tap(copyButton);
      await tester.pump();

      // Verify snackbar shows copy confirmation
      expect(find.text('Code copied to clipboard'), findsOneWidget);
    });

    testWidgets('should navigate to home after clicking continue in success dialog', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
      when(() => mockAuthBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const AuthInitial(),
          AuthState(
            status: AuthStatus.authenticated,
            user: User(
              id: 1,
              username: 'adminuser',
              email: 'admin@example.com',
              role: UserRole.admin,
              createdAt: DateTime.now(),
              organizationId: 1,
            ),
            groupCode: 'TEST12',
          ),
        ]),
      );

      await tester.pumpWidget(createWidgetUnderTest(isAdmin: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify dialog is shown
      expect(find.byType(AdminRegistrationSuccessDialog), findsOneWidget);

      // Find and tap continue button
      final continueButton = find.text('Continue to Dashboard');
      expect(continueButton, findsOneWidget);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(AdminRegistrationSuccessDialog), findsNothing);
    });
  });

  group('User Registration with Group Code Tests', () {
    testWidgets('should show group code input for user registration', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isAdmin: false));

      // Verify group code input is visible
      expect(find.byType(GroupCodeInput), findsOneWidget);
    });

    testWidgets('should show error when group code is empty for user', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isAdmin: false));

      // Enter valid data except group code
      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'user@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password123');
      await tester.pump();

      // Tap register button without entering group code
      final registerButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Verify error message is shown
      expect(find.text('Group code is required'), findsOneWidget);
    });

    testWidgets('should show error when group code is invalid length', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isAdmin: false));

      // Enter valid data with short group code
      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'user@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password123');
      
      // Enter short group code
      final groupCodeInput = find.byType(TextField).last;
      await tester.enterText(groupCodeInput, 'ABC');
      await tester.pump();

      // Tap register button
      final registerButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Verify error message is shown
      expect(find.text('Group code must be 6 characters'), findsOneWidget);
    });

    testWidgets('should register user with valid group code', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isAdmin: false));

      // Enter valid user registration data with group code
      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'user@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password123');
      await tester.enterText(find.byType(TextFormField).at(4), 'Sales Org');
      await tester.enterText(find.byType(TextFormField).at(5), 'Marketing');
      
      // Enter valid group code
      final groupCodeInput = find.byType(TextField).last;
      await tester.enterText(groupCodeInput, 'ABC123');
      await tester.pump();

      // Tap register button
      final registerButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.tap(registerButton);
      await tester.pump();

      // Verify register event was dispatched with user role and group code
      final captured = verify(() => mockAuthBloc.add(captureAny())).captured;
      expect(captured.length, 1);
      final event = captured.first as AuthRegisterRequested;
      expect(event.role, 'user');
      expect(event.groupCode, 'ABC123');
      expect(event.organizationName, 'Sales Org');
      expect(event.departmentName, 'Marketing');
    });

    testWidgets('should show success message for user registration', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
      when(() => mockAuthBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const AuthInitial(),
          AuthState(
            status: AuthStatus.authenticated,
            user: User(
              id: 2,
              username: 'testuser',
              email: 'user@example.com',
              role: UserRole.user,
              createdAt: DateTime.now(),
              organizationId: 1,
            ),
          ),
        ]),
      );

      await tester.pumpWidget(createWidgetUnderTest(isAdmin: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify success message is shown (no dialog for users)
      expect(find.text('Account created successfully!'), findsOneWidget);
      expect(find.byType(AdminRegistrationSuccessDialog), findsNothing);
    });

    testWidgets('should allow optional organization and department fields', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isAdmin: false));

      // Enter required fields only (no org/dept)
      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'user@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password123');
      
      // Enter valid group code
      final groupCodeInput = find.byType(TextField).last;
      await tester.enterText(groupCodeInput, 'TEST99');
      await tester.pump();

      // Tap register button
      final registerButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.tap(registerButton);
      await tester.pump();

      // Verify register event was dispatched with null org/dept
      final captured = verify(() => mockAuthBloc.add(captureAny())).captured;
      expect(captured.length, 1);
      final event = captured.first as AuthRegisterRequested;
      expect(event.organizationName, isNull);
      expect(event.departmentName, isNull);
      expect(event.groupCode, 'TEST99');
    });
  });

  group('Validation Error Tests', () {
    testWidgets('should show error for invalid group code format', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isAdmin: false));

      // Enter valid data
      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'user@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password123');
      
      // Enter group code with special characters
      final groupCodeInput = find.byType(TextField).last;
      await tester.enterText(groupCodeInput, 'ABC@#\$');
      await tester.pump();

      // The input formatter should prevent special characters
      // So the actual text should be empty or only valid chars
      final textField = tester.widget<TextField>(groupCodeInput);
      final actualText = textField.controller?.text ?? '';
      expect(actualText, isNot(contains('@')));
      expect(actualText, isNot(contains('#')));
      expect(actualText, isNot(contains('\$')));
    });

    testWidgets('should show backend error for invalid group code', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
      when(() => mockAuthBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const AuthInitial(),
          const AuthState(
            status: AuthStatus.error,
            errorMessage: 'The selected group code is invalid',
          ),
        ]),
      );

      await tester.pumpWidget(createWidgetUnderTest(isAdmin: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify error message is shown in snackbar
      expect(find.text('The selected group code is invalid'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('should show error when user already in group', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
      when(() => mockAuthBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const AuthInitial(),
          const AuthState(
            status: AuthStatus.error,
            errorMessage: 'You are already in a group',
          ),
        ]),
      );

      await tester.pumpWidget(createWidgetUnderTest(isAdmin: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify error message is shown
      expect(find.text('You are already in a group'), findsOneWidget);
    });
  });
}

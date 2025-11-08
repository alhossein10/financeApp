import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:finance_app/ui/superadmin_cash_page.dart';
import 'package:finance_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:finance_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:finance_app/features/auth/domain/entities/user.dart';
import 'package:finance_app/features/fund_box/presentation/bloc/fund_box_bloc.dart';
import 'package:finance_app/features/fund_box/presentation/bloc/fund_box_state.dart';
import 'package:finance_app/features/fund_box/domain/entities/fund_box.dart';
import 'package:finance_app/features/transfers/presentation/bloc/transfer_bloc.dart';
import 'package:finance_app/features/transfers/presentation/bloc/transfer_state.dart';
import 'package:finance_app/features/transfers/domain/entities/transfer.dart';
import 'package:finance_app/features/admin_group/presentation/bloc/admin_group_bloc.dart';
import 'package:finance_app/features/admin_group/presentation/bloc/admin_group_state.dart';
import 'package:finance_app/features/admin_group/domain/entities/group_member.dart';
import 'package:finance_app/l10n/app_localizations.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockFundBoxBloc extends Mock implements FundBoxBloc {}
class MockTransferBloc extends Mock implements TransferBloc {}
class MockAdminGroupBloc extends Mock implements AdminGroupBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockFundBoxBloc mockFundBoxBloc;
  late MockTransferBloc mockTransferBloc;
  late MockAdminGroupBloc mockAdminGroupBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockFundBoxBloc = MockFundBoxBloc();
    mockTransferBloc = MockTransferBloc();
    mockAdminGroupBloc = MockAdminGroupBloc();

    // Default auth state
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticated(
        user: User(
          id: 1,
          name: 'Test SuperAdmin',
          email: 'superadmin@test.com',
          role: 'superadmin',
        ),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer(
      (_) => Stream.value(
        AuthAuthenticated(
          user: User(
            id: 1,
            name: 'Test SuperAdmin',
            email: 'superadmin@test.com',
            role: 'superadmin',
          ),
        ),
      ),
    );

    // Default fund box state
    when(() => mockFundBoxBloc.state).thenReturn(const FundBoxInitial());
    when(() => mockFundBoxBloc.stream).thenAnswer(
      (_) => Stream.value(const FundBoxInitial()),
    );

    // Default transfer state
    when(() => mockTransferBloc.state).thenReturn(const TransferInitial());
    when(() => mockTransferBloc.stream).thenAnswer(
      (_) => Stream.value(const TransferInitial()),
    );

    // Default admin group state
    when(() => mockAdminGroupBloc.state).thenReturn(const AdminGroupInitial());
    when(() => mockAdminGroupBloc.stream).thenAnswer(
      (_) => Stream.value(const AdminGroupInitial()),
    );
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<FundBoxBloc>.value(value: mockFundBoxBloc),
          BlocProvider<TransferBloc>.value(value: mockTransferBloc),
          BlocProvider<AdminGroupBloc>.value(value: mockAdminGroupBloc),
        ],
        child: const SuperAdminCashPage(),
      ),
    );
  }

  group('SuperAdminCashPage Widget Tests - UI Rendering', () {
    testWidgets('should display fund box balance with mock data', (tester) async {
      // Setup loaded fund box state
      final fundBox = FundBox(
        id: 1,
        userId: 1,
        balanceUsd: 1000.0,
        balanceSyp: 5000000.0,
        balanceTry: 20000.0,
        lastUpdated: DateTime.now(),
      );

      when(() => mockFundBoxBloc.state).thenReturn(FundBoxLoaded(fundBox));
      when(() => mockFundBoxBloc.stream).thenAnswer(
        (_) => Stream.value(FundBoxLoaded(fundBox)),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify fund box balance is displayed
      expect(find.text('1000.00'), findsOneWidget); // USD balance
      expect(find.text('5000000.00'), findsOneWidget); // SYP balance
      expect(find.text('20000.00'), findsOneWidget); // TRY balance
      
      // Verify currency labels
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('SYP'), findsOneWidget);
      expect(find.text('TRY'), findsOneWidget);
    });

    testWidgets('should display outgoing transfers list with mock data', (tester) async {
      // Setup loaded transfers state
      final transfers = [
        Transfer(
          id: 1,
          userId: 1,
          recipientName: 'Admin User 1',
          amountUsd: 500.0,
          convertedAmountUsd: 500.0,
          transactionDate: DateTime(2024, 1, 15),
          createdAt: DateTime.now(),
        ),
        Transfer(
          id: 2,
          userId: 1,
          recipientName: 'Admin User 2',
          amountUsd: 300.0,
          convertedAmountUsd: 300.0,
          transactionDate: DateTime(2024, 1, 20),
          createdAt: DateTime.now(),
        ),
      ];

      when(() => mockTransferBloc.state).thenReturn(TransferLoaded(transfers));
      when(() => mockTransferBloc.stream).thenAnswer(
        (_) => Stream.value(TransferLoaded(transfers)),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify transfers are displayed
      expect(find.text('Admin User 1'), findsOneWidget);
      expect(find.text('Admin User 2'), findsOneWidget);
      expect(find.text('\$500.00'), findsOneWidget);
      expect(find.text('\$300.00'), findsOneWidget);
    });

    testWidgets('should display create outgoing transfer button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify create transfer button is displayed
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('should display refresh button in app bar', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify refresh button is displayed
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should display outgoing transfers section header', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify section header with arrow icon
      expect(find.byIcon(Icons.arrow_upward), findsWidgets);
    });
  });

  group('SuperAdminCashPage Widget Tests - Empty States', () {
    testWidgets('should display empty state when no transfers', (tester) async {
      // Setup empty transfers state
      when(() => mockTransferBloc.state).thenReturn(const TransferLoaded([]));
      when(() => mockTransferBloc.stream).thenAnswer(
        (_) => Stream.value(const TransferLoaded([])),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify empty state icon is displayed
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('should display loading indicator when fund box is loading', (tester) async {
      // Setup loading state
      when(() => mockFundBoxBloc.state).thenReturn(const FundBoxLoading());
      when(() => mockFundBoxBloc.stream).thenAnswer(
        (_) => Stream.value(const FundBoxLoading()),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify loading indicator is displayed
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('should display loading indicator when transfers are loading', (tester) async {
      // Setup loading state
      when(() => mockTransferBloc.state).thenReturn(const TransferLoading());
      when(() => mockTransferBloc.stream).thenAnswer(
        (_) => Stream.value(const TransferLoading()),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify loading indicator is displayed
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });

  group('SuperAdminCashPage Widget Tests - Error States', () {
    testWidgets('should display error message when fund box fails to load', (tester) async {
      // Setup error state
      when(() => mockFundBoxBloc.state).thenReturn(
        const FundBoxError(message: 'Failed to load fund box'),
      );
      when(() => mockFundBoxBloc.stream).thenAnswer(
        (_) => Stream.value(
          const FundBoxError(message: 'Failed to load fund box'),
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.text('Failed to load fund box'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('should display retry button when fund box fails to load', (tester) async {
      // Setup error state
      when(() => mockFundBoxBloc.state).thenReturn(
        const FundBoxError(message: 'Network error'),
      );
      when(() => mockFundBoxBloc.stream).thenAnswer(
        (_) => Stream.value(
          const FundBoxError(message: 'Network error'),
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify retry button is displayed
      expect(find.byIcon(Icons.refresh), findsWidgets);
    });

    testWidgets('should display error message when transfers fail to load', (tester) async {
      // Setup error state
      when(() => mockTransferBloc.state).thenReturn(
        const TransferError(message: 'Failed to load transfers'),
      );
      when(() => mockTransferBloc.stream).thenAnswer(
        (_) => Stream.value(
          const TransferError(message: 'Failed to load transfers'),
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.text('Failed to load transfers'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('should display error icon in error state', (tester) async {
      // Setup error state
      when(() => mockFundBoxBloc.state).thenReturn(
        const FundBoxError(message: 'Error occurred'),
      );
      when(() => mockFundBoxBloc.stream).thenAnswer(
        (_) => Stream.value(
          const FundBoxError(message: 'Error occurred'),
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify error icon is displayed
      expect(find.byIcon(Icons.error), findsOneWidget);
    });
  });

  group('SuperAdminCashPage Widget Tests - Interactions', () {
    testWidgets('should show create transfer dialog when button is tapped', (tester) async {
      // Setup admin group members
      final members = [
        GroupMember(
          id: 2,
          name: 'Admin User',
          email: 'admin@test.com',
          role: 'admin',
          isAdmin: true,
          joinedAt: DateTime.now(),
        ),
      ];

      when(() => mockAdminGroupBloc.state).thenReturn(
        GroupMembersLoaded(members),
      );
      when(() => mockAdminGroupBloc.stream).thenAnswer(
        (_) => Stream.value(GroupMembersLoaded(members)),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find and tap create transfer button
      final createButton = find.byIcon(Icons.add);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('should display transfer form fields in dialog', (tester) async {
      // Setup admin group members
      final members = [
        GroupMember(
          id: 2,
          name: 'Admin User',
          email: 'admin@test.com',
          role: 'admin',
          isAdmin: true,
          joinedAt: DateTime.now(),
        ),
      ];

      when(() => mockAdminGroupBloc.state).thenReturn(
        GroupMembersLoaded(members),
      );
      when(() => mockAdminGroupBloc.stream).thenAnswer(
        (_) => Stream.value(GroupMembersLoaded(members)),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap create transfer button
      final createButton = find.byIcon(Icons.add);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Verify form fields are displayed
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('should display only admin members in recipient dropdown', (tester) async {
      // Setup mixed group members (admin and non-admin)
      final members = [
        GroupMember(
          id: 2,
          name: 'Admin User',
          email: 'admin@test.com',
          role: 'admin',
          isAdmin: true,
          joinedAt: DateTime.now(),
        ),
        GroupMember(
          id: 3,
          name: 'Regular User',
          email: 'user@test.com',
          role: 'user',
          isAdmin: false,
          joinedAt: DateTime.now(),
        ),
      ];

      when(() => mockAdminGroupBloc.state).thenReturn(
        GroupMembersLoaded(members),
      );
      when(() => mockAdminGroupBloc.stream).thenAnswer(
        (_) => Stream.value(GroupMembersLoaded(members)),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap create transfer button
      final createButton = find.byIcon(Icons.add);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Verify only admin user is shown in dropdown
      expect(find.text('Admin User (admin@test.com)'), findsOneWidget);
      expect(find.text('Regular User (user@test.com)'), findsNothing);
    });
  });

  group('SuperAdminCashPage Widget Tests - Layout', () {
    testWidgets('should display all main sections', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify main sections are present
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Card), findsWidgets); // Fund box card
      expect(find.byType(ElevatedButton), findsWidgets); // Create button
    });

    testWidgets('should display fund box card with proper styling', (tester) async {
      final fundBox = FundBox(
        id: 1,
        userId: 1,
        balanceUsd: 1000.0,
        balanceSyp: 5000000.0,
        balanceTry: 20000.0,
        lastUpdated: DateTime.now(),
      );

      when(() => mockFundBoxBloc.state).thenReturn(FundBoxLoaded(fundBox));
      when(() => mockFundBoxBloc.stream).thenAnswer(
        (_) => Stream.value(FundBoxLoaded(fundBox)),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify card is displayed
      expect(find.byType(Card), findsWidgets);
      
      // Verify balance icons are displayed
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
      expect(find.byIcon(Icons.currency_pound), findsOneWidget);
      expect(find.byIcon(Icons.currency_lira), findsOneWidget);
    });

    testWidgets('should display transfer cards with proper styling', (tester) async {
      final transfers = [
        Transfer(
          id: 1,
          userId: 1,
          recipientName: 'Admin User',
          amountUsd: 500.0,
          convertedAmountUsd: 500.0,
          transactionDate: DateTime(2024, 1, 15),
          createdAt: DateTime.now(),
        ),
      ];

      when(() => mockTransferBloc.state).thenReturn(TransferLoaded(transfers));
      when(() => mockTransferBloc.stream).thenAnswer(
        (_) => Stream.value(TransferLoaded(transfers)),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify transfer card elements
      expect(find.byType(ListTile), findsWidgets);
      expect(find.byType(CircleAvatar), findsWidgets);
      expect(find.byIcon(Icons.arrow_upward), findsWidgets);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:finance_app/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:finance_app/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:finance_app/features/admin/presentation/bloc/admin_event.dart';
import 'package:finance_app/features/admin/presentation/bloc/admin_state.dart';
import 'package:finance_app/features/expenses/domain/entities/expense.dart';
import 'package:finance_app/core/config/flavor_config.dart';

class MockAdminBloc extends Mock implements AdminBloc {}

void main() {
  late MockAdminBloc mockAdminBloc;

  setUp(() {
    mockAdminBloc = MockAdminBloc();
    when(() => mockAdminBloc.state).thenReturn(const AdminInitial());
    when(() => mockAdminBloc.stream).thenAnswer((_) => Stream.value(const AdminInitial()));
    
    // Set admin flavor for tests
    FlavorConfig(
      flavor: Flavor.admin,
      values: FlavorValues(
        baseUrl: 'http://localhost:8000',
        appName: 'Finance App Admin',
      ),
    );
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AdminBloc>.value(
        value: mockAdminBloc,
        child: const AdminDashboardPage(),
      ),
    );
  }

  group('AdminDashboardPage Widget Tests', () {
    testWidgets('should show loading indicator when state is AdminLoading', (tester) async {
      when(() => mockAdminBloc.state).thenReturn(const AdminLoading());
      when(() => mockAdminBloc.stream).thenAnswer((_) => Stream.value(const AdminLoading()));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message and retry button when state is AdminError', (tester) async {
      const errorMessage = 'Failed to load admin data';
      when(() => mockAdminBloc.state).thenReturn(const AdminError(errorMessage));
      when(() => mockAdminBloc.stream).thenAnswer((_) => Stream.value(const AdminError(errorMessage)));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Verify error message is shown
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      
      // Verify retry button exists
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should dispatch events when retry button is tapped', (tester) async {
      when(() => mockAdminBloc.state).thenReturn(const AdminError('Error'));
      when(() => mockAdminBloc.stream).thenAnswer((_) => Stream.value(const AdminError('Error')));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pump();

      // Verify events were dispatched
      verify(() => mockAdminBloc.add(any(that: isA<FetchAdminStatisticsRequested>()))).called(1);
      verify(() => mockAdminBloc.add(any(that: isA<FetchAllUserExpensesRequested>()))).called(1);
    });

    testWidgets('should display statistics cards when state is AdminLoaded', (tester) async {
      final state = AdminLoaded(
        totalUsers: 10,
        totalExpenses: 50,
        pendingSync: 5,
        totalAmount: 1000.0,
        recentExpenses: [],
        userActivityMap: {},
      );

      when(() => mockAdminBloc.state).thenReturn(state);
      when(() => mockAdminBloc.stream).thenAnswer((_) => Stream.value(state));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Verify statistics are displayed
      expect(find.text('10'), findsOneWidget); // Total users
      expect(find.text('50'), findsOneWidget); // Total expenses
      expect(find.text('5'), findsOneWidget); // Pending sync
      expect(find.text('\$1000.00'), findsOneWidget); // Total amount
    });

    testWidgets('should display statistics section with correct icons', (tester) async {
      final state = AdminLoaded(
        totalUsers: 10,
        totalExpenses: 50,
        pendingSync: 5,
        totalAmount: 1000.0,
        recentExpenses: [],
        userActivityMap: {},
      );

      when(() => mockAdminBloc.state).thenReturn(state);
      when(() => mockAdminBloc.stream).thenAnswer((_) => Stream.value(state));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Verify stat card icons
      expect(find.byIcon(Icons.people), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
      expect(find.byIcon(Icons.pending), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
    });

    testWidgets('should display recent expenses list', (tester) async {
      final expenses = [
        Expense(
          id: 1,
          userId: 1,
          description: 'Office Supplies',
          priceUsd: 50.0,
          priceSyp: null,
          priceTry: null,
          invoiceStatus: InvoiceStatus.invoiceAvailable,
          invoiceFilePath: null,
          expenseDate: DateTime.now(),
          syncStatus: SyncStatus.synced,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          creatorUsername: 'john_doe',
          creatorEmail: 'john@example.com',
        ),
        Expense(
          id: 2,
          userId: 2,
          description: 'Travel Expenses',
          priceUsd: 200.0,
          priceSyp: null,
          priceTry: null,
          invoiceStatus: InvoiceStatus.noInvoice,
          invoiceFilePath: null,
          expenseDate: DateTime.now(),
          syncStatus: SyncStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          creatorUsername: 'jane_smith',
          creatorEmail: 'jane@example.com',
        ),
      ];

      final state = AdminLoaded(
        totalUsers: 10,
        totalExpenses: 50,
        pendingSync: 5,
        totalAmount: 1000.0,
        recentExpenses: expenses,
        userActivityMap: {},
      );

      when(() => mockAdminBloc.state).thenReturn(state);
      when(() => mockAdminBloc.stream).thenAnswer((_) => Stream.value(state));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Verify expenses are displayed
      expect(find.text('Office Supplies'), findsOneWidget);
      expect(find.text('Travel Expenses'), findsOneWidget);
      
      // Verify creator names are shown
      expect(find.textContaining('john_doe'), findsOneWidget);
      expect(find.textContaining('jane_smith'), findsOneWidget);
    });

    testWidgets('should display sync status badges for expenses', (tester) async {
      final expenses = [
        Expense(
          id: 1,
          userId: 1,
          description: 'Synced Expense',
          priceUsd: 50.0,
          priceSyp: null,
          priceTry: null,
          invoiceStatus: InvoiceStatus.noInvoice,
          invoiceFilePath: null,
          expenseDate: DateTime.now(),
          syncStatus: SyncStatus.synced,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Expense(
          id: 2,
          userId: 1,
          description: 'Pending Expense',
          priceUsd: 30.0,
          priceSyp: null,
          priceTry: null,
          invoiceStatus: InvoiceStatus.noInvoice,
          invoiceFilePath: null,
          expenseDate: DateTime.now(),
          syncStatus: SyncStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final state = AdminLoaded(
        totalUsers: 10,
        totalExpenses: 50,
        pendingSync: 5,
        totalAmount: 1000.0,
        recentExpenses: expenses,
        userActivityMap: {},
      );

      when(() => mockAdminBloc.state).thenReturn(state);
      when(() => mockAdminBloc.stream).thenAnswer((_) => Stream.value(state));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Verify sync status badges
      expect(find.text('Synced'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('should display user activity summary', (tester) async {
      final state = AdminLoaded(
        totalUsers: 10,
        totalExpenses: 50,
        pendingSync: 5,
        totalAmount: 1000.0,
        recentExpenses: [],
        userActivityMap: {
          'john_doe': 15,
          'jane_smith': 10,
          'bob_jones': 5,
        },
      );

      when(() => mockAdminBloc.state).thenReturn(state);
      when(() => mockAdminBloc.stream).thenAnswer((_) => Stream.value(state));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Verify user activity is displayed
      expect(find.text('john_doe'), findsOneWidget);
      expect(find.text('jane_smith'), findsOneWidget);
      expect(find.text('bob_jones'), findsOneWidget);
      
      // Verify expense counts
      expect(find.textContaining('15'), findsOneWidget);
      expect(find.textContaining('10'), findsOneWidget);
      expect(find.textContaining('5'), findsOneWidget);
    });

    testWidgets('should show empty state when no expenses exist', (tester) async {
      final state = AdminLoaded(
        totalUsers: 10,
        totalExpenses: 0,
        pendingSync: 0,
        totalAmount: 0.0,
        recentExpenses: [],
        userActivityMap: {},
      );

      when(() => mockAdminBloc.state).thenReturn(state);
      when(() => mockAdminBloc.stream).thenAnswer((_) => Stream.value(state));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Verify empty state messages
      expect(find.text('No expenses yet'), findsOneWidget);
      expect(find.text('No user activity'), findsOneWidget);
    });

    testWidgets('should have refresh button in app bar', (tester) async {
      final state = AdminLoaded(
        totalUsers: 10,
        totalExpenses: 50,
        pendingSync: 5,
        totalAmount: 1000.0,
        recentExpenses: [],
        userActivityMap: {},
      );

      when(() => mockAdminBloc.state).thenReturn(state);
      when(() => mockAdminBloc.stream).thenAnswer((_) => Stream.value(state));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Verify refresh button exists
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should dispatch events when refresh button is tapped', (tester) async {
      final state = AdminLoaded(
        totalUsers: 10,
        totalExpenses: 50,
        pendingSync: 5,
        totalAmount: 1000.0,
        recentExpenses: [],
        userActivityMap: {},
      );

      when(() => mockAdminBloc.state).thenReturn(state);
      when(() => mockAdminBloc.stream).thenAnswer((_) => Stream.value(state));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Tap refresh button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Verify events were dispatched
      verify(() => mockAdminBloc.add(any(that: isA<FetchAdminStatisticsRequested>()))).called(1);
      verify(() => mockAdminBloc.add(any(that: isA<FetchAllUserExpensesRequested>()))).called(1);
    });

    testWidgets('should support pull-to-refresh', (tester) async {
      final state = AdminLoaded(
        totalUsers: 10,
        totalExpenses: 50,
        pendingSync: 5,
        totalAmount: 1000.0,
        recentExpenses: [],
        userActivityMap: {},
      );

      when(() => mockAdminBloc.state).thenReturn(state);
      when(() => mockAdminBloc.stream).thenAnswer((_) => Stream.value(state));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Verify RefreshIndicator exists
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('should display expense with multiple currencies', (tester) async {
      final expense = Expense(
        id: 1,
        userId: 1,
        description: 'Multi-currency',
        priceUsd: 50.0,
        priceSyp: 10000.0,
        priceTry: 150.0,
        invoiceStatus: InvoiceStatus.noInvoice,
        invoiceFilePath: null,
        expenseDate: DateTime.now(),
        syncStatus: SyncStatus.synced,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final state = AdminLoaded(
        totalUsers: 10,
        totalExpenses: 50,
        pendingSync: 5,
        totalAmount: 1000.0,
        recentExpenses: [expense],
        userActivityMap: {},
      );

      when(() => mockAdminBloc.state).thenReturn(state);
      when(() => mockAdminBloc.stream).thenAnswer((_) => Stream.value(state));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Verify all currencies are displayed
      expect(find.textContaining('50.00'), findsOneWidget);
      expect(find.textContaining('10000'), findsOneWidget);
      expect(find.textContaining('150.00'), findsOneWidget);
    });
  });
}

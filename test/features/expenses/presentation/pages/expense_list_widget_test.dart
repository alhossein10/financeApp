import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:finance_app/features/expenses/presentation/bloc/expense_bloc.dart';
import 'package:finance_app/features/expenses/presentation/bloc/expense_event.dart';
import 'package:finance_app/features/expenses/presentation/bloc/expense_state.dart';
import 'package:finance_app/features/expenses/domain/entities/expense.dart';
import 'package:finance_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:finance_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:finance_app/features/auth/domain/entities/user.dart';

class MockExpenseBloc extends Mock implements ExpenseBloc {}
class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockExpenseBloc mockExpenseBloc;
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockExpenseBloc = MockExpenseBloc();
    mockAuthBloc = MockAuthBloc();
    
    when(() => mockExpenseBloc.state).thenReturn(const ExpenseInitial());
    when(() => mockExpenseBloc.stream).thenAnswer((_) => Stream.value(const ExpenseInitial()));
    
    when(() => mockAuthBloc.state).thenReturn(
      const AuthAuthenticated(user: User(id: 1, username: 'testuser', email: 'test@example.com', role: 'user')),
    );
    when(() => mockAuthBloc.stream).thenAnswer(
      (_) => Stream.value(const AuthAuthenticated(user: User(id: 1, username: 'testuser', email: 'test@example.com', role: 'user'))),
    );
  });

  Widget createExpenseListWidget() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<ExpenseBloc>.value(value: mockExpenseBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        ],
        child: Scaffold(
          body: BlocBuilder<ExpenseBloc, ExpenseState>(
            builder: (context, state) {
              if (state is ExpenseLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (state is ExpenseError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<ExpenseBloc>().add(const LoadExpensesRequested(1));
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              
              if (state is ExpenseLoaded) {
                if (state.expenses.isEmpty) {
                  return const Center(
                    child: Text('No expenses yet'),
                  );
                }
                
                return ListView.builder(
                  itemCount: state.expenses.length,
                  itemBuilder: (context, index) {
                    final expense = state.expenses[index];
                    return ListTile(
                      key: Key('expense_${expense.id}'),
                      leading: Icon(
                        expense.invoiceStatus == InvoiceStatus.invoiceAvailable
                            ? Icons.receipt
                            : Icons.description,
                      ),
                      title: Text(expense.description),
                      subtitle: Text(
                        [
                          if (expense.priceUsd != null) '\$${expense.priceUsd!.toStringAsFixed(2)}',
                          if (expense.priceSyp != null) '${expense.priceSyp!.toStringAsFixed(0)} SYP',
                          if (expense.priceTry != null) '${expense.priceTry!.toStringAsFixed(2)} TRY',
                        ].join(' • '),
                      ),
                      trailing: buildSyncStatusBadge(expense.syncStatus),
                    );
                  },
                );
              }
              
              return const Center(child: Text('Welcome'));
            },
          ),
        ),
      ),
    );
  }

  Widget buildSyncStatusBadge(SyncStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case SyncStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case SyncStatus.syncing:
        color = Colors.blue;
        text = 'Syncing';
        break;
      case SyncStatus.synced:
        color = Colors.green;
        text = 'Synced';
        break;
      case SyncStatus.failed:
        color = Colors.red;
        text = 'Failed';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  group('Expense List Widget Tests', () {
    testWidgets('should show loading indicator when state is ExpenseLoading', (tester) async {
      when(() => mockExpenseBloc.state).thenReturn(const ExpenseLoading());
      when(() => mockExpenseBloc.stream).thenAnswer((_) => Stream.value(const ExpenseLoading()));

      await tester.pumpWidget(createExpenseListWidget());
      await tester.pump();

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message and retry button when state is ExpenseError', (tester) async {
      const errorMessage = 'Failed to load expenses';
      when(() => mockExpenseBloc.state).thenReturn(const ExpenseError(errorMessage));
      when(() => mockExpenseBloc.stream).thenAnswer((_) => Stream.value(const ExpenseError(errorMessage)));

      await tester.pumpWidget(createExpenseListWidget());
      await tester.pump();

      // Verify error message is shown
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
      
      // Verify retry button exists
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should dispatch LoadExpensesRequested when retry button is tapped', (tester) async {
      when(() => mockExpenseBloc.state).thenReturn(const ExpenseError('Error'));
      when(() => mockExpenseBloc.stream).thenAnswer((_) => Stream.value(const ExpenseError('Error')));

      await tester.pumpWidget(createExpenseListWidget());
      await tester.pump();

      // Tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pump();

      // Verify event was dispatched
      verify(() => mockExpenseBloc.add(any(that: isA<LoadExpensesRequested>()))).called(1);
    });

    testWidgets('should show empty state when no expenses exist', (tester) async {
      when(() => mockExpenseBloc.state).thenReturn(const ExpenseLoaded([]));
      when(() => mockExpenseBloc.stream).thenAnswer((_) => Stream.value(const ExpenseLoaded([])));

      await tester.pumpWidget(createExpenseListWidget());
      await tester.pump();

      // Verify empty state message
      expect(find.text('No expenses yet'), findsOneWidget);
    });

    testWidgets('should display list of expenses when state is ExpenseLoaded', (tester) async {
      final expenses = [
        Expense(
          id: 1,
          userId: 1,
          description: 'Groceries',
          priceUsd: 50.0,
          priceSyp: null,
          priceTry: null,
          invoiceStatus: InvoiceStatus.invoiceAvailable,
          invoiceFilePath: null,
          expenseDate: DateTime.now(),
          syncStatus: SyncStatus.synced,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Expense(
          id: 2,
          userId: 1,
          description: 'Transportation',
          priceUsd: null,
          priceSyp: 10000.0,
          priceTry: null,
          invoiceStatus: InvoiceStatus.noInvoice,
          invoiceFilePath: null,
          expenseDate: DateTime.now(),
          syncStatus: SyncStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(() => mockExpenseBloc.state).thenReturn(ExpenseLoaded(expenses));
      when(() => mockExpenseBloc.stream).thenAnswer((_) => Stream.value(ExpenseLoaded(expenses)));

      await tester.pumpWidget(createExpenseListWidget());
      await tester.pump();

      // Verify expenses are displayed
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Transportation'), findsOneWidget);
      
      // Verify list items exist
      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('should display correct icons based on invoice status', (tester) async {
      final expenses = [
        Expense(
          id: 1,
          userId: 1,
          description: 'With Invoice',
          priceUsd: 50.0,
          priceSyp: null,
          priceTry: null,
          invoiceStatus: InvoiceStatus.invoiceAvailable,
          invoiceFilePath: null,
          expenseDate: DateTime.now(),
          syncStatus: SyncStatus.synced,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Expense(
          id: 2,
          userId: 1,
          description: 'Without Invoice',
          priceUsd: 30.0,
          priceSyp: null,
          priceTry: null,
          invoiceStatus: InvoiceStatus.noInvoice,
          invoiceFilePath: null,
          expenseDate: DateTime.now(),
          syncStatus: SyncStatus.synced,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(() => mockExpenseBloc.state).thenReturn(ExpenseLoaded(expenses));
      when(() => mockExpenseBloc.stream).thenAnswer((_) => Stream.value(ExpenseLoaded(expenses)));

      await tester.pumpWidget(createExpenseListWidget());
      await tester.pump();

      // Verify correct icons are displayed
      expect(find.byIcon(Icons.receipt), findsOneWidget);
      expect(find.byIcon(Icons.description), findsOneWidget);
    });

    testWidgets('should display sync status badges correctly', (tester) async {
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

      when(() => mockExpenseBloc.state).thenReturn(ExpenseLoaded(expenses));
      when(() => mockExpenseBloc.stream).thenAnswer((_) => Stream.value(ExpenseLoaded(expenses)));

      await tester.pumpWidget(createExpenseListWidget());
      await tester.pump();

      // Verify sync status badges are displayed
      expect(find.text('Synced'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('should display multiple currency prices correctly', (tester) async {
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

      when(() => mockExpenseBloc.state).thenReturn(ExpenseLoaded([expense]));
      when(() => mockExpenseBloc.stream).thenAnswer((_) => Stream.value(ExpenseLoaded([expense])));

      await tester.pumpWidget(createExpenseListWidget());
      await tester.pump();

      // Verify all currency prices are displayed
      expect(find.textContaining('\$50.00'), findsOneWidget);
      expect(find.textContaining('10000 SYP'), findsOneWidget);
      expect(find.textContaining('150.00 TRY'), findsOneWidget);
    });
  });
}

# Infinite Scroll Implementation Example

This document provides a complete example of implementing infinite scroll pagination in a Flutter page.

## Complete Example: Expense List with Infinite Scroll

### Step 1: Update the BLoC State

Add pagination fields to your state:

```dart
// lib/features/expenses/presentation/bloc/expense_state.dart

class ExpenseLoaded extends ExpenseState {
  final List<Expense> expenses;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;

  const ExpenseLoaded(
    this.expenses, {
    this.currentPage = 1,
    this.totalPages = 1,
    this.isLoadingMore = false,
    super.syncStatusMap,
  });

  bool get hasMorePages => currentPage < totalPages;

  ExpenseLoaded copyWith({
    List<Expense>? expenses,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    Map<int, SyncStatus>? syncStatusMap,
  }) {
    return ExpenseLoaded(
      expenses ?? this.expenses,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      syncStatusMap: syncStatusMap ?? this.syncStatusMap,
    );
  }

  @override
  List<Object?> get props => [
        expenses,
        currentPage,
        totalPages,
        isLoadingMore,
        syncStatusMap,
      ];
}
```

### Step 2: Add Events for Pagination

```dart
// lib/features/expenses/presentation/bloc/expense_event.dart

class LoadMoreExpensesRequested extends ExpenseEvent {
  final int userId;
  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadMoreExpensesRequested(
    this.userId, {
    this.category,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [userId, category, startDate, endDate];
}

class RefreshExpensesRequested extends ExpenseEvent {
  final int userId;
  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;

  const RefreshExpensesRequested(
    this.userId, {
    this.category,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [userId, category, startDate, endDate];
}
```

### Step 3: Update BLoC to Handle Pagination

```dart
// lib/features/expenses/presentation/bloc/expense_bloc.dart

import 'package:finance_app/core/utils/pagination_helper.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  // ... existing code ...

  ExpenseBloc({
    // ... existing dependencies ...
  }) : super(const ExpenseInitial()) {
    // ... existing event handlers ...
    on<LoadMoreExpensesRequested>(_onLoadMoreExpensesRequested);
    on<RefreshExpensesRequested>(_onRefreshExpensesRequested);
  }

  Future<void> _onLoadExpensesRequested(
    LoadExpensesRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading(syncStatusMap: _syncStatusMap));

    try {
      // Call API with pagination
      final result = await expenseRepository.getExpenses(
        userId: event.userId,
        page: 1,
        perPage: PaginationHelper.defaultPageSize,
        category: event.category,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(ExpenseLoaded(
        result.data,
        currentPage: result.meta.currentPage,
        totalPages: result.meta.totalPages,
        syncStatusMap: _syncStatusMap,
      ));
    } catch (e) {
      emit(ExpenseError(e.toString(), syncStatusMap: _syncStatusMap));
    }
  }

  Future<void> _onLoadMoreExpensesRequested(
    LoadMoreExpensesRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ExpenseLoaded) return;
    if (!currentState.hasMorePages || currentState.isLoadingMore) return;

    // Set loading more flag
    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = currentState.currentPage + 1;
      
      final result = await expenseRepository.getExpenses(
        userId: event.userId,
        page: nextPage,
        perPage: PaginationHelper.defaultPageSize,
        category: event.category,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      // Merge new data with existing
      emit(currentState.copyWith(
        expenses: [...currentState.expenses, ...result.data],
        currentPage: result.meta.currentPage,
        totalPages: result.meta.totalPages,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
      emit(ExpenseError(e.toString(), syncStatusMap: _syncStatusMap));
    }
  }

  Future<void> _onRefreshExpensesRequested(
    RefreshExpensesRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    // Just reload from first page
    add(LoadExpensesRequested(
      event.userId,
      category: event.category,
      startDate: event.startDate,
      endDate: event.endDate,
    ));
  }
}
```

### Step 4: Update Repository to Return PaginatedResponse

```dart
// lib/features/expenses/domain/repositories/expense_repository.dart

import 'package:finance_app/core/utils/pagination_helper.dart';

abstract class ExpenseRepository {
  Future<PaginatedResponse<Expense>> getExpenses({
    required int userId,
    int page = 1,
    int perPage = 15,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  // ... other methods ...
}
```

```dart
// lib/features/expenses/data/repositories/expense_repository_impl.dart

@override
Future<PaginatedResponse<Expense>> getExpenses({
  required int userId,
  int page = 1,
  int perPage = 15,
  String? category,
  DateTime? startDate,
  DateTime? endDate,
}) async {
  try {
    final result = await apiDataSource.getExpenses(
      page: page,
      perPage: perPage,
      category: category,
      startDate: startDate,
      endDate: endDate,
    );

    // Convert DTOs to entities
    final expenses = result.data
        .map((dto) => Expense.fromDto(dto))
        .toList();

    return PaginatedResponse(
      data: expenses,
      meta: result.meta,
    );
  } catch (e) {
    // Fallback to local data if API fails
    final localExpenses = await localDataSource.getExpenses(userId);
    return PaginatedResponse(
      data: localExpenses,
      meta: PaginationMeta(
        currentPage: 1,
        perPage: localExpenses.length,
        totalItems: localExpenses.length,
        totalPages: 1,
      ),
    );
  }
}
```

### Step 5: Use InfiniteScrollList in UI

```dart
// lib/features/expenses/presentation/pages/expense_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finance_app/core/widgets/infinite_scroll_list.dart';
import 'package:finance_app/features/expenses/presentation/bloc/expense_bloc.dart';
import 'package:finance_app/features/expenses/presentation/bloc/expense_event.dart';
import 'package:finance_app/features/expenses/presentation/bloc/expense_state.dart';

class ExpenseListPage extends StatefulWidget {
  final int userId;
  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;

  const ExpenseListPage({
    Key? key,
    required this.userId,
    this.category,
    this.startDate,
    this.endDate,
  }) : super(key: key);

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() {
    context.read<ExpenseBloc>().add(
          LoadExpensesRequested(
            widget.userId,
            category: widget.category,
            startDate: widget.startDate,
            endDate: widget.endDate,
          ),
        );
  }

  void _loadMore() {
    context.read<ExpenseBloc>().add(
          LoadMoreExpensesRequested(
            widget.userId,
            category: widget.category,
            startDate: widget.startDate,
            endDate: widget.endDate,
          ),
        );
  }

  Future<void> _refresh() async {
    context.read<ExpenseBloc>().add(
          RefreshExpensesRequested(
            widget.userId,
            category: widget.category,
            startDate: widget.startDate,
            endDate: widget.endDate,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter dialog
            },
          ),
        ],
      ),
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
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadExpenses,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ExpenseLoaded) {
            return InfiniteScrollList<Expense>(
              items: state.expenses,
              isLoading: false,
              hasMore: state.hasMorePages,
              onLoadMore: _loadMore,
              onRefresh: _refresh,
              itemBuilder: (context, expense) {
                return ExpenseListTile(
                  expense: expense,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/expense-detail',
                      arguments: expense,
                    );
                  },
                );
              },
              emptyMessage: 'No expenses found',
              separator: const Divider(height: 1),
              padding: const EdgeInsets.symmetric(vertical: 8),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-expense');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ExpenseListTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;

  const ExpenseListTile({
    Key? key,
    required this.expense,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(expense.category[0].toUpperCase()),
      ),
      title: Text(expense.description),
      subtitle: Text(
        '${expense.date.day}/${expense.date.month}/${expense.date.year}',
      ),
      trailing: Text(
        '\$${expense.amount.toStringAsFixed(2)}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }
}
```

## Alternative: Manual Load More Button

If you prefer a manual "Load More" button instead of infinite scroll:

```dart
Column(
  children: [
    Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.expenses.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return ExpenseListTile(
            expense: state.expenses[index],
            onTap: () {
              // Handle tap
            },
          );
        },
      ),
    ),
    LoadMoreButton(
      isLoading: state.isLoadingMore,
      hasMore: state.hasMorePages,
      onPressed: _loadMore,
      text: 'Load More Expenses',
    ),
  ],
)
```

## Performance Tips

1. **Use const constructors** where possible to reduce rebuilds
2. **Implement proper equality** in your state classes using Equatable
3. **Cache images** if your list items contain images
4. **Use ListView.builder** for very large lists (InfiniteScrollList uses it internally)
5. **Debounce scroll events** if you notice performance issues
6. **Consider using AutomaticKeepAliveClientMixin** for complex list items

## Testing

```dart
testWidgets('loads more expenses when scrolled to bottom', (tester) async {
  final mockBloc = MockExpenseBloc();
  
  when(() => mockBloc.state).thenReturn(
    ExpenseLoaded(
      [Expense(id: 1, description: 'Test')],
      currentPage: 1,
      totalPages: 2,
    ),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<ExpenseBloc>.value(
        value: mockBloc,
        child: ExpenseListPage(userId: 1),
      ),
    ),
  );

  // Scroll to bottom
  await tester.drag(
    find.byType(ListView),
    const Offset(0, -500),
  );
  await tester.pumpAndSettle();

  // Verify LoadMoreExpensesRequested was added
  verify(() => mockBloc.add(any(that: isA<LoadMoreExpensesRequested>()))).called(1);
});
```

## Common Issues and Solutions

### Issue: Duplicate items after loading more
**Solution**: Make sure you're appending, not replacing:
```dart
expenses: [...currentState.expenses, ...result.data]
```

### Issue: Infinite scroll triggers too early
**Solution**: Adjust the scroll threshold:
```dart
InfiniteScrollList(
  scrollThreshold: 0.9, // Load at 90% instead of 80%
  // ...
)
```

### Issue: Loading indicator doesn't show
**Solution**: Ensure `isLoadingMore` is properly set in your state

### Issue: Can't scroll after loading more
**Solution**: Make sure to set `isLoadingMore: false` after loading completes

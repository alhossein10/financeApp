# Pagination Utilities Usage Guide

This guide explains how to use the pagination utilities in the Finance App.

## Overview

The pagination system consists of three main components:

1. **PaginationHelper** - Utility class for pagination calculations
2. **PaginatedResponse** - Wrapper for paginated API responses
3. **InfiniteScrollList** - UI widget for infinite scroll functionality

## PaginationHelper

### Basic Usage

```dart
import 'package:finance_app/core/utils/pagination_helper.dart';

// Get pagination parameters for API request
final params = PaginationHelper.getPaginationParams(
  page: 1,
  perPage: 15,
);
// Returns: {'page': 1, 'per_page': 15}

// Check if there are more pages
final hasMore = PaginationHelper.hasMorePages(
  currentPage: 2,
  totalPages: 5,
);
// Returns: true

// Calculate total pages
final totalPages = PaginationHelper.calculateTotalPages(
  totalItems: 47,
  perPage: 15,
);
// Returns: 4

// Get next page number
final nextPage = PaginationHelper.getNextPage(
  currentPage: 2,
  totalPages: 5,
);
// Returns: 3
```

### Constants

```dart
PaginationHelper.defaultPageSize  // 15
PaginationHelper.maxPageSize      // 100
```

## PaginatedResponse

### Creating from API Response

```dart
import 'package:finance_app/core/utils/pagination_helper.dart';
import 'package:finance_app/features/expenses/data/models/expense_dto.dart';

// Parse API response
final response = await apiClient.get('/expenses', queryParams: {'page': 1});
final paginatedExpenses = PaginatedResponse<ExpenseDto>.fromJson(
  response.data,
  (json) => ExpenseDto.fromJson(json),
);

// Access data
final expenses = paginatedExpenses.data;
final hasMore = paginatedExpenses.hasMore;
final nextPage = paginatedExpenses.nextPage;
```

### Merging Responses (for Infinite Scroll)

```dart
// Load first page
PaginatedResponse<ExpenseDto> allExpenses = await loadExpenses(page: 1);

// Load more pages
final morExpenses = await loadExpenses(page: 2);
allExpenses = allExpenses.merge(moreExpenses);

// Now allExpenses.data contains items from both pages
```

### Empty Response

```dart
final emptyResponse = PaginatedResponse<ExpenseDto>.empty();
```

## PaginationMeta

### Accessing Metadata

```dart
final meta = paginatedResponse.meta;

print('Current page: ${meta.currentPage}');
print('Per page: ${meta.perPage}');
print('Total items: ${meta.totalItems}');
print('Total pages: ${meta.totalPages}');
print('Has next: ${meta.hasNextPage}');
print('Has previous: ${meta.hasPreviousPage}');
print('Is first: ${meta.isFirstPage}');
print('Is last: ${meta.isLastPage}');
```

## InfiniteScrollList Widget

### Basic Usage

```dart
import 'package:finance_app/core/widgets/infinite_scroll_list.dart';

InfiniteScrollList<Expense>(
  items: state.expenses,
  isLoading: state.isLoading,
  hasMore: state.hasMorePages,
  onLoadMore: () {
    context.read<ExpenseBloc>().add(LoadMoreExpenses());
  },
  itemBuilder: (context, expense) {
    return ExpenseListTile(expense: expense);
  },
  emptyMessage: 'No expenses found',
)
```

### With Pull-to-Refresh

```dart
InfiniteScrollList<Expense>(
  items: state.expenses,
  isLoading: state.isLoading,
  hasMore: state.hasMorePages,
  onLoadMore: () {
    context.read<ExpenseBloc>().add(LoadMoreExpenses());
  },
  onRefresh: () async {
    context.read<ExpenseBloc>().add(RefreshExpenses());
    await Future.delayed(const Duration(seconds: 1));
  },
  itemBuilder: (context, expense) {
    return ExpenseListTile(expense: expense);
  },
)
```

### Custom Empty Widget

```dart
InfiniteScrollList<Expense>(
  items: state.expenses,
  isLoading: state.isLoading,
  hasMore: state.hasMorePages,
  onLoadMore: () => context.read<ExpenseBloc>().add(LoadMoreExpenses()),
  itemBuilder: (context, expense) => ExpenseListTile(expense: expense),
  emptyWidget: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.receipt_long, size: 64, color: Colors.grey),
      SizedBox(height: 16),
      Text('No expenses yet'),
      SizedBox(height: 8),
      ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/add-expense'),
        child: Text('Add Expense'),
      ),
    ],
  ),
)
```

### Custom Loading Widget

```dart
InfiniteScrollList<Expense>(
  items: state.expenses,
  isLoading: state.isLoading,
  hasMore: state.hasMorePages,
  onLoadMore: () => context.read<ExpenseBloc>().add(LoadMoreExpenses()),
  itemBuilder: (context, expense) => ExpenseListTile(expense: expense),
  loadingWidget: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Loading expenses...'),
      ],
    ),
  ),
)
```

### With Custom Separator

```dart
InfiniteScrollList<Expense>(
  items: state.expenses,
  isLoading: state.isLoading,
  hasMore: state.hasMorePages,
  onLoadMore: () => context.read<ExpenseBloc>().add(LoadMoreExpenses()),
  itemBuilder: (context, expense) => ExpenseListTile(expense: expense),
  separator: Divider(height: 1),
)
```

### Adjust Scroll Threshold

```dart
InfiniteScrollList<Expense>(
  items: state.expenses,
  isLoading: state.isLoading,
  hasMore: state.hasMorePages,
  onLoadMore: () => context.read<ExpenseBloc>().add(LoadMoreExpenses()),
  itemBuilder: (context, expense) => ExpenseListTile(expense: expense),
  scrollThreshold: 0.9, // Load more at 90% scrolled (default is 0.8)
)
```

## LoadMoreButton Widget

For manual "Load More" button instead of infinite scroll:

```dart
import 'package:finance_app/core/widgets/infinite_scroll_list.dart';

Column(
  children: [
    // Your list items
    ...expenses.map((e) => ExpenseListTile(expense: e)),
    
    // Load more button
    LoadMoreButton(
      isLoading: state.isLoadingMore,
      hasMore: state.hasMorePages,
      onPressed: () {
        context.read<ExpenseBloc>().add(LoadMoreExpenses());
      },
      text: 'Load More Expenses',
    ),
  ],
)
```

## BLoC Integration

### State Definition

```dart
class ExpenseState {
  final List<Expense> expenses;
  final bool isLoading;
  final bool isLoadingMore;
  final int currentPage;
  final int totalPages;
  final String? error;

  bool get hasMorePages => currentPage < totalPages;

  ExpenseState({
    this.expenses = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.currentPage = 1,
    this.totalPages = 1,
    this.error,
  });
}
```

### Events

```dart
abstract class ExpenseEvent {}

class LoadExpenses extends ExpenseEvent {}

class LoadMoreExpenses extends ExpenseEvent {}

class RefreshExpenses extends ExpenseEvent {}
```

### BLoC Implementation

```dart
class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository repository;

  ExpenseBloc({required this.repository}) : super(ExpenseState()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<LoadMoreExpenses>(_onLoadMoreExpenses);
    on<RefreshExpenses>(_onRefreshExpenses);
  }

  Future<void> _onLoadExpenses(
    LoadExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final result = await repository.getExpenses(
        page: 1,
        perPage: PaginationHelper.defaultPageSize,
      );

      emit(state.copyWith(
        expenses: result.data,
        currentPage: result.meta.currentPage,
        totalPages: result.meta.totalPages,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreExpenses(
    LoadMoreExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    if (!state.hasMorePages || state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final nextPage = state.currentPage + 1;
      final result = await repository.getExpenses(
        page: nextPage,
        perPage: PaginationHelper.defaultPageSize,
      );

      emit(state.copyWith(
        expenses: [...state.expenses, ...result.data],
        currentPage: result.meta.currentPage,
        totalPages: result.meta.totalPages,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshExpenses(
    RefreshExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    // Reset to first page
    add(LoadExpenses());
  }
}
```

## API Data Source Integration

### Example: Expense API Data Source

```dart
class ExpenseApiDataSourceImpl implements ExpenseApiDataSource {
  final ApiClient apiClient;

  ExpenseApiDataSourceImpl({required this.apiClient});

  @override
  Future<PaginatedResponse<ExpenseDto>> getExpenses({
    int page = 1,
    int perPage = 15,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = PaginationHelper.getPaginationParams(
      page: page,
      perPage: perPage,
    );

    if (category != null) queryParams['category'] = category;
    if (startDate != null) queryParams['date_from'] = formatDate(startDate);
    if (endDate != null) queryParams['date_to'] = formatDate(endDate);

    final response = await apiClient.get(
      '/expenses',
      queryParams: queryParams,
    );

    return PaginatedResponse<ExpenseDto>.fromJson(
      response.data,
      (json) => ExpenseDto.fromJson(json),
    );
  }
}
```

## Best Practices

1. **Use Default Page Size**: Stick to `PaginationHelper.defaultPageSize` (15) for consistency
2. **Handle Loading States**: Always show loading indicators for better UX
3. **Implement Pull-to-Refresh**: Allow users to refresh the list easily
4. **Cache Data**: Consider caching paginated data to reduce API calls
5. **Error Handling**: Show appropriate error messages when pagination fails
6. **Empty States**: Provide helpful empty state messages and actions
7. **Scroll Position**: Maintain scroll position when navigating back to lists
8. **Performance**: Use `ListView.builder` or `ListView.separated` for large lists

## Testing

### Unit Tests

```dart
test('PaginationHelper calculates total pages correctly', () {
  final totalPages = PaginationHelper.calculateTotalPages(
    totalItems: 47,
    perPage: 15,
  );
  expect(totalPages, 4);
});

test('PaginatedResponse merges correctly', () {
  final page1 = PaginatedResponse<int>(
    data: [1, 2, 3],
    meta: PaginationMeta(currentPage: 1, perPage: 3, totalItems: 6, totalPages: 2),
  );
  
  final page2 = PaginatedResponse<int>(
    data: [4, 5, 6],
    meta: PaginationMeta(currentPage: 2, perPage: 3, totalItems: 6, totalPages: 2),
  );
  
  final merged = page1.merge(page2);
  expect(merged.data, [1, 2, 3, 4, 5, 6]);
  expect(merged.meta.currentPage, 2);
});
```

### Widget Tests

```dart
testWidgets('InfiniteScrollList shows empty state', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: InfiniteScrollList<String>(
          items: [],
          isLoading: false,
          hasMore: false,
          onLoadMore: () {},
          itemBuilder: (context, item) => Text(item),
          emptyMessage: 'No items',
        ),
      ),
    ),
  );

  expect(find.text('No items'), findsOneWidget);
});
```

## Troubleshooting

### Issue: Infinite scroll not triggering

**Solution**: Check that `hasMore` is true and `scrollThreshold` is appropriate. Try lowering the threshold to 0.7.

### Issue: Duplicate items after loading more

**Solution**: Ensure you're appending new items, not replacing: `[...state.items, ...newItems]`

### Issue: Loading indicator stuck

**Solution**: Make sure to set `isLoading` or `isLoadingMore` to false in all code paths, including error cases.

### Issue: Scroll position resets

**Solution**: Use a custom `ScrollController` and maintain it across rebuilds.

## Related Files

- `lib/core/utils/pagination_helper.dart` - Core pagination utilities
- `lib/core/widgets/infinite_scroll_list.dart` - UI widgets
- `lib/features/expenses/data/datasources/expense_api_datasource.dart` - Example implementation
- `lib/features/expenses/presentation/bloc/expense_bloc.dart` - Example BLoC integration

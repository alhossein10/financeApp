# Admin Dashboard API - Quick Reference

## Overview

The Admin Dashboard provides comprehensive statistics, user activity, expense summaries, and analytics for admin users. All data is automatically scoped to the admin's group.

---

## API Endpoints

### 1. Dashboard Statistics
```dart
GET /admin/dashboard/stats
```

**Returns:**
- Total users in admin group
- Total expenses count
- Total income count
- Total transfers count
- Total expense amount
- Total income amount
- Fund box balance

**Usage:**
```dart
context.read<AdminBloc>().add(const FetchDashboardStatsRequested());
```

---

### 2. User Activity
```dart
GET /admin/dashboard/users
```

**Returns:**
- List of users in admin group
- User name, email, role
- Account creation date
- Last login timestamp

**Usage:**
```dart
context.read<AdminBloc>().add(const FetchUserActivityRequested());
```

---

### 3. Expense Summaries
```dart
GET /admin/dashboard/expenses
```

**Returns:**
- Expenses grouped by category
- Expenses grouped by payment method
- Count and total for each group

**Usage:**
```dart
context.read<AdminBloc>().add(const FetchExpenseSummariesRequested());
```

---

### 4. Analytics with Date Range
```dart
GET /admin/dashboard/analytics?date_from=YYYY-MM-DD&date_to=YYYY-MM-DD
```

**Returns:**
- Expense analytics (total, count, average)
- Income analytics (total, count, average)
- Net balance
- Monthly trends

**Usage:**
```dart
context.read<AdminBloc>().add(FetchAnalyticsRequested(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 12, 31),
));
```

---

## UI Features

### Date Range Selector
- Default: Last 30 days
- Tap to select custom range
- Visual display of selected dates
- Automatic analytics refresh

### Statistics Cards
- 6 key metrics displayed in grid
- Color-coded for easy reading
- Real-time updates
- Pull-to-refresh support

### User Activity List
- All users in admin group
- Role-based color coding
- Last login information
- Empty state handling

### Expense Summaries
- Category breakdown
- Payment method breakdown
- Count and total for each
- Visual card layout

### Analytics Dashboard
- Period information
- Expense vs Income comparison
- Net balance calculation
- Monthly trends visualization

---

## Access Control

### Requirements
1. ✅ Admin flavor enabled
2. ✅ User has admin role
3. ✅ Valid Bearer token

### Error Handling
- **403 Forbidden**: Access denied message
- **401 Unauthorized**: Automatic token refresh
- **Network Error**: Retry button
- **No Data**: Empty state message

---

## Data Scoping

All dashboard data is automatically filtered by `admin_group_id`:

✅ Admins only see their group's data
✅ No manual filtering required
✅ Backend enforces isolation
✅ Secure and private

---

## State Management

### States
- `AdminLoading`: Data is being fetched
- `AdminDashboardStatsLoaded`: Statistics loaded
- `AdminUserActivityLoaded`: User activity loaded
- `AdminExpenseSummariesLoaded`: Summaries loaded
- `AdminAnalyticsLoaded`: Analytics loaded
- `AdminError`: Error occurred

### Events
- `FetchDashboardStatsRequested`: Fetch statistics
- `FetchUserActivityRequested`: Fetch user activity
- `FetchExpenseSummariesRequested`: Fetch summaries
- `FetchAnalyticsRequested`: Fetch analytics

---

## Example: Complete Dashboard Load

```dart
void _loadDashboardData() {
  // Fetch all dashboard data
  context.read<AdminBloc>().add(const FetchDashboardStatsRequested());
  context.read<AdminBloc>().add(const FetchUserActivityRequested());
  context.read<AdminBloc>().add(const FetchExpenseSummariesRequested());
  
  // Fetch analytics with date range
  context.read<AdminBloc>().add(FetchAnalyticsRequested(
    startDate: DateTime.now().subtract(const Duration(days: 30)),
    endDate: DateTime.now(),
  ));
}
```

---

## Example: Handle Dashboard States

```dart
BlocBuilder<AdminBloc, AdminState>(
  builder: (context, state) {
    if (state is AdminLoading) {
      return const CircularProgressIndicator();
    }
    
    if (state is AdminDashboardStatsLoaded) {
      return Column(
        children: [
          Text('Total Users: ${state.totalUsers}'),
          Text('Total Expenses: ${state.totalExpenses}'),
          Text('Fund Box: \$${state.fundBoxBalance}'),
        ],
      );
    }
    
    if (state is AdminError) {
      return Column(
        children: [
          Text(state.message),
          ElevatedButton(
            onPressed: _loadDashboardData,
            child: const Text('Retry'),
          ),
        ],
      );
    }
    
    return const Text('No data available');
  },
)
```

---

## Testing

### Unit Tests
```dart
test('should fetch dashboard stats with Bearer token', () async {
  // Arrange
  when(mockApiClient.get('/admin/dashboard/stats'))
      .thenAnswer((_) async => ApiResponse(statusCode: 200, data: {...}));
  
  // Act
  final result = await dataSource.getStats();
  
  // Assert
  expect(result, isA<AdminStatsDto>());
  verify(mockApiClient.get('/admin/dashboard/stats')).called(1);
});
```

### Integration Tests
```dart
testWidgets('should display dashboard statistics', (tester) async {
  // Arrange
  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle();
  
  // Act
  await tester.tap(find.text('Dashboard'));
  await tester.pumpAndSettle();
  
  // Assert
  expect(find.text('Total Users'), findsOneWidget);
  expect(find.text('Total Expenses'), findsOneWidget);
});
```

---

## Troubleshooting

### Issue: 403 Forbidden
**Solution**: Ensure user has admin role and admin flavor is enabled

### Issue: No data displayed
**Solution**: Check network connection and verify backend is running

### Issue: Token expired
**Solution**: Token refresh is automatic, but user may need to re-login

### Issue: Wrong data displayed
**Solution**: Verify admin_group_id is correct in user token

---

## Best Practices

1. ✅ Always check admin role before loading data
2. ✅ Use pull-to-refresh for data updates
3. ✅ Handle all error states gracefully
4. ✅ Show loading indicators during fetch
5. ✅ Implement empty states for no data
6. ✅ Use date range filters for analytics
7. ✅ Cache data when appropriate
8. ✅ Test with different admin groups

---

## Related Documentation

- [Bearer Token Implementation](./BEARER_TOKEN_VERIFICATION.md)
- [Admin API Documentation](./API_DOCUMENTATION.md)
- [Error Handling Guide](./ERROR_HANDLING_GUIDE.md)
- [Role-Based Access Control](./RBAC_GUIDE.md)

---

**Last Updated**: November 15, 2024
**Status**: ✅ Complete and Verified

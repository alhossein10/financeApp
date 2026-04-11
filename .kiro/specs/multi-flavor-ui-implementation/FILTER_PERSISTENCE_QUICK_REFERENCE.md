# Filter Persistence Quick Reference

## Overview

The Filter Persistence feature allows users to maintain their filter selections when navigating between Expenses and Export pages. Filters are stored in memory during the current session and automatically cleared on logout.

## Requirements Implemented

- **26.1**: Filters applied on Expenses page are remembered
- **26.2**: Filters are automatically applied when navigating to Export page
- **26.3**: Filters are restored when returning to Expenses page
- **26.4**: Filters persist during the current session
- **26.5**: Filters are cleared when user logs out
- **26.6**: "Clear Filters" button resets all filters
- **26.7**: Active filter count indicator is displayed
- **26.8**: Active filter buttons are highlighted

## FilterPersistenceService

### Location
`lib/core/services/filter_persistence_service.dart`

### Features

The service is a singleton that manages filter state for both Admin and User roles:

#### Admin Filters
- Date range filter
- Currency filter (USD, SYP, TRY)
- User filter (specific user or all users)

#### User Filters
- Date range filter
- Currency filter (USD, SYP, TRY)

### Key Methods

```dart
// Get singleton instance
final filterService = FilterPersistenceService();

// Set Admin filters
filterService.setAdminFilters(
  dateRange: DateTimeRange(...),
  currencyFilter: 'USD',
  userFilter: 123,
);

// Set User filters
filterService.setUserFilters(
  dateRange: DateTimeRange(...),
  currencyFilter: 'SYP',
);

// Clear filters
filterService.clearAdminFilters();
filterService.clearUserFilters();
filterService.clearAllFilters(); // Called on logout

// Get active filter count
int adminCount = filterService.getAdminActiveFilterCount();
int userCount = filterService.getUserActiveFilterCount();

// Check if filters are active
bool hasAdminFilters = filterService.hasAdminActiveFilters;
bool hasUserFilters = filterService.hasUserActiveFilters;

// Access individual filters
DateTimeRange? dateRange = filterService.adminDateRange;
String? currency = filterService.adminCurrencyFilter;
int? userId = filterService.adminUserFilter;
```

## Integration Points

### 1. Expenses Pages

Both Admin and User expenses pages:
- Restore filters from service on `initState()`
- Persist filters to service when changed
- Display active filter count in app bar
- Provide "Clear Filters" button

**Files:**
- `lib/features/admin/presentation/pages/admin_expenses_page.dart`
- `lib/features/user/presentation/pages/user_expenses_page.dart`

### 2. Export Pages

Both Admin and User export pages:
- Read filters from service (no parameters needed)
- Display active filters in a card
- Apply filters to export operations

**Files:**
- `lib/features/admin/presentation/pages/admin_export_page.dart`
- `lib/features/user/presentation/pages/user_export_page.dart`

### 3. Authentication

The AuthBloc clears all filters on logout:

**File:** `lib/features/auth/presentation/bloc/auth_bloc.dart`

```dart
Future<void> _onLogoutRequested(...) async {
  // Clear all persisted filters on logout
  FilterPersistenceService().clearAllFilters();
  // ... rest of logout logic
}
```

## User Experience Flow

### Admin Flow

1. **Expenses Page**
   - Admin applies filters (date range, currency, specific user)
   - Filter count badge shows in app bar (e.g., "3")
   - Filters are automatically persisted

2. **Navigate to Export Page**
   - Export page automatically loads the same filters
   - Active filters are displayed in a card
   - Export operations use these filters

3. **Return to Expenses Page**
   - Filters are still active
   - Same filter selections are maintained

4. **Clear Filters**
   - Click "Clear All" button
   - All filters reset to default
   - Filter count badge disappears

5. **Logout**
   - All filters are automatically cleared
   - Next login starts with clean state

### User Flow

Same as Admin flow, but without the user filter option.

## Visual Indicators

### Active Filter Count Badge

Displayed in the app bar when filters are active:

```dart
if (_dateRange != null || _currencyFilter != null || _userFilter != null)
  Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(Icons.filter_alt, size: 16),
        SizedBox(width: 4),
        Text(_getActiveFilterCount().toString()),
      ],
    ),
  ),
```

### Filter Chips

Active filters are shown as chips in the Export page:

```dart
Chip(
  avatar: Icon(Icons.calendar_today, size: 16),
  label: Text('Jan 1 - Jan 31'),
),
Chip(
  avatar: Icon(Icons.attach_money, size: 16),
  label: Text('USD'),
),
```

### Highlighted Filter Buttons

FilterChip widgets show selected state:

```dart
FilterChip(
  label: Text('Date Range'),
  selected: _dateRange != null, // Highlighted when active
  onSelected: (_) => _selectDateRange(),
),
```

## Testing

### Manual Testing Checklist

1. ✅ Apply filters on Expenses page
2. ✅ Navigate to Export page - filters should be applied
3. ✅ Return to Expenses page - filters should be restored
4. ✅ Clear filters - all filters should reset
5. ✅ Apply filters and logout - filters should be cleared
6. ✅ Login again - no filters should be active
7. ✅ Filter count badge shows correct number
8. ✅ Active filters are highlighted

### Unit Testing

Test the FilterPersistenceService:

```dart
test('should persist admin filters', () {
  final service = FilterPersistenceService();
  final dateRange = DateTimeRange(
    start: DateTime(2024, 1, 1),
    end: DateTime(2024, 1, 31),
  );
  
  service.setAdminFilters(
    dateRange: dateRange,
    currencyFilter: 'USD',
    userFilter: 123,
  );
  
  expect(service.adminDateRange, dateRange);
  expect(service.adminCurrencyFilter, 'USD');
  expect(service.adminUserFilter, 123);
  expect(service.getAdminActiveFilterCount(), 3);
});

test('should clear all filters', () {
  final service = FilterPersistenceService();
  service.setAdminFilters(currencyFilter: 'USD');
  service.setUserFilters(currencyFilter: 'SYP');
  
  service.clearAllFilters();
  
  expect(service.hasAdminActiveFilters, false);
  expect(service.hasUserActiveFilters, false);
});
```

## Benefits

1. **Improved UX**: Users don't lose their filter context when navigating
2. **Consistency**: Same filters apply to both viewing and exporting
3. **Efficiency**: No need to re-apply filters on each page
4. **Clean State**: Automatic cleanup on logout prevents stale data
5. **Visual Feedback**: Clear indicators show when filters are active

## Limitations

- Filters are stored in memory only (not persisted to disk)
- Filters are cleared on app restart
- Filters are session-specific (cleared on logout)
- No filter history or saved filter sets

## Future Enhancements

Potential improvements for future versions:

1. Persist filters to local storage for cross-session persistence
2. Save named filter presets
3. Filter history with quick access to recent filters
4. Share filter configurations between team members
5. Advanced filter combinations with AND/OR logic

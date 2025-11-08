# Cash Inbox Filters Implementation

## Overview
Added date filtering and user filtering (for admin flavor) to the Cash Inbox page, with filters applied to both the UI display and PDF export.

## Changes Made

### 1. Cash Inbox Page (`lib/ui/cash_inbox_page.dart`)

#### Added Filter State
- `DateFilter _dateFilter` - Tracks the current date filter selection
- `String? _selectedUser` - Tracks the selected user for filtering (admin only)
- `List<GroupMember> _groupMembers` - Stores group members for user filter dropdown

#### Added Filter UI
- **Date Filter Button**: Dropdown menu with options:
  - All Dates
  - Today
  - This Week
  - This Month
  - Custom Range (with date picker dialogs)
  
- **User Filter Button** (Admin flavor only):
  - Dropdown showing all group members
  - Filters transfers by recipient name
  - Only visible when group members are loaded

- **Clear Filters Button**:
  - Appears when any filter is active
  - Resets all filters to default state

#### Filter Logic

**Date Filtering** (`_filterTransfers` and `_filterIncoming`):
- Filters both transfers and incoming transactions by transaction date
- Supports:
  - Today: Same day as current date
  - This Week: Current week (Monday to Sunday)
  - This Month: Current month
  - Custom Range: User-selected start and end dates

**User Filtering** (`_filterTransfers`):
- Only applies to transfers (outgoing transactions)
- Filters by recipient name matching selected user
- Only active in admin flavor when a user is selected

#### Group Members Loading
- Loads group members on page initialization for admin flavor
- Uses `AdminGroupBloc` to fetch members
- Listens to state changes to update `_groupMembers` list

#### PDF Export Integration
- Filtered data is automatically used when exporting to PDF
- `_exportCash()` method uses `_filterTransfers()` and `_filterIncoming()`
- Exported PDF only includes transactions matching active filters

### 2. Localization (`lib/l10n/app_localizations.dart`)

#### Added English Translations
```dart
'filter_by_date': 'Filter by Date',
'filter_by_user': 'Filter by User',
'all_dates': 'All Dates',
'all_users': 'All Users',
'custom_range': 'Custom Range',
'clear_filters': 'Clear Filters',
```

#### Added Arabic Translations
```dart
'filter_by_date': 'تصفية حسب التاريخ',
'filter_by_user': 'تصفية حسب المستخدم',
'all_dates': 'كل التواريخ',
'all_users': 'كل المستخدمين',
'custom_range': 'نطاق مخصص',
'clear_filters': 'مسح التصفية',
```

### 3. Dependencies
- Uses existing `DateFilter` and `DateFilterType` from `lib/state/filters.dart`
- Uses `GroupMember` entity from admin group feature
- Uses `AdminGroupBloc` for loading group members

## Features

### Date Filter
1. **All Dates** (Default): Shows all transactions
2. **Today**: Shows only today's transactions
3. **This Week**: Shows transactions from Monday to Sunday of current week
4. **This Month**: Shows transactions from current month
5. **Custom Range**: User selects start and end dates via date picker

### User Filter (Admin Only)
1. Shows dropdown with all group members
2. Filters transfers by recipient name
3. "All Users" option to clear user filter
4. Only visible in admin flavor
5. Only appears when group members are loaded

### Clear Filters
- Single button to reset all filters
- Only visible when filters are active
- Resets to default state (All Dates, All Users)

### PDF Export
- Automatically applies active filters to exported data
- Filtered transfers and incoming transactions are included in PDF
- Export button remains in same location
- No changes needed to `PdfExportHelper` - filtering happens before export

## UI Layout

```
[Date Filter Icon] [User Filter Icon] [Clear Icon] ... [Export PDF Icon]
```

- Filters are in a horizontal scrollable row
- Date filter always visible
- User filter only visible for admin with loaded members
- Clear button only visible when filters active
- Export button aligned to the right

## Testing Recommendations

1. **Date Filtering**:
   - Test each date filter option
   - Verify custom range date picker works
   - Check that filtered data displays correctly
   - Verify PDF export includes only filtered data

2. **User Filtering** (Admin):
   - Test user dropdown appears for admin
   - Verify filtering by different users
   - Check "All Users" option clears filter
   - Test with no group members loaded

3. **Combined Filters**:
   - Test date + user filter together
   - Verify clear filters resets both
   - Check PDF export with multiple filters

4. **User Flavor**:
   - Verify user filter doesn't appear in user flavor
   - Check date filter works in user flavor

## Notes

- User filter only applies to transfers (outgoing), not incoming transactions
- Incoming transactions are only filtered by date
- Group members are loaded automatically on page load for admin flavor
- Filters persist during the page session but reset on page reload
- PDF export filename remains unchanged ("cash_transactions.pdf")

## Technical Implementation Details

### Stream Subscription Management
- Uses `StreamSubscription<AdminGroupState>` to listen to group member updates
- Properly cancels subscription in `dispose()` to prevent memory leaks
- Uses `Future.microtask()` to schedule state updates and avoid rendering conflicts
- Handles both context-based and dependency injection-based AdminGroupBloc access

### Rendering Issue Fix
The initial implementation caused Flutter rendering assertions due to `setState` being called during the build phase. This was fixed by:
1. Using `Future.microtask()` instead of `WidgetsBinding.instance.addPostFrameCallback()`
2. Properly managing stream subscriptions with cancellation
3. Separating group member loading into its own method `_loadGroupMembers()`

# Fix: New Expenses Not Showing in App

**Issue**: Latest expenses show in database but not in the app

---

## Root Causes

1. **Cache Issue**: App caches expense list, new expenses don't invalidate cache properly
2. **Pagination**: API returns only 15 expenses per page (default)
3. **No Refresh**: App doesn't reload after creating expense

---

## Quick Fix

### Option 1: Clear Cache After Creation (Recommended)

The code already does this, but let's verify it's working:

**Check**: `lib/features/expenses/data/repositories/expense_repository_impl.dart`

Line ~127 should have:
```dart
await cacheDataSource.clearAllCache(); // Clear list caches
```

If this exists but still not working, the cache service might not be clearing properly.

### Option 2: Increase Per Page Limit

**File**: `lib/features/expenses/data/datasources/expense_api_datasource.dart`

**Change line ~48**:
```dart
// FROM:
int perPage = 15,

// TO:
int perPage = 100,  // Show more expenses
```

### Option 3: Force Reload After Creation

**File**: `lib/ui/expense_page.dart`

After creating expense, force reload. Find the `_addExpense` method and ensure it calls `_reload()`.

---

## Complete Solution

### Step 1: Increase Default Page Size

```dart
// lib/features/expenses/data/datasources/expense_api_datasource.dart
@override
Future<ExpenseListResponse> getExpenses({
  int page = 1,
  int perPage = 100,  // Changed from 15 to 100
  String? category,
  DateTime? startDate,
  DateTime? endDate,
  SyncStatus? syncStatus,
}) async {
```

### Step 2: Clear Cache Properly

```dart
// lib/features/expenses/data/repositories/expense_repository_impl.dart
// After creating expense:
await cacheDataSource.cacheExpense(createdDto);
await cacheDataSource.clearAllCache(); // This should clear list cache
```

### Step 3: Force UI Reload

The `ExpensePage` already has `_reload()` method. Make sure it's called after creation.

---

## Test

1. Create new expense
2. Should appear immediately in list
3. If not, pull to refresh
4. Should show all expenses (up to 100)

---

## Alternative: Remove Pagination Entirely

If you want to show ALL expenses without pagination:

**File**: `lib/features/expenses/data/datasources/expense_api_datasource.dart`

```dart
int perPage = 1000,  // Very large number to get all
```

**Note**: This works for small datasets but may be slow with thousands of expenses.

---

## Recommended: Implement Infinite Scroll

For better UX with many expenses:

1. Load first 15 expenses
2. When user scrolls to bottom, load next 15
3. Continue until all loaded

This requires more changes but provides best performance.

---

## Quick Test

Run this to see how many expenses are in database:

```bash
# In Laravel project
php artisan tinker
DB::table('expenses')->count();
exit
```

If you have more than 15 expenses, that's why new ones don't show (pagination).

---

## Immediate Fix (Copy & Paste)

Edit `lib/features/expenses/data/datasources/expense_api_datasource.dart`:

Find line ~48:
```dart
int perPage = 15,
```

Change to:
```dart
int perPage = 100,
```

Save, rebuild app, done!

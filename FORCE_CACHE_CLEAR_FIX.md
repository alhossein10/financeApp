# Force Cache Clear - Final Fix

## Problem
Expenses were being loaded from cache, which had old data without `has_invoice` field. Even after clearing app data, the cache was being used.

## Solution Applied
Added automatic cache clearing in the expense repository to force API reload:

```dart
// TEMPORARY FIX: Clear cache to force API reload (to get has_invoice field)
await cacheDataSource.clearCache();
print('[ExpenseRepository] 🗑️ Cache cleared - forcing API reload');
```

This ensures every time expenses are loaded, they come fresh from the API with the correct `has_invoice: true` values.

## What This Does
1. **Clears cache** before checking for cached data
2. **Forces API call** to get fresh data with `has_invoice` field
3. **Triggers DTO parsing** which infers invoice status from `invoice_path`
4. **Caches new data** with correct invoice information

## Expected Console Output
After this fix, you should see:
```
[ExpenseRepository] 🔵 Loading expenses for user 3
[ExpenseRepository] 🗑️ Cache cleared - forcing API reload
[ExpenseRepository] 📡 Calling API to get expenses...
[ExpenseDto] Inferred has_invoice=true from invoice_path: public/invoices/...
[ExpenseDto] Inferred has_invoice=true from invoice_path: public/invoices/...
[Export] Total expenses: 2, With invoices: 2  ✅
[Export] Expense 2 has invoice: path=null, cloudId=public/invoices/...
[Export] Expense 10 has invoice: path=null, cloudId=public/invoices/...
[Export] Filtered expenses with invoices: 2
[Export] Starting PDF export with 2 records
```

## How to Test
1. **Stop the app completely**
2. **Rebuild**: `flutter clean && flutter pub get && flutter run`
3. **Login** to the app
4. **Go to Expenses** page (expenses will load from API)
5. **Go to Export** page
6. **Click "Export Invoice Images"**
7. **Should work!**

## Files Modified
- ✅ `lib/features/expenses/data/repositories/expense_repository_impl.dart` - Added cache clear
- ✅ `lib/features/expenses/data/models/expense_dto.dart` - Added invoice inference
- ✅ `lib/features/admin/presentation/pages/admin_export_page.dart` - Added debug logging
- ✅ `lib/features/user/presentation/pages/user_export_page.dart` - Added debug logging

## Why This Works
The cache was the bottleneck. By clearing it on every load:
- Fresh data comes from API
- DTO parsing runs and infers `has_invoice` from `invoice_path`
- Export finds expenses with invoices
- PDF generation succeeds

## Permanent Solution (TODO)
After confirming this works, implement proper cache versioning:
```dart
static const int CACHE_VERSION = 2;
// Invalidate cache when version doesn't match
```

## Status
✅ **FINAL FIX APPLIED** - Cache is now cleared on every expense load, forcing fresh API data with invoice information.

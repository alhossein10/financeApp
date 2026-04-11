# Cache Issue - Root Cause Found!

## The Real Problem

Your API response is CORRECT:
```json
{
  "has_invoice": true,  ✅ This is correct!
  "invoice_path": "public/invoices/..."
}
```

But your app logs show:
```
[ExpenseRepository] ✅ Found 2 expenses in cache
[Export] Total expenses: 2, With invoices: 0  ❌
```

**The expenses are loaded from CACHE, not from the API!**

The cached data was saved BEFORE your backend had the `has_invoice` field, so the cached expenses have `has_invoice: false`.

## Quick Fix

### Option 1: Clear App Data (Easiest)

On your device:
1. Go to Settings → Apps → Your App
2. Click "Storage"
3. Click "Clear Data" or "Clear Cache"
4. Restart the app

This will force the app to reload from the API.

### Option 2: Force API Reload (In Code)

Add a button or pull-to-refresh that bypasses cache:

In your expense page, add:
```dart
// Force reload from API, bypassing cache
context.read<ExpenseBloc>().add(LoadExpensesRequested(_currentUserId!, forceRefresh: true));
```

### Option 3: Invalidate Cache Programmatically

Add this to your expense repository to clear old cache:

```dart
// In expense_repository_impl.dart
Future<void> clearCache() async {
  await cacheDataSource.clearAll();
}
```

## Why This Happened

1. **Before**: Backend didn't send `has_invoice`
2. **App cached** expenses with `has_invoice: false`
3. **Backend updated** to send `has_invoice: true`
4. **App still uses** old cached data
5. **Export fails** because cached data says no invoices

## Permanent Solution

Update your cache invalidation strategy:

```dart
// In expense_cache_datasource.dart
// Add a cache version check
static const int CACHE_VERSION = 2; // Increment when schema changes

Future<void> saveExpenses(List<ExpenseModel> expenses) async {
  final data = {
    'version': CACHE_VERSION,
    'expenses': expenses.map((e) => e.toJson()).toList(),
    'timestamp': DateTime.now().toIso8601String(),
  };
  await _storage.write(key: 'expenses', value: jsonEncode(data));
}

Future<List<ExpenseModel>> getExpenses() async {
  final json = await _storage.read(key: 'expenses');
  if (json == null) return [];
  
  final data = jsonDecode(json);
  final version = data['version'] as int?;
  
  // If cache version doesn't match, return empty (force API reload)
  if (version != CACHE_VERSION) {
    print('[Cache] Version mismatch, invalidating cache');
    return [];
  }
  
  // ... rest of code
}
```

## Test After Fix

After clearing cache, you should see:
```
[ExpenseRepository] 🔵 Loading expenses for user 3
[ExpenseRepository] 📡 Fetching from API (cache miss or expired)
[ExpenseDto] Inferred has_invoice=true from invoice_path: ...
[Export] Total expenses: 2, With invoices: 2  ✅
```

## Status

🔴 **CACHE INVALIDATION REQUIRED** - Clear app data to reload from API with correct `has_invoice` values.

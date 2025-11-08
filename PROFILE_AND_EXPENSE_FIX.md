# Profile and Expense Issues - Diagnostic and Fix Guide

## Current Status

✅ **Build**: Both flavors compile successfully
✅ **Dependency Injection**: All services properly registered
✅ **Flavor Configuration**: Working correctly
❌ **Profile Page**: Crashes or doesn't load
❌ **Expenses**: Don't save properly

## Likely Issues and Solutions

### Issue 1: Profile Page Crash

**Possible Causes:**
1. API endpoint `/profile` or `/profile/statistics` not responding
2. Authentication token not being sent correctly
3. User data not available when profile loads
4. Network connectivity issues

**Diagnostic Steps:**

1. **Check if backend is running:**
```bash
# Test the Laravel backend
curl http://192.168.137.1:8000/api/profile -H "Authorization: Bearer YOUR_TOKEN"
```

2. **Check API logs in the app:**
   - Look for console output when opening profile page
   - Check for 401 (Unauthorized), 404 (Not Found), or 500 (Server Error)

**Solution A: Add Better Error Handling**

The profile page needs graceful error handling. Let me update the ProfileBloc to handle missing data better.

**Solution B: Ensure Token is Valid**

The issue might be that the auth token expires or isn't being sent. Check:
- Token is stored after login
- Token is included in API requests
- Token hasn't expired

### Issue 2: Expenses Don't Save

**Possible Causes:**
1. API endpoint `/expenses` not working
2. Validation errors from backend
3. Queue system not processing offline requests
4. Cache not being updated after save

**Diagnostic Steps:**

1. **Check backend endpoint:**
```bash
# Test expense creation
curl -X POST http://192.168.137.1:8000/api/expenses \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Test expense",
    "price_usd": 100,
    "expense_date": "2024-10-22",
    "has_invoice": false
  }'
```

2. **Check app logs:**
   - Look for "[CreateExpenseUseCase]" messages
   - Check for validation errors
   - Look for queue status messages

**Solution: Add Debug Logging**

Let me add comprehensive logging to track what's happening.

## Quick Fixes to Apply

### Fix 1: Add Fallback for Profile Statistics

If statistics endpoint fails, show profile without statistics:

```dart
// In GetUserProfileUseCase
Future<Either<Failure, UserProfileData>> call() async {
  final userResult = await authRepository.getCurrentUser();
  if (userResult.isLeft()) {
    return Left(UnauthorizedFailure());
  }

  final user = userResult.getOrElse(() => throw Exception());

  // Get statistics, but don't fail if it errors
  final statisticsResult = await profileRepository.getUserStatistics(user.id);
  
  final statistics = statisticsResult.fold(
    (failure) {
      // Return empty statistics instead of failing
      print('[Profile] Failed to load statistics: ${failure.message}');
      return UserStatistics(
        totalExpenses: 0,
        totalIncoming: 0,
        totalTransfers: 0,
        pendingExpenses: 0,
      );
    },
    (stats) => stats,
  );

  return Right(UserProfileData(
    user: user,
    statistics: statistics,
  ));
}
```

### Fix 2: Add Expense Save Confirmation

Add visual feedback when expense is saved:

```dart
// In ExpenseBloc
result.fold(
  (failure) {
    print('[ExpenseBloc] Failed to create expense: ${failure.message}');
    emit(ExpenseError(failure.message, syncStatusMap: _syncStatusMap));
  },
  (expense) {
    print('[ExpenseBloc] Expense created successfully: ${expense.id}');
    print('[ExpenseBloc] Description: ${expense.description}');
    print('[ExpenseBloc] Amount: USD ${expense.priceUsd}, SYP ${expense.priceSyp}');
    
    if (expense.id != null) {
      _watchExpenseSyncStatus(expense.id!);
    }
    emit(ExpenseCreated(expense, syncStatusMap: _syncStatusMap));
  },
);
```

### Fix 3: Check Backend Routes

Ensure your Laravel backend has these routes:

```php
// routes/api.php
Route::middleware('auth:sanctum')->group(function () {
    // Profile routes
    Route::get('/profile', [ProfileController::class, 'show']);
    Route::put('/profile', [ProfileController::class, 'update']);
    Route::get('/profile/statistics', [ProfileController::class, 'statistics']);
    
    // Expense routes
    Route::get('/expenses', [ExpenseController::class, 'index']);
    Route::post('/expenses', [ExpenseController::class, 'store']);
    Route::get('/expenses/{id}', [ExpenseController::class, 'show']);
    Route::put('/expenses/{id}', [ExpenseController::class, 'update']);
    Route::delete('/expenses/{id}', [ExpenseController::class, 'destroy']);
});
```

## Testing Steps

### Test Profile Page

1. **Login to the app**
2. **Open profile page**
3. **Check console for errors:**
   - Look for "Failed to load statistics"
   - Look for "401 Unauthorized"
   - Look for "Failed to get profile"

4. **Expected behavior:**
   - Profile should show user name and email
   - Statistics should show (or show 0 if backend fails)
   - No crash

### Test Expense Creation

1. **Go to Expenses page**
2. **Click "Add Expense"**
3. **Fill in:**
   - Description: "Test Expense"
   - Amount: 100 USD
   - Date: Today
4. **Click Save**
5. **Check console for:**
   - "[ExpenseBloc] Expense created successfully"
   - "[CreateExpenseUseCase] Expense created successfully"
   - "[CreateExpenseUseCase] Queuing for sync"

6. **Expected behavior:**
   - Success message appears
   - Expense appears in list
   - Can see the expense details

## Backend Requirements

Your Laravel backend MUST have:

1. **Profile Controller** with:
   - `show()` - Returns user profile
   - `statistics()` - Returns user statistics (expenses, incoming, transfers counts)

2. **Expense Controller** with:
   - `index()` - List expenses for authenticated user
   - `store()` - Create new expense
   - `update()` - Update expense
   - `destroy()` - Delete expense

3. **Authentication** using Laravel Sanctum:
   - Token-based authentication
   - Middleware protecting routes

## Common Errors and Solutions

### Error: "Failed to get profile: 401 Unauthorized"
**Solution**: Token expired or not sent. Re-login to get new token.

### Error: "Failed to get user statistics: 404 Not Found"
**Solution**: Backend doesn't have `/profile/statistics` endpoint. Add it or use fallback.

### Error: "Expense created successfully but doesn't appear in list"
**Solution**: Cache not cleared. The fix is already in place - check if backend returns the expense.

### Error: "Validation failed: The description field is required"
**Solution**: Backend validation rules don't match app. Check backend validation.

## Next Steps

1. **Run the app with logging enabled**
2. **Try to open profile page** - note any errors
3. **Try to create an expense** - note any errors
4. **Share the console output** so I can see exactly what's failing

## Files to Check

- `lib/features/profile/domain/usecases/get_user_profile_usecase.dart`
- `lib/features/expenses/domain/usecases/create_expense_usecase.dart`
- `lib/features/expenses/data/repositories/expense_repository_impl.dart`
- `lib/core/api/api_client.dart` - Check if token is being sent

## Quick Test Command

```bash
# Run with verbose logging
flutter run --flavor user --dart-define=API_BASE_URL=http://192.168.137.1:8000 --verbose
```

Watch the console output when you:
1. Login
2. Open profile
3. Create expense

The logs will tell us exactly what's failing.

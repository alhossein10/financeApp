# Expenses Not Showing - Diagnosis and Fix

## Problem

- ✅ Backend API works (Postman test successful)
- ✅ Expense saved to database
- ❌ Expense doesn't show in mobile app

## Root Cause

The app is likely getting a 401 error when fetching expenses, OR the response format doesn't match what the app expects.

## Your Backend Response Format

### POST /expenses (Create) - Works in Postman
```json
{
  "success": true,
  "message": "Expense created successfully",
  "data": {
    "id": 1,
    "user_id": 11,
    "description": "Grocery shopping",
    "price_usd": "14500.00",
    ...
  }
}
```

### GET /expenses (List) - What format does it return?

The app expects Laravel pagination format:
```json
{
  "data": [
    {
      "id": 1,
      "user_id": 11,
      "description": "Grocery shopping",
      ...
    }
  ],
  "current_page": 1,
  "last_page": 1,
  "per_page": 15,
  "total": 1
}
```

## Diagnostic Steps

### Step 1: Check GET Expenses Endpoint

Test in Postman:
```
GET http://192.168.137.1:8000/api/v1/expenses
Headers:
  Authorization: Bearer YOUR_TOKEN
  Accept: application/json
```

**Check**:
1. Does it return 200 OK?
2. Does it return expenses for the logged-in user?
3. What format is the response?

### Step 2: Run App with Logging

The enhanced logging will show:
```
[ExpenseRepository] Loading expenses for user 11
[ExpenseRepository] No cache found, fetching from API...
[ExpenseRepository] Online status: true
[ExpenseRepository] Calling API to get expenses...
```

Then either:
- `[ExpenseRepository] ✅ API returned 1 expenses` (Success)
- `[ExpenseRepository] ⚠️ API failed: ...` (Error)

## Common Issues

### Issue 1: 401 Unauthorized

**Symptom**: 
```
[ExpenseRepository] ⚠️ API failed: Unauthorized
[ExpenseRepository] Status code: 401
```

**Cause**: Token expired or invalid
**Fix**: Logout and login again

### Issue 2: Wrong Response Format

**Symptom**:
```
[ExpenseRepository] ⚠️ Unexpected error: type 'String' is not a subtype of type 'int'
```

**Cause**: Backend returns different format than expected
**Fix**: Check Laravel controller returns paginated response

### Issue 3: Filtering by User

**Symptom**: API returns 200 but 0 expenses

**Cause**: Backend not filtering by authenticated user
**Fix**: In Laravel ExpenseController:

```php
public function index(Request $request)
{
    // Get expenses for authenticated user only
    $expenses = $request->user()
        ->expenses()
        ->orderBy('expense_date', 'desc')
        ->paginate(15);
    
    return response()->json($expenses);
}
```

### Issue 4: Cache Issue

**Symptom**: Old data showing, new expense not appearing

**Cause**: App using cached data
**Fix**: Pull to refresh in the app

## Laravel Backend Checklist

### GET /expenses Endpoint

Your Laravel `routes/api.php` should have:
```php
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/expenses', [ExpenseController::class, 'index']);
    Route::post('/expenses', [ExpenseController::class, 'store']);
});
```

### ExpenseController@index

```php
public function index(Request $request)
{
    // Get expenses for the authenticated user
    $expenses = $request->user()
        ->expenses()
        ->orderBy('expense_date', 'desc')
        ->paginate(15);
    
    // Laravel pagination automatically returns correct format:
    // {
    //   "data": [...],
    //   "current_page": 1,
    //   "last_page": 1,
    //   "per_page": 15,
    //   "total": 1
    // }
    
    return response()->json($expenses);
}
```

### User-Expense Relationship

In `User.php` model:
```php
public function expenses()
{
    return $this->hasMany(Expense::class);
}
```

In `Expense.php` model:
```php
public function user()
{
    return $this->belongsTo(User::class);
}
```

## Testing Steps

### 1. Test Backend Directly

```bash
# Get your token from login
curl -X POST http://192.168.137.1:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"your@email.com","password":"yourpassword"}'

# Use the token to get expenses
curl -X GET http://192.168.137.1:8000/api/v1/expenses \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Accept: application/json"
```

**Expected**: Should return expenses for that user

### 2. Test in App

1. **Logout and login** (to get fresh token)
2. **Go to Expenses page**
3. **Pull to refresh** (swipe down)
4. **Watch console logs**

**Expected logs**:
```
[ExpenseRepository] Loading expenses for user 11
[ExpenseRepository] No cache found, fetching from API...
[ExpenseRepository] Online status: true
[ExpenseRepository] Calling API to get expenses...
[ExpenseRepository] ✅ API returned 1 expenses
```

### 3. If Still Not Showing

Check the expense list page is triggering the load:
```
[ExpenseBloc] Loading expenses requested
```

## Quick Fixes

### Fix 1: Clear Cache

In the app, the cache might be stale. Add a button or pull-to-refresh gesture to force reload.

### Fix 2: Check User ID Match

The expense in database has `user_id: 11`. Make sure you're logged in as user ID 11 in the app.

Check in console:
```
[GetUserProfileUseCase] Got user: username (ID: 11)
```

If the ID is different, the backend won't return that expense.

### Fix 3: Backend Returns All Expenses

If your backend returns ALL expenses (not filtered by user), you need to fix the controller:

```php
// WRONG - returns all expenses
$expenses = Expense::paginate(15);

// CORRECT - returns only user's expenses
$expenses = $request->user()->expenses()->paginate(15);
```

## What I Added

Enhanced logging in `getExpensesByUser` to show:
1. When expenses are loaded
2. If cache is used
3. If API is called
4. How many expenses returned
5. Any errors

## Next Steps

1. **Logout and login** in the app
2. **Go to Expenses page**
3. **Pull to refresh**
4. **Share the console logs** - they will show exactly what's happening

The logs will tell us:
- Is the API being called?
- Is it returning 401?
- Is it returning data?
- Is the data being parsed correctly?

## Expected Working Flow

```
1. Open Expenses Page
   ↓
2. [ExpenseRepository] Loading expenses for user 11
   ↓
3. [ExpenseRepository] Calling API to get expenses...
   ↓
4. [ExpenseRepository] ✅ API returned 1 expenses
   ↓
5. Expenses show in list
```

If any step fails, the logs will show where and why.

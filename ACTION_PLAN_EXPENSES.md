# Action Plan - Fix Expenses Not Showing

## Current Situation

✅ **Backend works** - Postman can create expenses
✅ **Database has data** - Expense ID 1 exists for user 11
❌ **App doesn't show expenses** - List is empty

## Most Likely Causes

1. **401 Unauthorized** - Token expired (same issue as create)
2. **Wrong user** - Logged in as different user than user 11
3. **Backend not filtering** - Returns all users' expenses, but app filters them out
4. **Response format mismatch** - Backend returns different format than expected

## Immediate Actions

### Action 1: Logout and Login (5 seconds)

This fixes the token issue:

1. Open app
2. Profile → Logout
3. Login with same email you used in Postman
4. Go to Expenses page

**Expected**: Should show the expense now

### Action 2: Check Console Logs (1 minute)

After logging in and opening Expenses page, check console for:

```
[ExpenseRepository] Loading expenses for user X
[ExpenseRepository] Calling API to get expenses...
```

Then either:
- ✅ `[ExpenseRepository] ✅ API returned 1 expenses` → Working!
- ❌ `[ExpenseRepository] ⚠️ API failed: ...` → See error message

### Action 3: Test Backend GET Endpoint (2 minutes)

In Postman, test:
```
GET http://192.168.137.1:8000/api/v1/expenses
Headers:
  Authorization: Bearer YOUR_TOKEN
  Accept: application/json
```

**Check**:
- Status code 200?
- Returns expenses array?
- Returns expense ID 1?

## Debugging Guide

### If Logs Show: "Status code: 401"

**Problem**: Token expired
**Solution**: Already fixed by logout/login in Action 1

### If Logs Show: "API returned 0 expenses"

**Problem**: Backend not returning expenses for this user
**Possible causes**:
1. Logged in as different user (not user 11)
2. Backend not filtering by user
3. Backend query has wrong conditions

**Solution**: Check Laravel controller filters by authenticated user

### If Logs Show: "Unexpected error: ..."

**Problem**: Response format doesn't match
**Solution**: Check backend returns Laravel pagination format

### If No Logs Appear

**Problem**: Expenses page not loading data
**Solution**: Check if LoadExpensesRequested event is triggered

## Laravel Backend Requirements

### Route Must Exist

```php
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/expenses', [ExpenseController::class, 'index']);
});
```

### Controller Must Filter by User

```php
public function index(Request $request)
{
    $expenses = $request->user()
        ->expenses()
        ->orderBy('expense_date', 'desc')
        ->paginate(15);
    
    return response()->json($expenses);
}
```

### Response Format

Laravel pagination automatically returns:
```json
{
  "data": [
    {
      "id": 1,
      "user_id": 11,
      "description": "Grocery shopping",
      "price_usd": "14500.00",
      ...
    }
  ],
  "current_page": 1,
  "last_page": 1,
  "per_page": 15,
  "total": 1
}
```

## Quick Test Checklist

- [ ] Logout from app
- [ ] Login with same email as Postman test
- [ ] Open Expenses page
- [ ] Pull to refresh (swipe down)
- [ ] Check console logs
- [ ] Verify user ID matches (should be 11)
- [ ] Test GET /expenses in Postman with token
- [ ] Check Laravel logs for incoming request

## Expected Success Logs

```
[ExpenseRepository] Loading expenses for user 11
[ExpenseRepository] No cache found, fetching from API...
[ExpenseRepository] Online status: true
[ExpenseRepository] Calling API to get expenses...
[ExpenseRepository] ✅ API returned 1 expenses
```

Then expense should appear in the list!

## If Still Not Working

Share these details:

1. **Console logs** from opening Expenses page
2. **Postman response** from GET /expenses
3. **User ID** from profile page logs
4. **Laravel logs** from storage/logs/laravel.log

This will tell us exactly what's wrong.

## Summary

**Most likely fix**: Logout and login again (token issue)
**Backup fix**: Check backend filters by authenticated user
**Diagnostic tool**: Console logs will show exact issue

Try logout/login first - it should fix both create and fetch issues!

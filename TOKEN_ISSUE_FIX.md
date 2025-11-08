# Token Issue - 401 Unauthorized

## Problem Identified ✅

```
[ExpenseRepository] Status code: 401
```

**Root Cause**: The authentication token is expired or invalid. The app thinks you're logged in, but the Laravel backend is rejecting the token.

## Why This Happens

1. **Token Expired**: Laravel Sanctum tokens have an expiration time
2. **Token Not Synced**: Token stored in app doesn't match backend
3. **Token Not Sent**: Token not being included in API requests
4. **Backend Session Cleared**: Backend database was reset/cleared

## Quick Fix

### Solution 1: Logout and Login Again (Recommended)

This will get a fresh token from the backend:

1. **In the app**: Click profile → Logout
2. **Login again** with your credentials
3. **Try creating expense** - should work now

### Solution 2: Check Token is Being Sent

The token should be in the Authorization header:
```
Authorization: Bearer YOUR_TOKEN_HERE
```

## What's Happening Now

✅ **App Side**: Working correctly
- Expense is created locally
- Queued for sync when online
- Will retry when token is valid

❌ **Backend Side**: Rejecting requests
- Returns 401 Unauthorized
- Token is invalid/expired
- Needs fresh token

## How to Verify Token Issue

### Check if token exists:

Look for these logs when you login:
```
[TokenManager] Token saved
[LaravelAuthService] Login successful
```

### Check if token is sent:

With `DEBUG_LOGGING=true`, you should see:
```
Authorization: Bearer [REDACTED]
```

### Check backend receives token:

In Laravel, add logging to middleware:
```php
Log::info('Token received: ' . $request->bearerToken());
```

## Backend Token Configuration

### Laravel Sanctum Token Expiration

In `config/sanctum.php`:
```php
'expiration' => 60 * 24, // 24 hours (in minutes)
```

Or set to `null` for no expiration:
```php
'expiration' => null,
```

### Check Token in Database

In your Laravel backend:
```sql
SELECT * FROM personal_access_tokens 
WHERE tokenable_id = YOUR_USER_ID 
ORDER BY created_at DESC 
LIMIT 1;
```

Check if:
- Token exists
- `expires_at` is in the future (or NULL)
- `last_used_at` is recent

## Automatic Token Refresh

The app should automatically refresh tokens, but if it's not working:

### Check TokenManager

The `TokenManager` should:
1. Store token after login
2. Include token in all API requests
3. Clear token on 401 errors
4. Trigger re-login

## Testing Steps

### 1. Logout and Login

```
1. Open app
2. Go to Profile
3. Click Logout
4. Login with credentials
5. Try creating expense
```

**Expected**: Should work now

### 2. Check Logs After Login

```
[LaravelAuthService] Login successful
[TokenManager] Token saved: xxx...
[AuthBloc] Login successful
```

### 3. Check Logs When Creating Expense

```
[ExpenseRepository] Attempting to create via API...
[ExpenseRepository] ✅ API creation successful! ID: 123
```

**Not**:
```
[ExpenseRepository] Status code: 401
```

## Profile Page Issue

The profile page might also be affected by the token issue. After logging in again:

1. **Profile should load** - Shows user info
2. **Statistics might fail** - But won't crash (we added fallback)

## Long-term Solution

### Option 1: Increase Token Expiration

In Laravel `config/sanctum.php`:
```php
'expiration' => 60 * 24 * 30, // 30 days
```

### Option 2: Implement Token Refresh

Add automatic token refresh before expiration:
```dart
// Check token expiration
if (tokenWillExpireSoon()) {
  await refreshToken();
}
```

### Option 3: No Expiration (Development Only)

In Laravel `config/sanctum.php`:
```php
'expiration' => null, // Never expires
```

⚠️ **Warning**: Only use for development, not production!

## Summary

**Problem**: 401 Unauthorized - Token expired/invalid
**Solution**: Logout and login again to get fresh token
**Prevention**: Increase token expiration or implement auto-refresh

## Quick Test

After logging in again, create an expense and you should see:

```
[ExpenseRepository] Creating expense for user X
[ExpenseRepository] Online status: true
[ExpenseRepository] Attempting to create via API...
[ExpenseRepository] ✅ API creation successful! ID: 123
[ExpenseBloc] ✅ Expense created successfully!
[ExpenseBloc]    ID: 123  ← Should have ID now!
```

The key difference: **ID will not be null** when it works.

## Files to Check

If logout/login doesn't fix it:

1. **TokenManager** - `lib/core/services/token_manager.dart`
2. **LaravelAuthService** - `lib/core/services/laravel_auth_service.dart`
3. **ApiClient** - `lib/core/api/api_client.dart` (check token injection)
4. **Laravel Sanctum Config** - `config/sanctum.php`
5. **Laravel Auth Middleware** - Check routes are protected

## Next Steps

1. **Logout from the app**
2. **Login again**
3. **Try creating expense**
4. **Share the logs** if still failing

The 401 error should be gone after fresh login!

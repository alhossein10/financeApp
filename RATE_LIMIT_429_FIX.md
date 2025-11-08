# 429 Too Many Requests - Rate Limit Fix

## Problem

```
Status code: 429
```

Your Laravel backend is rate limiting the API requests. This is Laravel's built-in protection against too many requests.

## Why This Happens

Laravel Sanctum has default rate limiting:
- **60 requests per minute** for authenticated routes
- You're probably testing rapidly and hitting this limit

## Solution

### Option 1: Increase Rate Limit (Recommended for Development)

In your Laravel backend, edit `app/Http/Kernel.php`:

```php
protected $middlewareGroups = [
    'api' => [
        \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
        'throttle:api',  // ← This line controls rate limiting
        \Illuminate\Routing\Middleware\SubstituteBindings::class,
    ],
];
```

Then edit `config/sanctum.php` or `app/Providers/RouteServiceProvider.php`:

```php
// In RouteServiceProvider.php
protected function configureRateLimiting()
{
    RateLimiter::for('api', function (Request $request) {
        return Limit::perMinute(1000)  // ← Increase from 60 to 1000
            ->by($request->user()?->id ?: $request->ip());
    });
}
```

### Option 2: Disable Rate Limiting (Development Only!)

In `app/Http/Kernel.php`:

```php
protected $middlewareGroups = [
    'api' => [
        \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
        // 'throttle:api',  // ← Comment this out
        \Illuminate\Routing\Middleware\SubstituteBindings::class,
    ],
];
```

⚠️ **Warning**: Only do this in development! Re-enable for production.

### Option 3: Wait 1 Minute

The rate limit resets every minute. Just wait 60 seconds and try again.

## After Fixing

1. **Restart Laravel**:
```bash
php artisan config:clear
php artisan cache:clear
php artisan serve
```

2. **Test in app** - Should work now!

## Expected Logs After Fix

```
[ExpenseRepository] Attempting to create via API...
[ExpenseRepository] ✅ API creation successful! ID: 2
[ExpenseBloc] ✅ Expense created successfully!
[ExpenseBloc]    ID: 2  ← Should have ID now!
```

## Verification

The fact that you're getting 429 instead of 401 means:
- ✅ **Token is working!**
- ✅ **Authentication is successful!**
- ✅ **Request is reaching backend!**
- ⚠️ **Just need to adjust rate limit**

## Quick Test

After adjusting rate limit, wait 1 minute, then:

1. Create expense in app
2. Should get ID and save successfully
3. Refresh list - should see new expense

## Summary

**Problem**: Laravel rate limiting (429)
**Solution**: Increase rate limit in Laravel config
**Status**: Almost there! Just a backend configuration issue.

The token fix worked perfectly - now it's just a rate limit issue!

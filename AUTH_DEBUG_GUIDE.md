# Authentication Debug Guide

## Issue
Register and Login buttons show loading spinner but nothing happens - no error, no success.

## Debug Logging Added

I've added comprehensive logging to track the authentication flow:

### 1. BLoC Level (lib/features/auth/presentation/bloc/auth_bloc.dart)
- 🔵 Blue: Request started
- 🟢 Green: Success
- 🔴 Red: Error

### 2. Service Level (lib/core/services/laravel_auth_service.dart)
- 🔵 Blue: API call started
- 🟢 Green: API response received
- 🔴 Red: API error

## How to Debug

### Step 1: Run the App with Logs

```bash
flutter run --flavor user --dart-define=API_BASE_URL=http://192.168.6.18:8000
```

### Step 2: Try to Register

1. Fill in the registration form
2. Click "Create Account"
3. Watch the console output

### Step 3: Check the Logs

You should see logs like this:

**Success Flow:**
```
🔵 [BLOC] Registration requested for: test@example.com
🔵 [AUTH] Starting registration for: test@example.com
🔵 [AUTH] Request body: name=testuser, email=test@example.com
🟢 [AUTH] Registration response received: 201
🟢 [AUTH] Response data: {token: ..., user: {...}}
🟢 [AUTH] Token stored successfully
🟢 [BLOC] Registration successful for user: test@example.com
```

**Error Flow:**
```
🔵 [BLOC] Registration requested for: test@example.com
🔵 [AUTH] Starting registration for: test@example.com
🔵 [AUTH] Request body: name=testuser, email=test@example.com
🔴 [AUTH] DioException during registration: Connection refused
🔴 [AUTH] Response: null
🔴 [AUTH] Status code: null
🔴 [BLOC] Registration failed: Network error. Please check your internet connection.
```

## Common Issues & Solutions

### Issue 1: No Logs Appear

**Problem:** Nothing is printed to console

**Possible Causes:**
1. App is not running in debug mode
2. Console output is filtered

**Solution:**
```bash
# Make sure you're running in debug mode
flutter run --flavor user --dart-define=API_BASE_URL=http://192.168.6.18:8000 --verbose
```

### Issue 2: Connection Refused

**Logs:**
```
🔴 [AUTH] DioException during registration: Connection refused
```

**Possible Causes:**
1. Laravel backend is not running
2. Wrong IP address
3. Firewall blocking connection

**Solution:**
```bash
# 1. Check Laravel is running
cd financeApp-backend-main
php artisan serve --host=0.0.0.0

# 2. Verify IP address
# On your computer, run:
ipconfig  # Windows
ifconfig  # Mac/Linux

# 3. Check firewall
# Windows: Allow PHP through Windows Defender Firewall
# Mac: System Preferences → Security & Privacy → Firewall
```

### Issue 3: Timeout

**Logs:**
```
🔴 [AUTH] DioException during registration: Timeout
```

**Possible Causes:**
1. Laravel is slow to respond
2. Network is slow
3. Database connection issue

**Solution:**
```bash
# Check Laravel logs
cd financeApp-backend-main
tail -f storage/logs/laravel.log

# Check database connection
php artisan tinker
>>> DB::connection()->getPdo();
```

### Issue 4: 500 Server Error

**Logs:**
```
🔴 [AUTH] DioException during registration: Server error
🔴 [AUTH] Status code: 500
```

**Possible Causes:**
1. Laravel error
2. Database error
3. Missing configuration

**Solution:**
```bash
# Check Laravel logs
cd financeApp-backend-main
tail -f storage/logs/laravel.log

# Check Laravel configuration
php artisan config:clear
php artisan cache:clear
```

### Issue 5: 422 Validation Error

**Logs:**
```
🔴 [AUTH] DioException during registration: Validation failed
🔴 [AUTH] Status code: 422
🔴 [AUTH] Response: {errors: {email: [The email has already been taken.]}}
```

**Possible Causes:**
1. Email already exists
2. Password too weak
3. Missing required fields

**Solution:**
- Use a different email
- Check password requirements
- Verify all fields are filled

### Issue 6: 401 Unauthorized

**Logs:**
```
🔴 [AUTH] DioException during login: Unauthorized
🔴 [AUTH] Status code: 401
```

**Possible Causes:**
1. Wrong email/password
2. User doesn't exist
3. Account disabled

**Solution:**
- Check credentials
- Register a new account
- Check user in database

## Testing the API Directly

### Test Registration with cURL

```bash
curl -X POST http://192.168.6.18:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "Password123!",
    "password_confirmation": "Password123!"
  }'
```

**Expected Response:**
```json
{
  "token": "1|abc123...",
  "token_type": "Bearer",
  "expires_at": "2024-02-15T10:00:00.000000Z",
  "user": {
    "id": 1,
    "name": "Test User",
    "email": "test@example.com",
    "role": "user",
    "created_at": "2024-01-15T10:00:00.000000Z"
  }
}
```

### Test Login with cURL

```bash
curl -X POST http://192.168.6.18:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Password123!"
  }'
```

## Next Steps

1. **Run the app** with debug logging
2. **Try to register** and watch console
3. **Copy the logs** and share them if issue persists
4. **Test API directly** with cURL to verify backend works

## Remove Debug Logging (After Fixing)

Once the issue is fixed, you can remove the debug print statements:

1. Search for `print('🔵` in the codebase
2. Remove all debug print statements
3. Or keep them for future debugging (they don't affect production)

---

**Status:** Debug logging added ✅  
**Next:** Run app and check console logs

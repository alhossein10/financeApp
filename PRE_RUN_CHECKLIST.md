# Pre-Run Checklist ✅

## Can You Run the App Now?

**Almost!** You need to configure your Laravel backend URL first.

## Required Steps Before Running

### 1. ✅ Configure Laravel Backend URL

The app is currently pointing to `http://localhost:8000` by default. You need to update this to your actual Laravel backend URL.

**Option A: Using Environment Variables (Recommended)**
```bash
# For development with local Laravel
flutter run --flavor user --dart-define=API_BASE_URL=http://10.0.2.2:8000

# For Android emulator (10.0.2.2 maps to host machine's localhost)
flutter run --flavor user --dart-define=API_BASE_URL=http://10.0.2.2:8000

# For real device on same network
flutter run --flavor user --dart-define=API_BASE_URL=http://192.168.1.100:8000

# For production
flutter run --flavor user --dart-define=API_BASE_URL=https://your-backend.com --dart-define=ENVIRONMENT=production
```

**Option B: Hardcode for Testing (Quick & Dirty)**

Edit `lib/core/config/api_config.dart` line 12:
```dart
static const String _devBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://YOUR_BACKEND_IP:8000', // Change this!
);
```

### 2. ✅ Ensure Laravel Backend is Running

Make sure your Laravel backend is:
- Running and accessible
- Has CORS configured to allow requests from your Flutter app
- Has all required API endpoints implemented
- Database is migrated and seeded

Test your backend:
```bash
curl http://YOUR_BACKEND_URL/api/v1/auth/login
```

### 3. ✅ Check Flutter Setup

```bash
# Verify Flutter is working
flutter doctor

# Clean and get dependencies
flutter clean
flutter pub get
```

## Running the App

### For User Version:
```bash
# Debug mode
flutter run --flavor user --dart-define=API_BASE_URL=http://YOUR_BACKEND_URL

# Release mode
flutter run --flavor user --release --dart-define=API_BASE_URL=http://YOUR_BACKEND_URL
```

### For Admin Version:
```bash
# Debug mode
flutter run --flavor admin --dart-define=API_BASE_URL=http://YOUR_BACKEND_URL

# Release mode
flutter run --flavor admin --release --dart-define=API_BASE_URL=http://YOUR_BACKEND_URL
```

## Common Issues & Solutions

### Issue 1: "Connection refused" or "Network error"

**Cause**: Backend URL is incorrect or backend is not running

**Solutions**:
- For Android Emulator: Use `http://10.0.2.2:8000` instead of `localhost`
- For iOS Simulator: Use `http://localhost:8000` or your machine's IP
- For Real Device: Use your machine's IP address (e.g., `http://192.168.1.100:8000`)
- Check firewall settings
- Ensure Laravel is running: `php artisan serve --host=0.0.0.0`

### Issue 2: "CORS error"

**Cause**: Laravel backend not configured for CORS

**Solution**: Update Laravel's `config/cors.php`:
```php
'paths' => ['api/*'],
'allowed_origins' => ['*'], // Or specific origins
'allowed_methods' => ['*'],
'allowed_headers' => ['*'],
```

### Issue 3: "401 Unauthorized" on all requests

**Cause**: Token authentication not working

**Solution**: 
- Check Laravel Sanctum is installed and configured
- Verify API routes are protected correctly
- Check token is being sent in headers

### Issue 4: Compilation errors

**Solution**: Run diagnostics
```bash
flutter analyze
flutter pub get
```

## Testing the Connection

Once the app starts, try:

1. **Register a new user** - Tests POST /api/v1/auth/register
2. **Login** - Tests POST /api/v1/auth/login
3. **View dashboard** - Tests GET requests with authentication
4. **Create an expense** - Tests POST with file upload

## Quick Test Command

```bash
# Test with local Laravel backend on Android emulator
flutter run --flavor user --dart-define=API_BASE_URL=http://10.0.2.2:8000 --dart-define=DEBUG_LOGGING=true
```

## What's Already Fixed ✅

- ✅ All compilation errors resolved
- ✅ Dependency injection configured
- ✅ API client setup
- ✅ Auth services registered
- ✅ Repository pattern implemented
- ✅ Offline queue system ready
- ✅ Connectivity monitoring working
- ✅ Cache system configured

## What You Need to Provide

- ❓ Laravel backend URL
- ❓ Ensure backend is running and accessible
- ❓ CORS configured on backend
- ❓ API endpoints implemented

## Next Steps After First Run

1. Test authentication flow
2. Test CRUD operations
3. Test offline mode
4. Test file uploads
5. Test admin features (if using admin flavor)

---

**Ready to run?** Just set your backend URL and execute:

```bash
flutter run --flavor user --dart-define=API_BASE_URL=http://YOUR_BACKEND_URL
```

Good luck! 🚀

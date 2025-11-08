# API Configuration Guide

## Overview

This document explains how to configure the Flutter app to connect to different backend environments (local development, staging, production).

---

## Current Configuration

The app uses `lib/core/config/api_config.dart` which supports environment-based configuration through build-time variables.

### Default URLs

| Environment | URL | Usage |
|-------------|-----|-------|
| Development | `http://localhost:8000` | Local testing |
| Staging | `https://staging.example.com` | Pre-production testing |
| Production | `https://api.example.com` | Live deployment |

---

## Building for Different Environments

### 1. Development (Local Backend)

**Default behavior** - no special configuration needed:

```bash
# Run app (connects to localhost:8000)
flutter run

# Build debug APK
flutter build apk --debug --flavor user -t lib/main_user.dart
```

**Custom local IP** (e.g., testing on physical device):

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000
```

---

### 2. Staging Environment

Use the staging build script:

```bash
build_with_staging_api.bat
```

**Or manually:**

```bash
flutter build apk --release ^
  --dart-define=API_BASE_URL=https://staging.yourdomain.com ^
  --dart-define=ENVIRONMENT=staging ^
  --flavor user ^
  -t lib/main_user.dart
```

---

### 3. Production Environment (Hostinger)

#### User App

```bash
build_with_production_api.bat
```

**Manual command:**

```bash
flutter build apk --release ^
  --dart-define=API_BASE_URL=https://yourdomain.com ^
  --dart-define=ENVIRONMENT=production ^
  --flavor user ^
  -t lib/main_user.dart
```

#### Admin App (Optimized)

```bash
build_admin_production_api.bat
```

**Manual command:**

```bash
flutter build apk --release ^
  --dart-define=API_BASE_URL=https://yourdomain.com ^
  --dart-define=ENVIRONMENT=production ^
  --split-per-abi ^
  --obfuscate ^
  --split-debug-info=build/debug-info-admin-prod ^
  --flavor admin ^
  -t lib/main_admin.dart
```

---

## Updating API URLs

### Method 1: Update Build Scripts (Recommended)

Edit the `.bat` files and change the `API_BASE_URL`:

**Example: `build_with_production_api.bat`**

```batch
REM Change this line:
set API_BASE_URL=https://yourdomain.com

REM To your actual domain:
set API_BASE_URL=https://api.financeapp.com
```

### Method 2: Update Default Values

Edit `lib/core/config/api_config.dart`:

```dart
static const String _productionBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://yourdomain.com', // Change this
);
```

**Note**: Method 1 is preferred as it doesn't require code changes.

---

## API Endpoints Structure

All API calls follow this pattern:

```
{BASE_URL}/api/v1/{endpoint}
```

### Examples

**Development:**
```
http://localhost:8000/api/v1/auth/login
http://localhost:8000/api/v1/expenses
```

**Production:**
```
https://yourdomain.com/api/v1/auth/login
https://yourdomain.com/api/v1/expenses
```

---

## Verification

### Check API URL in Built APK

1. **Build the APK**
2. **Install on device**
3. **Open app and try to login**
4. **Check logs** (if debug logging enabled)

### Using Android Studio

1. Connect device
2. Open Logcat
3. Filter by "API" or "HTTP"
4. Look for API calls - should show your production URL

### Using Chrome DevTools

1. Run app: `flutter run --release`
2. Open DevTools
3. Go to Network tab
4. Perform actions (login, create expense)
5. Verify URLs in network requests

---

## Environment Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `API_BASE_URL` | Backend API base URL | `https://yourdomain.com` |
| `ENVIRONMENT` | Environment name | `production`, `staging`, `development` |
| `DEBUG_LOGGING` | Enable debug logs | `true`, `false` |

### Using Multiple Variables

```bash
flutter build apk --release ^
  --dart-define=API_BASE_URL=https://yourdomain.com ^
  --dart-define=ENVIRONMENT=production ^
  --dart-define=DEBUG_LOGGING=false ^
  --flavor user ^
  -t lib/main_user.dart
```

---

## Common Scenarios

### Scenario 1: Testing with Local Backend on Physical Device

Your computer IP: `192.168.1.100`

```bash
# Make sure Laravel is accessible on network
php artisan serve --host=0.0.0.0 --port=8000

# Build and run
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000
```

### Scenario 2: Multiple Production Environments

**Main Production:**
```bash
set API_BASE_URL=https://api.financeapp.com
build_with_production_api.bat
```

**Client-Specific Production:**
```bash
set API_BASE_URL=https://client1.financeapp.com
build_with_production_api.bat
```

### Scenario 3: Testing Production API in Development

```bash
flutter run --dart-define=API_BASE_URL=https://yourdomain.com
```

---

## Troubleshooting

### Issue: App still connects to localhost

**Solution:**
1. Verify you used `--dart-define` in build command
2. Do a clean build:
```bash
flutter clean
flutter pub get
# Then rebuild with correct API URL
```

### Issue: "Connection refused" error

**Possible causes:**
1. Wrong API URL
2. Backend not running
3. Firewall blocking connection
4. SSL certificate issues

**Solutions:**
1. Verify API URL is correct
2. Test API in browser: `https://yourdomain.com/api/v1/auth/login`
3. Check SSL certificate is valid
4. Verify CORS is configured on backend

### Issue: CORS errors

**Solution:** Update backend `config/cors.php`:
```php
'allowed_origins' => ['*'],
'supports_credentials' => true,
```

### Issue: SSL certificate errors

**Solution:** Ensure SSL is properly installed on Hostinger:
1. Go to hPanel → SSL
2. Verify certificate is active
3. Test: `https://www.sslshopper.com/ssl-checker.html`

---

## Security Considerations

### Production Builds

✅ **Do:**
- Use HTTPS for production
- Set `APP_DEBUG=false` on backend
- Enable code obfuscation
- Use environment variables for sensitive data

❌ **Don't:**
- Hardcode API URLs in code
- Use HTTP in production
- Commit `.env` files
- Expose debug logs in production

### API Keys and Secrets

Never include in code:
- Database credentials
- API keys
- Secret tokens
- Passwords

Use environment variables or secure storage instead.

---

## Quick Reference

### Build Commands

```bash
# Development (local)
flutter run

# Staging
build_with_staging_api.bat

# Production User
build_with_production_api.bat

# Production Admin
build_admin_production_api.bat
```

### Important Files

```
lib/core/config/api_config.dart          # API configuration
build_with_production_api.bat            # Production user build
build_admin_production_api.bat           # Production admin build
build_with_staging_api.bat               # Staging build
HOSTINGER_DEPLOYMENT_GUIDE.md            # Full deployment guide
```

### Testing Checklist

- [ ] API URL is correct in build script
- [ ] Backend is accessible at that URL
- [ ] SSL certificate is valid (for HTTPS)
- [ ] CORS is configured on backend
- [ ] Build completes successfully
- [ ] APK installs on device
- [ ] App can register new user
- [ ] App can login
- [ ] Data operations work (create, read, update, delete)
- [ ] File uploads work
- [ ] No localhost references in production build

---

## Support

### Documentation
- Main deployment guide: `HOSTINGER_DEPLOYMENT_GUIDE.md`
- API documentation: Check backend `/api/documentation`
- Flutter docs: https://flutter.dev/docs

### Common Commands

```bash
# Check current API configuration
flutter run --dart-define=API_BASE_URL=https://yourdomain.com --verbose

# Test API connection
curl https://yourdomain.com/api/v1/auth/login

# View build configuration
flutter build apk --release --verbose
```

---

**Last Updated:** November 4, 2025

For complete deployment instructions, see `HOSTINGER_DEPLOYMENT_GUIDE.md`

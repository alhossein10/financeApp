# Build Environments Configuration

## Overview

This document describes how to configure and build the Finance App for different environments (development, staging, production).

## Environment Types

### Development
- Local Laravel API server
- Debug logging enabled
- Hot reload enabled
- Test data allowed
- No analytics

### Staging
- Staging Laravel API server
- Limited logging
- Production-like environment
- Test with real-like data
- Analytics enabled

### Production
- Production Laravel API server
- Minimal logging
- Optimized performance
- Real user data
- Full analytics

---

## Configuration Files

### Environment Variables

Create `.env` files for each environment:

**`.env.development`**
```bash
API_BASE_URL=http://localhost:8000/api/v1
ENVIRONMENT=development
DEBUG_MODE=true
ENABLE_LOGGING=true
ANALYTICS_ENABLED=false
```

**`.env.staging`**
```bash
API_BASE_URL=https://staging-api.example.com/api/v1
ENVIRONMENT=staging
DEBUG_MODE=false
ENABLE_LOGGING=true
ANALYTICS_ENABLED=true
```

**`.env.production`**
```bash
API_BASE_URL=https://api.example.com/api/v1
ENVIRONMENT=production
DEBUG_MODE=false
ENABLE_LOGGING=false
ANALYTICS_ENABLED=true
```

### API Configuration

Update `lib/core/config/api_config.dart`:

```dart
class ApiConfig {
  // Environment
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // API Base URL
  static const String apiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  // Debug Mode
  static const bool debugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: true,
  );

  // Logging
  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: true,
  );

  // Analytics
  static const bool analyticsEnabled = bool.fromEnvironment(
    'ANALYTICS_ENABLED',
    defaultValue: false,
  );

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(seconds: 1);
  static const double retryDelayMultiplier = 2.0;
  static const Duration maxRetryDelay = Duration(seconds: 30);

  // Headers
  static const String contentTypeJson = 'application/json';
  static const String contentTypeMultipart = 'multipart/form-data';
  static const String acceptJson = 'application/json';
  static const String authorizationPrefix = 'Bearer';

  // Environment checks
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';
}
```

---

## Build Commands

### Development Build

**Android**:
```bash
flutter run --flavor dev --dart-define=API_BASE_URL=http://localhost:8000/api/v1 --dart-define=ENVIRONMENT=development --dart-define=DEBUG_MODE=true --dart-define=ENABLE_LOGGING=true --dart-define=ANALYTICS_ENABLED=false
```

**iOS**:
```bash
flutter run --flavor dev --dart-define=API_BASE_URL=http://localhost:8000/api/v1 --dart-define=ENVIRONMENT=development --dart-define=DEBUG_MODE=true --dart-define=ENABLE_LOGGING=true --dart-define=ANALYTICS_ENABLED=false
```

### Staging Build

**Android APK**:
```bash
flutter build apk --flavor staging --dart-define=API_BASE_URL=https://staging-api.example.com/api/v1 --dart-define=ENVIRONMENT=staging --dart-define=DEBUG_MODE=false --dart-define=ENABLE_LOGGING=true --dart-define=ANALYTICS_ENABLED=true
```

**iOS IPA**:
```bash
flutter build ipa --flavor staging --dart-define=API_BASE_URL=https://staging-api.example.com/api/v1 --dart-define=ENVIRONMENT=staging --dart-define=DEBUG_MODE=false --dart-define=ENABLE_LOGGING=true --dart-define=ANALYTICS_ENABLED=true
```

### Production Build

**Android APK**:
```bash
flutter build apk --release --flavor prod --dart-define=API_BASE_URL=https://api.example.com/api/v1 --dart-define=ENVIRONMENT=production --dart-define=DEBUG_MODE=false --dart-define=ENABLE_LOGGING=false --dart-define=ANALYTICS_ENABLED=true
```

**Android App Bundle**:
```bash
flutter build appbundle --release --flavor prod --dart-define=API_BASE_URL=https://api.example.com/api/v1 --dart-define=ENVIRONMENT=production --dart-define=DEBUG_MODE=false --dart-define=ENABLE_LOGGING=false --dart-define=ANALYTICS_ENABLED=true
```

**iOS IPA**:
```bash
flutter build ipa --release --flavor prod --dart-define=API_BASE_URL=https://api.example.com/api/v1 --dart-define=ENVIRONMENT=production --dart-define=DEBUG_MODE=false --dart-define=ENABLE_LOGGING=false --dart-define=ANALYTICS_ENABLED=true
```

---

## Build Scripts

### Windows Build Scripts

**`build_dev.bat`** (Already exists):
```batch
@echo off
echo Building Finance App - Development
flutter run --flavor dev --dart-define=API_BASE_URL=http://localhost:8000/api/v1 --dart-define=ENVIRONMENT=development --dart-define=DEBUG_MODE=true --dart-define=ENABLE_LOGGING=true --dart-define=ANALYTICS_ENABLED=false
```

**`build_staging.bat`**:
```batch
@echo off
echo Building Finance App - Staging
flutter build apk --flavor staging --dart-define=API_BASE_URL=https://staging-api.example.com/api/v1 --dart-define=ENVIRONMENT=staging --dart-define=DEBUG_MODE=false --dart-define=ENABLE_LOGGING=true --dart-define=ANALYTICS_ENABLED=true
echo.
echo Build complete! APK location:
echo build\app\outputs\flutter-apk\app-staging-release.apk
pause
```

**`build_production.bat`**:
```batch
@echo off
echo Building Finance App - Production
echo.
echo WARNING: This will build a production release!
echo Make sure you have:
echo - Updated version number
echo - Tested on staging
echo - Reviewed all changes
echo.
pause

echo Building Android App Bundle...
flutter build appbundle --release --flavor prod --dart-define=API_BASE_URL=https://api.example.com/api/v1 --dart-define=ENVIRONMENT=production --dart-define=DEBUG_MODE=false --dart-define=ENABLE_LOGGING=false --dart-define=ANALYTICS_ENABLED=true

echo.
echo Building APK...
flutter build apk --release --flavor prod --dart-define=API_BASE_URL=https://api.example.com/api/v1 --dart-define=ENVIRONMENT=production --dart-define=DEBUG_MODE=false --dart-define=ENABLE_LOGGING=false --dart-define=ANALYTICS_ENABLED=true

echo.
echo Build complete!
echo.
echo App Bundle location:
echo build\app\outputs\bundle\prodRelease\app-prod-release.aab
echo.
echo APK location:
echo build\app\outputs\flutter-apk\app-prod-release.apk
echo.
pause
```

### Linux/Mac Build Scripts

**`build_dev.sh`**:
```bash
#!/bin/bash
echo "Building Finance App - Development"
flutter run --flavor dev \
  --dart-define=API_BASE_URL=http://localhost:8000/api/v1 \
  --dart-define=ENVIRONMENT=development \
  --dart-define=DEBUG_MODE=true \
  --dart-define=ENABLE_LOGGING=true \
  --dart-define=ANALYTICS_ENABLED=false
```

**`build_staging.sh`**:
```bash
#!/bin/bash
echo "Building Finance App - Staging"
flutter build apk --flavor staging \
  --dart-define=API_BASE_URL=https://staging-api.example.com/api/v1 \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=DEBUG_MODE=false \
  --dart-define=ENABLE_LOGGING=true \
  --dart-define=ANALYTICS_ENABLED=true

echo ""
echo "Build complete! APK location:"
echo "build/app/outputs/flutter-apk/app-staging-release.apk"
```

**`build_production.sh`**:
```bash
#!/bin/bash
echo "Building Finance App - Production"
echo ""
echo "WARNING: This will build a production release!"
echo "Make sure you have:"
echo "- Updated version number"
echo "- Tested on staging"
echo "- Reviewed all changes"
echo ""
read -p "Press enter to continue..."

echo "Building Android App Bundle..."
flutter build appbundle --release --flavor prod \
  --dart-define=API_BASE_URL=https://api.example.com/api/v1 \
  --dart-define=ENVIRONMENT=production \
  --dart-define=DEBUG_MODE=false \
  --dart-define=ENABLE_LOGGING=false \
  --dart-define=ANALYTICS_ENABLED=true

echo ""
echo "Building APK..."
flutter build apk --release --flavor prod \
  --dart-define=API_BASE_URL=https://api.example.com/api/v1 \
  --dart-define=ENVIRONMENT=production \
  --dart-define=DEBUG_MODE=false \
  --dart-define=ENABLE_LOGGING=false \
  --dart-define=ANALYTICS_ENABLED=true

echo ""
echo "Build complete!"
echo ""
echo "App Bundle location:"
echo "build/app/outputs/bundle/prodRelease/app-prod-release.aab"
echo ""
echo "APK location:"
echo "build/app/outputs/flutter-apk/app-prod-release.apk"
```

Make scripts executable:
```bash
chmod +x build_dev.sh build_staging.sh build_production.sh
```

---

## Android Configuration

### Gradle Configuration

Update `android/app/build.gradle`:

```gradle
android {
    // ... existing config

    flavorDimensions "environment"
    
    productFlavors {
        dev {
            dimension "environment"
            applicationIdSuffix ".dev"
            versionNameSuffix "-dev"
            resValue "string", "app_name", "Finance App (Dev)"
        }
        
        staging {
            dimension "environment"
            applicationIdSuffix ".staging"
            versionNameSuffix "-staging"
            resValue "string", "app_name", "Finance App (Staging)"
        }
        
        prod {
            dimension "environment"
            resValue "string", "app_name", "Finance App"
        }
    }
}
```

### AndroidManifest.xml

Update `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.finance_app">
    
    <application
        android:label="@string/app_name"
        android:icon="@mipmap/ic_launcher">
        <!-- ... rest of config -->
    </application>
</manifest>
```

---

## iOS Configuration

### Xcode Configuration

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target
3. Go to "Signing & Capabilities"
4. Add configurations for each flavor

### Info.plist

Update `ios/Runner/Info.plist`:

```xml
<key>CFBundleDisplayName</key>
<string>$(APP_DISPLAY_NAME)</string>
```

### Schemes

Create Xcode schemes for each environment:
- Runner-Dev
- Runner-Staging
- Runner-Prod

---

## Version Management

### Update Version

Edit `pubspec.yaml`:

```yaml
version: 2.0.0+1
```

Format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`

### Version Naming Convention

- **Major**: Breaking changes (1.0.0 → 2.0.0)
- **Minor**: New features (2.0.0 → 2.1.0)
- **Patch**: Bug fixes (2.1.0 → 2.1.1)
- **Build**: Build number (2.1.1+1 → 2.1.1+2)

---

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/build.yml`:

```yaml
name: Build and Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Run tests
      run: flutter test
    
    - name: Build APK (Staging)
      run: |
        flutter build apk --flavor staging \
          --dart-define=API_BASE_URL=${{ secrets.STAGING_API_URL }} \
          --dart-define=ENVIRONMENT=staging \
          --dart-define=DEBUG_MODE=false \
          --dart-define=ENABLE_LOGGING=true \
          --dart-define=ANALYTICS_ENABLED=true
    
    - name: Upload APK
      uses: actions/upload-artifact@v2
      with:
        name: app-staging-release
        path: build/app/outputs/flutter-apk/app-staging-release.apk
```

---

## Environment-Specific Features

### Development

```dart
if (ApiConfig.isDevelopment) {
  // Enable debug features
  enableDebugMenu();
  showPerformanceOverlay();
  allowTestData();
}
```

### Staging

```dart
if (ApiConfig.isStaging) {
  // Enable staging features
  showEnvironmentBanner('STAGING');
  enableBetaFeatures();
}
```

### Production

```dart
if (ApiConfig.isProduction) {
  // Production-only features
  enableCrashReporting();
  enableAnalytics();
  disableDebugFeatures();
}
```

---

## Testing Environments

### Local Testing

1. Start local Laravel server:
   ```bash
   cd laravel-backend
   php artisan serve
   ```

2. Run app in development mode:
   ```bash
   flutter run --flavor dev
   ```

### Staging Testing

1. Deploy to staging server
2. Build staging APK
3. Install on test devices
4. Perform UAT

### Production Testing

1. Test on staging first
2. Build production release
3. Test on multiple devices
4. Verify all features
5. Deploy to stores

---

## Troubleshooting

### Build Fails

**Problem**: Build fails with environment errors

**Solution**:
- Verify all dart-define values are set
- Check API URL is accessible
- Ensure Flutter SDK is updated

### Wrong API URL

**Problem**: App connects to wrong server

**Solution**:
- Check dart-define values in build command
- Verify ApiConfig.apiUrl value
- Rebuild with correct environment

### Flavor Not Found

**Problem**: "Flavor not found" error

**Solution**:
- Check build.gradle has flavor defined
- Verify flavor name matches exactly
- Clean and rebuild project

---

## Best Practices

1. **Never commit API keys**: Use environment variables
2. **Test before deploying**: Always test on staging first
3. **Version control**: Tag releases in git
4. **Document changes**: Update changelog
5. **Backup builds**: Keep copies of production builds
6. **Monitor logs**: Check logs after deployment
7. **Gradual rollout**: Deploy to small percentage first

---

## Checklist

### Before Building

- [ ] Update version number
- [ ] Run all tests
- [ ] Update changelog
- [ ] Review code changes
- [ ] Test on staging
- [ ] Verify API endpoints
- [ ] Check environment variables

### After Building

- [ ] Test APK/IPA on device
- [ ] Verify API connection
- [ ] Check all features work
- [ ] Test offline mode
- [ ] Verify analytics
- [ ] Check crash reporting
- [ ] Document build

---

## Support

For build issues:
- Check Flutter documentation
- Review error logs
- Contact DevOps team
- Email: devops@example.com

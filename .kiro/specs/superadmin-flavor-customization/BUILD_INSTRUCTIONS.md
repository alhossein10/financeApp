# SuperAdmin Flavor Build Instructions

## Overview

This document provides step-by-step instructions for building the SuperAdmin flavor of the Finance application for different environments and platforms.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Build Commands](#build-commands)
4. [Build Configurations](#build-configurations)
5. [Platform-Specific Instructions](#platform-specific-instructions)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio (for Android builds)
- Xcode 14+ (for iOS builds, macOS only)
- Git

### Verify Installation

```bash
flutter --version
dart --version
flutter doctor
```

Ensure all checks pass before proceeding.

### Project Dependencies

Install project dependencies:

```bash
flutter pub get
```

## Environment Setup

### Flavor Configuration

The SuperAdmin flavor is configured in:
- `lib/core/config/flavor_config.dart`
- `android/app/build.gradle` (Android)
- `ios/Runner/Info.plist` (iOS)

### API Configuration

Update API endpoints in `lib/core/config/api_config.dart`:

```dart
// Development
static const String devBaseUrl = 'https://dev-api.example.com';

// Production
static const String prodBaseUrl = 'https://api.example.com';
```

## Build Commands

### Development Builds

#### Android APK (Development)

```bash
flutter build apk --flavor superadmin --target lib/main_superadmin.dart
```

Output: `build/app/outputs/flutter-apk/app-superadmin-release.apk`

#### iOS (Development)

```bash
flutter build ios --flavor superadmin --target lib/main_superadmin.dart
```

Output: `build/ios/iphoneos/Runner.app`

### Production Builds

#### Android APK (Production)

```bash
flutter build apk --release --flavor superadmin --target lib/main_superadmin.dart
```

#### Android App Bundle (Production)

```bash
flutter build appbundle --release --flavor superadmin --target lib/main_superadmin.dart
```

Output: `build/app/outputs/bundle/superadminRelease/app-superadmin-release.aab`

#### iOS (Production)

```bash
flutter build ios --release --flavor superadmin --target lib/main_superadmin.dart
```

### Debug Builds

For development and testing:

```bash
flutter run --flavor superadmin --target lib/main_superadmin.dart
```

## Build Configurations

### Flavor-Specific Settings

The SuperAdmin flavor has the following configuration:

```dart
FlavorConfig(
  flavor: AppFlavor.superAdmin,
  appName: 'Finance SuperAdmin',
  applicationId: 'com.app.finance.superadmin',
  enableCashModule: true,
  enableCashboxModule: false,
  enableCurrencyModule: false,
  enableExpensesModule: true,
  enableExportModule: false,
  requiresAdminRole: true,
  enableAdminDashboard: false,
  enableFundBox: true,
  enableAuditLogs: true,
  enableUserManagement: true,
  enableSuperAdminCashPage: true,
  enableSuperAdminExpensesPage: true,
  showIncomingTransfers: false,
  showExchangeHistory: false,
);
```

### Build Variants

| Variant | Flavor | Mode | Use Case |
|---------|--------|------|----------|
| superadmin-debug | superadmin | debug | Local development |
| superadmin-profile | superadmin | profile | Performance testing |
| superadmin-release | superadmin | release | Production deployment |

## Platform-Specific Instructions

### Android

#### Build Configuration

The SuperAdmin flavor is configured in `android/app/build.gradle`:

```gradle
flavorDimensions "app"
productFlavors {
    superadmin {
        dimension "app"
        applicationIdSuffix ".superadmin"
        versionNameSuffix "-superadmin"
        resValue "string", "app_name", "Finance SuperAdmin"
    }
}
```

#### Signing Configuration

For production builds, configure signing in `android/key.properties`:

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=<your-key-alias>
storeFile=<path-to-keystore>
```

Reference in `android/app/build.gradle`:

```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
```

#### Build Steps

1. Clean previous builds:
   ```bash
   flutter clean
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Build APK:
   ```bash
   flutter build apk --release --flavor superadmin --target lib/main_superadmin.dart
   ```

4. Build App Bundle (for Play Store):
   ```bash
   flutter build appbundle --release --flavor superadmin --target lib/main_superadmin.dart
   ```

#### Testing APK

Install on device:
```bash
flutter install --flavor superadmin --target lib/main_superadmin.dart
```

Or manually:
```bash
adb install build/app/outputs/flutter-apk/app-superadmin-release.apk
```

### iOS

#### Build Configuration

The SuperAdmin flavor is configured in Xcode schemes and `ios/Runner/Info.plist`.

#### Prerequisites

1. Valid Apple Developer account
2. Provisioning profiles configured
3. Code signing certificates installed

#### Build Steps

1. Open iOS project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Select the SuperAdmin scheme

3. Configure signing:
   - Select Runner target
   - Go to Signing & Capabilities
   - Select your team
   - Ensure provisioning profile is valid

4. Build from command line:
   ```bash
   flutter build ios --release --flavor superadmin --target lib/main_superadmin.dart
   ```

5. Archive for App Store:
   - In Xcode: Product > Archive
   - Upload to App Store Connect

#### Testing on Device

```bash
flutter run --flavor superadmin --target lib/main_superadmin.dart --device <device-id>
```

List devices:
```bash
flutter devices
```

### Web (Not Supported)

The SuperAdmin flavor is currently not configured for web deployment. Mobile platforms only.

## Build Scripts

### Windows Batch Scripts

#### Build Development APK

Create `build_superadmin_dev.bat`:

```batch
@echo off
echo Building SuperAdmin Development APK...
flutter clean
flutter pub get
flutter build apk --flavor superadmin --target lib/main_superadmin.dart
echo Build complete!
pause
```

#### Build Production APK

Create `build_superadmin_production.bat`:

```batch
@echo off
echo Building SuperAdmin Production APK...
flutter clean
flutter pub get
flutter build apk --release --flavor superadmin --target lib/main_superadmin.dart
echo Build complete!
echo APK location: build\app\outputs\flutter-apk\app-superadmin-release.apk
pause
```

#### Build App Bundle

Create `build_superadmin_bundle.bat`:

```batch
@echo off
echo Building SuperAdmin App Bundle...
flutter clean
flutter pub get
flutter build appbundle --release --flavor superadmin --target lib/main_superadmin.dart
echo Build complete!
echo Bundle location: build\app\outputs\bundle\superadminRelease\app-superadmin-release.aab
pause
```

### Linux/macOS Shell Scripts

#### Build Development APK

Create `build_superadmin_dev.sh`:

```bash
#!/bin/bash
echo "Building SuperAdmin Development APK..."
flutter clean
flutter pub get
flutter build apk --flavor superadmin --target lib/main_superadmin.dart
echo "Build complete!"
```

Make executable:
```bash
chmod +x build_superadmin_dev.sh
```

#### Build Production APK

Create `build_superadmin_production.sh`:

```bash
#!/bin/bash
echo "Building SuperAdmin Production APK..."
flutter clean
flutter pub get
flutter build apk --release --flavor superadmin --target lib/main_superadmin.dart
echo "Build complete!"
echo "APK location: build/app/outputs/flutter-apk/app-superadmin-release.apk"
```

## Build Optimization

### Reducing APK Size

1. Enable code shrinking in `android/app/build.gradle`:

```gradle
buildTypes {
    release {
        shrinkResources true
        minifyEnabled true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

2. Split APKs by ABI:

```gradle
android {
    splits {
        abi {
            enable true
            reset()
            include 'armeabi-v7a', 'arm64-v8a', 'x86_64'
            universalApk false
        }
    }
}
```

3. Build split APKs:

```bash
flutter build apk --release --split-per-abi --flavor superadmin --target lib/main_superadmin.dart
```

### Performance Optimization

1. Use release mode for production
2. Enable Dart obfuscation:

```bash
flutter build apk --release --obfuscate --split-debug-info=./debug-info --flavor superadmin --target lib/main_superadmin.dart
```

3. Profile build for performance testing:

```bash
flutter build apk --profile --flavor superadmin --target lib/main_superadmin.dart
```

## Troubleshooting

### Common Issues

#### 1. Flavor Not Found

**Error**: `Could not find flavor superadmin`

**Solution**: Ensure flavor is defined in `android/app/build.gradle` and iOS schemes are configured.

#### 2. Build Failed - Dependencies

**Error**: `Pub get failed`

**Solution**:
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

#### 3. Android Build Failed - Gradle

**Error**: `Gradle build failed`

**Solution**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter build apk --flavor superadmin --target lib/main_superadmin.dart
```

#### 4. iOS Build Failed - Signing

**Error**: `Code signing failed`

**Solution**:
1. Open Xcode
2. Select Runner target
3. Go to Signing & Capabilities
4. Select correct team and provisioning profile
5. Clean build folder (Cmd+Shift+K)
6. Build again

#### 5. Main Entry Point Not Found

**Error**: `Could not find main_superadmin.dart`

**Solution**: Ensure `lib/main_superadmin.dart` exists and contains:

```dart
import 'package:flutter/material.dart';
import 'core/config/flavor_config.dart';
import 'main.dart' as app;

void main() {
  FlavorConfig.initialize(AppFlavor.superAdmin);
  app.main();
}
```

#### 6. API Connection Failed

**Error**: App builds but cannot connect to API

**Solution**:
1. Verify API URL in `lib/core/config/api_config.dart`
2. Check network permissions in `AndroidManifest.xml`
3. Verify SSL certificates for HTTPS

### Build Verification

After building, verify the APK:

```bash
# Check APK info
aapt dump badging build/app/outputs/flutter-apk/app-superadmin-release.apk

# Check package name
aapt dump badging build/app/outputs/flutter-apk/app-superadmin-release.apk | grep package

# Check version
aapt dump badging build/app/outputs/flutter-apk/app-superadmin-release.apk | grep versionName
```

### Clean Build

If experiencing persistent issues, perform a clean build:

```bash
# Clean Flutter build
flutter clean

# Clean Android build (if on Windows)
cd android
gradlew clean
cd ..

# Clean Android build (if on Linux/macOS)
cd android
./gradlew clean
cd ..

# Get dependencies
flutter pub get

# Rebuild
flutter build apk --release --flavor superadmin --target lib/main_superadmin.dart
```

## Continuous Integration

### GitHub Actions Example

Create `.github/workflows/build-superadmin.yml`:

```yaml
name: Build SuperAdmin

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '11'
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'
      
      - run: flutter pub get
      
      - run: flutter build apk --release --flavor superadmin --target lib/main_superadmin.dart
      
      - uses: actions/upload-artifact@v3
        with:
          name: superadmin-apk
          path: build/app/outputs/flutter-apk/app-superadmin-release.apk
```

## Version Management

### Updating Version

Update version in `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Format: `major.minor.patch+buildNumber`

### Build Number

Increment build number for each release:
- Version: 1.0.0 (user-facing)
- Build: +1, +2, +3 (internal tracking)

## Distribution

### Android

1. **Google Play Store**: Upload App Bundle
2. **Direct Distribution**: Share APK file
3. **Internal Testing**: Use Firebase App Distribution

### iOS

1. **App Store**: Archive and upload via Xcode
2. **TestFlight**: For beta testing
3. **Enterprise Distribution**: For internal deployment

## Best Practices

1. Always clean before production builds
2. Test on multiple devices before release
3. Use App Bundle for Play Store (smaller download size)
4. Keep build scripts in version control
5. Document any custom build configurations
6. Use semantic versioning
7. Tag releases in Git
8. Maintain separate keystores for debug and release
9. Never commit signing keys to version control
10. Test builds on physical devices, not just emulators

## Support

For build issues:
1. Check Flutter documentation: https://docs.flutter.dev
2. Review Android/iOS platform-specific docs
3. Check project README.md
4. Contact development team

## Changelog

### Version 1.0.0
- Initial SuperAdmin flavor build configuration
- Android and iOS build support
- Build scripts for Windows, Linux, macOS
- CI/CD integration examples

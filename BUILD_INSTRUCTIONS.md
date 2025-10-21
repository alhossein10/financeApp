# Build Instructions - Finance App

This document explains how to build the Finance App with two flavors: **Admin** and **User**.

## Flavors Overview

### Admin Flavor
- **App Name**: Finance Admin
- **Package ID**: com.app.finance.admin
- **Features**: Full access including admin dashboard, cash management, currency tools, expenses, and export
- **Entry Point**: `lib/main_admin.dart`

### User Flavor
- **App Name**: Finance
- **Package ID**: com.app.finance.user
- **Features**: Limited access - currency tools, expenses, and export only (no admin dashboard or cash management)
- **Entry Point**: `lib/main_user.dart`

## Build Scripts

### 1. Clean Build (`clean_build.bat`)
Cleans all build artifacts and caches.

```bash
clean_build.bat
```

**What it does:**
- Stops Gradle daemons
- Runs `flutter clean`
- Removes Android build caches
- Removes build directory
- Removes releases directory

**When to use:**
- Before creating production builds
- When switching between flavors
- When experiencing build issues
- After updating dependencies

### 2. Development Build (`build_dev.bat`)
Creates debug APKs for testing.

```bash
build_dev.bat
```

**Options:**
1. Build Admin (debug)
2. Build User (debug)
3. Build Both (debug)

**Output:**
- `build\app\outputs\flutter-apk\app-admin-debug.apk`
- `build\app\outputs\flutter-apk\app-user-debug.apk`

**When to use:**
- During development
- For quick testing
- When you need debug features

### 3. Production Build (`build_releases.bat`)
Creates production-ready APKs and App Bundles.

```bash
build_releases.bat
```

**What it builds:**
1. User APK (release)
2. User App Bundle (release)
3. Admin APK (release)
4. Admin App Bundle (release)

**Output directory:** `releases/`
- `finance-user-release.apk` - Direct install on Android devices
- `finance-user-release.aab` - Google Play Store distribution
- `finance-admin-release.apk` - Direct install on Android devices
- `finance-admin-release.aab` - Google Play Store distribution

**When to use:**
- For production deployment
- For Play Store submission
- For distribution to end users

## Manual Build Commands

### Run in Development Mode

**Admin flavor:**
```bash
flutter run --flavor admin -t lib/main_admin.dart
```

**User flavor:**
```bash
flutter run --flavor user -t lib/main_user.dart
```

### Build Debug APK

**Admin flavor:**
```bash
flutter build apk --debug --flavor admin -t lib/main_admin.dart
```

**User flavor:**
```bash
flutter build apk --debug --flavor user -t lib/main_user.dart
```

### Build Release APK

**Admin flavor:**
```bash
flutter build apk --release --flavor admin -t lib/main_admin.dart
```

**User flavor:**
```bash
flutter build apk --release --flavor user -t lib/main_user.dart
```

### Build App Bundle (for Play Store)

**Admin flavor:**
```bash
flutter build appbundle --release --flavor admin -t lib/main_admin.dart
```

**User flavor:**
```bash
flutter build appbundle --release --flavor user -t lib/main_user.dart
```

## Recommended Workflow

### For Development:
1. Make code changes
2. Test with: `flutter run --flavor admin -t lib/main_admin.dart`
3. Or use: `build_dev.bat` for APK testing

### For Production Release:
1. Run: `clean_build.bat`
2. Run: `build_releases.bat`
3. Test APKs from `releases/` folder
4. Upload AAB files to Play Store

## File Structure

```
finance_app/
├── lib/
│   ├── main.dart              # Shared app code
│   ├── main_admin.dart        # Admin flavor entry point
│   └── main_user.dart         # User flavor entry point
├── android/
│   └── app/
│       └── build.gradle.kts   # Flavor configuration
├── build_releases.bat         # Production build script
├── build_dev.bat              # Development build script
├── clean_build.bat            # Clean script
└── releases/                  # Output directory (created by build)
```

## Troubleshooting

### Build fails with "file in use" error
- Close Android Studio / VS Code
- Run `clean_build.bat`
- Try building again

### Gradle daemon issues
- Run: `cd android && gradlew --stop`
- Run `clean_build.bat`

### Dependencies not found
- Run: `flutter pub get`
- Run: `flutter pub upgrade`

### APK not installing
- Uninstall previous version
- Check if you're installing the correct flavor
- Ensure USB debugging is enabled

## Distribution

### APK Files (.apk)
- Can be installed directly on Android devices
- Good for testing and direct distribution
- Larger file size

### App Bundle Files (.aab)
- Required for Google Play Store
- Optimized for each device configuration
- Smaller download size for users

## Version Management

Update version in `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

Format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`
- MAJOR: Breaking changes
- MINOR: New features
- PATCH: Bug fixes
- BUILD_NUMBER: Incremental build number

## Notes

- Both flavors share the same codebase
- Features are controlled by `FlavorConfig` in `lib/core/config/flavor_config.dart`
- Each flavor has its own package ID for independent installation
- Admin and User apps can be installed simultaneously on the same device

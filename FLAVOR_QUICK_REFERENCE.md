# Flavor Quick Reference

## Quick Commands

### Run App
```bash
# Admin
flutter run --flavor admin -t lib/main_admin.dart

# User
flutter run --flavor user -t lib/main_user.dart
```

### Build Scripts
```bash
clean_build.bat      # Clean everything
build_dev.bat        # Build debug APKs
build_releases.bat   # Build production releases
```

### Manual Builds
```bash
# Debug APK
flutter build apk --debug --flavor admin -t lib/main_admin.dart
flutter build apk --debug --flavor user -t lib/main_user.dart

# Release APK
flutter build apk --release --flavor admin -t lib/main_admin.dart
flutter build apk --release --flavor user -t lib/main_user.dart

# App Bundle (Play Store)
flutter build appbundle --release --flavor admin -t lib/main_admin.dart
flutter build appbundle --release --flavor user -t lib/main_user.dart
```

## Flavor Differences

| Feature | Admin | User |
|---------|-------|------|
| App Name | Finance Admin | Finance |
| Package ID | com.app.finance.admin | com.app.finance.user |
| Admin Dashboard | ✅ | ❌ |
| Cash Management | ✅ | ❌ |
| Cashbox Module | ✅ | ❌ |
| Currency Tools | ✅ | ✅ |
| Expenses | ✅ | ✅ |
| Export | ✅ | ✅ |

## Output Locations

### Development Builds
- `build/app/outputs/flutter-apk/app-admin-debug.apk`
- `build/app/outputs/flutter-apk/app-user-debug.apk`

### Production Builds
- `releases/finance-admin-release.apk`
- `releases/finance-admin-release.aab`
- `releases/finance-user-release.apk`
- `releases/finance-user-release.aab`

## Configuration Files

- `lib/core/config/flavor_config.dart` - Flavor configuration
- `lib/main_admin.dart` - Admin entry point
- `lib/main_user.dart` - User entry point
- `android/app/build.gradle.kts` - Android flavor setup

## Troubleshooting

**Problem:** Build fails
**Solution:** Run `clean_build.bat` first

**Problem:** Wrong flavor running
**Solution:** Check you're using correct `-t` flag

**Problem:** Can't install APK
**Solution:** Uninstall old version first

**Problem:** Gradle daemon issues
**Solution:** `cd android && gradlew --stop`

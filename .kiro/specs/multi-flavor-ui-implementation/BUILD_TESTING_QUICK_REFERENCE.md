# Build Testing Quick Reference - Task 28.3

## Quick Start

### 1. Run Automated Build Test
```bash
test_builds.bat
```

### 2. Verify Build Outputs
```bash
verify_builds.bat
```

### 3. Install on Device
```bash
adb install test_builds/finance-superadmin-test.apk
adb install test_builds/finance-admin-test.apk
adb install test_builds/finance-user-test.apk
```

## Build Commands

### SuperAdmin
```bash
flutter build apk --release --flavor superAdmin -t lib/main_superadmin.dart
```

### Admin
```bash
flutter build apk --release --flavor admin -t lib/main_admin.dart
```

### User
```bash
flutter build apk --release --flavor user -t lib/main_user.dart
```

## Application IDs

| Flavor | Application ID |
|--------|---------------|
| SuperAdmin | `com.app.finance.superadmin` |
| Admin | `com.app.finance.admin` |
| User | `com.app.finance.user` |

## Verification Commands

### Check Installed Apps
```bash
adb shell pm list packages | findstr finance
```

### Check App Info
```bash
adb shell dumpsys package com.app.finance.superadmin | findstr version
adb shell dumpsys package com.app.finance.admin | findstr version
adb shell dumpsys package com.app.finance.user | findstr version
```

### View Logs
```bash
# SuperAdmin
adb logcat | findstr "MAIN_SUPERADMIN"

# Admin
adb logcat | findstr "MAIN_ADMIN"

# User
adb logcat | findstr "MAIN_USER"
```

### Uninstall Apps
```bash
adb uninstall com.app.finance.superadmin
adb uninstall com.app.finance.admin
adb uninstall com.app.finance.user
```

### Clear App Data
```bash
adb shell pm clear com.app.finance.superadmin
adb shell pm clear com.app.finance.admin
adb shell pm clear com.app.finance.user
```

## Expected Navigation

### SuperAdmin
- Group Management
- Cash
- Transfers
- Analytics
- Profile

### Admin
- Group Management
- Financial Box
- Exchange
- Expenses
- Export
- Profile

### User
- Financial Box (Home)
- Exchange
- Expenses
- Export
- Profile

## Success Criteria

✅ All three APKs build successfully  
✅ All three apps install simultaneously  
✅ Unique application IDs verified  
✅ Correct app names displayed  
✅ Correct navigation for each flavor  
✅ Separate data storage  
✅ Independent uninstallation  

## Common Issues

### Build Fails
```bash
flutter clean
flutter pub get
# Try build again
```

### Installation Fails
```bash
# Uninstall existing app
adb uninstall com.app.finance.[flavor]
# Try install again
```

### Wrong Navigation
- Check FlavorConfig.initialize() in main entry point
- Verify correct main file is used: `-t lib/main_[flavor].dart`

## Files

- **Test Script:** `test_builds.bat`
- **Verify Script:** `verify_builds.bat`
- **Full Guide:** `.kiro/specs/multi-flavor-ui-implementation/BUILD_TESTING_GUIDE.md`
- **Test Report:** `.kiro/specs/multi-flavor-ui-implementation/TASK_28.3_TEST_REPORT_TEMPLATE.md`

## Requirements

- **35.5:** Flavor-specific testing
- **35.6:** Data visibility rules verification

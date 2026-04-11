# Build Testing Guide - Task 28.3

## Overview

This guide provides comprehensive instructions for testing the three flavor builds (SuperAdmin, Admin, User) to verify that:
1. All APKs build successfully
2. Separate app identifiers work correctly
3. Each flavor can be installed simultaneously on the same device
4. Each flavor displays the correct app name and functionality

## Build Configuration

### Flavor Definitions

| Flavor | Application ID | Entry Point | App Name |
|--------|---------------|-------------|----------|
| SuperAdmin | `com.app.finance.superadmin` | `lib/main_superadmin.dart` | Finance SuperAdmin |
| Admin | `com.app.finance.admin` | `lib/main_admin.dart` | Finance Admin |
| User | `com.app.finance.user` | `lib/main_user.dart` | Finance User |

### Build Commands

```bash
# SuperAdmin Flavor
flutter build apk --release --flavor superAdmin -t lib/main_superadmin.dart

# Admin Flavor
flutter build apk --release --flavor admin -t lib/main_admin.dart

# User Flavor
flutter build apk --release --flavor user -t lib/main_user.dart
```

## Automated Build Testing

### Using the Test Script

Run the automated build test script:

```bash
test_builds.bat
```

This script will:
1. Clean previous builds
2. Get dependencies
3. Build all three flavors
4. Copy APKs to `test_builds/` directory
5. Generate a test summary report

### Expected Output

```
========================================
Build Test Summary
========================================

SuperAdmin Build: PASS
Admin Build:      PASS
User Build:       PASS

[OK] test_builds\finance-superadmin-test.apk
[OK] test_builds\finance-admin-test.apk
[OK] test_builds\finance-user-test.apk

========================================
ALL BUILDS PASSED!
========================================
```

## Manual Testing Checklist

### Test 1: Build Verification

- [ ] SuperAdmin APK builds without errors
- [ ] Admin APK builds without errors
- [ ] User APK builds without errors
- [ ] All APK files are created in expected locations
- [ ] APK file sizes are reasonable (typically 30-50 MB)

### Test 2: Installation Testing

#### Prerequisites
- Android device or emulator (Android 5.0+)
- USB debugging enabled
- ADB installed and configured

#### Installation Steps

1. **Install SuperAdmin APK**
   ```bash
   adb install test_builds/finance-superadmin-test.apk
   ```
   - [ ] Installation succeeds
   - [ ] App appears in launcher as "Finance SuperAdmin"
   - [ ] App icon displays correctly

2. **Install Admin APK**
   ```bash
   adb install test_builds/finance-admin-test.apk
   ```
   - [ ] Installation succeeds
   - [ ] App appears in launcher as "Finance Admin"
   - [ ] App icon displays correctly
   - [ ] SuperAdmin app is still installed (not replaced)

3. **Install User APK**
   ```bash
   adb install test_builds/finance-user-test.apk
   ```
   - [ ] Installation succeeds
   - [ ] App appears in launcher as "Finance User"
   - [ ] App icon displays correctly
   - [ ] SuperAdmin and Admin apps are still installed

### Test 3: App Identifier Verification

Verify that all three apps are installed simultaneously:

```bash
adb shell pm list packages | findstr finance
```

Expected output:
```
package:com.app.finance.superadmin
package:com.app.finance.admin
package:com.app.finance.user
```

- [ ] All three package names are listed
- [ ] Package names match the configured application IDs

### Test 4: Functionality Testing

#### SuperAdmin Flavor
- [ ] App launches successfully
- [ ] Console shows: "App starting with SuperAdmin flavor"
- [ ] Navigation shows: Group, Cash, Transfers, Analytics, Profile
- [ ] SuperAdmin Cash Page is accessible
- [ ] SuperAdmin Expenses Page is accessible
- [ ] Currency Module is enabled
- [ ] Export Module is enabled

#### Admin Flavor
- [ ] App launches successfully
- [ ] Console shows: "App starting with Admin flavor"
- [ ] Navigation shows: Group Management, Financial Box, Exchange, Expenses, Export, Profile
- [ ] Cash module is enabled
- [ ] Currency module is enabled
- [ ] Export module is enabled

#### User Flavor
- [ ] App launches successfully
- [ ] Console shows: "App starting with User flavor"
- [ ] Navigation shows: Financial Box (Home), Exchange, Expenses, Export, Profile
- [ ] Cash module is enabled
- [ ] Currency module is enabled
- [ ] Export module is enabled

### Test 5: Isolation Testing

Verify that each flavor maintains separate data:

1. **Register/Login in SuperAdmin**
   - [ ] Create account in SuperAdmin app
   - [ ] Verify data is stored

2. **Register/Login in Admin**
   - [ ] Create account in Admin app
   - [ ] Verify data is separate from SuperAdmin
   - [ ] SuperAdmin data is not affected

3. **Register/Login in User**
   - [ ] Create account in User app
   - [ ] Verify data is separate from SuperAdmin and Admin
   - [ ] Other apps' data is not affected

### Test 6: Uninstallation Testing

Verify that uninstalling one flavor doesn't affect others:

1. **Uninstall User app**
   ```bash
   adb uninstall com.app.finance.user
   ```
   - [ ] User app is removed
   - [ ] SuperAdmin app still works
   - [ ] Admin app still works

2. **Reinstall User app**
   ```bash
   adb install test_builds/finance-user-test.apk
   ```
   - [ ] User app installs successfully
   - [ ] All three apps work independently

## Troubleshooting

### Build Failures

**Problem**: Build fails with Gradle errors
- **Solution**: Run `flutter clean` and try again
- **Solution**: Check that all dependencies are up to date: `flutter pub get`

**Problem**: APK not found after build
- **Solution**: Check the build output path matches the expected location
- **Solution**: Verify the flavor name matches exactly (case-sensitive)

### Installation Failures

**Problem**: Installation fails with "INSTALL_FAILED_UPDATE_INCOMPATIBLE"
- **Solution**: Uninstall the existing app first
- **Solution**: Verify the application ID is unique

**Problem**: App crashes on launch
- **Solution**: Check device logs: `adb logcat | findstr flutter`
- **Solution**: Verify the correct entry point is used for each flavor

### Flavor Configuration Issues

**Problem**: Wrong navigation items appear
- **Solution**: Verify FlavorConfig.initialize() is called with correct flavor
- **Solution**: Check that the correct main entry point is used

**Problem**: Features are not enabled/disabled correctly
- **Solution**: Check FlavorConfig feature flags
- **Solution**: Verify flavor-specific configuration in lib/core/config/flavor_config.dart

## Verification Commands

### Check Installed Apps
```bash
adb shell pm list packages | findstr finance
```

### Get App Info
```bash
adb shell dumpsys package com.app.finance.superadmin | findstr version
adb shell dumpsys package com.app.finance.admin | findstr version
adb shell dumpsys package com.app.finance.user | findstr version
```

### View App Logs
```bash
# SuperAdmin logs
adb logcat | findstr "MAIN_SUPERADMIN"

# Admin logs
adb logcat | findstr "MAIN_ADMIN"

# User logs
adb logcat | findstr "MAIN_USER"
```

### Clear App Data (for testing)
```bash
adb shell pm clear com.app.finance.superadmin
adb shell pm clear com.app.finance.admin
adb shell pm clear com.app.finance.user
```

## Success Criteria

Task 28.3 is complete when:

✅ All three flavor APKs build successfully without errors
✅ All three apps can be installed simultaneously on the same device
✅ Each app has a unique application ID (package name)
✅ Each app displays the correct name in the launcher
✅ Each app shows the correct navigation structure for its flavor
✅ Each app maintains separate data storage
✅ Uninstalling one app doesn't affect the others

## Test Results Template

```
========================================
Build Testing Results - Task 28.3
========================================

Date: [DATE]
Tester: [NAME]
Device: [DEVICE MODEL]
Android Version: [VERSION]

Build Tests:
[ ] SuperAdmin APK builds successfully
[ ] Admin APK builds successfully
[ ] User APK builds successfully

Installation Tests:
[ ] All three apps install simultaneously
[ ] Separate app identifiers verified
[ ] Correct app names displayed

Functionality Tests:
[ ] SuperAdmin flavor works correctly
[ ] Admin flavor works correctly
[ ] User flavor works correctly

Isolation Tests:
[ ] Each flavor maintains separate data
[ ] Uninstalling one doesn't affect others

Overall Result: [PASS/FAIL]

Notes:
[Any additional observations or issues]
```

## Next Steps

After completing Task 28.3:
1. Document any issues found during testing
2. Update build scripts if needed
3. Proceed to Task 29: Documentation
4. Prepare for final testing and deployment

## References

- Requirements: 35.5, 35.6
- Design Document: `.kiro/specs/multi-flavor-ui-implementation/design.md`
- Build Configuration: `android/app/build.gradle.kts`
- Flavor Config: `lib/core/config/flavor_config.dart`

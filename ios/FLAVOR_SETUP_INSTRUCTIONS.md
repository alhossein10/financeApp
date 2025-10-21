# iOS Flavor Configuration Instructions

This document explains how to set up Admin and User build schemes in Xcode for the Finance app.

## Configuration Files Created

The following xcconfig files have been created to support both flavors:

- `Debug-Admin.xcconfig` - Admin flavor debug configuration
- `Release-Admin.xcconfig` - Admin flavor release configuration
- `Debug-User.xcconfig` - User flavor debug configuration
- `Release-User.xcconfig` - User flavor release configuration

## Manual Xcode Configuration Steps

Since Xcode schemes must be configured through the Xcode IDE, follow these steps:

### 1. Open the Project in Xcode

```bash
open ios/Runner.xcworkspace
```

### 2. Create Admin Scheme

1. In Xcode, go to **Product > Scheme > Manage Schemes...**
2. Click the **+** button to create a new scheme
3. Name it **Admin**
4. Select **Runner** as the target
5. Click **OK**

### 3. Configure Admin Scheme

1. Select the **Admin** scheme and click **Edit...**
2. For each build configuration (Debug, Release, Profile):
   - Click on **Build** in the left sidebar
   - Expand **Runner** target
   - Click on **Runner** project
   - In the **Info** tab, find the configuration
   - Set **Debug** to use `Debug-Admin.xcconfig`
   - Set **Release** to use `Release-Admin.xcconfig`
3. Click **Close**

### 4. Create User Scheme

1. Repeat step 2, but name the scheme **User**

### 5. Configure User Scheme

1. Select the **User** scheme and click **Edit...**
2. For each build configuration:
   - Set **Debug** to use `Debug-User.xcconfig`
   - Set **Release** to use `Release-User.xcconfig`
3. Click **Close**

### 6. Verify Configuration

1. Select the **Admin** scheme
2. Build the project (⌘B)
3. Verify the app name shows as "Finance Admin"
4. Verify the bundle identifier is `com.app.finance.admin`

5. Select the **User** scheme
6. Build the project (⌘B)
7. Verify the app name shows as "Finance"
8. Verify the bundle identifier is `com.app.finance.user`

## Building from Command Line

Once schemes are configured, you can build from the command line:

### Build Admin Version

```bash
# Debug
flutter build ios --flavor admin -t lib/main_admin.dart --debug

# Release
flutter build ios --flavor admin -t lib/main_admin.dart --release
```

### Build User Version

```bash
# Debug
flutter build ios --flavor user -t lib/main_user.dart --debug

# Release
flutter build ios --flavor user -t lib/main_user.dart --release
```

## Running on Device/Simulator

### Run Admin Version

```bash
flutter run --flavor admin -t lib/main_admin.dart
```

### Run User Version

```bash
flutter run --flavor user -t lib/main_user.dart
```

## Troubleshooting

### Issue: "No such module" errors

**Solution:** Clean the build folder and rebuild:
```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter build ios --flavor admin -t lib/main_admin.dart
```

### Issue: Wrong app name or bundle identifier

**Solution:** Verify the xcconfig files are properly linked to the schemes in Xcode.

### Issue: Schemes not appearing

**Solution:** Make sure the schemes are marked as "Shared" in Xcode's Manage Schemes dialog.

## Notes

- The xcconfig files automatically set the correct bundle identifier and app display name
- The FLUTTER_TARGET variable ensures the correct entry point (main_admin.dart or main_user.dart) is used
- Both flavors can be installed on the same device simultaneously due to different bundle identifiers

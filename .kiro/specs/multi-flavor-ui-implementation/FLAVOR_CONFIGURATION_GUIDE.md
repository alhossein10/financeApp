# Flavor Configuration Guide

## Overview

This guide explains how to configure and build the three flavors of the Finance application: Superadmin, Admin, and User. Each flavor provides a distinct user experience with role-specific features.

## Table of Contents

1. [Understanding Flavors](#understanding-flavors)
2. [Project Structure](#project-structure)
3. [Flavor Configuration](#flavor-configuration)
4. [Build Configuration](#build-configuration)
5. [Running Flavors](#running-flavors)
6. [Testing Flavors](#testing-flavors)
7. [Troubleshooting](#troubleshooting)

## Understanding Flavors

### What are Flavors?

Flavors allow you to create multiple versions of your app from a single codebase. Each flavor can have:
- Different app names
- Different app icons
- Different package identifiers
- Different feature sets
- Different navigation structures

### Three Flavors

1. **Superadmin**: Manages multiple Admin groups
2. **Admin**: Manages a group of Users
3. **User**: Individual financial tracking

## Project Structure

```
lib/
├── main.dart                    # Default entry point
├── main_superadmin.dart         # Superadmin flavor entry
├── main_admin.dart              # Admin flavor entry
├── main_user.dart               # User flavor entry
├── core/
│   ├── config/
│   │   └── flavor_config.dart   # Flavor configuration
│   ├── routing/
│   │   └── app_router.dart      # Flavor-specific routing
│   └── widgets/
│       └── app_navigation_bar.dart  # Flavor-specific navigation
├── features/
│   ├── superadmin/              # Superadmin-only features
│   ├── admin/                   # Admin-specific features
│   └── user/                    # User-specific features
└── ui/
    └── ...                      # Shared UI components

android/
├── app/
│   ├── build.gradle             # Android flavor configuration
│   └── src/
│       ├── superadmin/          # Superadmin Android resources
│       ├── admin/               # Admin Android resources
│       └── user/                # User Android resources

ios/
├── Runner/
│   ├── Info.plist              # iOS configuration
│   └── Configurations/
│       ├── Superadmin.xcconfig
│       ├── Admin.xcconfig
│       └── User.xcconfig
```

## Flavor Configuration

### FlavorConfig Class

Location: `lib/core/config/flavor_config.dart`

```dart
enum AppFlavor {
  superadmin,
  admin,
  user,
}

class FlavorConfig {
  final AppFlavor flavor;
  final String appName;
  final String packageName;
  
  // Feature flags
  final bool canManageAdmins;
  final bool canManageUsers;
  final bool canViewAnalytics;
  final bool canCreateExpenses;
  final bool canExchangeCurrency;
  final bool canExportData;
  
  // Navigation
  final List<NavigationDestination> navigationItems;
  final String defaultRoute;
}
```

### Superadmin Configuration

```dart
FlavorConfig.superadmin()
    : flavor = AppFlavor.superadmin,
      appName = 'Finance - Superadmin',
      packageName = 'com.finance.superadmin',
      canManageAdmins = true,
      canManageUsers = false,
      canViewAnalytics = true,
      canCreateExpenses = false,
      canExchangeCurrency = false,
      canExportData = true,
      navigationItems = [
        NavigationDestination(icon: Icons.group, label: 'Group'),
        NavigationDestination(icon: Icons.account_balance_wallet, label: 'Cash'),
        NavigationDestination(icon: Icons.swap_horiz, label: 'Transfers'),
        NavigationDestination(icon: Icons.analytics, label: 'Analytics'),
        NavigationDestination(icon: Icons.person, label: 'Profile'),
      ],
      defaultRoute = '/group-management';
```

### Admin Configuration

```dart
FlavorConfig.admin()
    : flavor = AppFlavor.admin,
      appName = 'Finance - Admin',
      packageName = 'com.finance.admin',
      canManageAdmins = false,
      canManageUsers = true,
      canViewAnalytics = false,
      canCreateExpenses = true,
      canExchangeCurrency = true,
      canExportData = true,
      navigationItems = [
        NavigationDestination(icon: Icons.group, label: 'Group'),
        NavigationDestination(icon: Icons.account_balance_wallet, label: 'Cash'),
        NavigationDestination(icon: Icons.currency_exchange, label: 'Exchange'),
        NavigationDestination(icon: Icons.receipt, label: 'Expenses'),
        NavigationDestination(icon: Icons.download, label: 'Export'),
        NavigationDestination(icon: Icons.person, label: 'Profile'),
      ],
      defaultRoute = '/group-management';
```

### User Configuration

```dart
FlavorConfig.user()
    : flavor = AppFlavor.user,
      appName = 'Finance - User',
      packageName = 'com.finance.user',
      canManageAdmins = false,
      canManageUsers = false,
      canViewAnalytics = false,
      canCreateExpenses = true,
      canExchangeCurrency = true,
      canExportData = true,
      navigationItems = [
        NavigationDestination(icon: Icons.home, label: 'Home'),
        NavigationDestination(icon: Icons.currency_exchange, label: 'Exchange'),
        NavigationDestination(icon: Icons.receipt, label: 'Expenses'),
        NavigationDestination(icon: Icons.download, label: 'Export'),
        NavigationDestination(icon: Icons.person, label: 'Profile'),
      ],
      defaultRoute = '/financial-box';
```

## Build Configuration

### Android Configuration

Location: `android/app/build.gradle`

```gradle
android {
    flavorDimensions "app"
    
    productFlavors {
        superadmin {
            dimension "app"
            applicationId "com.finance.superadmin"
            resValue "string", "app_name", "Finance - Superadmin"
            manifestPlaceholders = [appIcon: "@mipmap/ic_launcher_superadmin"]
        }
        
        admin {
            dimension "app"
            applicationId "com.finance.admin"
            resValue "string", "app_name", "Finance - Admin"
            manifestPlaceholders = [appIcon: "@mipmap/ic_launcher_admin"]
        }
        
        user {
            dimension "app"
            applicationId "com.finance.user"
            resValue "string", "app_name", "Finance - User"
            manifestPlaceholders = [appIcon: "@mipmap/ic_launcher_user"]
        }
    }
}
```

### iOS Configuration

Each flavor has its own `.xcconfig` file:

**Superadmin.xcconfig**:
```
PRODUCT_BUNDLE_IDENTIFIER = com.finance.superadmin
PRODUCT_NAME = Finance - Superadmin
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon-Superadmin
```

**Admin.xcconfig**:
```
PRODUCT_BUNDLE_IDENTIFIER = com.finance.admin
PRODUCT_NAME = Finance - Admin
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon-Admin
```

**User.xcconfig**:
```
PRODUCT_BUNDLE_IDENTIFIER = com.finance.user
PRODUCT_NAME = Finance - User
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon-User
```

### Main Entry Points

Each flavor has its own main entry point:

**main_superadmin.dart**:
```dart
void main() {
  FlavorConfig.initialize(FlavorConfig.superadmin());
  runApp(const MyApp());
}
```

**main_admin.dart**:
```dart
void main() {
  FlavorConfig.initialize(FlavorConfig.admin());
  runApp(const MyApp());
}
```

**main_user.dart**:
```dart
void main() {
  FlavorConfig.initialize(FlavorConfig.user());
  runApp(const MyApp());
}
```

## Running Flavors

### Development Mode

#### Run Superadmin
```bash
flutter run --flavor superadmin --target lib/main_superadmin.dart
```

#### Run Admin
```bash
flutter run --flavor admin --target lib/main_admin.dart
```

#### Run User
```bash
flutter run --flavor user --target lib/main_user.dart
```

### Using Batch Scripts (Windows)

**build_superadmin.bat**:
```batch
flutter build apk --flavor superadmin --target lib/main_superadmin.dart
```

**build_admin.bat**:
```batch
flutter build apk --flavor admin --target lib/main_admin.dart
```

**build_user.bat**:
```batch
flutter build apk --flavor user --target lib/main_user.dart
```

**build_releases.bat** (Build all flavors):
```batch
@echo off
echo Building all flavors...

echo Building Superadmin...
call flutter build apk --flavor superadmin --target lib/main_superadmin.dart

echo Building Admin...
call flutter build apk --flavor admin --target lib/main_admin.dart

echo Building User...
call flutter build apk --flavor user --target lib/main_user.dart

echo All builds complete!
pause
```

### Release Builds

#### Android APK
```bash
flutter build apk --release --flavor superadmin --target lib/main_superadmin.dart
flutter build apk --release --flavor admin --target lib/main_admin.dart
flutter build apk --release --flavor user --target lib/main_user.dart
```

#### Android App Bundle
```bash
flutter build appbundle --release --flavor superadmin --target lib/main_superadmin.dart
flutter build appbundle --release --flavor admin --target lib/main_admin.dart
flutter build appbundle --release --flavor user --target lib/main_user.dart
```

#### iOS
```bash
flutter build ios --release --flavor superadmin --target lib/main_superadmin.dart
flutter build ios --release --flavor admin --target lib/main_admin.dart
flutter build ios --release --flavor user --target lib/main_user.dart
```

## Testing Flavors

### Unit Tests

Run tests for specific flavor:
```bash
flutter test --dart-define=FLAVOR=superadmin
flutter test --dart-define=FLAVOR=admin
flutter test --dart-define=FLAVOR=user
```

### Widget Tests

```dart
testWidgets('Superadmin navigation shows correct items', (tester) async {
  FlavorConfig.initialize(FlavorConfig.superadmin());
  
  await tester.pumpWidget(const MyApp());
  
  expect(find.text('Group'), findsOneWidget);
  expect(find.text('Cash'), findsOneWidget);
  expect(find.text('Transfers'), findsOneWidget);
  expect(find.text('Analytics'), findsOneWidget);
  expect(find.text('Profile'), findsOneWidget);
  
  // Should not have Exchange or Export
  expect(find.text('Exchange'), findsNothing);
  expect(find.text('Export'), findsNothing);
});
```

### Integration Tests

```bash
flutter drive --flavor superadmin --target=test_driver/app.dart
flutter drive --flavor admin --target=test_driver/app.dart
flutter drive --flavor user --target=test_driver/app.dart
```

## Troubleshooting

### Common Issues

#### Wrong Flavor Running

**Problem**: App shows wrong features or navigation.

**Solution**:
1. Verify you're using the correct `--flavor` and `--target` flags
2. Clean build: `flutter clean && flutter pub get`
3. Rebuild the app

#### Build Fails

**Problem**: Build fails with flavor-related errors.

**Solution**:
1. Check `build.gradle` for correct flavor configuration
2. Verify all flavor directories exist in `android/app/src/`
3. Ensure `.xcconfig` files exist for iOS
4. Run `flutter clean` and rebuild

#### App Icon Not Showing

**Problem**: Default icon shows instead of flavor-specific icon.

**Solution**:
1. Verify icon files exist in flavor-specific directories
2. Check `manifestPlaceholders` in `build.gradle`
3. Check `ASSETCATALOG_COMPILER_APPICON_NAME` in `.xcconfig`
4. Clean and rebuild

#### Multiple Apps Installing

**Problem**: Installing one flavor overwrites another.

**Solution**:
- This is expected behavior if package names are the same
- Verify each flavor has unique `applicationId` (Android) and `PRODUCT_BUNDLE_IDENTIFIER` (iOS)

### Debugging Flavor Issues

#### Check Current Flavor

```dart
void printCurrentFlavor() {
  final config = FlavorConfig.instance;
  print('Current Flavor: ${config.flavor}');
  print('App Name: ${config.appName}');
  print('Package: ${config.packageName}');
  print('Features: ${config.featureFlags}');
}
```

#### Verify Feature Flags

```dart
if (FlavorConfig.instance.canCreateExpenses) {
  // Show create expense button
} else {
  // Hide create expense button
}
```

## Best Practices

### 1. Use Feature Flags

Always check feature flags before showing features:
```dart
if (FlavorConfig.instance.canExchangeCurrency) {
  // Show exchange feature
}
```

### 2. Centralize Configuration

Keep all flavor-specific configuration in `FlavorConfig`:
- Don't hardcode flavor checks throughout the app
- Use feature flags instead of flavor enum checks

### 3. Test All Flavors

- Test each flavor independently
- Verify navigation is correct
- Verify features are properly hidden/shown
- Test data visibility rules

### 4. Consistent Naming

Use consistent naming across:
- Main entry points (`main_*.dart`)
- Build scripts (`build_*.bat`)
- Flavor names in configuration

### 5. Documentation

Document:
- Which features are available in each flavor
- How to build each flavor
- Any flavor-specific configuration

## Advanced Configuration

### Environment-Specific Configuration

You can combine flavors with environments (dev, staging, prod):

```dart
class FlavorConfig {
  final AppFlavor flavor;
  final Environment environment;
  
  String get apiBaseUrl {
    switch (environment) {
      case Environment.dev:
        return 'https://dev-api.financeapp.com';
      case Environment.staging:
        return 'https://staging-api.financeapp.com';
      case Environment.prod:
        return 'https://api.financeapp.com';
    }
  }
}
```

### Custom Build Scripts

Create custom scripts for specific scenarios:

**build_dev_all.bat** (Build all flavors for development):
```batch
flutter build apk --debug --flavor superadmin --target lib/main_superadmin.dart
flutter build apk --debug --flavor admin --target lib/main_admin.dart
flutter build apk --debug --flavor user --target lib/main_user.dart
```

### CI/CD Integration

Example GitHub Actions workflow:

```yaml
name: Build All Flavors

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        flavor: [superadmin, admin, user]
    
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      
      - name: Build ${{ matrix.flavor }}
        run: |
          flutter build apk --release \
            --flavor ${{ matrix.flavor }} \
            --target lib/main_${{ matrix.flavor }}.dart
```

## Reference

### Flavor Comparison Table

| Feature | Superadmin | Admin | User |
|---------|-----------|-------|------|
| Manage Admins | ✓ | ✗ | ✗ |
| Manage Users | ✗ | ✓ | ✗ |
| View Analytics | ✓ | ✗ | ✗ |
| Create Expenses | ✗ | ✓ | ✓ |
| Exchange Currency | ✗ | ✓ | ✓ |
| Export Data | ✓ | ✓ | ✓ |
| Transfer Funds | ✓ | ✓ | ✗ |

### Package Identifiers

| Flavor | Android | iOS |
|--------|---------|-----|
| Superadmin | com.finance.superadmin | com.finance.superadmin |
| Admin | com.finance.admin | com.finance.admin |
| User | com.finance.user | com.finance.user |

### Build Output Locations

**Android APK**:
- `build/app/outputs/flutter-apk/app-superadmin-release.apk`
- `build/app/outputs/flutter-apk/app-admin-release.apk`
- `build/app/outputs/flutter-apk/app-user-release.apk`

**Android App Bundle**:
- `build/app/outputs/bundle/superadminRelease/app-superadmin-release.aab`
- `build/app/outputs/bundle/adminRelease/app-admin-release.aab`
- `build/app/outputs/bundle/userRelease/app-user-release.aab`

---

**Version**: 1.0  
**Last Updated**: November 2024

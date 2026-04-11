# Flavor Configuration Quick Reference

## Overview
This guide provides quick access to flavor configuration usage patterns for the Finance app's three flavors: SuperAdmin, Admin, and User.

## Build & Run Commands

### Development (Debug)
```bash
# SuperAdmin
flutter run --flavor superAdmin -t lib/main_superadmin.dart

# Admin  
flutter run --flavor admin -t lib/main_admin.dart

# User
flutter run --flavor user -t lib/main_user.dart
```

### Production (Release)
```bash
# SuperAdmin APK
flutter build apk --release --flavor superAdmin -t lib/main_superadmin.dart

# Admin APK
flutter build apk --release --flavor admin -t lib/main_admin.dart

# User APK
flutter build apk --release --flavor user -t lib/main_user.dart
```

### iOS Builds
```bash
# SuperAdmin
flutter build ios --release --flavor superAdmin -t lib/main_superadmin.dart

# Admin
flutter build ios --release --flavor admin -t lib/main_admin.dart

# User
flutter build ios --release --flavor user -t lib/main_user.dart
```

## Code Usage Patterns

### 1. Check Current Flavor
```dart
import 'package:finance_app/core/config/flavor_config.dart';

// Check flavor type
if (FlavorConfig.instance.isSuperAdmin) {
  // SuperAdmin-specific code
}

if (FlavorConfig.instance.isAdmin) {
  // Admin-specific code
}

if (FlavorConfig.instance.isUser) {
  // User-specific code
}
```

### 2. Check Feature Availability
```dart
// Check if user can create expenses
if (FlavorConfig.instance.isFeatureEnabled('canCreateExpenses')) {
  // Show create expense button
}

// Check if user can manage groups
if (FlavorConfig.instance.isFeatureEnabled('canManageGroup')) {
  // Show group management UI
}

// Check if user can exchange currency
if (FlavorConfig.instance.isFeatureEnabled('canExchangeCurrency')) {
  // Show exchange page
}
```

### 3. Get Navigation Destinations
```dart
// Get all navigation destinations for current flavor
final destinations = FlavorConfig.instance.getNavigationDestinations();

// Use in NavigationBar
NavigationBar(
  destinations: destinations.map((dest) => NavigationDestination(
    icon: Icon(dest.icon),
    selectedIcon: Icon(dest.selectedIcon),
    label: AppLocalizations.of(context).translate(dest.labelKey),
  )).toList(),
  onDestinationSelected: (index) {
    Navigator.pushNamed(context, destinations[index].route);
  },
)
```

### 4. Check Module Availability
```dart
// Check if cash module is enabled
if (FlavorConfig.instance.enableCashModule) {
  // Show cash-related features
}

// Check if currency exchange is enabled
if (FlavorConfig.instance.enableCurrencyModule) {
  // Show currency exchange features
}

// Check if export is enabled
if (FlavorConfig.instance.enableExportModule) {
  // Show export features
}
```

### 5. Get App Information
```dart
// Get app name
final appName = FlavorConfig.instance.appName;
// SuperAdmin: "Finance SuperAdmin"
// Admin: "Finance Admin"
// User: "Finance"

// Get application ID
final appId = FlavorConfig.instance.applicationId;
// SuperAdmin: "com.app.finance.superadmin"
// Admin: "com.app.finance.admin"
// User: "com.app.finance.user"

// Get default home route
final homeRoute = FlavorConfig.instance.defaultHomeRoute;
```

## Feature Flags Reference

### Available Feature Flags:
- `canCreateExpenses` - Can create expense records
- `canExchangeCurrency` - Can perform currency exchanges
- `canExportData` - Can export data to PDF/Excel
- `canManageGroup` - Can manage user/admin groups
- `canViewAnalytics` - Can view analytics dashboard
- `canTransferFunds` - Can transfer funds to others
- `canViewTransfers` - Can view transfer history
- `canManageIncoming` - Can manually add incoming amounts

### Feature Flags by Flavor:

| Feature | SuperAdmin | Admin | User |
|---------|-----------|-------|------|
| canCreateExpenses | ❌ | ✅ | ✅ |
| canExchangeCurrency | ❌ | ✅ | ✅ |
| canExportData | ❌ | ✅ | ✅ |
| canManageGroup | ✅ | ✅ | ❌ |
| canViewAnalytics | ✅ | ❌ | ❌ |
| canTransferFunds | ✅ | ✅ | ❌ |
| canViewTransfers | ✅ | ✅ | ✅ |
| canManageIncoming | ✅ | ❌ | ❌ |

## Module Flags Reference

### Available Module Flags:
- `enableCashModule` - Cash management features
- `enableCashboxModule` - Cashbox features
- `enableCurrencyModule` - Currency exchange features
- `enableExpensesModule` - Expense tracking features
- `enableExportModule` - Data export features
- `enableAdminDashboard` - Admin dashboard
- `enableFundBox` - Fund box display
- `enableAuditLogs` - Audit log viewing
- `enableUserManagement` - User management features

### Module Flags by Flavor:

| Module | SuperAdmin | Admin | User |
|--------|-----------|-------|------|
| enableCashModule | ✅ | ✅ | ❌ |
| enableCashboxModule | ✅ | ✅ | ❌ |
| enableCurrencyModule | ❌ | ✅ | ✅ |
| enableExpensesModule | ✅ | ✅ | ✅ |
| enableExportModule | ❌ | ✅ | ✅ |
| enableAdminDashboard | ❌ | ✅ | ❌ |
| enableFundBox | ✅ | ✅ | ✅ |
| enableAuditLogs | ✅ | ✅ | ❌ |
| enableUserManagement | ✅ | ✅ | ❌ |

## Navigation Structure

### SuperAdmin Navigation:
1. 🏢 Group Management - `/group-management`
2. 💰 Cash - `/cash`
3. 🔄 Transfers - `/transfers`
4. 📊 Analytics - `/analytics`
5. 👤 Profile - `/profile`

### Admin Navigation:
1. 🏢 Group Management - `/group-management`
2. 💰 Cash - `/cash`
3. 💱 Exchange - `/exchange`
4. 🧾 Expenses - `/expenses`
5. 📤 Export - `/export`
6. 👤 Profile - `/profile`

### User Navigation:
1. 🏠 Home - `/home`
2. 💱 Exchange - `/exchange`
3. 🧾 Expenses - `/expenses`
4. 📤 Export - `/export`
5. 👤 Profile - `/profile`

## Common Patterns

### Conditional UI Rendering
```dart
Widget build(BuildContext context) {
  final config = FlavorConfig.instance;
  
  return Column(
    children: [
      // Always show
      Text('Welcome to ${config.appName}'),
      
      // Conditional based on flavor
      if (config.isSuperAdmin)
        SuperAdminDashboard(),
      
      if (config.isAdmin)
        AdminDashboard(),
      
      if (config.isUser)
        UserDashboard(),
      
      // Conditional based on feature flag
      if (config.isFeatureEnabled('canCreateExpenses'))
        ElevatedButton(
          onPressed: () => _createExpense(),
          child: Text('Create Expense'),
        ),
    ],
  );
}
```

### Route Guards
```dart
Route<dynamic> generateRoute(RouteSettings settings) {
  final config = FlavorConfig.instance;
  
  switch (settings.name) {
    case '/analytics':
      // Only accessible to SuperAdmin
      if (!config.isFeatureEnabled('canViewAnalytics')) {
        return MaterialPageRoute(
          builder: (_) => UnauthorizedPage(),
        );
      }
      return MaterialPageRoute(
        builder: (_) => AnalyticsPage(),
      );
      
    case '/exchange':
      // Not accessible to SuperAdmin
      if (!config.isFeatureEnabled('canExchangeCurrency')) {
        return MaterialPageRoute(
          builder: (_) => UnauthorizedPage(),
        );
      }
      return MaterialPageRoute(
        builder: (_) => ExchangePage(),
      );
      
    default:
      return MaterialPageRoute(
        builder: (_) => NotFoundPage(),
      );
  }
}
```

### Dynamic Menu Building
```dart
List<MenuItem> buildMenu() {
  final config = FlavorConfig.instance;
  final menu = <MenuItem>[];
  
  // Add items based on feature flags
  if (config.isFeatureEnabled('canManageGroup')) {
    menu.add(MenuItem(
      title: 'Group Management',
      icon: Icons.group,
      route: '/group-management',
    ));
  }
  
  if (config.isFeatureEnabled('canViewAnalytics')) {
    menu.add(MenuItem(
      title: 'Analytics',
      icon: Icons.analytics,
      route: '/analytics',
    ));
  }
  
  if (config.isFeatureEnabled('canExportData')) {
    menu.add(MenuItem(
      title: 'Export',
      icon: Icons.ios_share,
      route: '/export',
    ));
  }
  
  return menu;
}
```

## Testing

### Unit Test Example
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/config/flavor_config.dart';

void main() {
  test('SuperAdmin should not be able to create expenses', () {
    FlavorConfig.initialize(AppFlavor.superAdmin);
    final config = FlavorConfig.instance;
    
    expect(config.isFeatureEnabled('canCreateExpenses'), isFalse);
  });
  
  test('Admin should be able to create expenses', () {
    FlavorConfig.initialize(AppFlavor.admin);
    final config = FlavorConfig.instance;
    
    expect(config.isFeatureEnabled('canCreateExpenses'), isTrue);
  });
}
```

## Troubleshooting

### Issue: Wrong flavor running
**Solution**: Make sure you're using the correct target file:
```bash
flutter run --flavor admin -t lib/main_admin.dart
```

### Issue: Features not showing
**Solution**: Check feature flags:
```dart
print('Can create expenses: ${FlavorConfig.instance.isFeatureEnabled("canCreateExpenses")}');
```

### Issue: Navigation not working
**Solution**: Verify navigation destinations:
```dart
final destinations = FlavorConfig.instance.getNavigationDestinations();
print('Available routes: ${destinations.map((d) => d.route).toList()}');
```

### Issue: Build fails with flavor
**Solution**: Clean and rebuild:
```bash
flutter clean
flutter pub get
flutter build apk --flavor admin -t lib/main_admin.dart
```

## Best Practices

1. **Always check feature flags** before showing UI elements
2. **Use flavor checks** for major UI differences
3. **Leverage navigation destinations** from config instead of hardcoding
4. **Test each flavor** independently
5. **Document flavor-specific behavior** in code comments
6. **Use const constructors** for FlavorConfig to improve performance
7. **Initialize flavor early** in main() before any other code

## Related Files

- `lib/core/config/flavor_config.dart` - Main configuration class
- `lib/main_superadmin.dart` - SuperAdmin entry point
- `lib/main_admin.dart` - Admin entry point
- `lib/main_user.dart` - User entry point
- `android/app/build.gradle.kts` - Android flavor configuration
- `ios/Flutter/*.xcconfig` - iOS flavor configuration
- `test/core/config/flavor_config_test.dart` - Unit tests

## Support

For issues or questions about flavor configuration:
1. Check this quick reference guide
2. Review the completion summary: `TASK_1_COMPLETION_SUMMARY.md`
3. Check unit tests for usage examples
4. Review iOS setup instructions: `ios/FLAVOR_SETUP_INSTRUCTIONS.md`

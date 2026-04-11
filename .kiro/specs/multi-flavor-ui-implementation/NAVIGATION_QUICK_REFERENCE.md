# Flavor-Specific Navigation - Quick Reference Guide

## Overview
This guide provides quick reference information for working with the flavor-specific navigation system.

## Navigation Structure by Flavor

### SuperAdmin Navigation
```
┌─────────────────────────────────────┐
│  الإدارة المالية (سوبر)    [👤]   │  ← AppBar with Profile
├─────────────────────────────────────┤
│                                     │
│         Page Content                │
│                                     │
├─────────────────────────────────────┤
│  👥    💰    ⇄    📊               │  ← Bottom Navigation
│ Group  Cash  Trans Analytics        │
└─────────────────────────────────────┘
```

**Routes:**
- `/group-management` - Manage admin groups
- `/cash` - SuperAdmin cash page (fund box + transfers)
- `/transfers` - Transfer funds to admins
- `/analytics` - Global analytics dashboard
- `/profile` - User profile (via AppBar button)

### Admin Navigation
```
┌─────────────────────────────────────┐
│  الإدارة المالية (أدمن)    [👤]   │  ← AppBar with Profile
├─────────────────────────────────────┤
│                                     │
│         Page Content                │
│                                     │
├─────────────────────────────────────┤
│  👥   💰   💱   🧾   📤            │  ← Bottom Navigation
│ Group Cash Exch Exp Export          │
└─────────────────────────────────────┘
```

**Routes:**
- `/group-management` - Manage user groups
- `/cash` - Admin cash page
- `/exchange` - Currency exchange
- `/expenses` - Expense management
- `/export` - Export data
- `/profile` - User profile (via AppBar button)

### User Navigation
```
┌─────────────────────────────────────┐
│     الإدارة المالية        [👤]   │  ← AppBar with Profile
├─────────────────────────────────────┤
│                                     │
│         Page Content                │
│                                     │
├─────────────────────────────────────┤
│    🏠    💱    🧾    📤            │  ← Bottom Navigation
│   Home  Exch  Exp  Export           │
└─────────────────────────────────────┘
```

**Routes:**
- `/home` - User home (fund box + incoming transfers)
- `/exchange` - Currency exchange
- `/expenses` - Personal expenses
- `/export` - Export personal data
- `/profile` - User profile (via AppBar button)

## Key Components

### 1. AppNavigationBar
**Location:** `lib/core/widgets/app_navigation_bar.dart`

**Usage:**
```dart
AppNavigationBar(
  selectedIndex: _currentIndex,
  onDestinationSelected: (index) {
    setState(() => _currentIndex = index);
  },
)
```

**Features:**
- Automatically adapts to current flavor
- Reads destinations from `FlavorConfig`
- Supports localization
- Provides helper extensions

### 2. AppRouter
**Location:** `lib/core/routing/app_router.dart`

**Usage:**
```dart
MaterialApp(
  onGenerateRoute: AppRouter.generateRoute,
  initialRoute: AppRouter.initialRoute,
)
```

**Features:**
- Centralized route generation
- Route guards based on flavor
- Unauthorized access handling
- 404 error pages

### 3. HomeScaffold
**Location:** `lib/core/routing/home_scaffold.dart`

**Features:**
- Main app scaffold with navigation
- Flavor-specific page building
- State management integration
- Page caching for performance

## Route Access Matrix

| Route                | SuperAdmin | Admin | User |
|---------------------|------------|-------|------|
| `/`                 | ✅         | ✅    | ✅   |
| `/home`             | ✅         | ✅    | ✅   |
| `/profile`          | ✅         | ✅    | ✅   |
| `/group-management` | ✅         | ✅    | ❌   |
| `/group-info`       | ✅         | ✅    | ❌   |
| `/join-group`       | ✅         | ✅    | ❌   |
| `/cash`             | ✅         | ✅    | ✅   |
| `/exchange`         | ❌         | ✅    | ✅   |
| `/exchange-history` | ❌         | ✅    | ✅   |
| `/expenses`         | ✅         | ✅    | ✅   |
| `/export`           | ❌         | ✅    | ✅   |
| `/transfers`        | ✅         | ❌    | ❌   |
| `/analytics`        | ✅         | ❌    | ❌   |

**Legend:**
- ✅ = Allowed
- ❌ = Blocked (returns unauthorized page)

## Common Tasks

### Add a New Navigation Destination

1. **Update FlavorConfig** (`lib/core/config/flavor_config.dart`):
```dart
navigationDestinations: [
  // ... existing destinations
  FlavorNavigationDestination(
    icon: Icons.new_icon_outlined,
    selectedIcon: Icons.new_icon,
    labelKey: 'new_feature',
    route: '/new-feature',
  ),
],
```

2. **Add Route to AppRouter** (`lib/core/routing/app_router.dart`):
```dart
case '/new-feature':
  return MaterialPageRoute(
    builder: (_) => BlocProvider(
      create: (_) => di.sl<NewFeatureBloc>(),
      child: const NewFeaturePage(),
    ),
  );
```

3. **Add Route Guard** (if needed):
```dart
case '/new-feature':
  return config.isFeatureEnabled('canAccessNewFeature');
```

4. **Add Localization** (`lib/l10n/app_en.arb` and `app_ar.arb`):
```json
"new_feature": "New Feature",
```

### Navigate to a Route

**Simple Navigation:**
```dart
Navigator.pushNamed(context, '/exchange');
```

**With Arguments:**
```dart
Navigator.pushNamed(
  context,
  '/expenses',
  arguments: {'filter': 'monthly'},
);
```

**Check Route Access Before Navigation:**
```dart
final config = FlavorConfig.instance;
if (config.enableCurrencyModule) {
  Navigator.pushNamed(context, '/exchange');
} else {
  // Show error or alternative
}
```

### Get Navigation Information

**Get Route for Index:**
```dart
final route = FlavorConfig.instance.getRouteForIndex(2);
// Returns: '/exchange' for Admin flavor
```

**Get Index for Route:**
```dart
final index = FlavorConfig.instance.getIndexForRoute('/expenses');
// Returns: 3 for Admin flavor
```

**Get Navigation Count:**
```dart
final count = FlavorConfig.instance.navigationDestinationCount;
// Returns: 5 for Admin flavor (excluding profile)
```

**Get Default Home Route:**
```dart
final home = FlavorConfig.instance.defaultHomeRoute;
// Returns: '/group-management' for SuperAdmin
// Returns: '/group-management' for Admin
// Returns: '/home' for User
```

## Feature Flags

Check feature availability before showing UI elements:

```dart
final config = FlavorConfig.instance;

// Check if user can create expenses
if (config.isFeatureEnabled('canCreateExpenses')) {
  // Show create expense button
}

// Check if user can exchange currency
if (config.isFeatureEnabled('canExchangeCurrency')) {
  // Show exchange page
}

// Check if user can export data
if (config.isFeatureEnabled('canExportData')) {
  // Show export button
}

// Check if user can manage groups
if (config.isFeatureEnabled('canManageGroup')) {
  // Show group management features
}

// Check if user can view analytics
if (config.isFeatureEnabled('canViewAnalytics')) {
  // Show analytics dashboard
}
```

## Error Handling

### Unauthorized Access
When a user tries to access a route not allowed for their flavor:

```
┌─────────────────────────────────────┐
│  Unauthorized                  [←]  │
├─────────────────────────────────────┤
│                                     │
│            🚫                       │
│                                     │
│        Access Denied                │
│                                     │
│  This feature is not available      │
│  in your app version.               │
│                                     │
│  Route: /analytics                  │
│                                     │
│        [  Go Back  ]                │
│                                     │
└─────────────────────────────────────┘
```

### 404 Not Found
When a user tries to access a non-existent route:

```
┌─────────────────────────────────────┐
│  Not Found                     [←]  │
├─────────────────────────────────────┤
│                                     │
│            ⚠️                       │
│                                     │
│      404 - Page Not Found           │
│                                     │
│  The requested page does not exist. │
│                                     │
│  Route: /invalid-route              │
│                                     │
│        [  Go Home  ]                │
│                                     │
└─────────────────────────────────────┘
```

## Debugging Tips

### Enable Route Logging
Add logging to track navigation:

```dart
// In AppRouter.generateRoute
print('🔵 [AppRouter] Generating route: ${settings.name}');
print('🔵 [AppRouter] Flavor: ${config.flavor}');
print('🔵 [AppRouter] Route allowed: ${_isRouteAllowed(settings.name ?? '', config)}');
```

### Check Current Flavor
```dart
final config = FlavorConfig.instance;
print('Current flavor: ${config.flavor}');
print('App name: ${config.appName}');
print('Navigation destinations: ${config.navigationDestinationCount}');
```

### Verify Navigation State
```dart
// In HomeScaffold
print('🔵 [HomeScaffold] Selected index: $_selectedIndex');
print('🔵 [HomeScaffold] Total pages: ${pages.length}');
print('🔵 [HomeScaffold] Current route: ${config.getRouteForIndex(_selectedIndex)}');
```

## Best Practices

1. **Always use route names** instead of direct widget navigation
2. **Check feature flags** before showing UI elements
3. **Use AppRouter.generateRoute** for all navigation
4. **Cache pages** in HomeScaffold to preserve state
5. **Provide clear error messages** for unauthorized access
6. **Test navigation** for all three flavors
7. **Keep navigation destinations** in sync with FlavorConfig
8. **Use localization** for all navigation labels

## Common Issues

### Issue: Navigation destination not showing
**Solution:** Check if the feature flag is enabled in FlavorConfig

### Issue: Route returns unauthorized
**Solution:** Verify route guard logic in AppRouter._isRouteAllowed

### Issue: Wrong page displayed
**Solution:** Check route mapping in AppRouter.generateRoute

### Issue: Navigation index out of bounds
**Solution:** Ensure _selectedIndex is validated against pages.length

### Issue: Localization not working
**Solution:** Verify label key exists in app_en.arb and app_ar.arb

## Related Files

- `lib/core/config/flavor_config.dart` - Flavor configuration
- `lib/core/routing/app_router.dart` - Route generation and guards
- `lib/core/routing/home_scaffold.dart` - Main app scaffold
- `lib/core/widgets/app_navigation_bar.dart` - Navigation bar widget
- `lib/main.dart` - App entry point
- `lib/main_superadmin.dart` - SuperAdmin entry point
- `lib/main_admin.dart` - Admin entry point
- `lib/main_user.dart` - User entry point

## Support

For questions or issues with the navigation system:
1. Check this quick reference guide
2. Review the implementation summary (TASK_5_NAVIGATION_SUMMARY.md)
3. Check the design document (design.md)
4. Review the requirements document (requirements.md)

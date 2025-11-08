# Admin Dashboard Removal from Admin Flavor

## Changes Made

Removed the Admin Dashboard page from the admin flavor navigation to simplify the admin interface.

### Files Modified

#### `lib/main.dart`

**Removed Imports:**
```dart
// Commented out - no longer needed
// import 'features/admin/presentation/bloc/admin_bloc.dart';
// import 'features/admin/presentation/pages/admin_dashboard_page.dart';
```

**Removed from Pages List:**
```dart
// Admin dashboard removed - not needed in admin flavor
// if (isAdmin) {
//   pages.add(BlocProvider(
//     create: (context) => di.sl<AdminBloc>(),
//     child: const AdminDashboardPage(),
//   ));
// }
```

**Removed from Navigation Destinations:**
```dart
// Admin dashboard removed - not needed in admin flavor
// if (isAdmin) {
//   destinations.add(NavigationDestination(
//     icon: const Icon(Icons.dashboard_outlined),
//     selectedIcon: const Icon(Icons.dashboard),
//     label: l10n.translate('admin_dashboard'),
//   ));
// }
```

## Impact

### What's Removed
- Admin Dashboard page from bottom navigation
- Admin Dashboard navigation destination icon
- AdminBloc initialization for the dashboard page

### What's Preserved
- Admin Dashboard page file (`lib/features/admin/presentation/pages/admin_dashboard_page.dart`) - kept for potential future use
- Admin Dashboard BLoC and related files - kept for potential future use
- Admin Dashboard API endpoints and data sources - kept for potential future use
- All other admin features (Group Management, etc.)

### Admin Flavor Navigation After Changes
1. **Group Management** - Manage admin groups and members
2. **Cash Inbox** - View cash transactions
3. **Currency Tool** - Currency conversion
4. **Expenses** - Manage expenses
5. **Export** - Export data

## Rationale

The Admin Dashboard was removed because:
1. The admin flavor already has dedicated pages for each feature
2. Group Management provides the primary admin functionality needed
3. Simplifies the navigation and reduces complexity
4. Statistics and analytics can be accessed through other means if needed

## Restoration

If you need to restore the Admin Dashboard in the future:

1. Uncomment the imports in `lib/main.dart`:
```dart
import 'features/admin/presentation/bloc/admin_bloc.dart';
import 'features/admin/presentation/pages/admin_dashboard_page.dart';
```

2. Uncomment the page addition in `_buildPages()`:
```dart
if (isAdmin) {
  pages.add(BlocProvider(
    create: (context) => di.sl<AdminBloc>(),
    child: const AdminDashboardPage(),
  ));
}
```

3. Uncomment the navigation destination in `build()`:
```dart
if (isAdmin) {
  destinations.add(NavigationDestination(
    icon: const Icon(Icons.dashboard_outlined),
    selectedIcon: const Icon(Icons.dashboard),
    label: l10n.translate('admin_dashboard'),
  ));
}
```

## Testing

After this change, test the admin flavor to ensure:
1. App launches without errors
2. Navigation works correctly with remaining pages
3. Group Management is the first page for admin users
4. All other features are accessible
5. No broken references or imports

## Notes

- The code is commented out rather than deleted to make restoration easier if needed
- All backend API endpoints and data models remain intact
- The AdminBloc is still registered in the dependency injection container
- This change only affects the UI navigation, not the underlying functionality

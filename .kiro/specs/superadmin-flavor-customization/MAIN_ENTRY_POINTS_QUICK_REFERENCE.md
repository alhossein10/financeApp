# Main Entry Points Quick Reference

## Overview
This document provides a quick reference for the main entry points of the Finance application across all three flavors: SuperAdmin, Admin, and User.

## Entry Point Files

### SuperAdmin Flavor
**File:** `lib/main_superadmin.dart`

**Usage:**
```bash
flutter run -t lib/main_superadmin.dart
flutter build apk -t lib/main_superadmin.dart
```

**Configuration:**
- Flavor: `AppFlavor.superAdmin`
- App Name: "Finance SuperAdmin"
- Application ID: `com.app.finance.superadmin`
- SuperAdmin Cash Page: ✅ Enabled
- SuperAdmin Expenses Page: ✅ Enabled
- Currency Module (Exchange): ❌ Disabled
- Export Module: ❌ Disabled
- Incoming Transfers: ❌ Hidden
- Exchange History: ❌ Hidden

### Admin Flavor
**File:** `lib/main_admin.dart`

**Usage:**
```bash
flutter run -t lib/main_admin.dart
flutter build apk -t lib/main_admin.dart
```

**Configuration:**
- Flavor: `AppFlavor.admin`
- App Name: "Finance Admin"
- Application ID: `com.app.finance.admin`
- Cash Module: ✅ Enabled
- Currency Module (Exchange): ✅ Enabled
- Export Module: ✅ Enabled
- Admin Dashboard: ✅ Enabled
- Incoming Transfers: ✅ Visible
- Exchange History: ✅ Visible

### User Flavor
**File:** `lib/main_user.dart`

**Usage:**
```bash
flutter run -t lib/main_user.dart
flutter build apk -t lib/main_user.dart
```

**Configuration:**
- Flavor: `AppFlavor.user`
- App Name: "Finance"
- Application ID: `com.app.finance.user`
- Cash Module: ❌ Disabled
- Currency Module (Exchange): ✅ Enabled
- Export Module: ✅ Enabled
- Admin Features: ❌ Disabled
- Incoming Transfers: ✅ Visible
- Exchange History: ✅ Visible

## Common Initialization Flow

All entry points follow the same initialization pattern:

```dart
void main() async {
  // 1. Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialize flavor configuration
  FlavorConfig.initialize(AppFlavor.xxx);
  
  // 3. Log flavor configuration (for debugging)
  print('🔵 [MAIN_XXX] App starting with XXX flavor');
  print('🔵 [MAIN_XXX] App name: ${FlavorConfig.instance.appName}');
  // ... more logging
  
  // 4. Initialize dependency injection
  await di.initializeDependencies();
  
  // 5. Restore authentication token
  await di.restoreAuthToken();
  
  // 6. Run the app
  runApp(const app.MyApp());
}
```

## Key Services Initialized

### All Flavors
- ✅ `ApiClient` - Laravel API client
- ✅ `TokenManager` - Authentication token management
- ✅ `LaravelAuthService` - Authentication service
- ✅ `CacheService` - Local caching
- ✅ `QueueManager` - Offline queue management
- ✅ `ConnectivityMonitor` - Network connectivity monitoring
- ✅ `ConnectivityService` - Connectivity service
- ✅ `RoleService` - Role-based access control
- ✅ `AuthBloc` - Authentication state management
- ✅ `ProfileBloc` - Profile management

### SuperAdmin & Admin Only
- ✅ `FundBoxBloc` - Fund box management
- ✅ `TransferBloc` - Transfer management
- ✅ `AdminGroupBloc` - Admin group management
- ✅ `AuditLogBloc` - Audit log viewing

### Admin & User Only
- ✅ `ExchangeBloc` - Currency exchange management

### SuperAdmin Only
- ✅ `SuperAdminExpenseApiDataSource` - Used directly in widgets (not registered as singleton)

## Deprecated Services

### Supabase Service
**Status:** ❌ REMOVED

The `SupabaseService` has been removed from all entry points as the app now uses Laravel backend exclusively. All authentication and data operations go through the Laravel API.

**Old Code (Removed):**
```dart
import 'core/services/supabase_service.dart';
await SupabaseService().initialize();
```

**New Code:**
```dart
// No Supabase initialization needed
// All operations use Laravel API through ApiClient
```

## Debugging Tips

### Check Current Flavor
Look for these log messages when the app starts:
```
🔵 [MAIN_SUPERADMIN] App starting with SuperAdmin flavor
🔵 [MAIN_SUPERADMIN] App name: Finance SuperAdmin
🔵 [MAIN_SUPERADMIN] SuperAdmin Cash Page enabled: true
🔵 [MAIN_SUPERADMIN] SuperAdmin Expenses Page enabled: true
🔵 [MAIN_SUPERADMIN] Currency Module enabled: false
🔵 [MAIN_SUPERADMIN] Export Module enabled: false
```

### Check Token Restoration
Look for these log messages:
```
🔵 [DI] Restoring authentication token...
✅ [DI] Token restored successfully
🔑 [DI] Token expires at: 2024-12-31T23:59:59.000Z
⚠️ [DI] Token expired: false
⚠️ [DI] Token needs refresh: false
```

### Common Issues

#### Wrong Flavor Running
**Symptom:** App shows features that shouldn't be available
**Solution:** Check the `-t` parameter when running/building the app

#### Token Not Restored
**Symptom:** User is logged out after app restart
**Solution:** Check secure storage permissions and token expiration

#### Missing Dependencies
**Symptom:** Null pointer exceptions or missing service errors
**Solution:** Verify `initializeDependencies()` completes successfully

## Build Commands

### Development Builds
```bash
# SuperAdmin
flutter run -t lib/main_superadmin.dart

# Admin
flutter run -t lib/main_admin.dart

# User
flutter run -t lib/main_user.dart
```

### Production Builds
```bash
# SuperAdmin APK
flutter build apk -t lib/main_superadmin.dart --release

# Admin APK
flutter build apk -t lib/main_admin.dart --release

# User APK
flutter build apk -t lib/main_user.dart --release
```

### Build with Backend Configuration
```bash
# Use production API
flutter build apk -t lib/main_admin.dart --release --dart-define=API_BASE_URL=https://api.production.com

# Use staging API
flutter build apk -t lib/main_admin.dart --release --dart-define=API_BASE_URL=https://api.staging.com
```

## Related Files
- `lib/core/config/flavor_config.dart` - Flavor configuration
- `lib/injection_container.dart` - Dependency injection setup
- `lib/main.dart` - Main app widget (shared across flavors)
- `lib/core/services/laravel_auth_service.dart` - Authentication service
- `lib/core/api/api_client.dart` - API client

## Summary

All three main entry points are now:
- ✅ Properly configured for their respective flavors
- ✅ Free of deprecated Supabase dependencies
- ✅ Using shared token restoration logic
- ✅ Providing comprehensive logging for debugging
- ✅ Initializing all required services correctly

The SuperAdmin flavor is fully configured and ready for use with its specialized Cash and Expenses pages.

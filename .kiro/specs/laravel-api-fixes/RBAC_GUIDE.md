# Role-Based Access Control (RBAC) Guide

## Overview

This guide documents the role-based access control system implemented for the Laravel API integration. The system ensures that users and admins have appropriate permissions and that admin-only features are properly protected.

## User Roles

### User Role

**Role Value**: `user`

**Permissions**:
- Create, read, update, delete own expenses
- Create, read, update, delete own income
- Create, read, update, delete own transfers
- View own profile
- Update own profile
- Change own password
- Export own data
- Upload and manage own files

**Restrictions**:
- Cannot access fund box
- Cannot access admin dashboard
- Cannot view audit logs
- Cannot manage other users

### Admin Role

**Role Value**: `admin`

**Permissions**:
- All user permissions
- Access fund box
- View and update fund box balance
- Access admin dashboard
- View system statistics
- View user activity
- View expense summaries
- View analytics
- View audit logs
- View audit log details

## Role Detection

### Getting User Role

```dart
// From authentication response
final user = await authService.login(email, password);
final role = user.role; // 'user' or 'admin'

// From stored profile
final profile = await profileApiDataSource.getProfile();
final role = profile.role;

// Using RoleService
final isAdmin = await roleService.isAdmin();
final isUser = await roleService.isUser();
```

### RoleService

```dart
class RoleService {
  final TokenManager _tokenManager;
  
  Future<bool> isAdmin() async {
    final user = await _tokenManager.getCurrentUser();
    return user?.role == 'admin';
  }
  
  Future<bool> isUser() async {
    final user = await _tokenManager.getCurrentUser();
    return user?.role == 'user';
  }
  
  Future<String?> getRole() async {
    final user = await _tokenManager.getCurrentUser();
    return user?.role;
  }
  
  Future<bool> hasPermission(String permission) async {
    final role = await getRole();
    return _permissions[role]?.contains(permission) ?? false;
  }
}
```

## Flavor Configuration

### User Flavor

**Target Audience**: Regular users

**Configuration**:
```dart
FlavorConfig(
  flavor: Flavor.user,
  name: 'Finance App',
  apiBaseUrl: 'http://localhost:8000/api/v1',
  enableAdminFeatures: false,
);
```

**Features**:
- Expense management
- Income management
- Transfer management
- Profile management
- Data export
- File upload

### Admin Flavor

**Target Audience**: Administrators

**Configuration**:
```dart
FlavorConfig(
  flavor: Flavor.admin,
  name: 'Finance App Admin',
  apiBaseUrl: 'http://localhost:8000/api/v1',
  enableAdminFeatures: true,
);
```

**Additional Features**:
- Fund box management
- Admin dashboard
- User activity monitoring
- System analytics
- Audit logs

## UI Access Control

### RoleBasedWidget

Use `RoleBasedWidget` to conditionally render UI based on role:

```dart
RoleBasedWidget(
  adminWidget: AdminDashboardPage(),
  userWidget: UserDashboardPage(),
  loadingWidget: CircularProgressIndicator(),
)
```

**Implementation**:
```dart
class RoleBasedWidget extends StatelessWidget {
  final Widget adminWidget;
  final Widget userWidget;
  final Widget? loadingWidget;
  final RoleService roleService;
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: roleService.isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? CircularProgressIndicator();
        }
        
        final isAdmin = snapshot.data ?? false;
        return isAdmin ? adminWidget : userWidget;
      },
    );
  }
}
```

### Conditional Navigation

```dart
// Show admin menu items only for admins
if (await roleService.isAdmin()) {
  menuItems.add(
    ListTile(
      title: Text('Admin Dashboard'),
      onTap: () => Navigator.pushNamed(context, '/admin/dashboard'),
    ),
  );
  
  menuItems.add(
    ListTile(
      title: Text('Fund Box'),
      onTap: () => Navigator.pushNamed(context, '/fund-box'),
    ),
  );
  
  menuItems.add(
    ListTile(
      title: Text('Audit Logs'),
      onTap: () => Navigator.pushNamed(context, '/admin/audit-logs'),
    ),
  );
}
```

### Conditional Feature Display

```dart
// In dashboard
Widget build(BuildContext context) {
  return FutureBuilder<bool>(
    future: roleService.isAdmin(),
    builder: (context, snapshot) {
      final isAdmin = snapshot.data ?? false;
      
      return Column(
        children: [
          // User features
          ExpenseCard(),
          IncomeCard(),
          TransferCard(),
          
          // Admin-only features
          if (isAdmin) ...[
            FundBoxCard(),
            AdminStatsCard(),
            AuditLogsCard(),
          ],
        ],
      );
    },
  );
}
```

## API Access Control

### Client-Side Validation

Always validate role before making admin API calls:

```dart
// Before accessing fund box
if (!await roleService.isAdmin()) {
  showError('Access denied. Admin privileges required.');
  return;
}

try {
  final fundBox = await fundBoxApiDataSource.getFundBox();
} on ApiException catch (e) {
  if (e.isForbidden) {
    showError('Access denied. Admin privileges required.');
  }
}
```

### Server-Side Enforcement

The server always enforces role-based access. Client-side checks are for UX only:

```dart
// Client checks role (for UX)
if (!await roleService.isAdmin()) {
  showError('Access denied');
  return;
}

// Server validates role (for security)
// If user somehow bypasses client check, server returns 403
try {
  await adminApiDataSource.getDashboardStats();
} on ApiException catch (e) {
  if (e.isForbidden) {
    // Server rejected the request
    showError('Access denied. Admin privileges required.');
  }
}
```

## Admin-Only Endpoints

### Fund Box

```dart
// GET /fund-box
// PUT /fund-box
if (!await roleService.isAdmin()) {
  throw AuthorizationException('Admin privileges required');
}

final fundBox = await fundBoxApiDataSource.getFundBox();
```

### Admin Dashboard

```dart
// GET /admin/dashboard/stats
// GET /admin/dashboard/users
// GET /admin/dashboard/expenses
// GET /admin/dashboard/analytics
if (!await roleService.isAdmin()) {
  throw AuthorizationException('Admin privileges required');
}

final stats = await adminApiDataSource.getDashboardStats();
```

### Audit Logs

```dart
// GET /audit-logs
// GET /audit-logs/{id}
if (!await roleService.isAdmin()) {
  throw AuthorizationException('Admin privileges required');
}

final logs = await auditLogApiDataSource.getAuditLogs();
```

## Error Handling

### 403 Forbidden Response

When a non-admin user attempts to access admin endpoints:

```dart
try {
  await fundBoxApiDataSource.getFundBox();
} on ApiException catch (e) {
  if (e.isForbidden) {
    // Hide admin features
    setState(() {
      showAdminFeatures = false;
    });
    
    // Show error message
    showError('Access denied. Admin privileges required.');
    
    // Optionally redirect
    Navigator.pop(context);
  }
}
```

### Graceful Degradation

```dart
// Try to load admin features, fall back to user features
try {
  if (await roleService.isAdmin()) {
    final stats = await adminApiDataSource.getDashboardStats();
    setState(() {
      adminStats = stats;
      showAdminDashboard = true;
    });
  }
} on ApiException catch (e) {
  if (e.isForbidden) {
    // Silently fall back to user dashboard
    setState(() {
      showAdminDashboard = false;
    });
  }
}
```

## BLoC Integration

### Role-Aware BLoC

```dart
class FundBoxBloc extends Bloc<FundBoxEvent, FundBoxState> {
  final FundBoxApiDataSource _apiDataSource;
  final RoleService _roleService;
  
  Future<void> _onGetFundBox(
    GetFundBoxEvent event,
    Emitter<FundBoxState> emit,
  ) async {
    // Check role first
    if (!await _roleService.isAdmin()) {
      emit(FundBoxError('Access denied. Admin privileges required.'));
      return;
    }
    
    emit(FundBoxLoading());
    
    try {
      final fundBox = await _apiDataSource.getFundBox();
      emit(FundBoxLoaded(fundBox));
    } on ApiException catch (e) {
      if (e.isForbidden) {
        emit(FundBoxError('Access denied. Admin privileges required.'));
      } else {
        emit(FundBoxError(e.userFriendlyMessage));
      }
    }
  }
}
```

## Testing RBAC

### Unit Tests

```dart
group('RoleService', () {
  test('should return true for admin user', () async {
    // Arrange
    when(mockTokenManager.getCurrentUser())
      .thenAnswer((_) async => User(role: 'admin'));
    
    // Act
    final isAdmin = await roleService.isAdmin();
    
    // Assert
    expect(isAdmin, true);
  });
  
  test('should return false for regular user', () async {
    // Arrange
    when(mockTokenManager.getCurrentUser())
      .thenAnswer((_) async => User(role: 'user'));
    
    // Act
    final isAdmin = await roleService.isAdmin();
    
    // Assert
    expect(isAdmin, false);
  });
});
```

### Integration Tests

```dart
group('Fund Box Access Control', () {
  test('admin user should access fund box', () async {
    // Login as admin
    await authService.login('admin@example.com', 'password');
    
    // Should succeed
    final fundBox = await fundBoxApiDataSource.getFundBox();
    expect(fundBox, isNotNull);
  });
  
  test('regular user should not access fund box', () async {
    // Login as user
    await authService.login('user@example.com', 'password');
    
    // Should throw 403
    expect(
      () => fundBoxApiDataSource.getFundBox(),
      throwsA(isA<ApiException>().having(
        (e) => e.statusCode,
        'statusCode',
        403,
      )),
    );
  });
});
```

### Widget Tests

```dart
testWidgets('should show admin features for admin', (tester) async {
  // Arrange
  when(mockRoleService.isAdmin()).thenAnswer((_) async => true);
  
  // Act
  await tester.pumpWidget(DashboardPage());
  await tester.pumpAndSettle();
  
  // Assert
  expect(find.text('Fund Box'), findsOneWidget);
  expect(find.text('Admin Dashboard'), findsOneWidget);
});

testWidgets('should hide admin features for user', (tester) async {
  // Arrange
  when(mockRoleService.isAdmin()).thenAnswer((_) async => false);
  
  // Act
  await tester.pumpWidget(DashboardPage());
  await tester.pumpAndSettle();
  
  // Assert
  expect(find.text('Fund Box'), findsNothing);
  expect(find.text('Admin Dashboard'), findsNothing);
});
```

## Best Practices

### 1. Always Check Role Before Admin Operations

```dart
// Good
if (await roleService.isAdmin()) {
  await fundBoxApiDataSource.getFundBox();
}

// Bad - no role check
await fundBoxApiDataSource.getFundBox();
```

### 2. Handle 403 Errors Gracefully

```dart
// Good
try {
  await adminApiDataSource.getDashboardStats();
} on ApiException catch (e) {
  if (e.isForbidden) {
    showError('Access denied. Admin privileges required.');
    Navigator.pop(context);
  }
}

// Bad - no error handling
await adminApiDataSource.getDashboardStats();
```

### 3. Use RoleBasedWidget for Conditional UI

```dart
// Good
RoleBasedWidget(
  adminWidget: AdminDashboard(),
  userWidget: UserDashboard(),
)

// Bad - manual role checking in build
FutureBuilder<bool>(
  future: roleService.isAdmin(),
  builder: (context, snapshot) {
    if (snapshot.data == true) {
      return AdminDashboard();
    }
    return UserDashboard();
  },
)
```

### 4. Cache Role Information

```dart
// Cache role to avoid repeated API calls
class RoleService {
  String? _cachedRole;
  
  Future<String?> getRole() async {
    if (_cachedRole != null) {
      return _cachedRole;
    }
    
    final user = await _tokenManager.getCurrentUser();
    _cachedRole = user?.role;
    return _cachedRole;
  }
  
  void clearCache() {
    _cachedRole = null;
  }
}
```

### 5. Clear Role Cache on Logout

```dart
await authService.logout();
roleService.clearCache();
```

## Security Considerations

### Client-Side Checks Are Not Security

Client-side role checks are for UX only. Always rely on server-side enforcement:

```dart
// Client check (UX)
if (!await roleService.isAdmin()) {
  showError('Access denied');
  return; // Prevent unnecessary API call
}

// Server check (Security)
// Server will validate role and return 403 if unauthorized
await adminApiDataSource.getDashboardStats();
```

### Never Trust Client Role

The server must always validate the user's role from the authenticated token:

```php
// Laravel middleware
public function handle($request, Closure $next)
{
    if ($request->user()->role !== 'admin') {
        return response()->json(['message' => 'Forbidden'], 403);
    }
    
    return $next($request);
}
```

### Audit Admin Actions

All admin actions should be logged in audit logs:

```dart
// After successful admin action
await auditLogService.log(
  action: 'fund_box.updated',
  entityType: 'FundBox',
  entityId: fundBox.id,
  changes: {'total_balance': newBalance},
);
```

## Summary

- Two roles: `user` and `admin`
- Admin has all user permissions plus admin-only features
- Use `RoleService` to check user role
- Use `RoleBasedWidget` for conditional UI
- Always validate role before admin API calls
- Handle 403 errors gracefully
- Client-side checks are for UX, server-side checks are for security
- Cache role information to avoid repeated checks
- Clear role cache on logout
- Test RBAC thoroughly with both roles

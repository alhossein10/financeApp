# Admin Group Management - Migration Guide

## Table of Contents

1. [Overview](#overview)
2. [What's Changing](#whats-changing)
3. [Backward Compatibility](#backward-compatibility)
4. [Migration Steps](#migration-steps)
5. [Code Changes](#code-changes)
6. [Testing](#testing)
7. [Troubleshooting](#troubleshooting)
8. [Rollback Plan](#rollback-plan)

---

## Overview

This guide helps you migrate from the old organization/department dropdown system to the new admin group management system using 6-character group codes.

### Migration Timeline

- **Preparation**: 1 week
- **Implementation**: 2-3 weeks
- **Testing**: 1 week
- **Deployment**: 1 day
- **Monitoring**: 1 week

### Key Changes

| Old System | New System |
|------------|------------|
| Organization dropdown (ID-based) | Organization name (free text) |
| Department dropdown (ID-based) | Department name (free text) |
| No group concept | Admin groups with codes |
| Manual data filtering | Automatic data scoping |

---

## What's Changing

### 1. Registration Flow

**OLD:**
```dart
// Users selected from dropdowns
RegisterRequest(
  name: 'John Doe',
  email: 'john@example.com',
  password: 'password',
  role: 'user',
  organizationId: 1,      // Dropdown selection
  departmentId: 2,        // Dropdown selection
)
```

**NEW:**
```dart
// Admins get auto-generated code, users enter code
RegisterRequest(
  name: 'John Doe',
  email: 'john@example.com',
  password: 'password',
  role: 'user',
  groupCode: 'ABC123',              // NEW: Required for users
  organizationName: 'Acme Corp',    // NEW: Optional text
  departmentName: 'Marketing',      // NEW: Optional text
)
```

### 2. User Model

**OLD:**
```dart
class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final int? organizationId;
  final int? departmentId;
}
```

**NEW:**
```dart
class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? organizationName;    // NEW
  final String? departmentName;      // NEW
  final int? adminGroupId;           // NEW
  final int? organizationId;         // DEPRECATED but kept
  final int? departmentId;           // DEPRECATED but kept
}
```

### 3. Data Queries

**OLD:**
```dart
// No automatic filtering
final expenses = await repository.getExpenses();
// Returns all expenses (or manual filtering)
```

**NEW:**
```dart
// Automatic filtering by admin_group_id
final expenses = await repository.getExpenses();
// Returns only expenses from users in the same admin group
```

### 4. New Features

- Admin group management page
- Group member list with search/filter
- Group code regeneration
- User group info page
- Join group functionality

---

## Backward Compatibility

### Maintained Compatibility

✅ **Old fields still work:**
- `organization_id` and `department_id` are still accepted
- Existing users continue to function
- No data loss during migration

✅ **Gradual transition:**
- Old and new systems coexist
- Users can migrate at their own pace
- No forced immediate migration

✅ **API compatibility:**
- Old API format still accepted
- New format takes precedence
- Responses include both old and new fields

### Breaking Changes

⚠️ **Registration UI:**
- Dropdowns removed from registration page
- Group code input required for new users
- Organization/department now text fields

⚠️ **Data scoping:**
- Users without `admin_group_id` see no data
- Must join a group to access features
- Complete isolation between groups

⚠️ **Admin features:**
- New group management page (admin only)
- New permissions and role checks
- New navigation menu items

---

## Migration Steps

### Phase 1: Preparation (Week 1)

#### 1.1 Review Documentation

- [ ] Read requirements document
- [ ] Read design document
- [ ] Review API documentation
- [ ] Test backend endpoints with Postman

#### 1.2 Backup Data

```bash
# Backup database
pg_dump financeapp > backup_$(date +%Y%m%d).sql

# Backup user data
SELECT * FROM users INTO OUTFILE '/backup/users.csv';
```

#### 1.3 Update Dependencies

```bash
# Update Flutter dependencies
flutter pub get
flutter pub upgrade

# Verify versions
flutter doctor -v
```

#### 1.4 Configure Environment

```dart
// lib/core/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://your-backend-url/api/v1';
  static const bool enableGroupManagement = true;  // Feature flag
}
```

### Phase 2: Code Migration (Weeks 2-3)

#### 2.1 Update User Model

```dart
// lib/core/api/models/user_dto.dart

class UserDto {
  final int id;
  final String name;
  final String email;
  final String role;
  
  // NEW FIELDS
  final String? organizationName;
  final String? departmentName;
  final int? adminGroupId;
  
  // DEPRECATED (but kept for compatibility)
  final int? organizationId;
  final int? departmentId;
  
  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      // Prioritize new fields
      organizationName: json['organization_name'],
      departmentName: json['department_name'],
      adminGroupId: json['admin_group_id'],
      // Keep old fields for backward compatibility
      organizationId: json['organization_id'],
      departmentId: json['department_id'],
    );
  }
}
```

#### 2.2 Update Registration Page

```dart
// lib/features/auth/presentation/pages/register_page.dart

// REMOVE: Organization dropdown
// REMOVE: Department dropdown

// ADD: Group code input (for users)
if (selectedRole == 'user')
  GroupCodeInput(
    controller: groupCodeController,
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Group code is required';
      }
      if (value.length != 6) {
        return 'Group code must be 6 characters';
      }
      return null;
    },
  ),

// ADD: Organization text field (optional)
TextFormField(
  controller: organizationController,
  decoration: InputDecoration(
    labelText: 'Organization (optional)',
  ),
),

// ADD: Department text field (optional)
TextFormField(
  controller: departmentController,
  decoration: InputDecoration(
    labelText: 'Department (optional)',
  ),
),
```

#### 2.3 Add Admin Group Feature

```dart
// lib/features/admin_group/
// Copy all files from the implementation

// Update dependency injection
// lib/injection_container.dart
void init() {
  // Admin Group
  sl.registerFactory(() => AdminGroupBloc(
    getAdminGroup: sl(),
    regenerateGroupCode: sl(),
    getGroupMembers: sl(),
    removeGroupMember: sl(),
    joinGroup: sl(),
    getUserGroupInfo: sl(),
  ));
  
  // Use cases
  sl.registerLazySingleton(() => GetAdminGroupUseCase(sl()));
  sl.registerLazySingleton(() => RegenerateGroupCodeUseCase(sl()));
  // ... register all use cases
  
  // Repository
  sl.registerLazySingleton<AdminGroupRepository>(
    () => AdminGroupRepositoryImpl(
      apiDataSource: sl(),
      cacheDataSource: sl(),
    ),
  );
  
  // Data sources
  sl.registerLazySingleton<AdminGroupApiDataSource>(
    () => AdminGroupApiDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<AdminGroupCacheDataSource>(
    () => AdminGroupCacheDataSourceImpl(),
  );
}
```

#### 2.4 Update Data Repositories

```dart
// lib/features/expenses/data/repositories/expense_repository_impl.dart

class ExpenseRepositoryImpl implements ExpenseRepository {
  @override
  Future<Either<Failure, List<Expense>>> getExpenses() async {
    try {
      // Data is automatically filtered by admin_group_id on backend
      final expenses = await apiDataSource.getExpenses();
      return Right(expenses.map((dto) => dto.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// Same pattern for:
// - TransferRepositoryImpl
// - IncomingRepositoryImpl
// - FundBoxRepositoryImpl
```

#### 2.5 Update Navigation

```dart
// lib/main.dart or routes file

// Add new routes
'/group-management': (context) => GroupManagementPage(),
'/group-info': (context) => GroupInfoPage(),
'/join-group': (context) => JoinGroupPage(),

// Update menu based on role
Widget _buildMenu(BuildContext context, String role) {
  return Drawer(
    child: ListView(
      children: [
        // ... existing menu items
        
        if (role == 'admin')
          ListTile(
            leading: Icon(Icons.group),
            title: Text('Group Management'),
            onTap: () => Navigator.pushNamed(context, '/group-management'),
          ),
        
        if (role == 'user')
          ListTile(
            leading: Icon(Icons.info),
            title: Text('My Group'),
            onTap: () => Navigator.pushNamed(context, '/group-info'),
          ),
      ],
    ),
  );
}
```

### Phase 3: Testing (Week 4)

#### 3.1 Unit Tests

```bash
# Run all unit tests
flutter test

# Run specific test suites
flutter test test/features/admin_group/
flutter test test/core/api/models/user_dto_test.dart
```

#### 3.2 Widget Tests

```bash
# Test registration page
flutter test test/features/auth/presentation/pages/register_page_test.dart

# Test admin group pages
flutter test test/features/admin_group/presentation/pages/
```

#### 3.3 Integration Tests

```bash
# Test complete flows
flutter test test/integration/admin_group_registration_test.dart
flutter test test/integration/admin_group_management_test.dart
flutter test test/integration/admin_group_join_test.dart
flutter test test/integration/admin_group_data_scoping_test.dart
```

#### 3.4 Manual Testing

Follow the [Manual Testing Guide](./MANUAL_TESTING_GUIDE.md):

- [ ] Admin registration with group code display
- [ ] User registration with group code input
- [ ] Group management operations
- [ ] Data scoping verification
- [ ] Error handling
- [ ] Both English and Arabic
- [ ] Multiple devices and screen sizes

### Phase 4: Deployment (Week 5)

#### 4.1 Staging Deployment

```bash
# Build for staging
flutter build apk --flavor staging --release
flutter build ios --flavor staging --release

# Deploy to staging environment
# Test all features in staging
```

#### 4.2 Production Deployment

```bash
# Build for production
flutter build apk --flavor production --release
flutter build ios --flavor production --release

# Deploy to app stores
# Monitor for issues
```

---

## Code Changes

### Required Changes

#### 1. User DTO

**File:** `lib/core/api/models/user_dto.dart`

**Changes:**
- Add `organizationName`, `departmentName`, `adminGroupId` fields
- Update `fromJson` to handle both old and new fields
- Update `toEntity` to prioritize new fields

#### 2. Registration Page

**File:** `lib/features/auth/presentation/pages/register_page.dart`

**Changes:**
- Remove organization dropdown
- Remove department dropdown
- Add group code input (conditional for users)
- Add organization text field (optional)
- Add department text field (optional)
- Add admin registration success dialog

#### 3. Auth Bloc

**File:** `lib/features/auth/presentation/bloc/auth_bloc.dart`

**Changes:**
- Update `AuthRegisterRequested` event
- Remove `organizationId`, `departmentId` parameters
- Add `groupCode`, `organizationName`, `departmentName` parameters
- Handle admin group response

#### 4. Auth API DataSource

**File:** `lib/features/auth/data/datasources/auth_api_datasource.dart`

**Changes:**
- Update `register` method signature
- Send new fields in request body
- Handle admin group in response

#### 5. Repositories

**Files:**
- `lib/features/expenses/data/repositories/expense_repository_impl.dart`
- `lib/features/transfers/data/repositories/transfer_repository_impl.dart`
- `lib/features/incoming/data/repositories/incoming_repository_impl.dart`
- `lib/features/fund_box/data/repositories/fund_box_repository_impl.dart`

**Changes:**
- No code changes needed (backend handles filtering)
- Verify queries return scoped data
- Add comments about automatic filtering

#### 6. Navigation

**File:** `lib/main.dart` or routes file

**Changes:**
- Add routes for new pages
- Update menu based on user role
- Add navigation guards if needed

### Optional Changes

#### 1. Feature Flags

```dart
// lib/core/config/feature_flags.dart
class FeatureFlags {
  static const bool enableGroupManagement = true;
  static const bool showOldFields = false;  // For debugging
}
```

#### 2. Analytics

```dart
// Track group management events
Analytics.logEvent('group_code_copied');
Analytics.logEvent('member_removed');
Analytics.logEvent('group_code_regenerated');
```

#### 3. Error Tracking

```dart
// Monitor group-related errors
Sentry.captureException(
  exception,
  hint: Hint.withMap({'feature': 'admin_group'}),
);
```

---

## Testing

### Pre-Migration Testing

1. **Backup Testing**
   - Verify backups are complete
   - Test restore procedure
   - Validate data integrity

2. **Compatibility Testing**
   - Test old API format still works
   - Verify existing users can login
   - Check data access for old users

### Post-Migration Testing

1. **Functional Testing**
   - All new features work
   - Old features still work
   - No regressions

2. **Data Testing**
   - Data scoping works correctly
   - No cross-group data leaks
   - Statistics calculated correctly

3. **Performance Testing**
   - Page load times acceptable
   - API response times normal
   - No memory leaks

4. **Security Testing**
   - Group codes are secure
   - Authorization works correctly
   - Data isolation enforced

---

## Troubleshooting

### Issue 1: Existing Users Cannot Login

**Symptom:** Users registered before migration cannot login.

**Cause:** Missing `admin_group_id` field.

**Solution:**
```sql
-- Backend: Assign existing users to default groups
UPDATE users 
SET admin_group_id = (
  SELECT id FROM admin_groups 
  WHERE admin_user_id = users.id 
  LIMIT 1
)
WHERE role = 'user' AND admin_group_id IS NULL;
```

### Issue 2: Data Not Showing

**Symptom:** Users see no data after migration.

**Cause:** User not assigned to any group.

**Solution:**
1. User must join a group using group code
2. Or admin must be assigned a group
3. Check `admin_group_id` is set

### Issue 3: Group Code Not Displayed

**Symptom:** Admin registers but doesn't see group code.

**Cause:** Backend not returning admin_group in response.

**Solution:**
1. Verify backend is updated
2. Check API response includes `admin_group`
3. Verify dialog is shown in UI

### Issue 4: Old Dropdowns Still Showing

**Symptom:** Registration page still shows dropdowns.

**Cause:** Code not updated or cached.

**Solution:**
```bash
# Clear build cache
flutter clean
flutter pub get
flutter run
```

### Issue 5: Data Scoping Not Working

**Symptom:** Users see data from other groups.

**Cause:** Backend not filtering by admin_group_id.

**Solution:**
1. Verify backend is updated
2. Check query includes group filter
3. Test with Postman
4. Clear cache and retry

---

## Rollback Plan

### When to Rollback

- Critical bugs affecting all users
- Data integrity issues
- Security vulnerabilities
- Performance degradation

### Rollback Steps

#### 1. Immediate Actions

```bash
# Revert to previous app version
git checkout <previous-tag>
flutter build apk --release
# Deploy old version
```

#### 2. Database Rollback

```sql
-- No database changes needed
-- Old fields are still present
-- Users can continue with old system
```

#### 3. Feature Flag Disable

```dart
// lib/core/config/feature_flags.dart
class FeatureFlags {
  static const bool enableGroupManagement = false;  // Disable feature
}
```

#### 4. Communication

- Notify users of temporary issues
- Provide timeline for resolution
- Offer support channels

### Rollback Testing

1. **Verify Old Version Works**
   - Test login
   - Test registration
   - Test data access

2. **Data Integrity**
   - Verify no data loss
   - Check all records accessible
   - Validate relationships

3. **User Communication**
   - Send notification
   - Update status page
   - Provide support

---

## Best Practices

### During Migration

1. **Communicate Early**
   - Inform users about changes
   - Provide migration timeline
   - Offer support channels

2. **Test Thoroughly**
   - Test all scenarios
   - Include edge cases
   - Test on multiple devices

3. **Monitor Closely**
   - Watch error rates
   - Monitor performance
   - Track user feedback

4. **Have Rollback Ready**
   - Keep old version available
   - Test rollback procedure
   - Document rollback steps

### After Migration

1. **Monitor Metrics**
   - User adoption rate
   - Error rates
   - Performance metrics
   - User feedback

2. **Provide Support**
   - Answer user questions
   - Fix bugs quickly
   - Update documentation

3. **Gather Feedback**
   - User surveys
   - Support tickets
   - Analytics data

4. **Iterate**
   - Improve based on feedback
   - Fix issues
   - Add enhancements

---

## Checklist

### Pre-Migration

- [ ] Backup database
- [ ] Backup user data
- [ ] Review all documentation
- [ ] Test backend endpoints
- [ ] Update dependencies
- [ ] Configure environments
- [ ] Prepare rollback plan

### Migration

- [ ] Update user model
- [ ] Update registration page
- [ ] Add admin group feature
- [ ] Update repositories
- [ ] Update navigation
- [ ] Add localization
- [ ] Write tests
- [ ] Update documentation

### Testing

- [ ] Run unit tests
- [ ] Run widget tests
- [ ] Run integration tests
- [ ] Perform manual testing
- [ ] Test on Android
- [ ] Test on iOS
- [ ] Test both languages
- [ ] Test error scenarios

### Deployment

- [ ] Deploy to staging
- [ ] Test in staging
- [ ] Fix any issues
- [ ] Deploy to production
- [ ] Monitor for issues
- [ ] Provide user support

### Post-Migration

- [ ] Monitor metrics
- [ ] Gather feedback
- [ ] Fix bugs
- [ ] Update documentation
- [ ] Plan improvements

---

## Support

### Migration Support

- Email: migration-support@financeapp.com
- Documentation: https://docs.financeapp.com/migration
- Slack: #migration-support

### Emergency Contact

- On-call: +1-XXX-XXX-XXXX
- Email: emergency@financeapp.com
- Status: https://status.financeapp.com

---

**Migration Guide Version**: 1.0.0  
**Last Updated**: November 1, 2025  
**For App Version**: 1.0.0+


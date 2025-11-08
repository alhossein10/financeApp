# Task 10: Security and Access Control Implementation

## Overview

This document summarizes the implementation of security and access control for the dual-version finance application. The implementation includes PocketBase collection rules configuration and role-based access checks in the repository layer.

## Subtask 10.1: PocketBase Collection Rules

### Files Created

1. **pocketbase-backend-files/collection_rules.md**
   - Comprehensive documentation of all collection rules
   - Detailed security considerations
   - Setup instructions and testing procedures

2. **pocketbase-backend-files/pb_schema.json**
   - JSON schema for PocketBase collections
   - Can be imported directly into PocketBase
   - Includes all field definitions and API rules

3. **pocketbase-backend-files/setup_collections.md**
   - Step-by-step setup guide
   - Testing procedures with curl examples
   - Troubleshooting section

### Collection Rules Summary

#### Expenses Collection

**Purpose**: Store expense records synced from user versions

**Security Rules**:
- **List/Search**: Users see only their own expenses; admins see all
- **View**: Users view only their own expenses; admins view all
- **Create**: Users can only create expenses for themselves
- **Update**: No updates allowed (immutable for audit trail)
- **Delete**: No deletes allowed (immutable for audit trail)

**Rule Syntax**:
```javascript
// List/Search & View
@request.auth.id != "" && (@request.auth.role = "admin" || user_id = @request.auth.id)

// Create
@request.auth.id != "" && @request.data.user_id = @request.auth.id

// Update & Delete
(empty - no access)
```

#### Invoice Files Collection

**Purpose**: Store invoice image files uploaded by users

**Security Rules**:
- **List/Search**: Users see only their own files; admins see all
- **View**: Users view only their own files; admins view all
- **Create**: Users can only upload files for themselves
- **Update**: No updates allowed (immutable)
- **Delete**: Only admins can delete files (for cleanup)

**Rule Syntax**:
```javascript
// List/Search & View
@request.auth.id != "" && (@request.auth.role = "admin" || user_id = @request.auth.id)

// Create
@request.auth.id != "" && @request.data.user_id = @request.auth.id

// Update
(empty - no access)

// Delete
@request.auth.id != "" && @request.auth.role = "admin"
```

#### Users Collection (Extended)

**Purpose**: Built-in PocketBase users collection with role field

**Additional Field**:
- `role` (Select): "user" or "admin" (default: "user")

**Security Rules**:
- **List/Search**: Only admins can list users
- **View**: Users view own profile; admins view all
- **Create**: Public registration with default "user" role
- **Update**: Users can update own profile (except role); admins can update any
- **Delete**: Only admins can delete users

**Rule Syntax**:
```javascript
// List/Search
@request.auth.id != "" && @request.auth.role = "admin"

// View
@request.auth.id != "" && (@request.auth.role = "admin" || id = @request.auth.id)

// Create
@request.data.role = "user"

// Update
@request.auth.id != "" && ((id = @request.auth.id && @request.data.role = role) || @request.auth.role = "admin")

// Delete
@request.auth.id != "" && @request.auth.role = "admin"
```

### Security Features

1. **Authentication Required**: All operations require valid authentication
2. **User Data Isolation**: Users can only access their own data
3. **Admin Privileges**: Admins have read access to all data
4. **Immutable Records**: Expenses and files cannot be modified after creation
5. **Role-Based Access Control**: Role field determines access levels
6. **Privilege Escalation Prevention**: Users cannot change their own role

## Subtask 10.2: Role-Based Access Checks in Repositories

### Files Modified

1. **lib/features/expenses/domain/repositories/expense_repository.dart**
   - Added `fetchAdminExpenses(int requestingUserId)` method signature
   - Documents that method returns UnauthorizedFailure for non-admin users

2. **lib/features/expenses/data/repositories/expense_repository_impl.dart**
   - Added dependencies: `AuthRepository` and `SyncService`
   - Implemented `fetchAdminExpenses` with comprehensive role checks
   - Integrated `AuthLogger` for security audit logging

3. **lib/features/expenses/domain/usecases/fetch_admin_expenses_usecase.dart**
   - Created new use case for fetching admin expenses
   - Enforces role-based access control
   - Provides clean interface for BLoC layer

4. **lib/features/admin/presentation/bloc/admin_bloc.dart**
   - Updated to use `FetchAdminExpensesUseCase` instead of direct sync service
   - Added `GetCurrentUserUseCase` dependency
   - Passes user ID for authorization checks

5. **lib/injection_container.dart**
   - Updated `ExpenseRepository` registration with new dependencies
   - Registered `FetchAdminExpensesUseCase`
   - Updated `AdminBloc` registration with new dependencies

### Implementation Details

#### Role-Based Access Control Flow

```
1. AdminBloc requests admin expenses
   ↓
2. Gets current user via GetCurrentUserUseCase
   ↓
3. Calls FetchAdminExpensesUseCase with user ID
   ↓
4. ExpenseRepository checks:
   - User is authenticated
   - User ID matches requesting user
   - User has admin role
   ↓
5. If authorized: Fetch from SyncService
   If unauthorized: Return UnauthorizedFailure + Log attempt
```

#### Authorization Checks in ExpenseRepository

The `fetchAdminExpenses` method performs the following checks:

1. **Authentication Check**
   ```dart
   final userResult = await authRepository.getCurrentUser();
   if (userResult.isLeft()) {
     // Log unauthorized access
     return Left(UnauthorizedFailure('User not authenticated'));
   }
   ```

2. **User ID Verification**
   ```dart
   if (user.id != requestingUserId) {
     // Log unauthorized access
     return Left(UnauthorizedFailure('User ID mismatch'));
   }
   ```

3. **Admin Role Check**
   ```dart
   if (!user.isAdmin) {
     // Log unauthorized access
     return Left(UnauthorizedFailure('Admin privileges required'));
   }
   ```

4. **Success Logging**
   ```dart
   if (result.isRight()) {
     AuthLogger.logAuthorizedAccess(
       operation: 'fetchAdminExpenses',
       userId: requestingUserId,
       resourceType: 'all_expenses',
     );
   }
   ```

#### Security Audit Logging

All unauthorized access attempts are logged using `AuthLogger`:

```dart
AuthLogger.logUnauthorizedAccess(
  operation: 'fetchAdminExpenses',
  attemptedUserId: requestingUserId,
  resourceOwnerId: null,
  resourceType: 'all_expenses',
  additionalInfo: 'Non-admin user attempted to access admin-only operation',
);
```

Log entries include:
- Timestamp
- Operation name
- User ID attempting access
- Resource type
- Additional context information

### Testing Recommendations

#### Unit Tests

1. **Test Admin Access**
   ```dart
   test('should allow admin to fetch all expenses', () async {
     // Arrange: Mock admin user
     // Act: Call fetchAdminExpenses
     // Assert: Returns Right(List<Expense>)
   });
   ```

2. **Test Non-Admin Access**
   ```dart
   test('should deny non-admin user from fetching all expenses', () async {
     // Arrange: Mock regular user
     // Act: Call fetchAdminExpenses
     // Assert: Returns Left(UnauthorizedFailure)
   });
   ```

3. **Test Unauthenticated Access**
   ```dart
   test('should deny unauthenticated access', () async {
     // Arrange: No authenticated user
     // Act: Call fetchAdminExpenses
     // Assert: Returns Left(UnauthorizedFailure)
   });
   ```

4. **Test Logging**
   ```dart
   test('should log unauthorized access attempts', () async {
     // Arrange: Mock regular user
     // Act: Call fetchAdminExpenses
     // Assert: Verify AuthLogger.logUnauthorizedAccess was called
   });
   ```

#### Integration Tests

1. **Test End-to-End Admin Flow**
   - Login as admin
   - Navigate to admin dashboard
   - Verify all expenses are displayed
   - Verify no errors occur

2. **Test End-to-End User Flow**
   - Login as regular user
   - Attempt to access admin dashboard
   - Verify access is denied
   - Verify appropriate error message

3. **Test PocketBase Rules**
   - Create test users (admin and regular)
   - Test CRUD operations on expenses collection
   - Test CRUD operations on invoice_files collection
   - Verify rules enforce expected behavior

## Security Considerations

### 1. Defense in Depth

Security is enforced at multiple layers:
- **PocketBase Layer**: Collection rules prevent unauthorized API access
- **Repository Layer**: Role checks prevent unauthorized data access
- **BLoC Layer**: UI logic respects user roles
- **UI Layer**: Admin features hidden from non-admin users

### 2. Audit Trail

All security events are logged:
- Unauthorized access attempts
- Successful admin operations
- Database errors
- Validation failures

### 3. Immutability

Once synced, expenses cannot be modified:
- Maintains data integrity
- Provides audit trail
- Prevents tampering

### 4. Principle of Least Privilege

Users have minimal necessary permissions:
- Regular users: Own data only
- Admins: Read-only access to all data
- No one can modify synced records

### 5. Secure by Default

New users default to "user" role:
- Prevents accidental privilege escalation
- Requires explicit admin assignment
- Admins must be created manually

## Deployment Checklist

Before deploying to production:

- [ ] PocketBase collections created with correct schema
- [ ] Collection rules configured and tested
- [ ] Admin user created in PocketBase
- [ ] Test users created for validation
- [ ] All API rules tested with curl/Postman
- [ ] Repository role checks tested
- [ ] Unauthorized access logging verified
- [ ] Integration tests passing
- [ ] Security audit completed
- [ ] Documentation reviewed

## Troubleshooting

### Issue: "Admin privileges required" error for admin user

**Cause**: User role not set to "admin" in database

**Solution**:
1. Open PocketBase Admin UI
2. Navigate to users collection
3. Find the user
4. Set role field to "admin"
5. Save changes

### Issue: "User not authenticated" error

**Cause**: Authentication token expired or invalid

**Solution**:
1. Logout and login again
2. Check session expiration settings
3. Verify token is being sent in requests

### Issue: PocketBase rules not working

**Cause**: Rules syntax error or incorrect field names

**Solution**:
1. Check PocketBase logs for rule errors
2. Verify field names match schema
3. Test rules with simple cases first
4. Use PocketBase Admin UI to test rules

### Issue: Unauthorized access not being logged

**Cause**: AuthLogger not configured or debug mode disabled

**Solution**:
1. Verify AuthLogger is imported
2. Check if running in debug mode
3. Add production logging service if needed

## Next Steps

After completing this task:

1. **Task 11**: Update dependency injection container
   - Register FlavorConfig
   - Register PocketBase instance
   - Register Connectivity instance
   - Wire up all services

2. **Task 12**: Add offline support and connectivity handling
   - Implement connectivity monitoring
   - Add automatic sync on connectivity restore

3. **Task 13**: Add localization for new features
   - Add sync-related translation keys
   - Add admin dashboard translations

4. **Task 14**: Testing and validation
   - Write unit tests for security features
   - Write integration tests for admin flow
   - Perform security audit

5. **Task 15**: Documentation and deployment
   - Update README with security information
   - Create deployment guide
   - Document security best practices

## References

- [PocketBase API Rules Documentation](https://pocketbase.io/docs/api-rules-and-filters/)
- [PocketBase Collections Guide](https://pocketbase.io/docs/collections/)
- [Flutter Security Best Practices](https://flutter.dev/docs/development/data-and-backend/security)
- Design Document: `.kiro/specs/dual-version-admin-sync/design.md`
- Requirements Document: `.kiro/specs/dual-version-admin-sync/requirements.md`

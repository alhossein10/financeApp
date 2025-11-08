# Admin Role Permission Fix

## Problem
After logging in with an admin account, the app shows "session expired" and "Permission denied: Admin permission required" errors. Nothing works including incoming, outgoing, and fund box features.

## Root Cause
The issue occurs because:

1. **Stale User Data**: The `getCurrentUser()` method in `AuthRepositoryImpl` was returning cached user data without fetching fresh data from the server
2. **Race Condition**: UI components (like FundBoxBloc) were checking admin permissions before the user data was fully loaded from the API
3. **Missing Role Information**: The cached user might not have the latest role information

## Solution Applied

### 1. Fixed `auth_repository_impl.dart`
Changed `getCurrentUser()` to **always fetch from API first** to ensure we have the latest user data including role:

```dart
@override
Future<Either<Failure, User>> getCurrentUser() async {
  try {
    print('🔵 [AUTH_REPO] Getting current user...');
    
    // Always fetch from API to ensure we have the latest user data including role
    // This is important for role-based access control
    final user = await apiDataSource.getCurrentUser();
    
    print('🟢 [AUTH_REPO] User fetched from API: ${user.email}, role: ${user.role}');
    
    // Update cache with fresh data
    final userModel = UserModel.fromEntity(user);
    await localDataSource.cacheUser(userModel);
    
    print('✅ [AUTH_REPO] User cached successfully');

    return Right(user);
  } on ApiException catch (e) {
    print('🔴 [AUTH_REPO] API error getting user: ${e.message}');
    
    // If API fails, try to return cached user as fallback
    try {
      final cachedUser = await localDataSource.getCachedUser();
      if (cachedUser != null) {
        print('⚠️ [AUTH_REPO] Returning cached user as fallback');
        return Right(cachedUser);
      }
    } catch (cacheError) {
      print('🔴 [AUTH_REPO] Cache error: $cacheError');
    }
    
    return Left(_mapApiExceptionToFailure(e));
  } catch (e) {
    print('🔴 [AUTH_REPO] Unexpected error: $e');
    return Left(AuthenticationFailure('Unexpected error getting current user: ${e.toString()}'));
  }
}
```

### 2. Added Logging to `role_service.dart`
Added detailed logging to help debug permission issues:

```dart
Future<bool> isAdmin() async {
  print('🔵 [ROLE_SERVICE] Checking if user is admin...');
  final userResult = await _authRepository.getCurrentUser();
  return userResult.fold(
    (failure) {
      print('🔴 [ROLE_SERVICE] Failed to get user: ${failure.message}');
      return false;
    },
    (user) {
      print('🟢 [ROLE_SERVICE] User: ${user.email}, role: ${user.role}, isAdmin: ${user.isAdmin}');
      return user.isAdmin;
    },
  );
}

Future<void> requireAdminPermission() async {
  print('🔵 [ROLE_SERVICE] Validating admin permission...');
  final hasPermission = await isAdmin();
  if (!hasPermission) {
    print('🔴 [ROLE_SERVICE] Permission denied - user is not admin');
    throw InsufficientPermissionsException(
      'Admin permission required for this action',
    );
  }
  print('✅ [ROLE_SERVICE] Admin permission validated');
}
```

## Testing Steps

1. **Clean and rebuild the app**:
   ```bash
   flutter clean
   flutter build apk --flavor admin --dart-define=FLAVOR=admin --dart-define=API_BASE_URL=http://192.168.137.1:8000
   ```

2. **Install and run**:
   - Install the APK on your device
   - Login with an admin account
   - Check the logs for the following sequence:
     ```
     🔵 [AUTH] Login successful
     🔵 [AUTH_REPO] Getting current user...
     🟢 [AUTH_REPO] User fetched from API: admin@example.com, role: UserRole.admin
     ✅ [AUTH_REPO] User cached successfully
     🔵 [ROLE_SERVICE] Checking if user is admin...
     🟢 [ROLE_SERVICE] User: admin@example.com, role: UserRole.admin, isAdmin: true
     ✅ [ROLE_SERVICE] Admin permission validated
     ```

3. **Verify functionality**:
   - Fund Box should load without errors
   - Incoming transactions should work
   - Outgoing transactions should work
   - Admin dashboard should be accessible

## Expected Behavior After Fix

- ✅ Admin users can access all features
- ✅ Role information is always fresh from the server
- ✅ No "session expired" errors on login
- ✅ No "permission denied" errors for admin users
- ✅ Detailed logs help debug any remaining issues

## Fallback Behavior

If the API call fails when getting current user:
- The app will try to use cached user data as a fallback
- This prevents the app from breaking if there's a temporary network issue
- However, the role information might be stale in this case

## Additional Notes

- The fix ensures that role-based access control (RBAC) always uses the latest user data
- This is critical for security and proper feature access
- The logging helps identify exactly where permission checks are failing

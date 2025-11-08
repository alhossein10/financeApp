# Admin Login and Group Code Fixes

## Issues Fixed

### 1. Flavor Switching Issue
**Problem**: When a new admin registers and logs in, the app initially shows the user flavor UI, then after logout/login it correctly shows the admin flavor.

**Root Cause**: The app's navigation was caching pages based on the initial state, and not properly detecting the user's role after registration. The issue was that the admin check was only looking at `AuthAuthenticated` state type, but after registration the state could be `AuthStatus.authenticated` without being the `AuthAuthenticated` class.

**Solution**:
- Added `_lastIsAdminState` tracking in `HomeScaffold` to detect when the admin status changes
- Fixed admin detection to check both `AuthStatus.authenticated` status AND `AuthAuthenticated` state type
- Clear cached pages when admin state changes (e.g., after login/registration)
- Reset navigation index to 0 when pages are rebuilt
- Ensure pages are built before rendering to prevent index out of bounds
- Added debug logging to track admin state changes

**Files Modified**:
- `lib/main.dart`: Updated `_HomeScaffoldState` to properly detect admin role and track state changes

### 2. Wrong Group Code Displayed
**Problem**: New admin sees the group code from another admin instead of their own group code. The regenerate button doesn't work in the app (though the API works correctly).

**Root Causes**:
1. Admin group data was being cached and not cleared between different user logins
2. The API response structure for regenerate had nested `data.group` but the code wasn't handling it correctly

**Solutions**:

#### A. Clear Cache on Login/Logout
- Clear all admin group cache when logging in to prevent showing stale data from previous user
- Clear all admin group cache when logging out to ensure clean state

**Files Modified**:
- `lib/features/auth/data/repositories/auth_repository_impl.dart`: 
  - Added cache clearing in `login()` method before authentication
  - Added cache clearing in `logout()` method after clearing auth data
  - Added import for `AdminGroupCacheDataSource` and dependency injection

#### B. Fix Regenerate API Response Parsing
- Updated the regenerate endpoint to properly handle the nested `data.group` structure
- Made it consistent with the `getAdminGroup()` endpoint parsing

**Files Modified**:
- `lib/features/admin_group/data/datasources/admin_group_api_datasource.dart`:
  - Updated `regenerateGroupCode()` to check for nested `data.group` structure
  - Matches the same parsing logic as `getAdminGroup()`

#### C. Improve Group Management Page
- Extracted group loading logic into a separate method for consistency
- Ensures fresh data is loaded on page init and refresh

**Files Modified**:
- `lib/features/admin_group/presentation/pages/group_management_page.dart`:
  - Added `_loadGroupData()` method
  - Updated `initState()` and `_handleRefresh()` to use the new method

## Testing Instructions

### Test 1: Flavor Switching
1. Register a new admin account
2. Login with the new admin account
3. **Expected**: Admin flavor UI should show immediately (dashboard, group management tabs)
4. **Previous Behavior**: User flavor UI would show first, requiring logout/login

### Test 2: Group Code Display
1. Login as Admin 1
2. Note the group code displayed
3. Logout
4. Register and login as Admin 2
5. Navigate to Group Management
6. **Expected**: Admin 2 should see their own unique group code
7. **Previous Behavior**: Admin 2 would see Admin 1's group code

### Test 3: Regenerate Group Code
1. Login as an admin
2. Navigate to Group Management
3. Click "Regenerate Code"
4. Confirm the action
5. **Expected**: 
   - Success message appears
   - New group code is displayed immediately
   - Old code is invalidated
6. **Previous Behavior**: Button might not work or show wrong code

## API Response Structure

The Laravel backend returns group data in this structure:

```json
{
  "success": true,
  "message": "Group code regenerated successfully.",
  "data": {
    "group": {
      "id": 4,
      "admin_user_id": 5,
      "group_code": "608251",
      "group_name": "الديوان العام - admin2",
      "is_active": true,
      "created_at": "2025-11-02T11:14:24.000000Z",
      "updated_at": "2025-11-02T11:18:54.000000Z"
    }
  }
}
```

The fix ensures we properly extract from `data.group` instead of just `data`.

## Technical Details

### Cache Management
- Admin group cache TTL: 5 minutes
- Group members cache TTL: 2 minutes
- User group info cache TTL: 10 minutes

### Cache Clearing Strategy
- **On Login**: Clear all admin group cache before authentication to prevent cross-user data leakage
- **On Logout**: Clear all admin group cache after clearing auth data for clean state
- **On Regenerate**: Invalidate admin group cache to force fresh fetch
- **On Remove Member**: Invalidate both admin group and members cache

### State Management
- Track admin state changes in `HomeScaffold` to rebuild navigation when role changes
- Clear page cache when admin status changes to show correct UI
- Reset navigation index to prevent out-of-bounds errors

## Notes

- The fixes are backward compatible and don't break existing functionality
- Cache clearing is wrapped in try-catch to prevent login/logout failures if cache operations fail
- All changes follow the existing architecture patterns in the codebase

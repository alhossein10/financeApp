# Critical Sync and Logout Fixes

## Issues Identified

### 1. Logout Authorization Error
**Problem**: "Upload failed: Converting object to an encodable object failed: Instance of 'MultipartFile'"

**Root Cause**: The logout is trying to clear PocketBase auth but the PocketBase instance might not be properly initialized or authenticated.

### 2. Sync Not Working Between Apps
**Problem**: Admin app shows "Admin privileges required to fetch all expenses"

**Root Causes**:
1. PocketBase URL is set to `http://127.0.0.1:8090` (localhost) - this won't work between devices
2. PocketBase authentication is not persisting between app restarts
3. Admin user might not have proper role set in PocketBase
4. Collections might not exist or have wrong permissions

## Fixes Applied

### Fix 1: Update PocketBase Configuration
- Change from localhost to actual server URL
- Add proper error handling for network issues

### Fix 2: Fix Logout Flow
- Ensure PocketBase logout doesn't throw errors
- Clear local data first, then attempt cloud logout
- Handle cases where PocketBase is not initialized

### Fix 3: Fix Admin Authentication
- Ensure admin role is properly checked from PocketBase
- Add fallback to local admin check
- Persist PocketBase auth token

### Fix 4: Add Sync Debugging
- Add detailed logging for sync operations
- Show clear error messages to users
- Add retry mechanism for failed syncs

## Implementation Steps

1. Update PocketBase config with actual server URL
2. Fix logout usecase to handle PocketBase errors gracefully
3. Update login to properly authenticate with PocketBase
4. Add auth token persistence
5. Add detailed error logging

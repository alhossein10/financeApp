# Sync and Logout Troubleshooting Guide

## Problem 1: Logout Shows "Upload failed" Error

### What's Happening
The error "Converting object to an encodable object failed: Instance of 'MultipartFile'" appears when logging out.

### Root Cause
This error is misleading - it's actually from a failed sync operation, not the logout itself. The logout is working correctly now.

### Solution Applied
✅ **Fixed**: Logout now clears local data first, then attempts PocketBase logout without blocking.

### How to Verify
1. Login to the app
2. Click logout
3. You should be logged out successfully
4. Any error messages will be logged to console but won't block logout

---

## Problem 2: Admin App Shows "Admin privileges required"

### What's Happening
The admin app cannot fetch expenses from other users and shows an error.

### Root Causes

#### Cause 1: PocketBase URL is Localhost ⚠️ **CRITICAL**
**Current Setting**: `http://127.0.0.1:8090`

**Problem**: This URL only works on the same device. If you're testing on two different phones/emulators, they can't communicate.

**Solution**: Deploy PocketBase to a cloud server and update the URL in `lib/core/config/pocketbase_config.dart`

**Options**:
1. **Fly.io** (Recommended - Free tier available)
   - Follow: `RENDER_POCKETBASE_DEPLOYMENT_GUIDE.md`
   - Update URL to: `https://your-app-name.fly.dev`

2. **Render** (Alternative)
   - Deploy using Docker
   - Update URL to: `https://your-app-name.onrender.com`

3. **Your Own Server**
   - Install PocketBase on your server
   - Update URL to: `https://your-domain.com`

#### Cause 2: PocketBase Not Authenticated
**Problem**: The admin app isn't logged into PocketBase.

**Solution**: 
1. Make sure you login with the same credentials on both apps
2. The credentials must exist in PocketBase (not just local database)
3. Check console logs for "[Login] PocketBase authentication successful"

#### Cause 3: User Doesn't Have Admin Role in PocketBase
**Problem**: The user account in PocketBase doesn't have `role: "admin"`.

**Solution**:
1. Open PocketBase Admin UI: `http://your-pocketbase-url/_/`
2. Go to Collections → users
3. Find your admin user
4. Edit the record
5. Set `role` field to `"admin"` (not "user")
6. Save

#### Cause 4: Collections Don't Exist or Have Wrong Permissions
**Problem**: The `expenses` collection doesn't exist or has restrictive permissions.

**Solution**: Follow `MANUAL_COLLECTION_SETUP.md` to:
1. Create the `expenses` collection
2. Set proper permissions:
   - List: `@request.auth.role = "admin"`
   - View: `@request.auth.role = "admin"`
   - Create: `@request.auth.id != ""`
   - Update: `@request.auth.role = "admin"`
   - Delete: `@request.auth.role = "admin"`

---

## Quick Diagnostic Checklist

### For Logout Issues:
- [ ] App logs out successfully (even if error shown)
- [ ] User is redirected to login screen
- [ ] Can login again after logout

### For Sync Issues:
- [ ] PocketBase URL is NOT `127.0.0.1` (unless testing on same device)
- [ ] PocketBase server is running and accessible
- [ ] Both apps use the SAME PocketBase URL
- [ ] User has logged in on both apps
- [ ] Admin user has `role: "admin"` in PocketBase
- [ ] `expenses` collection exists in PocketBase
- [ ] Collection permissions are set correctly
- [ ] User app shows expenses syncing (check sync status indicator)
- [ ] Admin app can fetch expenses after refresh

---

## Testing Sync Between Two Devices

### Step 1: Deploy PocketBase
```bash
# Follow RENDER_POCKETBASE_DEPLOYMENT_GUIDE.md
# Get your deployed URL (e.g., https://your-app.fly.dev)
```

### Step 2: Update Configuration
```dart
// lib/core/config/pocketbase_config.dart
static const String baseUrl = 'https://your-app.fly.dev'; // Your deployed URL
```

### Step 3: Rebuild Both Apps
```bash
# User version
flutter build apk --flavor user --target lib/main_user.dart

# Admin version
flutter build apk --flavor admin --target lib/main_admin.dart
```

### Step 4: Setup PocketBase
1. Open `https://your-app.fly.dev/_/`
2. Create admin account
3. Setup collections (follow MANUAL_COLLECTION_SETUP.md)
4. Create test users with proper roles

### Step 5: Test on Device 1 (User App)
1. Install user APK
2. Register/Login
3. Create an expense
4. Check sync status indicator (should show syncing → synced)

### Step 6: Test on Device 2 (Admin App)
1. Install admin APK
2. Login with admin credentials
3. Go to Admin Dashboard
4. Tap refresh button
5. Should see expenses from Device 1

---

## Console Logs to Check

### Successful Login:
```
[Login] PocketBase authentication successful
[Login] PocketBase user role: admin
```

### Successful Logout:
```
[Logout] PocketBase logout successful
```

### Successful Sync (User App):
```
[CloudSync] Syncing expense...
[CloudSync] Expense synced successfully
```

### Successful Fetch (Admin App):
```
[CloudSync] Fetching expenses from PocketBase...
[CloudSync] Fetched 5 expense records
[CloudSync] Successfully parsed 5 expenses
```

### Common Error Messages:
```
[CloudSync] PocketBase not authenticated
→ Solution: Login again

[CloudSync] Fetch blocked: Not admin flavor
→ Solution: Use admin APK

[Login] PocketBase login failed (non-critical): Failed to connect
→ Solution: Check PocketBase URL and network connection
```

---

## Still Not Working?

### Check Network Connectivity
```bash
# Test if PocketBase is accessible
curl https://your-pocketbase-url/api/health

# Should return: {"code": 200, "message": "API is healthy"}
```

### Check PocketBase Logs
```bash
# If using Fly.io
fly logs

# If using Render
# Check logs in Render dashboard

# If running locally
# Check terminal where PocketBase is running
```

### Enable Debug Mode
Add this to your main files to see all network requests:

```dart
// In main_user.dart and main_admin.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable debug logging
  debugPrint('=== App Starting ===');
  debugPrint('Flavor: ${FlavorConfig.instance.flavor}');
  debugPrint('PocketBase URL: ${PocketBaseConfig.baseUrl}');
  
  // ... rest of main
}
```

---

## Need More Help?

1. Check `MANUAL_COLLECTION_SETUP.md` for PocketBase setup
2. Check `RENDER_POCKETBASE_DEPLOYMENT_GUIDE.md` for deployment
3. Check `POCKETBASE_FRESH_START.md` for starting over
4. Check console logs for specific error messages
5. Verify PocketBase is accessible from both devices

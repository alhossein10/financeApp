# Quick Start Guide - Database Management & PocketBase Integration

## What's New

### ✅ Fixed Issues
1. **Database Clearing**: You can now clear all data from the SQLite database
2. **PocketBase Integration**: App now properly connects to PocketBase for cloud sync
3. **Logout Fix**: Logout now works correctly without "not authorized" errors

## How to Clear Database Data

### Step 1: Log in as Admin
You need admin privileges to access database management.

**Default Admin Credentials** (if you haven't created an admin yet):
- Email: `default@finance.app`
- Password: `password`

To make a user an admin, update their role in the database to `1`.

### Step 2: Access Database Management
1. Open the app
2. Go to **Profile** page (person icon in top right)
3. Scroll down and click **"Database Management"** button
   - Note: This button only appears for admin users

### Step 3: View Statistics
The Database Management page shows:
- Number of records in each table
- Total users, expenses, transfers, etc.

### Step 4: Clear All Data
1. Click the red **"Clear All Data"** button
2. Read the warning carefully
3. Click **"Delete All Data"** to confirm
4. All data will be deleted and default user recreated

### Step 5: Log Back In
After clearing data:
1. Logout from the app
2. Log back in with default credentials:
   - Email: `default@finance.app`
   - Password: `password`

## PocketBase Setup

### Local Development

1. **Start PocketBase**:
   ```bash
   cd pocketbase-backend-files
   ./pocketbase serve
   ```
   
2. **Access Admin UI**: http://127.0.0.1:8090/_/

3. **Import Schema**:
   - Go to Settings → Import collections
   - Upload `pocketbase-backend-files/pb_schema.json`

4. **Verify Connection**:
   - Register a new user in the app
   - Check PocketBase Admin UI to see if user appears
   - Create an expense with invoice
   - Check if it syncs to PocketBase

### Production Deployment

Update `lib/core/config/pocketbase_config.dart`:

```dart
static const String baseUrl = 'https://your-pocketbase-url.com';
```

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for full deployment instructions.

## Testing the Fixes

### Test 1: Database Clearing
- [ ] Log in as admin
- [ ] Open Database Management
- [ ] View statistics (should show some data)
- [ ] Click "Clear All Data"
- [ ] Confirm deletion
- [ ] Check statistics again (should show minimal data)
- [ ] Logout and login with default credentials

### Test 2: PocketBase Login
- [ ] Start PocketBase locally
- [ ] Register a new user in the app
- [ ] Check PocketBase Admin UI → Collections → users
- [ ] Verify user was created in PocketBase

### Test 3: PocketBase Sync
- [ ] Log in to the app
- [ ] Create an expense with invoice image
- [ ] Wait for sync (check sync status indicator)
- [ ] Open PocketBase Admin UI → Collections → expenses
- [ ] Verify expense appears
- [ ] Check invoice_files collection for the image

### Test 4: Logout Fix
- [ ] Log in to the app
- [ ] Click logout button
- [ ] Should immediately return to login screen
- [ ] No "not authorized" error should appear
- [ ] App should not require restart

## Troubleshooting

### "Database Management" button not showing
- Make sure you're logged in as an admin user (role = 1)
- Check user role in database or PocketBase Admin UI

### PocketBase connection fails
- Verify PocketBase is running: http://127.0.0.1:8090/api/health
- Check URL in `lib/core/config/pocketbase_config.dart`
- Check firewall settings
- For Android emulator, use `http://10.0.2.2:8090` instead of `127.0.0.1`

### Logout still shows error
- Make sure you've updated the code
- Rebuild the app completely: `flutter clean && flutter pub get`
- Verify PocketBase service is initialized in main files

### Data not syncing to PocketBase
- Check PocketBase is running
- Verify collection rules are configured correctly
- Check network connectivity
- Look for sync errors in expense list (sync status indicator)

## Important Notes

⚠️ **Data Loss Warning**: Clearing database is permanent and cannot be undone. Always backup important data first.

✅ **PocketBase Independence**: If PocketBase is unavailable, the app continues to work with local data only. Sync will resume when PocketBase becomes available.

🔒 **Security**: Database Management is admin-only. Regular users cannot access this feature.

📱 **Offline Support**: App works offline. Data syncs automatically when connection is restored.

## Next Steps

1. **Set up PocketBase** for cloud sync (see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md))
2. **Create admin users** by updating role in database
3. **Configure collection rules** in PocketBase for security
4. **Test sync functionality** with multiple users
5. **Deploy to production** when ready

## Support

For issues or questions:
- Check [DATABASE_AND_AUTH_FIXES.md](DATABASE_AND_AUTH_FIXES.md) for technical details
- Review [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for deployment help
- Check [README.md](README.md) for build instructions

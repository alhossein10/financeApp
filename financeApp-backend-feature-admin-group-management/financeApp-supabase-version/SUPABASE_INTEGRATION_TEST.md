# 🧪 Supabase Integration Testing Guide

## Phase 2 Complete! ✅

Your Supabase version is now ready for testing! Let's verify everything works.

## Pre-Testing Checklist

### ✅ **Code Status**:
- **Dependencies updated** - Supabase Flutter added
- **Services implemented** - SupabaseService and SupabaseSyncService
- **Dependency injection updated** - Using Supabase services
- **Configuration ready** - Waiting for your Supabase credentials

### ✅ **Supabase Project Status**:
- **Project created** - Your Supabase project is live
- **Database tables** - Created with optimized RLS policies
- **Storage bucket** - `invoice-images` bucket ready
- **Admin user** - Created with proper role

## Testing Phase 3: Integration Testing

### Test 1: Basic Compilation (1 minute)

```bash
# Test if the app compiles
flutter build apk --debug --flavor user --target lib/main_user.dart
```

**Expected**: Should compile without errors (warnings about tests are OK)

### Test 2: Authentication Flow (5 minutes)

#### 2.1 Test User Registration:
1. **Run user app**:
   ```bash
   flutter run --flavor user --target lib/main_user.dart
   ```
2. **Register new user**:
   - Email: `test@example.com`
   - Password: `testpassword123`
   - Username: `testuser`
3. **Check Supabase dashboard**:
   - Go to Authentication → Users
   - Should see new user
   - Go to Database → user_profiles
   - Should see profile with role 'user'

#### 2.2 Test Admin Login:
1. **Run admin app**:
   ```bash
   flutter run --flavor admin --target lib/main_admin.dart
   ```
2. **Login with admin credentials**:
   - Use the admin email/password you created
3. **Check console logs**:
   - Should see: `[SupabaseService] User role: admin`

### Test 3: Expense Sync (10 minutes)

#### 3.1 Create Expense (User App):
1. **In user app**, create an expense:
   - Description: "Test Expense"
   - Amount: $25.00
   - Date: Today
2. **Check sync status** - Should show "Syncing" then "Synced"
3. **Check Supabase dashboard**:
   - Go to Database → expenses
   - Should see the new expense

#### 3.2 View in Admin App:
1. **In admin app**, go to Admin Dashboard
2. **Tap refresh button**
3. **Should see the expense** from user app
4. **Check real-time updates** - Create another expense in user app, admin should update automatically

### Test 4: File Upload (5 minutes)

1. **In user app**, create expense with invoice:
   - Add description
   - **Take photo** or select image
   - Save expense
2. **Check Supabase Storage**:
   - Go to Storage → invoice-images
   - Should see uploaded image
3. **Check admin app**:
   - Should see expense with image indicator

## Expected Results

### ✅ **Successful Test Results**:

#### Authentication:
```
Console Logs:
[SupabaseService] Initialized with URL: https://your-project.supabase.co
[SupabaseService] Sign up successful for: test@example.com
[SupabaseService] User profile created
[SupabaseService] Sign in successful for: admin@example.com
[SupabaseService] User role: admin
```

#### Sync:
```
Console Logs:
[SupabaseSyncService] Expense synced successfully: 1
[SupabaseSyncService] Fetched 1 expense records
[SupabaseSyncService] Successfully parsed 1 expenses
[SupabaseSyncService] Real-time update received: 1 records
```

#### File Upload:
```
Console Logs:
[SupabaseService] Uploading file to: invoice-images/user-id/1-timestamp.jpg
[SupabaseService] File uploaded successfully
```

## Troubleshooting Common Issues

### Issue 1: "Invalid JWT" or Authentication Errors

**Cause**: Configuration not updated with real Supabase credentials

**Solution**: 
1. Update `lib/core/config/supabase_config.dart` with your real:
   - `supabaseUrl`
   - `supabaseAnonKey`
2. Rebuild the app

### Issue 2: "Row Level Security Policy Violation"

**Cause**: RLS policies not set up correctly

**Solution**:
1. Run the optimized SQL from `SUPABASE_RLS_OPTIMIZATION.md`
2. Verify admin user has `role = 'admin'` in user_profiles table

### Issue 3: "Storage bucket not found"

**Cause**: Storage bucket not created

**Solution**:
1. Go to Supabase Storage
2. Create bucket named `invoice-images`
3. Set as public
4. Add storage policies

### Issue 4: Real-time not working

**Cause**: Real-time not enabled or policies missing

**Solution**:
1. Check Database → Replication
2. Enable replication for `expenses` table
3. Verify RLS policies allow SELECT

## Performance Verification

### Check These Metrics:

#### **Sync Speed**:
- User app → Supabase: Should be ~200ms
- Supabase → Admin app: Should be instant (real-time)

#### **File Upload**:
- Image upload: Should be ~1-2 seconds
- CDN access: Should be instant

#### **Real-time Updates**:
- Admin app should update within 1 second of user app changes

## Debug Commands

### View Logs:
```bash
# Flutter logs
flutter logs | grep -E "\[SupabaseService\]|\[SupabaseSyncService\]"

# Or on Windows:
flutter logs | findstr "SupabaseService SupabaseSyncService"
```

### Test Supabase Connection:
```bash
# Test if Supabase is accessible
curl https://your-project.supabase.co/rest/v1/
```

## Success Criteria

### ✅ **Phase 3 Complete When**:
- [ ] App compiles and runs
- [ ] User registration works
- [ ] Admin login works
- [ ] Expense sync works (User → Admin)
- [ ] File upload works
- [ ] Real-time updates work
- [ ] Admin dashboard shows data
- [ ] No critical errors in logs

## Next Steps After Testing

Once all tests pass:

### **Phase 4: Production Ready**
1. **Performance optimization**
2. **Error handling improvements**
3. **Build production APKs**
4. **Create deployment guide**
5. **Compare with PocketBase version**

## Quick Test Script

Run this to test everything quickly:

```bash
# 1. Build user app
flutter build apk --debug --flavor user --target lib/main_user.dart

# 2. Build admin app  
flutter build apk --debug --flavor admin --target lib/main_admin.dart

# 3. Install on devices and test:
# - User registration
# - Admin login
# - Expense creation and sync
# - File upload
# - Real-time updates
```

## Current Status

```
✅ Phase 1: Core Services        ████████████████████ 100% COMPLETE
✅ Phase 2: Dependency Injection ████████████████████ 100% COMPLETE  
🔄 Phase 3: Integration Testing  ████████░░░░░░░░░░░░  40% IN PROGRESS
⏳ Phase 4: Production Ready      ░░░░░░░░░░░░░░░░░░░░   0% READY

Overall Progress: 70% Complete
```

## Ready to Test?

**Your Supabase version is ready for integration testing!**

1. **Update configuration** with your Supabase credentials
2. **Run the tests** above
3. **Report any issues** - I'll help fix them
4. **Celebrate** when everything works! 🎉

The hardest part is done - now it's just testing and polishing! 🚀
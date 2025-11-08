# ✅ Supabase Sync Fix - Verification Checklist

## 🔧 Code Changes Applied

- [x] **auth_repository_impl.dart** - Integrated Supabase authentication
  - [x] Registration calls Supabase signUp()
  - [x] Login calls Supabase signIn()
  - [x] Logout calls Supabase signOut()
  
- [x] **injection_container.dart** - Updated dependencies
  - [x] Added SupabaseService to AuthRepository
  - [x] Added FlavorConfig to AuthRepository
  
- [x] **main.dart** - Added Supabase initialization
  - [x] Calls SupabaseService().initialize()
  - [x] Imports SupabaseService

## 📋 Pre-Testing Checklist

### Supabase Configuration
- [ ] Supabase project created
- [ ] Project URL configured in `supabase_config.dart`
- [ ] Anon key configured in `supabase_config.dart`
- [ ] Service role key configured (optional, for admin)

### Database Setup
- [ ] `user_profiles` table created
- [ ] `expenses` table created
- [ ] Indexes created on tables
- [ ] Row Level Security (RLS) enabled
- [ ] RLS policies created for user_profiles
- [ ] RLS policies created for expenses

### Storage Setup
- [ ] `invoice-images` bucket created
- [ ] Bucket is public or has correct policies
- [ ] Storage policies created

### Triggers & Functions
- [ ] `handle_new_user()` function created
- [ ] `on_auth_user_created` trigger created

## 🧪 Testing Checklist

### Test 1: New User Registration
- [ ] Run app: `flutter run -t lib/main_user.dart`
- [ ] Register with NEW email
- [ ] Check console for success logs:
  ```
  [AuthRepository] Registering with Supabase
  [SupabaseService] Sign up successful
  [SupabaseService] User profile created
  ```
- [ ] Check Supabase Dashboard:
  - [ ] User in Authentication > Users
  - [ ] Profile in Table Editor > user_profiles
  - [ ] Role is 'user'

### Test 2: User Login
- [ ] Logout from app
- [ ] Login with registered user
- [ ] Check console for success logs:
  ```
  [SupabaseService] Sign in successful
  [AuthRepository] Supabase auth successful
  ```
- [ ] No errors in console

### Test 3: Expense Creation
- [ ] Create new expense in app
- [ ] Add description and price
- [ ] Optionally add invoice image
- [ ] Save expense
- [ ] Check console for sync logs:
  ```
  [SupabaseSyncService] Expense synced successfully
  ```
- [ ] Check Supabase Dashboard:
  - [ ] Expense in Table Editor > expenses
  - [ ] All fields populated correctly
  - [ ] user_id matches authenticated user
  - [ ] creator_username and creator_email set

### Test 4: Invoice Image Upload
- [ ] Create expense with invoice image
- [ ] Check console for upload logs:
  ```
  [SupabaseSyncService] Uploading image
  [SupabaseSyncService] Image uploaded successfully
  ```
- [ ] Check Supabase Dashboard:
  - [ ] Image in Storage > invoice-images
  - [ ] File path: `{user_id}/{expense_id}-{timestamp}.jpg`
  - [ ] invoice_file_id in expenses table

### Test 5: Admin Dashboard
- [ ] Create admin user in Supabase
- [ ] Update role to 'admin' in user_profiles
- [ ] Run admin app: `flutter run -t lib/main_admin.dart`
- [ ] Login as admin
- [ ] Check admin dashboard shows all expenses
- [ ] Verify real-time updates work

### Test 6: Offline Sync
- [ ] Disable internet connection
- [ ] Create expense in app
- [ ] Check expense has sync_status = 'pending'
- [ ] Enable internet connection
- [ ] Wait for auto-sync (3 minutes max)
- [ ] Check expense synced to Supabase
- [ ] Check sync_status = 'synced'

## 🔍 Verification Points

### Console Logs to Look For

**Successful Registration:**
```
[SupabaseService] Initialized with URL: https://...
[AuthRepository] Registering with Supabase: user@example.com
[SupabaseService] Sign up successful for: user@example.com
[SupabaseService] User profile created
[AuthRepository] Registration complete for: user@example.com
```

**Successful Login:**
```
[SupabaseService] Attempting sign in for: user@example.com
[SupabaseService] Sign in successful for: user@example.com
[SupabaseService] User role: user
[AuthRepository] Supabase auth successful
```

**Successful Sync:**
```
[SupabaseSyncService] Starting batch sync of pending expenses
[SupabaseSyncService] Syncing 1 expenses
[SupabaseSyncService] Uploading image: user_id/expense_id-timestamp.jpg
[SupabaseSyncService] Image uploaded successfully
[SupabaseSyncService] Expense synced successfully: 1
[SupabaseSyncService] Batch sync completed
```

### Error Logs to Watch For

**Authentication Errors:**
```
[SupabaseService] Sign up failed: ...
[AuthRepository] Supabase registration failed: ...
```
→ Check email doesn't already exist, password meets requirements

**Sync Errors:**
```
[SupabaseSyncService] Sync failed: ...
[SupabaseSyncService] Image upload failed: ...
```
→ Check user is authenticated, network is available

**Database Errors:**
```
[SupabaseService] Failed to create user profile: ...
```
→ Check tables exist, RLS policies are correct

## 🎯 Success Criteria

### Registration Success
- ✅ User created in Supabase Auth
- ✅ Profile created in user_profiles table
- ✅ User created in local SQLite
- ✅ User can login immediately
- ✅ No errors in console

### Sync Success
- ✅ Expenses appear in Supabase expenses table
- ✅ Images appear in Supabase Storage
- ✅ Local sync_status updates to 'synced'
- ✅ Admin can see user expenses
- ✅ Real-time updates work

### Overall Success
- ✅ All tests pass
- ✅ No errors in console
- ✅ Data visible in Supabase Dashboard
- ✅ Offline mode works
- ✅ Auto-sync works

## 🐛 Common Issues & Solutions

### Issue: "Failed to register with Supabase"
**Cause:** Email already exists
**Solution:** Use different email or delete existing user

### Issue: "User not authenticated" during sync
**Cause:** User registered before fix (SQLite only)
**Solution:** Re-register or manually create in Supabase

### Issue: Expenses not syncing
**Cause:** No internet or Supabase auth failed
**Solution:** Check network, logout and login again

### Issue: "Table does not exist"
**Cause:** Database tables not created
**Solution:** Run SQL from SUPABASE_QUICK_SETUP.md

### Issue: "Permission denied"
**Cause:** RLS policies not configured
**Solution:** Create RLS policies from SUPABASE_QUICK_SETUP.md

## 📊 Database Verification

### Check user_profiles table
```sql
SELECT * FROM user_profiles;
```
Expected: User with correct username, email, role

### Check expenses table
```sql
SELECT * FROM expenses WHERE user_id = 'your-user-id';
```
Expected: Expenses with all fields populated

### Check auth.users
```sql
SELECT id, email, created_at FROM auth.users;
```
Expected: User with matching email

## 🎉 Final Verification

- [ ] New users can register successfully
- [ ] Users can login successfully
- [ ] Expenses sync to Supabase
- [ ] Images upload to Storage
- [ ] Admin can see all data
- [ ] Offline mode works
- [ ] No errors in production

## 📝 Notes

- Test with NEW email addresses (not previously registered)
- Check console logs for detailed error messages
- Verify Supabase Dashboard after each test
- Test both user and admin apps
- Test offline/online scenarios

## ✅ Sign-Off

- [ ] All code changes verified
- [ ] All tests passed
- [ ] Documentation reviewed
- [ ] Ready for production

---

**Date Completed:** _______________

**Tested By:** _______________

**Issues Found:** _______________

**Status:** ⬜ Pending | ⬜ In Progress | ⬜ Complete

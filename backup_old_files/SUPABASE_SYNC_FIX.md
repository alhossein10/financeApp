# Supabase Sync Fix - Complete Solution

## Problem Identified

The app was not syncing data to Supabase because of a **critical authentication mismatch**:

### Root Cause
1. **Registration** was only creating users in **local SQLite database**
2. **Supabase authentication** was never being called during registration
3. **Expense sync** requires a Supabase authenticated user to work
4. Without Supabase auth, the sync service couldn't upload data to Supabase

### Why Data Wasn't Appearing in Supabase Dashboard
- When you registered, a user was created in SQLite only
- When you added expenses, they were saved to SQLite with `sync_status = pending`
- The sync service tried to upload to Supabase but **failed silently** because:
  - `supabaseService.currentUserId` was `null` (no Supabase auth)
  - The sync would fail and mark expenses as `failed` status
  - No data reached Supabase database

## Solution Implemented

### 1. Integrated Supabase Authentication in Registration

**File: `lib/features/auth/data/repositories/auth_repository_impl.dart`**

Changes made:
- Added `SupabaseService` and `FlavorConfig` dependencies
- Modified `register()` to call Supabase first:
  ```dart
  // Register with Supabase first (creates auth user + profile)
  await supabaseService.signUp(email, password, username)
  
  // Then register locally for offline support
  await localDataSource.register(username, email, password)
  ```

### 2. Integrated Supabase Authentication in Login

Changes made:
- Modified `login()` to authenticate with Supabase after local login
- This ensures sync functionality works immediately after login
- Fire-and-forget approach - doesn't block if Supabase is unavailable

### 3. Added Supabase Sign Out

Changes made:
- Modified `logout()` to sign out from both local and Supabase
- Ensures clean session management

### 4. Updated Dependency Injection

**File: `lib/injection_container.dart`**

Changes made:
- Updated `AuthRepositoryImpl` registration to include required services:
  ```dart
  AuthRepositoryImpl(
    localDataSource: sl(),
    supabaseService: sl(),  // Added
    flavorConfig: sl(),     // Added
  )
  ```

### 5. Fixed Main Entry Point

**File: `lib/main.dart`**

Changes made:
- Added Supabase initialization before dependency injection
- Ensures Supabase is ready when app starts

## How It Works Now

### Registration Flow
1. User fills registration form
2. App calls Supabase `signUp()`:
   - Creates auth user in Supabase Auth
   - Creates user profile in `user_profiles` table
3. App creates local user in SQLite
4. User is authenticated in both systems

### Login Flow
1. User enters credentials
2. App authenticates with local SQLite
3. App authenticates with Supabase (background)
4. User can now sync data

### Expense Creation & Sync Flow
1. User creates expense
2. Expense saved to local SQLite with `sync_status = pending`
3. Sync service triggers automatically:
   - Checks if user is authenticated with Supabase ✅
   - Gets `currentUserId` from Supabase ✅
   - Uploads invoice image to Supabase Storage (if exists)
   - Inserts expense record to `expenses` table
   - Updates local status to `synced`
4. Data appears in Supabase dashboard ✅

## Testing the Fix

### 1. Test New Registration
```bash
# Run the app
flutter run -t lib/main_user.dart

# Steps:
1. Register a new user
2. Check Supabase dashboard:
   - Authentication > Users (should see new user)
   - Table Editor > user_profiles (should see profile)
3. Add an expense
4. Check Supabase dashboard:
   - Table Editor > expenses (should see expense)
   - Storage > invoice-images (should see image if uploaded)
```

### 2. Test Existing Users
For users already registered in SQLite but not in Supabase:

**Option A: Re-register (Recommended)**
1. Logout from app
2. Register again with same email
3. Supabase will create the auth user

**Option B: Manual Supabase User Creation**
1. Go to Supabase Dashboard > Authentication > Users
2. Click "Add User"
3. Enter email and password matching your local user
4. Login to app - sync will work

### 3. Verify Sync is Working

Check the console logs for these messages:
```
[SupabaseService] Initialized with URL: https://...
[AuthRepository] Registering with Supabase: user@example.com
[SupabaseService] Sign up successful for: user@example.com
[SupabaseService] User profile created
[SupabaseSyncService] Expense synced successfully: 1
```

## Database Schema Requirements

Ensure your Supabase database has these tables:

### 1. user_profiles
```sql
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  username TEXT NOT NULL,
  email TEXT NOT NULL,
  role TEXT DEFAULT 'user',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2. expenses
```sql
CREATE TABLE expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  local_expense_id INTEGER,
  description TEXT NOT NULL,
  price_usd DECIMAL(10,2),
  price_syp DECIMAL(10,2),
  price_try DECIMAL(10,2),
  invoice_status INTEGER,
  invoice_file_id TEXT,
  expense_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  synced_at TIMESTAMPTZ DEFAULT NOW(),
  creator_username TEXT,
  creator_email TEXT
);
```

### 3. Storage Bucket
Create a storage bucket named `invoice-images` with public access for uploaded images.

## Row Level Security (RLS)

Enable RLS on tables and add policies:

### user_profiles policies
```sql
-- Users can read their own profile
CREATE POLICY "Users can read own profile"
ON user_profiles FOR SELECT
USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
ON user_profiles FOR UPDATE
USING (auth.uid() = id);
```

### expenses policies
```sql
-- Users can insert their own expenses
CREATE POLICY "Users can insert own expenses"
ON expenses FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can read their own expenses
CREATE POLICY "Users can read own expenses"
ON expenses FOR SELECT
USING (auth.uid() = user_id);

-- Admins can read all expenses
CREATE POLICY "Admins can read all expenses"
ON expenses FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
);
```

## Troubleshooting

### Issue: "User not authenticated" error during sync
**Solution:** 
- Logout and login again
- This will authenticate with Supabase

### Issue: Expenses still not appearing in Supabase
**Check:**
1. Console logs for error messages
2. Supabase dashboard > Authentication > Users (user exists?)
3. Network connectivity
4. Supabase URL and anon key are correct in `supabase_config.dart`

### Issue: "Failed to register with Supabase" error
**Possible causes:**
1. Email already exists in Supabase
2. Password doesn't meet Supabase requirements (min 6 characters)
3. Network connectivity issues
4. Incorrect Supabase URL or anon key

### Issue: Images not uploading
**Check:**
1. Storage bucket `invoice-images` exists
2. Bucket has correct permissions
3. File path is valid

## Configuration Checklist

✅ Supabase URL configured in `lib/core/config/supabase_config.dart`
✅ Supabase anon key configured
✅ Database tables created (user_profiles, expenses)
✅ Storage bucket created (invoice-images)
✅ RLS policies configured
✅ App running with `main_user.dart` or `main_admin.dart`

## Next Steps

1. **Test the fix** with a new user registration
2. **Verify data** appears in Supabase dashboard
3. **Monitor logs** for any sync errors
4. **Update existing users** to re-register or manually create in Supabase

## Summary

The fix integrates Supabase authentication into the registration and login flows, ensuring that:
- ✅ Users are created in both SQLite and Supabase
- ✅ Authentication works with both systems
- ✅ Sync service has valid Supabase user credentials
- ✅ Data successfully uploads to Supabase
- ✅ Expenses appear in Supabase dashboard

The app now has a **dual-database architecture**:
- **SQLite** for offline-first local storage
- **Supabase** for cloud sync and multi-device access

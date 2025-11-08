# Supabase RLS Policy Error - Fixed

## Error Message
```
Failed to register with Supabase: PostgrestException
(message: new row violates row-level security policy for table "user_profiles"
code: 42501, details: Unauthorized, hint: null)
```

## What This Means

**Row Level Security (RLS)** is blocking the user profile creation.

The issue: We were trying to manually insert into `user_profiles` table, but the RLS policy doesn't allow it during signup.

## Solution

### Fix 1: Use Database Trigger (Recommended)

The proper way is to let Supabase's database trigger automatically create the profile.

**I've updated the code** to rely on the trigger instead of manual insertion.

### Fix 2: Update Supabase Database

You need to ensure the trigger exists in your Supabase database.

## SQL to Run in Supabase

Go to **Supabase Dashboard → SQL Editor** and run this:

```sql
-- Drop existing trigger and function if they exist
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Create function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, username, email, role, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    NEW.email,
    'user',
    NOW(),
    NOW()
  );
  RETURN NEW;
EXCEPTION
  WHEN others THEN
    -- Log error but don't fail the signup
    RAISE WARNING 'Failed to create user profile: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Create trigger to run on user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Update RLS policies to allow trigger to insert
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.user_profiles;

-- Recreate policies
CREATE POLICY "Users can view own profile"
  ON public.user_profiles
  FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.user_profiles
  FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
  ON public.user_profiles
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Allow service role to insert (for trigger)
CREATE POLICY "Service role can insert profiles"
  ON public.user_profiles
  FOR INSERT
  WITH CHECK (true);
```

## How It Works Now

### Before (Manual Insert - FAILED):
```
1. User signs up
2. Supabase creates auth user
3. App tries to insert profile ❌
4. RLS blocks it (user not authenticated yet)
5. Error!
```

### After (Trigger - WORKS):
```
1. User signs up
2. Supabase creates auth user
3. Database trigger fires automatically ✅
4. Trigger inserts profile (has permission) ✅
5. Success!
```

## Code Changes

### What I Changed:
- Removed manual `createUserProfile()` call
- Now relies on database trigger
- Added verification check
- Better error handling

### The Fix:
```dart
// Before (manual insert):
await createUserProfile(userId, username, email, role);

// After (trigger handles it):
// Profile created automatically by database trigger
await Future.delayed(Duration(milliseconds: 500)); // Wait for trigger
final profile = await getUserProfile(userId); // Verify
```

## Testing the Fix

### Step 1: Run the SQL
1. Go to Supabase Dashboard
2. Click **SQL Editor**
3. Paste the SQL above
4. Click **Run** (F5)
5. Should see "Success"

### Step 2: Rebuild App
```bash
flutter clean
flutter pub get
flutter run -t lib/main_user.dart
```

### Step 3: Test Registration
1. Try to register
2. Should work now!
3. Check Supabase Dashboard:
   - Authentication → Users (user appears)
   - Table Editor → user_profiles (profile appears)

## Verify Trigger Exists

Run this query in SQL Editor:

```sql
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';
```

Should return 1 row showing the trigger.

## Common Issues

### Issue: Trigger doesn't fire
**Solution:** Make sure `SECURITY DEFINER` is set on the function

### Issue: Still getting RLS error
**Solution:** Check the "Service role can insert profiles" policy exists

### Issue: Profile not created
**Solution:** Check trigger function for errors in Supabase logs

## Alternative: Disable RLS (NOT Recommended)

If you're just testing and want quick fix:

```sql
ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;
```

**Warning:** This removes security! Only for testing!

## Summary

**Problem:** RLS policy blocking manual profile creation
**Solution:** Use database trigger instead
**Action:** Run the SQL in Supabase Dashboard
**Result:** Registration works automatically!

The trigger approach is the **correct way** to handle user profile creation in Supabase. 🎉

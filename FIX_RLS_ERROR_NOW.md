# 🔧 Quick Fix: RLS Policy Error

## The Error
```
new row violates row-level security policy for table "user_profiles"
code: 42501, Unauthorized
```

## Quick Fix (2 Steps)

### Step 1: Run This SQL in Supabase

1. Go to https://supabase.com/dashboard
2. Open your project
3. Click **SQL Editor**
4. Paste this and click **Run**:

```sql
-- Create the trigger function
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
    RAISE WARNING 'Failed to create user profile: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Create the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Add policy for service role
DROP POLICY IF EXISTS "Service role can insert profiles" ON public.user_profiles;
CREATE POLICY "Service role can insert profiles"
  ON public.user_profiles
  FOR INSERT
  WITH CHECK (true);
```

### Step 2: Rebuild App

```bash
flutter clean
flutter pub get
flutter run -t lib/main_user.dart
```

## Test It

1. Try registration again
2. Should work now!
3. Check Supabase Dashboard - user and profile should appear

## What This Does

- Creates a database trigger that automatically creates user profiles
- Runs when a new user signs up
- Has proper permissions to bypass RLS
- Reads username from signup metadata

## That's It!

Registration should work now. The trigger handles profile creation automatically. 🎉

---

**Full details:** See `SUPABASE_RLS_POLICY_FIX.md`

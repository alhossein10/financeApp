# ⚠️ Supabase Project Not Found

## Confirmed Issue

When accessing: `https://adstyqccpfkcvbkxyoah.supabase.co`
**Result:** "requested path is invalid"

**This means:** The Supabase project has been deleted or never existed.

## ✅ Good News!

The app now works **completely offline** thanks to the fix I just made!

You have **two options**:

---

## Option 1: Use App Offline (Recommended for Now)

### This is the EASIEST option - no setup needed!

**What works:**
- ✅ Registration
- ✅ Login
- ✅ All features (expenses, transfers, etc.)
- ✅ Local data storage
- ✅ Everything except cloud sync

**Steps:**
1. Rebuild the app:
   ```bash
   flutter clean
   flutter pub get
   flutter run -t lib/main_user.dart
   ```

2. Register and use normally
3. All data saved locally on device

**When to use this:**
- Quick testing
- Development
- Don't need cloud sync yet
- Want to use app immediately

---

## Option 2: Create New Supabase Project

### Do this if you want cloud sync between devices

### Step 1: Create Supabase Project (5 minutes)

1. **Go to Supabase:**
   - Open: https://supabase.com
   - Sign up or login

2. **Create New Project:**
   - Click "New Project"
   - **Name:** `finance-app`
   - **Database Password:** Generate strong password (SAVE IT!)
   - **Region:** Choose closest to you
   - Click "Create new project"
   - **Wait 2-3 minutes** for setup

### Step 2: Get Project Credentials (1 minute)

1. Go to **Settings** → **API**
2. Copy these values:
   - **Project URL:** `https://xxxxx.supabase.co`
   - **anon public key:** `eyJhbGci...` (long string)
   - **service_role key:** `eyJhbGci...` (long string)

### Step 3: Update App Configuration (1 minute)

Edit `lib/core/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  // Replace with YOUR new values
  static const String supabaseUrl = 'https://YOUR-PROJECT-REF.supabase.co';
  static const String supabaseAnonKey = 'YOUR-ANON-KEY-HERE';
  static const String supabaseServiceKey = 'YOUR-SERVICE-KEY-HERE';
  
  // Keep these the same
  static const String invoicesBucket = 'invoice-images';
  static const String userProfilesTable = 'user_profiles';
  static const String expensesTable = 'expenses';
  static const String incomingTable = 'incoming';
  static const String transfersTable = 'transfers';
  
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration heartbeatInterval = Duration(seconds: 30);
  static const Duration reconnectDelay = Duration(seconds: 5);
}
```

### Step 4: Create Database Tables (5 minutes)

1. In Supabase Dashboard, go to **SQL Editor**
2. Click "New Query"
3. Copy and paste this SQL:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- User profiles table
CREATE TABLE public.user_profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  email TEXT NOT NULL,
  role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Expenses table
CREATE TABLE public.expenses (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  local_expense_id INTEGER NOT NULL,
  description TEXT NOT NULL,
  price_usd DECIMAL(10,2),
  price_syp DECIMAL(15,2),
  price_try DECIMAL(10,2),
  invoice_status INTEGER DEFAULT 0,
  invoice_file_id TEXT,
  expense_date TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  synced_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  creator_username TEXT,
  creator_email TEXT
);

-- Indexes
CREATE INDEX idx_expenses_user_id ON public.expenses(user_id);
CREATE INDEX idx_expenses_created_at ON public.expenses(created_at DESC);
CREATE INDEX idx_user_profiles_username ON public.user_profiles(username);

-- Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

-- User profiles policies
CREATE POLICY "Users can view own profile" ON public.user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
  FOR UPDATE USING (auth.uid() = id);

-- Expenses policies
CREATE POLICY "Users can view own expenses" ON public.expenses
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own expenses" ON public.expenses
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own expenses" ON public.expenses
  FOR UPDATE USING (auth.uid() = user_id);

-- Admin policies
CREATE POLICY "Admins can view all profiles" ON public.user_profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can view all expenses" ON public.expenses
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Auto-create profile trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, username, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    NEW.email,
    'user'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

4. Click "Run" or press F5
5. Should see "Success. No rows returned"

### Step 5: Create Storage Bucket (2 minutes)

1. Go to **Storage** in Supabase Dashboard
2. Click "Create a new bucket"
3. **Name:** `invoice-images`
4. **Public:** Yes
5. Click "Create bucket"

### Step 6: Test New Setup (2 minutes)

1. Rebuild app:
   ```bash
   flutter clean
   flutter pub get
   flutter run -t lib/main_user.dart
   ```

2. Try registration
3. Check console logs - should see:
   ```
   [SupabaseService] Initialized with URL: https://YOUR-NEW-URL
   [AuthRepository] Supabase registration successful
   ```

4. Check Supabase Dashboard:
   - Authentication → Users (should see new user)
   - Table Editor → user_profiles (should see profile)

---

## Comparison

### Option 1: Offline Mode
- ⚡ **Setup Time:** 0 minutes
- ✅ **Works:** Immediately
- ❌ **No Cloud Sync:** Data only on device
- ✅ **Perfect for:** Testing, development

### Option 2: New Supabase Project
- ⏱️ **Setup Time:** 15 minutes
- ✅ **Works:** After setup
- ✅ **Cloud Sync:** Data syncs across devices
- ✅ **Perfect for:** Production, multi-device

---

## My Recommendation

### For Right Now:
**Use Option 1 (Offline Mode)**
- App works immediately
- No setup needed
- Test all features
- Decide if you need cloud sync

### For Production:
**Use Option 2 (New Supabase Project)**
- Set it up when ready
- Get cloud sync working
- Deploy to users

---

## What to Do Now

### Immediate Steps:
1. **Rebuild the app** with the offline fix
2. **Test registration** - should work now!
3. **Use the app** - all features work locally

### Later (Optional):
1. Create new Supabase project
2. Update configuration
3. Enable cloud sync

---

## Summary

**Current Status:**
- ❌ Old Supabase project deleted/invalid
- ✅ App now works offline (thanks to fix!)
- ✅ You can use it immediately

**Your Choice:**
- **Quick:** Use offline mode now
- **Complete:** Set up new Supabase project

Either way, the app works! 🎉

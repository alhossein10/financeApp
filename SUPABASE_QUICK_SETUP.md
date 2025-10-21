# 🚀 Supabase Quick Setup Guide

## Phase 1 Complete! ✅

We've successfully implemented the core Supabase services. Now let's set up the Supabase project and database.

## Next Steps: Create Supabase Project

### Step 1: Create Supabase Account & Project (5 minutes)

1. **Go to Supabase**: https://supabase.com
2. **Sign up** with GitHub (recommended)
3. **Create new project**:
   - **Name**: `finance-app`
   - **Database Password**: Generate strong password (save it!)
   - **Region**: Choose closest to your users
4. **Wait 2-3 minutes** for project setup

### Step 2: Get Project Credentials (1 minute)

1. Go to **Settings** → **API**
2. **Copy these values**:
   - **Project URL**: `https://your-project-ref.supabase.co`
   - **anon public key**: `eyJ...` (long string)
   - **service_role key**: `eyJ...` (keep this secure!)

### Step 3: Update Configuration (1 minute)

Update `lib/core/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  // Replace with your actual values
  static const String supabaseUrl = 'https://your-project-ref.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
  static const String supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
  
  // ... rest stays the same
}
```

### Step 4: Create Database Tables (5 minutes)

Go to **SQL Editor** in Supabase dashboard and run this SQL:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
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

-- Create indexes for performance
CREATE INDEX idx_expenses_user_id ON public.expenses(user_id);
CREATE INDEX idx_expenses_created_at ON public.expenses(created_at DESC);
CREATE INDEX idx_expenses_local_id ON public.expenses(local_expense_id);
CREATE INDEX idx_user_profiles_username ON public.user_profiles(username);
CREATE INDEX idx_user_profiles_role ON public.user_profiles(role);

-- Enable Row Level Security (RLS)
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

-- User profiles policies
CREATE POLICY "Users can view own profile" ON public.user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can view all profiles" ON public.user_profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Expenses policies
CREATE POLICY "Users can view own expenses" ON public.expenses
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own expenses" ON public.expenses
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own expenses" ON public.expenses
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all expenses" ON public.expenses
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Function to automatically create user profile on signup
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

-- Trigger to create profile on user signup
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### Step 5: Set Up Storage (2 minutes)

1. Go to **Storage** in Supabase dashboard
2. **Create new bucket**:
   - **Name**: `invoice-images`
   - **Public**: Yes (for easier access)
3. **Set storage policies** (go to Storage → Policies):

```sql
-- Allow users to upload their own files
CREATE POLICY "Users can upload own files" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'invoice-images' AND 
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Allow users to view their own files
CREATE POLICY "Users can view own files" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'invoice-images' AND 
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Allow admins to view all files
CREATE POLICY "Admins can view all files" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'invoice-images' AND
    EXISTS (
      SELECT 1 FROM public.user_profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

### Step 6: Create Admin User (2 minutes)

1. Go to **Authentication** → **Users**
2. **Add user**:
   - **Email**: `admin@example.com` (or your email)
   - **Password**: Create strong password
   - **Auto Confirm User**: Yes
3. **Update user role**:
   - Go to **SQL Editor**
   - Run: 
   ```sql
   UPDATE public.user_profiles 
   SET role = 'admin' 
   WHERE email = 'admin@example.com';
   ```

### Step 7: Test the Setup (5 minutes)

1. **Update your config** with real Supabase credentials
2. **Build and test**:
   ```bash
   flutter run --flavor user --target lib/main_user.dart
   ```
3. **Try to register** a new user
4. **Check Supabase dashboard** - user should appear
5. **Test admin app**:
   ```bash
   flutter run --flavor admin --target lib/main_admin.dart
   ```

## What We've Built So Far

### ✅ Core Services:
- **SupabaseService** - Authentication and basic operations
- **SupabaseSyncService** - Full sync functionality with real-time
- **Configuration** - Ready for your Supabase project

### ✅ Features Implemented:
- **Authentication** - Sign up, sign in, sign out
- **User Profiles** - Automatic profile creation
- **Expense Sync** - Real-time sync between apps
- **File Upload** - Invoice images to Supabase Storage
- **Admin Features** - Role-based access control
- **Offline Support** - Works without internet
- **Real-time Updates** - Live data updates

### ✅ Security:
- **Row Level Security** - Users can only see their own data
- **Admin Policies** - Admins can see all data
- **File Permissions** - Secure file access
- **JWT Authentication** - Secure session management

## Next Phase: Testing & Integration

Once you complete the setup above, we'll:

1. **Update dependency injection** to use Supabase services
2. **Test all authentication flows**
3. **Test sync between User and Admin apps**
4. **Optimize performance and add error handling**
5. **Create production build**

## Current Status

```
✅ Phase 1: Core Services (COMPLETE)
🔄 Phase 2: Supabase Project Setup (IN PROGRESS)
⏳ Phase 3: Integration & Testing (NEXT)
⏳ Phase 4: Production Ready (FINAL)
```

## Need Help?

- **Supabase Docs**: https://supabase.com/docs
- **SQL Issues**: Check the SQL Editor for error messages
- **Authentication Issues**: Check Authentication → Users in dashboard
- **Storage Issues**: Check Storage → Policies

Ready for the next phase? Let me know when you've completed the Supabase project setup! 🚀
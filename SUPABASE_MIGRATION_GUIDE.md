# Supabase Migration Guide

## Overview

This guide helps you create a Supabase version of your finance app. Your current app uses:
- **SQLite** for local storage
- **PocketBase** for cloud sync

The Supabase version will use:
- **SQLite** for local storage (same)
- **Supabase** for cloud sync (instead of PocketBase)

## Why Migrate to Supabase?

### Advantages of Supabase:
- ✅ **Managed Infrastructure** - No server deployment needed
- ✅ **PostgreSQL** - More powerful than SQLite
- ✅ **Built-in Auth** - Advanced authentication features
- ✅ **Real-time** - Live data updates
- ✅ **Storage** - File uploads built-in
- ✅ **Auto-scaling** - Handles growth automatically
- ✅ **Better Dashboard** - Rich admin interface
- ✅ **Row Level Security** - Advanced permissions

### Current PocketBase vs Supabase:
| Feature | PocketBase | Supabase |
|---------|------------|----------|
| **Hosting** | Self-hosted | Managed |
| **Database** | SQLite | PostgreSQL |
| **Setup Time** | 30 min | 15 min |
| **Scaling** | Manual | Automatic |
| **Auth Features** | Basic | Advanced |
| **Real-time** | Yes | Yes |
| **Free Tier** | Depends on host | Very generous |

---

## Migration Strategy

### Phase 1: Analysis (Current State)
1. Document current database schema
2. Map PocketBase collections to Supabase tables
3. Identify authentication flows
4. List file storage requirements

### Phase 2: Supabase Setup
1. Create Supabase project
2. Set up database tables
3. Configure authentication
4. Set up storage buckets
5. Configure Row Level Security (RLS)

### Phase 3: Code Migration
1. Replace PocketBase service with Supabase client
2. Update authentication logic
3. Migrate sync services
4. Update storage services
5. Test all functionality

### Phase 4: Testing & Deployment
1. Test all features
2. Migrate existing data (if needed)
3. Deploy and monitor

---

## Current Database Schema Analysis

### SQLite Tables (Local):
Based on your code, you have these local tables:

1. **users** - User accounts and profiles
2. **expenses** - Expense records
3. **incoming** - Income records  
4. **transfers** - Transfer records
5. **fund_box** - Fund box records

### PocketBase Collections (Cloud):
1. **users** - User authentication and profiles
2. **expenses** - Synced expense data

### Key Fields to Map:
```sql
-- Expenses table structure
CREATE TABLE expenses (
  id INTEGER PRIMARY KEY,
  user_id INTEGER,
  description TEXT,
  price_usd REAL,
  price_syp REAL,
  price_try REAL,
  invoice_status INTEGER,
  invoice_file_path TEXT,
  invoice_cloud_file_id TEXT,
  expense_date TEXT,
  created_at TEXT,
  sync_status INTEGER,
  sync_retry_count INTEGER,
  sync_error_message TEXT,
  synced_at TEXT,
  creator_username TEXT,
  creator_email TEXT
);
```

---

## Step 1: Create Supabase Project

### 1.1 Sign Up & Create Project
1. Go to https://supabase.com
2. Sign up with GitHub (recommended)
3. Click "New Project"
4. Fill in:
   - **Name**: `finance-app`
   - **Database Password**: Generate strong password
   - **Region**: Choose closest to your users
5. Click "Create new project"
6. Wait 2-3 minutes for setup

### 1.2 Get Project Credentials
1. Go to **Settings** → **API**
2. Copy these values:
   - **Project URL**: `https://your-project.supabase.co`
   - **anon public key**: `eyJ...` (for client-side)
   - **service_role key**: `eyJ...` (for admin operations)

---

## Step 2: Set Up Database Tables

### 2.1 Create Tables in Supabase

Go to **Database** → **SQL Editor** and run:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE public.user_profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  username TEXT UNIQUE,
  email TEXT,
  role TEXT DEFAULT 'user',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Expenses table
CREATE TABLE public.expenses (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  local_expense_id INTEGER, -- Reference to local SQLite ID
  description TEXT NOT NULL,
  price_usd DECIMAL(10,2),
  price_syp DECIMAL(15,2),
  price_try DECIMAL(10,2),
  invoice_status INTEGER DEFAULT 0,
  invoice_file_id UUID, -- Reference to storage file
  expense_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  synced_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  creator_username TEXT,
  creator_email TEXT
);

-- Incoming table (if you want to sync income too)
CREATE TABLE public.incoming (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  local_incoming_id INTEGER,
  description TEXT NOT NULL,
  price_usd DECIMAL(10,2),
  price_syp DECIMAL(15,2),
  price_try DECIMAL(10,2),
  incoming_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Transfers table (if you want to sync transfers)
CREATE TABLE public.transfers (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  local_transfer_id INTEGER,
  description TEXT NOT NULL,
  amount DECIMAL(10,2),
  currency TEXT,
  transfer_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_expenses_user_id ON public.expenses(user_id);
CREATE INDEX idx_expenses_created_at ON public.expenses(created_at);
CREATE INDEX idx_incoming_user_id ON public.incoming(user_id);
CREATE INDEX idx_transfers_user_id ON public.transfers(user_id);
```

### 2.2 Set Up Row Level Security (RLS)

```sql
-- Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incoming ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transfers ENABLE ROW LEVEL SECURITY;

-- User profiles policies
CREATE POLICY "Users can view own profile" ON public.user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
  FOR UPDATE USING (auth.uid() = id);

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

-- Similar policies for incoming and transfers
CREATE POLICY "Users can manage own incoming" ON public.incoming
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own transfers" ON public.transfers
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all incoming" ON public.incoming
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can view all transfers" ON public.transfers
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

---

## Step 3: Set Up Storage

### 3.1 Create Storage Bucket

1. Go to **Storage** in Supabase dashboard
2. Click "New bucket"
3. Name: `invoice-images`
4. Set as **Public** (for easier access)
5. Click "Create bucket"

### 3.2 Set Storage Policies

Go to **Storage** → **Policies** → **invoice-images**:

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

---

## Step 4: Code Migration

### 4.1 Add Supabase Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  supabase_flutter: ^2.3.4
  # Remove pocketbase dependency when ready
  # pocketbase: ^0.18.2
```

### 4.2 Create Supabase Configuration

Create `lib/core/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
  
  // For admin operations (keep secure!)
  static const String supabaseServiceKey = 'your-service-key';
  
  // Storage
  static const String invoicesBucket = 'invoice-images';
}
```

### 4.3 Create Supabase Service

Create `lib/core/services/supabase_service.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();
  
  late final SupabaseClient client;
  
  Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    client = Supabase.instance.client;
  }
  
  // Auth helpers
  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  
  // Sign in
  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  // Sign up
  Future<AuthResponse> signUp(String email, String password, String username) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
    );
    
    if (response.user != null) {
      // Create user profile
      await client.from('user_profiles').insert({
        'id': response.user!.id,
        'username': username,
        'email': email,
        'role': 'user',
      });
    }
    
    return response;
  }
  
  // Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }
  
  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await client
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }
}
```

### 4.4 Create Supabase Sync Service

Create `lib/core/services/supabase_sync_service.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/expenses/domain/entities/expense.dart';
import '../error/failures.dart';
import '../models/sync_status.dart';
import 'supabase_service.dart';
import 'sync_service.dart';

class SupabaseSyncService implements SyncService {
  final SupabaseService _supabaseService;
  
  SupabaseSyncService(this._supabaseService);
  
  @override
  Future<Either<Failure, void>> syncExpense(Expense expense) async {
    try {
      if (!_supabaseService.isAuthenticated) {
        return const Left(UnauthorizedFailure('User not authenticated'));
      }
      
      final user = _supabaseService.currentUser!;
      
      // Upload invoice image if exists
      String? fileId;
      if (expense.invoiceFilePath != null) {
        fileId = await _uploadInvoiceImage(
          expense.invoiceFilePath!,
          user.id,
          expense.id!,
        );
      }
      
      // Insert expense to Supabase
      await _supabaseService.client.from('expenses').insert({
        'user_id': user.id,
        'local_expense_id': expense.id,
        'description': expense.description,
        'price_usd': expense.priceUsd,
        'price_syp': expense.priceSyp,
        'price_try': expense.priceTry,
        'invoice_status': expense.invoiceStatus.index,
        'invoice_file_id': fileId,
        'expense_date': expense.expenseDate.toIso8601String(),
        'creator_username': user.userMetadata?['username'],
        'creator_email': user.email,
      });
      
      return const Right(null);
    } catch (e) {
      return Left(SyncFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, List<Expense>>> fetchAdminExpenses() async {
    try {
      if (!_supabaseService.isAuthenticated) {
        return const Left(UnauthorizedFailure('User not authenticated'));
      }
      
      // Check if user is admin
      final userProfile = await _supabaseService.getUserProfile(
        _supabaseService.currentUser!.id,
      );
      
      if (userProfile?['role'] != 'admin') {
        return const Left(UnauthorizedFailure('Admin access required'));
      }
      
      // Fetch all expenses
      final response = await _supabaseService.client
          .from('expenses')
          .select()
          .order('created_at', ascending: false);
      
      final expenses = response.map<Expense>((data) {
        return Expense(
          id: data['local_expense_id'] as int,
          userId: data['user_id'] as String, // Note: UUID instead of int
          description: data['description'] as String,
          priceUsd: (data['price_usd'] as num?)?.toDouble(),
          priceSyp: (data['price_syp'] as num?)?.toDouble(),
          priceTry: (data['price_try'] as num?)?.toDouble(),
          invoiceStatus: InvoiceStatus.values[data['invoice_status'] as int],
          invoiceCloudFileId: data['invoice_file_id'] as String?,
          expenseDate: DateTime.parse(data['expense_date'] as String),
          createdAt: DateTime.parse(data['created_at'] as String),
          syncStatus: SyncStatus.synced,
          syncedAt: DateTime.parse(data['synced_at'] as String),
          creatorUsername: data['creator_username'] as String?,
          creatorEmail: data['creator_email'] as String?,
        );
      }).toList();
      
      return Right(expenses);
    } catch (e) {
      return Left(SyncFailure(e.toString()));
    }
  }
  
  Future<String> _uploadInvoiceImage(
    String localPath,
    String userId,
    int expenseId,
  ) async {
    final fileName = '$userId/$expenseId-${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    await _supabaseService.client.storage
        .from('invoice-images')
        .upload(fileName, File(localPath));
    
    return fileName;
  }
  
  // Implement other SyncService methods...
}
```

---

## Step 5: Update Main Files

### 5.1 Update main_user.dart and main_admin.dart

```dart
import 'package:flutter/material.dart';
import 'core/config/flavor_config.dart';
import 'core/services/supabase_service.dart';
import 'injection_container.dart' as di;
import 'main.dart' as app;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize user flavor
  FlavorConfig.initialize(AppFlavor.user);
  
  // Initialize Supabase
  await SupabaseService().initialize();
  
  // Initialize dependencies
  await di.initializeDependencies();
  
  runApp(const app.MyApp());
}
```

### 5.2 Update Dependency Injection

In `injection_container.dart`, replace PocketBase services with Supabase:

```dart
// Replace PocketBase registrations with Supabase
sl.registerLazySingleton<SupabaseService>(() => SupabaseService());
sl.registerLazySingleton<SyncService>(() => SupabaseSyncService(sl()));

// Update auth repository to use Supabase
// ... update other services
```

---

## Step 6: Testing Migration

### 6.1 Create Test Plan

1. **Authentication Tests**:
   - [ ] User registration
   - [ ] User login
   - [ ] User logout
   - [ ] Admin role verification

2. **Sync Tests**:
   - [ ] Expense sync from user app
   - [ ] Expense fetch in admin app
   - [ ] File upload/download
   - [ ] Offline/online sync

3. **Data Integrity Tests**:
   - [ ] All expense fields sync correctly
   - [ ] Currency values maintain precision
   - [ ] Dates are handled correctly
   - [ ] File associations work

### 6.2 Migration Testing Steps

1. **Set up test environment**:
   ```bash
   # Create new branch for Supabase version
   git checkout -b supabase-migration
   ```

2. **Implement changes incrementally**:
   - Start with authentication
   - Then basic sync
   - Then file uploads
   - Finally admin features

3. **Test each component**:
   ```bash
   # Run tests after each change
   flutter test
   ```

---

## Step 7: Deployment Strategy

### 7.1 Parallel Deployment

Keep both versions running:

1. **PocketBase version** (current):
   - Branch: `main`
   - APK: `finance-app-pocketbase.apk`

2. **Supabase version** (new):
   - Branch: `supabase-migration`
   - APK: `finance-app-supabase.apk`

### 7.2 User Migration

For existing users:

1. **Export data** from PocketBase version
2. **Import data** to Supabase version
3. **Gradual rollout** to test users
4. **Full migration** when stable

---

## Step 8: Comparison & Benefits

### Performance Comparison

| Metric | PocketBase | Supabase |
|--------|------------|----------|
| **Setup Time** | 30 min | 15 min |
| **Maintenance** | Manual | Automatic |
| **Scaling** | Manual | Automatic |
| **Backup** | Manual | Automatic |
| **Monitoring** | Basic | Advanced |
| **Security** | Manual | Built-in |

### Cost Comparison

| Usage | PocketBase (Fly.io) | Supabase |
|-------|-------------------|----------|
| **Development** | Free | Free |
| **Small Scale** | Free | Free |
| **Medium Scale** | $5-10/month | Free |
| **Large Scale** | $20+/month | $25/month |

### Feature Comparison

| Feature | PocketBase | Supabase |
|---------|------------|----------|
| **Real-time** | ✅ Yes | ✅ Yes |
| **Auth** | ✅ Basic | ✅ Advanced |
| **Storage** | ✅ Yes | ✅ Yes |
| **Dashboard** | ✅ Basic | ✅ Rich |
| **API** | ✅ REST | ✅ REST + GraphQL |
| **Edge Functions** | ❌ No | ✅ Yes |
| **Extensions** | ❌ Limited | ✅ Many |

---

## Conclusion

### When to Choose Supabase:

✅ **Choose Supabase if**:
- You want managed infrastructure
- You need advanced auth features
- You plan to scale significantly
- You want rich dashboard/analytics
- You prefer PostgreSQL over SQLite
- You want automatic backups/monitoring

✅ **Keep PocketBase if**:
- You prefer full control
- You have simple requirements
- You want to minimize dependencies
- You're comfortable with server management
- You need custom backend logic

### Migration Timeline:

- **Week 1**: Set up Supabase project and tables
- **Week 2**: Implement authentication migration
- **Week 3**: Implement sync service migration
- **Week 4**: Testing and refinement
- **Week 5**: Deployment and user migration

### Next Steps:

1. **Start with Supabase setup** (Step 1-3)
2. **Create a test branch** for migration
3. **Implement authentication first**
4. **Test thoroughly** before full migration
5. **Keep both versions** until confident

Your current PocketBase implementation provides an excellent foundation for the Supabase migration. The clean architecture you've built makes this transition much easier!
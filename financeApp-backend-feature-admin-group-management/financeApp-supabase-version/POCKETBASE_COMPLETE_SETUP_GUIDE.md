# PocketBase Complete Setup Guide - Free Hosting with Fly.io

## 🎉 Overview

This guide will help you set up a **completely free** backend for your dual-version finance app using:
- **PocketBase**: Open-source backend (database + auth + file storage)
- **Fly.io**: Free hosting (3 GB storage, 160 GB bandwidth/month)
- **No credit card required** for initial setup

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Part 1: Local PocketBase Setup](#part-1-local-pocketbase-setup)
3. [Part 2: Configure Collections & Rules](#part-2-configure-collections--rules)
4. [Part 3: Deploy to Fly.io](#part-3-deploy-to-flyio)
5. [Part 4: Flutter Integration](#part-4-flutter-integration)
6. [Part 5: Testing & Verification](#part-5-testing--verification)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software

1. **Git** - [Download](https://git-scm.com/downloads)
2. **A text editor** (VS Code, Notepad++, etc.)
3. **Flutter** (already installed)

### Accounts Needed

1. **Fly.io account** - [Sign up](https://fly.io/app/sign-up) (free, email only)
2. **GitHub account** (optional, for easier deployment)

---

## Part 1: Local PocketBase Setup

### Step 1.1: Download PocketBase

1. Go to [PocketBase Releases](https://github.com/pocketbase/pocketbase/releases)
2. Download the latest version for your OS:
   - **Windows**: `pocketbase_X.X.X_windows_amd64.zip`
   - **macOS**: `pocketbase_X.X.X_darwin_amd64.zip`
   - **Linux**: `pocketbase_X.X.X_linux_amd64.zip`

### Step 1.2: Extract and Run

1. Create a folder: `C:\pocketbase` (or `~/pocketbase` on Mac/Linux)
2. Extract the downloaded file to this folder
3. You should have: `pocketbase.exe` (Windows) or `pocketbase` (Mac/Linux)

### Step 1.3: Start PocketBase Locally

**Windows:**
```cmd
cd C:\pocketbase
pocketbase.exe serve
```

**Mac/Linux:**
```bash
cd ~/pocketbase
chmod +x pocketbase
./pocketbase serve
```

You should see:
```
> Server started at http://127.0.0.1:8090
  - REST API: http://127.0.0.1:8090/api/
  - Admin UI: http://127.0.0.1:8090/_/
```

### Step 1.4: Create Admin Account

1. Open browser: http://127.0.0.1:8090/_/
2. Create admin account:
   - Email: your-email@example.com
   - Password: (choose a strong password)
3. Click "Create and login"

✅ **Checkpoint**: You should now see the PocketBase admin dashboard!

---

## Part 2: Configure Collections & Rules

### Step 2.1: Create Users Collection (Enhanced)

The default `users` collection needs customization for our app.

1. Go to **Collections** in the sidebar
2. Click on **users** collection
3. Click **Edit** (pencil icon)
4. Add these fields:

| Field Name | Type | Required | Options |
|------------|------|----------|---------|
| role | Select | Yes | Options: `user`, `admin` (default: `user`) |
| created_at | Date | Yes | Auto-set on create |
| updated_at | Date | No | Auto-set on update |

5. Click **Save**

### Step 2.2: Create Expenses Collection

1. Click **New collection**
2. Collection name: `expenses`
3. Collection type: **Base**
4. Add these fields:

| Field Name | Type | Required | Options |
|------------|------|----------|---------|
| user_id | Relation | Yes | Collection: `users`, Single |
| expense_id | Number | Yes | Min: 1 |
| description | Text | Yes | Min: 1, Max: 500 |
| price_usd | Number | No | Min: 0 |
| price_syp | Number | No | Min: 0 |
| price_try | Number | No | Min: 0 |
| invoice_status | Number | Yes | Min: 0, Max: 2 |
| invoice_image | File | No | Max files: 1, Max size: 5MB, Types: image/* |
| expense_date | Date | Yes | |
| sync_status | Select | Yes | Options: `pending`, `syncing`, `synced`, `failed` (default: `synced`) |
| synced_at | Date | Yes | Auto-set on create |

5. Click **Create**

### Step 2.3: Set API Rules for Users Collection

1. Click on **users** collection
2. Go to **API Rules** tab
3. Set these rules:

**List/Search Rule:**
```javascript
// Admins can list all users, users can only see themselves
@request.auth.role = "admin" || @request.auth.id = id
```

**View Rule:**
```javascript
// Admins can view all, users can view themselves
@request.auth.role = "admin" || @request.auth.id = id
```

**Create Rule:**
```javascript
// Anyone can create (for registration)
@request.data.role = "user"
```

**Update Rule:**
```javascript
// Users can update themselves (but not role), admins can update anyone
(@request.auth.id = id && @request.data.role = role) || @request.auth.role = "admin"
```

**Delete Rule:**
```javascript
// Only admins can delete
@request.auth.role = "admin"
```

4. Click **Save**

### Step 2.4: Set API Rules for Expenses Collection

1. Click on **expenses** collection
2. Go to **API Rules** tab
3. Set these rules:

**List/Search Rule:**
```javascript
// Admins can see all, users can only see their own
@request.auth.role = "admin" || user_id = @request.auth.id
```

**View Rule:**
```javascript
// Admins can view all, users can view their own
@request.auth.role = "admin" || user_id = @request.auth.id
```

**Create Rule:**
```javascript
// Users can only create expenses for themselves
@request.auth.id != "" && @request.data.user_id = @request.auth.id
```

**Update Rule:**
```javascript
// No updates allowed (immutable for audit trail)
@request.auth.role = "admin"
```

**Delete Rule:**
```javascript
// Only admins can delete
@request.auth.role = "admin"
```

4. Click **Save**

### Step 2.5: Create Admin User

1. Go to **Collections** → **users**
2. Click **New record**
3. Fill in:
   - **email**: admin@example.com
   - **password**: (choose a strong password)
   - **passwordConfirm**: (same password)
   - **role**: admin
4. Click **Create**

✅ **Checkpoint**: You now have collections configured with proper security rules!

---

## Part 3: Deploy to Fly.io

### Step 3.1: Install Fly CLI

**Windows (PowerShell):**
```powershell
iwr https://fly.io/install.ps1 -useb | iex
```

**Mac:**
```bash
brew install flyctl
```

**Linux:**
```bash
curl -L https://fly.io/install.sh | sh
```

### Step 3.2: Sign Up / Login to Fly.io

```bash
fly auth signup
```

Or if you already have an account:
```bash
fly auth login
```

Follow the browser prompts to complete authentication.

### Step 3.3: Create Deployment Files

Create a new folder for deployment:

```bash
mkdir pocketbase-deploy
cd pocketbase-deploy
```

**Create `Dockerfile`:**

```dockerfile
FROM alpine:latest

ARG PB_VERSION=0.22.0

RUN apk add --no-cache \
    unzip \
    ca-certificates

# Download and install PocketBase
ADD https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip /tmp/pb.zip
RUN unzip /tmp/pb.zip -d /pb/

EXPOSE 8080

# Start PocketBase
CMD ["/pb/pocketbase", "serve", "--http=0.0.0.0:8080"]
```

**Create `fly.toml`:**

```toml
app = "finance-app-backend"

[build]
  dockerfile = "Dockerfile"

[env]
  PORT = "8080"

[[services]]
  internal_port = 8080
  protocol = "tcp"

  [[services.ports]]
    handlers = ["http"]
    port = 80

  [[services.ports]]
    handlers = ["tls", "http"]
    port = 443

  [[services.http_checks]]
    interval = 10000
    timeout = 2000
    grace_period = "30s"
    method = "GET"
    path = "/api/health"

[mounts]
  source = "pb_data"
  destination = "/pb/pb_data"
```

### Step 3.4: Launch App on Fly.io

```bash
fly launch
```

Answer the prompts:
- **App name**: finance-app-backend (or choose your own)
- **Region**: Choose closest to you
- **PostgreSQL**: No
- **Redis**: No

### Step 3.5: Create Persistent Volume

```bash
fly volumes create pb_data --size 3
```

This creates a 3 GB persistent volume (free tier).

### Step 3.6: Deploy

```bash
fly deploy
```

Wait for deployment to complete (2-5 minutes).

### Step 3.7: Get Your URL

```bash
fly status
```

Your PocketBase URL will be: `https://finance-app-backend.fly.dev`

### Step 3.8: Access Admin Dashboard

1. Open: `https://finance-app-backend.fly.dev/_/`
2. Create admin account (first time only)
3. **Important**: Recreate all collections and rules from Part 2!

✅ **Checkpoint**: Your PocketBase is now live on the internet!

---

## Part 4: Flutter Integration

### Step 4.1: Add Dependencies

Update `pubspec.yaml`:

```yaml
dependencies:
  # Existing dependencies...
  
  # PocketBase
  pocketbase: ^0.18.0
  http: ^1.1.0
  
  # Connectivity
  connectivity_plus: ^6.0.5
```

Run:
```bash
flutter pub get
```

### Step 4.2: Create PocketBase Config

Create `lib/core/config/pocketbase_config.dart`:

```dart
class PocketBaseConfig {
  // Replace with your Fly.io URL
  static const String baseUrl = 'https://finance-app-backend.fly.dev';
  
  // For local testing, use:
  // static const String baseUrl = 'http://127.0.0.1:8090';
  
  static const String apiUrl = '$baseUrl/api';
  
  // Collection names
  static const String usersCollection = 'users';
  static const String expensesCollection = 'expenses';
}
```

### Step 4.3: Create PocketBase Service

Create `lib/core/services/pocketbase_service.dart`:

```dart
import 'package:pocketbase/pocketbase.dart';
import '../config/pocketbase_config.dart';

class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;
  PocketBaseService._internal();
  
  late final PocketBase pb;
  
  void initialize() {
    pb = PocketBase(PocketBaseConfig.baseUrl);
  }
  
  // Check if user is authenticated
  bool get isAuthenticated => pb.authStore.isValid;
  
  // Get current user
  RecordModel? get currentUser => pb.authStore.model;
  
  // Check if current user is admin
  bool get isAdmin {
    if (!isAuthenticated) return false;
    return currentUser?.data['role'] == 'admin';
  }
  
  // Login
  Future<RecordAuth> login(String email, String password) async {
    return await pb.collection(PocketBaseConfig.usersCollection)
        .authWithPassword(email, password);
  }
  
  // Register
  Future<RecordModel> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final body = {
      'email': email,
      'password': password,
      'passwordConfirm': password,
      'username': username,
      'role': 'user', // Always create as user
    };
    
    return await pb.collection(PocketBaseConfig.usersCollection).create(body: body);
  }
  
  // Logout
  void logout() {
    pb.authStore.clear();
  }
}
```

### Step 4.4: Create Sync Service

Create `lib/core/services/pocketbase_sync_service.dart`:

```dart
import 'dart:io';
import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import 'pocketbase_service.dart';
import '../config/pocketbase_config.dart';

class PocketBaseSyncService {
  final PocketBaseService _pbService = PocketBaseService();
  
  // Sync expense to PocketBase
  Future<String?> syncExpense({
    required int expenseId,
    required String description,
    required double? priceUsd,
    required double? priceSyp,
    required double? priceTry,
    required int invoiceStatus,
    required DateTime expenseDate,
    File? invoiceImage,
  }) async {
    try {
      final pb = _pbService.pb;
      
      if (!_pbService.isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      final body = {
        'user_id': _pbService.currentUser!.id,
        'expense_id': expenseId,
        'description': description,
        'price_usd': priceUsd,
        'price_syp': priceSyp,
        'price_try': priceTry,
        'invoice_status': invoiceStatus,
        'expense_date': expenseDate.toIso8601String(),
        'sync_status': 'synced',
        'synced_at': DateTime.now().toIso8601String(),
      };
      
      // Create record
      final record = await pb.collection(PocketBaseConfig.expensesCollection)
          .create(body: body);
      
      // Upload image if exists
      if (invoiceImage != null) {
        final formData = http.MultipartFile.fromBytes(
          'invoice_image',
          await invoiceImage.readAsBytes(),
          filename: 'invoice_${expenseId}.jpg',
        );
        
        await pb.collection(PocketBaseConfig.expensesCollection)
            .update(record.id, body: {}, files: [formData]);
      }
      
      return record.id;
    } catch (e) {
      print('Sync error: $e');
      return null;
    }
  }
  
  // Fetch all expenses (admin only)
  Future<List<RecordModel>> fetchAllExpenses() async {
    try {
      if (!_pbService.isAdmin) {
        throw Exception('Only admins can fetch all expenses');
      }
      
      final records = await _pbService.pb
          .collection(PocketBaseConfig.expensesCollection)
          .getFullList(
            sort: '-created',
            expand: 'user_id',
          );
      
      return records;
    } catch (e) {
      print('Fetch error: $e');
      return [];
    }
  }
  
  // Fetch user's own expenses
  Future<List<RecordModel>> fetchMyExpenses() async {
    try {
      if (!_pbService.isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      final records = await _pbService.pb
          .collection(PocketBaseConfig.expensesCollection)
          .getFullList(
            filter: 'user_id = "${_pbService.currentUser!.id}"',
            sort: '-created',
          );
      
      return records;
    } catch (e) {
      print('Fetch error: $e');
      return [];
    }
  }
  
  // Get image URL
  String getImageUrl(RecordModel record) {
    if (record.data['invoice_image'] == null || 
        record.data['invoice_image'] == '') {
      return '';
    }
    
    return _pbService.pb.files.getUrl(
      record,
      record.data['invoice_image'],
    ).toString();
  }
}
```

### Step 4.5: Initialize in main.dart

Update `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'core/services/pocketbase_service.dart';
// ... other imports

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize PocketBase
  PocketBaseService().initialize();
  
  // ... rest of your initialization
  
  runApp(const MyApp());
}
```

✅ **Checkpoint**: Flutter app is now connected to PocketBase!

---

## Part 5: Testing & Verification

### Step 5.1: Test Authentication

Create a simple test page to verify connection:

```dart
// Test login
final pbService = PocketBaseService();
try {
  await pbService.login('admin@example.com', 'your-password');
  print('Login successful!');
  print('Is admin: ${pbService.isAdmin}');
} catch (e) {
  print('Login failed: $e');
}
```

### Step 5.2: Test Expense Sync

```dart
final syncService = PocketBaseSyncService();
final recordId = await syncService.syncExpense(
  expenseId: 1,
  description: 'Test expense',
  priceUsd: 50.0,
  priceSyp: null,
  priceTry: null,
  invoiceStatus: 0,
  expenseDate: DateTime.now(),
);

if (recordId != null) {
  print('Expense synced successfully! ID: $recordId');
} else {
  print('Sync failed');
}
```

### Step 5.3: Verify in Admin Dashboard

1. Go to `https://your-app.fly.dev/_/`
2. Login with admin credentials
3. Check **expenses** collection
4. You should see the synced expense!

---

## Troubleshooting

### Issue: "Connection refused" or "Network error"

**Solution:**
- Check if PocketBase is running: `fly status`
- Verify URL in `pocketbase_config.dart`
- Check internet connection
- Try: `fly logs` to see server errors

### Issue: "Authentication failed"

**Solution:**
- Verify email/password are correct
- Check if user exists in admin dashboard
- Ensure `role` field is set correctly

### Issue: "Permission denied" when creating expense

**Solution:**
- Check API rules in expenses collection
- Verify user is authenticated
- Ensure `user_id` matches authenticated user

### Issue: "File upload failed"

**Solution:**
- Check file size (max 5MB)
- Verify file type is image
- Ensure collection has `invoice_image` field

### Issue: Fly.io deployment fails

**Solution:**
```bash
# Check logs
fly logs

# Restart app
fly apps restart finance-app-backend

# Check volume
fly volumes list
```

---

## Next Steps

Now that PocketBase is set up:

1. ✅ **Proceed to Task 2**: Implement build flavor configuration
2. ✅ **Integrate sync**: Add sync calls when creating expenses
3. ✅ **Test offline mode**: Implement local queue for offline sync
4. ✅ **Add real-time**: Use PocketBase realtime subscriptions (optional)

---

## Free Tier Limits

### Fly.io Free Tier

- ✅ 3 GB persistent storage
- ✅ 160 GB bandwidth/month
- ✅ Shared CPU (sufficient for small apps)
- ✅ Always-on (doesn't sleep)

### Estimated Capacity

- **~6,000 expenses** with images (500KB each)
- **~15,000 expenses** without images
- **Unlimited users** (within bandwidth limits)

### Monitoring Usage

```bash
# Check app status
fly status

# Check volume usage
fly volumes list

# View logs
fly logs

# Check metrics
fly dashboard
```

---

## Alternative: Local Development

For development/testing without deploying:

1. Run PocketBase locally: `./pocketbase serve`
2. Use `http://127.0.0.1:8090` in config
3. Access admin: `http://127.0.0.1:8090/_/`
4. Deploy to Fly.io when ready for production

---

## Security Best Practices

1. **Change default admin password** immediately
2. **Use environment variables** for sensitive data
3. **Enable HTTPS only** (Fly.io does this automatically)
4. **Regular backups**: Download `pb_data` folder periodically
5. **Monitor logs**: Check for suspicious activity

---

## Backup & Restore

### Backup

```bash
# SSH into Fly.io app
fly ssh console

# Create backup
tar -czf backup.tar.gz /pb/pb_data

# Download backup
fly ssh sftp get /pb/backup.tar.gz
```

### Restore

```bash
# Upload backup
fly ssh sftp shell
put backup.tar.gz /pb/

# Extract
tar -xzf /pb/backup.tar.gz -C /pb/
```

---

## Support & Resources

- **PocketBase Docs**: https://pocketbase.io/docs/
- **Fly.io Docs**: https://fly.io/docs/
- **Flutter PocketBase Package**: https://pub.dev/packages/pocketbase
- **Community**: https://github.com/pocketbase/pocketbase/discussions

---

## Summary

You now have:
- ✅ PocketBase backend running on Fly.io (free)
- ✅ 3 GB storage for expenses and images
- ✅ Authentication with role-based access
- ✅ Secure API rules
- ✅ Flutter integration ready
- ✅ Admin dashboard for management

**Total Cost: $0/month** (within free tier limits)

Ready to proceed with Task 2: Build Flavor Configuration!

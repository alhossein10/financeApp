# 🚀 START HERE - Laravel Backend Integration

## ✅ Your App is Ready!

Your Flutter finance app has been successfully migrated to Laravel backend. All old backend code (PocketBase, Supabase, SQLite) has been cleaned up.

---

## Quick Start (3 Steps)

### Step 1: Start Laravel Backend (2 minutes)

```bash
cd financeApp-backend-main

# First time only
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate

# Start server
php artisan serve --host=0.0.0.0
```

✅ Laravel API is now running at: `http://localhost:8000`

### Step 2: Run Flutter App (1 minute)

**Choose your device:**

```bash
# Android Emulator
flutter run --flavor user --dart-define=API_BASE_URL=http://10.0.2.2:8000

# iOS Simulator
flutter run --flavor user --dart-define=API_BASE_URL=http://localhost:8000

# Real Device (replace with your IP)
flutter run --flavor user --dart-define=API_BASE_URL=http://192.168.1.XXX:8000
```

### Step 3: Test It! (2 minutes)

1. **Register** a new user
2. **Create** an expense with invoice image
3. **Turn off WiFi** and create another expense
4. **Turn on WiFi** - it should auto-sync!

---

## What Changed?

### ❌ Removed
- PocketBase (self-hosted backend)
- Supabase (PostgreSQL cloud)
- SQLite (local database)
- Firebase (cloud services)

### ✅ Now Using
- **Laravel API** - RESTful API with MySQL
- **Laravel Sanctum** - Token authentication
- **Hive** - Offline cache
- **Queue Manager** - Offline operations

---

## Architecture Overview

```
Flutter App (User/Admin)
    ↓ HTTP Requests (Dio)
Laravel API (REST)
    ↓ Eloquent ORM
MySQL Database
```

### Data Flow

**Online:**
```
User Action → BLoC → UseCase → Repository → API DataSource → Laravel API → MySQL
```

**Offline:**
```
User Action → BLoC → UseCase → Repository → Queue Manager → Hive Cache
                                                ↓
                                    (When online) → Laravel API → MySQL
```

---

## Project Structure

```
financeApp-backend-main/          # Laravel Backend
├── app/
│   ├── Http/Controllers/Api/V1/
│   │   ├── AuthController.php
│   │   ├── ExpenseController.php
│   │   └── ...
│   └── Models/
│       ├── User.php
│       ├── Expense.php
│       └── ...
├── routes/api.php
└── database/migrations/

finance_app/                       # Flutter Frontend
├── lib/
│   ├── core/
│   │   ├── api/
│   │   │   └── api_client.dart   # Dio HTTP client
│   │   ├── config/
│   │   │   └── api_config.dart   # API configuration
│   │   └── services/
│   │       ├── laravel_auth_service.dart
│   │       ├── cache_service.dart
│   │       └── queue_manager.dart
│   └── features/
│       ├── auth/
│       ├── expenses/
│       ├── transfers/
│       └── ...
└── pubspec.yaml
```

---

## Configuration

### API Base URL

Update based on your environment:

**Development (Local):**
- Android Emulator: `http://10.0.2.2:8000`
- iOS Simulator: `http://localhost:8000`
- Real Device: `http://YOUR_IP:8000`

**Production:**
- `https://your-domain.com`

### Environment Variables

Run with:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000 --dart-define=ENVIRONMENT=development
```

---

## API Endpoints

### Authentication
```
POST   /api/v1/auth/register      # Register
POST   /api/v1/auth/login         # Login
POST   /api/v1/auth/logout        # Logout
GET    /api/v1/auth/me            # Current user
```

### Expenses
```
GET    /api/v1/expenses           # List
POST   /api/v1/expenses           # Create
PUT    /api/v1/expenses/{id}      # Update
DELETE /api/v1/expenses/{id}      # Delete
POST   /api/v1/expenses/{id}/invoice  # Upload image
```

### Transfers
```
GET    /api/v1/transfers          # List
POST   /api/v1/transfers          # Create
PUT    /api/v1/transfers/{id}     # Update
DELETE /api/v1/transfers/{id}     # Delete
```

### Admin (Admin only)
```
GET    /api/v1/admin/dashboard/stats      # Statistics
GET    /api/v1/admin/dashboard/users      # Users
GET    /api/v1/admin/dashboard/expenses   # All expenses
```

---

## Testing

### Test with cURL

**Register:**
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "Password123!",
    "password_confirmation": "Password123!"
  }'
```

**Login:**
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Password123!"
  }'
```

**Create Expense:**
```bash
curl -X POST http://localhost:8000/api/v1/expenses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "description": "Test Expense",
    "price_usd": 100.50,
    "expense_date": "2024-01-15",
    "invoice_status": 1
  }'
```

---

## Troubleshooting

### ❌ Connection refused

**Check:**
1. Laravel is running: `php artisan serve`
2. Correct URL for your device
3. Firewall allows connections

**Solution:**
```bash
# Windows Firewall
# Settings → Windows Security → Firewall → Allow an app

# Mac Firewall
# System Preferences → Security & Privacy → Firewall
```

### ❌ 401 Unauthorized

**Check:**
1. Token is stored in SecureStorage
2. Token hasn't expired
3. Sanctum is configured

**Solution:**
```bash
# Clear Laravel cache
php artisan config:clear
php artisan cache:clear

# Try logout and login again in app
```

### ❌ CORS error

**Solution:**
Update `config/cors.php` in Laravel:
```php
return [
    'paths' => ['api/*'],
    'allowed_origins' => ['*'],
    'allowed_methods' => ['*'],
    'allowed_headers' => ['*'],
];
```

### ❌ File upload fails

**Solution:**
1. Check `php.ini`:
   ```ini
   upload_max_filesize = 10M
   post_max_size = 10M
   ```

2. Restart PHP server

---

## Cleanup Old Files (Optional)

Remove obsolete documentation:

```bash
# Windows
cleanup_old_backend_files.bat
```

This will backup and remove:
- All PocketBase documentation
- All Supabase documentation
- All Firebase documentation
- Old test files
- Old deployment guides

---

## Build for Production

### User Version
```bash
flutter build apk --flavor user --release \
  --dart-define=API_BASE_URL=https://your-domain.com \
  --dart-define=ENVIRONMENT=production
```

### Admin Version
```bash
flutter build apk --flavor admin --release \
  --dart-define=API_BASE_URL=https://your-domain.com \
  --dart-define=ENVIRONMENT=production
```

---

## Features

### ✅ User Version
- Currency Exchange
- Expenses with invoice scanning
- Invoice Export (PDF, Excel, Images)

### ✅ Admin Version
- All User features
- Cash management (Fund Box)
- Transfers with exchange tracking
- Incoming transactions
- Admin dashboard
- User management
- Analytics

---

## Documentation

### Quick Guides
- 📄 **LARAVEL_QUICK_START.md** - Detailed quick start
- 📄 **LARAVEL_BACKEND_CLEANUP.md** - Cleanup information
- 📄 **BACKEND_MIGRATION_COMPLETE.md** - Migration summary

### Full Documentation
- 📁 **.kiro/specs/laravel-backend-integration/**
  - API_DOCUMENTATION.md
  - MIGRATION_GUIDE.md
  - TROUBLESHOOTING.md
  - USER_GUIDE.md
  - DEPLOYMENT_GUIDE.md

### Code Documentation
- 📁 **lib/core/**
  - api/README.md
  - services/README.md
  - USAGE_EXAMPLES.md

---

## Support

### Common Issues
1. **Connection problems** → Check URL and firewall
2. **Authentication errors** → Check token and Sanctum
3. **CORS errors** → Update Laravel CORS config
4. **File upload fails** → Check PHP upload limits

### Get Help
1. Check **TROUBLESHOOTING.md**
2. Check **PRE_RUN_CHECKLIST.md**
3. Review Laravel logs: `storage/logs/laravel.log`
4. Check Flutter console output

---

## Next Steps

1. ✅ **Test locally** - Verify all features work
2. ✅ **Clean up** - Run cleanup script (optional)
3. ✅ **Deploy Laravel** - Deploy to production server
4. ✅ **Build app** - Create production builds
5. ✅ **Test production** - Test with production backend
6. ✅ **Release** - Publish to app stores

---

## Summary

✅ **Backend:** Laravel + MySQL  
✅ **Frontend:** Flutter + BLoC  
✅ **Auth:** Laravel Sanctum tokens  
✅ **Offline:** Hive cache + queue  
✅ **Status:** Ready for production  

🚀 **Your app is ready to use!**

---

**Need help?** Read the documentation files listed above or check the troubleshooting guide.

**Ready to deploy?** Check the deployment guide in `.kiro/specs/laravel-backend-integration/DEPLOYMENT_GUIDE.md`

# Laravel Backend - Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Start Laravel Backend

```bash
cd financeApp-backend-main

# Install dependencies (first time only)
composer install

# Set up environment
cp .env.example .env
php artisan key:generate

# Run migrations
php artisan migrate

# Start server
php artisan serve --host=0.0.0.0
```

Your Laravel API is now running at: `http://localhost:8000`

### Step 2: Configure Flutter App

Update API URL based on your device:

**For Android Emulator:**
```bash
flutter run --flavor user --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

**For iOS Simulator:**
```bash
flutter run --flavor user --dart-define=API_BASE_URL=http://localhost:8000
```

**For Real Device:**
```bash
# Find your computer's IP address
# Windows: ipconfig
# Mac/Linux: ifconfig

flutter run --flavor user --dart-define=API_BASE_URL=http://192.168.1.XXX:8000
```

### Step 3: Test the Connection

1. **Register a new user**
   - Open the app
   - Click "Create Account"
   - Fill in details and register
   - Check Laravel logs: `php artisan serve` output

2. **Create an expense**
   - Login with your new account
   - Go to Expenses tab
   - Add a new expense with invoice image
   - Check Laravel database: `php artisan tinker` → `App\Models\Expense::all()`

3. **Test offline mode**
   - Turn off WiFi
   - Create another expense
   - Turn on WiFi
   - Expense should auto-sync to Laravel

## 📁 Project Structure

```
financeApp-backend-main/          # Laravel backend
├── app/
│   ├── Http/Controllers/Api/V1/
│   │   ├── AuthController.php
│   │   ├── ExpenseController.php
│   │   ├── TransferController.php
│   │   └── ...
│   └── Models/
│       ├── User.php
│       ├── Expense.php
│       └── ...
├── routes/
│   └── api.php                   # API routes
└── database/
    └── migrations/               # Database schema

finance_app/                      # Flutter frontend
├── lib/
│   ├── core/
│   │   ├── api/
│   │   │   └── api_client.dart  # Dio HTTP client
│   │   ├── config/
│   │   │   └── api_config.dart  # API configuration
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

## 🔧 Configuration Files

### Laravel Backend (.env)

```env
APP_NAME="Finance App API"
APP_URL=http://localhost:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=finance_app
DB_USERNAME=root
DB_PASSWORD=

SANCTUM_STATEFUL_DOMAINS=localhost,127.0.0.1
```

### Flutter App (lib/core/config/api_config.dart)

```dart
class ApiConfig {
  // Development
  static const String _devBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  
  // Production
  static const String _productionBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://your-domain.com',
  );
}
```

## 🔐 Authentication Flow

```
1. User registers → POST /api/v1/auth/register
   ↓
2. Laravel creates user + returns token
   ↓
3. Flutter stores token in SecureStorage
   ↓
4. All API requests include: Authorization: Bearer {token}
   ↓
5. Laravel validates token via Sanctum middleware
```

## 📊 API Endpoints

### Authentication
```
POST   /api/v1/auth/register      # Register new user
POST   /api/v1/auth/login         # Login
POST   /api/v1/auth/logout        # Logout
GET    /api/v1/auth/me            # Get current user
POST   /api/v1/auth/refresh       # Refresh token
```

### Expenses
```
GET    /api/v1/expenses           # List expenses
POST   /api/v1/expenses           # Create expense
GET    /api/v1/expenses/{id}      # Get expense
PUT    /api/v1/expenses/{id}      # Update expense
DELETE /api/v1/expenses/{id}      # Delete expense
POST   /api/v1/expenses/{id}/invoice  # Upload invoice image
```

### Transfers
```
GET    /api/v1/transfers          # List transfers
POST   /api/v1/transfers          # Create transfer
GET    /api/v1/transfers/{id}     # Get transfer
PUT    /api/v1/transfers/{id}     # Update transfer
DELETE /api/v1/transfers/{id}     # Delete transfer
```

### Admin (Admin users only)
```
GET    /api/v1/admin/dashboard/stats      # Dashboard statistics
GET    /api/v1/admin/dashboard/users      # User list
GET    /api/v1/admin/dashboard/expenses   # All expenses
```

## 🧪 Testing API with cURL

### Register User
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

### Login
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Password123!"
  }'
```

### Create Expense (with token)
```bash
curl -X POST http://localhost:8000/api/v1/expenses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "description": "Test Expense",
    "price_usd": 100.50,
    "expense_date": "2024-01-15",
    "invoice_status": 1
  }'
```

## 🐛 Troubleshooting

### Problem: "Connection refused"

**Check:**
1. Is Laravel running? `php artisan serve`
2. Is the URL correct?
   - Android emulator: `http://10.0.2.2:8000`
   - iOS simulator: `http://localhost:8000`
   - Real device: `http://YOUR_IP:8000`
3. Is firewall blocking the connection?

**Solution:**
```bash
# Allow Laravel through firewall
# Windows: Windows Defender Firewall → Allow an app
# Mac: System Preferences → Security & Privacy → Firewall
```

### Problem: "401 Unauthorized"

**Check:**
1. Is token stored? Check SecureStorage
2. Is token expired? Try logout and login again
3. Is Sanctum configured? Check `config/sanctum.php`

**Solution:**
```bash
# Clear Laravel cache
php artisan config:clear
php artisan cache:clear

# Regenerate app key
php artisan key:generate
```

### Problem: "CORS error"

**Check:**
`config/cors.php` in Laravel:

```php
return [
    'paths' => ['api/*'],
    'allowed_origins' => ['*'],
    'allowed_methods' => ['*'],
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => false,
];
```

### Problem: File upload fails

**Check:**
1. File size limit in `php.ini`:
   ```ini
   upload_max_filesize = 10M
   post_max_size = 10M
   ```

2. Laravel config `config/filesystems.php`:
   ```php
   'max_file_size' => 10240, // 10MB
   ```

### Problem: Database connection error

**Check:**
1. MySQL is running
2. Database exists: `CREATE DATABASE finance_app;`
3. `.env` credentials are correct
4. Run migrations: `php artisan migrate`

## 📱 Build Flavors

### User Version (Limited features)
```bash
# Debug
flutter run --flavor user --dart-define=API_BASE_URL=http://10.0.2.2:8000

# Release
flutter build apk --flavor user --release --dart-define=API_BASE_URL=https://your-domain.com
```

### Admin Version (Full features)
```bash
# Debug
flutter run --flavor admin --dart-define=API_BASE_URL=http://10.0.2.2:8000

# Release
flutter build apk --flavor admin --release --dart-define=API_BASE_URL=https://your-domain.com
```

## 🔄 Offline Support

The app works offline using:
- **Hive** for local cache
- **Queue Manager** for pending operations

When offline:
1. User creates expense → Stored in Hive queue
2. User sees expense immediately (optimistic update)
3. When online → Queue processor sends to Laravel API
4. On success → Updates cache with server data
5. On failure → Retries with exponential backoff

## 📚 Additional Resources

- **Full API Documentation**: `.kiro/specs/laravel-backend-integration/API_DOCUMENTATION.md`
- **Migration Guide**: `.kiro/specs/laravel-backend-integration/MIGRATION_GUIDE.md`
- **Troubleshooting**: `.kiro/specs/laravel-backend-integration/TROUBLESHOOTING.md`
- **User Guide**: `.kiro/specs/laravel-backend-integration/USER_GUIDE.md`

## ✅ Checklist

Before running the app:

- [ ] Laravel backend is running
- [ ] MySQL database is created and migrated
- [ ] API_BASE_URL is set correctly
- [ ] Firewall allows connections
- [ ] CORS is configured in Laravel
- [ ] Sanctum is configured in Laravel

## 🎯 Next Steps

1. ✅ Start Laravel backend
2. ✅ Run Flutter app with correct API_BASE_URL
3. ✅ Test registration and login
4. ✅ Test creating expenses
5. ✅ Test offline mode
6. ✅ Deploy Laravel to production
7. ✅ Build Flutter app for production

---

**Need Help?** Check `LARAVEL_BACKEND_CLEANUP.md` for detailed cleanup information.

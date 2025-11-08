# 🚀 RUN YOUR APP NOW!

Your Laravel backend is on `http://127.0.0.1:8000` - Perfect!

## ⚡ Quick Start (Choose One)

### Option 1: Use the Batch Script (Easiest)
```bash
run_app.bat
```
Then select option 1 for Android Emulator or option 2 for iOS Simulator.

### Option 2: Direct Command

**For Android Emulator:**
```bash
flutter run --flavor user --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

**For iOS Simulator:**
```bash
flutter run --flavor user --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

**For Admin Version (Android):**
```bash
flutter run --flavor admin --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## 📋 Before You Run - Quick Checklist

1. ✅ **Laravel backend is running**
   ```bash
   # In your Laravel project directory:
   php artisan serve
   ```
   Should show: `Server running on [http://127.0.0.1:8000]`

2. ✅ **CORS is configured** (if not already)
   
   Edit `config/cors.php` in your Laravel project:
   ```php
   'paths' => ['api/*'],
   'allowed_origins' => ['*'],
   'allowed_methods' => ['*'],
   'allowed_headers' => ['*'],
   'supports_credentials' => true,
   ```

3. ✅ **Device/Emulator is running**
   ```bash
   flutter devices
   ```
   Should show your connected device or emulator.

## 🎯 First Time Setup

If this is your first time running:

```bash
# 1. Clean and get dependencies
flutter clean
flutter pub get

# 2. Run the app
flutter run --flavor user --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## 🐛 Troubleshooting

### "Connection refused" Error?

**For Android Emulator:**
- ✅ Use `http://10.0.2.2:8000` (NOT `127.0.0.1`)
- ✅ Make sure Laravel is running: `php artisan serve`

**For iOS Simulator:**
- ✅ Use `http://127.0.0.1:8000`
- ✅ Check firewall isn't blocking connections

**For Real Device:**
1. Find your computer's IP:
   ```bash
   ipconfig  # Windows
   ```
   Look for "IPv4 Address" (e.g., 192.168.1.100)

2. Start Laravel on all interfaces:
   ```bash
   php artisan serve --host=0.0.0.0
   ```

3. Run Flutter with your IP:
   ```bash
   flutter run --flavor user --dart-define=API_BASE_URL=http://YOUR_IP:8000
   ```

### "CORS Error"?

Add to your Laravel `.env`:
```env
SANCTUM_STATEFUL_DOMAINS=localhost,127.0.0.1,10.0.2.2
```

And run:
```bash
php artisan config:clear
php artisan cache:clear
```

### "API endpoint not found"?

Make sure your Laravel routes are set up:
```bash
php artisan route:list | grep api
```

Should show routes like:
- POST /api/v1/auth/register
- POST /api/v1/auth/login
- GET /api/v1/expenses
- etc.

## 📱 What to Test First

Once the app launches:

1. **Register a new user**
   - Tests: POST /api/v1/auth/register
   - Should create user in your Laravel database

2. **Login**
   - Tests: POST /api/v1/auth/login
   - Should return auth token

3. **View Dashboard**
   - Tests: Authenticated GET requests
   - Should show empty state or data

4. **Create an Expense**
   - Tests: POST /api/v1/expenses
   - Should save to database

## 🎉 You're Ready!

Just run:
```bash
flutter run --flavor user --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

The app will:
- ✅ Compile successfully (all errors fixed!)
- ✅ Connect to your Laravel backend
- ✅ Show the welcome/login screen
- ✅ Allow you to register and login

**Good luck! 🚀**

---

**Need help?** Check the logs:
```bash
# Enable debug logging
flutter run --flavor user --dart-define=API_BASE_URL=http://10.0.2.2:8000 --dart-define=DEBUG_LOGGING=true
```

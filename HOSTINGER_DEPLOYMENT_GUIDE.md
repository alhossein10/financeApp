# Complete Guide: Deploy Laravel Backend to Hostinger & Configure Flutter Frontend

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Backend Deployment to Hostinger](#backend-deployment)
3. [Frontend Configuration Changes](#frontend-configuration)
4. [Testing & Verification](#testing-verification)
5. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### What You Need
- ✅ Hostinger account with hosting plan (Business or higher recommended)
- ✅ Laravel backend project ready
- ✅ Flutter frontend project (this project)
- ✅ Domain name (or use Hostinger subdomain)
- ✅ FTP/SFTP client (FileZilla recommended)
- ✅ SSH access (for Composer and Artisan commands)

### Hostinger Plan Requirements
- **Minimum**: Business Hosting Plan
- **Recommended**: Cloud Hosting or VPS
- **Required Features**:
  - PHP 8.1 or higher
  - MySQL database
  - SSH access
  - Composer support
  - SSL certificate (free with Hostinger)

---

## Part 1: Backend Deployment to Hostinger

### Step 1: Prepare Your Laravel Backend

#### 1.1 Update Environment Configuration
Before uploading, prepare your `.env` file:

```env
# Application
APP_NAME="Finance App API"
APP_ENV=production
APP_KEY=base64:YOUR_APP_KEY_HERE
APP_DEBUG=false
APP_URL=https://yourdomain.com

# Database (will get from Hostinger)
DB_CONNECTION=mysql
DB_HOST=localhost
DB_PORT=3306
DB_DATABASE=your_database_name
DB_USERNAME=your_database_user
DB_PASSWORD=your_database_password

# Session & Cache
SESSION_DRIVER=database
CACHE_DRIVER=file
QUEUE_CONNECTION=database

# CORS (Important for Flutter app)
SANCTUM_STATEFUL_DOMAINS=yourdomain.com
SESSION_DOMAIN=.yourdomain.com

# File Storage
FILESYSTEM_DISK=public

# Mail (Optional - for password reset)
MAIL_MAILER=smtp
MAIL_HOST=smtp.hostinger.com
MAIL_PORT=587
MAIL_USERNAME=your-email@yourdomain.com
MAIL_PASSWORD=your-email-password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@yourdomain.com
MAIL_FROM_NAME="${APP_NAME}"
```

#### 1.2 Optimize Laravel for Production
Run these commands locally before uploading:

```bash
# Clear all caches
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# Optimize for production
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Generate optimized autoloader
composer install --optimize-autoloader --no-dev
```

#### 1.3 Update CORS Configuration
Edit `config/cors.php`:

```php
return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    
    'allowed_methods' => ['*'],
    
    'allowed_origins' => ['*'], // Or specify your app domains
    
    'allowed_origins_patterns' => [],
    
    'allowed_headers' => ['*'],
    
    'exposed_headers' => [],
    
    'max_age' => 0,
    
    'supports_credentials' => true,
];
```

---

### Step 2: Setup Hostinger Hosting

#### 2.1 Create MySQL Database

1. **Login to Hostinger hPanel**
2. **Go to**: Websites → Manage → Databases → MySQL Databases
3. **Click**: "Create New Database"
4. **Fill in**:
   - Database name: `u123456789_financeapp`
   - Username: `u123456789_finance`
   - Password: (generate strong password)
5. **Save credentials** - you'll need them for `.env`

#### 2.2 Get Database Connection Details

After creating database, note:
```
DB_HOST: localhost (or specific hostname shown)
DB_PORT: 3306
DB_DATABASE: u123456789_financeapp
DB_USERNAME: u123456789_finance
DB_PASSWORD: [your generated password]
```

#### 2.3 Setup Domain/Subdomain

**Option A: Use Main Domain**
- Your API will be at: `https://yourdomain.com/api/v1`

**Option B: Create Subdomain (Recommended)**
1. Go to: Domains → Subdomains
2. Create: `api.yourdomain.com`
3. Point to: `public_html/api` (or custom folder)
4. Your API will be at: `https://api.yourdomain.com/api/v1`

---

### Step 3: Upload Laravel Files

#### 3.1 Connect via FTP/SFTP

**Using FileZilla:**
```
Host: ftp.yourdomain.com (or IP from hPanel)
Username: your_hostinger_username
Password: your_hostinger_password
Port: 21 (FTP) or 22 (SFTP)
```

#### 3.2 Upload Structure

**Important**: Laravel's `public` folder should be your web root.

**Option A: Root Domain Setup**
```
public_html/
├── .env                    (upload here)
├── app/                    (upload here)
├── bootstrap/              (upload here)
├── config/                 (upload here)
├── database/               (upload here)
├── resources/              (upload here)
├── routes/                 (upload here)
├── storage/                (upload here)
├── vendor/                 (upload here)
├── artisan                 (upload here)
├── composer.json           (upload here)
├── composer.lock           (upload here)
└── [Laravel public folder contents in public_html root]
```

**Option B: Subdomain Setup (Recommended)**
```
public_html/
└── api/                    (create this folder)
    ├── .env
    ├── app/
    ├── bootstrap/
    ├── config/
    ├── database/
    ├── resources/
    ├── routes/
    ├── storage/
    ├── vendor/
    ├── artisan
    ├── composer.json
    ├── composer.lock
    └── public/             (point subdomain here)
        ├── index.php
        ├── .htaccess
        └── [other public files]
```

#### 3.3 Upload Files
1. Upload all Laravel files EXCEPT `node_modules`
2. Upload `.env` file (with production settings)
3. Ensure `storage` and `bootstrap/cache` folders are uploaded

---

### Step 4: Configure Hostinger Server

#### 4.1 Set Correct Permissions via SSH

Connect via SSH:
```bash
ssh your_username@yourdomain.com
```

Set permissions:
```bash
# Navigate to your Laravel directory
cd public_html/api  # or your Laravel root

# Set storage permissions
chmod -R 775 storage
chmod -R 775 bootstrap/cache

# Set ownership (replace 'username' with your Hostinger username)
chown -R username:username storage
chown -R username:username bootstrap/cache
```

#### 4.2 Install/Update Composer Dependencies

```bash
# If composer is not available globally, use:
php composer.phar install --optimize-autoloader --no-dev

# Or if composer is available:
composer install --optimize-autoloader --no-dev
```

#### 4.3 Generate Application Key

```bash
php artisan key:generate
```

#### 4.4 Run Database Migrations

```bash
# Run migrations
php artisan migrate --force

# Seed database (if needed)
php artisan db:seed --force
```

#### 4.5 Create Storage Link

```bash
php artisan storage:link
```

#### 4.6 Optimize for Production

```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

---

### Step 5: Configure .htaccess

#### 5.1 Root .htaccess (if using root domain)

Create/edit `public_html/.htaccess`:

```apache
<IfModule mod_rewrite.c>
    RewriteEngine On
    
    # Redirect to HTTPS
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
    
    # Handle Authorization Header
    RewriteCond %{HTTP:Authorization} .
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
    
    # Redirect all requests to public/index.php
    RewriteRule ^(.*)$ public/$1 [L]
</IfModule>
```

#### 5.2 Public .htaccess

Ensure `public/.htaccess` has:

```apache
<IfModule mod_rewrite.c>
    <IfModule mod_negotiation.c>
        Options -MultiViews -Indexes
    </IfModule>

    RewriteEngine On

    # Handle Authorization Header
    RewriteCond %{HTTP:Authorization} .
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

    # Redirect Trailing Slashes If Not A Folder...
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_URI} (.+)/$
    RewriteRule ^ %1 [L,R=301]

    # Send Requests To Front Controller...
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]
</IfModule>
```

---

### Step 6: Enable SSL Certificate

#### 6.1 Install Free SSL (Let's Encrypt)

1. Go to: hPanel → SSL
2. Select your domain
3. Click "Install SSL"
4. Wait 5-10 minutes for activation

#### 6.2 Force HTTPS

Add to `.env`:
```env
APP_URL=https://yourdomain.com
ASSET_URL=https://yourdomain.com
```

---

### Step 7: Test Backend API

#### 7.1 Test Basic Endpoint

Open browser or use curl:
```bash
curl https://yourdomain.com/api/v1/auth/login
```

Expected response:
```json
{
    "message": "The given data was invalid.",
    "errors": {
        "email": ["The email field is required."],
        "password": ["The password field is required."]
    }
}
```

This confirms API is working!

#### 7.2 Test Registration

```bash
curl -X POST https://yourdomain.com/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }'
```

---

## Part 2: Frontend Configuration Changes

### Step 1: Update API Configuration

#### 1.1 Create Environment-Specific Build Scripts

Create `build_with_production_api.bat`:

```batch
@echo off
echo Building Flutter app with production API...

REM Set production API URL
set API_BASE_URL=https://yourdomain.com
set ENVIRONMENT=production

echo API URL: %API_BASE_URL%
echo Environment: %ENVIRONMENT%

REM Build APK with environment variables
flutter build apk --release ^
  --dart-define=API_BASE_URL=%API_BASE_URL% ^
  --dart-define=ENVIRONMENT=%ENVIRONMENT% ^
  --flavor user ^
  -t lib/main_user.dart

echo.
echo Build complete!
pause
```

Create `build_admin_production_api.bat`:

```batch
@echo off
echo Building Admin app with production API...

REM Set production API URL
set API_BASE_URL=https://yourdomain.com
set ENVIRONMENT=production

echo API URL: %API_BASE_URL%
echo Environment: %ENVIRONMENT%

REM Build Admin APK with environment variables
flutter build apk --release ^
  --dart-define=API_BASE_URL=%API_BASE_URL% ^
  --dart-define=ENVIRONMENT=%ENVIRONMENT% ^
  --split-per-abi ^
  --obfuscate ^
  --split-debug-info=build/debug-info-admin-prod ^
  --flavor admin ^
  -t lib/main_admin.dart

echo.
echo Admin build complete!
echo APKs are in: build\app\outputs\flutter-apk\
pause
```

#### 1.2 Create Staging Build Scripts (Optional)

Create `build_with_staging_api.bat`:

```batch
@echo off
echo Building Flutter app with staging API...

REM Set staging API URL
set API_BASE_URL=https://staging.yourdomain.com
set ENVIRONMENT=staging

flutter build apk --release ^
  --dart-define=API_BASE_URL=%API_BASE_URL% ^
  --dart-define=ENVIRONMENT=%ENVIRONMENT% ^
  --flavor user ^
  -t lib/main_user.dart

pause
```

---

### Step 2: Update API Config Documentation

#### 2.1 Document API URLs

Create `API_CONFIGURATION.md`:

```markdown
# API Configuration

## Current API Endpoints

### Development (Local)
- URL: `http://localhost:8000`
- Use for: Local development and testing
- Build: `flutter run` (uses default)

### Staging (Optional)
- URL: `https://staging.yourdomain.com`
- Use for: Pre-production testing
- Build: `build_with_staging_api.bat`

### Production (Hostinger)
- URL: `https://yourdomain.com`
- Use for: Live app distribution
- Build: `build_with_production_api.bat`

## Building for Different Environments

### Development Build
```bash
flutter run
# Uses: http://localhost:8000
```

### Production Build (User)
```bash
build_with_production_api.bat
# Uses: https://yourdomain.com
```

### Production Build (Admin)
```bash
build_admin_production_api.bat
# Uses: https://yourdomain.com
```

## Changing API URL

### Method 1: Build-time Configuration (Recommended)
Use the build scripts above with `--dart-define`

### Method 2: Manual Override
Edit `lib/core/config/api_config.dart`:
```dart
static const String _productionBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://yourdomain.com', // Change this
);
```

## Verification

After building, verify API URL:
1. Install APK on device
2. Try to login
3. Check network logs for API calls
4. Should see: `https://yourdomain.com/api/v1/...`
```

---

### Step 3: Network Security Configuration (Android)

#### 3.1 Update Network Security Config

The app should already support HTTPS, but verify:

Check `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:usesCleartextTraffic="false"
    ...>
```

If you need to support both HTTP (dev) and HTTPS (prod), create:

`android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- Production: Only HTTPS -->
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
    
    <!-- Development: Allow localhost -->
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">localhost</domain>
        <domain includeSubdomains="true">10.0.2.2</domain>
        <domain includeSubdomains="true">192.168.1.1</domain>
    </domain-config>
</network-security-config>
```

Reference it in `AndroidManifest.xml`:

```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ...>
```

---

### Step 4: Build Production APKs

#### 4.1 Build User APK

```bash
build_with_production_api.bat
```

Output: `build\app\outputs\flutter-apk\app-user-release.apk`

#### 4.2 Build Admin APK

```bash
build_admin_production_api.bat
```

Output: 
- `app-admin-arm64-v8a-release.apk` (~30 MB)
- `app-admin-armeabi-v7a-release.apk` (~28 MB)
- `app-admin-x86_64-release.apk` (~32 MB)

---

## Part 3: Testing & Verification

### Step 1: Backend API Testing

#### 1.1 Test Health Check

```bash
curl https://yourdomain.com/api/v1/auth/login
```

Should return validation error (means API is working).

#### 1.2 Test Registration

```bash
curl -X POST https://yourdomain.com/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "role": "user"
  }'
```

Should return success with token.

#### 1.3 Test Authentication

```bash
# Login
curl -X POST https://yourdomain.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# Copy the token from response, then:
curl https://yourdomain.com/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Accept: application/json"
```

---

### Step 2: Frontend Testing

#### 2.1 Install Production APK

```bash
# Install on connected device
adb install build\app\outputs\flutter-apk\app-user-release.apk
```

#### 2.2 Test Registration Flow

1. Open app
2. Go to Register
3. Fill in details
4. Submit
5. Should successfully register

#### 2.3 Test Login Flow

1. Login with registered credentials
2. Should successfully authenticate
3. Should see main dashboard

#### 2.4 Test Data Operations

1. Create expense
2. Create transfer
3. Create incoming
4. Verify data syncs to backend

#### 2.5 Monitor Network Calls

Use Android Studio or Chrome DevTools to verify:
- All API calls go to `https://yourdomain.com`
- No calls to `localhost` or local IPs
- SSL/HTTPS is working
- Responses are successful

---

## Part 4: Troubleshooting

### Common Issues & Solutions

#### Issue 1: 500 Internal Server Error

**Symptoms**: API returns 500 error

**Solutions**:
```bash
# Check Laravel logs
tail -f storage/logs/laravel.log

# Clear and recache
php artisan config:clear
php artisan cache:clear
php artisan config:cache

# Check permissions
chmod -R 775 storage
chmod -R 775 bootstrap/cache
```

#### Issue 2: CORS Errors

**Symptoms**: "CORS policy" error in app

**Solution**: Update `config/cors.php`:
```php
'allowed_origins' => ['*'],
'supports_credentials' => true,
```

Then:
```bash
php artisan config:cache
```

#### Issue 3: 404 Not Found

**Symptoms**: API endpoints return 404

**Solutions**:
1. Check `.htaccess` is uploaded
2. Verify mod_rewrite is enabled
3. Clear route cache:
```bash
php artisan route:clear
php artisan route:cache
```

#### Issue 4: Database Connection Failed

**Symptoms**: "SQLSTATE[HY000]" error

**Solutions**:
1. Verify database credentials in `.env`
2. Check database exists in hPanel
3. Test connection:
```bash
php artisan tinker
DB::connection()->getPdo();
```

#### Issue 5: Storage/Upload Issues

**Symptoms**: File uploads fail

**Solutions**:
```bash
# Recreate storage link
php artisan storage:link

# Set permissions
chmod -R 775 storage/app/public
```

#### Issue 6: App Can't Connect to API

**Symptoms**: App shows connection errors

**Solutions**:
1. Verify API URL in build command
2. Check SSL certificate is active
3. Test API in browser
4. Check Android network permissions
5. Verify no firewall blocking

#### Issue 7: Token/Authentication Issues

**Symptoms**: "Unauthenticated" errors

**Solutions**:
1. Check `APP_KEY` is set in `.env`
2. Regenerate key:
```bash
php artisan key:generate
php artisan config:cache
```
3. Clear app data and re-login

---

## Part 5: Production Checklist

### Backend Checklist

- [ ] Database created and configured
- [ ] `.env` file uploaded with production settings
- [ ] `APP_DEBUG=false` in `.env`
- [ ] `APP_ENV=production` in `.env`
- [ ] SSL certificate installed and active
- [ ] All Laravel files uploaded
- [ ] Composer dependencies installed
- [ ] Database migrations run
- [ ] Storage link created
- [ ] Permissions set correctly (775 for storage)
- [ ] Caches optimized (config, route, view)
- [ ] `.htaccess` configured
- [ ] API endpoints tested and working
- [ ] CORS configured correctly

### Frontend Checklist

- [ ] Production API URL configured
- [ ] Build scripts created
- [ ] Production APKs built with correct API URL
- [ ] Network security config updated
- [ ] APKs tested on real devices
- [ ] Registration flow tested
- [ ] Login flow tested
- [ ] Data operations tested
- [ ] File uploads tested
- [ ] Offline functionality tested
- [ ] No localhost references in production build

---

## Part 6: Maintenance & Updates

### Updating Backend

```bash
# Connect via SSH
ssh your_username@yourdomain.com

# Navigate to Laravel directory
cd public_html/api

# Pull latest changes (if using Git)
git pull origin main

# Update dependencies
composer install --optimize-autoloader --no-dev

# Run migrations
php artisan migrate --force

# Clear and optimize caches
php artisan config:clear
php artisan cache:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

### Updating Frontend

1. Make changes locally
2. Test with development API
3. Build with production API:
```bash
build_with_production_api.bat
```
4. Test production APK
5. Distribute to users

---

## Part 7: Quick Reference

### Important URLs

```
Production API: https://yourdomain.com/api/v1
API Documentation: https://yourdomain.com/api/documentation
Admin Panel: https://yourdomain.com/admin (if applicable)
```

### Important Commands

```bash
# Backend: Clear all caches
php artisan config:clear && php artisan cache:clear && php artisan route:clear

# Backend: Optimize for production
php artisan config:cache && php artisan route:cache && php artisan view:cache

# Frontend: Build production user APK
build_with_production_api.bat

# Frontend: Build production admin APK
build_admin_production_api.bat
```

### Support Contacts

```
Hostinger Support: https://www.hostinger.com/support
Laravel Documentation: https://laravel.com/docs
Flutter Documentation: https://flutter.dev/docs
```

---

## Summary

### What You Did

1. ✅ Deployed Laravel backend to Hostinger
2. ✅ Configured database and environment
3. ✅ Enabled SSL/HTTPS
4. ✅ Created production build scripts for Flutter
5. ✅ Built production APKs with correct API URL
6. ✅ Tested complete flow

### What Users Get

- ✅ Secure HTTPS API connection
- ✅ Fast, reliable backend on Hostinger
- ✅ Production-ready mobile apps
- ✅ Proper data synchronization

### Next Steps

1. Monitor Laravel logs for errors
2. Set up automated backups
3. Configure monitoring/alerts
4. Plan for scaling if needed
5. Document any custom configurations

---

**Deployment Complete! 🎉**

Your Finance App is now running on Hostinger with a production-ready backend and properly configured Flutter frontend.

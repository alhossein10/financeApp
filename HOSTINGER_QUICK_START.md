# Hostinger Deployment - Quick Start Checklist

## 🎯 Goal
Deploy Laravel backend to Hostinger and configure Flutter app to use it.

---

## ⏱️ Time Required
- Backend deployment: 30-45 minutes
- Frontend configuration: 10 minutes
- Testing: 15 minutes
- **Total: ~1 hour**

---

## 📋 Pre-Deployment Checklist

### Before You Start

- [ ] Hostinger account with Business plan or higher
- [ ] Domain name ready (or use Hostinger subdomain)
- [ ] Laravel backend project ready
- [ ] Flutter frontend project (this project)
- [ ] FTP client installed (FileZilla)
- [ ] SSH access credentials from Hostinger

---

## 🚀 Backend Deployment (30-45 min)

### Step 1: Hostinger Setup (10 min)

1. **Create MySQL Database**
   - [ ] Login to hPanel
   - [ ] Go to: Databases → MySQL Databases
   - [ ] Create new database
   - [ ] Note credentials:
     ```
     DB_HOST: localhost
     DB_DATABASE: u123456789_financeapp
     DB_USERNAME: u123456789_finance
     DB_PASSWORD: [generated password]
     ```

2. **Setup Domain/Subdomain**
   - [ ] Option A: Use main domain (`yourdomain.com`)
   - [ ] Option B: Create subdomain (`api.yourdomain.com`) ← Recommended
   - [ ] Note your API URL: `https://_______________`

3. **Enable SSL Certificate**
   - [ ] Go to: SSL section in hPanel
   - [ ] Install free Let's Encrypt SSL
   - [ ] Wait 5-10 minutes for activation

### Step 2: Prepare Laravel Backend (10 min)

1. **Update `.env` file**
   ```env
   APP_ENV=production
   APP_DEBUG=false
   APP_URL=https://yourdomain.com
   
   DB_CONNECTION=mysql
   DB_HOST=localhost
   DB_DATABASE=u123456789_financeapp
   DB_USERNAME=u123456789_finance
   DB_PASSWORD=your_password_here
   ```

2. **Optimize locally**
   ```bash
   composer install --optimize-autoloader --no-dev
   php artisan config:cache
   php artisan route:cache
   php artisan view:cache
   ```

### Step 3: Upload Files (15 min)

1. **Connect via FTP**
   - [ ] Host: `ftp.yourdomain.com`
   - [ ] Username: [from hPanel]
   - [ ] Password: [from hPanel]
   - [ ] Port: 21

2. **Upload Laravel files to `public_html/api/`**
   - [ ] All Laravel folders (app, config, database, etc.)
   - [ ] `.env` file
   - [ ] `composer.json` and `composer.lock`
   - [ ] **Don't upload:** `node_modules`, `.git`

3. **Point subdomain to `public_html/api/public`**

### Step 4: Configure Server (10 min)

1. **Connect via SSH**
   ```bash
   ssh your_username@yourdomain.com
   cd public_html/api
   ```

2. **Set permissions**
   ```bash
   chmod -R 775 storage
   chmod -R 775 bootstrap/cache
   ```

3. **Install dependencies**
   ```bash
   composer install --optimize-autoloader --no-dev
   ```

4. **Setup database**
   ```bash
   php artisan key:generate
   php artisan migrate --force
   php artisan storage:link
   ```

5. **Optimize**
   ```bash
   php artisan config:cache
   php artisan route:cache
   php artisan view:cache
   ```

### Step 5: Test Backend (5 min)

Test in browser or curl:
```bash
curl https://yourdomain.com/api/v1/auth/login
```

Expected: JSON error response (means API is working!)

- [ ] API responds
- [ ] HTTPS works
- [ ] No errors

---

## 📱 Frontend Configuration (10 min)

### Step 1: Update Build Scripts (5 min)

1. **Edit `build_with_production_api.bat`**
   
   Change this line:
   ```batch
   set API_BASE_URL=https://yourdomain.com
   ```
   
   To your actual domain:
   ```batch
   set API_BASE_URL=https://api.financeapp.com
   ```

2. **Edit `build_admin_production_api.bat`**
   
   Same change:
   ```batch
   set API_BASE_URL=https://api.financeapp.com
   ```

### Step 2: Build Production APKs (5 min)

1. **Build User APK**
   ```bash
   build_with_production_api.bat
   ```
   - [ ] Build completes successfully
   - [ ] APK created in `build\app\outputs\flutter-apk\`

2. **Build Admin APK**
   ```bash
   build_admin_production_api.bat
   ```
   - [ ] Build completes successfully
   - [ ] 3 APKs created in `releases\` folder

---

## ✅ Testing (15 min)

### Backend Testing (5 min)

1. **Test registration**
   ```bash
   curl -X POST https://yourdomain.com/api/v1/auth/register \
     -H "Content-Type: application/json" \
     -d '{"name":"Test","email":"test@test.com","password":"password123","password_confirmation":"password123","role":"user"}'
   ```
   - [ ] Returns success with token

2. **Test login**
   ```bash
   curl -X POST https://yourdomain.com/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@test.com","password":"password123"}'
   ```
   - [ ] Returns success with token

### Frontend Testing (10 min)

1. **Install User APK**
   ```bash
   adb install build\app\outputs\flutter-apk\app-user-release.apk
   ```

2. **Test Registration**
   - [ ] Open app
   - [ ] Register new user
   - [ ] Registration succeeds

3. **Test Login**
   - [ ] Login with credentials
   - [ ] Login succeeds
   - [ ] Dashboard loads

4. **Test Data Operations**
   - [ ] Create expense
   - [ ] Create transfer
   - [ ] Data syncs to backend

5. **Verify API URL**
   - [ ] Check network logs
   - [ ] All calls go to `https://yourdomain.com`
   - [ ] No localhost references

---

## 🎉 Deployment Complete!

### What You Achieved

✅ Laravel backend running on Hostinger
✅ Database configured and migrated
✅ SSL/HTTPS enabled
✅ Flutter app connecting to production API
✅ User and Admin APKs built
✅ Complete flow tested

### Your URLs

```
Production API: https://yourdomain.com/api/v1
Admin Panel: https://yourdomain.com/admin (if applicable)
```

### Your APKs

```
User APK: build\app\outputs\flutter-apk\app-user-release.apk
Admin APKs: releases\finance-admin-arm64-production.apk (~30 MB)
```

---

## 📚 Next Steps

1. **Distribute APKs**
   - Share with users via email, website, or Google Drive
   - Or upload to Google Play Store

2. **Monitor Backend**
   - Check Laravel logs: `storage/logs/laravel.log`
   - Monitor database usage in hPanel
   - Set up error notifications

3. **Setup Backups**
   - Enable automatic database backups in hPanel
   - Backup Laravel files regularly

4. **Documentation**
   - Share API URL with team
   - Document any custom configurations
   - Keep credentials secure

---

## 🆘 Quick Troubleshooting

### Backend Issues

**500 Error:**
```bash
# Check logs
tail -f storage/logs/laravel.log

# Clear caches
php artisan config:clear
php artisan cache:clear
```

**404 Error:**
```bash
# Clear route cache
php artisan route:clear
php artisan route:cache
```

**Database Error:**
- Verify credentials in `.env`
- Check database exists in hPanel

### Frontend Issues

**Can't connect:**
- Verify API URL in build script
- Test API in browser
- Check SSL certificate

**Still using localhost:**
```bash
# Clean rebuild
flutter clean
flutter pub get
build_with_production_api.bat
```

---

## 📞 Support Resources

- **Full Guide:** `HOSTINGER_DEPLOYMENT_GUIDE.md`
- **API Config:** `API_CONFIGURATION.md`
- **Hostinger Support:** https://www.hostinger.com/support
- **Laravel Docs:** https://laravel.com/docs
- **Flutter Docs:** https://flutter.dev/docs

---

## ✏️ Notes

Use this space to note your specific configuration:

```
Domain: _________________________________
API URL: _________________________________
Database Name: _________________________________
Database User: _________________________________
Admin Email: _________________________________
Deployment Date: _________________________________
```

---

**Ready to deploy? Start with Step 1! 🚀**

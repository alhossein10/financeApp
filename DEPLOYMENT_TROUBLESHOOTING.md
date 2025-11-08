# Deployment Troubleshooting Guide

## Common Issues & Solutions

This guide covers common problems when deploying Laravel backend to Hostinger and connecting Flutter frontend.

---

## Backend Issues

### Issue 1: 500 Internal Server Error

**Symptoms:**
- API returns "500 Internal Server Error"
- White screen when accessing API

**Causes:**
- Laravel configuration error
- Missing `.env` file
- Wrong file permissions
- PHP version mismatch

**Solutions:**

1. **Check Laravel logs**
   ```bash
   ssh your_username@yourdomain.com
   cd public_html/api
   tail -f storage/logs/laravel.log
   ```

2. **Verify `.env` file exists**
   ```bash
   ls -la .env
   cat .env  # Check contents
   ```

3. **Clear all caches**
   ```bash
   php artisan config:clear
   php artisan cache:clear
   php artisan route:clear
   php artisan view:clear
   ```

4. **Regenerate application key**
   ```bash
   php artisan key:generate
   php artisan config:cache
   ```

5. **Check file permissions**
   ```bash
   chmod -R 775 storage
   chmod -R 775 bootstrap/cache
   chown -R username:username storage
   chown -R username:username bootstrap/cache
   ```

6. **Verify PHP version**
   ```bash
   php -v  # Should be 8.1 or higher
   ```

---

### Issue 2: 404 Not Found on API Routes

**Symptoms:**
- `/api/v1/auth/login` returns 404
- All API endpoints return 404

**Causes:**
- `.htaccess` not uploaded or not working
- mod_rewrite not enabled
- Wrong document root

**Solutions:**

1. **Verify `.htaccess` exists in public folder**
   ```bash
   ls -la public/.htaccess
   ```

2. **Check `.htaccess` content**
   
   Should contain:
   ```apache
   <IfModule mod_rewrite.c>
       RewriteEngine On
       RewriteCond %{HTTP:Authorization} .
       RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
       RewriteCond %{REQUEST_FILENAME} !-d
       RewriteCond %{REQUEST_FILENAME} !-f
       RewriteRule ^ index.php [L]
   </IfModule>
   ```

3. **Clear route cache**
   ```bash
   php artisan route:clear
   php artisan route:cache
   php artisan route:list  # Verify routes exist
   ```

4. **Verify document root**
   - Should point to `public` folder
   - Check in hPanel → Domains → Manage

---

### Issue 3: Database Connection Failed

**Symptoms:**
- "SQLSTATE[HY000] [1045] Access denied"
- "SQLSTATE[HY000] [2002] Connection refused"

**Causes:**
- Wrong database credentials
- Database doesn't exist
- Database user doesn't have permissions

**Solutions:**

1. **Verify database exists**
   - Login to hPanel
   - Go to Databases → MySQL Databases
   - Check database is created

2. **Check credentials in `.env`**
   ```env
   DB_CONNECTION=mysql
   DB_HOST=localhost
   DB_PORT=3306
   DB_DATABASE=u123456789_financeapp
   DB_USERNAME=u123456789_finance
   DB_PASSWORD=correct_password_here
   ```

3. **Test database connection**
   ```bash
   php artisan tinker
   DB::connection()->getPdo();
   # Should return PDO object, not error
   ```

4. **Clear config cache**
   ```bash
   php artisan config:clear
   php artisan config:cache
   ```

---

### Issue 4: CORS Errors

**Symptoms:**
- Flutter app shows "CORS policy" error
- "Access-Control-Allow-Origin" error in browser console

**Causes:**
- CORS not configured
- Wrong CORS settings

**Solutions:**

1. **Update `config/cors.php`**
   ```php
   return [
       'paths' => ['api/*', 'sanctum/csrf-cookie'],
       'allowed_methods' => ['*'],
       'allowed_origins' => ['*'],
       'allowed_headers' => ['*'],
       'exposed_headers' => [],
       'max_age' => 0,
       'supports_credentials' => true,
   ];
   ```

2. **Clear config cache**
   ```bash
   php artisan config:clear
   php artisan config:cache
   ```

3. **Verify CORS middleware is active**
   ```bash
   php artisan route:list
   # Should show 'cors' middleware on API routes
   ```

---

### Issue 5: File Upload Fails

**Symptoms:**
- Image uploads return error
- "Failed to store file" error

**Causes:**
- Storage link not created
- Wrong permissions on storage folder
- Upload size limit exceeded

**Solutions:**

1. **Create storage link**
   ```bash
   php artisan storage:link
   ls -la public/storage  # Should be symlink
   ```

2. **Set storage permissions**
   ```bash
   chmod -R 775 storage/app/public
   chown -R username:username storage
   ```

3. **Check upload limits**
   
   Edit `.htaccess` in public folder:
   ```apache
   php_value upload_max_filesize 10M
   php_value post_max_size 10M
   ```

4. **Verify storage disk in `.env`**
   ```env
   FILESYSTEM_DISK=public
   ```

---

### Issue 6: Migrations Fail

**Symptoms:**
- `php artisan migrate` returns errors
- Tables not created

**Causes:**
- Database connection issue
- Migration files corrupted
- Previous migration failed

**Solutions:**

1. **Check database connection first**
   ```bash
   php artisan tinker
   DB::connection()->getPdo();
   ```

2. **Run migrations with verbose output**
   ```bash
   php artisan migrate --force --verbose
   ```

3. **Reset migrations (CAUTION: Deletes data)**
   ```bash
   php artisan migrate:fresh --force
   ```

4. **Check specific migration**
   ```bash
   php artisan migrate:status
   ```

---

## Frontend Issues

### Issue 7: App Still Connects to Localhost

**Symptoms:**
- App tries to connect to `http://localhost:8000`
- "Connection refused" error on device

**Causes:**
- Build script not used
- Wrong API URL in build command
- Old APK installed

**Solutions:**

1. **Verify build script has correct URL**
   
   Edit `build_with_production_api.bat`:
   ```batch
   set API_BASE_URL=https://yourdomain.com
   ```

2. **Clean rebuild**
   ```bash
   flutter clean
   flutter pub get
   build_with_production_api.bat
   ```

3. **Uninstall old APK**
   ```bash
   adb uninstall com.example.finance_app.user
   adb install build\app\outputs\flutter-apk\app-user-release.apk
   ```

4. **Verify API URL in logs**
   - Run app with logging enabled
   - Check network requests
   - Should show production URL

---

### Issue 8: SSL Certificate Errors

**Symptoms:**
- "SSL handshake failed"
- "Certificate verify failed"

**Causes:**
- SSL certificate not properly installed
- Self-signed certificate
- Certificate expired

**Solutions:**

1. **Verify SSL is active**
   - Go to: https://www.sslshopper.com/ssl-checker.html
   - Enter your domain
   - Should show valid certificate

2. **Reinstall SSL in Hostinger**
   - hPanel → SSL
   - Delete existing certificate
   - Install new Let's Encrypt certificate
   - Wait 10 minutes

3. **Force HTTPS in Laravel**
   
   Add to `.env`:
   ```env
   APP_URL=https://yourdomain.com
   ASSET_URL=https://yourdomain.com
   ```

4. **Update `.htaccess` to force HTTPS**
   ```apache
   RewriteCond %{HTTPS} off
   RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
   ```

---

### Issue 9: Authentication Fails

**Symptoms:**
- Login returns "Unauthenticated"
- Token not working
- Session expires immediately

**Causes:**
- APP_KEY not set
- Session configuration wrong
- Token expired

**Solutions:**

1. **Regenerate APP_KEY**
   ```bash
   php artisan key:generate
   php artisan config:cache
   ```

2. **Check session configuration in `.env`**
   ```env
   SESSION_DRIVER=database
   SESSION_LIFETIME=120
   SESSION_DOMAIN=.yourdomain.com
   SANCTUM_STATEFUL_DOMAINS=yourdomain.com
   ```

3. **Clear app data on device**
   - Settings → Apps → Finance App
   - Clear Storage
   - Clear Cache
   - Reopen app and login again

4. **Verify token in database**
   ```bash
   php artisan tinker
   DB::table('personal_access_tokens')->count();
   ```

---

### Issue 10: Data Not Syncing

**Symptoms:**
- Create expense but doesn't appear
- Data not saving to backend
- "Failed to sync" error

**Causes:**
- API endpoint error
- Validation failing
- Network issue

**Solutions:**

1. **Check Laravel logs**
   ```bash
   tail -f storage/logs/laravel.log
   ```

2. **Test API endpoint directly**
   ```bash
   curl -X POST https://yourdomain.com/api/v1/expenses \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"description":"Test","amount":100,"date":"2025-11-04"}'
   ```

3. **Verify validation rules**
   - Check backend validation
   - Ensure all required fields sent

4. **Check network connectivity**
   - Verify device has internet
   - Test API in browser
   - Check firewall settings

---

## Performance Issues

### Issue 11: Slow API Response

**Symptoms:**
- API takes >5 seconds to respond
- App feels sluggish

**Solutions:**

1. **Enable caching**
   ```bash
   php artisan config:cache
   php artisan route:cache
   php artisan view:cache
   ```

2. **Optimize database queries**
   - Add indexes to frequently queried columns
   - Use eager loading in Laravel

3. **Enable OPcache**
   - Contact Hostinger support to enable
   - Or add to `.htaccess`:
   ```apache
   php_value opcache.enable 1
   ```

4. **Upgrade hosting plan**
   - Consider Cloud Hosting or VPS
   - More resources = better performance

---

### Issue 12: Large APK Size

**Symptoms:**
- APK is 70+ MB
- Users complain about download size

**Solutions:**

See `SIZE_REDUCTION_SUMMARY.md` for complete guide.

Quick fix:
```bash
build_admin_optimized.bat
# Creates ~30 MB APKs instead of 72 MB
```

---

## Debugging Tools

### Backend Debugging

1. **Laravel Logs**
   ```bash
   tail -f storage/logs/laravel.log
   ```

2. **Enable Debug Mode (temporarily)**
   ```env
   APP_DEBUG=true  # In .env
   ```
   **Remember to disable after debugging!**

3. **Database Queries**
   ```bash
   php artisan tinker
   DB::enableQueryLog();
   # Run your code
   DB::getQueryLog();
   ```

### Frontend Debugging

1. **Flutter Logs**
   ```bash
   flutter run --verbose
   ```

2. **Network Inspection**
   ```bash
   flutter run --dart-define=DEBUG_LOGGING=true
   ```

3. **APK Analysis**
   ```bash
   flutter build apk --analyze-size
   ```

---

## Emergency Procedures

### Backend is Down

1. **Check server status**
   - Login to hPanel
   - Check if hosting is active

2. **Restore from backup**
   - hPanel → Backups
   - Restore latest backup

3. **Contact Hostinger support**
   - Live chat available 24/7
   - Provide error details

### Database Corrupted

1. **Restore database backup**
   - hPanel → Databases → Backups
   - Restore latest backup

2. **Re-run migrations**
   ```bash
   php artisan migrate:fresh --force
   php artisan db:seed --force
   ```

### App Not Working

1. **Rollback to previous APK**
   - Keep previous working version
   - Distribute to users

2. **Fix issue locally**
   - Test thoroughly
   - Rebuild and redistribute

---

## Prevention Tips

### Backend

✅ **Do:**
- Keep regular backups
- Monitor logs daily
- Test changes in staging first
- Keep Laravel updated
- Use version control (Git)

❌ **Don't:**
- Enable debug mode in production
- Commit `.env` file
- Ignore error logs
- Skip testing after updates

### Frontend

✅ **Do:**
- Test on multiple devices
- Keep previous APK versions
- Use version control
- Test with production API before release
- Monitor user feedback

❌ **Don't:**
- Skip testing
- Release without verification
- Ignore user reports
- Hardcode API URLs

---

## Getting Help

### Documentation
- Full deployment guide: `HOSTINGER_DEPLOYMENT_GUIDE.md`
- API configuration: `API_CONFIGURATION.md`
- Quick start: `HOSTINGER_QUICK_START.md`

### Support Channels
- **Hostinger Support:** https://www.hostinger.com/support (24/7 live chat)
- **Laravel Docs:** https://laravel.com/docs
- **Flutter Docs:** https://flutter.dev/docs
- **Stack Overflow:** Tag questions with `laravel`, `flutter`, `hostinger`

### Before Contacting Support

Gather this information:
- Error message (exact text)
- Laravel logs (last 50 lines)
- Steps to reproduce
- What you've tried
- Environment (production/staging/dev)
- PHP version
- Laravel version
- Flutter version

---

## Checklist for Troubleshooting

When something goes wrong:

- [ ] Check error message carefully
- [ ] Look in Laravel logs
- [ ] Verify configuration (`.env`)
- [ ] Test API endpoint directly
- [ ] Check file permissions
- [ ] Clear all caches
- [ ] Verify database connection
- [ ] Check SSL certificate
- [ ] Test on different device
- [ ] Review recent changes
- [ ] Check Hostinger status
- [ ] Search this guide
- [ ] Contact support if needed

---

**Most issues can be resolved by clearing caches and checking logs!**

Good luck with your deployment! 🚀

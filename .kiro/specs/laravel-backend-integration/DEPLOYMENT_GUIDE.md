# Production Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying the Finance App to production, including both the Laravel backend and Flutter mobile app.

## Prerequisites

Before starting deployment:

- [ ] All code merged to main branch
- [ ] All tests passing
- [ ] Code reviewed and approved
- [ ] Version number updated
- [ ] Changelog updated
- [ ] Documentation updated
- [ ] Staging environment tested
- [ ] Team notified of deployment

---

## Part 1: Backend Deployment

### Step 1: Prepare Laravel Backend

1. **Update Code**
   ```bash
   cd laravel-backend
   git checkout main
   git pull origin main
   ```

2. **Install Dependencies**
   ```bash
   composer install --no-dev --optimize-autoloader
   ```

3. **Configure Environment**
   ```bash
   cp .env.production .env
   
   # Edit .env with production values:
   # - APP_ENV=production
   # - APP_DEBUG=false
   # - Database credentials
   # - API keys
   # - Mail settings
   ```

4. **Generate Keys**
   ```bash
   php artisan key:generate
   ```

### Step 2: Database Setup

1. **Backup Current Database**
   ```bash
   mysqldump -u root -p finance_db > backup_$(date +%Y%m%d_%H%M%S).sql
   ```

2. **Run Migrations**
   ```bash
   php artisan migrate --force
   ```

3. **Seed Data (if needed)**
   ```bash
   php artisan db:seed --class=ProductionSeeder
   ```

4. **Verify Database**
   ```bash
   php artisan tinker
   >>> User::count()
   >>> Expense::count()
   ```

### Step 3: Optimize Laravel

1. **Cache Configuration**
   ```bash
   php artisan config:cache
   php artisan route:cache
   php artisan view:cache
   ```

2. **Optimize Autoloader**
   ```bash
   composer dump-autoload --optimize
   ```

3. **Clear Old Caches**
   ```bash
   php artisan cache:clear
   php artisan queue:restart
   ```

### Step 4: Deploy Backend

**Option A: Manual Deployment**

1. **Upload Files**
   ```bash
   rsync -avz --exclude='.git' --exclude='node_modules' \
     ./ user@server:/var/www/finance-api/
   ```

2. **Set Permissions**
   ```bash
   ssh user@server
   cd /var/www/finance-api
   chmod -R 755 storage bootstrap/cache
   chown -R www-data:www-data storage bootstrap/cache
   ```

3. **Restart Services**
   ```bash
   sudo systemctl restart php-fpm
   sudo systemctl restart nginx
   sudo systemctl restart supervisor
   ```

**Option B: Git Deployment**

1. **Pull Latest Code**
   ```bash
   ssh user@server
   cd /var/www/finance-api
   git pull origin main
   ```

2. **Run Deployment Script**
   ```bash
   ./deploy.sh
   ```

**Option C: CI/CD Pipeline**

1. **Push to Main Branch**
   ```bash
   git push origin main
   ```

2. **Monitor Pipeline**
   - Check GitHub Actions / GitLab CI
   - Verify all steps complete
   - Check deployment logs

### Step 5: Verify Backend

1. **Check API Health**
   ```bash
   curl https://api.example.com/health
   ```

2. **Test Authentication**
   ```bash
   curl -X POST https://api.example.com/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"password"}'
   ```

3. **Test Endpoints**
   ```bash
   # Get expenses
   curl https://api.example.com/api/v1/expenses \
     -H "Authorization: Bearer {token}"
   ```

4. **Check Logs**
   ```bash
   tail -f storage/logs/laravel.log
   ```

---

## Part 2: Flutter App Deployment

### Step 1: Prepare Flutter App

1. **Update Code**
   ```bash
   cd finance-app
   git checkout main
   git pull origin main
   ```

2. **Update Version**
   
   Edit `pubspec.yaml`:
   ```yaml
   version: 2.0.0+1
   ```

3. **Update Changelog**
   
   Edit `CHANGELOG.md`:
   ```markdown
   ## [2.0.0] - 2024-01-15
   
   ### Added
   - Laravel backend integration
   - Offline support with queue
   - Admin dashboard
   
   ### Changed
   - Improved sync performance
   - Better error handling
   
   ### Removed
   - SQLite local database
   - Supabase integration
   ```

4. **Clean Build**
   ```bash
   flutter clean
   flutter pub get
   ```

### Step 2: Build Android Release

1. **Build App Bundle**
   ```bash
   flutter build appbundle --release --flavor prod \
     --dart-define=API_BASE_URL=https://api.example.com/api/v1 \
     --dart-define=ENVIRONMENT=production \
     --dart-define=DEBUG_MODE=false \
     --dart-define=ENABLE_LOGGING=false \
     --dart-define=ANALYTICS_ENABLED=true
   ```

2. **Build APK (Optional)**
   ```bash
   flutter build apk --release --flavor prod \
     --dart-define=API_BASE_URL=https://api.example.com/api/v1 \
     --dart-define=ENVIRONMENT=production \
     --dart-define=DEBUG_MODE=false \
     --dart-define=ENABLE_LOGGING=false \
     --dart-define=ANALYTICS_ENABLED=true
   ```

3. **Verify Build**
   ```bash
   # Check file exists
   ls -lh build/app/outputs/bundle/prodRelease/app-prod-release.aab
   
   # Check file size (should be reasonable)
   du -h build/app/outputs/bundle/prodRelease/app-prod-release.aab
   ```

### Step 3: Test Android Build

1. **Install on Test Device**
   ```bash
   # Install APK
   adb install build/app/outputs/flutter-apk/app-prod-release.apk
   ```

2. **Test Functionality**
   - [ ] App launches
   - [ ] Login works
   - [ ] Data loads
   - [ ] Create/edit/delete works
   - [ ] File upload works
   - [ ] Offline mode works
   - [ ] No crashes

3. **Check API Connection**
   - [ ] Connects to production API
   - [ ] Authentication successful
   - [ ] Data syncs correctly

### Step 4: Deploy to Google Play Store

1. **Login to Play Console**
   - Go to https://play.google.com/console
   - Select Finance App

2. **Create New Release**
   - Go to Release → Production
   - Click "Create new release"

3. **Upload App Bundle**
   - Upload `app-prod-release.aab`
   - Wait for processing
   - Review any warnings

4. **Add Release Notes**
   ```
   What's new in version 2.0.0:
   
   ✨ New Features:
   - Centralized data management with cloud sync
   - Enhanced offline support
   - Admin dashboard with analytics
   - Improved performance
   
   🐛 Bug Fixes:
   - Fixed sync issues
   - Improved error handling
   - Better stability
   
   📱 Improvements:
   - Faster app startup
   - Better user experience
   - Enhanced security
   ```

5. **Configure Rollout**
   - Start with 10% rollout
   - Set to increase gradually
   - Or release to 100% if confident

6. **Review and Publish**
   - Review all details
   - Click "Review release"
   - Click "Start rollout to Production"

### Step 5: Build iOS Release

1. **Open Xcode**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Configure Signing**
   - Select Runner target
   - Go to Signing & Capabilities
   - Select production provisioning profile
   - Verify bundle identifier

3. **Build Archive**
   ```bash
   flutter build ipa --release --flavor prod \
     --dart-define=API_BASE_URL=https://api.example.com/api/v1 \
     --dart-define=ENVIRONMENT=production \
     --dart-define=DEBUG_MODE=false \
     --dart-define=ENABLE_LOGGING=false \
     --dart-define=ANALYTICS_ENABLED=true
   ```

4. **Verify Build**
   ```bash
   ls -lh build/ios/ipa/finance_app.ipa
   ```

### Step 6: Deploy to App Store

1. **Login to App Store Connect**
   - Go to https://appstoreconnect.apple.com
   - Select Finance App

2. **Create New Version**
   - Go to App Store → iOS App
   - Click "+" to add version
   - Enter version number: 2.0.0

3. **Upload IPA**
   
   **Option A: Xcode**
   - Open Xcode
   - Window → Organizer
   - Select archive
   - Click "Distribute App"
   - Follow wizard

   **Option B: Transporter**
   - Open Transporter app
   - Drag and drop IPA file
   - Click "Deliver"

4. **Configure App Information**
   
   **What's New:**
   ```
   Version 2.0.0 brings major improvements:
   
   • Cloud sync for seamless data access across devices
   • Enhanced offline support
   • Admin dashboard with powerful analytics
   • Improved performance and stability
   • Better error handling
   • Enhanced security features
   
   Thank you for using Finance App!
   ```

   **Screenshots:**
   - Upload new screenshots if UI changed
   - Ensure all required sizes included

   **App Review Information:**
   - Demo account: test@example.com / TestPass123!
   - Notes: "Please test login, expense creation, and sync"

5. **Submit for Review**
   - Review all information
   - Click "Submit for Review"
   - Wait for approval (1-3 days)

---

## Part 3: Post-Deployment

### Step 1: Monitor Deployment

**First Hour:**

1. **Check Crash Reports**
   - Firebase Crashlytics
   - Google Play Console
   - App Store Connect

2. **Monitor Error Logs**
   ```bash
   # Backend logs
   ssh user@server
   tail -f /var/www/finance-api/storage/logs/laravel.log
   ```

3. **Check API Performance**
   - Response times
   - Error rates
   - Request volume

4. **Monitor User Feedback**
   - App store reviews
   - Support tickets
   - Social media

**First Day:**

1. **Review Analytics**
   - Daily active users
   - Session duration
   - Feature usage
   - Crash rate

2. **Check Metrics**
   - API success rate
   - Sync success rate
   - Error rate
   - Performance metrics

3. **Address Issues**
   - Respond to user feedback
   - Fix critical bugs
   - Plan hotfix if needed

**First Week:**

1. **Analyze Trends**
   - User adoption
   - Feature usage
   - Performance trends
   - Error patterns

2. **Gather Feedback**
   - User surveys
   - Support tickets
   - App reviews
   - Team feedback

3. **Plan Improvements**
   - Bug fixes
   - Performance optimizations
   - New features
   - UX improvements

### Step 2: Increase Rollout (Google Play)

If using gradual rollout:

**Day 1: 10% Rollout**
- Monitor closely
- Check for critical issues
- Review crash reports

**Day 2: 50% Rollout**
- If stable, increase to 50%
- Continue monitoring
- Address any issues

**Day 3: 100% Rollout**
- If stable, release to all users
- Continue monitoring
- Celebrate! 🎉

### Step 3: Communication

1. **Announce Release**
   
   **Email to Users:**
   ```
   Subject: Finance App 2.0 is Here! 🎉
   
   We're excited to announce Finance App 2.0 with major improvements:
   
   ✨ What's New:
   - Cloud sync across all your devices
   - Work offline, sync when online
   - Enhanced performance
   - Better security
   
   Update now to enjoy these new features!
   
   [Update Now Button]
   ```

   **Social Media:**
   ```
   🎉 Finance App 2.0 is live!
   
   ✨ Cloud sync
   📱 Offline support
   ⚡ Better performance
   🔒 Enhanced security
   
   Update now! [Link]
   ```

2. **Update Documentation**
   - [ ] Website
   - [ ] Help center
   - [ ] API documentation
   - [ ] User guide

3. **Brief Support Team**
   - Share release notes
   - Provide FAQs
   - Set up escalation path
   - Monitor support tickets

---

## Deployment Checklist

### Pre-Deployment

- [ ] Code merged to main
- [ ] All tests passing
- [ ] Version updated
- [ ] Changelog updated
- [ ] Staging tested
- [ ] Team notified

### Backend Deployment

- [ ] Code deployed
- [ ] Database migrated
- [ ] Caches cleared
- [ ] Services restarted
- [ ] API tested
- [ ] Logs checked

### App Deployment

- [ ] Android built
- [ ] iOS built
- [ ] Builds tested
- [ ] Play Store uploaded
- [ ] App Store uploaded
- [ ] Release notes added

### Post-Deployment

- [ ] Monitoring active
- [ ] Crash reports checked
- [ ] Error logs reviewed
- [ ] User feedback monitored
- [ ] Team notified
- [ ] Documentation updated

---

## Troubleshooting

### Backend Issues

**Problem**: API not responding

**Solution**:
```bash
# Check service status
sudo systemctl status php-fpm
sudo systemctl status nginx

# Restart services
sudo systemctl restart php-fpm
sudo systemctl restart nginx

# Check logs
tail -f /var/log/nginx/error.log
tail -f storage/logs/laravel.log
```

**Problem**: Database connection error

**Solution**:
```bash
# Check database
mysql -u root -p
> SHOW DATABASES;
> USE finance_db;
> SHOW TABLES;

# Check .env file
cat .env | grep DB_
```

### App Issues

**Problem**: Build fails

**Solution**:
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build appbundle --release
```

**Problem**: App crashes on launch

**Solution**:
- Check crash reports
- Verify API URL is correct
- Test on multiple devices
- Check for missing dependencies

---

## Emergency Procedures

### Critical Bug Found

1. **Assess Severity**
   - How many users affected?
   - What is the impact?
   - Can it wait for hotfix?

2. **Immediate Actions**
   - Halt rollout if possible
   - Notify team
   - Post status update

3. **Fix or Rollback**
   - If quick fix: Deploy hotfix
   - If complex: Rollback
   - See [ROLLBACK_PROCEDURE.md](ROLLBACK_PROCEDURE.md)

### Server Overload

1. **Scale Up**
   ```bash
   # Add more workers
   # Increase server resources
   # Enable caching
   ```

2. **Optimize**
   ```bash
   # Enable query caching
   # Optimize slow queries
   # Add CDN
   ```

3. **Monitor**
   - Watch server metrics
   - Check response times
   - Monitor error rates

---

## Success Metrics

Deployment is successful if:

- [ ] Crash rate < 1%
- [ ] Error rate < 5%
- [ ] API response time < 500ms
- [ ] Sync success rate > 95%
- [ ] User rating > 4.0 stars
- [ ] No critical bugs
- [ ] Positive user feedback

---

## Post-Deployment Tasks

### Immediate

- [ ] Monitor crash reports
- [ ] Check error logs
- [ ] Review user feedback
- [ ] Respond to support tickets

### This Week

- [ ] Analyze usage patterns
- [ ] Review performance metrics
- [ ] Address non-critical bugs
- [ ] Plan next release

### This Month

- [ ] Review analytics trends
- [ ] Gather user feedback
- [ ] Plan new features
- [ ] Optimize performance

---

## Contacts

### Team

- **Project Manager**: [Name] - [Email] - [Phone]
- **Lead Developer**: [Name] - [Email] - [Phone]
- **DevOps**: [Name] - [Email] - [Phone]
- **Support**: [Email] - [Phone]

### External

- **Google Play Support**: https://support.google.com/googleplay/android-developer
- **Apple Developer Support**: https://developer.apple.com/support/
- **Hosting Provider**: [Contact]

---

## Congratulations! 🎉

You've successfully deployed Finance App to production!

Remember to:
- Monitor closely for the first 24 hours
- Respond quickly to any issues
- Gather user feedback
- Plan improvements

Great job! 🚀

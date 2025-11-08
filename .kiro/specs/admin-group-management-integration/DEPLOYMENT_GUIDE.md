# Admin Group Management - Deployment Guide

## Table of Contents

1. [Overview](#overview)
2. [Pre-Deployment Checklist](#pre-deployment-checklist)
3. [Staging Deployment](#staging-deployment)
4. [Production Deployment](#production-deployment)
5. [Post-Deployment](#post-deployment)
6. [Rollback Procedures](#rollback-procedures)
7. [Monitoring](#monitoring)

---

## Overview

This guide provides step-by-step instructions for deploying the Admin Group Management feature to staging and production environments.

### Deployment Strategy

- **Staging First**: Always deploy to staging before production
- **Smoke Testing**: Perform comprehensive smoke tests in staging
- **Gradual Rollout**: Consider phased rollout for production
- **Monitoring**: Monitor closely for 24-48 hours post-deployment

### Timeline

- **Staging Deployment**: 2-4 hours
- **Staging Testing**: 4-8 hours
- **Production Deployment**: 2-4 hours
- **Monitoring Period**: 24-48 hours

---

## Pre-Deployment Checklist

### Code Quality

- [ ] All unit tests passing (85%+ coverage)
- [ ] All widget tests passing
- [ ] All integration tests passing
- [ ] No critical bugs in issue tracker
- [ ] Code review completed and approved
- [ ] Documentation updated

### Backend Verification

- [ ] Backend API deployed and accessible
- [ ] All admin group endpoints working
- [ ] Database migrations completed
- [ ] API authentication working
- [ ] Test with Postman collection

### Build Verification

- [ ] Clean build successful
- [ ] No compilation errors
- [ ] No deprecation warnings
- [ ] App size within limits
- [ ] Performance benchmarks met

### Documentation

- [ ] README updated
- [ ] User guide completed
- [ ] API documentation updated
- [ ] Migration guide ready
- [ ] Release notes prepared

---

## Staging Deployment

### Step 1: Prepare Staging Build

#### 1.1 Clean Build Environment

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Verify no issues
flutter doctor -v
```

#### 1.2 Run Tests

```bash
# Run all tests
flutter test

# Verify all tests pass
# Expected: 0 failures
```

#### 1.3 Build for Staging

**Android:**
```bash
# Build APK for staging
flutter build apk --flavor staging --release

# Output: build/app/outputs/flutter-apk/app-staging-release.apk
```

**iOS:**
```bash
# Build for staging
flutter build ios --flavor staging --release

# Archive in Xcode for distribution
```

### Step 2: Deploy to Staging

#### 2.1 Android Deployment

```bash
# Option 1: Internal testing track
# Upload to Google Play Console > Internal testing

# Option 2: Firebase App Distribution
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-staging-release.apk \
  --app YOUR_FIREBASE_APP_ID \
  --groups testers \
  --release-notes "Admin Group Management feature"
```

#### 2.2 iOS Deployment

```bash
# Upload to TestFlight
# Use Xcode or Transporter app

# Or use fastlane
fastlane beta
```

### Step 3: Staging Smoke Tests

#### 3.1 Installation Test

- [ ] App installs successfully
- [ ] App launches without crashes
- [ ] No permission errors
- [ ] Splash screen displays correctly

#### 3.2 Authentication Tests

- [ ] Login works
- [ ] Registration works (admin)
- [ ] Registration works (user with group code)
- [ ] Logout works
- [ ] Token refresh works

#### 3.3 Admin Group Tests

**Admin Flow:**
- [ ] Admin registers and receives group code
- [ ] Group code displays in success dialog
- [ ] Can navigate to Group Management
- [ ] Can view group information
- [ ] Can copy group code
- [ ] Can view member list
- [ ] Can search members
- [ ] Can filter by department
- [ ] Can remove a member
- [ ] Can regenerate group code

**User Flow:**
- [ ] User registers with group code
- [ ] Successfully joins group
- [ ] Can navigate to My Group
- [ ] Can view group information
- [ ] Can see admin contact
- [ ] Can join group after registration

#### 3.4 Data Scoping Tests

- [ ] Create expense as user A
- [ ] Login as user B (same group)
- [ ] Verify user B sees user A's expense
- [ ] Login as user C (different group)
- [ ] Verify user C doesn't see user A's expense
- [ ] Test with transfers, incoming, fund boxes

#### 3.5 Localization Tests

- [ ] Switch to Arabic
- [ ] Verify RTL layout
- [ ] Verify all translations
- [ ] Test group management in Arabic
- [ ] Switch back to English

#### 3.6 Error Handling Tests

- [ ] Invalid group code
- [ ] Already in group
- [ ] Network errors
- [ ] Validation errors
- [ ] Permission errors

### Step 4: Staging Sign-Off

- [ ] All smoke tests passed
- [ ] No critical issues found
- [ ] Performance acceptable
- [ ] UI/UX approved
- [ ] Stakeholder approval received

---

## Production Deployment

### Step 1: Final Preparation

#### 1.1 Version Bump

```yaml
# pubspec.yaml
version: 1.0.0+100  # Update version and build number
```

#### 1.2 Update Changelog

```markdown
# CHANGELOG.md
## [1.0.0] - 2025-11-01
### Added
- Admin Group Management feature
- Group code system
- Data scoping by admin group
```

#### 1.3 Create Git Tag

```bash
git tag -a v1.0.0 -m "Release v1.0.0 - Admin Group Management"
git push origin v1.0.0
```

### Step 2: Build Production Release

#### 2.1 Clean and Prepare

```bash
flutter clean
flutter pub get
flutter test  # Verify all tests pass
```

#### 2.2 Build Android

```bash
# Build App Bundle (recommended for Play Store)
flutter build appbundle --flavor production --release

# Output: build/app/outputs/bundle/productionRelease/app-production-release.aab

# Build APK (for direct distribution)
flutter build apk --flavor production --release --split-per-abi

# Outputs:
# - app-armeabi-v7a-production-release.apk
# - app-arm64-v8a-production-release.apk
# - app-x86_64-production-release.apk
```

#### 2.3 Build iOS

```bash
# Build for release
flutter build ios --flavor production --release

# Create archive in Xcode
# Product > Archive
```

### Step 3: Deploy to App Stores

#### 3.1 Google Play Store

**Using Play Console:**

1. Go to Google Play Console
2. Select your app
3. Navigate to Production > Create new release
4. Upload the AAB file
5. Fill in release notes:

```
What's New in v1.0.0:

🎉 New Feature: Admin Group Management
- Admins get unique 6-character group codes
- Users join groups easily with codes
- Manage team members from one place
- Automatic data filtering by group

✨ Improvements:
- Simplified registration process
- Better data privacy and isolation
- Enhanced user experience
- Full Arabic language support

🐛 Bug Fixes:
- Fixed various UI issues
- Improved error handling
- Performance optimizations
```

6. Set rollout percentage (start with 10-20%)
7. Review and publish

**Using Fastlane:**

```bash
fastlane deploy_production
```

#### 3.2 Apple App Store

**Using App Store Connect:**

1. Go to App Store Connect
2. Select your app
3. Create new version (1.0.0)
4. Upload build from TestFlight
5. Fill in release notes:

```
What's New:

Admin Group Management
• Admins receive unique group codes
• Easy team member management
• Secure data isolation
• Simplified registration

Improvements
• Better user experience
• Full localization support
• Enhanced performance
• Bug fixes and stability
```

6. Submit for review
7. Set release schedule (manual or automatic)

**Using Fastlane:**

```bash
fastlane release_ios
```

### Step 4: Phased Rollout (Recommended)

#### 4.1 Initial Rollout (10%)

- Deploy to 10% of users
- Monitor for 24 hours
- Check error rates
- Review user feedback

#### 4.2 Expand Rollout (50%)

If no issues:
- Increase to 50% of users
- Monitor for 24 hours
- Continue checking metrics

#### 4.3 Full Rollout (100%)

If all good:
- Deploy to 100% of users
- Continue monitoring
- Provide support

---

## Post-Deployment

### Step 1: Immediate Monitoring (First 2 Hours)

#### 1.1 Check Crash Reports

```bash
# Firebase Crashlytics
# Check for new crashes

# Sentry (if using)
# Monitor error rates
```

#### 1.2 Monitor API

- Check API error rates
- Monitor response times
- Verify endpoint availability
- Check database performance

#### 1.3 User Feedback

- Monitor app store reviews
- Check support tickets
- Review social media mentions
- Monitor in-app feedback

### Step 2: First 24 Hours

#### 2.1 Metrics to Monitor

- **Crash Rate**: Should be < 1%
- **API Error Rate**: Should be < 2%
- **User Adoption**: Track group creation/joining
- **Performance**: App launch time, page load times

#### 2.2 Key Indicators

- [ ] No critical crashes
- [ ] API performing normally
- [ ] Users successfully creating groups
- [ ] Users successfully joining groups
- [ ] Data scoping working correctly
- [ ] No security issues

### Step 3: First Week

#### 3.1 Ongoing Monitoring

- Daily review of metrics
- Address user feedback
- Fix any minor bugs
- Monitor adoption rate

#### 3.2 Support

- Respond to user questions
- Update FAQ if needed
- Provide guidance to admins
- Assist with migration

---

## Rollback Procedures

### When to Rollback

- Critical crashes affecting > 5% of users
- Data integrity issues
- Security vulnerabilities
- Complete feature failure

### Rollback Steps

#### Option 1: App Store Rollback

**Google Play:**
1. Go to Play Console
2. Navigate to Production
3. Click "Manage" on current release
4. Select "Halt rollout"
5. Create new release with previous version
6. Publish immediately

**Apple App Store:**
1. Go to App Store Connect
2. Remove current version from sale
3. Submit previous version
4. Request expedited review

#### Option 2: Feature Flag Disable

```dart
// lib/core/config/feature_flags.dart
class FeatureFlags {
  static const bool enableGroupManagement = false;  // Disable feature
}

// Push hotfix update
flutter build appbundle --release
// Deploy as hotfix
```

#### Option 3: Backend Rollback

```bash
# Rollback backend to previous version
# This maintains old API behavior
# Frontend continues to work with old system
```

### Post-Rollback

1. Notify users of temporary issue
2. Investigate root cause
3. Fix the issue
4. Test thoroughly
5. Redeploy when ready

---

## Monitoring

### Metrics Dashboard

#### Key Metrics

1. **Adoption Metrics**
   - New admin registrations
   - New user registrations with group codes
   - Groups created
   - Users joined to groups

2. **Usage Metrics**
   - Group management page views
   - Group code copies
   - Member removals
   - Code regenerations

3. **Performance Metrics**
   - App launch time
   - Page load times
   - API response times
   - Cache hit rates

4. **Error Metrics**
   - Crash rate
   - API error rate
   - Validation errors
   - Network errors

### Monitoring Tools

#### Firebase Analytics

```dart
// Track key events
Analytics.logEvent('group_created');
Analytics.logEvent('user_joined_group');
Analytics.logEvent('member_removed');
Analytics.logEvent('code_regenerated');
```

#### Crashlytics

```dart
// Monitor crashes
FirebaseCrashlytics.instance.recordError(
  error,
  stackTrace,
  reason: 'Admin group operation failed',
);
```

#### Custom Logging

```dart
// Log important operations
Logger.info('Admin group created', {
  'admin_id': adminId,
  'group_code': groupCode,
});
```

### Alerts

Set up alerts for:
- Crash rate > 1%
- API error rate > 2%
- Response time > 2 seconds
- Failed group operations > 5%

---

## Troubleshooting

### Common Deployment Issues

#### Issue 1: Build Fails

**Solution:**
```bash
flutter clean
flutter pub get
flutter build apk --release
```

#### Issue 2: App Store Rejection

**Common Reasons:**
- Missing privacy policy
- Incomplete metadata
- Guideline violations

**Solution:**
- Review rejection reason
- Make necessary changes
- Resubmit

#### Issue 3: High Crash Rate

**Solution:**
1. Check Crashlytics for stack traces
2. Identify common crash pattern
3. Deploy hotfix
4. Monitor improvement

#### Issue 4: Users Can't Join Groups

**Solution:**
1. Verify backend is accessible
2. Check API endpoints
3. Verify group codes are valid
4. Check network connectivity

---

## Support Contacts

### Emergency Contacts

- **On-Call Engineer**: +1-XXX-XXX-XXXX
- **Backend Team**: backend@financeapp.com
- **DevOps**: devops@financeapp.com

### Escalation Path

1. **Level 1**: Support team
2. **Level 2**: Engineering team
3. **Level 3**: Senior engineers
4. **Level 4**: CTO

---

## Deployment Checklist

### Pre-Deployment

- [ ] All tests passing
- [ ] Code review completed
- [ ] Documentation updated
- [ ] Backend verified
- [ ] Staging tested
- [ ] Stakeholder approval

### Deployment

- [ ] Version bumped
- [ ] Git tagged
- [ ] Production build created
- [ ] Uploaded to stores
- [ ] Release notes added
- [ ] Phased rollout configured

### Post-Deployment

- [ ] Monitoring active
- [ ] No critical errors
- [ ] User feedback reviewed
- [ ] Support team briefed
- [ ] Documentation published
- [ ] Success metrics tracked

---

**Document Version**: 1.0.0  
**Last Updated**: November 1, 2025  
**Next Review**: December 1, 2025


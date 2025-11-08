# Release Checklist

Use this checklist before creating production releases.

## Pre-Release Checklist

### Code Preparation
- [ ] All features tested and working
- [ ] No console errors or warnings
- [ ] Code reviewed and approved
- [ ] All tests passing
- [ ] Documentation updated

### Version Management
- [ ] Update version in `pubspec.yaml`
  - Format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`
  - Example: `1.0.0+1` → `1.0.1+2`
- [ ] Update changelog (if you have one)
- [ ] Commit version changes

### Environment Check
- [ ] Close all IDEs (VS Code, Android Studio)
- [ ] Close all emulators/simulators
- [ ] Stop all Flutter processes
- [ ] Stop Gradle daemons: `cd android && gradlew --stop`

### Dependencies
- [ ] Run `flutter pub get`
- [ ] Run `flutter pub upgrade` (if needed)
- [ ] Verify no dependency conflicts
- [ ] Check for security vulnerabilities

## Build Process

### Step 1: Clean Build
- [ ] Run `clean_build.bat`
- [ ] Verify build directory is removed
- [ ] Verify releases directory is removed
- [ ] Wait for completion

### Step 2: Production Build
- [ ] Run `build_releases.bat`
- [ ] Wait for all 4 builds to complete:
  - [ ] User APK
  - [ ] User AAB
  - [ ] Admin APK
  - [ ] Admin AAB
- [ ] Check for build errors
- [ ] Verify all files in `releases/` folder

### Step 3: File Verification
- [ ] `releases/finance-user-release.apk` exists
- [ ] `releases/finance-user-release.aab` exists
- [ ] `releases/finance-admin-release.apk` exists
- [ ] `releases/finance-admin-release.aab` exists
- [ ] Check file sizes are reasonable (not 0 bytes)

## Testing

### Admin Flavor Testing
- [ ] Install `finance-admin-release.apk` on test device
- [ ] Verify app name shows "Finance Admin"
- [ ] Test login/registration
- [ ] Test admin dashboard access
- [ ] Test database management
- [ ] Test cash management
- [ ] Test cashbox module
- [ ] Test currency tools
- [ ] Test expenses tracking
- [ ] Test export functionality
- [ ] Test profile management
- [ ] Test logout

### User Flavor Testing
- [ ] Install `finance-user-release.apk` on test device
- [ ] Verify app name shows "Finance"
- [ ] Test login/registration
- [ ] Verify NO admin dashboard
- [ ] Verify NO cash management
- [ ] Verify NO cashbox module
- [ ] Test currency tools
- [ ] Test expenses tracking
- [ ] Test export functionality
- [ ] Test profile management
- [ ] Test logout

### Simultaneous Installation Test
- [ ] Install both APKs on same device
- [ ] Verify both apps appear separately
- [ ] Verify different app names
- [ ] Verify different icons (if applicable)
- [ ] Test both apps work independently
- [ ] Verify no data conflicts

### Performance Testing
- [ ] App launches quickly
- [ ] No crashes or freezes
- [ ] Smooth navigation
- [ ] Database operations fast
- [ ] Export functions work
- [ ] Memory usage acceptable
- [ ] Battery usage acceptable

## Pre-Distribution

### Security Check
- [ ] No hardcoded API keys
- [ ] No debug logs in production
- [ ] Secure storage implemented
- [ ] Authentication working
- [ ] Data encryption enabled (if applicable)
- [ ] Network security configured

### Compliance
- [ ] Privacy policy updated
- [ ] Terms of service updated
- [ ] Required permissions documented
- [ ] Data handling compliant
- [ ] Age restrictions set (if applicable)

### Store Preparation (Google Play)
- [ ] App signing configured
- [ ] Store listing prepared
  - [ ] App title
  - [ ] Short description
  - [ ] Full description
  - [ ] Screenshots (phone)
  - [ ] Screenshots (tablet)
  - [ ] Feature graphic
  - [ ] App icon
- [ ] Content rating completed
- [ ] Pricing set
- [ ] Countries selected
- [ ] Release notes written

## Distribution

### Internal Testing
- [ ] Upload AAB to internal testing track
- [ ] Add internal testers
- [ ] Send test invitation
- [ ] Collect feedback
- [ ] Fix critical issues

### Beta Testing (Optional)
- [ ] Upload AAB to beta track
- [ ] Add beta testers
- [ ] Monitor crash reports
- [ ] Collect user feedback
- [ ] Fix reported issues

### Production Release
- [ ] Upload `finance-admin-release.aab` to Play Store
- [ ] Upload `finance-user-release.aab` to Play Store
- [ ] Set rollout percentage (start with 10-20%)
- [ ] Monitor crash reports
- [ ] Monitor user reviews
- [ ] Gradually increase rollout

### Direct Distribution (APK)
- [ ] Upload APKs to secure location
- [ ] Create download links
- [ ] Send to authorized users
- [ ] Provide installation instructions
- [ ] Provide support contact

## Post-Release

### Monitoring
- [ ] Monitor crash reports (first 24 hours)
- [ ] Monitor user reviews
- [ ] Monitor analytics
- [ ] Check error logs
- [ ] Monitor performance metrics

### Support
- [ ] Respond to user feedback
- [ ] Address critical bugs immediately
- [ ] Plan hotfix if needed
- [ ] Update documentation
- [ ] Communicate with users

### Documentation
- [ ] Tag release in Git
- [ ] Create release notes
- [ ] Update README
- [ ] Archive release builds
- [ ] Document known issues

## Rollback Plan

If critical issues found:
- [ ] Pause rollout in Play Store
- [ ] Identify the issue
- [ ] Fix the bug
- [ ] Create hotfix release
- [ ] Follow this checklist again
- [ ] Resume rollout

## Version History

| Version | Date | Admin Build | User Build | Notes |
|---------|------|-------------|------------|-------|
| 1.0.0+1 | YYYY-MM-DD | ✓ | ✓ | Initial release |
| | | | | |
| | | | | |

## Notes

- Always test on multiple devices (different Android versions)
- Keep previous release builds archived
- Document any issues encountered
- Update this checklist based on experience
- Maintain separate release notes for Admin and User versions

## Quick Commands Reference

```bash
# Clean everything
clean_build.bat

# Build production releases
build_releases.bat

# Check version
flutter --version

# Check dependencies
flutter pub outdated

# Analyze code
flutter analyze

# Run tests
flutter test
```

## Emergency Contacts

- **Developer:** [Your Name/Team]
- **QA Lead:** [Name]
- **Product Owner:** [Name]
- **Support:** [Email/Phone]

---

**Last Updated:** [Date]
**Checklist Version:** 1.0

# Production Deployment - Quick Reference Card

## 🚀 Admin Group Management v1.1.0

---

## Pre-Flight Checklist (5 minutes)

```bash
# 1. Verify backend is live
curl https://your-backend-url.com/api/v1/admin/group

# 2. Run tests
flutter test

# 3. Check code quality
flutter analyze
```

- [ ] Backend responding ✅
- [ ] All tests pass ✅
- [ ] No critical warnings ✅

---

## Build Production (30 minutes)

```bash
# 1. Clean
clean_build.bat

# 2. Build
build_production.bat
```

**Expected Output**:
```
releases/
├── finance-user-release.apk
├── finance-user-release.aab
├── finance-admin-release.apk
└── finance-admin-release.aab
```

---

## Test on Devices (1 hour)

### Device 1: User App
```bash
adb install releases\finance-user-release.apk
```
- [ ] Register with group code
- [ ] Join group works
- [ ] View "My Group"
- [ ] Data scoping works

### Device 2: Admin App
```bash
adb install releases\finance-admin-release.apk
```
- [ ] Register as admin
- [ ] Get group code
- [ ] View Group Management
- [ ] Remove member works

---

## Deploy to Play Store (30 minutes)

### User App
1. Go to Play Console → Finance (User)
2. Production → Create new release
3. Upload `finance-user-release.aab`
4. Release name: `1.1.0 (2)`
5. Add release notes
6. **Set rollout: 10%**
7. Start rollout

### Admin App
1. Go to Play Console → Finance Admin
2. Production → Create new release
3. Upload `finance-admin-release.aab`
4. Release name: `1.1.0 (2)`
5. Add release notes
6. **Set rollout: 10%**
7. Start rollout

---

## Monitor (First 2 Hours)

**Check every 30 minutes**:

### Play Console
- Crash-free rate: > 99% ✅
- ANR rate: < 0.5% ✅
- User reviews: Positive ✅

### Firebase Crashlytics
- No critical crashes ✅
- Error rate: < 2% ✅

### Backend
- API uptime: > 99.9% ✅
- Response time: < 500ms ✅

---

## Rollout Schedule

| Day | Rollout | Action |
|-----|---------|--------|
| 1 | 10% | Deploy & monitor closely |
| 2 | 25% | Increase if stable |
| 3 | 50% | Increase if stable |
| 4-5 | 100% | Complete rollout |

---

## Emergency Contacts

- **On-Call**: [Phone]
- **Backend**: [Phone]
- **DevOps**: [Phone]

---

## Rollback (If Needed)

**If crash rate > 5%**:
1. Play Console → Production
2. Click "Halt rollout"
3. Investigate issue
4. Fix and redeploy

---

## Success Criteria

- [ ] Crash-free rate > 99%
- [ ] Users creating groups
- [ ] Users joining groups
- [ ] Data scoping working
- [ ] No security issues
- [ ] Positive feedback

---

## Key Metrics to Track

**Adoption**:
- Groups created: _____
- Users joined: _____

**Stability**:
- Crash-free rate: _____%
- API error rate: _____%

**Feedback**:
- User reviews: _____ (Rating: _____)
- Support tickets: _____

---

## Quick Commands

```bash
# Clean build
clean_build.bat

# Production build
build_production.bat

# Install User APK
adb install releases\finance-user-release.apk

# Install Admin APK
adb install releases\finance-admin-release.apk

# Check version
flutter --version

# Run tests
flutter test

# Analyze code
flutter analyze
```

---

## Documentation Links

- **Full Guide**: PRODUCTION_DEPLOYMENT_GUIDE.md
- **Checklist**: PRODUCTION_DEPLOYMENT_CHECKLIST.md
- **Monitoring**: MONITORING_GUIDE.md
- **User Guide**: USER_GUIDE.md

---

## Version Info

**Version**: 1.1.0+2  
**Build Date**: November 1, 2025  
**Feature**: Admin Group Management

---

## Notes

- Always start with 10% rollout
- Monitor closely first 24 hours
- Be ready to rollback if needed
- Respond to user feedback quickly

---

**Good luck! 🚀**

Print this card and keep it handy during deployment.

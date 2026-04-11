# Final Testing Quick Reference

## Quick Start

### Run All Tests
```bash
cd test/e2e
run_all_tests.bat
```

### Run Specific Test Suite
```bash
# Unit tests only
flutter test test/core/ test/features/

# Widget tests only
flutter test test/widgets/

# Integration tests only
flutter test test/integration/

# E2E tests only
flutter test test/e2e/
```

### Verify Requirements
```bash
dart test/e2e/verify_requirements.dart
```

### Generate Coverage Report
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
start coverage/html/index.html
```

## Test Execution Checklist

### Phase 1: Automated Tests ⏱️ ~30 min
- [ ] Run unit tests
- [ ] Run widget tests
- [ ] Run integration tests
- [ ] Run E2E tests
- [ ] Generate coverage report
- [ ] Review failed tests
- [ ] Document issues

### Phase 2: Manual Tests - Superadmin ⏱️ ~2 hours
- [ ] Registration flow (6 tests)
- [ ] Group management (8 tests)
- [ ] Financial box (7 tests)
- [ ] Transfers (10 tests)
- [ ] Analytics (9 tests)
- [ ] Navigation (6 tests)
- [ ] Data visibility (6 tests)

### Phase 3: Manual Tests - Admin ⏱️ ~3 hours
- [ ] Registration flow (8 tests)
- [ ] Group management (9 tests)
- [ ] Financial box (10 tests)
- [ ] Currency exchange (14 tests)
- [ ] Expenses (14 tests)
- [ ] Export (8 tests)
- [ ] Navigation (6 tests)
- [ ] Data visibility (8 tests)

### Phase 4: Manual Tests - User ⏱️ ~2 hours
- [ ] Registration flow (8 tests)
- [ ] Financial box (8 tests)
- [ ] Currency exchange (10 tests)
- [ ] Expenses (10 tests)
- [ ] Export (8 tests)
- [ ] Navigation (5 tests)
- [ ] Data visibility (8 tests)

### Phase 5: Cross-Flavor Tests ⏱️ ~1 hour
- [ ] Balance verification (5 tests)
- [ ] Data visibility (8 tests)
- [ ] Filter persistence (4 tests)

### Phase 6: Special Tests ⏱️ ~2 hours
- [ ] Offline functionality (8 tests)
- [ ] Error scenarios (10 tests)
- [ ] Localization (6 tests)
- [ ] Accessibility (8 tests)
- [ ] Performance (8 tests)
- [ ] Security (8 tests)

### Phase 7: Build Tests ⏱️ ~30 min
- [ ] Build superadmin APK
- [ ] Build admin APK
- [ ] Build user APK
- [ ] Install and verify all APKs

**Total Estimated Time: ~11 hours**

## Bug Priority Guide

### P0 - Critical (Fix Immediately)
- App crashes
- Data loss
- Security vulnerabilities
- Core functionality broken
- Blocks all testing

**Action:** Stop testing, fix immediately, retest

### P1 - High (Fix Before Release)
- Major feature broken
- Poor user experience
- Workaround exists but difficult
- Affects multiple users

**Action:** Fix before release, continue testing other areas

### P2 - Medium (Fix If Time Permits)
- Minor feature issue
- Cosmetic problems
- Edge cases
- Affects few users

**Action:** Document, fix if time permits, can defer to next release

### P3 - Low (Future Enhancement)
- Nice to have fixes
- Minor improvements
- Very rare edge cases
- Enhancement requests

**Action:** Document for future consideration

## Common Test Scenarios

### Test: Insufficient Balance
```
1. Login as [role]
2. Navigate to [Transfer/Exchange/Expense]
3. Enter amount > current balance
4. Submit
✓ Should show error: "Insufficient [currency] balance"
✓ Should show current balance
✓ Should not submit
```

### Test: Offline Mode
```
1. Login as [role]
2. Enable airplane mode
3. Navigate to [page]
✓ Should show offline indicator
✓ Should show cached data
✓ Should prevent balance operations
4. Create [expense/transfer]
✓ Should queue operation
5. Disable airplane mode
✓ Should auto-sync
✓ Should show success
```

### Test: Filter Persistence
```
1. Login as [Admin/User]
2. Navigate to Expenses
3. Apply filters (date, currency, user)
4. Navigate to Export
✓ Filters should be applied
5. Return to Expenses
✓ Filters should be restored
6. Logout and login
✓ Filters should be cleared
```

### Test: Data Visibility
```
Superadmin:
✓ Can see admin profiles
✓ Can see admin balances
✗ Cannot see user data directly
✗ Cannot create expenses

Admin:
✓ Can see all users in group
✓ Can see user expenses
✓ Can see user exchanges
✗ Cannot see other admin groups

User:
✓ Can see own data only
✗ Cannot see other users
✗ Cannot see admin details
```

## Quick Bug Report

```
BUG-[ID]: [Title]
Priority: [P0/P1/P2/P3]
Flavor: [Superadmin/Admin/User/All]

Steps:
1. [Step 1]
2. [Step 2]
3. [Step 3]

Expected: [What should happen]
Actual: [What happened]

Device: [Model]
OS: [Version]
```

## Test Status Indicators

- ✅ **Pass** - Test passed, no issues
- ❌ **Fail** - Test failed, bug found
- ⚠️ **Warning** - Test passed with minor issues
- 🚫 **Blocked** - Cannot test, dependency missing
- ⏭️ **Skipped** - Intentionally not tested
- 🔄 **Retest** - Needs retesting after fix

## Coverage Targets

- **Unit Tests:** 80%+ coverage
- **Widget Tests:** 70%+ coverage
- **Integration Tests:** 60%+ coverage
- **Overall:** 75%+ coverage

## Performance Benchmarks

| Metric | Target | Acceptable | Poor |
|--------|--------|------------|------|
| Home page load | <2s | <3s | >3s |
| List scrolling | 60fps | 50fps | <50fps |
| API response | <500ms | <1s | >1s |
| Image load | <1s | <2s | >2s |
| App startup | <3s | <5s | >5s |
| Memory usage | <200MB | <300MB | >300MB |

## Accessibility Checklist

- [ ] All buttons have semantic labels
- [ ] All images have alt text
- [ ] Contrast ratio ≥ 4.5:1
- [ ] Touch targets ≥ 48dp
- [ ] Text scales to 200%
- [ ] Screen reader announces correctly
- [ ] Keyboard navigation works
- [ ] Focus indicators visible

## Security Checklist

- [ ] Tokens in secure storage
- [ ] No sensitive data in logs
- [ ] HTTPS for all API calls
- [ ] Certificate pinning enabled
- [ ] Auto-logout after 30 min
- [ ] Data cleared on logout
- [ ] Input validation working
- [ ] SQL injection prevented

## Localization Checklist

- [ ] Switch to Arabic works
- [ ] RTL layout correct
- [ ] All text translated
- [ ] No hardcoded strings
- [ ] Numbers formatted correctly
- [ ] Dates formatted correctly
- [ ] Currency symbols correct
- [ ] Switch to English works

## Files Reference

| File | Purpose |
|------|---------|
| `test/e2e/final_comprehensive_test.dart` | E2E test suite |
| `test/e2e/test_execution_plan.md` | Manual test checklist |
| `test/e2e/bug_tracker.md` | Bug tracking |
| `test/e2e/FINAL_TEST_REPORT.md` | Test report template |
| `test/e2e/verify_requirements.dart` | Requirements verification |
| `test/e2e/run_all_tests.bat` | Automated test runner |

## Contact

**Questions about testing?**
- Check test_execution_plan.md for detailed procedures
- Check bug_tracker.md for bug reporting
- Check FINAL_TEST_REPORT.md for report template

## Tips

1. **Test in order** - Follow the phase sequence
2. **Document everything** - Even small issues
3. **Take screenshots** - Visual proof helps
4. **Test on real devices** - Emulators miss issues
5. **Test offline** - Network issues are common
6. **Test slow networks** - 3G reveals problems
7. **Test with real data** - Edge cases appear
8. **Test all flavors** - Each is different
9. **Retest after fixes** - Regression happens
10. **Ask questions** - Better to clarify than assume

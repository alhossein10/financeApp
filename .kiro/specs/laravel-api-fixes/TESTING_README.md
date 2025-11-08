# Laravel API Integration - Testing Documentation

## Overview
This directory contains comprehensive testing documentation and resources for validating the Laravel API integration fixes implemented in Tasks 1-18.

## Testing Resources

### 1. 📋 Manual Testing Checklist
**File:** `MANUAL_TESTING_CHECKLIST.md`

A comprehensive 20-section checklist covering all aspects of the Laravel API integration:
- Pre-testing setup
- Authentication and token management
- All module testing (Transfers, Incoming, Expenses, Fund Box, Admin Dashboard, etc.)
- Error handling for all HTTP status codes
- Role-based access control
- Date formatting and pagination
- Offline mode and batch sync
- Field mapping verification
- Performance testing
- User acceptance testing

**Use this for:** Complete, systematic testing of all features

### 2. 🚀 Quick Test Guide
**File:** `QUICK_TEST_GUIDE.md`

A streamlined guide for rapid validation:
- 30-minute quick test flow
- Critical tests checklist
- Field mapping quick reference
- Common issues and solutions
- Quick Postman test instructions

**Use this for:** Fast validation before detailed testing

### 3. 🤖 Automated API Test Script
**File:** `test_api_endpoints.dart`

A Dart script that automatically tests all API endpoints:
- Authentication
- Transfers, Incoming, Expenses CRUD
- Fund Box (admin only)
- Admin Dashboard (admin only)
- Profile, Export, Audit Logs
- Field mapping verification

**Usage:**
```bash
dart run .kiro/specs/laravel-api-fixes/test_api_endpoints.dart
```

**Use this for:** Automated baseline testing

### 4. 📝 Test Results Template
**File:** `TEST_RESULTS_TEMPLATE.md`

A structured template for documenting test results:
- Executive summary
- Detailed test results for each module
- Issues tracking (Critical, High, Medium, Low)
- Performance metrics
- Sign-off sections

**Use this for:** Documenting and reporting test results

### 5. 📊 Testing Summary
**File:** `TASK_19_MANUAL_TESTING_SUMMARY.md`

Comprehensive overview of the testing approach:
- Testing phases (1-8)
- Testing timeline (5 days)
- Expected results
- Common issues and solutions
- Sign-off criteria

**Use this for:** Understanding the overall testing strategy

## Testing Workflow

### Step 1: Setup (Day 1)
1. Read `QUICK_TEST_GUIDE.md` for setup instructions
2. Start Laravel backend
3. Create test accounts (admin and user)
4. Import Postman collection
5. Run automated test script to verify baseline

### Step 2: Quick Validation (30 minutes)
1. Follow `QUICK_TEST_GUIDE.md`
2. Test critical features in both flavors
3. Verify field mappings
4. Test access control
5. If all pass, proceed to full testing

### Step 3: Full Manual Testing (Days 2-4)
1. Open `MANUAL_TESTING_CHECKLIST.md`
2. Work through each section systematically
3. Document results in `TEST_RESULTS_TEMPLATE.md`
4. Take screenshots of any issues
5. Log all findings

### Step 4: Issue Resolution (As needed)
1. Review documented issues
2. Prioritize by severity
3. Fix critical and high priority issues
4. Re-test affected areas
5. Update test results

### Step 5: Final Validation (Day 5)
1. Re-run automated test script
2. Re-test any previously failed scenarios
3. Complete final sign-off
4. Prepare release documentation

## Test Accounts

### Regular User
- **Email:** user@test.com
- **Password:** password
- **Role:** user
- **Purpose:** Test user-level features and access control

### Admin User
- **Email:** admin@test.com
- **Password:** password
- **Role:** admin
- **Purpose:** Test admin-level features and full access

## Critical Test Areas

### 🔴 Must Pass (Blocking Issues)
1. **Authentication** - Login, token management, logout
2. **Field Mappings** - All DTOs match API specification exactly
3. **CRUD Operations** - Transfers, Incoming, Expenses work correctly
4. **Access Control** - Admin features blocked for regular users
5. **Error Handling** - 403 errors don't crash app
6. **Date Format** - All dates sent as YYYY-MM-DD

### 🟡 Should Pass (High Priority)
1. **Profile Management** - Get, update, change password
2. **Export Functionality** - PDF and Excel generation
3. **Batch Sync** - Offline queue and auto-sync
4. **File Upload** - Upload, download, delete files
5. **Audit Logs** - Admin can view, user gets 403
6. **Pagination** - Load more, last page handling

### 🟢 Nice to Have (Medium Priority)
1. **Date Localization** - Dates display per locale
2. **Large Datasets** - Pagination handles 100+ items
3. **Performance** - Response times meet benchmarks
4. **Conflict Resolution** - Sync conflicts handled
5. **Manual Sync** - User can trigger sync

## Field Mapping Reference

### Transfers
```
App Field       → API Field
fromAccount     → from_account
toAccount       → to_account
amount          → amount
date            → date (YYYY-MM-DD)
description     → description
```

### Incoming
```
App Field       → API Field
source          → source
paymentMethod   → payment_method
amount          → amount
date            → date (YYYY-MM-DD)
description     → description
```

### Fund Box
```
App Field       → API Field
totalBalance    → total_balance
lastUpdated     → last_updated
```

### Admin Stats
```
App Field              → API Field
totalUsers             → total_users
totalExpenses          → total_expenses
totalIncome            → total_income
totalTransfers         → total_transfers
totalAmountExpenses    → total_amount_expenses
totalAmountIncome      → total_amount_income
fundBoxBalance         → fund_box_balance
```

## Common Issues

### Issue: Field Mapping Mismatch
**Symptom:** 422 errors, data doesn't save
**Check:** Compare DTO field names with API spec
**Fix:** Update DTO @JsonKey annotations

### Issue: 403 Not Handled
**Symptom:** App crashes on admin feature access
**Check:** Error handling in BLoCs
**Fix:** Add proper ApiException handling

### Issue: Date Format Wrong
**Symptom:** 422 errors on date fields
**Check:** DateFormatter usage
**Fix:** Ensure YYYY-MM-DD format

### Issue: Pagination Broken
**Symptom:** All items load at once
**Check:** per_page and page parameters
**Fix:** Verify PaginationHelper implementation

### Issue: Offline Sync Fails
**Symptom:** Items don't sync when online
**Check:** QueueManager and ConnectivityMonitor
**Fix:** Verify batch sync endpoint

## Performance Benchmarks

| Operation | Expected | Acceptable | Unacceptable |
|-----------|----------|------------|--------------|
| Login | < 500ms | < 1s | > 1s |
| CRUD | < 300ms | < 500ms | > 500ms |
| List | < 500ms | < 1s | > 1s |
| Dashboard | < 1s | < 2s | > 2s |
| Export | < 3s | < 5s | > 5s |

## Testing Tools

### Required
- **Postman** - API baseline testing
- **Flutter DevTools** - Debugging
- **Device/Emulator** - App testing

### Optional
- **Charles Proxy** - Network inspection
- **Android Studio Profiler** - Performance
- **Xcode Instruments** - iOS performance

## Sign-Off Criteria

### Development ✅
- [ ] All unit tests pass (Task 16)
- [ ] All integration tests pass (Task 17)
- [ ] All widget tests pass (Task 18)
- [ ] Automated API test passes
- [ ] Manual testing checklist complete
- [ ] No critical issues

### QA ✅
- [ ] All test scenarios executed
- [ ] All field mappings verified
- [ ] All error scenarios tested
- [ ] Performance benchmarks met
- [ ] Test results documented

### Product ✅
- [ ] All features work as expected
- [ ] User experience is smooth
- [ ] Error messages are clear
- [ ] Ready for release

## Timeline

| Day | Activity | Duration |
|-----|----------|----------|
| 1 | Setup and baseline testing | 4 hours |
| 2 | User flavor testing | 6 hours |
| 3 | Admin flavor testing | 6 hours |
| 4 | Edge cases and performance | 6 hours |
| 5 | Final validation and sign-off | 4 hours |

**Total:** ~26 hours (5 days)

## Next Steps After Testing

1. **Document Results**
   - Complete test results template
   - Create bug reports for issues
   - Update issue tracker

2. **Fix Issues**
   - Prioritize by severity
   - Fix and re-test
   - Update documentation

3. **Prepare Release**
   - Update Task 20 (Documentation)
   - Create release notes
   - Update version numbers
   - Prepare deployment checklist

## Support

If you encounter issues during testing:

1. Check `QUICK_TEST_GUIDE.md` for common solutions
2. Review `TASK_19_MANUAL_TESTING_SUMMARY.md` for detailed guidance
3. Consult the API documentation at `financeApp-backend-main/API_DOCUMENTATION.md`
4. Check existing test implementations in `test/` directory

## Files in This Directory

```
.kiro/specs/laravel-api-fixes/
├── MANUAL_TESTING_CHECKLIST.md      # Comprehensive testing checklist
├── QUICK_TEST_GUIDE.md              # 30-minute quick validation
├── test_api_endpoints.dart          # Automated API testing script
├── TEST_RESULTS_TEMPLATE.md         # Results documentation template
├── TASK_19_MANUAL_TESTING_SUMMARY.md # Testing strategy overview
├── TESTING_README.md                # This file
├── requirements.md                  # Requirements specification
├── design.md                        # Design document
└── tasks.md                         # Implementation tasks
```

## Quick Commands

```bash
# Start backend
cd financeApp-backend-main && php artisan serve

# Run automated test
dart run .kiro/specs/laravel-api-fixes/test_api_endpoints.dart

# Run user flavor
flutter run --flavor user

# Run admin flavor
flutter run --flavor admin

# Run all tests
flutter test

# Run specific test
flutter test test/integration/transfer_crud_integration_test.dart
```

---

**Last Updated:** 2024-01-15
**Version:** 1.0
**Status:** Ready for testing

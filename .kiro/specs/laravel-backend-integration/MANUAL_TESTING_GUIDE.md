# Manual Testing Guide - Laravel Backend Integration

## Overview

This comprehensive manual testing guide covers all scenarios for the Laravel backend integration. Use this document to systematically test the application on Android and iOS devices, including offline scenarios, error handling, and admin features.

## Test Environment Setup

### Prerequisites

- **Android Device/Emulator:** Android 8.0+ (API 26+)
- **iOS Device/Simulator:** iOS 12.0+
- **Laravel Backend:** Running and accessible
- **Test Accounts:**
  - Regular User: `user@test.com` / `password123`
  - Admin User: `admin@test.com` / `password123`
- **Network Tools:** Ability to toggle airplane mode or disable network

### Build Instructions

```bash
# Development build
flutter run --flavor dev

# Production build
flutter build apk --flavor prod
flutter build ios --flavor prod
```

## Testing Checklist

### ✅ = Pass | ❌ = Fail | ⚠️ = Issue Found

---

## 1. Android Device Testing

### 1.1 Authentication Tests (Android)

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Register New User** | 1. Open app<br>2. Tap "Register"<br>3. Enter name, email, password<br>4. Tap "Register" | User created, redirected to home | ☐ | |
| **Login Existing User** | 1. Open app<br>2. Enter credentials<br>3. Tap "Login" | User logged in, home screen shown | ☐ | |
| **Invalid Credentials** | 1. Enter wrong password<br>2. Tap "Login" | Error message displayed | ☐ | |
| **Forgot Password** | 1. Tap "Forgot Password"<br>2. Enter email<br>3. Submit | Success message shown | ☐ | |
| **Logout** | 1. Navigate to profile<br>2. Tap "Logout" | Redirected to login screen | ☐ | |

### 1.2 Expense Management Tests (Android)

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Create Expense** | 1. Tap "Add Expense"<br>2. Fill form<br>3. Save | Expense created, appears in list | ☐ | |
| **Upload Invoice** | 1. Create expense<br>2. Tap "Add Invoice"<br>3. Select image<br>4. Upload | Image uploaded, thumbnail shown | ☐ | |
| **View Expense Details** | 1. Tap expense from list | Details screen shown with all data | ☐ | |
| **Edit Expense** | 1. Open expense<br>2. Tap edit<br>3. Modify data<br>4. Save | Changes saved and reflected | ☐ | |
| **Delete Expense** | 1. Open expense<br>2. Tap delete<br>3. Confirm | Expense removed from list | ☐ | |
| **Filter by Date** | 1. Open filter<br>2. Select date range<br>3. Apply | Only expenses in range shown | ☐ | |
| **Pagination** | 1. Scroll to bottom of list | Next page loads automatically | ☐ | |
| **Multi-Currency Display** | 1. Create expense with USD, SYP, TRY<br>2. View in list | All currencies displayed | ☐ | |


### 1.3 Transfer Management Tests (Android)

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Create Transfer** | 1. Tap "Add Transfer"<br>2. Fill recipient, amount<br>3. Save | Transfer created successfully | ☐ | |
| **Add Exchange Info** | 1. Open transfer<br>2. Add exchange details<br>3. Save | Exchange info saved | ☐ | |
| **View Transfer List** | 1. Navigate to transfers | All transfers displayed | ☐ | |
| **Edit Transfer** | 1. Open transfer<br>2. Edit details<br>3. Save | Changes reflected | ☐ | |
| **Delete Transfer** | 1. Open transfer<br>2. Delete<br>3. Confirm | Transfer removed | ☐ | |

### 1.4 Incoming Funds Tests (Android)

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Create Incoming** | 1. Tap "Add Incoming"<br>2. Fill form<br>3. Save | Incoming record created | ☐ | |
| **View Incoming List** | 1. Navigate to incoming | All records shown | ☐ | |
| **Edit Incoming** | 1. Open record<br>2. Edit<br>3. Save | Changes saved | ☐ | |
| **Delete Incoming** | 1. Open record<br>2. Delete<br>3. Confirm | Record removed | ☐ | |
| **Calculate Totals** | 1. View incoming list | Total amount displayed correctly | ☐ | |

### 1.5 Profile Management Tests (Android)

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **View Profile** | 1. Navigate to profile | User info and stats shown | ☐ | |
| **Update Name** | 1. Edit profile<br>2. Change name<br>3. Save | Name updated | ☐ | |
| **Update Email** | 1. Edit profile<br>2. Change email<br>3. Save | Email updated | ☐ | |
| **Change Password** | 1. Tap "Change Password"<br>2. Enter old/new<br>3. Save | Password changed | ☐ | |
| **View Statistics** | 1. Open profile | Expense count, totals shown | ☐ | |

### 1.6 Export Features Tests (Android)

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Export to PDF** | 1. Navigate to export<br>2. Select date range<br>3. Export PDF | PDF generated and downloadable | ☐ | |
| **Export to Excel** | 1. Navigate to export<br>2. Select date range<br>3. Export Excel | Excel file generated | ☐ | |
| **Check Export Status** | 1. Start export<br>2. Monitor status | Progress shown, completion notified | ☐ | |
| **Download Export** | 1. Export completes<br>2. Tap download | File downloaded to device | ☐ | |

### 1.7 Admin Features Tests (Android)

**Note:** Login as admin user for these tests

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **View Dashboard** | 1. Login as admin<br>2. Navigate to dashboard | Stats displayed (users, expenses, etc.) | ☐ | |
| **View All Users** | 1. Open admin dashboard<br>2. View users section | All users listed with activity | ☐ | |
| **View Fund Box** | 1. Navigate to fund box | Current balance shown | ☐ | |
| **Update Fund Box** | 1. Open fund box<br>2. Update balance<br>3. Save | Balance updated | ☐ | |
| **View Audit Logs** | 1. Navigate to audit logs | All system actions logged | ☐ | |
| **Filter Audit Logs** | 1. Open filters<br>2. Select user/action<br>3. Apply | Filtered logs shown | ☐ | |
| **View Analytics** | 1. Open analytics<br>2. Select date range | Charts and stats displayed | ☐ | |
| **System-Wide Export** | 1. Navigate to export<br>2. Select "All Users"<br>3. Export | All users' data exported | ☐ | |

### 1.8 UI/UX Tests (Android)

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Loading Indicators** | 1. Perform any API action | Loading spinner shown | ☐ | |
| **Error Messages** | 1. Trigger error (invalid input) | Clear error message displayed | ☐ | |
| **Success Messages** | 1. Complete action successfully | Success toast/snackbar shown | ☐ | |
| **Navigation** | 1. Navigate between screens | Smooth transitions, no lag | ☐ | |
| **Back Button** | 1. Press Android back button | Proper navigation behavior | ☐ | |
| **Orientation Change** | 1. Rotate device | UI adapts correctly | ☐ | |
| **Dark Mode** | 1. Enable dark mode<br>2. Navigate app | All screens support dark mode | ☐ | |
| **Language Switch** | 1. Change language to Arabic<br>2. Navigate app | All text translated | ☐ | |

---

## 2. iOS Device Testing

### 2.1 Authentication Tests (iOS)

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Register New User** | 1. Open app<br>2. Tap "Register"<br>3. Enter details<br>4. Submit | User created, home shown | ☐ | |
| **Login Existing User** | 1. Enter credentials<br>2. Tap "Login" | Logged in successfully | ☐ | |
| **Face ID/Touch ID** | 1. Enable biometric<br>2. Login with biometric | Biometric auth works | ☐ | |
| **Invalid Credentials** | 1. Enter wrong password | Error shown | ☐ | |
| **Logout** | 1. Tap logout | Redirected to login | ☐ | |

### 2.2 Expense Management Tests (iOS)

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Create Expense** | 1. Tap "+"<br>2. Fill form<br>3. Save | Expense created | ☐ | |
| **Upload Invoice (Camera)** | 1. Create expense<br>2. Tap camera<br>3. Take photo<br>4. Upload | Photo uploaded | ☐ | |
| **Upload Invoice (Gallery)** | 1. Create expense<br>2. Select from gallery<br>3. Upload | Image uploaded | ☐ | |
| **View Expense** | 1. Tap expense | Details shown | ☐ | |
| **Edit Expense** | 1. Edit expense<br>2. Save | Changes saved | ☐ | |
| **Delete Expense** | 1. Swipe to delete<br>2. Confirm | Expense removed | ☐ | |
| **Pull to Refresh** | 1. Pull down on list | List refreshes | ☐ | |

### 2.3 Transfer Management Tests (iOS)

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Create Transfer** | 1. Add transfer<br>2. Fill form<br>3. Save | Transfer created | ☐ | |
| **View Transfers** | 1. Navigate to transfers | All transfers shown | ☐ | |
| **Edit Transfer** | 1. Edit transfer<br>2. Save | Changes saved | ☐ | |
| **Delete Transfer** | 1. Swipe to delete | Transfer removed | ☐ | |

### 2.4 Incoming Funds Tests (iOS)

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Create Incoming** | 1. Add incoming<br>2. Fill form<br>3. Save | Record created | ☐ | |
| **View List** | 1. Navigate to incoming | All records shown | ☐ | |
| **Edit Incoming** | 1. Edit record<br>2. Save | Changes saved | ☐ | |
| **Delete Incoming** | 1. Swipe to delete | Record removed | ☐ | |

### 2.5 Profile Management Tests (iOS)

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **View Profile** | 1. Navigate to profile | Info displayed | ☐ | |
| **Update Profile** | 1. Edit profile<br>2. Save | Changes saved | ☐ | |
| **Change Password** | 1. Change password<br>2. Save | Password updated | ☐ | |

### 2.6 Admin Features Tests (iOS)

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **View Dashboard** | 1. Login as admin<br>2. Open dashboard | Stats shown | ☐ | |
| **Manage Fund Box** | 1. Open fund box<br>2. Update<br>3. Save | Balance updated | ☐ | |
| **View Audit Logs** | 1. Navigate to logs | Logs displayed | ☐ | |
| **View Analytics** | 1. Open analytics | Charts shown | ☐ | |

### 2.7 UI/UX Tests (iOS)

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Loading Indicators** | 1. Perform API action | Loading shown | ☐ | |
| **Error Messages** | 1. Trigger error | Error displayed | ☐ | |
| **Success Messages** | 1. Complete action | Success shown | ☐ | |
| **Navigation** | 1. Navigate app | Smooth transitions | ☐ | |
| **Swipe Gestures** | 1. Use swipe gestures | Gestures work correctly | ☐ | |
| **Dark Mode** | 1. Enable dark mode | UI adapts | ☐ | |
| **Accessibility** | 1. Enable VoiceOver<br>2. Navigate | VoiceOver works | ☐ | |

---

## 3. Offline Scenario Testing

### 3.1 Offline Creation Tests

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Create Expense Offline** | 1. Enable airplane mode<br>2. Create expense<br>3. Save | Expense saved locally, "Pending Sync" shown | ☐ | |
| **Create Transfer Offline** | 1. Disable network<br>2. Create transfer<br>3. Save | Transfer queued for sync | ☐ | |
| **Create Incoming Offline** | 1. Go offline<br>2. Create incoming<br>3. Save | Record queued | ☐ | |
| **Multiple Offline Actions** | 1. Go offline<br>2. Create 5 expenses<br>3. Edit 2 transfers<br>4. Delete 1 incoming | All actions queued | ☐ | |

### 3.2 Offline Viewing Tests

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **View Cached Expenses** | 1. Load expenses online<br>2. Go offline<br>3. View expenses | Cached data shown with offline indicator | ☐ | |
| **View Cached Transfers** | 1. Load transfers online<br>2. Go offline<br>3. View transfers | Cached data displayed | ☐ | |
| **View Profile Offline** | 1. Go offline<br>2. Open profile | Cached profile shown | ☐ | |
| **Offline Indicator** | 1. Go offline<br>2. Navigate app | Offline indicator visible | ☐ | |

### 3.3 Sync When Online Tests

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Auto Sync on Reconnect** | 1. Create items offline<br>2. Go online | Queue processes automatically | ☐ | |
| **Sync Progress** | 1. Queue multiple items<br>2. Go online<br>3. Watch sync | Progress indicator shown | ☐ | |
| **Sync Success** | 1. Complete sync | All items synced, IDs updated | ☐ | |
| **Partial Sync Failure** | 1. Queue items<br>2. Sync with some failures | Failed items remain in queue | ☐ | |
| **Retry Failed Sync** | 1. Have failed items<br>2. Tap retry | Failed items retry | ☐ | |
| **Batch Sync** | 1. Create 20 items offline<br>2. Go online | Items synced in batches | ☐ | |

### 3.4 Conflict Resolution Tests

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Edit Same Record** | 1. Edit expense on device A<br>2. Edit same expense on device B<br>3. Sync both | Conflict dialog shown | ☐ | |
| **Server Wins** | 1. Trigger conflict<br>2. Choose "Server Wins" | Server version kept | ☐ | |
| **Client Wins** | 1. Trigger conflict<br>2. Choose "Client Wins" | Local version kept | ☐ | |

---

## 4. Error Scenario Testing

### 4.1 Network Error Tests

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Connection Timeout** | 1. Slow network<br>2. Perform action | Timeout error shown, retry option | ☐ | |
| **Server Unreachable** | 1. Stop backend<br>2. Perform action | "Server unreachable" error | ☐ | |
| **Intermittent Connection** | 1. Toggle network on/off<br>2. Perform actions | Actions queued and synced | ☐ | |

### 4.2 Authentication Error Tests

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Invalid Token** | 1. Manually invalidate token<br>2. Make API call | Redirected to login | ☐ | |
| **Token Expiry** | 1. Wait for token expiry<br>2. Make API call | Token auto-refreshed | ☐ | |
| **Session Timeout** | 1. Leave app idle<br>2. Return after timeout | Redirected to login | ☐ | |

### 4.3 Validation Error Tests

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Empty Required Fields** | 1. Submit form with empty fields | Validation errors shown | ☐ | |
| **Invalid Email Format** | 1. Enter invalid email<br>2. Submit | Email format error shown | ☐ | |
| **Password Too Short** | 1. Enter short password<br>2. Submit | Password length error shown | ☐ | |
| **Invalid Date** | 1. Enter future date<br>2. Submit | Date validation error shown | ☐ | |
| **Negative Amount** | 1. Enter negative amount<br>2. Submit | Amount validation error shown | ☐ | |

### 4.4 Permission Error Tests

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Regular User Access Admin** | 1. Login as regular user<br>2. Try to access admin features | 403 error, access denied message | ☐ | |
| **Access Other User's Data** | 1. Try to access another user's expense | 403 error shown | ☐ | |
| **Unauthorized Action** | 1. Attempt unauthorized action | Permission error shown | ☐ | |

### 4.5 File Upload Error Tests

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **File Too Large** | 1. Upload file > 10MB | File size error shown | ☐ | |
| **Invalid File Type** | 1. Upload non-image file | File type error shown | ☐ | |
| **Upload Failure** | 1. Simulate upload failure | Error shown, retry option | ☐ | |
| **Corrupted Image** | 1. Upload corrupted image | Error handled gracefully | ☐ | |

### 4.6 Rate Limiting Tests

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Rapid Requests** | 1. Make many rapid requests | Rate limit message shown | ☐ | |
| **Retry After Limit** | 1. Get rate limited<br>2. Wait<br>3. Retry | Request succeeds after wait | ☐ | |
| **Countdown Timer** | 1. Get rate limited | Countdown timer shown | ☐ | |

---

## 5. Performance Testing

### 5.1 Load Time Tests

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **App Startup** | 1. Launch app | App loads in < 2 seconds | ☐ | |
| **Login Time** | 1. Login | Login completes in < 1 second | ☐ | |
| **List Load Time** | 1. Open expense list | List loads in < 500ms | ☐ | |
| **Image Load Time** | 1. View invoice | Image loads in < 1 second | ☐ | |

### 5.2 Pagination Tests

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Large List Scrolling** | 1. Scroll through 100+ items | Smooth scrolling, no lag | ☐ | |
| **Lazy Loading** | 1. Scroll to bottom | Next page loads automatically | ☐ | |
| **Pull to Refresh** | 1. Pull down on list | List refreshes quickly | ☐ | |

### 5.3 Memory Tests

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Memory Usage** | 1. Use app for 10 minutes<br>2. Check memory | No memory leaks | ☐ | |
| **Image Caching** | 1. View many images<br>2. Check memory | Images cached efficiently | ☐ | |
| **Background Memory** | 1. Background app<br>2. Check memory | Memory released | ☐ | |

---

## 6. Security Testing

### 6.1 Token Security Tests

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Token Storage** | 1. Login<br>2. Check storage | Token in secure storage | ☐ | |
| **Token Not Logged** | 1. Login<br>2. Check logs | Token not in logs | ☐ | |
| **Token Cleared on Logout** | 1. Logout<br>2. Check storage | Token removed | ☐ | |

### 6.2 Data Security Tests

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **HTTPS Only** | 1. Check network traffic | All requests use HTTPS | ☐ | |
| **Sensitive Data Not Logged** | 1. Perform actions<br>2. Check logs | No passwords/tokens logged | ☐ | |
| **Background Data Clear** | 1. Background app<br>2. Check memory | Sensitive data cleared | ☐ | |

---

## 7. Localization Testing

### 7.1 English Language Tests

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **All Screens in English** | 1. Set language to English<br>2. Navigate all screens | All text in English | ☐ | |
| **Error Messages** | 1. Trigger errors | Errors in English | ☐ | |
| **Date Format** | 1. View dates | Dates in English format | ☐ | |

### 7.2 Arabic Language Tests

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **All Screens in Arabic** | 1. Set language to Arabic<br>2. Navigate all screens | All text in Arabic | ☐ | |
| **RTL Layout** | 1. Switch to Arabic | Layout mirrors correctly | ☐ | |
| **Error Messages** | 1. Trigger errors | Errors in Arabic | ☐ | |
| **Date Format** | 1. View dates | Dates in Arabic format | ☐ | |

---

## 8. Data Migration Testing

### 8.1 SQLite Migration Tests

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Export SQLite Data** | 1. Open migration tool<br>2. Export data | Data exported to JSON | ☐ | |
| **Upload to Laravel** | 1. Upload exported data | Data uploaded successfully | ☐ | |
| **Verify Data Integrity** | 1. Compare old vs new data | All data matches | ☐ | |
| **Delete Local Database** | 1. Complete migration<br>2. Delete SQLite | Local DB removed | ☐ | |

---

## 9. Cross-Platform Consistency

### 9.1 Feature Parity Tests

| Test Case | Android Status | iOS Status | Notes |
|-----------|----------------|------------|-------|
| **Authentication** | ☐ | ☐ | |
| **Expense CRUD** | ☐ | ☐ | |
| **Transfer CRUD** | ☐ | ☐ | |
| **Incoming CRUD** | ☐ | ☐ | |
| **File Upload** | ☐ | ☐ | |
| **Offline Mode** | ☐ | ☐ | |
| **Admin Features** | ☐ | ☐ | |
| **Export** | ☐ | ☐ | |

---

## 10. Edge Cases

### 10.1 Boundary Tests

| Test Case | Steps | Expected Result | Status | Notes |
|-----------|-------|-----------------|--------|-------|
| **Very Long Description** | 1. Enter 1000 char description<br>2. Save | Handled gracefully | ☐ | |
| **Very Large Amount** | 1. Enter amount > 1 billion<br>2. Save | Handled or validated | ☐ | |
| **Special Characters** | 1. Enter special chars<br>2. Save | Characters handled correctly | ☐ | |
| **Empty Database** | 1. Fresh install<br>2. View lists | Empty states shown | ☐ | |
| **1000+ Records** | 1. Create many records<br>2. View list | Pagination works | ☐ | |

---

## Test Execution Instructions

### How to Use This Guide

1. **Print or open this document** on a separate device
2. **Test one section at a time** - don't rush
3. **Mark each test** with ✅, ❌, or ⚠️
4. **Document issues** in the Notes column
5. **Take screenshots** of any bugs found
6. **Report critical issues** immediately

### Test Execution Order

1. Start with **Authentication** (both platforms)
2. Test **Core Features** (Expenses, Transfers, Incoming)
3. Test **Offline Scenarios**
4. Test **Error Scenarios**
5. Test **Admin Features**
6. Test **Performance**
7. Test **Security**
8. Test **Localization**

### Issue Reporting Template

When you find an issue, document it as follows:

```
**Issue ID:** [Unique ID]
**Severity:** [Critical/High/Medium/Low]
**Platform:** [Android/iOS/Both]
**Test Case:** [Test case name]
**Steps to Reproduce:**
1. Step 1
2. Step 2
3. Step 3

**Expected Result:** [What should happen]
**Actual Result:** [What actually happened]
**Screenshots:** [Attach screenshots]
**Device Info:** [Device model, OS version]
**App Version:** [App version number]
```

### Severity Levels

- **Critical:** App crashes, data loss, security issues
- **High:** Major feature broken, blocking workflow
- **Medium:** Feature partially works, workaround exists
- **Low:** Minor UI issue, cosmetic problem

---

## Test Summary Report

### Overall Results

- **Total Test Cases:** [Count]
- **Passed:** [Count]
- **Failed:** [Count]
- **Issues Found:** [Count]

### Platform-Specific Results

**Android:**
- Passed: [Count]
- Failed: [Count]
- Issues: [Count]

**iOS:**
- Passed: [Count]
- Failed: [Count]
- Issues: [Count]

### Critical Issues

List any critical issues that must be fixed before release:

1. [Issue description]
2. [Issue description]
3. [Issue description]

### Recommendations

Based on testing, provide recommendations:

- [ ] Ready for production release
- [ ] Needs minor fixes
- [ ] Needs major fixes
- [ ] Not ready for release

### Sign-Off

**Tester Name:** ___________________
**Date:** ___________________
**Signature:** ___________________

---

## Additional Resources

### Useful Commands

```bash
# Check app logs (Android)
adb logcat | grep Flutter

# Check app logs (iOS)
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "Runner"'

# Clear app data (Android)
adb shell pm clear com.yourapp.package

# Uninstall app (Android)
adb uninstall com.yourapp.package

# Uninstall app (iOS)
xcrun simctl uninstall booted com.yourapp.bundle
```

### Network Simulation

**Android:**
- Use airplane mode
- Use Android Studio Network Profiler
- Use Charles Proxy for request inspection

**iOS:**
- Use airplane mode
- Use Network Link Conditioner
- Use Charles Proxy for request inspection

### Test Data

Create test data with various scenarios:
- Expenses with all currency combinations
- Transfers with and without exchange info
- Incoming funds with various amounts
- Users with different roles
- Large datasets for performance testing

---

## Conclusion

This manual testing guide ensures comprehensive coverage of all Laravel backend integration features. Complete all test cases systematically and document any issues found. The goal is to ensure a stable, performant, and user-friendly application across both Android and iOS platforms.

**Remember:** Quality testing takes time. Don't rush through the tests. Each test case is important for ensuring a great user experience.

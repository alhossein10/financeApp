# Admin Group Management - Manual Testing Guide

## Overview

This guide provides comprehensive manual testing procedures for the Admin Group Management feature. Follow these test cases to ensure all functionality works correctly across different platforms and scenarios.

## Prerequisites

- Backend API is running and accessible
- Flutter app is built for the target platform (Android/iOS)
- Test devices/emulators are ready
- Both English and Arabic language settings available

## Test Environment Setup

### Android Testing
- Device: Physical device or emulator (API 21+)
- Screen sizes: Phone (5-6"), Tablet (7-10")
- OS versions: Android 5.0+

### iOS Testing
- Device: Physical device or simulator (iOS 11+)
- Screen sizes: iPhone (4.7-6.7"), iPad (9.7-12.9")
- OS versions: iOS 11+

## Test Cases

### 1. Admin Registration Flow

#### Test 1.1: Admin Registration with Group Creation
**Steps:**
1. Launch the app
2. Navigate to registration page
3. Select "Admin" role
4. Fill in:
   - Name: "Test Admin"
   - Email: "admin@test.com"
   - Password: "TestPass123!"
   - Organization Name: "Test Org" (optional)
   - Department Name: "IT" (optional)
5. Submit registration

**Expected Results:**
- ✅ Registration succeeds
- ✅ Success dialog displays with 6-character group code
- ✅ Group code has copy button
- ✅ Copy button works and shows confirmation
- ✅ Code is alphanumeric (A-Z, 0-9)
- ✅ User is logged in automatically
- ✅ Dashboard loads successfully

**Test on:**
- [ ] Android Phone (English)
- [ ] Android Phone (Arabic)
- [ ] Android Tablet (English)
- [ ] iOS iPhone (English)
- [ ] iOS iPhone (Arabic)
- [ ] iOS iPad (English)

---

#### Test 1.2: Admin Registration - Organization/Department Optional
**Steps:**
1. Register as admin
2. Leave organization and department fields empty
3. Submit registration

**Expected Results:**
- ✅ Registration succeeds without organization/department
- ✅ Group code is still generated
- ✅ No validation errors

**Test on:**
- [ ] Android (English)
- [ ] iOS (English)

---

### 2. User Registration Flow

#### Test 2.1: User Registration with Valid Group Code
**Steps:**
1. Get group code from admin registration
2. Navigate to registration page
3. Select "User" role
4. Fill in:
   - Name: "Test User"
   - Email: "user@test.com"
   - Password: "TestPass123!"
   - Group Code: [admin's code]
   - Organization Name: "Test Org" (optional)
   - Department Name: "Sales" (optional)
5. Submit registration

**Expected Results:**
- ✅ Registration succeeds
- ✅ User is logged in automatically
- ✅ User can access their group info
- ✅ Dashboard loads successfully

**Test on:**
- [ ] Android Phone (English)
- [ ] Android Phone (Arabic)
- [ ] iOS iPhone (English)
- [ ] iOS iPhone (Arabic)

---

#### Test 2.2: User Registration - Invalid Group Code Format
**Steps:**
1. Register as user
2. Enter group code: "ABC" (too short)
3. Submit registration

**Expected Results:**
- ✅ Validation error displays
- ✅ Error message: "Group code must be 6 characters"
- ✅ Registration is blocked

**Test on:**
- [ ] Android (English)
- [ ] Android (Arabic)
- [ ] iOS (English)

---

#### Test 2.3: User Registration - Non-existent Group Code
**Steps:**
1. Register as user
2. Enter group code: "XXXXXX"
3. Submit registration

**Expected Results:**
- ✅ API error displays
- ✅ Error message: "The selected group code is invalid"
- ✅ Registration fails

**Test on:**
- [ ] Android (English)
- [ ] iOS (English)

---

#### Test 2.4: User Registration - Missing Group Code
**Steps:**
1. Register as user
2. Leave group code field empty
3. Submit registration

**Expected Results:**
- ✅ Validation error displays
- ✅ Error message: "The group code field is required"
- ✅ Registration is blocked

**Test on:**
- [ ] Android (English)
- [ ] iOS (English)

---

#### Test 2.5: User Registration - Case Insensitive Code
**Steps:**
1. Get group code from admin (e.g., "ABC123")
2. Register as user
3. Enter lowercase code: "abc123"
4. Submit registration

**Expected Results:**
- ✅ Registration succeeds
- ✅ User joins the correct group
- ✅ Case doesn't matter

**Test on:**
- [ ] Android (English)
- [ ] iOS (English)

---

### 3. Group Management (Admin)

#### Test 3.1: View Group Information
**Steps:**
1. Login as admin
2. Navigate to "Group Management" page
3. Observe displayed information

**Expected Results:**
- ✅ Group code is displayed prominently
- ✅ Copy button is present and functional
- ✅ Group name is displayed (if set)
- ✅ Member count is displayed
- ✅ UI is responsive and clear

**Test on:**
- [ ] Android Phone (English)
- [ ] Android Phone (Arabic)
- [ ] Android Tablet (English)
- [ ] iOS iPhone (English)
- [ ] iOS iPhone (Arabic)
- [ ] iOS iPad (English)

---

#### Test 3.2: View Member List
**Steps:**
1. Login as admin (with at least 3 members)
2. Navigate to "Group Management"
3. Scroll through member list

**Expected Results:**
- ✅ All members are displayed
- ✅ Each member shows: name, email, department
- ✅ Admin is included in the list
- ✅ Remove button is shown for non-admin members
- ✅ Remove button is disabled/hidden for admin
- ✅ List scrolls smoothly

**Test on:**
- [ ] Android Phone (English)
- [ ] Android Phone (Arabic)
- [ ] iOS iPhone (English)
- [ ] iOS iPhone (Arabic)

---

#### Test 3.3: Search Members
**Steps:**
1. Login as admin (with multiple members)
2. Navigate to "Group Management"
3. Enter search term in search field
4. Observe filtered results

**Expected Results:**
- ✅ Search filters members by name
- ✅ Results update in real-time
- ✅ Clear search button works
- ✅ Empty state shows when no results

**Test on:**
- [ ] Android (English)
- [ ] iOS (English)

---

#### Test 3.4: Filter by Department
**Steps:**
1. Login as admin (with members in different departments)
2. Navigate to "Group Management"
3. Select department from filter dropdown
4. Observe filtered results

**Expected Results:**
- ✅ Only members from selected department show
- ✅ Filter can be cleared
- ✅ "All Departments" option shows all members

**Test on:**
- [ ] Android (English)
- [ ] iOS (English)

---

#### Test 3.5: Pagination
**Steps:**
1. Login as admin (with 20+ members)
2. Navigate to "Group Management"
3. Scroll to bottom of list
4. Observe "Load More" or infinite scroll

**Expected Results:**
- ✅ Initial page loads quickly
- ✅ More members load on scroll/button click
- ✅ Loading indicator shows during fetch
- ✅ No duplicate members appear

**Test on:**
- [ ] Android (English)
- [ ] iOS (English)

---

#### Test 3.6: Remove Member
**Steps:**
1. Login as admin
2. Navigate to "Group Management"
3. Click remove button for a user
4. Confirm removal in dialog
5. Observe result

**Expected Results:**
- ✅ Confirmation dialog appears
- ✅ Dialog shows member name
- ✅ Cancel button works
- ✅ Confirm button removes member
- ✅ Success message displays
- ✅ Member disappears from list
- ✅ Member count decreases

**Test on:**
- [ ] Android Phone (English)
- [ ] Android Phone (Arabic)
- [ ] iOS iPhone (English)
- [ ] iOS iPhone (Arabic)

---

#### Test 3.7: Cannot Remove Self
**Steps:**
1. Login as admin
2. Navigate to "Group Management"
3. Find admin in member list
4. Observe remove button

**Expected Results:**
- ✅ Remove button is disabled or hidden for admin
- ✅ Tooltip/message explains why

**Test on:**
- [ ] Android (English)
- [ ] iOS (English)

---

#### Test 3.8: Regenerate Group Code
**Steps:**
1. Login as admin
2. Navigate to "Group Management"
3. Note current group code
4. Click "Regenerate Code" button
5. Confirm in warning dialog
6. Observe result

**Expected Results:**
- ✅ Warning dialog appears
- ✅ Dialog explains old code will be invalid
- ✅ Cancel button works
- ✅ Confirm button regenerates code
- ✅ New code is different from old code
- ✅ New code is 6 characters
- ✅ Success message displays
- ✅ New code is displayed prominently

**Test on:**
- [ ] Android Phone (English)
- [ ] Android Phone (Arabic)
- [ ] iOS iPhone (English)
- [ ] iOS iPhone (Arabic)

---

#### Test 3.9: Old Code Invalid After Regeneration
**Steps:**
1. Login as admin
2. Note current group code
3. Regenerate code
4. Logout
5. Try to register new user with old code

**Expected Results:**
- ✅ Registration fails with old code
- ✅ Error message: "The selected group code is invalid"

**Test on:**
- [ ] Android (English)
- [ ] iOS (English)

---

### 4. Group Information (User)

#### Test 4.1: View Group Info
**Steps:**
1. Login as user (in a group)
2. Navigate to "My Group" page
3. Observe displayed information

**Expected Results:**
- ✅ Group code is displayed
- ✅ Group name is displayed (if set)
- ✅ Admin name is displayed
- ✅ Admin email is displayed
- ✅ Member count is displayed
- ✅ Join date is displayed
- ✅ UI is clear and readable

**Test on:**
- [ ] Android Phone (English)
- [ ] Android Phone (Arabic)
- [ ] iOS iPhone (English)
- [ ] iOS iPhone (Arabic)

---

#### Test 4.2: Not in Group State
**Steps:**
1. Login as user (not in any group)
2. Navigate to profile/settings
3. Observe group section

**Expected Results:**
- ✅ Message: "You are not in a group"
- ✅ "Join Group" button is displayed
- ✅ Button navigates to join page

**Test on:**
- [ ] Android (English)
- [ ] iOS (English)

---

### 5. Join Group (User)

#### Test 5.1: Join Group with Valid Code
**Steps:**
1. Login as user (not in group)
2. Navigate to "Join Group" page
3. Enter valid group code
4. Submit

**Expected Results:**
- ✅ Success message displays
- ✅ User is redirected to group info page
- ✅ Group information is displayed
- ✅ User can see admin details

**Test on:**
- [ ] Android Phone (English)
- [ ] Android Phone (Arabic)
- [ ] iOS iPhone (English)
- [ ] iOS iPhone (Arabic)

---

#### Test 5.2: Join Group - Invalid Code
**Steps:**
1. Login as user (not in group)
2. Navigate to "Join Group" page
3. Enter invalid code: "XXXXXX"
4. Submit

**Expected Results:**
- ✅ Error message displays
- ✅ Message: "The selected group code is invalid"
- ✅ User remains on join page

**Test on:**
- [ ] Android (English)
- [ ] iOS (English)

---

#### Test 5.3: Join Group - Already in Group
**Steps:**
1. Login as user (already in a group)
2. Navigate to "Join Group" page
3. Enter different group code
4. Submit

**Expected Results:**
- ✅ Error message displays
- ✅ Message: "You are already in a group"
- ✅ Join is blocked

**Test on:**
- [ ] Android (English)
- [ ] iOS (English)

---

### 6. Data Scoping

#### Test 6.1: Expense Data Scoping
**Steps:**
1. Login as Admin 1, create expense
2. Logout, login as Admin 2
3. View expenses list

**Expected Results:**
- ✅ Admin 2 does NOT see Admin 1's expense
- ✅ Each admin sees only their group's data

**Test on:**
- [ ] Android (English)
- [ ] iOS (English)

---

#### Test 6.2: Transfer Data Scoping
**Steps:**
1. Login as Admin 1, create transfer
2. Logout, login as Admin 2
3. View transfers list

**Expected Results:**
- ✅ Admin 2 does NOT see Admin 1's transfer
- ✅ Each admin sees only their group's data

**Test on:**
- [ ] Android (English)
- [ ] iOS (English)

---

#### Test 6.3: Incoming Data Scoping
**Steps:**
1. Login as Admin 1, create incoming
2. Logout, login as Admin 2
3. View incoming list

**Expected Results:**
- ✅ Admin 2 does NOT see Admin 1's incoming
- ✅ Each admin sees only their group's data

**Test on:**
- [ ] Android (English)
- [ ] iOS (English)

---

#### Test 6.4: Fund Box Data Scoping
**Steps:**
1. Login as Admin 1, set fund box to 5000
2. Logout, login as Admin 2
3. View fund box

**Expected Results:**
- ✅ Admin 2 has separate fund box
- ✅ Admin 2's balance is NOT 5000
- ✅ Each admin has independent fund box

**Test on:**
- [ ] Android (English)
- [ ] iOS (English)

---

#### Test 6.5: Dashboard Statistics Scoping
**Steps:**
1. Login as Admin 1, create data
2. Note dashboard statistics
3. Logout, login as Admin 2
4. View dashboard

**Expected Results:**
- ✅ Admin 2's stats are different
- ✅ Stats only include group members' data
- ✅ No cross-group data leakage

**Test on:**
- [ ] Android (English)
- [ ] iOS (English)

---

### 7. Localization

#### Test 7.1: English Language
**Steps:**
1. Set device language to English
2. Test all group management features
3. Observe all text

**Expected Results:**
- ✅ All labels are in English
- ✅ All messages are in English
- ✅ All buttons are in English
- ✅ Text is clear and readable

**Test on:**
- [ ] Android
- [ ] iOS

---

#### Test 7.2: Arabic Language (RTL)
**Steps:**
1. Set device language to Arabic
2. Test all group management features
3. Observe layout and text

**Expected Results:**
- ✅ All labels are in Arabic
- ✅ All messages are in Arabic
- ✅ Layout is RTL (right-to-left)
- ✅ Text alignment is correct
- ✅ Icons are mirrored appropriately
- ✅ No text overflow or truncation

**Test on:**
- [ ] Android
- [ ] iOS

---

### 8. Offline Scenarios

#### Test 8.1: Registration Offline
**Steps:**
1. Disable network
2. Try to register as admin or user
3. Observe behavior

**Expected Results:**
- ✅ Error message displays
- ✅ Message indicates network issue
- ✅ App doesn't crash

**Test on:**
- [ ] Android (English)
- [ ] iOS (English)

---

#### Test 8.2: View Group Info Offline
**Steps:**
1. Login and view group info
2. Disable network
3. Navigate away and back to group info

**Expected Results:**
- ✅ Cached data is displayed
- ✅ Or appropriate offline message shows
- ✅ App doesn't crash

**Test on:**
- [ ] Android (English)
- [ ] iOS (English)

---

#### Test 8.3: Join Group Offline
**Steps:**
1. Login as user (not in group)
2. Disable network
3. Try to join group

**Expected Results:**
- ✅ Error message displays
- ✅ Message indicates network issue
- ✅ App doesn't crash

**Test on:**
- [ ] Android (English)
- [ ] iOS (English)

---

### 9. Screen Sizes and Orientations

#### Test 9.1: Phone Portrait
**Steps:**
1. Test all features on phone in portrait mode
2. Observe layout and usability

**Expected Results:**
- ✅ All elements are visible
- ✅ No text truncation
- ✅ Buttons are tappable
- ✅ Scrolling works smoothly

**Test on:**
- [ ] Android Phone
- [ ] iOS iPhone

---

#### Test 9.2: Phone Landscape
**Steps:**
1. Rotate phone to landscape
2. Test all features
3. Observe layout

**Expected Results:**
- ✅ Layout adapts to landscape
- ✅ All elements remain accessible
- ✅ No UI elements are cut off

**Test on:**
- [ ] Android Phone
- [ ] iOS iPhone

---

#### Test 9.3: Tablet Portrait
**Steps:**
1. Test all features on tablet in portrait mode
2. Observe layout and spacing

**Expected Results:**
- ✅ Layout uses available space well
- ✅ Text is readable
- ✅ No excessive white space

**Test on:**
- [ ] Android Tablet
- [ ] iOS iPad

---

#### Test 9.4: Tablet Landscape
**Steps:**
1. Test all features on tablet in landscape mode
2. Observe layout

**Expected Results:**
- ✅ Layout adapts to wide screen
- ✅ Multi-column layout if appropriate
- ✅ All features remain accessible

**Test on:**
- [ ] Android Tablet
- [ ] iOS iPad

---

## Bug Reporting Template

When you find a bug, document it using this template:

```
**Bug ID:** [Unique identifier]
**Title:** [Short description]
**Severity:** [Critical / High / Medium / Low]
**Platform:** [Android / iOS]
**Device:** [Device model]
**OS Version:** [OS version]
**Language:** [English / Arabic]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Result:**
[What should happen]

**Actual Result:**
[What actually happens]

**Screenshots:**
[Attach screenshots if applicable]

**Additional Notes:**
[Any other relevant information]
```

## Test Summary Report

After completing all tests, fill out this summary:

### Test Execution Summary

**Date:** [Date]
**Tester:** [Name]
**Build Version:** [Version]

**Total Test Cases:** 50+
**Passed:** [ ]
**Failed:** [ ]
**Blocked:** [ ]
**Not Tested:** [ ]

### Platform Coverage

- [ ] Android Phone (English)
- [ ] Android Phone (Arabic)
- [ ] Android Tablet (English)
- [ ] iOS iPhone (English)
- [ ] iOS iPhone (Arabic)
- [ ] iOS iPad (English)

### Critical Issues Found

1. [Issue 1]
2. [Issue 2]
3. [Issue 3]

### Recommendations

[Any recommendations for improvements or additional testing]

### Sign-off

**Tester:** _________________ **Date:** _________
**Reviewer:** _________________ **Date:** _________

---

## Notes

- Test with real backend API, not mocked data
- Test with multiple users simultaneously when possible
- Pay attention to performance and loading times
- Note any UI/UX issues even if functionality works
- Test edge cases (very long names, special characters, etc.)
- Verify all error messages are user-friendly
- Check that all features work after app restart
- Test with poor network conditions (slow 3G)

## Next Steps

After completing manual testing:
1. Document all bugs found
2. Prioritize bugs (Critical, High, Medium, Low)
3. Fix critical and high priority bugs
4. Retest fixed bugs
5. Update this document with any new test cases discovered
6. Prepare for production release

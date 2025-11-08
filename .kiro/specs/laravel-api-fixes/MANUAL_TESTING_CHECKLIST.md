# Manual Testing Checklist - Laravel API Integration

## Overview
This document provides a comprehensive checklist for manually testing all Laravel API integration features. Complete each section systematically to ensure all functionality works as expected.

---

## Pre-Testing Setup

### Backend Setup
- [ ] Laravel backend is running on `http://localhost:8000`
- [ ] Database is migrated and seeded with test data
- [ ] API documentation is accessible at `/api/documentation`
- [ ] Postman collection is imported and configured

### App Setup
- [ ] Flutter app dependencies are installed (`flutter pub get`)
- [ ] API configuration points to correct backend URL
- [ ] Test accounts are created:
  - Regular user: `user@test.com` / `password`
  - Admin user: `admin@test.com` / `password`

### Testing Tools
- [ ] Postman installed with Finance API collection
- [ ] Network monitoring tool ready (optional)
- [ ] Device/emulator with internet connection
- [ ] Device/emulator with airplane mode capability (for offline testing)

---

## 1. Authentication Testing

### 1.1 Login Flow
- [ ] Login with valid regular user credentials
- [ ] Verify token is stored securely
- [ ] Verify user role is correctly identified
- [ ] Login with valid admin credentials
- [ ] Verify admin role is correctly identified
- [ ] Login with invalid credentials (should show error)
- [ ] Verify 401 error handling

### 1.2 Token Management
- [ ] Token is included in all authenticated requests
- [ ] Token persists after app restart
- [ ] Expired token triggers re-authentication
- [ ] Logout clears token properly
- [ ] `/auth/me` endpoint validates token on app start

### 1.3 Registration Flow
- [ ] Register new user with valid data
- [ ] Verify validation errors for invalid email
- [ ] Verify validation errors for weak password
- [ ] Verify validation errors for duplicate email
- [ ] Verify 422 error handling with field-specific messages

---

## 2. Transfer Module Testing

### 2.1 Create Transfer (Postman Baseline)
- [ ] POST `/api/v1/transfers` with valid data in Postman
- [ ] Verify response contains: `id`, `amount`, `from_account`, `to_account`, `date`
- [ ] Verify date format is YYYY-MM-DD
- [ ] Note the response structure for comparison

### 2.2 Create Transfer (App - User Flavor)
- [ ] Open user flavor app
- [ ] Navigate to Transfers page
- [ ] Create new transfer with:
  - Amount: 100.00
  - From Account: "Savings"
  - To Account: "Checking"
  - Date: Today
  - Description: "Test transfer"
- [ ] Verify transfer appears in list
- [ ] Verify all fields match input
- [ ] Verify date format is correct

### 2.3 Create Transfer (App - Admin Flavor)
- [ ] Open admin flavor app
- [ ] Create transfer with same data
- [ ] Verify transfer is created successfully
- [ ] Verify admin can see all users' transfers

### 2.4 Update Transfer
- [ ] Edit existing transfer
- [ ] Change amount to 150.00
- [ ] Verify update is saved
- [ ] Verify PUT request includes all required fields

### 2.5 Delete Transfer
- [ ] Delete a transfer
- [ ] Verify it's removed from list
- [ ] Verify DELETE request succeeds

### 2.6 List Transfers with Pagination
- [ ] Load transfers list
- [ ] Verify pagination works (15 items per page)
- [ ] Scroll to load more
- [ ] Verify "load more" stops at last page

### 2.7 Field Mapping Verification
- [ ] Compare app request body with Postman request
- [ ] Verify `from_account` field is sent correctly
- [ ] Verify `to_account` field is sent correctly
- [ ] Verify `amount` field is sent correctly
- [ ] Verify `date` field is in YYYY-MM-DD format
- [ ] Verify response parsing matches API spec

---

## 3. Incoming (Income) Module Testing

### 3.1 Create Incoming (Postman Baseline)
- [ ] POST `/api/v1/incoming` with valid data in Postman
- [ ] Verify response contains: `id`, `amount`, `source`, `payment_method`, `date`
- [ ] Verify payment_method accepts: cash, card, bank_transfer
- [ ] Note the response structure

### 3.2 Create Incoming (App - User Flavor)
- [ ] Navigate to Income page
- [ ] Create new income with:
  - Amount: 500.00
  - Source: "Salary"
  - Payment Method: "bank_transfer"
  - Date: Today
  - Description: "Monthly salary"
- [ ] Verify income appears in list
- [ ] Verify all fields match input

### 3.3 Payment Method Validation
- [ ] Create income with payment_method: "cash"
- [ ] Create income with payment_method: "card"
- [ ] Create income with payment_method: "bank_transfer"
- [ ] Verify all three methods work correctly
- [ ] Verify invalid payment method is rejected (if applicable)

### 3.4 Update and Delete Incoming
- [ ] Edit existing income record
- [ ] Change source and amount
- [ ] Verify update succeeds
- [ ] Delete an income record
- [ ] Verify deletion succeeds

### 3.5 Field Mapping Verification
- [ ] Verify `source` field is sent correctly
- [ ] Verify `payment_method` field is sent correctly
- [ ] Verify `amount` and `date` fields are correct
- [ ] Compare with Postman request structure

---

## 4. Fund Box Module Testing

### 4.1 Fund Box Access (Admin User)
- [ ] Login as admin user
- [ ] Navigate to Fund Box page
- [ ] Verify fund box balance loads successfully
- [ ] Verify `total_balance` field is displayed
- [ ] Verify `last_updated` timestamp is shown

### 4.2 Fund Box Update (Admin User)
- [ ] Update fund box balance to 10000.00
- [ ] Verify PUT request sends `total_balance` field
- [ ] Verify update succeeds
- [ ] Verify new balance is displayed

### 4.3 Fund Box Access (Regular User)
- [ ] Logout and login as regular user
- [ ] Attempt to access Fund Box page
- [ ] Verify 403 Forbidden error is handled gracefully
- [ ] Verify error message: "Access denied. Admin privileges required"
- [ ] Verify app doesn't crash

### 4.4 Fund Box in Admin Flavor (Regular User)
- [ ] Open admin flavor app
- [ ] Login as regular user
- [ ] Attempt to access Fund Box
- [ ] Verify 403 error is handled
- [ ] Verify appropriate error message is shown

### 4.5 Field Mapping Verification
- [ ] Verify GET response contains `total_balance` field
- [ ] Verify GET response contains `last_updated` field
- [ ] Verify PUT request sends `total_balance` (not `balance_usd`)
- [ ] Compare with Postman request/response

---

## 5. Admin Dashboard Testing

### 5.1 Dashboard Stats (Admin User)
- [ ] Login as admin user
- [ ] Navigate to Admin Dashboard
- [ ] Verify stats load successfully
- [ ] Verify all fields are displayed:
  - Total Users
  - Total Expenses
  - Total Income
  - Total Transfers
  - Total Amount Expenses
  - Total Amount Income
  - Fund Box Balance

### 5.2 User Activity List
- [ ] View user activity section
- [ ] Verify user list loads
- [ ] Verify pagination works
- [ ] Verify user details are correct

### 5.3 Expense Summaries
- [ ] View expense summaries section
- [ ] Verify `by_category` data is displayed
- [ ] Verify `by_payment_method` data is displayed
- [ ] Verify totals are correct

### 5.4 Analytics Endpoint
- [ ] Select date range (e.g., last 30 days)
- [ ] Verify analytics data loads
- [ ] Verify `date_from` and `date_to` are sent in YYYY-MM-DD format
- [ ] Verify monthly trends are displayed

### 5.5 Admin Dashboard (Regular User)
- [ ] Logout and login as regular user
- [ ] Attempt to access Admin Dashboard
- [ ] Verify 403 error is handled
- [ ] Verify error message is shown
- [ ] Verify app doesn't crash

### 5.6 Field Mapping Verification
- [ ] Compare dashboard stats response with API spec
- [ ] Verify all field names match exactly
- [ ] Verify nested objects are parsed correctly
- [ ] Compare with Postman response

---

## 6. Expense Module Testing

### 6.1 Create Expense (Postman Baseline)
- [ ] POST `/api/v1/expenses` with valid data in Postman
- [ ] Verify response structure
- [ ] Note all field names

### 6.2 Create Expense (App)
- [ ] Create new expense with:
  - Amount: 50.00
  - Category: "Food"
  - Payment Method: "cash"
  - Date: Today
  - Description: "Lunch"
- [ ] Verify expense appears in list
- [ ] Verify all fields are correct

### 6.3 Payment Method Validation
- [ ] Create expense with each payment method:
  - cash
  - card
  - bank_transfer
- [ ] Verify all methods work

### 6.4 Expense Filtering
- [ ] Filter by category
- [ ] Filter by date range (date_from, date_to)
- [ ] Verify filters work correctly
- [ ] Verify query parameters are sent correctly

### 6.5 Expense Pagination
- [ ] Load expenses list
- [ ] Verify default per_page is 15
- [ ] Load more expenses
- [ ] Verify pagination works correctly

### 6.6 Update and Delete Expense
- [ ] Edit existing expense
- [ ] Verify update succeeds
- [ ] Delete an expense
- [ ] Verify deletion succeeds

---

## 7. Profile API Testing

### 7.1 Get Profile
- [ ] Navigate to Profile page
- [ ] Verify profile loads with:
  - id
  - name
  - email
  - role
  - created_at
- [ ] Verify all fields are displayed correctly

### 7.2 Update Profile
- [ ] Edit profile name
- [ ] Edit profile email
- [ ] Save changes
- [ ] Verify PUT request sends `name` and `email` fields
- [ ] Verify profile is updated

### 7.3 Change Password
- [ ] Navigate to Change Password
- [ ] Enter current password
- [ ] Enter new password
- [ ] Enter password confirmation
- [ ] Submit
- [ ] Verify POST to `/profile/password` succeeds
- [ ] Verify fields: `current_password`, `new_password`, `new_password_confirmation`

### 7.4 Profile Validation Errors
- [ ] Try to update with invalid email
- [ ] Verify 422 error is handled
- [ ] Verify validation messages are displayed
- [ ] Try to change password with wrong current password
- [ ] Verify error message is shown

---

## 8. Export API Testing

### 8.1 PDF Export
- [ ] Navigate to Export page
- [ ] Select date range
- [ ] Request PDF export
- [ ] Verify POST to `/export/expenses/pdf` with:
  - format: "pdf"
  - date_from: YYYY-MM-DD
  - date_to: YYYY-MM-DD
- [ ] Verify response contains:
  - id
  - format
  - status
  - download_url

### 8.2 Excel Export
- [ ] Request Excel export
- [ ] Verify POST to `/export/expenses/excel`
- [ ] Verify response structure

### 8.3 Export Status Checking
- [ ] Check export status
- [ ] Verify GET to `/export/{id}/status`
- [ ] Verify status updates (processing → completed)

### 8.4 File Download
- [ ] Download completed export
- [ ] Verify GET to `/export/{id}/download`
- [ ] Verify file downloads successfully
- [ ] Verify file opens correctly

---

## 9. Batch Sync Testing

### 9.1 Offline Changes
- [ ] Enable airplane mode
- [ ] Create 3 expenses offline
- [ ] Create 2 income records offline
- [ ] Create 1 transfer offline
- [ ] Verify items are queued

### 9.2 Batch Sync
- [ ] Disable airplane mode
- [ ] Trigger sync
- [ ] Verify POST to `/sync/batch` with:
  - last_sync timestamp
  - data object with expenses, incoming, transfers arrays
- [ ] Verify response contains:
  - synced_at
  - created items with local_id → server_id mapping
  - conflicts array

### 9.3 Sync Changes
- [ ] Call sync changes endpoint
- [ ] Verify GET to `/sync/changes?since=TIMESTAMP`
- [ ] Verify response contains created, updated, deleted arrays

### 9.4 Conflict Resolution
- [ ] Create a conflict scenario (edit same item offline and online)
- [ ] Trigger sync
- [ ] Verify conflict is detected
- [ ] Verify conflict resolution UI appears
- [ ] Resolve conflict
- [ ] Verify resolution is applied

---

## 10. File Upload Testing

### 10.1 File Upload
- [ ] Navigate to expense with receipt option
- [ ] Select image file
- [ ] Upload file
- [ ] Verify POST to `/files/upload` with:
  - multipart/form-data content type
  - file field
  - type field (receipt, invoice, document)
- [ ] Verify response contains:
  - id, filename, path, type, size, mime_type, uploaded_at

### 10.2 File Download
- [ ] Download uploaded file
- [ ] Verify GET to `/files/download?path=ENCRYPTED_PATH`
- [ ] Verify file downloads correctly
- [ ] Verify file content is intact

### 10.3 File Deletion
- [ ] Delete uploaded file
- [ ] Verify DELETE to `/files` with path in body
- [ ] Verify file is removed

---

## 11. Audit Logs Testing (Admin Only)

### 11.1 Audit Logs List
- [ ] Login as admin
- [ ] Navigate to Audit Logs page
- [ ] Verify GET to `/audit-logs`
- [ ] Verify paginated response with:
  - current_page
  - data array
  - per_page
  - total
- [ ] Verify each log entry shows:
  - user_id, action, entity_type, entity_id
  - ip_address, user_agent, created_at

### 11.2 Audit Log Details
- [ ] Click on a log entry
- [ ] Verify GET to `/audit-logs/{id}`
- [ ] Verify details show:
  - user_name
  - changes object
  - all metadata fields

### 11.3 Audit Logs (Regular User)
- [ ] Logout and login as regular user
- [ ] Attempt to access Audit Logs
- [ ] Verify 403 error is handled
- [ ] Verify error message is shown

---

## 12. Error Handling Testing

### 12.1 400 Bad Request
- [ ] Send malformed request (e.g., invalid JSON)
- [ ] Verify error message is displayed
- [ ] Verify app doesn't crash

### 12.2 401 Unauthorized
- [ ] Manually expire token or use invalid token
- [ ] Make authenticated request
- [ ] Verify redirect to login
- [ ] Verify token is cleared

### 12.3 403 Forbidden
- [ ] As regular user, access admin endpoint
- [ ] Verify "Access denied" message
- [ ] Verify app doesn't crash

### 12.4 404 Not Found
- [ ] Request non-existent resource
- [ ] Verify "Resource not found" message
- [ ] Verify app doesn't crash

### 12.5 422 Unprocessable Entity
- [ ] Submit form with validation errors
- [ ] Verify field-specific error messages
- [ ] Verify errors are displayed next to fields
- [ ] Verify error format matches API response

### 12.6 429 Too Many Requests
- [ ] Make rapid repeated requests (if rate limiting is enabled)
- [ ] Verify "Too many requests" message
- [ ] Verify retry-after handling

### 12.7 500 Internal Server Error
- [ ] Trigger server error (if possible in test environment)
- [ ] Verify "Internal server error" message
- [ ] Verify error is logged
- [ ] Verify app doesn't crash

### 12.8 Network Errors
- [ ] Enable airplane mode
- [ ] Make request
- [ ] Verify network error message
- [ ] Verify request is queued for retry

---

## 13. Role-Based Access Control Testing

### 13.1 User Role Determination
- [ ] Login as regular user
- [ ] Verify role is "user"
- [ ] Login as admin
- [ ] Verify role is "admin"

### 13.2 Admin-Only Features (Regular User)
- [ ] Login as regular user
- [ ] Verify Fund Box is not accessible
- [ ] Verify Admin Dashboard is not accessible
- [ ] Verify Audit Logs are not accessible
- [ ] Verify appropriate error messages

### 13.3 Admin-Only Features (Admin User)
- [ ] Login as admin
- [ ] Verify Fund Box is accessible
- [ ] Verify Admin Dashboard is accessible
- [ ] Verify Audit Logs are accessible
- [ ] Verify all features work correctly

### 13.4 Flavor-Based Access
- [ ] Open user flavor with admin account
- [ ] Verify admin features are available
- [ ] Open admin flavor with regular user account
- [ ] Verify 403 errors are handled gracefully

### 13.5 UI Component Visibility
- [ ] Verify RoleBasedWidget hides admin-only UI for regular users
- [ ] Verify admin-only menu items are hidden for regular users
- [ ] Verify admin-only buttons are hidden for regular users

---

## 14. Date Formatting Testing

### 14.1 Date Input Format
- [ ] Create expense with today's date
- [ ] Verify date is sent as YYYY-MM-DD
- [ ] Create transfer with custom date
- [ ] Verify date format in request

### 14.2 Date Response Parsing
- [ ] Receive date in YYYY-MM-DD format
- [ ] Verify date is parsed correctly
- [ ] Receive timestamp in ISO 8601 format
- [ ] Verify timestamp is parsed correctly

### 14.3 Date Display Format
- [ ] Verify dates are displayed according to user locale
- [ ] Change device locale
- [ ] Verify date display updates

### 14.4 Date Range Filters
- [ ] Filter expenses by date range
- [ ] Verify date_from is sent as YYYY-MM-DD
- [ ] Verify date_to is sent as YYYY-MM-DD
- [ ] Verify filter works correctly

### 14.5 Timezone Handling
- [ ] Create item with current time
- [ ] Verify timestamp is converted to UTC for API
- [ ] Verify timestamp is converted to local time for display

---

## 15. Pagination Testing

### 15.1 Default Pagination
- [ ] Load expenses list
- [ ] Verify default per_page is 15
- [ ] Verify page parameter is 1

### 15.2 Load More
- [ ] Scroll to bottom of list
- [ ] Verify "load more" button appears
- [ ] Click "load more"
- [ ] Verify page parameter increments
- [ ] Verify new items are appended

### 15.3 Last Page Handling
- [ ] Load all pages until last page
- [ ] Verify "load more" is disabled
- [ ] Verify no more requests are made

### 15.4 Pagination Metadata
- [ ] Verify response contains:
  - current_page
  - last_page
  - per_page
  - total
- [ ] Verify metadata is used correctly

### 15.5 Large Dataset Testing
- [ ] Create 100+ test records
- [ ] Load list
- [ ] Verify pagination handles large dataset
- [ ] Verify performance is acceptable

---

## 16. Offline Mode Testing

### 16.1 Queue Manager
- [ ] Enable airplane mode
- [ ] Create multiple items
- [ ] Verify items are queued
- [ ] Verify queue count is displayed

### 16.2 Auto-Sync on Reconnect
- [ ] Disable airplane mode
- [ ] Verify auto-sync triggers
- [ ] Verify queued items are synced
- [ ] Verify queue is cleared

### 16.3 Sync Status Indicator
- [ ] Verify sync status indicator shows:
  - Synced (when online and synced)
  - Pending (when items are queued)
  - Syncing (during sync)
  - Error (if sync fails)

### 16.4 Manual Sync
- [ ] Trigger manual sync
- [ ] Verify sync completes
- [ ] Verify status updates

---

## 17. Postman Collection Testing

### 17.1 Import Collection
- [ ] Import Finance API Postman collection
- [ ] Configure environment variables:
  - base_url: http://localhost:8000/api/v1
  - token: (from login response)

### 17.2 Test All Endpoints
- [ ] Run authentication endpoints
- [ ] Run transfer endpoints
- [ ] Run incoming endpoints
- [ ] Run expense endpoints
- [ ] Run fund box endpoints
- [ ] Run admin dashboard endpoints
- [ ] Run profile endpoints
- [ ] Run export endpoints
- [ ] Run sync endpoints
- [ ] Run file upload endpoints
- [ ] Run audit log endpoints

### 17.3 Compare with App
- [ ] For each endpoint, compare:
  - Request body structure
  - Request headers
  - Response structure
  - Field names
  - Data types
- [ ] Verify app matches Postman exactly

---

## 18. Field Mapping Verification

### 18.1 Transfer Field Mapping
- [ ] from_account (app) → from_account (API) ✓
- [ ] to_account (app) → to_account (API) ✓
- [ ] amount (app) → amount (API) ✓
- [ ] date (app) → date (API) ✓
- [ ] description (app) → description (API) ✓

### 18.2 Incoming Field Mapping
- [ ] source (app) → source (API) ✓
- [ ] amount (app) → amount (API) ✓
- [ ] paymentMethod (app) → payment_method (API) ✓
- [ ] date (app) → date (API) ✓
- [ ] description (app) → description (API) ✓

### 18.3 Fund Box Field Mapping
- [ ] totalBalance (app) → total_balance (API) ✓
- [ ] lastUpdated (app) → last_updated (API) ✓

### 18.4 Admin Stats Field Mapping
- [ ] totalUsers (app) → total_users (API) ✓
- [ ] totalExpenses (app) → total_expenses (API) ✓
- [ ] totalIncome (app) → total_income (API) ✓
- [ ] totalTransfers (app) → total_transfers (API) ✓
- [ ] totalAmountExpenses (app) → total_amount_expenses (API) ✓
- [ ] totalAmountIncome (app) → total_amount_income (API) ✓
- [ ] fundBoxBalance (app) → fund_box_balance (API) ✓

### 18.5 Expense Field Mapping
- [ ] amount (app) → amount (API) ✓
- [ ] category (app) → category (API) ✓
- [ ] paymentMethod (app) → payment_method (API) ✓
- [ ] date (app) → date (API) ✓
- [ ] description (app) → description (API) ✓

---

## 19. Performance Testing

### 19.1 Response Times
- [ ] Measure average response time for each endpoint
- [ ] Verify response times are acceptable (<2s)
- [ ] Identify slow endpoints

### 19.2 Large Dataset Performance
- [ ] Load list with 1000+ items
- [ ] Verify pagination performance
- [ ] Verify scroll performance

### 19.3 Concurrent Requests
- [ ] Make multiple simultaneous requests
- [ ] Verify all requests complete successfully
- [ ] Verify no race conditions

---

## 20. User Acceptance Testing

### 20.1 User Flavor Testing
- [ ] Complete full user workflow:
  1. Login
  2. Create expense
  3. Create income
  4. Create transfer
  5. View profile
  6. Export data
  7. Logout
- [ ] Verify all features work smoothly
- [ ] Verify UI is intuitive

### 20.2 Admin Flavor Testing
- [ ] Complete full admin workflow:
  1. Login as admin
  2. View dashboard
  3. Manage fund box
  4. View audit logs
  5. View user activity
  6. Export reports
  7. Logout
- [ ] Verify all admin features work
- [ ] Verify admin UI is appropriate

---

## Test Results Summary

### Critical Issues Found
- [ ] List any critical issues that block functionality

### High Priority Issues Found
- [ ] List any high priority issues that affect user experience

### Medium Priority Issues Found
- [ ] List any medium priority issues

### Low Priority Issues Found
- [ ] List any low priority issues or enhancements

### Overall Assessment
- [ ] All critical features work correctly
- [ ] All field mappings are correct
- [ ] All error scenarios are handled
- [ ] Role-based access control works
- [ ] Offline mode works
- [ ] Date formatting is consistent
- [ ] Pagination works correctly

### Sign-Off
- Tester Name: _______________
- Date: _______________
- Status: [ ] PASS [ ] FAIL [ ] PASS WITH ISSUES

---

## Notes and Observations

[Add any additional notes, observations, or recommendations here]

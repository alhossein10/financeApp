# Postman Collection v2 - Testing Checklist

## Pre-Testing Setup

- [ ] Import `Finance-API-Complete-v2.postman_collection.json` into Postman
- [ ] Set `base_url` variable to `http://127.0.0.1:8000/api/v1`
- [ ] Ensure Laravel server is running (`php artisan serve`)
- [ ] Verify database is migrated and seeded
- [ ] Clear any existing test data (optional)

## 1. Public Endpoints (No Auth) ✓

- [ ] **Get Organizations**
  - [ ] Returns 200 OK
  - [ ] Contains "هيئة الاتصالات"
  - [ ] Has valid JSON structure

- [ ] **Get Departments**
  - [ ] Returns 200 OK
  - [ ] Shows departments for organization 1
  - [ ] Includes department names in Arabic

## 2. Authentication ✓

### Registration
- [ ] **Register Regular User**
  - [ ] Returns 201 Created
  - [ ] Requires organization_id
  - [ ] Requires department_id
  - [ ] Token auto-saved to variables
  - [ ] User has organization and department

- [ ] **Register Admin User**
  - [ ] Returns 201 Created
  - [ ] Requires organization_id
  - [ ] Does NOT require department_id
  - [ ] Token auto-saved to variables
  - [ ] User has organization, no department

- [ ] **Registration Validation**
  - [ ] Fails without organization_id
  - [ ] Fails with invalid organization_id
  - [ ] Fails with invalid department_id
  - [ ] Fails when department doesn't match organization
  - [ ] Fails when regular user has no department_id

### Login & Session
- [ ] **Login**
  - [ ] Returns 200 OK
  - [ ] Token auto-saved
  - [ ] User data includes org and dept

- [ ] **Get Current User**
  - [ ] Returns 200 OK
  - [ ] Shows organization details
  - [ ] Shows department details (if applicable)

- [ ] **Refresh Token**
  - [ ] Returns 200 OK
  - [ ] New token auto-saved
  - [ ] Old token invalidated

- [ ] **Logout**
  - [ ] Returns 200 OK
  - [ ] Token revoked
  - [ ] Cannot use old token

- [ ] **Forgot Password**
  - [ ] Returns 200 OK
  - [ ] Email sent (check logs)

## 3. Expenses Management ✓

- [ ] **List Expenses**
  - [ ] Returns 200 OK
  - [ ] Paginated results
  - [ ] Regular user sees only own expenses
  - [ ] Admin sees all org expenses

- [ ] **Create Expense**
  - [ ] Returns 201 Created
  - [ ] organization_id auto-set from user
  - [ ] department_id auto-set from user
  - [ ] expense_id auto-saved to variables

- [ ] **Get Expense**
  - [ ] Returns 200 OK
  - [ ] Shows expense details
  - [ ] Includes org and dept info

- [ ] **Update Expense**
  - [ ] Returns 200 OK
  - [ ] Changes reflected
  - [ ] Cannot change org/dept

- [ ] **Upload Invoice**
  - [ ] Returns 200 OK
  - [ ] File uploaded successfully
  - [ ] has_invoice set to true

- [ ] **Download Invoice**
  - [ ] Returns file
  - [ ] Correct file type
  - [ ] File accessible

- [ ] **Delete Invoice**
  - [ ] Returns 200 OK
  - [ ] File removed
  - [ ] has_invoice set to false

- [ ] **Delete Expense**
  - [ ] Returns 200 OK
  - [ ] Soft deleted
  - [ ] Not in list anymore

## 4. Transfers Management ✓

- [ ] **List Transfers**
  - [ ] Returns 200 OK
  - [ ] Paginated results
  - [ ] Filtered by user/org correctly

- [ ] **Create Transfer**
  - [ ] Returns 201 Created
  - [ ] organization_id auto-set
  - [ ] department_id auto-set
  - [ ] transfer_id auto-saved

- [ ] **Get Transfer**
  - [ ] Returns 200 OK
  - [ ] Shows transfer details

- [ ] **Update Transfer**
  - [ ] Returns 200 OK
  - [ ] Changes reflected

- [ ] **Add Exchange**
  - [ ] Returns 200 OK
  - [ ] Exchange data saved
  - [ ] Linked to transfer

- [ ] **Delete Transfer**
  - [ ] Returns 200 OK
  - [ ] Soft deleted

## 5. Incoming Management ✓

- [ ] **List Incoming**
  - [ ] Returns 200 OK
  - [ ] Paginated results
  - [ ] Filtered correctly

- [ ] **Create Incoming**
  - [ ] Returns 201 Created
  - [ ] organization_id auto-set
  - [ ] department_id auto-set
  - [ ] incoming_id auto-saved

- [ ] **Get Incoming**
  - [ ] Returns 200 OK
  - [ ] Shows incoming details

- [ ] **Update Incoming**
  - [ ] Returns 200 OK
  - [ ] Changes reflected

- [ ] **Delete Incoming**
  - [ ] Returns 200 OK
  - [ ] Soft deleted

## 6. Fund Box (Admin Only) ✓

- [ ] **Get Fund Box**
  - [ ] Returns 200 OK (admin)
  - [ ] Returns 403 Forbidden (regular user)
  - [ ] Shows current balance

- [ ] **Update Fund Box**
  - [ ] Returns 200 OK (admin)
  - [ ] Returns 403 Forbidden (regular user)
  - [ ] Balance updated

## 7. Admin Dashboard (Admin Only) ✓

- [ ] **Get Stats**
  - [ ] Returns 200 OK (admin)
  - [ ] Returns 403 Forbidden (regular user)
  - [ ] Shows org-wide statistics

- [ ] **Get Users**
  - [ ] Returns 200 OK (admin)
  - [ ] Shows all org users
  - [ ] Does not show other org users

- [ ] **Get Expenses Summary**
  - [ ] Returns 200 OK (admin)
  - [ ] Shows org-wide expenses
  - [ ] Correct totals

- [ ] **Get Analytics**
  - [ ] Returns 200 OK (admin)
  - [ ] Shows analytics data
  - [ ] Org-specific data

## 8. Audit Logs (Admin Only) ✓

- [ ] **List Audit Logs**
  - [ ] Returns 200 OK (admin)
  - [ ] Returns 403 Forbidden (regular user)
  - [ ] Shows activity logs

- [ ] **Get Audit Log**
  - [ ] Returns 200 OK (admin)
  - [ ] Shows log details

## 9. Data Synchronization ✓

- [ ] **Batch Sync**
  - [ ] Returns 200 OK
  - [ ] Processes batch data
  - [ ] Returns sync results

- [ ] **Get Changes**
  - [ ] Returns 200 OK
  - [ ] Shows changes since date
  - [ ] Filtered by user/org

- [ ] **Resolve Conflict**
  - [ ] Returns 200 OK
  - [ ] Conflict resolved
  - [ ] Correct resolution applied

## 10. User Profile ✓

- [ ] **Get Profile**
  - [ ] Returns 200 OK
  - [ ] Shows user details
  - [ ] Includes org and dept

- [ ] **Update Profile**
  - [ ] Returns 200 OK
  - [ ] Changes reflected
  - [ ] Cannot change org/dept

- [ ] **Change Password**
  - [ ] Returns 200 OK
  - [ ] Password changed
  - [ ] Can login with new password

- [ ] **Delete Account**
  - [ ] Returns 200 OK
  - [ ] Account soft deleted
  - [ ] Cannot login anymore

## 11. Data Export ✓

- [ ] **List Exports**
  - [ ] Returns 200 OK
  - [ ] Shows user's exports

- [ ] **Export to PDF**
  - [ ] Returns 200 OK
  - [ ] Export queued/generated

- [ ] **Export to Excel**
  - [ ] Returns 200 OK
  - [ ] Export queued/generated

- [ ] **System-Wide Export**
  - [ ] Returns 200 OK (admin)
  - [ ] Returns 403 Forbidden (regular user)
  - [ ] Export queued

- [ ] **Get Export Status**
  - [ ] Returns 200 OK
  - [ ] Shows export status

- [ ] **Download Export**
  - [ ] Returns file
  - [ ] Correct format
  - [ ] Contains expected data

## 12. File Operations ✓

- [ ] **Upload File**
  - [ ] Returns 200 OK
  - [ ] File uploaded
  - [ ] Returns file path

- [ ] **Delete File**
  - [ ] Returns 200 OK
  - [ ] File removed

## Organizational Hierarchy Testing ✓

### Data Isolation
- [ ] **Regular User Isolation**
  - [ ] User A cannot see User B's data
  - [ ] User sees only own expenses
  - [ ] User sees only own transfers
  - [ ] User sees only own incoming

- [ ] **Admin Organization Access**
  - [ ] Admin sees all users in org
  - [ ] Admin sees all expenses in org
  - [ ] Admin sees all transfers in org
  - [ ] Admin sees all incoming in org

- [ ] **Cross-Organization Isolation**
  - [ ] Org 1 users cannot see Org 2 data
  - [ ] Org 1 admin cannot see Org 2 data
  - [ ] Complete data separation

### Automatic Context
- [ ] **Data Creation**
  - [ ] Expenses auto-get org_id from user
  - [ ] Expenses auto-get dept_id from user
  - [ ] Transfers auto-get org_id from user
  - [ ] Transfers auto-get dept_id from user
  - [ ] Incoming auto-get org_id from user
  - [ ] Incoming auto-get dept_id from user

### Validation
- [ ] **Organization Validation**
  - [ ] Invalid org_id rejected
  - [ ] Error message in Arabic
  - [ ] Proper 422 status code

- [ ] **Department Validation**
  - [ ] Invalid dept_id rejected
  - [ ] Dept from wrong org rejected
  - [ ] Regular user without dept rejected
  - [ ] Admin without dept accepted
  - [ ] Error messages in Arabic

## Performance Testing ✓

- [ ] **Response Times**
  - [ ] List endpoints < 500ms
  - [ ] Create endpoints < 300ms
  - [ ] Update endpoints < 300ms
  - [ ] Delete endpoints < 200ms

- [ ] **Pagination**
  - [ ] Works with different page sizes
  - [ ] Correct total counts
  - [ ] Proper page navigation

- [ ] **Filtering**
  - [ ] Date range filters work
  - [ ] Search filters work
  - [ ] Status filters work
  - [ ] Combined filters work

## Security Testing ✓

- [ ] **Authentication**
  - [ ] Protected endpoints require token
  - [ ] Invalid token rejected
  - [ ] Expired token rejected

- [ ] **Authorization**
  - [ ] Admin endpoints require admin role
  - [ ] Users cannot access other user data
  - [ ] Users cannot access other org data

- [ ] **Input Validation**
  - [ ] SQL injection prevented
  - [ ] XSS prevented
  - [ ] Invalid data rejected
  - [ ] File upload restrictions work

## Error Handling ✓

- [ ] **401 Unauthorized**
  - [ ] Missing token
  - [ ] Invalid token
  - [ ] Expired token

- [ ] **403 Forbidden**
  - [ ] Non-admin accessing admin endpoint
  - [ ] User accessing other user's data

- [ ] **404 Not Found**
  - [ ] Invalid resource ID
  - [ ] Deleted resource

- [ ] **422 Validation Error**
  - [ ] Missing required fields
  - [ ] Invalid data format
  - [ ] Business rule violations

- [ ] **500 Server Error**
  - [ ] Proper error logging
  - [ ] User-friendly message

## Final Verification ✓

- [ ] All 51 endpoints tested
- [ ] All organizational features verified
- [ ] All validation rules checked
- [ ] All error cases handled
- [ ] Performance acceptable
- [ ] Security measures working
- [ ] Documentation accurate
- [ ] Collection ready for production

## Notes

**Date Tested**: _________________

**Tested By**: _________________

**Environment**: _________________

**Issues Found**: _________________

**Status**: ☐ Pass ☐ Fail ☐ Needs Review

---

**Testing Complete! 🎉**

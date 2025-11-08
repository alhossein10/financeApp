# Complete API Testing Guide

## Overview

This guide covers testing all 51 endpoints in the Finance API, including the new organizational hierarchy features.

## Collection Information

- **File**: `Finance-API-Complete-v2.postman_collection.json`
- **Total Endpoints**: 51
- **Folders**: 12
- **Version**: 2.0.0

## Prerequisites

1. Import the collection into Postman
2. Set up environment variables:
   - `base_url`: http://127.0.0.1:8000/api/v1
   - `token`: (auto-populated after login)
   - `organization_id`: 1
   - `department_id`: 1

## Testing Workflow

### Phase 1: Public Endpoints (No Authentication)

#### 1.1 Get Organizations
```
GET /organizations
```
**Expected**: List of all organizations including "هيئة الاتصالات"

#### 1.2 Get Departments
```
GET /organizations/1/departments
```
**Expected**: List of departments for organization 1

### Phase 2: Authentication & Registration

#### 2.1 Register Regular User
```
POST /auth/register
Body:
{
  "name": "Test User",
  "email": "user@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "organization_id": 1,
  "department_id": 2,
  "role": "user"
}
```
**Expected**: 201 Created, token auto-saved

#### 2.2 Register Admin User
```
POST /auth/register
Body:
{
  "name": "Admin User",
  "email": "admin@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "organization_id": 1,
  "role": "admin"
}
```
**Expected**: 201 Created, no department_id required

#### 2.3 Login
```
POST /auth/login
Body:
{
  "email": "user@example.com",
  "password": "password123"
}
```
**Expected**: 200 OK, token auto-saved

#### 2.4 Get Current User
```
GET /auth/me
```
**Expected**: User details with organization and department

#### 2.5 Refresh Token
```
POST /auth/refresh
```
**Expected**: New token

#### 2.6 Forgot Password
```
POST /auth/forgot-password
Body:
{
  "email": "user@example.com"
}
```
**Expected**: Password reset email sent

#### 2.7 Logout
```
POST /auth/logout
```
**Expected**: 200 OK, token revoked

### Phase 3: Expenses Management

#### 3.1 List Expenses
```
GET /expenses?per_page=15
```
**Expected**: Paginated list of user's expenses

#### 3.2 Create Expense
```
POST /expenses
Body:
{
  "description": "Test expense",
  "price_usd": 100.50,
  "price_syp": 500000,
  "expense_date": "2024-10-29"
}
```
**Expected**: 201 Created, expense_id auto-saved
**Note**: organization_id and department_id auto-set from user

#### 3.3 Get Expense
```
GET /expenses/{expense_id}
```
**Expected**: Expense details

#### 3.4 Update Expense
```
PUT /expenses/{expense_id}
Body:
{
  "description": "Updated expense",
  "price_usd": 150.75
}
```
**Expected**: 200 OK, updated expense

#### 3.5 Upload Invoice
```
POST /expenses/{expense_id}/invoice
Body: (form-data)
- photo: [file]
```
**Expected**: 200 OK, invoice uploaded

#### 3.6 Download Invoice
```
GET /expenses/{expense_id}/invoice
```
**Expected**: Invoice file download

#### 3.7 Delete Invoice
```
DELETE /expenses/{expense_id}/invoice
```
**Expected**: 200 OK, invoice deleted

#### 3.8 Delete Expense
```
DELETE /expenses/{expense_id}
```
**Expected**: 200 OK, expense soft-deleted

### Phase 4: Transfers Management

#### 4.1 List Transfers
```
GET /transfers?per_page=15
```
**Expected**: Paginated list of user's transfers

#### 4.2 Create Transfer
```
POST /transfers
Body:
{
  "recipient_name": "John Doe",
  "amount_usd": 500.00,
  "transfer_date": "2024-10-29",
  "notes": "Test transfer"
}
```
**Expected**: 201 Created, transfer_id auto-saved

#### 4.3 Get Transfer
```
GET /transfers/{transfer_id}
```
**Expected**: Transfer details

#### 4.4 Update Transfer
```
PUT /transfers/{transfer_id}
Body:
{
  "recipient_name": "Jane Doe",
  "amount_usd": 600.00
}
```
**Expected**: 200 OK, updated transfer

#### 4.5 Add Exchange
```
POST /transfers/{transfer_id}/exchange
Body:
{
  "exchange_rate": 15000,
  "amount_syp": 7500000,
  "exchange_date": "2024-10-29"
}
```
**Expected**: 200 OK, exchange added

#### 4.6 Delete Transfer
```
DELETE /transfers/{transfer_id}
```
**Expected**: 200 OK, transfer soft-deleted

### Phase 5: Incoming Management

#### 5.1 List Incoming
```
GET /incoming?per_page=15
```
**Expected**: Paginated list of user's incoming

#### 5.2 Create Incoming
```
POST /incoming
Body:
{
  "description": "Monthly budget",
  "amount_usd": 5000.00,
  "incoming_date": "2024-10-29"
}
```
**Expected**: 201 Created, incoming_id auto-saved

#### 5.3 Get Incoming
```
GET /incoming/{incoming_id}
```
**Expected**: Incoming details

#### 5.4 Update Incoming
```
PUT /incoming/{incoming_id}
Body:
{
  "description": "Updated monthly budget",
  "amount_usd": 5500.00
}
```
**Expected**: 200 OK, updated incoming

#### 5.5 Delete Incoming
```
DELETE /incoming/{incoming_id}
```
**Expected**: 200 OK, incoming soft-deleted

### Phase 6: Fund Box (Admin Only)

**Note**: Login as admin user first

#### 6.1 Get Fund Box
```
GET /fund-box
```
**Expected**: Current fund box balance

#### 6.2 Update Fund Box
```
PUT /fund-box
Body:
{
  "balance_usd": 10000.00
}
```
**Expected**: 200 OK, balance updated

### Phase 7: Admin Dashboard (Admin Only)

#### 7.1 Get Stats
```
GET /admin/dashboard/stats
```
**Expected**: Organization-wide statistics

#### 7.2 Get Users
```
GET /admin/dashboard/users
```
**Expected**: List of users in organization

#### 7.3 Get Expenses Summary
```
GET /admin/dashboard/expenses
```
**Expected**: Expenses summary for organization

#### 7.4 Get Analytics
```
GET /admin/dashboard/analytics
```
**Expected**: Analytics data for organization

### Phase 8: Audit Logs (Admin Only)

#### 8.1 List Audit Logs
```
GET /audit-logs?per_page=15
```
**Expected**: Paginated audit logs

#### 8.2 Get Audit Log
```
GET /audit-logs/1
```
**Expected**: Specific audit log details

### Phase 9: Data Synchronization

#### 9.1 Batch Sync
```
POST /sync/batch
Body:
{
  "expenses": [
    {
      "description": "Offline expense",
      "price_usd": 50.00,
      "expense_date": "2024-10-29"
    }
  ]
}
```
**Expected**: 200 OK, sync results

#### 9.2 Get Changes
```
GET /sync/changes?since=2024-10-01
```
**Expected**: Changes since specified date

#### 9.3 Resolve Conflict
```
POST /sync/resolve
Body:
{
  "resource_type": "expense",
  "resource_id": 1,
  "resolution": "server"
}
```
**Expected**: 200 OK, conflict resolved

### Phase 10: User Profile

#### 10.1 Get Profile
```
GET /profile
```
**Expected**: Current user profile

#### 10.2 Update Profile
```
PUT /profile
Body:
{
  "name": "Updated Name",
  "email": "updated@example.com"
}
```
**Expected**: 200 OK, profile updated

#### 10.3 Change Password
```
PUT /profile/password
Body:
{
  "current_password": "password123",
  "password": "newpassword123",
  "password_confirmation": "newpassword123"
}
```
**Expected**: 200 OK, password changed

#### 10.4 Delete Account
```
DELETE /profile
```
**Expected**: 200 OK, account deleted

### Phase 11: Data Export

#### 11.1 List Exports
```
GET /export
```
**Expected**: List of user's exports

#### 11.2 Export to PDF
```
POST /export/expenses/pdf
Body:
{
  "date_from": "2024-01-01",
  "date_to": "2024-12-31"
}
```
**Expected**: 200 OK, export queued

#### 11.3 Export to Excel
```
POST /export/expenses/excel
Body:
{
  "date_from": "2024-01-01",
  "date_to": "2024-12-31"
}
```
**Expected**: 200 OK, export queued

#### 11.4 System-Wide Export (Admin)
```
POST /export/system-wide
Body:
{
  "format": "excel",
  "include": ["expenses", "transfers", "incoming"]
}
```
**Expected**: 200 OK, export queued

#### 11.5 Get Export Status
```
GET /export/1/status
```
**Expected**: Export status

#### 11.6 Download Export
```
GET /export/1/download
```
**Expected**: Export file download

### Phase 12: File Operations

#### 12.1 Upload File
```
POST /files/upload
Body: (form-data)
- file: [file]
- path: uploads
```
**Expected**: 200 OK, file uploaded

#### 12.2 Delete File
```
DELETE /files
Body:
{
  "path": "uploads/file.pdf"
}
```
**Expected**: 200 OK, file deleted

## Testing Organizational Hierarchy

### Test 1: Regular User Data Isolation
1. Login as regular user
2. Create expenses, transfers, incoming
3. List all records
4. **Verify**: Only see own data

### Test 2: Admin Organization-Wide Access
1. Login as admin user
2. Create data as admin
3. Login as regular user in same organization
4. Create data as regular user
5. Login back as admin
6. List all records
7. **Verify**: Admin sees all data from organization

### Test 3: Cross-Organization Isolation
1. Create second organization
2. Register users in different organizations
3. Create data in each organization
4. **Verify**: Users cannot see data from other organizations

### Test 4: Department Validation
1. Try to register user with invalid department_id
2. **Verify**: Error "القسم المحدد غير موجود"
3. Try to register user with department from different organization
4. **Verify**: Error "القسم لا ينتمي للمنظمة المحددة"

### Test 5: Admin Without Department
1. Register admin without department_id
2. **Verify**: Success, department_id is null
3. Try to register regular user without department_id
4. **Verify**: Error "القسم مطلوب للمستخدمين العاديين"

## Common Issues & Solutions

### Issue: 401 Unauthorized
**Solution**: Ensure token is set in Authorization header

### Issue: 403 Forbidden
**Solution**: Endpoint requires admin role, login as admin

### Issue: 404 Not Found
**Solution**: Check resource ID exists and belongs to user

### Issue: 422 Validation Error
**Solution**: Check request body matches required fields

### Issue: 500 Server Error
**Solution**: Check server logs for detailed error

## Performance Testing

Run these tests to verify performance:

1. **Bulk Create**: Create 100 expenses
2. **Pagination**: List expenses with different page sizes
3. **Filtering**: Test all filter combinations
4. **Concurrent Requests**: Run multiple requests simultaneously

## Security Testing

Verify these security measures:

1. **Authentication**: All protected endpoints require token
2. **Authorization**: Users can only access their own data
3. **Organization Isolation**: Data is isolated by organization
4. **Input Validation**: Invalid data is rejected
5. **File Upload**: Only allowed file types accepted

## Automated Testing

Use Postman's Collection Runner to:

1. Run entire collection
2. Run specific folders
3. Generate test reports
4. Export results

## Next Steps

1. Import collection into Postman
2. Set up environment variables
3. Run tests in order
4. Verify all responses
5. Report any issues

## Support

For issues or questions:
- Check API documentation
- Review error messages
- Check server logs
- Consult development team

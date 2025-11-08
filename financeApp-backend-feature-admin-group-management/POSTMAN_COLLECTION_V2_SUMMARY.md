# Postman Collection v2 - Complete API Testing Suite

## Overview

A comprehensive Postman collection has been created to test all 51 endpoints of the Finance API, including the new organizational hierarchy features.

## What's Included

### Collection File
- **File**: `postman/Finance-API-Complete-v2.postman_collection.json`
- **Version**: 2.0.0
- **Total Endpoints**: 51
- **Folders**: 12

### Documentation Files
1. **QUICK_START_V2.md** - Get started in 5 minutes
2. **COMPLETE_TESTING_GUIDE.md** - Comprehensive testing guide
3. **TESTING_GUIDE.md** - Original testing guide (still valid)

## Collection Structure

### 1. Public Endpoints (2 endpoints)
- Get All Organizations
- Get Departments for Organization

**New Feature**: These endpoints support the organizational hierarchy system

### 2. Authentication (7 endpoints)
- Register Regular User ⭐ (Updated with org/dept)
- Register Admin User ⭐ (Updated with org)
- Login
- Get Current User
- Refresh Token
- Forgot Password
- Logout

**New Feature**: Registration now requires organizational context

### 3. Expenses Management (8 endpoints)
- List Expenses
- Create Expense ⭐ (Auto-sets org/dept)
- Get Expense
- Update Expense
- Upload Invoice
- Download Invoice
- Delete Invoice
- Delete Expense

**New Feature**: Automatic organizational context on creation

### 4. Transfers Management (6 endpoints)
- List Transfers
- Create Transfer ⭐ (Auto-sets org/dept)
- Get Transfer
- Update Transfer
- Add Exchange to Transfer
- Delete Transfer

**New Feature**: Automatic organizational context on creation

### 5. Incoming Management (5 endpoints)
- List Incoming
- Create Incoming ⭐ (Auto-sets org/dept)
- Get Incoming
- Update Incoming
- Delete Incoming

**New Feature**: Automatic organizational context on creation

### 6. Fund Box - Admin Only (2 endpoints)
- Get Fund Box
- Update Fund Box

### 7. Admin Dashboard - Admin Only (4 endpoints)
- Get Dashboard Stats ⭐ (Organization-wide)
- Get Dashboard Users ⭐ (Organization-wide)
- Get Dashboard Expenses ⭐ (Organization-wide)
- Get Dashboard Analytics ⭐ (Organization-wide)

**New Feature**: Admin sees all data from their organization

### 8. Audit Logs - Admin Only (2 endpoints)
- List Audit Logs
- Get Audit Log

### 9. Data Synchronization (3 endpoints)
- Batch Sync
- Get Changes
- Resolve Conflict

### 10. User Profile (4 endpoints)
- Get Profile
- Update Profile
- Change Password
- Delete Account

### 11. Data Export (6 endpoints)
- List Exports
- Export Expenses to PDF
- Export Expenses to Excel
- System-Wide Export (Admin Only)
- Get Export Status
- Download Export

### 12. File Operations (2 endpoints)
- Upload File
- Delete File

## Key Features

### Auto-Populated Variables
The collection automatically saves these variables after requests:
- `token` - Authentication token (after login/register)
- `user_id` - Current user ID (after login/register)
- `expense_id` - Last created expense ID
- `transfer_id` - Last created transfer ID
- `incoming_id` - Last created incoming ID

### Pre-configured Variables
- `base_url` - API base URL (default: http://127.0.0.1:8000/api/v1)
- `organization_id` - Default organization (default: 1)
- `department_id` - Default department (default: 1)

### Smart Request Bodies
All request bodies include:
- Proper JSON formatting
- Example data
- Required fields
- Optional fields (commented)

## Testing Organizational Hierarchy

### Test Scenarios Included

#### 1. Regular User Data Isolation
- Register regular user with department
- Create expenses, transfers, incoming
- Verify user sees only own data

#### 2. Admin Organization-Wide Access
- Register admin user (no department required)
- Create data as admin
- Verify admin sees all organization data

#### 3. Cross-Organization Isolation
- Create users in different organizations
- Verify complete data isolation

#### 4. Validation Testing
- Test invalid organization_id
- Test invalid department_id
- Test department from wrong organization
- Test regular user without department

## Quick Start

### 1. Import Collection
```bash
# In Postman
File → Import → Select Finance-API-Complete-v2.postman_collection.json
```

### 2. Set Base URL
```
Collection → Variables → base_url = http://127.0.0.1:8000/api/v1
```

### 3. Test Public Endpoints
```
GET /organizations
GET /organizations/1/departments
```

### 4. Register & Login
```
POST /auth/register (with organization_id and department_id)
POST /auth/login
```

### 5. Create Data
```
POST /expenses
POST /transfers
POST /incoming
```

## Testing Workflows

### Workflow 1: Complete User Journey
1. Get organizations and departments (public)
2. Register user with org/dept
3. Login
4. Create expenses with invoices
5. Create transfers with exchanges
6. Create incoming records
7. Export data to PDF/Excel
8. Update profile
9. Logout

### Workflow 2: Admin Journey
1. Register admin (no department)
2. Login as admin
3. View dashboard stats (org-wide)
4. View all users in organization
5. View all expenses in organization
6. Manage fund box
7. View audit logs
8. Export system-wide data

### Workflow 3: Mobile Sync
1. Login
2. Create data offline (batch)
3. Batch sync when online
4. Get changes since last sync
5. Resolve any conflicts

## Validation Testing

### Registration Validation
- ✅ Valid regular user with org and dept
- ✅ Valid admin user with org only
- ❌ Regular user without department
- ❌ Invalid organization_id
- ❌ Invalid department_id
- ❌ Department from wrong organization

### Data Access Validation
- ✅ Regular user sees only own data
- ✅ Admin sees all org data
- ❌ User cannot see other org data
- ❌ User cannot see other user data

### Data Creation Validation
- ✅ Org/dept auto-set from user
- ❌ User cannot override org/dept
- ✅ All financial records have org context

## Performance Testing

Use Collection Runner to:
1. Run all 51 endpoints sequentially
2. Test with different data sizes
3. Measure response times
4. Generate performance reports

## Security Testing

Verify:
1. ✅ All protected endpoints require authentication
2. ✅ Admin endpoints require admin role
3. ✅ Users can only access own data
4. ✅ Organizations are completely isolated
5. ✅ Input validation works correctly

## Error Handling

Test these error scenarios:
- 401 Unauthorized (missing/invalid token)
- 403 Forbidden (insufficient permissions)
- 404 Not Found (resource doesn't exist)
- 422 Validation Error (invalid data)
- 500 Server Error (server issues)

## Environment Setup

### Local Development
```json
{
  "base_url": "http://127.0.0.1:8000/api/v1",
  "organization_id": "1",
  "department_id": "1"
}
```

### Staging
```json
{
  "base_url": "https://staging-api.example.com/api/v1",
  "organization_id": "1",
  "department_id": "1"
}
```

### Production
```json
{
  "base_url": "https://api.example.com/api/v1",
  "organization_id": "1",
  "department_id": "1"
}
```

## Automated Testing

### Using Collection Runner
1. Select collection or folder
2. Click "Run"
3. Configure iterations
4. Run tests
5. View results
6. Export report

### Using Newman (CLI)
```bash
# Install Newman
npm install -g newman

# Run collection
newman run Finance-API-Complete-v2.postman_collection.json \
  --environment local.postman_environment.json \
  --reporters cli,html

# Run specific folder
newman run Finance-API-Complete-v2.postman_collection.json \
  --folder "2. Authentication"
```

## Continuous Integration

### GitHub Actions Example
```yaml
name: API Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run API Tests
        run: |
          npm install -g newman
          newman run postman/Finance-API-Complete-v2.postman_collection.json
```

## Comparison with v1

### New in v2
- ✅ 2 new public endpoints (organizations, departments)
- ✅ Updated registration with org/dept
- ✅ Auto-populated org/dept on data creation
- ✅ Organization-wide admin access
- ✅ Enhanced validation testing
- ✅ Better variable management
- ✅ Improved documentation

### Maintained from v1
- ✅ All existing endpoints
- ✅ Authentication flow
- ✅ CRUD operations
- ✅ File uploads
- ✅ Data export
- ✅ Sync functionality

## Files Generated

1. **Collection**: `postman/Finance-API-Complete-v2.postman_collection.json`
2. **Generator**: `generate_complete_collection_v2.py`
3. **Quick Start**: `postman/QUICK_START_V2.md`
4. **Testing Guide**: `postman/COMPLETE_TESTING_GUIDE.md`
5. **This Summary**: `POSTMAN_COLLECTION_V2_SUMMARY.md`

## Next Steps

1. ✅ Import collection into Postman
2. ✅ Read Quick Start guide
3. ✅ Test public endpoints
4. ✅ Test authentication with org/dept
5. ✅ Test data creation with auto org/dept
6. ✅ Test admin organization-wide access
7. ✅ Test data isolation
8. ✅ Run full test suite
9. ✅ Generate test report
10. ✅ Integrate with CI/CD

## Support & Resources

- **Quick Start**: `postman/QUICK_START_V2.md`
- **Full Guide**: `postman/COMPLETE_TESTING_GUIDE.md`
- **API Docs**: `/api/documentation`
- **Org Hierarchy**: `docs/ORGANIZATIONAL_HIERARCHY.md`
- **Quick Reference**: `QUICK_REFERENCE_ORGANIZATIONAL_HIERARCHY.md`

## Feedback

If you find any issues or have suggestions:
1. Check the testing guides
2. Review error messages
3. Check server logs
4. Report to development team

---

**Collection v2 is ready for comprehensive API testing! 🚀**

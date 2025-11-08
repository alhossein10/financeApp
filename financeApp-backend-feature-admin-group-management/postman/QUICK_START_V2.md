# Quick Start Guide - Complete API Collection v2

## 🚀 Getting Started in 5 Minutes

### Step 1: Import Collection
1. Open Postman
2. Click **Import**
3. Select `Finance-API-Complete-v2.postman_collection.json`
4. Click **Import**

### Step 2: Set Base URL
1. Click on the collection
2. Go to **Variables** tab
3. Set `base_url` to: `http://127.0.0.1:8000/api/v1`
4. Save

### Step 3: Test Public Endpoints (No Auth Required)

#### Get Organizations
```
GET {{base_url}}/organizations
```
✅ Should return list of organizations

#### Get Departments
```
GET {{base_url}}/organizations/1/departments
```
✅ Should return departments for organization 1

### Step 4: Register & Login

#### Register a User
```
POST {{base_url}}/auth/register
{
  "name": "Test User",
  "email": "test@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "organization_id": 1,
  "department_id": 2,
  "role": "user"
}
```
✅ Token automatically saved to collection variables

#### Or Login with Existing User
```
POST {{base_url}}/auth/login
{
  "email": "test@example.com",
  "password": "password123"
}
```
✅ Token automatically saved

### Step 5: Test Protected Endpoints

#### Create an Expense
```
POST {{base_url}}/expenses
{
  "description": "Test expense",
  "price_usd": 100.00,
  "expense_date": "2024-10-29"
}
```
✅ Expense created with auto-set organization_id

#### List Your Expenses
```
GET {{base_url}}/expenses
```
✅ See only your expenses

### Step 6: Test Admin Features

#### Register Admin User
```
POST {{base_url}}/auth/register
{
  "name": "Admin User",
  "email": "admin@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "organization_name": "Acme Corporation",
  "role": "admin"
}
```
✅ Admin registered with auto-created group

#### Get Admin Group Info
```
GET {{base_url}}/admin/group
```
✅ Get your unique group code (auto-saved to {{group_code}})

#### Get Dashboard Stats
```
GET {{base_url}}/admin/dashboard/stats
```
✅ See organization-wide statistics

### Step 7: Test Admin Group Management

#### Register User with Group Code
```
POST {{base_url}}/auth/register
{
  "name": "Team Member",
  "email": "member@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "organization_name": "Acme Corporation",
  "department_name": "Finance",
  "group_code": "{{group_code}}",
  "role": "user"
}
```
✅ User automatically joins admin's group

#### Admin Views Group Members
```
GET {{base_url}}/admin/group/members
```
✅ See all users in your group

#### User Views Group Info
```
GET {{base_url}}/user/group-info
```
✅ See which group you belong to

## 📊 Collection Structure

```
Finance API Complete v2 (51 endpoints)
├── 1. Public Endpoints (2)
│   ├── Get Organizations
│   └── Get Departments
├── 2. Authentication (7)
│   ├── Register Regular User
│   ├── Register Admin User
│   ├── Login
│   ├── Get Current User
│   ├── Refresh Token
│   ├── Forgot Password
│   └── Logout
├── 3. Expenses Management (8)
│   ├── List, Create, Get, Update, Delete
│   └── Upload/Download/Delete Invoice
├── 4. Transfers Management (6)
│   ├── List, Create, Get, Update, Delete
│   └── Add Exchange
├── 5. Incoming Management (5)
│   └── List, Create, Get, Update, Delete
├── 6. Fund Box - Admin Only (2)
│   └── Get, Update
├── 7. Admin Dashboard - Admin Only (4)
│   └── Stats, Users, Expenses, Analytics
├── 8. Audit Logs - Admin Only (2)
│   └── List, Get
├── 9. Data Synchronization (3)
│   └── Batch Sync, Get Changes, Resolve Conflict
├── 10. User Profile (4)
│   └── Get, Update, Change Password, Delete
├── 11. Data Export (6)
│   └── List, PDF, Excel, System-Wide, Status, Download
└── 12. File Operations (2)
    └── Upload, Delete
```

## 🔑 Key Features

### Organizational Hierarchy
- ✅ Multi-organization support
- ✅ Department-level granularity
- ✅ Automatic data isolation
- ✅ Admin sees all org data
- ✅ Users see only own data

### Auto-Populated Variables
- `token` - Set after login/register
- `user_id` - Set after login/register
- `expense_id` - Set after creating expense
- `transfer_id` - Set after creating transfer
- `incoming_id` - Set after creating incoming

### Smart Defaults
- `organization_id` - Auto-set from user
- `department_id` - Auto-set from user
- Timestamps - Auto-generated
- Sync status - Defaults to 'synced'

## 🎯 Common Workflows

### Workflow 1: Regular User Journey
1. Register → Login
2. Create expenses/transfers/incoming
3. Upload invoices
4. Export data to PDF/Excel
5. Update profile

### Workflow 2: Admin User Journey
1. Register as admin → Login
2. View dashboard statistics
3. See all organization data
4. Manage fund box
5. View audit logs
6. Export system-wide data

### Workflow 3: Mobile App Sync
1. Login
2. Create data offline
3. Batch sync when online
4. Get changes since last sync
5. Resolve conflicts

## 🔒 Security Notes

### Authentication
- All protected endpoints require Bearer token
- Token auto-expires after 30 days
- Use refresh endpoint to get new token

### Authorization
- Regular users: See only own data
- Admin users: See all organization data
- Cross-organization: Complete isolation

### Data Validation
- Organization must exist
- Department must belong to organization
- Regular users must have department
- Admins can skip department

## 🐛 Troubleshooting

### Token Not Working
- Check Authorization header format: `Bearer {{token}}`
- Verify token is set in collection variables
- Try refreshing token or login again

### 403 Forbidden
- Endpoint requires admin role
- Login with admin account

### 422 Validation Error
- Check required fields
- Verify organization_id exists
- Ensure department belongs to organization

### 404 Not Found
- Resource doesn't exist
- Check resource ID
- Verify you have access to resource

## 📝 Testing Tips

### Use Collection Runner
1. Select collection or folder
2. Click **Run**
3. Review results
4. Export report

### Test Sequences
1. **Happy Path**: Register → Login → Create → List → Update → Delete
2. **Error Cases**: Invalid data → Missing fields → Unauthorized access
3. **Edge Cases**: Empty lists → Large datasets → Concurrent requests

### Environment Switching
- Create separate environments for:
  - Local development
  - Staging server
  - Production server

## 🎓 Next Steps

1. ✅ Import collection
2. ✅ Test public endpoints
3. ✅ Register and login
4. ✅ Create some data
5. ✅ Test admin features
6. 📖 Read full testing guide
7. 🚀 Integrate with your app

## 📚 Additional Resources

- **Full Testing Guide**: `COMPLETE_TESTING_GUIDE.md`
- **API Documentation**: `/api/documentation`
- **Organizational Hierarchy**: `../docs/ORGANIZATIONAL_HIERARCHY.md`
- **Quick Reference**: `../QUICK_REFERENCE_ORGANIZATIONAL_HIERARCHY.md`

## 💡 Pro Tips

1. **Save Responses**: Right-click response → Save as Example
2. **Use Variables**: Reference with `{{variable_name}}`
3. **Pre-request Scripts**: Auto-generate timestamps
4. **Tests Tab**: Add assertions for automated testing
5. **Console**: View detailed request/response logs

---

**Happy Testing! 🎉**

Need help? Check the full testing guide or API documentation.

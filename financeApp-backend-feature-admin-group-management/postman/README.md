# Finance Backend API - Postman Collection

This directory contains a complete Postman collection for testing the Finance Management Backend API.

## 📦 Collection File

- **File**: `Finance-API.postman_collection.json`
- **Version**: 1.0.0
- **Total Endpoints**: 50+ endpoints organized in 11 folders

## 🚀 Quick Start

### 1. Import Collection

1. Open Postman
2. Click **Import** button
3. Select `Finance-API.postman_collection.json`
4. Collection will appear in your workspace

### 2. Configure Variables

The collection uses the following variables (automatically managed):

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `base_url` | `http://localhost:8000/api/v1` | API base URL |
| `auth_token` | (auto-set) | Authentication token |
| `expense_id` | (auto-set) | Last created expense ID |
| `transfer_id` | (auto-set) | Last created transfer ID |
| `incoming_id` | (auto-set) | Last created incoming ID |
| `export_id` | (auto-set) | Last created export ID |
| `group_code` | (auto-set) | Admin's group code |
| `member_id` | (auto-set) | Group member ID |

**To change base URL**:
1. Click on the collection name
2. Go to **Variables** tab
3. Update `base_url` value (e.g., for production: `https://api.yourapp.com/api/v1`)

### 3. Start Testing

1. **Register a new user** (Authentication → Register)
   - Token is automatically saved to `auth_token` variable
2. **Or Login** with existing credentials (Authentication → Login)
3. Start testing other endpoints!

## 📁 Collection Structure

### 1. Authentication (6 endpoints)
- ✅ Register - Create new user account
- ✅ Login - Get authentication token
- ✅ Get Current User - Retrieve authenticated user info
- ✅ Refresh Token - Get new token
- ✅ Logout - Revoke current token

### 2. Password Reset (2 endpoints)
- ✅ Forgot Password - Request password reset
- ✅ Reset Password - Complete password reset

### 3. Expenses (5 endpoints)
- ✅ List Expenses - Paginated list with filters
- ✅ Create Expense - Add new expense
- ✅ Get Expense - View single expense
- ✅ Update Expense - Modify expense
- ✅ Delete Expense - Soft delete expense

### 4. Transfers (5 endpoints)
- ✅ List Transfers - Paginated list
- ✅ Create Transfer - Add new transfer
- ✅ Get Transfer - View single transfer
- ✅ Add Exchange to Transfer - Link exchange data
- ✅ Delete Transfer - Soft delete transfer

### 5. Incoming Funds (5 endpoints)
- ✅ List Incoming - Paginated list
- ✅ Create Incoming - Add new incoming transaction
- ✅ Get Incoming - View single transaction
- ✅ Update Incoming - Modify transaction
- ✅ Delete Incoming - Soft delete transaction

### 6. Admin - Fund Box (2 endpoints)
- ✅ Get Fund Box - View current balance (Admin only)
- ✅ Update Fund Box - Modify balance (Admin only)

### 7. Admin - Dashboard (4 endpoints)
- ✅ Get Stats - Overall system statistics (Admin only)
- ✅ Get User Activity - User activity list (Admin only)
- ✅ Get Expense Summaries - Expense aggregations (Admin only)
- ✅ Get Analytics - Date-range analytics (Admin only)

### 8. Admin - Audit Logs (2 endpoints)
- ✅ List Audit Logs - View all audit logs (Admin only)
- ✅ Get Audit Log - View single audit log (Admin only)

### 9. User Profile (3 endpoints)
- ✅ Get Profile - View user profile
- ✅ Update Profile - Modify profile info
- ✅ Change Password - Update password

### 10. Data Sync (2 endpoints)
- ✅ Batch Sync - Sync multiple records
- ✅ Get Changes - Retrieve changes since timestamp

### 11. Data Export (3 endpoints)
- ✅ Export to PDF - Generate PDF export
- ✅ Export to Excel - Generate Excel export
- ✅ Download Export - Download completed export

### 12. Admin Group Management (6 endpoints)
- ✅ Admin - Get Group Info - View admin's group and code
- ✅ Admin - Regenerate Group Code - Generate new unique code
- ✅ Admin - Get Group Members - List all group members (paginated)
- ✅ Admin - Remove Group Member - Remove user from group
- ✅ User - Join Group - Join admin group using code
- ✅ User - Get Group Info - View current group information

### 13. File Operations (6 endpoints)
- ✅ Upload File - Generic file upload
- ✅ Get File - Download file
- ✅ Delete File - Remove file
- ✅ Upload Invoice to Expense - Attach invoice
- ✅ Get Invoice from Expense - Download invoice
- ✅ Delete Invoice from Expense - Remove invoice

## 🔐 Authentication

The collection uses **Bearer Token** authentication automatically.

### How it works:
1. When you **Register** or **Login**, the response token is automatically saved
2. All subsequent requests use this token in the `Authorization` header
3. Token format: `Bearer {{auth_token}}`

### Manual token setup (if needed):
1. Click on collection name
2. Go to **Authorization** tab
3. Type: Bearer Token
4. Token: `{{auth_token}}`

## 🧪 Testing Workflow

### Basic User Flow

```
1. Register → Creates user and saves token
2. Create Expense → Saves expense_id
3. Upload Invoice → Attaches file to expense
4. List Expenses → View all expenses
5. Update Expense → Modify expense
6. Get Expense → View updated expense
7. Delete Expense → Soft delete
```

### Admin Flow

```
1. Login as Admin → Use admin credentials
2. Get Stats → View system statistics
3. Get User Activity → See all users
4. Get Expense Summaries → View aggregations
5. List Audit Logs → Review all actions
6. Get Fund Box → Check balance
```

### Sync Flow

```
1. Create local changes → Use mobile app
2. Batch Sync → Send changes to server
3. Get Changes → Pull server updates
4. Resolve conflicts → Handle conflicts
```

### Admin Group Management Flow

```
1. Register Admin → Group automatically created with unique code
2. Get Group Info → Retrieve group code to share
3. Register User with Code → User joins group during registration
   OR
   User Joins Later → Existing user joins using code
4. Admin Views Members → See all users in group
5. Admin Manages Data → View/manage group member expenses
6. Admin Removes Member → Remove user from group if needed
7. Regenerate Code → Generate new code if compromised
```

**Key Features**:
- ✅ Automatic group creation for admins
- ✅ Unique 4-6 digit group codes
- ✅ Organization-based access control
- ✅ Data isolation between groups
- ✅ Transfer restrictions to group members
- ✅ Flexible member management

**See**: [Admin Group Testing Guide](ADMIN_GROUP_TESTING_GUIDE.md) for detailed testing scenarios

## 📝 Request Examples

### Create Expense with Multi-Currency

```json
{
  "description": "Office Supplies",
  "price_usd": 150.50,
  "price_syp": 2000000,
  "price_try": 4500,
  "expense_date": "2025-10-22"
}
```

### Create Transfer with Exchange

```json
// 1. Create Transfer
{
  "recipient_name": "John Doe",
  "amount_usd": 500.00,
  "transfer_date": "2025-10-22"
}

// 2. Add Exchange Data
{
  "converted_amount_syp": 6500000,
  "converted_amount_try": 15000,
  "exchange_rate_syp": 13000,
  "exchange_rate_try": 30
}
```

### Batch Sync Multiple Records

```json
{
  "records": [
    {
      "resource_type": "expense",
      "action": "create",
      "client_id": "client-123",
      "data": {
        "description": "Synced Expense",
        "price_usd": 100.00,
        "expense_date": "2025-10-22"
      }
    },
    {
      "resource_type": "transfer",
      "action": "update",
      "client_id": "client-456",
      "server_id": 5,
      "data": {
        "amount_usd": 600.00
      }
    }
  ]
}
```

### Register Admin with Free-Text Organization

```json
{
  "name": "Admin User",
  "email": "admin@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "organization_name": "Acme Corporation",
  "department_name": "Management",
  "role": "admin"
}
```

**Note**: Admin group with unique code is automatically created.

### Register User with Group Code

```json
{
  "name": "Team Member",
  "email": "user@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "organization_name": "Acme Corporation",
  "department_name": "Finance",
  "group_code": "123456",
  "role": "user"
}
```

**Note**: User automatically joins admin's group if organization matches.

### Join Group After Registration

```json
{
  "group_code": "123456"
}
```

**Requirements**:
- User must be authenticated
- Organization must match admin's organization
- User cannot already be in another group

## 🔍 Query Parameters

### List Endpoints Support:

**Pagination**:
- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 15)

**Date Filtering**:
- `start_date` - Start date (YYYY-MM-DD)
- `end_date` - End date (YYYY-MM-DD)

**Example**:
```
GET {{base_url}}/expenses?page=1&per_page=20&start_date=2025-01-01&end_date=2025-12-31
```

## 🎯 Auto-Generated Variables

The collection automatically captures and stores IDs from responses:

### Register/Login Response:
```javascript
// Automatically saves token
pm.collectionVariables.set('auth_token', data.data.token);
```

### Create Expense Response:
```javascript
// Automatically saves expense ID
pm.collectionVariables.set('expense_id', data.data.id);
```

This allows you to:
1. Create an expense
2. Immediately use `{{expense_id}}` in subsequent requests
3. No manual copying of IDs needed!

## 🛠️ Troubleshooting

### Issue: 401 Unauthorized

**Solution**: 
1. Run **Login** or **Register** request first
2. Check that `auth_token` variable is set
3. Verify token hasn't expired (30-day expiration)

### Issue: 403 Forbidden

**Solution**:
- Endpoint requires admin role
- Login with admin credentials
- Check user role in database

### Issue: 422 Validation Error

**Solution**:
- Check request body format
- Verify required fields are present
- Review validation rules in response

### Issue: 404 Not Found

**Solution**:
- Verify `base_url` is correct
- Check Laravel server is running
- Ensure database is migrated

### Issue: 429 Too Many Requests

**Solution**:
- Rate limit exceeded
- Wait 1 minute before retrying
- Public endpoints: 5 req/min
- Authenticated: 60 req/min

## 🌐 Environment Setup

### Local Development
```
base_url: http://localhost:8000/api/v1
```

### Staging
```
base_url: https://staging-api.yourapp.com/api/v1
```

### Production
```
base_url: https://api.yourapp.com/api/v1
```

**To switch environments**:
1. Create Postman environments for each
2. Set `base_url` variable in each environment
3. Switch active environment in Postman

## 📊 Response Format

All responses follow this structure:

### Success Response:
```json
{
  "success": true,
  "message": "Operation successful",
  "data": {
    // Response data here
  }
}
```

### Error Response:
```json
{
  "success": false,
  "message": "Error message",
  "errors": {
    "field": ["Validation error"]
  }
}
```

### Paginated Response:
```json
{
  "success": true,
  "data": [...],
  "meta": {
    "current_page": 1,
    "per_page": 15,
    "total": 100,
    "last_page": 7
  }
}
```

## 🔗 Related Documentation

- [API Endpoints Reference](../API_ENDPOINTS_REFERENCE.md)
- [Admin Group Testing Guide](ADMIN_GROUP_TESTING_GUIDE.md) - Comprehensive guide for testing admin group features
- [Admin Group Management Documentation](../docs/ADMIN_GROUP_MANAGEMENT.md)
- [Setup Guide](../SETUP_GUIDE.md)
- [README](../README.md)
- [OpenAPI Documentation](http://localhost:8000/api/documentation)

## 💡 Tips

1. **Use folders** - Requests are organized by resource type
2. **Check tests** - Some requests have test scripts that auto-save variables
3. **Enable query params** - Disabled params can be enabled for filtering
4. **Save responses** - Use Postman's "Save Response" for reference
5. **Create environments** - Set up dev/staging/prod environments
6. **Use pre-request scripts** - Add custom logic before requests
7. **Export results** - Share collection runs with your team

## 🤝 Contributing

To add new endpoints to this collection:

1. Add request to appropriate folder
2. Use collection variables for dynamic values
3. Add test scripts to capture response data
4. Update this README with new endpoint info

## 📄 License

This collection is part of the Finance Management Backend API project.

---

**Happy Testing! 🚀**

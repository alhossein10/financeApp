# Complete API URLs Reference

Base URL: `http://localhost:8000/api/v1`

## 📋 Quick Reference - All Endpoints

### 1. Authentication (No Auth Required)
```
POST   /auth/register              - Register new user
POST   /auth/login                 - Login user
POST   /auth/forgot-password       - Request password reset
POST   /auth/reset-password        - Reset password
```

### 2. Authentication (Auth Required)
```
GET    /auth/me                    - Get current user
POST   /auth/logout                - Logout user
POST   /auth/refresh               - Refresh token
```

### 3. Expenses (Auth Required)
```
GET    /expenses                   - List all expenses
POST   /expenses                   - Create expense
GET    /expenses/{id}              - Get single expense
PUT    /expenses/{id}              - Update expense
DELETE /expenses/{id}              - Delete expense
POST   /expenses/{id}/invoice      - Upload invoice
GET    /expenses/{id}/invoice      - Download invoice
DELETE /expenses/{id}/invoice      - Delete invoice
```

### 4. Transfers (Auth Required)
```
GET    /transfers                  - List all transfers
POST   /transfers                  - Create transfer
GET    /transfers/{id}             - Get single transfer
PUT    /transfers/{id}             - Update transfer
DELETE /transfers/{id}             - Delete transfer
POST   /transfers/{id}/exchange    - Add exchange data
```

### 5. Incoming/Income (Auth Required)
```
GET    /incoming                   - List all income
POST   /incoming                   - Create income
GET    /incoming/{id}              - Get single income
PUT    /incoming/{id}              - Update income
DELETE /incoming/{id}              - Delete income
```

### 6. Fund Box (Admin Only)
```
GET    /fund-box                   - Get fund box balance
PUT    /fund-box                   - Update fund box
```

### 7. User Profile (Auth Required)
```
GET    /profile                    - Get user profile
PUT    /profile                    - Update profile
PUT    /profile/password           - Change password
DELETE /profile                    - Delete account
```

### 8. Data Export (Auth Required)
```
GET    /export                     - List all exports
POST   /export/expenses/pdf        - Export expenses to PDF
POST   /export/expenses/excel      - Export expenses to Excel
POST   /export/system-wide         - System-wide export (Admin)
GET    /export/{id}/status         - Get export status
GET    /export/{id}/download       - Download export file
```

### 9. Admin Dashboard (Admin Only)
```
GET    /admin/dashboard/stats      - Get system statistics
GET    /admin/dashboard/users      - Get all users
GET    /admin/dashboard/expenses   - Get expense summaries
GET    /admin/dashboard/analytics  - Get analytics data
```

### 10. Audit Logs (Admin Only)
```
GET    /audit-logs                 - List all audit logs
GET    /audit-logs/{id}            - Get single audit log
```

### 11. Data Synchronization (Auth Required)
```
POST   /sync/batch                 - Batch sync data
GET    /sync/changes               - Get changes since timestamp
POST   /sync/resolve               - Resolve sync conflicts
```

### 12. File Management (Auth Required)
```
POST   /files/upload               - Upload file
GET    /files/download             - Download file
DELETE /files                      - Delete file
```

---

## 🎯 Complete URL Examples

### Authentication
```bash
# Register
POST http://localhost:8000/api/v1/auth/register

# Login
POST http://localhost:8000/api/v1/auth/login

# Get current user
GET http://localhost:8000/api/v1/auth/me
```

### Expenses
```bash
# List expenses
GET http://localhost:8000/api/v1/expenses

# Create expense
POST http://localhost:8000/api/v1/expenses

# Get expense by ID
GET http://localhost:8000/api/v1/expenses/1

# Update expense
PUT http://localhost:8000/api/v1/expenses/1

# Delete expense
DELETE http://localhost:8000/api/v1/expenses/1
```

### Transfers
```bash
# List transfers
GET http://localhost:8000/api/v1/transfers

# Create transfer
POST http://localhost:8000/api/v1/transfers

# Get transfer by ID
GET http://localhost:8000/api/v1/transfers/1

# Update transfer
PUT http://localhost:8000/api/v1/transfers/1

# Delete transfer
DELETE http://localhost:8000/api/v1/transfers/1
```

### Incoming (Income)
```bash
# List income
GET http://localhost:8000/api/v1/incoming

# Create income
POST http://localhost:8000/api/v1/incoming

# Get income by ID
GET http://localhost:8000/api/v1/incoming/1

# Update income
PUT http://localhost:8000/api/v1/incoming/1

# Delete income
DELETE http://localhost:8000/api/v1/incoming/1
```

### Fund Box
```bash
# Get fund box
GET http://localhost:8000/api/v1/fund-box

# Update fund box
PUT http://localhost:8000/api/v1/fund-box
```

### Profile
```bash
# Get profile
GET http://localhost:8000/api/v1/profile

# Update profile
PUT http://localhost:8000/api/v1/profile

# Change password
PUT http://localhost:8000/api/v1/profile/password
```

### Export
```bash
# Export to PDF
POST http://localhost:8000/api/v1/export/expenses/pdf

# Export to Excel
POST http://localhost:8000/api/v1/export/expenses/excel

# Download export
GET http://localhost:8000/api/v1/export/1/download
```

### Admin Dashboard
```bash
# Get stats
GET http://localhost:8000/api/v1/admin/dashboard/stats

# Get users
GET http://localhost:8000/api/v1/admin/dashboard/users

# Get expenses summary
GET http://localhost:8000/api/v1/admin/dashboard/expenses

# Get analytics
GET http://localhost:8000/api/v1/admin/dashboard/analytics
```

### Audit Logs
```bash
# List audit logs
GET http://localhost:8000/api/v1/audit-logs

# Get single log
GET http://localhost:8000/api/v1/audit-logs/1
```

### Sync
```bash
# Batch sync
POST http://localhost:8000/api/v1/sync/batch

# Get changes
GET http://localhost:8000/api/v1/sync/changes?since=2024-10-23T09:00:00Z
```

### Files
```bash
# Upload file
POST http://localhost:8000/api/v1/files/upload

# Download file
GET http://localhost:8000/api/v1/files/download?path=encrypted_path

# Delete file
DELETE http://localhost:8000/api/v1/files
```

---

## 📦 Import Postman Collection

**File:** `postman/Finance-API-COMPLETE.postman_collection.json`

This collection includes:
- ✅ All 50+ endpoints
- ✅ Auto-save tokens and IDs
- ✅ Pre-configured request bodies
- ✅ Test scripts
- ✅ Environment variables

**To Import:**
1. Open Postman
2. Click "Import"
3. Select `Finance-API-COMPLETE.postman_collection.json`
4. Start testing!

---

## 🔑 Authentication

All endpoints (except register, login, forgot/reset password) require authentication.

**Add to Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
Accept: application/json
Content-Type: application/json
```

**Token is automatically saved** when you register or login using the Postman collection!

---

## 📝 Request Body Examples

### Create Expense
```json
{
  "amount": 150.50,
  "category": "Food",
  "description": "Grocery shopping",
  "date": "2024-10-23",
  "payment_method": "cash"
}
```

### Create Transfer
```json
{
  "amount": 500.00,
  "from_account": "Savings",
  "to_account": "Checking",
  "description": "Monthly transfer",
  "date": "2024-10-23"
}
```

### Create Income
```json
{
  "amount": 5000.00,
  "source": "Salary",
  "description": "Monthly salary",
  "date": "2024-10-23",
  "payment_method": "bank_transfer"
}
```

---

## 🎯 Testing Order

1. **Register** → Get token
2. **Create Expense** → Get expense_id
3. **List Expenses** → See all expenses
4. **Update Expense** → Modify expense
5. **Delete Expense** → Remove expense
6. Repeat for Transfers and Income
7. Test Export features
8. Test Admin features (if admin user)

Happy Testing! 🚀

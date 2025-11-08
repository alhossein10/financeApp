# API Testing Guide with Postman

## Overview

This guide provides comprehensive instructions for testing the Laravel API using Postman. Use this to verify API functionality, test error scenarios, and validate field mappings.

## Setup

### 1. Install Postman

Download and install Postman from [https://www.postman.com/downloads/](https://www.postman.com/downloads/)

### 2. Import Collection

The Laravel backend includes a Postman collection:

1. Open Postman
2. Click "Import"
3. Select `financeApp-backend-main/Finance-API-COMPLETE.postman_collection.json`
4. Click "Import"

### 3. Configure Environment

Create a new environment with these variables:

| Variable | Value | Description |
|----------|-------|-------------|
| base_url | http://localhost:8000/api/v1 | API base URL |
| token | (empty) | Auth token (set after login) |
| user_email | user@example.com | Test user email |
| user_password | password | Test user password |
| admin_email | admin@example.com | Test admin email |
| admin_password | password | Test admin password |

## Authentication

### Register User

**Endpoint**: `POST {{base_url}}/auth/register`

**Body**:
```json
{
  "name": "Test User",
  "email": "user@example.com",
  "password": "password",
  "password_confirmation": "password"
}
```

**Expected Response** (201):
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "user": {
      "id": 1,
      "name": "Test User",
      "email": "user@example.com",
      "role": "user"
    },
    "token": "1|abc123..."
  }
}
```

**Action**: Copy the token and set it in environment variable `token`

### Login User

**Endpoint**: `POST {{base_url}}/auth/login`

**Body**:
```json
{
  "email": "{{user_email}}",
  "password": "{{user_password}}"
}
```

**Expected Response** (200):
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "name": "Test User",
      "email": "user@example.com",
      "role": "user"
    },
    "token": "1|abc123..."
  }
}
```

**Action**: Copy the token and set it in environment variable `token`

### Get Current User

**Endpoint**: `GET {{base_url}}/auth/me`

**Headers**:
```
Authorization: Bearer {{token}}
```

**Expected Response** (200):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Test User",
    "email": "user@example.com",
    "role": "user"
  }
}
```

### Logout

**Endpoint**: `POST {{base_url}}/auth/logout`

**Headers**:
```
Authorization: Bearer {{token}}
```

**Expected Response** (200):
```json
{
  "success": true,
  "message": "Logout successful"
}
```

## Transfer Module

### Create Transfer

**Endpoint**: `POST {{base_url}}/transfers`

**Headers**:
```
Authorization: Bearer {{token}}
Content-Type: application/json
```

**Body**:
```json
{
  "amount": 100.50,
  "from_account": "Savings",
  "to_account": "Checking",
  "description": "Monthly transfer",
  "date": "2025-10-28"
}
```

**Expected Response** (201):
```json
{
  "success": true,
  "message": "Transfer created successfully",
  "data": {
    "id": 1,
    "user_id": 1,
    "amount": 100.50,
    "from_account": "Savings",
    "to_account": "Checking",
    "description": "Monthly transfer",
    "date": "2025-10-28",
    "created_at": "2025-10-28T10:30:00.000000Z",
    "updated_at": "2025-10-28T10:30:00.000000Z"
  }
}
```

**Test Cases**:
- ✓ Valid transfer creation
- ✓ Missing required fields (should return 422)
- ✓ Invalid date format (should return 422)
- ✓ Negative amount (should return 422)
- ✓ Without authentication (should return 401)

### List Transfers

**Endpoint**: `GET {{base_url}}/transfers?page=1&per_page=15`

**Headers**:
```
Authorization: Bearer {{token}}
```

**Expected Response** (200):
```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 1,
        "amount": 100.50,
        "from_account": "Savings",
        "to_account": "Checking",
        "date": "2025-10-28"
      }
    ],
    "last_page": 1,
    "per_page": 15,
    "total": 1
  }
}
```

### Get Transfer

**Endpoint**: `GET {{base_url}}/transfers/1`

**Headers**:
```
Authorization: Bearer {{token}}
```

**Expected Response** (200):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "user_id": 1,
    "amount": 100.50,
    "from_account": "Savings",
    "to_account": "Checking",
    "description": "Monthly transfer",
    "date": "2025-10-28",
    "created_at": "2025-10-28T10:30:00.000000Z",
    "updated_at": "2025-10-28T10:30:00.000000Z"
  }
}
```

### Update Transfer

**Endpoint**: `PUT {{base_url}}/transfers/1`

**Headers**:
```
Authorization: Bearer {{token}}
Content-Type: application/json
```

**Body**:
```json
{
  "amount": 150.00,
  "from_account": "Savings",
  "to_account": "Investment",
  "description": "Updated transfer",
  "date": "2025-10-28"
}
```

**Expected Response** (200):
```json
{
  "success": true,
  "message": "Transfer updated successfully",
  "data": {
    "id": 1,
    "amount": 150.00,
    "from_account": "Savings",
    "to_account": "Investment",
    "description": "Updated transfer",
    "date": "2025-10-28"
  }
}
```

### Delete Transfer

**Endpoint**: `DELETE {{base_url}}/transfers/1`

**Headers**:
```
Authorization: Bearer {{token}}
```

**Expected Response** (200):
```json
{
  "success": true,
  "message": "Transfer deleted successfully"
}
```

## Incoming Module

### Create Incoming

**Endpoint**: `POST {{base_url}}/incoming`

**Headers**:
```
Authorization: Bearer {{token}}
Content-Type: application/json
```

**Body**:
```json
{
  "amount": 5000.00,
  "source": "Salary",
  "description": "October salary",
  "date": "2025-10-28",
  "payment_method": "bank_transfer"
}
```

**Expected Response** (201):
```json
{
  "success": true,
  "message": "Income created successfully",
  "data": {
    "id": 1,
    "user_id": 1,
    "amount": 5000.00,
    "source": "Salary",
    "description": "October salary",
    "date": "2025-10-28",
    "payment_method": "bank_transfer",
    "created_at": "2025-10-28T10:30:00.000000Z",
    "updated_at": "2025-10-28T10:30:00.000000Z"
  }
}
```

**Test Cases**:
- ✓ Valid payment methods: cash, card, bank_transfer
- ✗ Invalid payment method: credit (should return 422)
- ✗ Missing source field (should return 422)

## Expense Module

### Create Expense

**Endpoint**: `POST {{base_url}}/expenses`

**Headers**:
```
Authorization: Bearer {{token}}
Content-Type: application/json
```

**Body**:
```json
{
  "amount": 50.00,
  "category": "Food",
  "description": "Lunch",
  "date": "2025-10-28",
  "payment_method": "card"
}
```

**Expected Response** (201):
```json
{
  "success": true,
  "message": "Expense created successfully",
  "data": {
    "id": 1,
    "user_id": 1,
    "amount": 50.00,
    "category": "Food",
    "description": "Lunch",
    "date": "2025-10-28",
    "payment_method": "card",
    "created_at": "2025-10-28T10:30:00.000000Z",
    "updated_at": "2025-10-28T10:30:00.000000Z"
  }
}
```

### Filter Expenses

**Endpoint**: `GET {{base_url}}/expenses?category=Food&date_from=2025-10-01&date_to=2025-10-31`

**Headers**:
```
Authorization: Bearer {{token}}
```

**Expected Response** (200):
```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 1,
        "amount": 50.00,
        "category": "Food",
        "date": "2025-10-28"
      }
    ],
    "last_page": 1,
    "per_page": 15,
    "total": 1
  }
}
```

## Fund Box Module (Admin Only)

### Get Fund Box

**Endpoint**: `GET {{base_url}}/fund-box`

**Headers**:
```
Authorization: Bearer {{token}}
```

**Expected Response** (200 for admin, 403 for user):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "total_balance": 10000.00,
    "last_updated": "2025-10-28T10:30:00.000000Z"
  }
}
```

**Test Cases**:
- ✓ Admin user can access (200)
- ✗ Regular user cannot access (403)

### Update Fund Box

**Endpoint**: `PUT {{base_url}}/fund-box`

**Headers**:
```
Authorization: Bearer {{token}}
Content-Type: application/json
```

**Body**:
```json
{
  "total_balance": 15000.00
}
```

**Expected Response** (200 for admin, 403 for user):
```json
{
  "success": true,
  "message": "Fund box updated successfully",
  "data": {
    "id": 1,
    "total_balance": 15000.00,
    "last_updated": "2025-10-28T10:35:00.000000Z"
  }
}
```

## Admin Dashboard (Admin Only)

### Get Dashboard Stats

**Endpoint**: `GET {{base_url}}/admin/dashboard/stats`

**Headers**:
```
Authorization: Bearer {{token}}
```

**Expected Response** (200 for admin, 403 for user):
```json
{
  "success": true,
  "data": {
    "total_users": 10,
    "total_expenses": 150,
    "total_income": 50,
    "total_transfers": 30,
    "total_amount_expenses": 5000.00,
    "total_amount_income": 10000.00,
    "fund_box_balance": 5000.00
  }
}
```

### Get User Activity

**Endpoint**: `GET {{base_url}}/admin/dashboard/users`

**Headers**:
```
Authorization: Bearer {{token}}
```

**Expected Response** (200 for admin, 403 for user):
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user",
      "expense_count": 50,
      "income_count": 10,
      "transfer_count": 5,
      "last_active": "2025-10-28T10:30:00.000000Z"
    }
  ]
}
```

### Get Expense Summary

**Endpoint**: `GET {{base_url}}/admin/dashboard/expenses`

**Headers**:
```
Authorization: Bearer {{token}}
```

**Expected Response** (200 for admin, 403 for user):
```json
{
  "success": true,
  "data": {
    "by_category": {
      "Food": {
        "category": "Food",
        "total": 500.00,
        "count": 10
      }
    },
    "by_payment_method": {
      "cash": {
        "payment_method": "cash",
        "total": 300.00
      }
    }
  }
}
```

### Get Analytics

**Endpoint**: `GET {{base_url}}/admin/dashboard/analytics?date_from=2025-10-01&date_to=2025-10-31`

**Headers**:
```
Authorization: Bearer {{token}}
```

**Expected Response** (200 for admin, 403 for user):
```json
{
  "success": true,
  "data": {
    "period": {
      "from": "2025-10-01",
      "to": "2025-10-31"
    },
    "expenses": {
      "total": 5000.00,
      "count": 150,
      "average": 33.33
    },
    "income": {
      "total": 10000.00,
      "count": 50,
      "average": 200.00
    },
    "net_balance": 5000.00,
    "trends": {
      "monthly": [
        {
          "month": "2025-10",
          "expenses": 5000.00,
          "income": 10000.00
        }
      ]
    }
  }
}
```

## Profile Module

### Get Profile

**Endpoint**: `GET {{base_url}}/profile`

**Headers**:
```
Authorization: Bearer {{token}}
```

**Expected Response** (200):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "user",
    "created_at": "2025-10-01T10:00:00.000000Z"
  }
}
```

### Update Profile

**Endpoint**: `PUT {{base_url}}/profile`

**Headers**:
```
Authorization: Bearer {{token}}
Content-Type: application/json
```

**Body**:
```json
{
  "name": "John Smith",
  "email": "john.smith@example.com"
}
```

**Expected Response** (200):
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "id": 1,
    "name": "John Smith",
    "email": "john.smith@example.com",
    "role": "user"
  }
}
```

### Change Password

**Endpoint**: `POST {{base_url}}/profile/password`

**Headers**:
```
Authorization: Bearer {{token}}
Content-Type: application/json
```

**Body**:
```json
{
  "current_password": "password",
  "new_password": "newpassword123",
  "new_password_confirmation": "newpassword123"
}
```

**Expected Response** (200):
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

## Export Module

### Export Expenses to PDF

**Endpoint**: `POST {{base_url}}/export/expenses/pdf`

**Headers**:
```
Authorization: Bearer {{token}}
Content-Type: application/json
```

**Body**:
```json
{
  "format": "pdf",
  "date_from": "2025-10-01",
  "date_to": "2025-10-31"
}
```

**Expected Response** (202):
```json
{
  "success": true,
  "message": "Export job created",
  "data": {
    "id": "exp_abc123",
    "format": "pdf",
    "status": "processing",
    "created_at": "2025-10-28T10:30:00.000000Z"
  }
}
```

### Check Export Status

**Endpoint**: `GET {{base_url}}/export/exp_abc123/status`

**Headers**:
```
Authorization: Bearer {{token}}
```

**Expected Response** (200):
```json
{
  "success": true,
  "data": {
    "id": "exp_abc123",
    "format": "pdf",
    "status": "completed",
    "download_url": "https://api.example.com/exports/exp_abc123/download",
    "created_at": "2025-10-28T10:30:00.000000Z"
  }
}
```

### Download Export

**Endpoint**: `GET {{base_url}}/export/exp_abc123/download`

**Headers**:
```
Authorization: Bearer {{token}}
```

**Expected Response** (200):
- Content-Type: application/pdf or application/vnd.ms-excel
- Binary file data

## Batch Sync Module

### Batch Sync

**Endpoint**: `POST {{base_url}}/sync/batch`

**Headers**:
```
Authorization: Bearer {{token}}
Content-Type: application/json
```

**Body**:
```json
{
  "last_sync": "2025-10-28T10:00:00.000Z",
  "data": {
    "expenses": [
      {
        "local_id": "temp_1",
        "amount": 50.00,
        "category": "Food",
        "date": "2025-10-28",
        "payment_method": "cash"
      }
    ],
    "incoming": [],
    "transfers": []
  }
}
```

**Expected Response** (200):
```json
{
  "success": true,
  "data": {
    "synced_at": "2025-10-28T10:30:00.000Z",
    "expenses": {
      "created": [
        {
          "local_id": "temp_1",
          "server_id": 123,
          "data": {...}
        }
      ],
      "conflicts": []
    },
    "incoming": {
      "created": [],
      "conflicts": []
    },
    "transfers": {
      "created": [],
      "conflicts": []
    }
  }
}
```

### Get Changes

**Endpoint**: `GET {{base_url}}/sync/changes?since=2025-10-28T10:00:00.000Z`

**Headers**:
```
Authorization: Bearer {{token}}
```

**Expected Response** (200):
```json
{
  "success": true,
  "data": {
    "expenses": {
      "created": [...],
      "updated": [...],
      "deleted": [1, 2, 3]
    },
    "incoming": {...},
    "transfers": {...}
  }
}
```

## File Upload Module

### Upload File

**Endpoint**: `POST {{base_url}}/files/upload`

**Headers**:
```
Authorization: Bearer {{token}}
Content-Type: multipart/form-data
```

**Body** (form-data):
- file: (select file)
- type: receipt

**Expected Response** (201):
```json
{
  "success": true,
  "message": "File uploaded successfully",
  "data": {
    "id": 1,
    "filename": "receipt.jpg",
    "path": "encrypted_path_abc123",
    "type": "receipt",
    "size": 1024000,
    "mime_type": "image/jpeg",
    "uploaded_at": "2025-10-28T10:30:00.000000Z"
  }
}
```

### Download File

**Endpoint**: `GET {{base_url}}/files/download?path=encrypted_path_abc123`

**Headers**:
```
Authorization: Bearer {{token}}
```

**Expected Response** (200):
- Binary file data

### Delete File

**Endpoint**: `DELETE {{base_url}}/files`

**Headers**:
```
Authorization: Bearer {{token}}
Content-Type: application/json
```

**Body**:
```json
{
  "path": "encrypted_path_abc123"
}
```

**Expected Response** (200):
```json
{
  "success": true,
  "message": "File deleted successfully"
}
```

## Audit Logs (Admin Only)

### List Audit Logs

**Endpoint**: `GET {{base_url}}/audit-logs?page=1&per_page=15`

**Headers**:
```
Authorization: Bearer {{token}}
```

**Expected Response** (200 for admin, 403 for user):
```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 1,
        "user_id": 1,
        "action": "expense.created",
        "entity_type": "Expense",
        "entity_id": 123,
        "ip_address": "192.168.1.1",
        "user_agent": "Mozilla/5.0...",
        "created_at": "2025-10-28T10:30:00.000000Z"
      }
    ],
    "last_page": 1,
    "per_page": 15,
    "total": 1
  }
}
```

### Get Audit Log Details

**Endpoint**: `GET {{base_url}}/audit-logs/1`

**Headers**:
```
Authorization: Bearer {{token}}
```

**Expected Response** (200 for admin, 403 for user):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "user_id": 1,
    "user_name": "John Doe",
    "action": "expense.updated",
    "entity_type": "Expense",
    "entity_id": 123,
    "changes": {
      "amount": {
        "old": 50.00,
        "new": 75.00
      }
    },
    "ip_address": "192.168.1.1",
    "user_agent": "Mozilla/5.0...",
    "created_at": "2025-10-28T10:30:00.000000Z"
  }
}
```

## Error Testing

### Test 401 Unauthorized

Remove or use invalid token:

**Headers**:
```
Authorization: Bearer invalid_token
```

**Expected Response** (401):
```json
{
  "message": "Unauthenticated."
}
```

### Test 403 Forbidden

Use regular user token for admin endpoint:

**Endpoint**: `GET {{base_url}}/fund-box`

**Expected Response** (403):
```json
{
  "message": "Forbidden. Admin privileges required."
}
```

### Test 422 Validation Error

Send invalid data:

**Body**:
```json
{
  "amount": -50,
  "payment_method": "invalid"
}
```

**Expected Response** (422):
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "amount": ["The amount must be greater than 0."],
    "payment_method": ["The selected payment method is invalid."]
  }
}
```

### Test 429 Rate Limit

Send many requests quickly (> 60 per minute):

**Expected Response** (429):
```json
{
  "message": "Too Many Requests"
}
```

## Testing Checklist

- [ ] All authentication endpoints work
- [ ] Token is properly set after login
- [ ] All CRUD operations work for transfers
- [ ] All CRUD operations work for incoming
- [ ] All CRUD operations work for expenses
- [ ] Fund box accessible by admin only
- [ ] Admin dashboard accessible by admin only
- [ ] Audit logs accessible by admin only
- [ ] Profile endpoints work
- [ ] Export endpoints work
- [ ] File upload/download works
- [ ] Batch sync works
- [ ] Pagination works correctly
- [ ] Filtering works correctly
- [ ] Date format validation works
- [ ] Payment method validation works
- [ ] 401 errors handled correctly
- [ ] 403 errors handled correctly
- [ ] 422 errors handled correctly
- [ ] 429 errors handled correctly

## Summary

- Use Postman collection for comprehensive testing
- Set up environment variables for easy testing
- Test both user and admin roles
- Test all error scenarios
- Verify field mappings match specification
- Test pagination and filtering
- Test file upload/download
- Test batch sync functionality

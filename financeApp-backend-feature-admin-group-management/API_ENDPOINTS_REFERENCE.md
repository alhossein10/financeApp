# API Endpoints Reference

Complete reference for all Finance Management API endpoints.

**Base URL**: `http://localhost:8000/api/v1`

**Authentication**: Most endpoints require a Bearer token in the Authorization header.

## Table of Contents

- [Authentication](#authentication)
- [Admin Group Management](#admin-group-management-admin-only)
- [User Group Management](#user-group-management)
- [Expenses](#expenses)
- [Transfers](#transfers)
- [Incoming Funds](#incoming-funds)
- [Fund Box](#fund-box-admin-only)
- [Admin Dashboard](#admin-dashboard-admin-only)
- [Audit Logs](#audit-logs-admin-only)
- [Synchronization](#synchronization)
- [User Profile](#user-profile)
- [Data Export](#data-export)
- [File Operations](#file-operations)

---

## Authentication

### Register

Create a new user account.

**Endpoint**: `POST /api/v1/auth/register`

**Rate Limit**: 5 requests/minute

**Request Body**:
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "role": "user",
  "organization_name": "Acme Corporation",
  "department_name": "Finance",
  "group_code": "123456"
}
```

**Fields**:
- `name` (required): User's full name
- `email` (required): User's email address
- `password` (required): Password (min 8 characters)
- `password_confirmation` (required): Password confirmation
- `role` (required): User role ("admin" or "user")
- `organization_name` (required): Free-text organization name (2-255 chars)
- `department_name` (optional): Free-text department name (2-255 chars)
- `group_code` (optional): 4-6 digit group code to join admin's group

**Response** (201):
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user",
      "organization_name": "Acme Corporation",
      "department_name": "Finance",
      "admin_group_id": 1,
      "created_at": "2025-10-22T10:00:00Z"
    },
    "token": "1|abc123...",
    "token_type": "Bearer",
    "expires_in": 2592000,
    "group": {
      "id": 1,
      "group_name": "Acme Corporation - Admin Name"
    }
  }
}
```

### Login

Authenticate and receive an API token.

**Endpoint**: `POST /api/v1/auth/login`

**Rate Limit**: 5 requests/minute

**Request Body**:
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response** (200):
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user"
    },
    "token": "1|abc123...",
    "token_type": "Bearer",
    "expires_in": 2592000
  }
}
```

### Logout

Revoke the current API token.

**Endpoint**: `POST /api/v1/auth/logout`

**Authentication**: Required

**Response** (200):
```json
{
  "success": true,
  "message": "Logout successful"
}
```

### Refresh Token

Get a new API token.

**Endpoint**: `POST /api/v1/auth/refresh`

**Authentication**: Required

**Response** (200):
```json
{
  "success": true,
  "message": "Token refreshed successfully",
  "data": {
    "token": "2|xyz789...",
    "token_type": "Bearer",
    "expires_in": 2592000
  }
}
```

### Get Current User

Get authenticated user information.

**Endpoint**: `GET /api/v1/auth/me`

**Authentication**: Required

**Response** (200):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "user",
    "created_at": "2025-10-22T10:00:00Z"
  }
}
```

### Forgot Password

Request a password reset link.

**Endpoint**: `POST /api/v1/auth/forgot-password`

**Rate Limit**: 5 requests/minute

**Request Body**:
```json
{
  "email": "john@example.com"
}
```

**Response** (200):
```json
{
  "success": true,
  "message": "Password reset link sent to your email"
}
```

### Reset Password

Reset password using token from email.

**Endpoint**: `POST /api/v1/auth/reset-password`

**Rate Limit**: 5 requests/minute

**Request Body**:
```json
{
  "email": "john@example.com",
  "token": "reset-token-from-email",
  "password": "newpassword123",
  "password_confirmation": "newpassword123"
}
```

**Response** (200):
```json
{
  "success": true,
  "message": "Password reset successful"
}
```

---

## Admin Group Management (Admin Only)

### Get Admin's Group Information

Get the authenticated admin's group information including group code.

**Endpoint**: `GET /api/v1/admin/group`

**Authentication**: Required (Admin only)

**Response** (200):
```json
{
  "success": true,
  "message": "Group information retrieved successfully.",
  "data": {
    "group": {
      "id": 1,
      "admin_user_id": 1,
      "group_code": "123456",
      "group_name": "Acme Corporation - John Doe",
      "is_active": true,
      "created_at": "2025-11-01T10:00:00Z",
      "updated_at": "2025-11-01T10:00:00Z"
    }
  }
}
```

### Regenerate Group Code

Generate a new unique group code for the admin.

**Endpoint**: `POST /api/v1/admin/group/regenerate`

**Authentication**: Required (Admin only)

**Response** (200):
```json
{
  "success": true,
  "message": "Group code regenerated successfully.",
  "data": {
    "group": {
      "id": 1,
      "admin_user_id": 1,
      "group_code": "654321",
      "group_name": "Acme Corporation - John Doe",
      "is_active": true,
      "created_at": "2025-11-01T10:00:00Z",
      "updated_at": "2025-11-01T11:00:00Z"
    }
  }
}
```

### Get Group Members

Get paginated list of users in the admin's group.

**Endpoint**: `GET /api/v1/admin/group/members`

**Authentication**: Required (Admin only)

**Query Parameters**:
- `page` (integer, optional): Page number (default: 1)
- `per_page` (integer, optional): Items per page (default: 15, max: 100)
- `search` (string, optional): Search by name or email

**Response** (200):
```json
{
  "success": true,
  "message": "Group members retrieved successfully.",
  "data": {
    "members": {
      "current_page": 1,
      "data": [
        {
          "id": 2,
          "name": "Jane Smith",
          "email": "jane@example.com",
          "organization_name": "Acme Corporation",
          "department_name": "Marketing",
          "created_at": "2025-11-01T10:05:00Z"
        }
      ],
      "per_page": 15,
      "total": 1,
      "last_page": 1
    }
  }
}
```

### Remove Member from Group

Remove a user from the admin's group.

**Endpoint**: `DELETE /api/v1/admin/group/members/{id}`

**Authentication**: Required (Admin only)

**Path Parameters**:
- `id` (integer, required): User ID to remove

**Response** (200):
```json
{
  "success": true,
  "message": "Member removed from group successfully."
}
```

---

## User Group Management

### Join Group Using Code

Join an admin's group using a group code.

**Endpoint**: `POST /api/v1/user/join-group`

**Authentication**: Required (Regular user only)

**Request Body**:
```json
{
  "group_code": "123456"
}
```

**Response** (200):
```json
{
  "success": true,
  "message": "Successfully joined group.",
  "data": {
    "group": {
      "id": 1,
      "group_name": "Acme Corporation - John Doe",
      "admin": {
        "id": 1,
        "name": "John Doe",
        "email": "john@example.com"
      }
    }
  }
}
```

**Error Response** (403 - Organization Mismatch):
```json
{
  "success": false,
  "message": "Failed to join group.",
  "errors": {
    "group_code": ["Cannot join group from different organization."]
  }
}
```

### Get User's Group Information

Get the authenticated user's group information.

**Endpoint**: `GET /api/v1/user/group-info`

**Authentication**: Required (Regular user only)

**Response** (200):
```json
{
  "success": true,
  "message": "Group information retrieved successfully.",
  "data": {
    "group": {
      "id": 1,
      "group_name": "Acme Corporation - John Doe",
      "admin": {
        "id": 1,
        "name": "John Doe",
        "email": "john@example.com"
      }
    }
  }
}
```

**Error Response** (404 - Not in Group):
```json
{
  "success": false,
  "message": "User is not in a group."
}
```

---

## Expenses

### List Expenses

Get paginated list of expenses.

**Endpoint**: `GET /api/v1/expenses`

**Authentication**: Required

**Query Parameters**:
- `page` (integer, optional): Page number (default: 1)
- `per_page` (integer, optional): Items per page (default: 15, max: 100)
- `start_date` (date, optional): Filter by start date (YYYY-MM-DD)
- `end_date` (date, optional): Filter by end date (YYYY-MM-DD)
- `sync_status` (string, optional): Filter by sync status (pending, syncing, synced, failed)

**Response** (200):
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": 1,
        "description": "Office supplies",
        "price_usd": "50.00",
        "price_syp": "125000.00",
        "price_try": null,
        "has_invoice": true,
        "expense_date": "2025-10-22",
        "sync_status": "synced",
        "created_at": "2025-10-22T10:00:00Z",
        "updated_at": "2025-10-22T10:00:00Z"
      }
    ],
    "current_page": 1,
    "per_page": 15,
    "total": 50,
    "last_page": 4
  }
}
```

### Create Expense

Create a new expense record.

**Endpoint**: `POST /api/v1/expenses`

**Authentication**: Required

**Request Body**:
```json
{
  "description": "Office supplies",
  "price_usd": 50.00,
  "price_syp": 125000.00,
  "price_try": null,
  "expense_date": "2025-10-22",
  "has_invoice": false
}
```

**Response** (201):
```json
{
  "success": true,
  "message": "Expense created successfully",
  "data": {
    "id": 1,
    "description": "Office supplies",
    "price_usd": "50.00",
    "price_syp": "125000.00",
    "price_try": null,
    "has_invoice": false,
    "expense_date": "2025-10-22",
    "sync_status": "synced",
    "created_at": "2025-10-22T10:00:00Z",
    "updated_at": "2025-10-22T10:00:00Z"
  }
}
```

### Get Expense

Get a single expense by ID.

**Endpoint**: `GET /api/v1/expenses/{id}`

**Authentication**: Required

**Response** (200):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "description": "Office supplies",
    "price_usd": "50.00",
    "price_syp": "125000.00",
    "price_try": null,
    "has_invoice": true,
    "invoice_path": "invoices/abc123.jpg",
    "expense_date": "2025-10-22",
    "sync_status": "synced",
    "created_at": "2025-10-22T10:00:00Z",
    "updated_at": "2025-10-22T10:00:00Z"
  }
}
```

### Update Expense

Update an existing expense.

**Endpoint**: `PUT /api/v1/expenses/{id}`

**Authentication**: Required

**Request Body**:
```json
{
  "description": "Updated office supplies",
  "price_usd": 55.00,
  "price_syp": 137500.00,
  "expense_date": "2025-10-22"
}
```

**Response** (200):
```json
{
  "success": true,
  "message": "Expense updated successfully",
  "data": {
    "id": 1,
    "description": "Updated office supplies",
    "price_usd": "55.00",
    "price_syp": "137500.00",
    "price_try": null,
    "has_invoice": true,
    "expense_date": "2025-10-22",
    "sync_status": "synced",
    "updated_at": "2025-10-22T11:00:00Z"
  }
}
```

### Delete Expense

Soft delete an expense.

**Endpoint**: `DELETE /api/v1/expenses/{id}`

**Authentication**: Required

**Response** (204): No content

### Upload Invoice

Upload an invoice file for an expense.

**Endpoint**: `POST /api/v1/expenses/{id}/invoice`

**Authentication**: Required

**Content-Type**: `multipart/form-data`

**Request Body**:
- `file`: Image file (JPEG, PNG, max 10MB)

**Response** (200):
```json
{
  "success": true,
  "message": "Invoice uploaded successfully",
  "data": {
    "invoice_path": "invoices/abc123.jpg",
    "invoice_url": "http://localhost:8000/api/v1/files/download?path=..."
  }
}
```

### Download Invoice

Download an invoice file.

**Endpoint**: `GET /api/v1/expenses/{id}/invoice`

**Authentication**: Required

**Response**: Binary file data

### Delete Invoice

Delete an invoice file from an expense.

**Endpoint**: `DELETE /api/v1/expenses/{id}/invoice`

**Authentication**: Required

**Response** (200):
```json
{
  "success": true,
  "message": "Invoice deleted successfully"
}
```

---

## Transfers

### List Transfers

Get paginated list of transfers.

**Endpoint**: `GET /api/v1/transfers`

**Authentication**: Required

**Query Parameters**:
- `page` (integer, optional): Page number
- `per_page` (integer, optional): Items per page
- `start_date` (date, optional): Filter by start date
- `end_date` (date, optional): Filter by end date

**Response** (200):
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": 1,
        "recipient_name": "Jane Smith",
        "amount_usd": "100.00",
        "transfer_date": "2025-10-22",
        "notes": "Payment for services",
        "exchange": {
          "converted_amount_syp": "250000.00",
          "exchange_rate_usd_to_syp": "2500.00",
          "exchange_date": "2025-10-22"
        },
        "created_at": "2025-10-22T10:00:00Z"
      }
    ],
    "current_page": 1,
    "total": 25
  }
}
```

### Create Transfer

Create a new transfer record.

**Endpoint**: `POST /api/v1/transfers`

**Authentication**: Required

**Request Body**:
```json
{
  "recipient_name": "Jane Smith",
  "amount_usd": 100.00,
  "transfer_date": "2025-10-22",
  "notes": "Payment for services"
}
```

**Response** (201):
```json
{
  "success": true,
  "message": "Transfer created successfully",
  "data": {
    "id": 1,
    "recipient_name": "Jane Smith",
    "amount_usd": "100.00",
    "transfer_date": "2025-10-22",
    "notes": "Payment for services",
    "created_at": "2025-10-22T10:00:00Z"
  }
}
```

### Get Transfer

Get a single transfer by ID.

**Endpoint**: `GET /api/v1/transfers/{id}`

**Authentication**: Required

**Response** (200): Similar to list response

### Update Transfer

Update an existing transfer.

**Endpoint**: `PUT /api/v1/transfers/{id}`

**Authentication**: Required

**Request Body**: Same as create

**Response** (200): Updated transfer data

### Delete Transfer

Soft delete a transfer.

**Endpoint**: `DELETE /api/v1/transfers/{id}`

**Authentication**: Required

**Response** (204): No content

### Add Exchange to Transfer

Add currency exchange information to a transfer.

**Endpoint**: `POST /api/v1/transfers/{id}/exchange`

**Authentication**: Required

**Request Body**:
```json
{
  "converted_amount_syp": 250000.00,
  "exchange_rate_usd_to_syp": 2500.00,
  "exchange_date": "2025-10-22"
}
```

**Response** (201):
```json
{
  "success": true,
  "message": "Exchange added successfully",
  "data": {
    "id": 1,
    "transfer_id": 1,
    "converted_amount_syp": "250000.00",
    "exchange_rate_usd_to_syp": "2500.00",
    "exchange_date": "2025-10-22"
  }
}
```

---

## Incoming Funds

### List Incoming

Get paginated list of incoming transactions.

**Endpoint**: `GET /api/v1/incoming`

**Authentication**: Required

**Query Parameters**: Same as expenses

**Response** (200):
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": 1,
        "description": "Client payment",
        "amount_usd": "500.00",
        "incoming_date": "2025-10-22",
        "created_at": "2025-10-22T10:00:00Z"
      }
    ],
    "current_page": 1,
    "total": 15
  }
}
```

### Create Incoming

Create a new incoming transaction.

**Endpoint**: `POST /api/v1/incoming`

**Authentication**: Required

**Request Body**:
```json
{
  "description": "Client payment",
  "amount_usd": 500.00,
  "incoming_date": "2025-10-22"
}
```

**Response** (201): Created incoming data

### Get Incoming

**Endpoint**: `GET /api/v1/incoming/{id}`

### Update Incoming

**Endpoint**: `PUT /api/v1/incoming/{id}`

### Delete Incoming

**Endpoint**: `DELETE /api/v1/incoming/{id}`

---

## Fund Box (Admin Only)

### Get Fund Box

Get the current fund box balance.

**Endpoint**: `GET /api/v1/fund-box`

**Authentication**: Required (Admin only)

**Response** (200):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "balance_usd": "5000.00",
    "last_calculated_at": "2025-10-22T10:00:00Z",
    "updated_at": "2025-10-22T10:00:00Z"
  }
}
```

### Update Fund Box

Update the fund box balance.

**Endpoint**: `PUT /api/v1/fund-box`

**Authentication**: Required (Admin only)

**Request Body**:
```json
{
  "balance_usd": 5500.00
}
```

**Response** (200): Updated fund box data

---

## Admin Dashboard (Admin Only)

### Get Statistics

Get overall system statistics.

**Endpoint**: `GET /api/v1/admin/dashboard/stats`

**Authentication**: Required (Admin only)

**Response** (200):
```json
{
  "success": true,
  "data": {
    "total_users": 50,
    "total_expenses": 1250,
    "total_transfers": 300,
    "total_incoming": 200,
    "fund_box_balance": "5000.00",
    "total_expenses_usd": "25000.00",
    "total_transfers_usd": "10000.00",
    "total_incoming_usd": "15000.00"
  }
}
```

### Get User Activity

Get user activity list.

**Endpoint**: `GET /api/v1/admin/dashboard/users`

**Authentication**: Required (Admin only)

**Response** (200):
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "expense_count": 25,
      "transfer_count": 10,
      "incoming_count": 5,
      "last_activity": "2025-10-22T10:00:00Z"
    }
  ]
}
```

### Get Expense Summaries

Get expense summaries by currency and user.

**Endpoint**: `GET /api/v1/admin/dashboard/expenses`

**Authentication**: Required (Admin only)

**Query Parameters**:
- `start_date` (date, optional)
- `end_date` (date, optional)

**Response** (200):
```json
{
  "success": true,
  "data": {
    "by_currency": {
      "usd": "25000.00",
      "syp": "62500000.00",
      "try": "5000.00"
    },
    "by_user": [
      {
        "user_id": 1,
        "user_name": "John Doe",
        "total_usd": "5000.00",
        "count": 25
      }
    ]
  }
}
```

### Get Analytics

Get date-range analytics.

**Endpoint**: `GET /api/v1/admin/dashboard/analytics`

**Authentication**: Required (Admin only)

**Query Parameters**:
- `start_date` (date, required)
- `end_date` (date, required)

**Response** (200): Comprehensive analytics data

---

## Audit Logs (Admin Only)

### List Audit Logs

Get paginated audit logs.

**Endpoint**: `GET /api/v1/audit-logs`

**Authentication**: Required (Admin only)

**Query Parameters**:
- `page` (integer, optional)
- `per_page` (integer, optional)
- `user_id` (integer, optional): Filter by user
- `action` (string, optional): Filter by action (create, update, delete, view)
- `resource_type` (string, optional): Filter by resource type
- `start_date` (date, optional)
- `end_date` (date, optional)

**Response** (200):
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": 1,
        "user_id": 1,
        "user_name": "John Doe",
        "action": "create",
        "resource_type": "Expense",
        "resource_id": 1,
        "ip_address": "127.0.0.1",
        "metadata": {},
        "created_at": "2025-10-22T10:00:00Z"
      }
    ],
    "current_page": 1,
    "total": 500
  }
}
```

### Get Audit Log

Get a single audit log by ID.

**Endpoint**: `GET /api/v1/audit-logs/{id}`

**Authentication**: Required (Admin only)

---

## Synchronization

### Batch Sync

Sync multiple records in a batch.

**Endpoint**: `POST /api/v1/sync/batch`

**Authentication**: Required

**Request Body**:
```json
{
  "records": [
    {
      "type": "expense",
      "action": "create",
      "data": {
        "description": "Office supplies",
        "price_usd": 50.00,
        "expense_date": "2025-10-22"
      }
    },
    {
      "type": "transfer",
      "action": "update",
      "id": 1,
      "data": {
        "amount_usd": 150.00
      }
    }
  ]
}
```

**Response** (200):
```json
{
  "success": true,
  "data": {
    "results": [
      {
        "index": 0,
        "success": true,
        "data": { "id": 1 }
      },
      {
        "index": 1,
        "success": true,
        "data": { "id": 1 }
      }
    ],
    "summary": {
      "total": 2,
      "successful": 2,
      "failed": 0
    }
  }
}
```

### Get Changes

Get records modified since a timestamp.

**Endpoint**: `GET /api/v1/sync/changes`

**Authentication**: Required

**Query Parameters**:
- `since` (timestamp, required): ISO 8601 timestamp

**Response** (200):
```json
{
  "success": true,
  "data": {
    "expenses": [...],
    "transfers": [...],
    "incoming": [...],
    "timestamp": "2025-10-22T10:00:00Z"
  }
}
```

### Resolve Conflict

Resolve a sync conflict.

**Endpoint**: `POST /api/v1/sync/resolve`

**Authentication**: Required

**Request Body**:
```json
{
  "type": "expense",
  "id": 1,
  "strategy": "server_wins",
  "client_data": {...},
  "server_data": {...}
}
```

**Response** (200): Resolved data

---

## User Profile

### Get Profile

Get current user profile.

**Endpoint**: `GET /api/v1/profile`

**Authentication**: Required

**Response** (200):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "user",
    "created_at": "2025-10-22T10:00:00Z"
  }
}
```

### Update Profile

Update user profile.

**Endpoint**: `PUT /api/v1/profile`

**Authentication**: Required

**Request Body**:
```json
{
  "name": "John Smith",
  "email": "johnsmith@example.com"
}
```

**Response** (200): Updated profile data

### Change Password

Change user password.

**Endpoint**: `PUT /api/v1/profile/password`

**Authentication**: Required (Recent authentication required)

**Request Body**:
```json
{
  "current_password": "oldpassword",
  "password": "newpassword123",
  "password_confirmation": "newpassword123"
}
```

**Response** (200):
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

### Delete Account

Delete user account.

**Endpoint**: `DELETE /api/v1/profile`

**Authentication**: Required (Recent authentication required)

**Response** (204): No content

---

## Data Export

### List Exports

Get list of user's exports.

**Endpoint**: `GET /api/v1/export`

**Authentication**: Required

**Response** (200):
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "type": "pdf",
      "status": "completed",
      "file_path": "exports/abc123.pdf",
      "created_at": "2025-10-22T10:00:00Z"
    }
  ]
}
```

### Export Expenses to PDF

Generate PDF export of expenses.

**Endpoint**: `POST /api/v1/export/expenses/pdf`

**Authentication**: Required

**Request Body**:
```json
{
  "start_date": "2025-10-01",
  "end_date": "2025-10-31"
}
```

**Response** (202):
```json
{
  "success": true,
  "message": "Export queued successfully",
  "data": {
    "export_id": 1,
    "status": "processing"
  }
}
```

### Export Expenses to Excel

Generate Excel export of expenses.

**Endpoint**: `POST /api/v1/export/expenses/excel`

**Authentication**: Required

**Request Body**: Same as PDF export

**Response** (202): Same as PDF export

### Export System-Wide (Admin Only)

Generate system-wide export.

**Endpoint**: `POST /api/v1/export/system-wide`

**Authentication**: Required (Admin only)

**Request Body**:
```json
{
  "format": "excel",
  "start_date": "2025-10-01",
  "end_date": "2025-10-31"
}
```

**Response** (202): Export queued

### Get Export Status

Check export status.

**Endpoint**: `GET /api/v1/export/{id}/status`

**Authentication**: Required

**Response** (200):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "status": "completed",
    "progress": 100,
    "download_url": "/api/v1/export/1/download"
  }
}
```

### Download Export

Download completed export.

**Endpoint**: `GET /api/v1/export/{id}/download`

**Authentication**: Required

**Response**: Binary file data

---

## File Operations

### Upload File

Upload a generic file.

**Endpoint**: `POST /api/v1/files/upload`

**Authentication**: Required

**Content-Type**: `multipart/form-data`

**Request Body**:
- `file`: File to upload (max 10MB)
- `directory` (optional): Target directory

**Response** (200):
```json
{
  "success": true,
  "message": "File uploaded successfully",
  "data": {
    "path": "files/abc123.jpg",
    "url": "http://localhost:8000/api/v1/files/download?path=..."
  }
}
```

### Download File

Download a file using encrypted path.

**Endpoint**: `GET /api/v1/files/download`

**Query Parameters**:
- `path` (string, required): Encrypted file path

**Response**: Binary file data

### Delete File

Delete a file.

**Endpoint**: `DELETE /api/v1/files`

**Authentication**: Required

**Request Body**:
```json
{
  "path": "files/abc123.jpg"
}
```

**Response** (200):
```json
{
  "success": true,
  "message": "File deleted successfully"
}
```

---

## Response Codes Summary

- `200 OK` - Successful GET, PUT requests
- `201 Created` - Successful POST requests
- `202 Accepted` - Request accepted for processing (async operations)
- `204 No Content` - Successful DELETE requests
- `400 Bad Request` - Invalid request data
- `401 Unauthorized` - Missing or invalid authentication
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `409 Conflict` - Sync conflict detected
- `422 Unprocessable Entity` - Validation errors
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server errors

---

For more information, see the [README.md](README.md) or access the interactive API documentation at `/api/documentation`.

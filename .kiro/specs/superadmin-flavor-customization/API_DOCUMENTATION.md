# SuperAdmin API Documentation

## Overview

This document outlines the API endpoints required by the backend team to support SuperAdmin flavor functionality. All endpoints require authentication and SuperAdmin role verification.

## Table of Contents

1. [Authentication](#authentication)
2. [Registration Endpoints](#registration-endpoints)
3. [Cash Management Endpoints](#cash-management-endpoints)
4. [Expense Monitoring Endpoints](#expense-monitoring-endpoints)
5. [Group Management Endpoints](#group-management-endpoints)
6. [Error Codes](#error-codes)

## Authentication

All SuperAdmin endpoints require:
- Valid JWT token in Authorization header
- User role verification (must be SuperAdmin)

### Headers

```
Authorization: Bearer {jwt_token}
Content-Type: application/json
Accept: application/json
```

### Role Verification

Backend must verify that the authenticated user has `role = 'superadmin'` before processing requests.

## Registration Endpoints

### POST /api/auth/register

Register a new SuperAdmin user and generate a unique group code.

#### Request Body

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "SecurePassword123",
  "password_confirmation": "SecurePassword123",
  "role": "superadmin",
  "admin_group_name": "Acme Corporation"
}
```

#### Response (Success - 201 Created)

```json
{
  "success": true,
  "message": "SuperAdmin registered successfully",
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "superadmin",
      "admin_group_id": 123,
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T10:30:00Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "group_code": "SA-ABC123",
    "admin_group_name": "Acme Corporation"
  }
}
```

#### Response (Error - 422 Unprocessable Entity)

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "email": ["The email has already been taken."],
    "password": ["The password must be at least 8 characters."]
  }
}
```

#### Backend Requirements

1. Generate a unique group code (format: `SA-{6_ALPHANUMERIC}`)
2. Create admin_group record with the group code
3. Associate user with the admin_group
4. Return group code in registration response
5. Ensure group code is unique across all admin groups

## Cash Management Endpoints

### GET /api/superadmin/fund-box

Get SuperAdmin's fund box balance.

#### Request

```
GET /api/superadmin/fund-box
Authorization: Bearer {jwt_token}
```

#### Response (Success - 200 OK)

```json
{
  "success": true,
  "data": {
    "balance": 50000.00,
    "currency": "USD",
    "last_updated": "2024-01-15T14:30:00Z"
  }
}
```

### GET /api/superadmin/transfers

Get list of outgoing transfers created by SuperAdmin.

#### Request Parameters

```
GET /api/superadmin/transfers?page=1&per_page=20&status=all&recipient_id=5&date_from=2024-01-01&date_to=2024-01-31
Authorization: Bearer {jwt_token}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| page | integer | No | Page number (default: 1) |
| per_page | integer | No | Items per page (default: 20, max: 100) |
| status | string | No | Filter by status: all, pending, completed, failed (default: all) |
| recipient_id | integer | No | Filter by recipient user ID |
| date_from | date | No | Filter from date (YYYY-MM-DD) |
| date_to | date | No | Filter to date (YYYY-MM-DD) |

#### Response (Success - 200 OK)

```json
{
  "success": true,
  "data": {
    "transfers": [
      {
        "id": 101,
        "sender_id": 1,
        "recipient_id": 5,
        "recipient_name": "Admin User",
        "recipient_email": "admin@example.com",
        "amount": 5000.00,
        "currency": "USD",
        "description": "Monthly allocation",
        "status": "completed",
        "created_at": "2024-01-15T10:00:00Z",
        "completed_at": "2024-01-15T10:05:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 20,
      "total": 45,
      "last_page": 3
    }
  }
}
```

### POST /api/superadmin/transfers

Create a new outgoing transfer to an admin user.

#### Request Body

```json
{
  "recipient_id": 5,
  "amount": 5000.00,
  "description": "Monthly allocation"
}
```

#### Response (Success - 201 Created)

```json
{
  "success": true,
  "message": "Transfer created successfully",
  "data": {
    "transfer": {
      "id": 102,
      "sender_id": 1,
      "recipient_id": 5,
      "recipient_name": "Admin User",
      "amount": 5000.00,
      "currency": "USD",
      "description": "Monthly allocation",
      "status": "pending",
      "created_at": "2024-01-15T15:00:00Z"
    }
  }
}
```

#### Response (Error - 400 Bad Request)

```json
{
  "success": false,
  "message": "Insufficient fund box balance",
  "error_code": "INSUFFICIENT_BALANCE"
}
```

#### Backend Requirements

1. Verify SuperAdmin has sufficient fund box balance
2. Verify recipient is an admin user in SuperAdmin's group
3. Deduct amount from SuperAdmin's fund box
4. Create transfer record with status "pending"
5. Process transfer asynchronously
6. Update status to "completed" or "failed"

### GET /api/superadmin/admins

Get list of admin users in SuperAdmin's group (for recipient selection).

#### Request

```
GET /api/superadmin/admins
Authorization: Bearer {jwt_token}
```

#### Response (Success - 200 OK)

```json
{
  "success": true,
  "data": {
    "admins": [
      {
        "id": 5,
        "name": "Admin User 1",
        "email": "admin1@example.com",
        "joined_at": "2024-01-10T09:00:00Z"
      },
      {
        "id": 6,
        "name": "Admin User 2",
        "email": "admin2@example.com",
        "joined_at": "2024-01-12T11:30:00Z"
      }
    ]
  }
}
```

## Expense Monitoring Endpoints

### GET /api/superadmin/expenses/summary

Get aggregated expense summaries for all admin groups under SuperAdmin supervision.

#### Request Parameters

```
GET /api/superadmin/expenses/summary?admin_group_id=123
Authorization: Bearer {jwt_token}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| admin_group_id | integer | No | Filter by specific admin group |

#### Response (Success - 200 OK)

```json
{
  "success": true,
  "data": {
    "summaries": [
      {
        "admin_group_id": 123,
        "admin_group_name": "Sales Department",
        "total_amount": 15000.00,
        "expense_count": 45,
        "pending_count": 5,
        "approved_count": 38,
        "rejected_count": 2,
        "currency": "USD",
        "last_expense_date": "2024-01-15T14:00:00Z"
      },
      {
        "admin_group_id": 124,
        "admin_group_name": "Marketing Department",
        "total_amount": 22000.00,
        "expense_count": 67,
        "pending_count": 8,
        "approved_count": 55,
        "rejected_count": 4,
        "currency": "USD",
        "last_expense_date": "2024-01-15T16:30:00Z"
      }
    ],
    "grand_total": 37000.00,
    "total_expense_count": 112
  }
}
```

#### Backend Requirements

1. Query all admin groups under the SuperAdmin
2. Aggregate expense data for each admin group
3. Calculate totals, counts, and status breakdowns
4. Return summaries sorted by admin group name

### GET /api/superadmin/expenses/by-group/{admin_group_id}

Get detailed expenses for a specific admin group.

#### Request Parameters

```
GET /api/superadmin/expenses/by-group/123?page=1&per_page=50&status=all&date_from=2024-01-01&date_to=2024-01-31
Authorization: Bearer {jwt_token}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| page | integer | No | Page number (default: 1) |
| per_page | integer | No | Items per page (default: 50, max: 100) |
| status | string | No | Filter by status: all, pending, approved, rejected (default: all) |
| date_from | date | No | Filter from date (YYYY-MM-DD) |
| date_to | date | No | Filter to date (YYYY-MM-DD) |

#### Response (Success - 200 OK)

```json
{
  "success": true,
  "data": {
    "admin_group": {
      "id": 123,
      "name": "Sales Department"
    },
    "expenses": [
      {
        "id": 501,
        "description": "Office supplies",
        "amount": 250.00,
        "currency": "USD",
        "category": "Supplies",
        "status": "approved",
        "created_by": {
          "id": 10,
          "name": "Admin User",
          "email": "admin@example.com"
        },
        "created_at": "2024-01-15T10:00:00Z",
        "approved_at": "2024-01-15T11:00:00Z",
        "photo_url": "https://example.com/photos/expense_501.jpg"
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 50,
      "total": 45,
      "last_page": 1
    }
  }
}
```

#### Response (Error - 403 Forbidden)

```json
{
  "success": false,
  "message": "You do not have permission to view this admin group's expenses",
  "error_code": "FORBIDDEN"
}
```

#### Backend Requirements

1. Verify the admin group belongs to the SuperAdmin
2. Query expenses for the specified admin group
3. Apply filters (status, date range)
4. Return paginated results
5. Include creator information for each expense

## Group Management Endpoints

### GET /api/superadmin/group

Get SuperAdmin's admin group information including group code.

#### Request

```
GET /api/superadmin/group
Authorization: Bearer {jwt_token}
```

#### Response (Success - 200 OK)

```json
{
  "success": true,
  "data": {
    "admin_group": {
      "id": 123,
      "name": "Acme Corporation",
      "group_code": "SA-ABC123",
      "created_at": "2024-01-15T10:30:00Z",
      "member_count": 15
    }
  }
}
```

### GET /api/superadmin/group/members

Get list of admin members in SuperAdmin's group.

#### Request

```
GET /api/superadmin/group/members?page=1&per_page=20
Authorization: Bearer {jwt_token}
```

#### Response (Success - 200 OK)

```json
{
  "success": true,
  "data": {
    "members": [
      {
        "id": 5,
        "name": "Admin User 1",
        "email": "admin1@example.com",
        "role": "admin",
        "joined_at": "2024-01-10T09:00:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 20,
      "total": 15,
      "last_page": 1
    }
  }
}
```

### POST /api/superadmin/group/regenerate-code

Regenerate the group code for SuperAdmin's admin group.

#### Request

```
POST /api/superadmin/group/regenerate-code
Authorization: Bearer {jwt_token}
```

#### Response (Success - 200 OK)

```json
{
  "success": true,
  "message": "Group code regenerated successfully",
  "data": {
    "group_code": "SA-XYZ789"
  }
}
```

#### Backend Requirements

1. Generate a new unique group code
2. Update admin_group record
3. Invalidate old group code
4. Return new group code

### DELETE /api/superadmin/group/members/{member_id}

Remove an admin member from SuperAdmin's group.

#### Request

```
DELETE /api/superadmin/group/members/5
Authorization: Bearer {jwt_token}
```

#### Response (Success - 200 OK)

```json
{
  "success": true,
  "message": "Member removed successfully"
}
```

#### Response (Error - 404 Not Found)

```json
{
  "success": false,
  "message": "Member not found in your group",
  "error_code": "MEMBER_NOT_FOUND"
}
```

#### Backend Requirements

1. Verify member belongs to SuperAdmin's group
2. Remove member from admin_group
3. Handle data cleanup (optional: archive member's data)
4. Prevent removal of the SuperAdmin themselves

## Error Codes

### Authentication Errors

| Code | HTTP Status | Description |
|------|-------------|-------------|
| UNAUTHORIZED | 401 | Missing or invalid authentication token |
| FORBIDDEN | 403 | User does not have SuperAdmin role |
| TOKEN_EXPIRED | 401 | JWT token has expired |

### Validation Errors

| Code | HTTP Status | Description |
|------|-------------|-------------|
| VALIDATION_ERROR | 422 | Request validation failed |
| INVALID_AMOUNT | 400 | Transfer amount is invalid or negative |
| INVALID_RECIPIENT | 400 | Recipient is not a valid admin in the group |

### Business Logic Errors

| Code | HTTP Status | Description |
|------|-------------|-------------|
| INSUFFICIENT_BALANCE | 400 | SuperAdmin fund box has insufficient balance |
| MEMBER_NOT_FOUND | 404 | Admin member not found in group |
| GROUP_NOT_FOUND | 404 | Admin group not found |
| DUPLICATE_GROUP_CODE | 409 | Generated group code already exists (retry) |

### Server Errors

| Code | HTTP Status | Description |
|------|-------------|-------------|
| INTERNAL_ERROR | 500 | Internal server error |
| DATABASE_ERROR | 500 | Database operation failed |

## Rate Limiting

All endpoints are subject to rate limiting:

- **Standard Endpoints**: 60 requests per minute per user
- **Transfer Creation**: 10 requests per minute per user
- **Group Code Regeneration**: 5 requests per hour per user

Rate limit headers are included in responses:

```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1642252800
```

## Pagination

All list endpoints support pagination with the following parameters:

- `page`: Page number (default: 1)
- `per_page`: Items per page (default: 20, max: 100)

Pagination metadata is included in responses:

```json
{
  "pagination": {
    "current_page": 1,
    "per_page": 20,
    "total": 100,
    "last_page": 5,
    "from": 1,
    "to": 20
  }
}
```

## Data Scoping

All SuperAdmin endpoints automatically scope data to the authenticated SuperAdmin:

- **Transfers**: Only outgoing transfers created by the SuperAdmin
- **Expenses**: Only expenses from admin groups under SuperAdmin supervision
- **Group Members**: Only admins in SuperAdmin's group
- **Fund Box**: Only SuperAdmin's own fund box

Backend must enforce these scoping rules at the database query level.

## Security Considerations

### Authorization

1. Verify JWT token on every request
2. Verify user role is "superadmin"
3. Verify data belongs to the authenticated SuperAdmin
4. Prevent cross-group data access

### Input Validation

1. Validate all input parameters
2. Sanitize user input to prevent SQL injection
3. Validate amount values (positive, reasonable limits)
4. Validate date ranges

### Group Code Security

1. Generate cryptographically secure random codes
2. Ensure uniqueness across all admin groups
3. Store codes securely (consider hashing)
4. Implement rate limiting on code regeneration

## Testing Endpoints

For testing purposes, consider implementing:

- Seed data endpoints (development only)
- Mock transfer processing (skip async processing)
- Test group code generation (predictable codes)

## Changelog

### Version 1.0.0 (2024-01-15)

- Initial API specification for SuperAdmin flavor
- Registration with group code generation
- Cash management endpoints
- Expense monitoring endpoints
- Group management endpoints

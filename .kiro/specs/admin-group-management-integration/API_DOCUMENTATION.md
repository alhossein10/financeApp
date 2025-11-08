# Admin Group Management - API Documentation

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Endpoints](#endpoints)
4. [Data Models](#data-models)
5. [Error Codes](#error-codes)
6. [Examples](#examples)

---

## Overview

This document describes the API endpoints for the Admin Group Management feature. All endpoints require authentication unless otherwise specified.

### Base URL

```
Production: https://api.financeapp.com/api/v1
Staging: https://staging-api.financeapp.com/api/v1
Development: http://localhost:8000/api/v1
```

### API Version

Current Version: `v1`

### Content Type

All requests and responses use `application/json` content type.

---

## Authentication

### Bearer Token

All authenticated endpoints require a Bearer token in the Authorization header:

```http
Authorization: Bearer {access_token}
```

### Getting a Token

```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": { ... },
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "token_type": "Bearer"
  }
}
```

---

## Endpoints

### 1. Get Admin Group

Retrieve the authenticated admin's group information.

**Endpoint:** `GET /admin/group`

**Authorization:** Required (Admin role)

**Request Headers:**
```http
Authorization: Bearer {access_token}
Accept: application/json
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "admin_user_id": 5,
    "group_code": "ABC123",
    "group_name": "Marketing Team",
    "is_active": true,
    "members_count": 12,
    "created_at": "2025-11-01T10:00:00.000000Z",
    "updated_at": "2025-11-01T10:00:00.000000Z"
  }
}
```

**Error Responses:**

- `401 Unauthorized`: Not authenticated
- `403 Forbidden`: User is not an admin
- `404 Not Found`: Admin group not found

---

### 2. Regenerate Group Code

Generate a new group code for the admin's group. The old code becomes invalid immediately.

**Endpoint:** `POST /admin/group/regenerate`

**Authorization:** Required (Admin role)

**Request Headers:**
```http
Authorization: Bearer {access_token}
Accept: application/json
Content-Type: application/json
```

**Request Body:** None

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Group code regenerated successfully",
  "data": {
    "id": 1,
    "admin_user_id": 5,
    "group_code": "XYZ789",
    "group_name": "Marketing Team",
    "is_active": true,
    "members_count": 12,
    "created_at": "2025-11-01T10:00:00.000000Z",
    "updated_at": "2025-11-01T11:30:00.000000Z"
  }
}
```

**Error Responses:**

- `401 Unauthorized`: Not authenticated
- `403 Forbidden`: User is not an admin
- `404 Not Found`: Admin group not found

---

### 3. Get Group Members

Retrieve a paginated list of members in the admin's group.

**Endpoint:** `GET /admin/group/members`

**Authorization:** Required (Admin role)

**Request Headers:**
```http
Authorization: Bearer {access_token}
Accept: application/json
```

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| page | integer | No | 1 | Page number |
| per_page | integer | No | 15 | Items per page (max 100) |
| search | string | No | - | Search by name or email |
| department | string | No | - | Filter by department name |

**Example Request:**
```http
GET /admin/group/members?page=1&per_page=15&search=john&department=Marketing
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": 10,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user",
      "organization_name": "Acme Corp",
      "department_name": "Marketing",
      "created_at": "2025-11-01T10:00:00.000000Z"
    },
    {
      "id": 11,
      "name": "John Smith",
      "email": "jsmith@example.com",
      "role": "user",
      "organization_name": "Acme Corp",
      "department_name": "Marketing",
      "created_at": "2025-11-01T10:15:00.000000Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "from": 1,
    "last_page": 1,
    "per_page": 15,
    "to": 2,
    "total": 2
  }
}
```

**Error Responses:**

- `401 Unauthorized`: Not authenticated
- `403 Forbidden`: User is not an admin
- `404 Not Found`: Admin group not found
- `422 Unprocessable Entity`: Invalid query parameters

---

### 4. Remove Group Member

Remove a user from the admin's group.

**Endpoint:** `DELETE /admin/group/members/{userId}`

**Authorization:** Required (Admin role)

**Request Headers:**
```http
Authorization: Bearer {access_token}
Accept: application/json
```

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| userId | integer | Yes | ID of the user to remove |

**Example Request:**
```http
DELETE /admin/group/members/10
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "User removed from group successfully"
}
```

**Error Responses:**

- `401 Unauthorized`: Not authenticated
- `403 Forbidden`: User is not an admin or trying to remove self
- `404 Not Found`: User not found or not in group
- `422 Unprocessable Entity`: Cannot remove self

**Error Example (Cannot Remove Self):**
```json
{
  "success": false,
  "message": "You cannot remove yourself from the group"
}
```

---

### 5. Join Group

Join an admin's group using a group code.

**Endpoint:** `POST /user/join-group`

**Authorization:** Required (User role)

**Request Headers:**
```http
Authorization: Bearer {access_token}
Accept: application/json
Content-Type: application/json
```

**Request Body:**
```json
{
  "group_code": "ABC123"
}
```

**Request Body Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| group_code | string | Yes | 6-character group code |

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Successfully joined the group",
  "data": {
    "group_code": "ABC123",
    "group_name": "Marketing Team",
    "admin_name": "Admin User",
    "admin_email": "admin@example.com",
    "members_count": 13,
    "joined_at": "2025-11-01T12:00:00.000000Z"
  }
}
```

**Error Responses:**

- `401 Unauthorized`: Not authenticated
- `403 Forbidden`: User is an admin (admins cannot join groups)
- `422 Unprocessable Entity`: Validation errors

**Error Examples:**

**Invalid Group Code:**
```json
{
  "success": false,
  "message": "The selected group code is invalid.",
  "errors": {
    "group_code": ["The selected group code is invalid."]
  }
}
```

**Already in Group:**
```json
{
  "success": false,
  "message": "You are already in a group"
}
```

**Admin Cannot Join:**
```json
{
  "success": false,
  "message": "Admins cannot join other groups"
}
```

**Group Code Required:**
```json
{
  "success": false,
  "message": "The group code field is required.",
  "errors": {
    "group_code": ["The group code field is required."]
  }
}
```

---

### 6. Get User Group Info

Retrieve the authenticated user's group information.

**Endpoint:** `GET /user/group-info`

**Authorization:** Required (User role)

**Request Headers:**
```http
Authorization: Bearer {access_token}
Accept: application/json
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "group_code": "ABC123",
    "group_name": "Marketing Team",
    "admin_name": "Admin User",
    "admin_email": "admin@example.com",
    "members_count": 12,
    "joined_at": "2025-11-01T10:00:00.000000Z"
  }
}
```

**Error Responses:**

- `401 Unauthorized`: Not authenticated
- `403 Forbidden`: User is an admin
- `404 Not Found`: User is not in any group

**Error Example (Not in Group):**
```json
{
  "success": false,
  "message": "You are not in any group"
}
```

---

### 7. Register (Updated)

Register a new user with group code support.

**Endpoint:** `POST /auth/register`

**Authorization:** Not required

**Request Headers:**
```http
Accept: application/json
Content-Type: application/json
```

**Request Body (Admin):**
```json
{
  "name": "Admin User",
  "email": "admin@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "role": "admin",
  "organization_name": "Acme Corp",
  "department_name": "Management"
}
```

**Request Body (User):**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "role": "user",
  "group_code": "ABC123",
  "organization_name": "Acme Corp",
  "department_name": "Marketing"
}
```

**Request Body Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| name | string | Yes | User's full name |
| email | string | Yes | Valid email address |
| password | string | Yes | Min 8 characters |
| password_confirmation | string | Yes | Must match password |
| role | string | Yes | "admin" or "user" |
| group_code | string | Conditional | Required for users, not for admins |
| organization_name | string | No | Organization name (free text) |
| department_name | string | No | Department name (free text) |

**Response (201 Created) - Admin:**
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "user": {
      "id": 5,
      "name": "Admin User",
      "email": "admin@example.com",
      "role": "admin",
      "organization_name": "Acme Corp",
      "department_name": "Management",
      "admin_group_id": 1,
      "created_at": "2025-11-01T10:00:00.000000Z"
    },
    "admin_group": {
      "id": 1,
      "admin_user_id": 5,
      "group_code": "ABC123",
      "group_name": "Admin User's Group",
      "is_active": true,
      "members_count": 1,
      "created_at": "2025-11-01T10:00:00.000000Z"
    },
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "token_type": "Bearer"
  }
}
```

**Response (201 Created) - User:**
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "user": {
      "id": 10,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user",
      "organization_name": "Acme Corp",
      "department_name": "Marketing",
      "admin_group_id": 1,
      "created_at": "2025-11-01T10:15:00.000000Z"
    },
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "token_type": "Bearer"
  }
}
```

**Error Responses:**

- `422 Unprocessable Entity`: Validation errors

**Error Examples:**

```json
{
  "success": false,
  "message": "The email has already been taken.",
  "errors": {
    "email": ["The email has already been taken."]
  }
}
```

```json
{
  "success": false,
  "message": "The group code field is required.",
  "errors": {
    "group_code": ["The group code field is required."]
  }
}
```

---

## Data Models

### AdminGroup

```typescript
interface AdminGroup {
  id: number;
  admin_user_id: number;
  group_code: string;          // 6 characters, alphanumeric
  group_name: string | null;
  is_active: boolean;
  members_count: number | null;
  created_at: string;          // ISO 8601 format
  updated_at: string;          // ISO 8601 format
}
```

### GroupMember

```typescript
interface GroupMember {
  id: number;
  name: string;
  email: string;
  role: 'user' | 'admin';
  organization_name: string | null;
  department_name: string | null;
  created_at: string;          // ISO 8601 format
}
```

### GroupInfo

```typescript
interface GroupInfo {
  group_code: string;          // 6 characters, alphanumeric
  group_name: string | null;
  admin_name: string;
  admin_email: string;
  members_count: number;
  joined_at: string;           // ISO 8601 format
}
```

### User (Updated)

```typescript
interface User {
  id: number;
  name: string;
  email: string;
  role: 'user' | 'admin';
  organization_name: string | null;    // NEW
  department_name: string | null;      // NEW
  admin_group_id: number | null;       // NEW
  organization_id: number | null;      // DEPRECATED
  department_id: number | null;        // DEPRECATED
  created_at: string;
  updated_at: string;
}
```

---

## Error Codes

### HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request successful |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Invalid request format |
| 401 | Unauthorized | Authentication required |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 422 | Unprocessable Entity | Validation errors |
| 500 | Internal Server Error | Server error |

### Application Error Codes

| Code | Message | Description |
|------|---------|-------------|
| GROUP_CODE_INVALID | The selected group code is invalid | Group code doesn't exist or is inactive |
| GROUP_CODE_REQUIRED | The group code field is required | Missing group code for user registration |
| ALREADY_IN_GROUP | You are already in a group | User is already a member of a group |
| ADMIN_CANNOT_JOIN | Admins cannot join other groups | Admin role cannot join groups |
| MEMBER_NOT_FOUND | User not found or not in your group | User doesn't exist or not in admin's group |
| CANNOT_REMOVE_SELF | You cannot remove yourself from the group | Admin trying to remove themselves |
| NOT_IN_GROUP | You are not in any group | User has no group membership |
| GROUP_NOT_FOUND | Admin group not found | Admin doesn't have a group |

---

## Examples

### Example 1: Complete Admin Registration Flow

```javascript
// 1. Register as admin
const registerResponse = await fetch('https://api.financeapp.com/api/v1/auth/register', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  },
  body: JSON.stringify({
    name: 'Admin User',
    email: 'admin@example.com',
    password: 'password123',
    password_confirmation: 'password123',
    role: 'admin',
    organization_name: 'Acme Corp',
    department_name: 'Management'
  })
});

const registerData = await registerResponse.json();
console.log('Group Code:', registerData.data.admin_group.group_code);
// Output: ABC123

const token = registerData.data.access_token;

// 2. Get group information
const groupResponse = await fetch('https://api.financeapp.com/api/v1/admin/group', {
  headers: {
    'Authorization': `Bearer ${token}`,
    'Accept': 'application/json'
  }
});

const groupData = await groupResponse.json();
console.log('Members:', groupData.data.members_count);
```

### Example 2: Complete User Registration Flow

```javascript
// 1. Register as user with group code
const registerResponse = await fetch('https://api.financeapp.com/api/v1/auth/register', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  },
  body: JSON.stringify({
    name: 'John Doe',
    email: 'john@example.com',
    password: 'password123',
    password_confirmation: 'password123',
    role: 'user',
    group_code: 'ABC123',
    organization_name: 'Acme Corp',
    department_name: 'Marketing'
  })
});

const registerData = await registerResponse.json();
const token = registerData.data.access_token;

// 2. Get group information
const groupInfoResponse = await fetch('https://api.financeapp.com/api/v1/user/group-info', {
  headers: {
    'Authorization': `Bearer ${token}`,
    'Accept': 'application/json'
  }
});

const groupInfo = await groupInfoResponse.json();
console.log('Admin:', groupInfo.data.admin_name);
console.log('Members:', groupInfo.data.members_count);
```

### Example 3: Managing Group Members

```javascript
const token = 'your_admin_token';

// 1. Get all members
const membersResponse = await fetch('https://api.financeapp.com/api/v1/admin/group/members?page=1&per_page=15', {
  headers: {
    'Authorization': `Bearer ${token}`,
    'Accept': 'application/json'
  }
});

const membersData = await membersResponse.json();
console.log('Total Members:', membersData.meta.total);

// 2. Search members
const searchResponse = await fetch('https://api.financeapp.com/api/v1/admin/group/members?search=john', {
  headers: {
    'Authorization': `Bearer ${token}`,
    'Accept': 'application/json'
  }
});

const searchData = await searchResponse.json();
console.log('Found:', searchData.data.length);

// 3. Remove a member
const userId = 10;
const removeResponse = await fetch(`https://api.financeapp.com/api/v1/admin/group/members/${userId}`, {
  method: 'DELETE',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Accept': 'application/json'
  }
});

const removeData = await removeResponse.json();
console.log(removeData.message);
```

### Example 4: Regenerating Group Code

```javascript
const token = 'your_admin_token';

// Regenerate code
const regenerateResponse = await fetch('https://api.financeapp.com/api/v1/admin/group/regenerate', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Accept': 'application/json',
    'Content-Type': 'application/json'
  }
});

const regenerateData = await regenerateResponse.json();
console.log('New Code:', regenerateData.data.group_code);
// Output: XYZ789
```

### Example 5: Joining Group After Registration

```javascript
const token = 'your_user_token';

// Join group
const joinResponse = await fetch('https://api.financeapp.com/api/v1/user/join-group', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Accept': 'application/json',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    group_code: 'ABC123'
  })
});

const joinData = await joinResponse.json();
console.log('Joined:', joinData.data.group_name);
console.log('Admin:', joinData.data.admin_name);
```

### Example 6: Error Handling

```javascript
try {
  const response = await fetch('https://api.financeapp.com/api/v1/user/join-group', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      group_code: 'INVALID'
    })
  });

  const data = await response.json();

  if (!data.success) {
    // Handle validation errors
    if (data.errors) {
      Object.keys(data.errors).forEach(field => {
        console.error(`${field}: ${data.errors[field].join(', ')}`);
      });
    } else {
      console.error(data.message);
    }
  }
} catch (error) {
  console.error('Network error:', error);
}
```

---

## Rate Limiting

### Limits

- **General Endpoints**: 60 requests per minute
- **Authentication Endpoints**: 10 requests per minute
- **Group Management**: 30 requests per minute

### Headers

Rate limit information is included in response headers:

```http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 59
X-RateLimit-Reset: 1635768000
```

### Exceeded Limit

```json
{
  "success": false,
  "message": "Too many requests. Please try again later."
}
```

---

## Pagination

### Request Parameters

| Parameter | Type | Default | Max | Description |
|-----------|------|---------|-----|-------------|
| page | integer | 1 | - | Page number |
| per_page | integer | 15 | 100 | Items per page |

### Response Meta

```json
{
  "meta": {
    "current_page": 1,
    "from": 1,
    "last_page": 3,
    "per_page": 15,
    "to": 15,
    "total": 42
  }
}
```

---

## Versioning

### Current Version

API Version: `v1`

### Version in URL

```
https://api.financeapp.com/api/v1/...
```

### Deprecation Policy

- Deprecated endpoints supported for 6 months
- Deprecation notices in response headers
- Migration guides provided

---

## Support

### API Issues

- Email: api-support@financeapp.com
- Documentation: https://docs.financeapp.com
- Status Page: https://status.financeapp.com

### Postman Collection

Import the Postman collection for easy testing:
- File: `Finance-API-Complete-v2.postman_collection.json`
- Location: Project root directory

---

**API Version**: 1.0.0  
**Last Updated**: November 1, 2025  
**Changelog**: See RELEASE_NOTES.md


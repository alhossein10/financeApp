# API Documentation - Postman API v3.1 Complete Integration

## Overview

This document provides comprehensive documentation for all API datasources, DTOs, and field mappings implemented in the Flutter application. The implementation ensures complete feature parity with the Postman API v3.1 collection, including Bearer token authentication, multi-currency support, SuperAdmin features, and all 12 endpoint categories.

## Table of Contents

1. [Authentication & Bearer Token](#authentication--bearer-token)
2. [Public Endpoints](#public-endpoints)
3. [SuperAdmin Features](#superadmin-features)
4. [Multi-Currency Support](#multi-currency-support)
5. [Balance-Based Exchanges](#balance-based-exchanges)
6. [Transfer Management](#transfer-management)
7. [Admin Group Management](#admin-group-management)
8. [Expense Management](#expense-management)
9. [Fund Box Operations](#fund-box-operations)
10. [Data Export & Sync](#data-export--sync)
11. [Audit Logs](#audit-logs)
12. [Profile Management](#profile-management)
13. [Error Handling](#error-handling)

---

## Authentication & Bearer Token

### BearerTokenInterceptor

**Location:** `lib/core/api/bearer_token_interceptor.dart`

**Purpose:** Automatically adds Bearer token authentication to all protected API endpoints and handles token refresh on 401 errors.

#### Features

- **Automatic Token Injection**: Adds `Authorization: Bearer {token}` header to all protected endpoints
- **Public Endpoint Detection**: Skips token injection for public endpoints (organizations, auth/register, auth/login)
- **Token Refresh**: Automatically refreshes expired tokens on 401 errors
- **Request Queueing**: Queues concurrent requests during token refresh to prevent race conditions
- **Logout on Failure**: Clears tokens and redirects to login when refresh fails

#### Public Endpoints (No Bearer Token Required)

```dart
final publicEndpoints = [
  '/organizations',
  '/organizations/{id}/departments',
  '/auth/register',
  '/auth/login',
  '/auth/forgot-password',
  '/auth/reset-password',
];
```

#### Protected Endpoints (Bearer Token Required)

All other endpoints require Bearer token authentication, including:
- `/auth/me` - Get current user
- `/auth/refresh` - Refresh token
- `/auth/logout` - Logout
- All SuperAdmin endpoints (`/super-admin/*`, `/superadmin/*`)
- All Admin endpoints (`/admin/*`)
- All User endpoints (`/user/*`)
- All resource endpoints (expenses, transfers, incoming, fund-box, exchanges)

#### Token Refresh Flow

```
1. Request fails with 401 Unauthorized
2. Interceptor detects 401 and checks if refresh is needed
3. Calls POST /auth/refresh with current Bearer token
4. Receives new token and saves it
5. Retries original request with new token
6. Processes any queued requests with new token
7. If refresh fails, clears tokens and triggers logout
```

#### Usage Example

```dart
// Token is automatically added by interceptor
final response = await apiClient.get('/expenses');
// Authorization: Bearer {token} is added automatically

// Public endpoints don't get token
final orgs = await apiClient.get('/organizations');
// No Authorization header added
```

---

## Public Endpoints

### Organizations API

**Location:** `lib/features/organizations/data/datasources/organizations_api_datasource.dart`

#### Get All Organizations

**Endpoint:** `GET /api/v1/organizations`

**Authentication:** None (Public endpoint)

**Response:**

```json
{
  "data": [
    {
      "id": 1,
      "name": "Organization Name",
      "created_at": "2024-01-01T00:00:00.000000Z",
      "updated_at": "2024-01-01T00:00:00.000000Z"
    }
  ]
}
```

**DTO:** `OrganizationDto`

```dart
class OrganizationDto {
  final int id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

#### Get Departments

**Endpoint:** `GET /api/v1/organizations/{id}/departments`

**Authentication:** None (Public endpoint)

**Response:**

```json
{
  "data": [
    {
      "id": 1,
      "organization_id": 1,
      "name": "Department Name",
      "created_at": "2024-01-01T00:00:00.000000Z",
      "updated_at": "2024-01-01T00:00:00.000000Z"
    }
  ]
}
```

**DTO:** `DepartmentDto`

```dart
class DepartmentDto {
  final int id;
  final int organizationId;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

---

## SuperAdmin Features

### SuperAdmin Analytics

**Location:** `lib/features/superadmin/data/datasources/superadmin_analytics_api_datasource.dart`

#### Get Analytics

**Endpoint:** `GET /api/v1/super-admin/analytics`

**Authentication:** Bearer token (SuperAdmin only)

**Query Parameters:**
- `period` (required): `'15days'`, `'month'`, or `'all'`

**Response:**

```json
{
  "data": {
    "admin_groups": [
      {
        "admin_group_id": 1,
        "admin_group_name": "Group Name",
        "transfer_count": 10,
        "transfer_total_usd": 1000.00,
        "expense_count": 50,
        "expense_total_usd": 500.00,
        "expense_total_syp": 250000.00,
        "expense_total_try": 5000.00
      }
    ]
  }
}
```

**DTO:** `SuperAdminAnalyticsDto`

```dart
class SuperAdminAnalyticsDto {
  final List<AdminGroupAnalyticsDto> adminGroups;
}

class AdminGroupAnalyticsDto {
  final int adminGroupId;
  final String adminGroupName;
  final int transferCount;
  final double transferTotalUsd;
  final int expenseCount;
  final double expenseTotalUsd;
  final double expenseTotalSyp;
  final double expenseTotalTry;
}
```

### SuperAdmin Group Management

**Location:** `lib/features/superadmin/data/datasources/superadmin_group_api_datasource.dart`

#### Get Group Info

**Endpoint:** `GET /api/v1/superadmin/group`

**Authentication:** Bearer token (SuperAdmin only)

**Response:**

```json
{
  "data": {
    "id": 1,
    "name": "SuperAdmin Group",
    "group_code": "ABC123",
    "member_count": 5,
    "created_at": "2024-01-01T00:00:00.000000Z"
  }
}
```

**DTO:** `SuperAdminGroupDto`

```dart
class SuperAdminGroupDto {
  final int id;
  final String name;
  final String groupCode;
  final int memberCount;
  final DateTime createdAt;
}
```

#### Get Members (Paginated)

**Endpoint:** `GET /api/v1/superadmin/group/members`

**Authentication:** Bearer token (SuperAdmin only)

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `per_page` (optional): Items per page (default: 15)

**Response:**

```json
{
  "data": [
    {
      "id": 1,
      "name": "Admin Name",
      "email": "admin@example.com",
      "admin_group_id": 1,
      "admin_group_name": "Admin Group",
      "joined_at": "2024-01-01T00:00:00.000000Z"
    }
  ],
  "current_page": 1,
  "last_page": 1,
  "per_page": 15,
  "total": 5
}
```

**DTO:** `AdminMemberDto`

```dart
class AdminMemberDto {
  final int id;
  final String name;
  final String email;
  final int? adminGroupId;
  final String? adminGroupName;
  final DateTime? joinedAt;
}
```

#### Regenerate Group Code

**Endpoint:** `POST /api/v1/superadmin/group/regenerate-code`

**Authentication:** Bearer token (SuperAdmin only)

**Response:** Same as Get Group Info

#### Remove Member

**Endpoint:** `DELETE /api/v1/superadmin/group/members/{id}`

**Authentication:** Bearer token (SuperAdmin only)

**Response:** 204 No Content

---

## Multi-Currency Support

### Fund Box (Multi-Currency)

**Location:** `lib/features/fund_box/data/datasources/fund_box_api_datasource.dart`

#### Get Fund Box (All Currencies)

**Endpoint:** `GET /api/v1/fund-box`

**Authentication:** Bearer token

**Response:**

```json
{
  "data": {
    "id": 1,
    "balance_usd": 1000.00,
    "balance_syp": 500000.00,
    "balance_try": 10000.00,
    "last_calculated_at": "2024-01-01T00:00:00.000000Z",
    "updated_at": "2024-01-01T00:00:00.000000Z"
  }
}
```

**DTO:** `FundBoxDto`

```dart
class FundBoxDto {
  final int id;
  final double? balanceUsd;
  final double? balanceSyp;
  final double? balanceTry;
  final String? currency;      // For single currency queries
  final double? balance;        // For single currency queries
  final DateTime? lastCalculatedAt;
  final DateTime lastUpdated;
}
```

#### Get Fund Box (Single Currency)

**Endpoint:** `GET /api/v1/fund-box?currency={currency}`

**Authentication:** Bearer token

**Query Parameters:**
- `currency`: `'USD'`, `'SYP'`, or `'TRY'`

**Response:**

```json
{
  "data": {
    "id": 1,
    "currency": "USD",
    "balance": 1000.00,
    "last_calculated_at": "2024-01-01T00:00:00.000000Z",
    "updated_at": "2024-01-01T00:00:00.000000Z"
  }
}
```

#### Get User Fund Box (Admin/SuperAdmin)

**Endpoint:** `GET /api/v1/fund-box?user_id={userId}&currency={currency}`

**Authentication:** Bearer token (Admin/SuperAdmin only)

**Query Parameters:**
- `user_id` (required): User ID
- `currency` (optional): `'USD'`, `'SYP'`, or `'TRY'`

### Expenses (Multi-Currency)

**Location:** `lib/features/expenses/data/datasources/expense_api_datasource.dart`

#### Create Expense

**Endpoint:** `POST /api/v1/expenses`

**Authentication:** Bearer token

**Request Body:**

```json
{
  "description": "Expense description",
  "price_usd": 100.00,
  "price_syp": 50000.00,
  "price_try": 1000.00,
  "expense_date": "2024-01-01"
}
```

**Note:** At least one price field (price_usd, price_syp, or price_try) must be provided.

**Response:**

```json
{
  "data": {
    "id": 1,
    "user_id": 1,
    "description": "Expense description",
    "price_usd": 100.00,
    "price_syp": 50000.00,
    "price_try": 1000.00,
    "has_invoice": false,
    "invoice_path": null,
    "expense_date": "2024-01-01",
    "created_at": "2024-01-01T00:00:00.000000Z",
    "updated_at": "2024-01-01T00:00:00.000000Z"
  }
}
```

**DTO:** `ExpenseDto`

```dart
class ExpenseDto {
  final int? id;
  final int? userId;
  final String? description;
  final double? priceUsd;
  final double? priceSyp;
  final double? priceTry;
  final bool hasInvoice;
  final String? invoicePath;
  final String expenseDate;  // YYYY-MM-DD format
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

---

## Balance-Based Exchanges

**Location:** `lib/features/exchanges/data/datasources/exchange_api_datasource.dart`

### Create Exchange

**Endpoint:** `POST /api/v1/exchanges`

**Authentication:** Bearer token

**Request Body:**

```json
{
  "transfer_id": 1,           // Optional - for linking to transfer
  "target_currency": "SYP",   // 'SYP' or 'TRY'
  "amount_usd": 100.00,
  "exchange_rate": 5000.00,   // Optional if converted_amount provided
  "converted_amount": 500000.00,  // Optional if exchange_rate provided
  "exchange_date": "2024-01-01",
  "notes": "Exchange notes"   // Optional
}
```

**Note:** Either `exchange_rate` OR `converted_amount` must be provided (backend will calculate the missing value).

**Response:**

```json
{
  "data": {
    "id": 1,
    "transfer_id": 1,
    "target_currency": "SYP",
    "amount_usd": 100.00,
    "exchange_rate": 5000.00,
    "converted_amount": 500000.00,
    "exchange_date": "2024-01-01",
    "notes": "Exchange notes",
    "created_at": "2024-01-01T00:00:00.000000Z"
  }
}
```

**DTO:** `ExchangeDto`

```dart
class ExchangeDto {
  final int? id;
  final int? transferId;        // Optional link to transfer
  final String targetCurrency;  // 'SYP' or 'TRY'
  final double amountUsd;
  final double? exchangeRate;
  final double? convertedAmount;
  final DateTime exchangeDate;
  final String? notes;
  final DateTime createdAt;
}
```

### Get All Exchanges

**Endpoint:** `GET /api/v1/exchanges?currency={currency}`

**Authentication:** Bearer token

**Query Parameters:**
- `currency` (optional): `'all'`, `'SYP'`, or `'TRY'` (default: 'all')

**Response:**

```json
{
  "data": [
    {
      "id": 1,
      "transfer_id": 1,
      "target_currency": "SYP",
      "amount_usd": 100.00,
      "exchange_rate": 5000.00,
      "converted_amount": 500000.00,
      "exchange_date": "2024-01-01",
      "notes": "Exchange notes",
      "created_at": "2024-01-01T00:00:00.000000Z"
    }
  ]
}
```

### Get Exchange by ID

**Endpoint:** `GET /api/v1/exchanges/{id}`

**Authentication:** Bearer token

**Response:** Same as single exchange object

### Get Exchanges by Transfer

**Endpoint:** `GET /api/v1/exchanges/transfer/{transferId}`

**Authentication:** Bearer token

**Response:** Array of exchanges linked to the transfer

### Get Transfer Balance Info

**Endpoint:** `GET /api/v1/exchanges/transfer/{transferId}/balance`

**Authentication:** Bearer token

**Response:**

```json
{
  "data": {
    "transfer_id": 1,
    "original_amount_usd": 1000.00,
    "exchanged_amount_usd": 600.00,
    "remaining_amount_usd": 400.00,
    "exchanges": [
      {
        "id": 1,
        "amount_usd": 300.00,
        "target_currency": "SYP",
        "converted_amount": 1500000.00
      }
    ]
  }
}
```

**DTO:** `TransferBalanceDto`

```dart
class TransferBalanceDto {
  final int transferId;
  final double originalAmountUsd;
  final double exchangedAmountUsd;
  final double remainingAmountUsd;
  final List<ExchangeDto> exchanges;
}
```

---

## Transfer Management

**Location:** `lib/features/transfers/data/datasources/transfer_api_datasource.dart`

### Create Transfer (SuperAdmin → Admin or Admin → User)

**Endpoint:** `POST /api/v1/transfers`

**Authentication:** Bearer token

**Request Body:**

```json
{
  "recipient_user_id": 2,
  "recipient_name": "Recipient Name",
  "amount_usd": 1000.00,
  "transfer_date": "2024-01-01",
  "notes": "Transfer notes"
}
```

**Response:**

```json
{
  "data": {
    "id": 1,
    "recipient_user_id": 2,
    "recipient_name": "Recipient Name",
    "amount_usd": 1000.00,
    "transfer_date": "2024-01-01",
    "notes": "Transfer notes",
    "created_at": "2024-01-01T00:00:00.000000Z"
  }
}
```

**DTO:** `TransferDto`

```dart
class TransferDto {
  final int? id;
  final int? recipientUserId;
  final String recipientName;
  final double amountUsd;
  final DateTime transferDate;
  final String? notes;
  final DateTime createdAt;
}
```

---

## Admin Group Management

**Location:** `lib/features/admin_group/data/datasources/admin_group_api_datasource.dart`

### Get Admin Group Info

**Endpoint:** `GET /api/v1/admin/group`

**Authentication:** Bearer token (Admin only)

**Response:**

```json
{
  "data": {
    "group": {
      "id": 1,
      "name": "Admin Group",
      "group_code": "ABC123",
      "member_count": 10,
      "created_at": "2024-01-01T00:00:00.000000Z"
    }
  }
}
```

**DTO:** `AdminGroupDto`

```dart
class AdminGroupDto {
  final int id;
  final String name;
  final String groupCode;
  final int memberCount;
  final DateTime createdAt;
}
```

### Get Group Members

**Endpoint:** `GET /api/v1/admin/group/members`

**Authentication:** Bearer token (Admin only)

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `per_page` (optional): Items per page (default: 15)
- `search` (optional): Search term for name or email
- `department` (optional): Filter by department name

**Response:**

```json
{
  "data": [
    {
      "id": 1,
      "name": "User Name",
      "email": "user@example.com",
      "department": "Department Name",
      "joined_at": "2024-01-01T00:00:00.000000Z"
    }
  ],
  "current_page": 1,
  "last_page": 1,
  "per_page": 15,
  "total": 10
}
```

**DTO:** `GroupMemberDto`

```dart
class GroupMemberDto {
  final int id;
  final String name;
  final String email;
  final String? department;
  final DateTime? joinedAt;
}
```

### Regenerate Group Code

**Endpoint:** `POST /api/v1/admin/group/regenerate`

**Authentication:** Bearer token (Admin only)

**Response:** Same as Get Admin Group Info

### Remove Group Member

**Endpoint:** `DELETE /api/v1/admin/group/members/{userId}`

**Authentication:** Bearer token (Admin only)

**Response:** 204 No Content

### Join Group (User)

**Endpoint:** `POST /api/v1/user/join-group`

**Authentication:** Bearer token (User only)

**Request Body:**

```json
{
  "group_code": "ABC123"
}
```

**Response:**

```json
{
  "data": {
    "group_code": "ABC123",
    "group_name": "Admin Group",
    "admin_name": "Admin Name",
    "admin_email": "admin@example.com",
    "members_count": 10,
    "joined_at": "2024-01-01T00:00:00.000000Z"
  }
}
```

**DTO:** `GroupInfoDto`

```dart
class GroupInfoDto {
  final String groupCode;
  final String? groupName;
  final String adminName;
  final String adminEmail;
  final int membersCount;
  final DateTime joinedAt;
}
```

### Get User Group Info

**Endpoint:** `GET /api/v1/user/group-info`

**Authentication:** Bearer token (User only)

**Response:** Same as Join Group response

---

## Error Handling

### HTTP Status Codes

All API endpoints follow standard HTTP status codes:

- **200 OK**: Request successful
- **201 Created**: Resource created successfully
- **204 No Content**: Request successful, no content to return
- **400 Bad Request**: Invalid request data
- **401 Unauthorized**: Missing or invalid Bearer token (triggers automatic token refresh)
- **403 Forbidden**: Insufficient permissions
- **404 Not Found**: Resource not found
- **422 Unprocessable Entity**: Validation errors
- **429 Too Many Requests**: Rate limit exceeded
- **500 Internal Server Error**: Server error

### Error Response Format

```json
{
  "success": false,
  "message": "Error message",
  "errors": {
    "field_name": ["Error detail 1", "Error detail 2"]
  }
}
```

### Bearer Token Error Handling

The `BearerTokenInterceptor` automatically handles:

1. **401 Unauthorized**: Attempts token refresh, retries request with new token
2. **Token Refresh Failure**: Clears tokens, triggers logout callback
3. **Request Queueing**: Queues concurrent requests during token refresh
4. **Public Endpoint Detection**: Skips token injection for public endpoints

---

## Field Mapping Reference

### Common Field Mappings

| API Field | DTO Field | Type | Notes |
|-----------|-----------|------|-------|
| `id` | `id` | `int` | Primary key |
| `created_at` | `createdAt` | `DateTime` | ISO 8601 timestamp |
| `updated_at` | `updatedAt` | `DateTime` | ISO 8601 timestamp |
| `deleted_at` | `deletedAt` | `DateTime?` | Soft delete timestamp |

### Multi-Currency Fields

| API Field | DTO Field | Type | Notes |
|-----------|-----------|------|-------|
| `balance_usd` | `balanceUsd` | `double?` | USD balance |
| `balance_syp` | `balanceSyp` | `double?` | SYP balance |
| `balance_try` | `balanceTry` | `double?` | TRY balance |
| `price_usd` | `priceUsd` | `double?` | USD price |
| `price_syp` | `priceSyp` | `double?` | SYP price |
| `price_try` | `priceTry` | `double?` | TRY price |

### Exchange Fields

| API Field | DTO Field | Type | Notes |
|-----------|-----------|------|-------|
| `transfer_id` | `transferId` | `int?` | Optional transfer link |
| `target_currency` | `targetCurrency` | `String` | 'SYP' or 'TRY' |
| `amount_usd` | `amountUsd` | `double` | USD amount to exchange |
| `exchange_rate` | `exchangeRate` | `double?` | Exchange rate |
| `converted_amount` | `convertedAmount` | `double?` | Converted amount |
| `exchange_date` | `exchangeDate` | `DateTime` | Date of exchange |

### Group Management Fields

| API Field | DTO Field | Type | Notes |
|-----------|-----------|------|-------|
| `group_code` | `groupCode` | `String` | 6-character code |
| `group_name` | `groupName` | `String?` | Group name |
| `admin_group_id` | `adminGroupId` | `int?` | Admin group ID |
| `admin_group_name` | `adminGroupName` | `String?` | Admin group name |
| `member_count` | `memberCount` | `int` | Number of members |
| `members_count` | `membersCount` | `int` | Number of members |

---

## Summary

This documentation covers all API datasources, DTOs, and field mappings for the complete Postman API v3.1 integration. All protected endpoints automatically include Bearer token authentication via the `BearerTokenInterceptor`, while public endpoints (organizations, departments) are accessed without authentication.

For usage examples, see [USAGE_EXAMPLES.md](./USAGE_EXAMPLES.md).

For troubleshooting, see [TROUBLESHOOTING.md](./TROUBLESHOOTING.md).

For feature parity verification, see [ENDPOINT_COVERAGE_SUMMARY.md](./ENDPOINT_COVERAGE_SUMMARY.md).

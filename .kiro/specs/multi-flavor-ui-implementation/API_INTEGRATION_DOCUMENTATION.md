# API Integration Documentation

## Overview

This document describes all API integration points used in the multi-flavor Finance application. It covers authentication, data models, endpoints, and error handling for all three flavors (Superadmin, Admin, User).

## Table of Contents

1. [Base Configuration](#base-configuration)
2. [Authentication](#authentication)
3. [Superadmin APIs](#superadmin-apis)
4. [Admin APIs](#admin-apis)
5. [User APIs](#user-apis)
6. [Shared APIs](#shared-apis)
7. [Error Handling](#error-handling)
8. [Data Models](#data-models)

## Base Configuration

### API Base URL

```dart
// lib/core/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://api.financeapp.com/api/v1';
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}
```

### Headers

All API requests include:
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer {token}
```

## Authentication

### Register

**Endpoint**: `POST /auth/register`

**Request Body**:
```json
{
  "name": "string",
  "email": "string",
  "password": "string",
  "role": "superadmin|admin|user",
  "super_admin_group_code": "string (optional, for admin)",
  "admin_group_code": "string (optional, for user)",
  "organization_name": "string (optional, for superadmin)",
  "admin_group_name": "string (optional, for superadmin)"
}
```

**Response**:
```json
{
  "token": "string",
  "user": {
    "id": "string",
    "name": "string",
    "email": "string",
    "role": "string",
    "profile_image_url": "string|null",
    "organization_name": "string|null",
    "department_name": "string|null",
    "admin_group_id": "string|null",
    "superadmin_group_id": "string|null"
  },
  "super_admin_group_code": "string (only for superadmin)",
  "admin_group_code": "string (only for admin)",
  "admin_group": {
    "id": "string",
    "group_code": "string",
    "group_name": "string"
  }
}
```

### Login

**Endpoint**: `POST /auth/login`

**Request Body**:
```json
{
  "email": "string",
  "password": "string"
}
```


**Response**: Same as Register

### Logout

**Endpoint**: `POST /auth/logout`

**Headers**: Requires Bearer token

**Response**:
```json
{
  "message": "Logged out successfully"
}
```

## Superadmin APIs

### Get Superadmin Group

**Endpoint**: `GET /superadmin/group`

**Response**:
```json
{
  "id": "string",
  "superadmin_user_id": "string",
  "group_code": "string",
  "group_name": "string",
  "members_count": "integer",
  "is_active": "boolean",
  "created_at": "datetime"
}
```

### Get Group Members (Admins)

**Endpoint**: `GET /superadmin/group/members`

**Query Parameters**:
- `page`: integer (default: 1)
- `per_page`: integer (default: 15, max: 100)

**Response**:
```json
{
  "data": [
    {
      "id": "string",
      "name": "string",
      "email": "string",
      "profile_image_url": "string|null",
      "balance_usd": "number",
      "balance_syp": "number",
      "balance_try": "number",
      "created_at": "datetime"
    }
  ],
  "meta": {
    "current_page": "integer",
    "per_page": "integer",
    "total": "integer",
    "last_page": "integer"
  }
}
```

### Regenerate Group Code

**Endpoint**: `POST /superadmin/group/regenerate-code`

**Response**:
```json
{
  "group_code": "string",
  "message": "Group code regenerated successfully"
}
```

### Remove Admin from Group

**Endpoint**: `DELETE /superadmin/group/members/{admin_id}`

**Response**:
```json
{
  "message": "Admin removed from group successfully"
}
```

### Get Analytics

**Endpoint**: `GET /superadmin/analytics`

**Query Parameters**:
- `period`: string (15days|month|all)
- `admin_group_id`: string (optional)

**Response**:
```json
{
  "global_summary": {
    "total_invoices": "integer",
    "total_invoices_value": "number",
    "total_transfers": "integer"
  },
  "admin_groups": [
    {
      "admin_id": "string",
      "admin_name": "string",
      "user_count": "integer",
      "invoice_count": "integer",
      "invoice_value": "number",
      "transfer_count": "integer"
    }
  ]
}
```

### Get Expenses (Read-Only)

**Endpoint**: `GET /superadmin/expenses`

**Query Parameters**:
- `page`: integer
- `per_page`: integer
- `start_date`: date (optional)
- `end_date`: date (optional)
- `admin_group_id`: string (optional)

**Response**:
```json
{
  "data": [
    {
      "id": "string",
      "user_id": "string",
      "user_name": "string",
      "admin_group_id": "string",
      "admin_group_name": "string",
      "description": "string",
      "price_usd": "number|null",
      "price_syp": "number|null",
      "price_try": "number|null",
      "expense_date": "date",
      "invoice_photo_url": "string|null",
      "has_invoice": "boolean",
      "created_at": "datetime"
    }
  ],
  "meta": {
    "current_page": "integer",
    "per_page": "integer",
    "total": "integer"
  }
}
```

## Admin APIs

### Get Admin Group

**Endpoint**: `GET /admin/group`

**Response**:
```json
{
  "id": "string",
  "admin_user_id": "string",
  "group_code": "string",
  "group_name": "string",
  "members_count": "integer",
  "is_active": "boolean",
  "created_at": "datetime"
}
```

### Get Group Members (Users)

**Endpoint**: `GET /admin/group/members`

**Query Parameters**:
- `page`: integer
- `per_page`: integer

**Response**:
```json
{
  "data": [
    {
      "id": "string",
      "name": "string",
      "email": "string",
      "profile_image_url": "string|null",
      "balance_usd": "number",
      "balance_syp": "number",
      "balance_try": "number",
      "created_at": "datetime"
    }
  ],
  "meta": {
    "current_page": "integer",
    "per_page": "integer",
    "total": "integer"
  }
}
```

### Regenerate Group Code

**Endpoint**: `POST /admin/group/regenerate`

**Response**:
```json
{
  "group_code": "string",
  "message": "Group code regenerated successfully"
}
```

### Remove User from Group

**Endpoint**: `DELETE /admin/group/members/{user_id}`

**Response**:
```json
{
  "message": "User removed from group successfully"
}
```

## User APIs

### Join Group

**Endpoint**: `POST /user/join-group`

**Request Body**:
```json
{
  "group_code": "string"
}
```

**Response**:
```json
{
  "message": "Joined group successfully",
  "group": {
    "id": "string",
    "group_code": "string",
    "group_name": "string",
    "admin_name": "string"
  }
}
```

### Get Group Info

**Endpoint**: `GET /user/group-info`

**Response**:
```json
{
  "group_code": "string",
  "group_name": "string",
  "admin_name": "string",
  "members_count": "integer",
  "joined_at": "datetime"
}
```

## Shared APIs

### Fund Box

#### Get Fund Box

**Endpoint**: `GET /fund-box`

**Query Parameters**:
- `currency`: string (optional, USD|SYP|TRY)
- `user_id`: string (optional, for Admin/Superadmin viewing User balance)

**Response**:
```json
{
  "id": "string",
  "user_id": "string",
  "balance_usd": "number",
  "balance_syp": "number",
  "balance_try": "number",
  "last_calculated_at": "datetime",
  "updated_at": "datetime"
}
```

### Transfers

#### Create Transfer

**Endpoint**: `POST /transfers`

**Request Body**:
```json
{
  "recipient_user_id": "string",
  "amount_usd": "number",
  "transfer_date": "date",
  "notes": "string (optional)"
}
```

**Response**:
```json
{
  "id": "string",
  "sender_user_id": "string",
  "recipient_user_id": "string",
  "recipient_name": "string",
  "amount_usd": "number",
  "transfer_date": "date",
  "notes": "string|null",
  "created_at": "datetime"
}
```

#### Get Transfers

**Endpoint**: `GET /transfers`

**Query Parameters**:
- `page`: integer
- `per_page`: integer
- `recipient_user_id`: string (optional)
- `start_date`: date (optional)
- `end_date`: date (optional)

**Response**:
```json
{
  "data": [
    {
      "id": "string",
      "sender_user_id": "string",
      "recipient_user_id": "string",
      "recipient_name": "string",
      "amount_usd": "number",
      "transfer_date": "date",
      "notes": "string|null",
      "created_at": "datetime"
    }
  ],
  "meta": {
    "current_page": "integer",
    "per_page": "integer",
    "total": "integer"
  }
}
```

### Exchanges

#### Create Exchange

**Endpoint**: `POST /exchanges`

**Request Body**:
```json
{
  "target_currency": "SYP|TRY",
  "amount_usd": "number",
  "exchange_rate": "number",
  "converted_amount": "number",
  "exchange_date": "date",
  "transfer_id": "string (optional)",
  "notes": "string (optional)"
}
```

**Response**:
```json
{
  "id": "string",
  "user_id": "string",
  "transfer_id": "string|null",
  "target_currency": "string",
  "amount_usd": "number",
  "exchange_rate": "number",
  "converted_amount": "number",
  "exchange_date": "date",
  "notes": "string|null",
  "created_at": "datetime"
}
```

#### Get Exchanges

**Endpoint**: `GET /exchanges`

**Query Parameters**:
- `page`: integer
- `per_page`: integer
- `currency`: string (optional, SYP|TRY)
- `user_id`: string (optional, for Admin viewing User exchanges)

**Response**:
```json
{
  "data": [
    {
      "id": "string",
      "user_id": "string",
      "user_name": "string",
      "target_currency": "string",
      "amount_usd": "number",
      "exchange_rate": "number",
      "converted_amount": "number",
      "exchange_date": "date",
      "notes": "string|null",
      "created_at": "datetime"
    }
  ],
  "meta": {
    "current_page": "integer",
    "per_page": "integer",
    "total": "integer"
  }
}
```

### Expenses

#### Create Expense

**Endpoint**: `POST /expenses`

**Request Body**:
```json
{
  "description": "string",
  "price_usd": "number|null",
  "price_syp": "number|null",
  "price_try": "number|null",
  "expense_date": "date",
  "invoice_photo": "file (optional)"
}
```

**Response**:
```json
{
  "id": "string",
  "user_id": "string",
  "description": "string",
  "price_usd": "number|null",
  "price_syp": "number|null",
  "price_try": "number|null",
  "expense_date": "date",
  "invoice_photo_url": "string|null",
  "has_invoice": "boolean",
  "created_at": "datetime"
}
```

#### Get Expenses

**Endpoint**: `GET /expenses`

**Query Parameters**:
- `page`: integer
- `per_page`: integer
- `start_date`: date (optional)
- `end_date`: date (optional)
- `currency`: string (optional, USD|SYP|TRY)
- `user_id`: string (optional, for Admin viewing User expenses)

**Response**:
```json
{
  "data": [
    {
      "id": "string",
      "user_id": "string",
      "user_name": "string",
      "description": "string",
      "price_usd": "number|null",
      "price_syp": "number|null",
      "price_try": "number|null",
      "expense_date": "date",
      "invoice_photo_url": "string|null",
      "has_invoice": "boolean",
      "created_at": "datetime"
    }
  ],
  "meta": {
    "current_page": "integer",
    "per_page": "integer",
    "total": "integer"
  }
}
```

### Export

#### Export to PDF

**Endpoint**: `POST /export/expenses/pdf`

**Request Body**:
```json
{
  "start_date": "date (optional)",
  "end_date": "date (optional)",
  "currency": "string (optional)",
  "user_id": "string (optional)"
}
```

**Response**:
```json
{
  "export_id": "string",
  "status": "pending|processing|completed|failed",
  "download_url": "string|null"
}
```

#### Export to Excel

**Endpoint**: `POST /export/expenses/excel`

**Request Body**: Same as PDF

**Response**: Same as PDF

#### Export Invoice Images

**Endpoint**: `POST /export/expenses/invoice-images`

**Request Body**: Same as PDF

**Response**: Same as PDF

#### Get Export Status

**Endpoint**: `GET /export/{export_id}/status`

**Response**:
```json
{
  "export_id": "string",
  "status": "pending|processing|completed|failed",
  "progress": "integer (0-100)",
  "download_url": "string|null",
  "error_message": "string|null"
}
```

### Profile

#### Get Profile

**Endpoint**: `GET /profile`

**Response**:
```json
{
  "id": "string",
  "name": "string",
  "email": "string",
  "role": "string",
  "profile_image_url": "string|null",
  "organization_name": "string|null",
  "department_name": "string|null",
  "created_at": "datetime"
}
```

#### Update Profile

**Endpoint**: `PUT /profile`

**Request Body**:
```json
{
  "name": "string (optional)",
  "organization_name": "string (optional)",
  "department_name": "string (optional)"
}
```

**Response**: Same as Get Profile

#### Upload Profile Image

**Endpoint**: `POST /profile/image`

**Request Body**: multipart/form-data
- `image`: file (max 10MB, jpg/png)

**Response**:
```json
{
  "profile_image_url": "string",
  "message": "Profile image uploaded successfully"
}
```

#### Change Password

**Endpoint**: `POST /profile/change-password`

**Request Body**:
```json
{
  "current_password": "string",
  "new_password": "string"
}
```

**Response**:
```json
{
  "message": "Password changed successfully"
}
```

## Error Handling

### Error Response Format

All errors follow this format:
```json
{
  "error": {
    "code": "string",
    "message": "string",
    "details": "object|null"
  }
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `UNAUTHORIZED` | 401 | Invalid or expired token |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `VALIDATION_ERROR` | 422 | Invalid input data |
| `INSUFFICIENT_BALANCE` | 400 | Not enough balance for operation |
| `INVALID_GROUP_CODE` | 400 | Group code is invalid or expired |
| `ALREADY_IN_GROUP` | 400 | User already belongs to a group |
| `SERVER_ERROR` | 500 | Internal server error |

### Handling Specific Errors

#### Insufficient Balance

```json
{
  "error": {
    "code": "INSUFFICIENT_BALANCE",
    "message": "Insufficient USD balance",
    "details": {
      "required": 100.00,
      "available": 50.00,
      "currency": "USD"
    }
  }
}
```

#### Validation Error

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": {
      "amount_usd": ["The amount must be greater than 0"],
      "recipient_user_id": ["The recipient user id field is required"]
    }
  }
}
```

## Data Models

### User DTO

```dart
class UserDto {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? profileImageUrl;
  final String? organizationName;
  final String? departmentName;
  final String? adminGroupId;
  final String? superadminGroupId;
  final DateTime createdAt;
}
```

### FundBox DTO

```dart
class FundBoxDto {
  final String id;
  final String userId;
  final double balanceUsd;
  final double balanceSyp;
  final double balanceTry;
  final DateTime lastCalculatedAt;
  final DateTime updatedAt;
}
```

### Transfer DTO

```dart
class TransferDto {
  final String id;
  final String senderUserId;
  final String recipientUserId;
  final String recipientName;
  final double amountUsd;
  final DateTime transferDate;
  final String? notes;
  final DateTime createdAt;
}
```

### Exchange DTO

```dart
class ExchangeDto {
  final String id;
  final String userId;
  final String? transferId;
  final String targetCurrency;
  final double amountUsd;
  final double exchangeRate;
  final double convertedAmount;
  final DateTime exchangeDate;
  final String? notes;
  final DateTime createdAt;
}
```

### Expense DTO

```dart
class ExpenseDto {
  final String id;
  final String userId;
  final String description;
  final double? priceUsd;
  final double? priceSyp;
  final double? priceTry;
  final DateTime expenseDate;
  final String? invoicePhotoUrl;
  final bool hasInvoice;
  final DateTime createdAt;
}
```

## Implementation Examples

### Making an API Call

```dart
// Using ApiClient
final response = await apiClient.get(
  '/fund-box',
  queryParameters: {'currency': 'USD'},
);

final fundBox = FundBoxDto.fromJson(response.data);
```

### Handling Errors

```dart
try {
  await apiClient.post('/transfers', data: transferData);
} on ApiException catch (e) {
  if (e.code == 'INSUFFICIENT_BALANCE') {
    // Show insufficient balance error
    showError('Insufficient balance: ${e.details['available']} ${e.details['currency']}');
  } else {
    // Show generic error
    showError(e.message);
  }
}
```

### Pagination

```dart
int currentPage = 1;
final perPage = 15;

Future<void> loadMore() async {
  final response = await apiClient.get(
    '/expenses',
    queryParameters: {
      'page': currentPage,
      'per_page': perPage,
    },
  );
  
  final expenses = (response.data['data'] as List)
      .map((e) => ExpenseDto.fromJson(e))
      .toList();
  
  currentPage++;
}
```

---

**Version**: 1.0  
**Last Updated**: November 2024

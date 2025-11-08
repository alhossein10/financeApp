# DTO Field Mappings Reference

## Overview

This document provides a comprehensive reference of all DTO field mappings between the Flutter app and Laravel API. Use this as a quick reference when working with API integration.

## Transfer Module

### TransferDto

| App Field (Dart) | API Field (JSON) | Type | Required | Default | Validation |
|------------------|------------------|------|----------|---------|------------|
| id | id | int | No | null | - |
| userId | user_id | int | No | null | - |
| amount | amount | double | Yes | - | > 0 |
| fromAccount | from_account | string | Yes | - | Not empty |
| toAccount | to_account | string | Yes | - | Not empty |
| description | description | string | No | null | Max 500 chars |
| date | date | string | Yes | - | YYYY-MM-DD format |
| createdAt | created_at | DateTime | No | null | ISO 8601 |
| updatedAt | updated_at | DateTime | No | null | ISO 8601 |

### Example JSON

```json
{
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
```

### Dart Code

```dart
class TransferDto {
  final int? id;
  final int? userId;
  final double amount;
  final String fromAccount;
  final String toAccount;
  final String? description;
  final String date;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  factory TransferDto.fromJson(Map<String, dynamic> json) {
    return TransferDto(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      amount: (json['amount'] as num).toDouble(),
      fromAccount: json['from_account'] as String,
      toAccount: json['to_account'] as String,
      description: json['description'] as String?,
      date: json['date'] as String,
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'] as String) 
        : null,
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at'] as String) 
        : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'from_account': fromAccount,
      'to_account': toAccount,
      'description': description,
      'date': date,
    };
  }
}
```

## Incoming Module

### IncomingDto

| App Field (Dart) | API Field (JSON) | Type | Required | Default | Validation |
|------------------|------------------|------|----------|---------|------------|
| id | id | int | No | null | - |
| userId | user_id | int | No | null | - |
| amountUsd | amount_usd | double | Yes | - | > 0 |
| source | source | string | Yes | - | Not empty |
| description | description | string | No | null | Max 500 chars |
| date | incoming_date | string | Yes | - | YYYY-MM-DD format |
| paymentMethod | payment_method | string | Yes | - | cash, card, bank_transfer |
| createdAt | created_at | DateTime | No | null | ISO 8601 |
| updatedAt | updated_at | DateTime | No | null | ISO 8601 |

### Example JSON

```json
{
  "id": 1,
  "user_id": 1,
  "amount_usd": 5000.00,
  "source": "Salary",
  "description": "October salary",
  "incoming_date": "2024-10-23",
  "payment_method": "bank_transfer",
  "created_at": "2025-10-28T10:30:00.000000Z",
  "updated_at": "2025-10-28T10:30:00.000000Z"
}
```

### Payment Method Enum

```dart
enum PaymentMethod {
  cash('cash'),
  card('card'),
  bankTransfer('bank_transfer');
  
  final String apiValue;
  const PaymentMethod(this.apiValue);
  
  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => throw ValidationException('Invalid payment method: $value'),
    );
  }
}
```

## Expense Module

### ExpenseDto

| App Field (Dart) | API Field (JSON) | Type | Required | Default | Validation |
|------------------|------------------|------|----------|---------|------------|
| id | id | int | No | null | - |
| userId | user_id | int | No | null | - |
| amount | amount | double | Yes | - | > 0 |
| category | category | string | Yes | - | Not empty |
| description | description | string | No | null | Max 500 chars |
| date | date | string | Yes | - | YYYY-MM-DD format |
| paymentMethod | payment_method | string | Yes | - | cash, card, bank_transfer |
| receiptPath | receipt_path | string | No | null | - |
| createdAt | created_at | DateTime | No | null | ISO 8601 |
| updatedAt | updated_at | DateTime | No | null | ISO 8601 |

### Example JSON

```json
{
  "id": 1,
  "user_id": 1,
  "amount": 50.00,
  "category": "Food",
  "description": "Lunch",
  "date": "2025-10-28",
  "payment_method": "card",
  "receipt_path": "receipts/abc123.jpg",
  "created_at": "2025-10-28T10:30:00.000000Z",
  "updated_at": "2025-10-28T10:30:00.000000Z"
}
```

## Fund Box Module

### FundBoxDto

| App Field (Dart) | API Field (JSON) | Type | Required | Default | Validation |
|------------------|------------------|------|----------|---------|------------|
| id | id | int | No | null | - |
| totalBalance | total_balance | double | Yes | - | >= 0 |
| lastUpdated | last_updated | DateTime | No | null | ISO 8601 |

### Example JSON

```json
{
  "id": 1,
  "total_balance": 10000.00,
  "last_updated": "2025-10-28T10:30:00.000000Z"
}
```

## Admin Dashboard Module

### AdminStatsDto

| App Field (Dart) | API Field (JSON) | Type | Required | Default |
|------------------|------------------|------|----------|---------|
| totalUsers | total_users | int | Yes | - |
| totalExpenses | total_expenses | int | Yes | - |
| totalIncome | total_income | int | Yes | - |
| totalTransfers | total_transfers | int | Yes | - |
| totalAmountExpenses | total_amount_expenses | double | Yes | - |
| totalAmountIncome | total_amount_income | double | Yes | - |
| fundBoxBalance | fund_box_balance | double | Yes | - |

### Example JSON

```json
{
  "total_users": 10,
  "total_expenses": 150,
  "total_income": 50,
  "total_transfers": 30,
  "total_amount_expenses": 5000.00,
  "total_amount_income": 10000.00,
  "fund_box_balance": 5000.00
}
```

### ExpenseSummaryDto

| App Field (Dart) | API Field (JSON) | Type | Description |
|------------------|------------------|------|-------------|
| byCategory | by_category | Map<String, CategorySummary> | Expenses grouped by category |
| byPaymentMethod | by_payment_method | Map<String, PaymentMethodSummary> | Expenses grouped by payment method |

### CategorySummary

| App Field (Dart) | API Field (JSON) | Type |
|------------------|------------------|------|
| category | category | string |
| total | total | double |
| count | count | int |

### PaymentMethodSummary

| App Field (Dart) | API Field (JSON) | Type |
|------------------|------------------|------|
| paymentMethod | payment_method | string |
| total | total | double |

### Example JSON

```json
{
  "by_category": {
    "Food": {
      "category": "Food",
      "total": 500.00,
      "count": 10
    },
    "Transport": {
      "category": "Transport",
      "total": 200.00,
      "count": 5
    }
  },
  "by_payment_method": {
    "cash": {
      "payment_method": "cash",
      "total": 300.00
    },
    "card": {
      "payment_method": "card",
      "total": 400.00
    }
  }
}
```

### AnalyticsDto

| App Field (Dart) | API Field (JSON) | Type |
|------------------|------------------|------|
| period | period | DatePeriod |
| expenses | expenses | ExpenseAnalytics |
| income | income | IncomeAnalytics |
| netBalance | net_balance | double |
| trends | trends | TrendsData |

### Example JSON

```json
{
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
```

### UserActivityDto

| App Field (Dart) | API Field (JSON) | Type |
|------------------|------------------|------|
| id | id | int |
| name | name | string |
| email | email | string |
| role | role | string |
| expenseCount | expense_count | int |
| incomeCount | income_count | int |
| transferCount | transfer_count | int |
| lastActive | last_active | DateTime |

### Example JSON

```json
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
```

## Profile Module

### ProfileDto

| App Field (Dart) | API Field (JSON) | Type | Required |
|------------------|------------------|------|----------|
| id | id | int | Yes |
| name | name | string | Yes |
| email | email | string | Yes |
| role | role | string | Yes |
| createdAt | created_at | DateTime | Yes |

### Example JSON

```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "role": "user",
  "created_at": "2025-10-01T10:00:00.000000Z"
}
```

## Export Module

### ExportDto

| App Field (Dart) | API Field (JSON) | Type | Required |
|------------------|------------------|------|----------|
| id | id | string | Yes |
| format | format | string | Yes |
| status | status | string | Yes |
| downloadUrl | download_url | string | No |
| createdAt | created_at | DateTime | Yes |

### Example JSON

```json
{
  "id": "exp_abc123",
  "format": "pdf",
  "status": "completed",
  "download_url": "https://api.example.com/exports/exp_abc123/download",
  "created_at": "2025-10-28T10:30:00.000000Z"
}
```

### Export Status Values

- `processing` - Export is being generated
- `completed` - Export is ready for download
- `failed` - Export generation failed

### Export Format Values

- `pdf` - PDF format
- `excel` - Excel format

## File Upload Module

### FileUploadDto

| App Field (Dart) | API Field (JSON) | Type | Required |
|------------------|------------------|------|----------|
| id | id | int | Yes |
| filename | filename | string | Yes |
| path | path | string | Yes |
| type | type | string | Yes |
| size | size | int | Yes |
| mimeType | mime_type | string | Yes |
| uploadedAt | uploaded_at | DateTime | Yes |

### Example JSON

```json
{
  "id": 1,
  "filename": "receipt.jpg",
  "path": "encrypted_path_abc123",
  "type": "receipt",
  "size": 1024000,
  "mime_type": "image/jpeg",
  "uploaded_at": "2025-10-28T10:30:00.000000Z"
}
```

### File Type Values

- `receipt` - Receipt image
- `invoice` - Invoice document
- `document` - General document

## Audit Log Module

### AuditLogDto

| App Field (Dart) | API Field (JSON) | Type | Required | Notes |
|------------------|------------------|------|----------|-------|
| id | id | int | Yes | - |
| userId | user_id | int | Yes | - |
| userName | user_name | string | No | Detail view only |
| action | action | string | Yes | - |
| entityType | entity_type | string | Yes | - |
| entityId | entity_id | int | Yes | - |
| changes | changes | Map | No | Detail view only |
| ipAddress | ip_address | string | Yes | - |
| userAgent | user_agent | string | Yes | - |
| createdAt | created_at | DateTime | Yes | - |

### Example JSON (List View)

```json
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
```

### Example JSON (Detail View)

```json
{
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
    },
    "category": {
      "old": "Food",
      "new": "Transport"
    }
  },
  "ip_address": "192.168.1.1",
  "user_agent": "Mozilla/5.0...",
  "created_at": "2025-10-28T10:30:00.000000Z"
}
```

## Batch Sync Module

### SyncRequestDto

| App Field (Dart) | API Field (JSON) | Type |
|------------------|------------------|------|
| lastSync | last_sync | DateTime |
| data | data | SyncDataDto |

### SyncDataDto

| App Field (Dart) | API Field (JSON) | Type |
|------------------|------------------|------|
| expenses | expenses | List<ExpenseDto> |
| incoming | incoming | List<IncomingDto> |
| transfers | transfers | List<TransferDto> |

### SyncResponseDto

| App Field (Dart) | API Field (JSON) | Type |
|------------------|------------------|------|
| syncedAt | synced_at | DateTime |
| expenses | expenses | EntitySyncResult |
| incoming | incoming | EntitySyncResult |
| transfers | transfers | EntitySyncResult |

### EntitySyncResult

| App Field (Dart) | API Field (JSON) | Type |
|------------------|------------------|------|
| created | created | List<CreatedItem> |
| conflicts | conflicts | List<ConflictItem> |

### CreatedItem

| App Field (Dart) | API Field (JSON) | Type |
|------------------|------------------|------|
| localId | local_id | string |
| serverId | server_id | int |
| data | data | Map |

### ConflictItem

| App Field (Dart) | API Field (JSON) | Type |
|------------------|------------------|------|
| localId | local_id | string |
| localData | local_data | Map |
| serverData | server_data | Map |
| reason | reason | string |

## Authentication Module

### UserDto

| App Field (Dart) | API Field (JSON) | Type | Required |
|------------------|------------------|------|----------|
| id | id | int | Yes |
| name | name | string | Yes |
| email | email | string | Yes |
| role | role | string | Yes |
| token | token | string | No |

### Example JSON (Login Response)

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
    "token": "1|abc123def456..."
  }
}
```

## Pagination

### PaginatedResponse

| App Field (Dart) | API Field (JSON) | Type |
|------------------|------------------|------|
| currentPage | current_page | int |
| data | data | List<T> |
| lastPage | last_page | int |
| perPage | per_page | int |
| total | total | int |

### Example JSON

```json
{
  "current_page": 1,
  "data": [...],
  "last_page": 5,
  "per_page": 15,
  "total": 73
}
```

## Date Formatting

### Date Format (YYYY-MM-DD)

```dart
// Dart to API
final apiDate = DateFormatter.toApiDate(DateTime.now());
// "2025-10-28"

// API to Dart
final date = DateFormatter.fromApiDate("2025-10-28");
```

### Timestamp Format (ISO 8601)

```dart
// Dart to API
final apiTimestamp = DateFormatter.toApiTimestamp(DateTime.now());
// "2025-10-28T10:30:00.000Z"

// API to Dart
final timestamp = DateFormatter.fromApiTimestamp("2025-10-28T10:30:00.000Z");
```

## Summary

- All DTOs use camelCase in Dart and snake_case in JSON
- Dates use YYYY-MM-DD format
- Timestamps use ISO 8601 format
- Payment methods: cash, card, bank_transfer
- All amounts are double type
- All IDs are int type
- Nullable fields use `?` in Dart
- Required fields must be provided in requests
- Response fields may be null even if not marked nullable

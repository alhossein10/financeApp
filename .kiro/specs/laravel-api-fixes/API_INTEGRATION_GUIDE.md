# API Integration Guide

## Overview

This guide provides comprehensive documentation for the Laravel API integration in the Flutter finance app. All API endpoints have been fixed to match the Laravel backend specification with correct field mappings, error handling, and role-based access control.

## Base Configuration

### API Endpoints

```dart
// Development
const String DEV_API_URL = 'http://localhost:8000/api/v1';

// Staging
const String STAGING_API_URL = 'https://staging-api.example.com/api/v1';

// Production
const String PROD_API_URL = 'https://api.example.com/api/v1';
```

### Authentication

All authenticated requests require a Bearer token in the Authorization header:

```dart
headers: {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
  'Accept': 'application/json',
}
```

## Module Documentation

### 1. Transfer Module

#### Endpoints

- `POST /transfers` - Create transfer
- `GET /transfers` - List transfers (paginated)
- `GET /transfers/{id}` - Get transfer details
- `PUT /transfers/{id}` - Update transfer
- `DELETE /transfers/{id}` - Delete transfer

#### Field Mappings

| App Field | API Field | Type | Required | Description |
|-----------|-----------|------|----------|-------------|
| amount | amount | double | Yes | Transfer amount |
| fromAccount | from_account | string | Yes | Source account name |
| toAccount | to_account | string | Yes | Destination account name |
| description | description | string | No | Transfer description |
| date | date | string | Yes | Date in YYYY-MM-DD format |

#### Example Request

```dart
final transfer = TransferDto(
  amount: 100.50,
  fromAccount: 'Savings',
  toAccount: 'Checking',
  description: 'Monthly transfer',
  date: '2025-10-28',
);

final result = await transferApiDataSource.createTransfer(transfer);
```

#### Example Response

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

### 2. Incoming (Income) Module

#### Endpoints

- `POST /incoming` - Create income
- `GET /incoming` - List income (paginated)
- `GET /incoming/{id}` - Get income details
- `PUT /incoming/{id}` - Update income
- `DELETE /incoming/{id}` - Delete income

#### Field Mappings

| App Field | API Field | Type | Required | Description |
|-----------|-----------|------|----------|-------------|
| amount | amount | double | Yes | Income amount |
| source | source | string | Yes | Income source |
| description | description | string | No | Income description |
| date | date | string | Yes | Date in YYYY-MM-DD format |
| paymentMethod | payment_method | string | Yes | cash, card, or bank_transfer |

#### Payment Method Validation

```dart
enum PaymentMethod {
  cash('cash'),
  card('card'),
  bankTransfer('bank_transfer');
  
  final String apiValue;
  const PaymentMethod(this.apiValue);
}
```

#### Example Request

```dart
final incoming = IncomingDto(
  amount: 5000.00,
  source: 'Salary',
  description: 'October salary',
  date: '2025-10-28',
  paymentMethod: 'bank_transfer',
);

final result = await incomingApiDataSource.createIncoming(incoming);
```

### 3. Fund Box Module (Admin Only)

#### Endpoints

- `GET /fund-box` - Get fund box balance (Admin only)
- `PUT /fund-box` - Update fund box balance (Admin only)

#### Field Mappings

| App Field | API Field | Type | Required | Description |
|-----------|-----------|------|----------|-------------|
| totalBalance | total_balance | double | Yes | Total fund box balance |
| lastUpdated | last_updated | DateTime | No | Last update timestamp |

#### Access Control

```dart
// Automatically handles 403 Forbidden for non-admin users
try {
  final fundBox = await fundBoxApiDataSource.getFundBox();
} on ApiException catch (e) {
  if (e.isForbidden) {
    // Display: "Access denied. Admin privileges required"
  }
}
```

#### Example Request

```dart
// Update fund box (admin only)
final result = await fundBoxApiDataSource.updateFundBox(10000.00);
```

### 4. Admin Dashboard Module

#### Endpoints

- `GET /admin/dashboard/stats` - Get dashboard statistics
- `GET /admin/dashboard/users` - Get user activity list
- `GET /admin/dashboard/expenses` - Get expense summaries
- `GET /admin/dashboard/analytics` - Get analytics data

#### Dashboard Stats Fields

| App Field | API Field | Type | Description |
|-----------|-----------|------|-------------|
| totalUsers | total_users | int | Total registered users |
| totalExpenses | total_expenses | int | Total expense count |
| totalIncome | total_income | int | Total income count |
| totalTransfers | total_transfers | int | Total transfer count |
| totalAmountExpenses | total_amount_expenses | double | Sum of all expenses |
| totalAmountIncome | total_amount_income | double | Sum of all income |
| fundBoxBalance | fund_box_balance | double | Current fund box balance |

#### Example Request

```dart
// Get dashboard stats
final stats = await adminApiDataSource.getDashboardStats();

// Get analytics with date range
final analytics = await adminApiDataSource.getAnalytics(
  dateFrom: '2025-10-01',
  dateTo: '2025-10-31',
);
```

### 5. Expense Module

#### Endpoints

- `POST /expenses` - Create expense
- `GET /expenses` - List expenses (paginated)
- `GET /expenses/{id}` - Get expense details
- `PUT /expenses/{id}` - Update expense
- `DELETE /expenses/{id}` - Delete expense

#### Field Mappings

| App Field | API Field | Type | Required | Description |
|-----------|-----------|------|----------|-------------|
| amount | amount | double | Yes | Expense amount |
| category | category | string | Yes | Expense category |
| description | description | string | No | Expense description |
| date | date | string | Yes | Date in YYYY-MM-DD format |
| paymentMethod | payment_method | string | Yes | cash, card, or bank_transfer |

#### Filtering

```dart
// Filter expenses by category and date range
final expenses = await expenseApiDataSource.getExpenses(
  category: 'Food',
  dateFrom: '2025-10-01',
  dateTo: '2025-10-31',
  page: 1,
  perPage: 15,
);
```

### 6. Profile Module

#### Endpoints

- `GET /profile` - Get user profile
- `PUT /profile` - Update profile
- `POST /profile/password` - Change password

#### Field Mappings

| App Field | API Field | Type | Description |
|-----------|-----------|------|-------------|
| id | id | int | User ID |
| name | name | string | User name |
| email | email | string | User email |
| role | role | string | user or admin |
| createdAt | created_at | DateTime | Account creation date |

#### Example Request

```dart
// Update profile
final profile = await profileApiDataSource.updateProfile(
  name: 'John Doe',
  email: 'john@example.com',
);

// Change password
await profileApiDataSource.changePassword(
  currentPassword: 'oldpass123',
  newPassword: 'newpass456',
  newPasswordConfirmation: 'newpass456',
);
```

### 7. Export Module

#### Endpoints

- `POST /export/expenses/pdf` - Export expenses to PDF
- `POST /export/expenses/excel` - Export expenses to Excel
- `GET /export/{id}/status` - Check export status
- `GET /export/{id}/download` - Download export file

#### Field Mappings

| App Field | API Field | Type | Description |
|-----------|-----------|------|-------------|
| id | id | string | Export job ID |
| format | format | string | pdf or excel |
| status | status | string | processing, completed, or failed |
| downloadUrl | download_url | string | Download URL (when completed) |

#### Example Request

```dart
// Request PDF export
final export = await exportApiDataSource.exportExpensesPdf(
  dateFrom: DateTime(2025, 10, 1),
  dateTo: DateTime(2025, 10, 31),
);

// Check status
final status = await exportApiDataSource.getExportStatus(export.id);

// Download when completed
if (status.status == 'completed') {
  final file = await exportApiDataSource.downloadExport(export.id);
}
```

### 8. Batch Sync Module

#### Endpoints

- `POST /sync/batch` - Batch sync offline changes
- `GET /sync/changes` - Get changes since last sync

#### Request Structure

```dart
{
  "last_sync": "2025-10-28T10:00:00.000Z",
  "data": {
    "expenses": [...],
    "incoming": [...],
    "transfers": [...]
  }
}
```

#### Response Structure

```dart
{
  "synced_at": "2025-10-28T10:30:00.000Z",
  "expenses": {
    "created": [
      {"local_id": "temp_1", "server_id": 123, "data": {...}}
    ],
    "conflicts": [
      {"local_id": "temp_2", "local_data": {...}, "server_data": {...}}
    ]
  },
  "incoming": {...},
  "transfers": {...}
}
```

### 9. File Upload Module

#### Endpoints

- `POST /files/upload` - Upload file
- `GET /files/download` - Download file
- `DELETE /files` - Delete file

#### Field Mappings

| App Field | API Field | Type | Description |
|-----------|-----------|------|-------------|
| id | id | int | File ID |
| filename | filename | string | Original filename |
| path | path | string | Encrypted file path |
| type | type | string | receipt, invoice, or document |
| size | size | int | File size in bytes |
| mimeType | mime_type | string | File MIME type |

#### Example Request

```dart
// Upload file
final file = File('/path/to/receipt.jpg');
final upload = await fileUploadService.uploadFile(
  file: file,
  type: 'receipt',
);

// Download file
final downloadedFile = await fileUploadService.downloadFile(upload.path);

// Delete file
await fileUploadService.deleteFile(upload.path);
```

### 10. Audit Logs Module (Admin Only)

#### Endpoints

- `GET /audit-logs` - List audit logs (paginated)
- `GET /audit-logs/{id}` - Get audit log details

#### Field Mappings

| App Field | API Field | Type | Description |
|-----------|-----------|------|-------------|
| id | id | int | Log entry ID |
| userId | user_id | int | User who performed action |
| userName | user_name | string | User name (detail view only) |
| action | action | string | Action performed |
| entityType | entity_type | string | Entity type affected |
| entityId | entity_id | int | Entity ID affected |
| changes | changes | object | Changes made (detail view only) |
| ipAddress | ip_address | string | User IP address |
| userAgent | user_agent | string | User agent string |
| createdAt | created_at | DateTime | Log timestamp |

## Pagination

All list endpoints support pagination with the following parameters:

```dart
// Query parameters
{
  "page": 1,        // Current page (default: 1)
  "per_page": 15    // Items per page (default: 15)
}

// Response structure
{
  "current_page": 1,
  "data": [...],
  "last_page": 5,
  "per_page": 15,
  "total": 73
}
```

## Date Formatting

### API Date Format

All date fields must be sent in `YYYY-MM-DD` format:

```dart
import 'package:finance_app/core/utils/date_formatter.dart';

// Format date for API
final apiDate = DateFormatter.toApiDate(DateTime.now());
// Output: "2025-10-28"

// Parse date from API
final date = DateFormatter.fromApiDate("2025-10-28");
```

### API Timestamp Format

Timestamps use ISO 8601 format:

```dart
// Format timestamp for API
final apiTimestamp = DateFormatter.toApiTimestamp(DateTime.now());
// Output: "2025-10-28T10:30:00.000Z"

// Parse timestamp from API
final timestamp = DateFormatter.fromApiTimestamp("2025-10-28T10:30:00.000Z");
```

## Error Handling

See [ERROR_HANDLING_GUIDE.md](ERROR_HANDLING_GUIDE.md) for comprehensive error handling documentation.

## Role-Based Access Control

See [RBAC_GUIDE.md](RBAC_GUIDE.md) for role-based access control documentation.

## Testing

See [API_TESTING_GUIDE.md](API_TESTING_GUIDE.md) for API testing with Postman.

## Troubleshooting

See [TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md) for common issues and solutions.

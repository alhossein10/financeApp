# Design Document: Laravel API Integration Fixes

## Overview

This design document outlines the comprehensive solution for fixing API integration issues between the Flutter finance app and the Laravel backend. The design focuses on correcting field mappings, implementing proper error handling, ensuring role-based access control, and maintaining consistency across user and admin flavors.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Application                      │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer (BLoC)                                   │
│  ├─ TransferBloc                                            │
│  ├─ IncomingBloc                                            │
│  ├─ FundBoxBloc                                             │
│  ├─ AdminBloc                                               │
│  └─ ExportBloc                                              │
├─────────────────────────────────────────────────────────────┤
│  Domain Layer (Use Cases & Entities)                        │
│  ├─ Transfer, Incoming, FundBox Entities                    │
│  ├─ CRUD Use Cases                                          │
│  └─ Role-Based Authorization Logic                          │
├─────────────────────────────────────────────────────────────┤
│  Data Layer (Repositories & Data Sources)                   │
│  ├─ API Data Sources (Fixed Field Mappings)                │
│  ├─ DTOs (Corrected JSON Serialization)                    │
│  ├─ Cache Data Sources                                      │
│  └─ Repository Implementations                              │
├─────────────────────────────────────────────────────────────┤
│  Core Services                                               │
│  ├─ ApiClient (Enhanced Error Handling)                    │
│  ├─ TokenManager (JWT Management)                          │
│  ├─ RoleService (RBAC Implementation)                      │
│  └─ QueueManager (Offline Sync)                            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    Laravel Backend API                       │
│                    (http://localhost:8000/api/v1)           │
└─────────────────────────────────────────────────────────────┘
```

### Key Design Principles

1. **Single Source of Truth**: API specification defines all field names and formats
2. **Fail-Safe Error Handling**: All API calls wrapped with comprehensive error handling
3. **Role-Based Access**: Flavor-aware components that respect user/admin permissions
4. **Offline-First**: Queue manager handles offline operations with automatic sync
5. **Type Safety**: Strong typing with DTOs for all API communication

## Components and Interfaces

### 1. Transfer Module Fixes

#### TransferDto Corrections

**Current Issues:**
- Missing `from_account` and `to_account` fields
- Incorrect field names (`recipient_name` vs API spec)
- Date format inconsistencies

**Fixed Structure:**
```dart
class TransferDto {
  final int? id;
  final int? userId;
  final double amount;
  final String fromAccount;
  final String toAccount;
  final String? description;
  final String date; // YYYY-MM-DD format
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

**API Mapping:**
```
App Field         → API Field
amount            → amount
fromAccount       → from_account
toAccount         → to_account
description       → description
date              → date (YYYY-MM-DD)
```

#### TransferApiDataSource Updates

```dart
class TransferApiDataSourceImpl {
  Future<TransferDto> createTransfer(TransferDto transfer) async {
    final body = {
      'amount': transfer.amount,
      'from_account': transfer.fromAccount,
      'to_account': transfer.toAccount,
      'description': transfer.description,
      'date': transfer.date, // Already in YYYY-MM-DD
    };
    
    final response = await apiClient.post('/transfers', body: body);
    return TransferDto.fromJson(response.data['data']);
  }
}
```

### 2. Incoming Module Fixes

#### IncomingDto Corrections

**Current Issues:**
- Missing `source` field (primary descriptor)
- Missing `payment_method` field
- Incorrect field mapping for API spec

**Fixed Structure:**
```dart
class IncomingDto {
  final int? id;
  final int? userId;
  final double amount;
  final String source; // Required by API
  final String? description;
  final String date; // YYYY-MM-DD format
  final String paymentMethod; // cash, card, bank_transfer
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

**API Mapping:**
```
App Field         → API Field
amount            → amount
source            → source
description       → description
date              → date (YYYY-MM-DD)
paymentMethod     → payment_method
```

#### IncomingApiDataSource Updates

```dart
class IncomingApiDataSourceImpl {
  Future<IncomingDto> createIncoming(IncomingDto incoming) async {
    final body = {
      'amount': incoming.amount,
      'source': incoming.source,
      'description': incoming.description,
      'date': incoming.date,
      'payment_method': incoming.paymentMethod,
    };
    
    final response = await apiClient.post('/incoming', body: body);
    return IncomingDto.fromJson(response.data['data']);
  }
}
```

### 3. Fund Box Module Fixes

#### FundBoxDto Corrections

**Current Issues:**
- Field name mismatch (`balance_usd` vs `total_balance`)
- Missing proper 403 error handling
- Incorrect update request body

**Fixed Structure:**
```dart
class FundBoxDto {
  final int id;
  final double totalBalance; // Matches API spec
  final DateTime lastUpdated; // Matches API spec
}
```

**API Mapping:**
```
App Field         → API Field
totalBalance      → total_balance
lastUpdated       → last_updated
```

#### FundBoxApiDataSource Updates

```dart
class FundBoxApiDataSourceImpl {
  Future<FundBoxDto> getFundBox() async {
    try {
      final response = await apiClient.get('/fund-box');
      return FundBoxDto.fromJson(response.data['data']);
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        throw AuthorizationFailure('Admin privileges required');
      }
      rethrow;
    }
  }
  
  Future<FundBoxDto> updateFundBox(double newBalance) async {
    final body = {'total_balance': newBalance}; // Correct field name
    final response = await apiClient.put('/fund-box', body: body);
    return FundBoxDto.fromJson(response.data['data']);
  }
}
```

### 4. Admin Dashboard Module Fixes

#### AdminStatsDto Corrections

**Current Issues:**
- Missing fields from API response
- Incorrect field names
- No handling for nested data structures

**Fixed Structure:**
```dart
class AdminStatsDto {
  final int totalUsers;
  final int totalExpenses;
  final int totalIncome;
  final int totalTransfers;
  final double totalAmountExpenses;
  final double totalAmountIncome;
  final double fundBoxBalance;
}
```

**API Mapping:**
```
App Field              → API Field
totalUsers             → total_users
totalExpenses          → total_expenses
totalIncome            → total_income
totalTransfers         → total_transfers
totalAmountExpenses    → total_amount_expenses
totalAmountIncome      → total_amount_income
fundBoxBalance         → fund_box_balance
```

#### ExpenseSummaryDto (New)

```dart
class ExpenseSummaryDto {
  final Map<String, CategorySummary> byCategory;
  final Map<String, PaymentMethodSummary> byPaymentMethod;
}

class CategorySummary {
  final String category;
  final double total;
  final int count;
}

class PaymentMethodSummary {
  final String paymentMethod;
  final double total;
}
```

#### AnalyticsDto (New)

```dart
class AnalyticsDto {
  final DatePeriod period;
  final ExpenseAnalytics expenses;
  final IncomeAnalytics income;
  final double netBalance;
  final TrendsData trends;
}

class DatePeriod {
  final String from;
  final String to;
}

class ExpenseAnalytics {
  final double total;
  final int count;
  final double average;
}

class TrendsData {
  final List<MonthlyTrend> monthly;
}

class MonthlyTrend {
  final String month;
  final double expenses;
  final double income;
}
```

### 5. Expense Module Fixes

#### ExpenseDto Corrections

**Current Issues:**
- Payment method validation not enforced
- Missing proper date formatting
- Pagination parameters incorrect

**Fixed Structure:**
```dart
class ExpenseDto {
  final int? id;
  final int? userId;
  final double amount;
  final String category;
  final String? description;
  final String date; // YYYY-MM-DD format
  final String paymentMethod; // Validated: cash, card, bank_transfer
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Validation
  static const validPaymentMethods = ['cash', 'card', 'bank_transfer'];
  
  void validate() {
    if (!validPaymentMethods.contains(paymentMethod)) {
      throw ValidationException('Invalid payment method: $paymentMethod');
    }
  }
}
```

### 6. Profile Module Integration

#### ProfileDto (New)

```dart
class ProfileDto {
  final int id;
  final String name;
  final String email;
  final String role; // 'user' or 'admin'
  final DateTime createdAt;
}
```

#### ProfileApiDataSource (New)

```dart
abstract class ProfileApiDataSource {
  Future<ProfileDto> getProfile();
  Future<ProfileDto> updateProfile(String name, String email);
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String newPasswordConfirmation,
  );
}
```

### 7. Export Module Integration

#### ExportDto (New)

```dart
class ExportDto {
  final String id;
  final String format; // 'pdf' or 'excel'
  final String status; // 'processing', 'completed', 'failed'
  final String? downloadUrl;
  final DateTime createdAt;
}
```

#### ExportApiDataSource Updates

```dart
class ExportApiDataSourceImpl {
  Future<ExportDto> exportExpensesPdf({
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    final body = {
      'format': 'pdf',
      'date_from': _formatDate(dateFrom),
      'date_to': _formatDate(dateTo),
    };
    
    final response = await apiClient.post('/export/expenses/pdf', body: body);
    return ExportDto.fromJson(response.data['data']);
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
```

### 8. Batch Sync Module Fixes

#### SyncRequestDto (New)

```dart
class SyncRequestDto {
  final DateTime lastSync;
  final SyncDataDto data;
}

class SyncDataDto {
  final List<ExpenseDto> expenses;
  final List<IncomingDto> incoming;
  final List<TransferDto> transfers;
}
```

#### SyncResponseDto (New)

```dart
class SyncResponseDto {
  final DateTime syncedAt;
  final EntitySyncResult expenses;
  final EntitySyncResult incoming;
  final EntitySyncResult transfers;
}

class EntitySyncResult {
  final List<CreatedItem> created;
  final List<ConflictItem> conflicts;
}

class CreatedItem {
  final String localId;
  final int serverId;
  final Map<String, dynamic> data;
}

class ConflictItem {
  final String localId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final String reason;
}
```

### 9. File Upload Module Integration

#### FileUploadDto (New)

```dart
class FileUploadDto {
  final int id;
  final String filename;
  final String path; // Encrypted path for download
  final String type; // 'receipt', 'invoice', 'document'
  final int size;
  final String mimeType;
  final DateTime uploadedAt;
}
```

#### FileUploadService Updates

```dart
class FileUploadService {
  Future<FileUploadDto> uploadFile({
    required File file,
    required String type,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
      'type': type,
    });
    
    final response = await apiClient.post(
      '/files/upload',
      body: formData,
      contentType: 'multipart/form-data',
    );
    
    return FileUploadDto.fromJson(response.data['data']);
  }
  
  Future<File> downloadFile(String encryptedPath) async {
    final response = await apiClient.get(
      '/files/download',
      queryParams: {'path': encryptedPath},
      responseType: ResponseType.bytes,
    );
    
    // Save to temp file and return
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/download_${DateTime.now().millisecondsSinceEpoch}');
    await file.writeAsBytes(response.data);
    return file;
  }
}
```

### 10. Audit Logs Module Integration

#### AuditLogDto Updates

```dart
class AuditLogDto {
  final int id;
  final int userId;
  final String? userName; // Only in detail view
  final String action; // e.g., 'expense.created'
  final String entityType; // e.g., 'Expense'
  final int entityId;
  final Map<String, dynamic>? changes; // Only in detail view
  final String ipAddress;
  final String userAgent;
  final DateTime createdAt;
}
```

## Data Models

### Unified Date Handling

```dart
class DateFormatter {
  /// Format date for API requests (YYYY-MM-DD)
  static String toApiDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// Format timestamp for API requests (ISO 8601)
  static String toApiTimestamp(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }
  
  /// Parse API date response
  static DateTime fromApiDate(String dateStr) {
    return DateTime.parse(dateStr);
  }
  
  /// Parse API timestamp response
  static DateTime fromApiTimestamp(String timestampStr) {
    return DateTime.parse(timestampStr).toLocal();
  }
}
```

### Payment Method Validation

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

## Error Handling

### Enhanced ApiException

```dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors; // Validation errors
  final dynamic response;
  
  ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
    this.response,
  });
  
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => statusCode == 422;
  bool get isRateLimited => statusCode == 429;
  bool get isServerError => statusCode >= 500;
  
  String get userFriendlyMessage {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'Access denied. You don\'t have permission for this action.';
      case 404:
        return 'Resource not found.';
      case 422:
        return _formatValidationErrors();
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
      case 502:
      case 503:
        return 'Server error. Please try again later.';
      default:
        return message;
    }
  }
  
  String _formatValidationErrors() {
    if (errors == null || errors!.isEmpty) return message;
    
    final errorMessages = <String>[];
    errors!.forEach((field, messages) {
      if (messages is List) {
        errorMessages.addAll(messages.cast<String>());
      }
    });
    
    return errorMessages.join('\n');
  }
}
```

### Error Handling in BLoCs

```dart
class TransferBloc extends Bloc<TransferEvent, TransferState> {
  Future<void> _handleApiCall<T>(
    Emitter<TransferState> emit,
    Future<T> Function() apiCall,
    void Function(T) onSuccess,
  ) async {
    try {
      final result = await apiCall();
      onSuccess(result);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        // Trigger logout
        emit(TransferError('Session expired', requiresLogin: true));
      } else if (e.isForbidden) {
        emit(TransferError('Access denied. Admin privileges required.'));
      } else {
        emit(TransferError(e.userFriendlyMessage));
      }
    } catch (e) {
      emit(TransferError('An unexpected error occurred'));
    }
  }
}
```

## Testing Strategy

### Unit Tests

1. **DTO Serialization Tests**
   - Test JSON to DTO conversion for all entities
   - Test DTO to JSON conversion for API requests
   - Test field mapping correctness
   - Test date format handling

2. **API Data Source Tests**
   - Mock API responses
   - Test successful responses
   - Test error responses (400, 401, 403, 404, 422, 429, 500)
   - Test pagination handling

3. **Validation Tests**
   - Test payment method validation
   - Test date format validation
   - Test required field validation

### Integration Tests

1. **API Integration Tests**
   - Test against real Laravel backend
   - Test all CRUD operations for each entity
   - Test admin-only endpoints with user/admin roles
   - Test batch sync flow
   - Test file upload/download

2. **Role-Based Access Tests**
   - Test admin flavor with admin user
   - Test admin flavor with regular user (should fail)
   - Test user flavor with both roles

### Widget Tests

1. **Error Display Tests**
   - Test error message display for each error type
   - Test validation error display
   - Test unauthorized redirect

2. **Admin Dashboard Tests**
   - Test stats display
   - Test user activity list
   - Test expense summaries
   - Test analytics charts

## Migration Strategy

### Phase 1: DTO Fixes (Priority: Critical)
1. Update TransferDto with correct field mappings
2. Update IncomingDto with source and payment_method fields
3. Update FundBoxDto with total_balance field
4. Update AdminStatsDto with all required fields
5. Update ExpenseDto with validation

### Phase 2: API Data Source Updates (Priority: Critical)
1. Fix TransferApiDataSource request bodies
2. Fix IncomingApiDataSource request bodies
3. Fix FundBoxApiDataSource with proper error handling
4. Update AdminApiDataSource for all endpoints
5. Add ProfileApiDataSource
6. Add ExportApiDataSource
7. Update FileUploadService

### Phase 3: Error Handling (Priority: High)
1. Enhance ApiException with user-friendly messages
2. Update all BLoCs with proper error handling
3. Add 403 handling for admin-only features
4. Add 422 validation error display

### Phase 4: New Features (Priority: Medium)
1. Implement Profile API integration
2. Implement Export API integration
3. Implement Audit Logs display
4. Implement File upload/download UI

### Phase 5: Testing (Priority: High)
1. Write unit tests for all DTOs
2. Write integration tests for API calls
3. Write widget tests for error handling
4. Manual testing with Postman collection

## Security Considerations

1. **Token Management**
   - Store JWT tokens securely using flutter_secure_storage
   - Clear tokens on logout
   - Refresh tokens before expiration

2. **Role Validation**
   - Always validate role on client side
   - Trust server-side role enforcement
   - Handle 403 errors gracefully

3. **Input Validation**
   - Validate payment methods before API calls
   - Validate date formats
   - Validate required fields

4. **Error Messages**
   - Don't expose sensitive information in error messages
   - Log detailed errors for debugging
   - Show user-friendly messages to users

## Performance Considerations

1. **Caching**
   - Cache frequently accessed data (profile, fund box)
   - Invalidate cache on updates
   - Use memory cache for session data

2. **Pagination**
   - Use default page size of 15
   - Implement infinite scroll for large lists
   - Cache paginated results

3. **Offline Support**
   - Queue operations when offline
   - Auto-sync when connection restored
   - Show pending sync count to users

## Rollback Plan

If issues arise after deployment:

1. **Immediate Rollback**
   - Revert to previous DTO versions
   - Restore old API data source implementations
   - Clear app cache to prevent data corruption

2. **Partial Rollback**
   - Disable specific features (e.g., admin dashboard)
   - Fall back to local-only mode
   - Show maintenance message to users

3. **Data Recovery**
   - Export local database before migration
   - Provide manual sync option
   - Support data import from backup

# Design Document

## Overview

This design document outlines the architecture for migrating the Flutter finance application from SQLite/Supabase/PocketBase to a Laravel REST API backend. The solution implements a clean architecture pattern with clear separation between data sources, repositories, use cases, and presentation layers, ensuring maintainability and testability.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Application                      │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer (BLoC/UI)                               │
├─────────────────────────────────────────────────────────────┤
│  Domain Layer (Use Cases/Entities)                          │
├─────────────────────────────────────────────────────────────┤
│  Data Layer (Repositories/Data Sources)                     │
│  ┌──────────────────┐  ┌──────────────────┐               │
│  │ API Data Source  │  │ Cache Data Source│               │
│  └──────────────────┘  └──────────────────┘               │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │  HTTP Client  │
                    └───────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Laravel Backend API                       │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Routes → Controllers → Services → Repositories       │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  MySQL Database                                       │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

**Presentation Layer:**
- UI widgets and screens
- BLoC for state management
- User input handling
- Display formatting

**Domain Layer:**
- Business logic use cases
- Entity models
- Repository interfaces
- Business rules validation

**Data Layer:**
- API data source implementation
- Cache management
- Data transformation (DTO ↔ Entity)
- Network request handling

## Components and Interfaces

### 1. API Client Service

**Purpose:** Central HTTP client for all API communication

**Key Features:**
- Base URL configuration
- Request/response interceptors
- Authentication token injection
- Error handling and retry logic
- Request timeout management

**Interface:**
```dart
abstract class ApiClient {
  Future<Response> get(String endpoint, {Map<String, dynamic>? queryParams});
  Future<Response> post(String endpoint, {dynamic body});
  Future<Response> put(String endpoint, {dynamic body});
  Future<Response> delete(String endpoint);
  Future<Response> uploadFile(String endpoint, File file, {Map<String, String>? fields});
}
```

**Implementation Details:**
- Use `dio` package for HTTP requests
- Implement interceptors for token refresh
- Handle 401 responses by triggering re-authentication
- Implement exponential backoff for retries
- Log requests in debug mode only

### 2. Authentication Service

**Purpose:** Manage user authentication and token lifecycle

**Key Features:**
- Register new users
- Login with email/password
- Token storage and retrieval
- Automatic token refresh
- Logout and token revocation

**Interface:**
```dart
abstract class AuthService {
  Future<AuthResult> register(String name, String email, String password);
  Future<AuthResult> login(String email, String password);
  Future<void> logout();
  Future<String?> getToken();
  Future<bool> isAuthenticated();
  Future<User> getCurrentUser();
  Future<void> refreshToken();
}
```

**Token Management:**
- Store tokens in `flutter_secure_storage`
- Implement token expiration checking
- Auto-refresh tokens 5 minutes before expiry
- Clear tokens on logout or 401 errors

### 3. Data Models

**User Model:**
```dart
class User {
  final int id;
  final String name;
  final String email;
  final String role; // 'admin' or 'user'
  final DateTime createdAt;
  
  bool get isAdmin => role == 'admin';
}
```

**Expense Model:**
```dart
class Expense {
  final int? id;
  final String description;
  final double? priceUsd;
  final double? priceSyp;
  final double? priceTry;
  final bool hasInvoice;
  final String? invoicePath;
  final DateTime expenseDate;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum SyncStatus { pending, syncing, synced, failed }
```

**Transfer Model:**
```dart
class Transfer {
  final int? id;
  final String recipientName;
  final double amountUsd;
  final DateTime transferDate;
  final String? notes;
  final Exchange? exchange;
  final DateTime createdAt;
}

class Exchange {
  final int? id;
  final double convertedAmountSyp;
  final double exchangeRateUsdToSyp;
  final DateTime exchangeDate;
}
```

**Incoming Model:**
```dart
class Incoming {
  final int? id;
  final String description;
  final double amountUsd;
  final DateTime incomingDate;
  final DateTime createdAt;
}
```

### 4. Repository Pattern

**Purpose:** Abstract data source implementation from business logic

**Expense Repository:**
```dart
abstract class ExpenseRepository {
  Future<List<Expense>> getExpenses({
    int page = 1,
    int perPage = 15,
    DateTime? startDate,
    DateTime? endDate,
    SyncStatus? syncStatus,
  });
  
  Future<Expense> getExpense(int id);
  Future<Expense> createExpense(Expense expense);
  Future<Expense> updateExpense(Expense expense);
  Future<void> deleteExpense(int id);
  Future<String> uploadInvoice(int expenseId, File file);
  Future<File> downloadInvoice(int expenseId);
  Future<void> deleteInvoice(int expenseId);
}
```

**Implementation Strategy:**
- API data source for remote operations
- Cache data source for offline support
- Repository coordinates between sources
- Implement cache-first strategy for reads
- Queue writes when offline

### 5. Offline Queue System

**Purpose:** Queue operations when offline and sync when online

**Queue Item Model:**
```dart
class QueueItem {
  final String id; // UUID
  final QueueOperation operation;
  final String resourceType; // 'expense', 'transfer', 'incoming'
  final Map<String, dynamic> data;
  final int retryCount;
  final DateTime createdAt;
  final QueueStatus status;
}

enum QueueOperation { create, update, delete }
enum QueueStatus { pending, processing, failed }
```

**Queue Manager:**
```dart
abstract class QueueManager {
  Future<void> enqueue(QueueItem item);
  Future<void> processQueue();
  Future<List<QueueItem>> getPendingItems();
  Future<void> clearQueue();
  Stream<QueueStatus> get queueStatus;
}
```

**Processing Logic:**
- Monitor connectivity changes
- Auto-process queue when online
- Implement exponential backoff for failures
- Batch operations when possible
- Update UI with sync progress

### 6. Cache Management

**Purpose:** Store API responses locally for offline access

**Cache Strategy:**
- Use `hive` for local storage
- Cache GET responses with TTL
- Invalidate cache on mutations
- Implement LRU eviction policy

**Cache Service:**
```dart
abstract class CacheService {
  Future<T?> get<T>(String key);
  Future<void> set<T>(String key, T value, {Duration? ttl});
  Future<void> delete(String key);
  Future<void> clear();
  bool isExpired(String key);
}
```

### 7. File Upload Service

**Purpose:** Handle file uploads with compression and progress tracking

**Features:**
- Image compression before upload
- Progress tracking
- Retry on failure
- Multipart form data encoding

**Interface:**
```dart
abstract class FileUploadService {
  Future<String> uploadFile(
    String endpoint,
    File file, {
    Map<String, String>? fields,
    Function(int sent, int total)? onProgress,
  });
  
  Future<File> downloadFile(String url, {Function(int received, int total)? onProgress});
}
```

### 8. Batch Sync Service

**Purpose:** Synchronize multiple records efficiently

**Batch Request Model:**
```dart
class BatchSyncRequest {
  final List<BatchRecord> records;
}

class BatchRecord {
  final String type; // 'expense', 'transfer', 'incoming'
  final String action; // 'create', 'update', 'delete'
  final int? id;
  final Map<String, dynamic> data;
}
```

**Sync Strategy:**
- Batch up to 50 records per request
- Process responses and update local state
- Handle partial failures gracefully
- Retry failed records individually

## Data Flow

### Authentication Flow

```
User Input (Email/Password)
    ↓
LoginUseCase
    ↓
AuthRepository
    ↓
API Data Source → POST /api/v1/auth/login
    ↓
Store Token (Secure Storage)
    ↓
Update Auth State (BLoC)
    ↓
Navigate to Home
```

### Create Expense Flow (Online)

```
User Input (Expense Data)
    ↓
CreateExpenseUseCase
    ↓
ExpenseRepository
    ↓
API Data Source → POST /api/v1/expenses
    ↓
Update Cache
    ↓
Update UI State (BLoC)
    ↓
Show Success Message
```

### Create Expense Flow (Offline)

```
User Input (Expense Data)
    ↓
CreateExpenseUseCase
    ↓
ExpenseRepository (Detects Offline)
    ↓
Queue Manager → Enqueue Operation
    ↓
Cache Data Source → Store Locally
    ↓
Update UI State (BLoC) with "Pending Sync"
    ↓
[When Online] → Process Queue → Sync to API
```

### File Upload Flow

```
User Selects Image
    ↓
Compress Image (ImageCompression)
    ↓
UploadInvoiceUseCase
    ↓
FileUploadService
    ↓
API Data Source → POST /api/v1/expenses/{id}/invoice
    ↓
Update Expense with Invoice Path
    ↓
Update UI
```

## Error Handling

### Error Types

**Network Errors:**
- Connection timeout
- No internet connection
- DNS resolution failure

**API Errors:**
- 400 Bad Request → Show validation errors
- 401 Unauthorized → Redirect to login
- 403 Forbidden → Show access denied message
- 404 Not Found → Show resource not found
- 422 Validation Error → Show field-specific errors
- 429 Rate Limited → Wait and retry
- 500 Server Error → Show generic error, retry

**Application Errors:**
- Cache corruption → Clear cache, fetch fresh
- Queue processing failure → Retry with backoff
- File upload failure → Retry up to 3 times

### Error Handling Strategy

```dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;
  
  bool get isAuthError => statusCode == 401;
  bool get isValidationError => statusCode == 422;
  bool get isRateLimited => statusCode == 429;
}
```

**Error Recovery:**
- Implement retry logic with exponential backoff
- Show user-friendly error messages
- Log errors for debugging
- Provide manual retry options
- Cache last successful state

## Testing Strategy

### Unit Tests

**Test Coverage:**
- API client methods
- Repository implementations
- Use case business logic
- Data model transformations
- Cache service operations
- Queue manager logic

**Mocking Strategy:**
- Mock HTTP client for API tests
- Mock repositories for use case tests
- Mock data sources for repository tests

### Integration Tests

**Test Scenarios:**
- Complete authentication flow
- CRUD operations for each resource
- Offline queue processing
- File upload/download
- Batch synchronization
- Token refresh mechanism

### Widget Tests

**UI Testing:**
- Login/register forms
- Expense list and detail screens
- Admin dashboard
- Error state displays
- Loading indicators

## Security Considerations

### Token Security

- Store tokens in `flutter_secure_storage`
- Never log tokens
- Clear tokens on logout
- Implement token rotation
- Use HTTPS for all requests

### Data Security

- Validate all user inputs
- Sanitize data before API calls
- Encrypt sensitive cache data
- Implement certificate pinning (optional)
- Clear sensitive data on app background

### API Security

- Include CSRF protection headers
- Validate API responses
- Implement request signing (optional)
- Rate limit client-side requests
- Timeout long-running requests

## Performance Optimization

### Network Optimization

- Implement request debouncing
- Batch multiple operations
- Compress images before upload
- Use pagination for large lists
- Implement incremental loading

### Cache Optimization

- Cache frequently accessed data
- Implement cache warming
- Use memory cache for hot data
- Disk cache for cold data
- Implement cache size limits

### UI Optimization

- Show cached data immediately
- Fetch fresh data in background
- Implement optimistic updates
- Use skeleton loaders
- Lazy load images

## Migration Strategy

### Phase 1: Preparation

1. Set up Laravel backend environment
2. Configure API base URL
3. Add required packages (dio, hive, flutter_secure_storage)
4. Create API client infrastructure

### Phase 2: Authentication

1. Implement auth service
2. Update login/register screens
3. Implement token management
4. Test authentication flow

### Phase 3: Data Migration

1. Export existing SQLite data
2. Create migration script
3. Upload data via batch sync API
4. Verify data integrity

### Phase 4: Feature Migration

1. Migrate expenses module
2. Migrate transfers module
3. Migrate incoming module
4. Migrate admin features
5. Migrate file operations

### Phase 5: Cleanup

1. Remove SQLite dependencies
2. Remove Supabase integration
3. Remove PocketBase integration
4. Update documentation
5. Final testing

### Phase 6: Deployment

1. Test on staging environment
2. Perform user acceptance testing
3. Deploy to production
4. Monitor for issues
5. Provide user support

## Configuration Management

### Environment Configuration

```dart
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  
  static const Duration timeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}
```

### Build Flavors

- **Development:** Local Laravel server
- **Staging:** Staging API server
- **Production:** Production API server

## Monitoring and Logging

### Logging Strategy

- Log all API requests/responses in debug mode
- Log errors with stack traces
- Log queue operations
- Log authentication events
- Never log sensitive data

### Analytics

- Track API response times
- Monitor error rates
- Track offline queue size
- Monitor cache hit rates
- Track user actions

## Rollback Plan

### Rollback Strategy

1. Keep SQLite code in separate branch
2. Maintain data export functionality
3. Document rollback procedure
4. Test rollback process
5. Communicate with users

### Rollback Triggers

- Critical API failures
- Data loss incidents
- Performance degradation
- Security vulnerabilities
- User complaints

## Documentation Requirements

### Code Documentation

- Document all public APIs
- Add inline comments for complex logic
- Create README for each module
- Document error codes
- Provide usage examples

### User Documentation

- Update user guide
- Create migration guide
- Document new features
- Provide troubleshooting guide
- Create FAQ document

## Success Criteria

### Technical Metrics

- 100% feature parity with current app
- < 500ms average API response time
- > 99% API success rate
- < 1% error rate
- Zero data loss during migration

### User Experience Metrics

- Seamless offline experience
- Fast app startup (< 2 seconds)
- Smooth scrolling and navigation
- Clear error messages
- Intuitive UI

### Business Metrics

- Successful migration of all users
- No increase in support tickets
- Positive user feedback
- Stable app performance
- Reduced infrastructure costs

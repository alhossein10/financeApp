# Design Document

## Overview

This document outlines the technical design for a Laravel-based RESTful API backend that serves a dual-version Flutter finance management application. The backend provides secure authentication, comprehensive financial data management, file storage, and synchronization capabilities. The architecture follows Laravel best practices with a clean separation of concerns, utilizing Laravel Sanctum for API authentication, Eloquent ORM for database operations, and Laravel's built-in features for file storage, queuing, and caching.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Mobile Apps                      │
│              (Admin Version + User Version)                  │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTPS/REST API
                         │ (JSON)
┌────────────────────────▼────────────────────────────────────┐
│                   API Gateway Layer                          │
│  - Rate Limiting (60 req/min)                               │
│  - CORS Handling                                            │
│  - Request Validation                                       │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│              Authentication Middleware                       │
│  - Laravel Sanctum Token Validation                         │
│  - Role-Based Access Control (Admin/User)                   │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                  Controller Layer                            │
│  - AuthController                                           │
│  - ExpenseController                                        │
│  - TransferController                                       │
│  - IncomingController                                       │
│  - FundBoxController                                        │
│  - AdminDashboardController                                 │
│  - FileController                                           │
│  - UserProfileController                                    │
│  - ExportController                                         │
│  - AuditLogController                                       │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                   Service Layer                              │
│  - AuthService                                              │
│  - ExpenseService                                           │
│  - TransferService                                          │
│  - IncomingService                                          │
│  - FundBoxService                                           │
│  - FileStorageService                                       │
│  - SyncService                                              │
│  - ExportService                                            │
│  - NotificationService                                      │
│  - AuditLogService                                          │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                 Repository Layer                             │
│  - UserRepository                                           │
│  - ExpenseRepository                                        │
│  - TransferRepository                                       │
│  - IncomingRepository                                       │
│  - FundBoxRepository                                        │
│  - AuditLogRepository                                       │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                    Model Layer                               │
│  - User (Eloquent Model)                                    │
│  - Expense (Eloquent Model)                                 │
│  - Transfer (Eloquent Model)                                │
│  - Exchange (Eloquent Model)                                │
│  - Incoming (Eloquent Model)                                │
│  - FundBox (Eloquent Model)                                 │
│  - AuditLog (Eloquent Model)                                │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                  Database Layer                              │
│  - MySQL/PostgreSQL                                         │
│  - Migrations & Seeders                                     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                External Services                             │
│  - File Storage (AWS S3 / Local)                            │
│  - Email Service (SMTP / Mailgun)                           │
│  - Queue System (Redis / Database)                          │
│  - Cache (Redis / Memcached)                                │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

- **Framework**: Laravel 11.x
- **Authentication**: Laravel Sanctum (API Token Authentication)
- **Database**: MySQL 8.0+ (configured in .env.example as DB_DATABASE=finance_backend)
- **File Storage**: Laravel Storage (Local/S3 via AWS SDK)
- **Queue System**: Laravel Queue (Database driver configured)
- **Cache**: Laravel Cache (Database driver configured)
- **Email**: Laravel Mail (Log driver for development)
- **API Documentation**: OpenAPI 3.0 / Swagger
- **Testing**: PHPUnit

### Design Patterns

1. **Repository Pattern**: Abstracts data access logic from business logic
2. **Service Layer Pattern**: Encapsulates business logic and orchestrates operations
3. **Dependency Injection**: Laravel's service container for loose coupling
4. **Observer Pattern**: Eloquent observers for model events (audit logging, notifications)
5. **Strategy Pattern**: For different export formats (PDF, Excel)
6. **Factory Pattern**: For test data generation

## Components and Interfaces

### 1. Authentication System

#### AuthController
```php
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/logout
POST   /api/v1/auth/refresh
POST   /api/v1/auth/forgot-password
POST   /api/v1/auth/reset-password
GET    /api/v1/auth/me
```

#### AuthService
- `register(array $data): User` - Creates new user with hashed password
- `login(array $credentials): array` - Validates credentials and returns token
- `logout(User $user): void` - Revokes user tokens
- `refreshToken(User $user): string` - Issues new token
- `sendPasswordResetLink(string $email): void` - Sends reset email
- `resetPassword(array $data): bool` - Updates password with token validation

### 2. Expense Management

#### ExpenseController
```php
GET    /api/v1/expenses              # List expenses (paginated)
POST   /api/v1/expenses              # Create expense
GET    /api/v1/expenses/{id}         # Get single expense
PUT    /api/v1/expenses/{id}         # Update expense
DELETE /api/v1/expenses/{id}         # Delete expense (soft delete)
POST   /api/v1/expenses/{id}/invoice # Upload invoice
GET    /api/v1/expenses/{id}/invoice # Download invoice
DELETE /api/v1/expenses/{id}/invoice # Delete invoice
```

#### ExpenseService
- `createExpense(User $user, array $data): Expense`
- `updateExpense(Expense $expense, array $data): Expense`
- `deleteExpense(Expense $expense): bool`
- `getUserExpenses(User $user, array $filters): LengthAwarePaginator`
- `getAllExpenses(array $filters): LengthAwarePaginator` (Admin only)
- `attachInvoice(Expense $expense, UploadedFile $file): string`
- `deleteInvoice(Expense $expense): bool`

### 3. Transfer & Exchange Management

#### TransferController
```php
GET    /api/v1/transfers           # List transfers
POST   /api/v1/transfers           # Create transfer
GET    /api/v1/transfers/{id}      # Get single transfer
PUT    /api/v1/transfers/{id}      # Update transfer
DELETE /api/v1/transfers/{id}      # Delete transfer
POST   /api/v1/transfers/{id}/exchange  # Add exchange to transfer
```

#### TransferService
- `createTransfer(User $user, array $data): Transfer`
- `updateTransfer(Transfer $transfer, array $data): Transfer`
- `deleteTransfer(Transfer $transfer): bool`
- `getUserTransfers(User $user, array $filters): LengthAwarePaginator`
- `addExchange(Transfer $transfer, array $data): Exchange`

### 4. Incoming Funds Management

#### IncomingController
```php
GET    /api/v1/incoming           # List incoming transactions
POST   /api/v1/incoming           # Create incoming
GET    /api/v1/incoming/{id}      # Get single incoming
PUT    /api/v1/incoming/{id}      # Update incoming
DELETE /api/v1/incoming/{id}      # Delete incoming
```

#### IncomingService
- `createIncoming(User $user, array $data): Incoming`
- `updateIncoming(Incoming $incoming, array $data): Incoming`
- `deleteIncoming(Incoming $incoming): bool`
- `getUserIncoming(User $user, array $filters): LengthAwarePaginator`

### 5. Fund Box Management

#### FundBoxController
```php
GET    /api/v1/fund-box           # Get fund box balance (Admin only)
PUT    /api/v1/fund-box           # Update fund box balance (Admin only)
```

#### FundBoxService
- `getFundBox(): FundBox`
- `updateBalance(float $newBalance): FundBox`
- `adjustBalance(float $amount): FundBox` (Add/subtract from current)
- `recalculateBalance(): FundBox` (Recalculate from all transactions)

### 6. Admin Dashboard

#### AdminDashboardController
```php
GET    /api/v1/admin/dashboard/stats        # Overall statistics
GET    /api/v1/admin/dashboard/users        # User activity list
GET    /api/v1/admin/dashboard/expenses     # Expense summaries
GET    /api/v1/admin/dashboard/analytics    # Date-range analytics
```

#### AdminDashboardService
- `getOverallStats(): array`
- `getUserActivityList(): Collection`
- `getExpenseSummaries(array $filters): array`
- `getAnalytics(Carbon $startDate, Carbon $endDate): array`

### 7. File Storage System

#### FileController
```php
POST   /api/v1/files/upload       # Generic file upload
GET    /api/v1/files/{id}         # Download file
DELETE /api/v1/files/{id}         # Delete file
```

#### FileStorageService
- `uploadFile(UploadedFile $file, string $directory): string`
- `compressImage(UploadedFile $file, int $maxWidth = 1920): UploadedFile`
- `deleteFile(string $path): bool`
- `getFileUrl(string $path): string`
- `validateFile(UploadedFile $file): bool`

### 8. Data Synchronization

#### SyncController
```php
POST   /api/v1/sync/batch         # Batch sync multiple records
GET    /api/v1/sync/changes       # Get changes since timestamp
POST   /api/v1/sync/resolve       # Resolve sync conflicts
```

#### SyncService
- `batchSync(User $user, array $records): array`
- `getChangesSince(User $user, Carbon $timestamp): array`
- `resolveConflict(string $strategy, array $clientData, array $serverData): mixed`
- `updateSyncStatus(Model $model, string $status): void`

### 9. User Profile Management

#### UserProfileController
```php
GET    /api/v1/profile            # Get user profile
PUT    /api/v1/profile            # Update profile
PUT    /api/v1/profile/password   # Change password
DELETE /api/v1/profile            # Delete account
```

#### UserProfileService
- `getProfile(User $user): array`
- `updateProfile(User $user, array $data): User`
- `changePassword(User $user, string $currentPassword, string $newPassword): bool`
- `deleteAccount(User $user): bool`

### 10. Data Export System

#### ExportController
```php
POST   /api/v1/export/expenses/pdf    # Export expenses as PDF
POST   /api/v1/export/expenses/excel  # Export expenses as Excel
GET    /api/v1/export/{id}/download   # Download generated export
```

#### ExportService
- `exportExpensesToPDF(User $user, array $filters): string`
- `exportExpensesToExcel(User $user, array $filters): string`
- `generateSystemWideExport(string $format): string` (Admin only)
- `cleanupOldExports(): void` (Delete exports older than 24 hours)

### 11. Audit Logging System

#### AuditLogController
```php
GET    /api/v1/audit-logs         # List audit logs (Admin only)
GET    /api/v1/audit-logs/{id}    # Get single audit log
```

#### AuditLogService
- `logAction(User $user, string $action, string $resourceType, int $resourceId, array $metadata = []): AuditLog`
- `logFailedAuth(string $email, string $ipAddress): void`
- `logDataAccess(User $admin, string $resourceType, int $resourceId): void`
- `getAuditLogs(array $filters): LengthAwarePaginator`

### 12. Notification System

#### NotificationService
- `sendWelcomeEmail(User $user): void`
- `sendPasswordResetEmail(User $user, string $token): void`
- `sendDataModificationAlert(User $user, string $action, string $resource): void`
- `sendSyncFailureAlert(User $user, int $retryCount): void`
- `sendPushNotification(User $user, string $title, string $body): void`

## Data Models

### User Model
```php
- id: bigint (PK)
- name: string
- email: string (unique)
- email_verified_at: timestamp (nullable)
- password: string (hashed)
- role: enum('admin', 'user') default 'user'
- remember_token: string (nullable)
- created_at: timestamp
- updated_at: timestamp
- deleted_at: timestamp (nullable, soft delete)

Relationships:
- hasMany(Expense)
- hasMany(Transfer)
- hasMany(Incoming)
- hasMany(AuditLog)
```

### Expense Model
```php
- id: bigint (PK)
- user_id: bigint (FK -> users.id)
- description: text
- price_usd: decimal(10,2)
- price_syp: decimal(15,2) (nullable)
- price_try: decimal(10,2) (nullable)
- has_invoice: boolean default false
- invoice_path: string (nullable)
- expense_date: date
- sync_status: enum('pending', 'syncing', 'synced', 'failed') default 'synced'
- synced_at: timestamp (nullable)
- sync_retry_count: int default 0
- sync_error_message: text (nullable)
- created_at: timestamp
- updated_at: timestamp
- deleted_at: timestamp (nullable)

Relationships:
- belongsTo(User)

Indexes:
- user_id, expense_date
- sync_status
```

### Transfer Model
```php
- id: bigint (PK)
- user_id: bigint (FK -> users.id)
- recipient_name: string
- amount_usd: decimal(10,2)
- transfer_date: date
- notes: text (nullable)
- sync_status: enum('pending', 'syncing', 'synced', 'failed') default 'synced'
- synced_at: timestamp (nullable)
- created_at: timestamp
- updated_at: timestamp
- deleted_at: timestamp (nullable)

Relationships:
- belongsTo(User)
- hasOne(Exchange)

Indexes:
- user_id, transfer_date
```

### Exchange Model
```php
- id: bigint (PK)
- transfer_id: bigint (FK -> transfers.id, unique)
- converted_amount_syp: decimal(15,2) (nullable)
- converted_amount_try: decimal(10,2) (nullable)
- exchange_rate_usd_to_syp: decimal(10,4) (nullable)
- exchange_rate_usd_to_try: decimal(10,4) (nullable)
- exchange_date: date
- created_at: timestamp
- updated_at: timestamp

Relationships:
- belongsTo(Transfer)

Indexes:
- transfer_id (unique)
```

### Incoming Model
```php
- id: bigint (PK)
- user_id: bigint (FK -> users.id)
- description: text
- amount_usd: decimal(10,2)
- incoming_date: date
- sync_status: enum('pending', 'syncing', 'synced', 'failed') default 'synced'
- synced_at: timestamp (nullable)
- created_at: timestamp
- updated_at: timestamp
- deleted_at: timestamp (nullable)

Relationships:
- belongsTo(User)

Indexes:
- user_id, incoming_date
```

### FundBox Model
```php
- id: bigint (PK) - Always 1 (single row)
- balance_usd: decimal(15,2) default 0.00
- last_calculated_at: timestamp (nullable)
- created_at: timestamp
- updated_at: timestamp

Note: This is a single-row table enforced by application logic
```

### AuditLog Model
```php
- id: bigint (PK)
- user_id: bigint (FK -> users.id, nullable)
- action: string (e.g., 'create', 'update', 'delete', 'view')
- resource_type: string (e.g., 'Expense', 'Transfer')
- resource_id: bigint (nullable)
- ip_address: string (nullable)
- user_agent: text (nullable)
- metadata: json (nullable)
- created_at: timestamp

Relationships:
- belongsTo(User)

Indexes:
- user_id, created_at
- resource_type, resource_id
- action
```

## Error Handling

### HTTP Status Codes
- `200 OK` - Successful GET, PUT requests
- `201 Created` - Successful POST requests
- `204 No Content` - Successful DELETE requests
- `400 Bad Request` - Invalid request data
- `401 Unauthorized` - Missing or invalid authentication
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `409 Conflict` - Sync conflict detected
- `422 Unprocessable Entity` - Validation errors
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server errors

### Error Response Format
```json
{
  "success": false,
  "message": "Human-readable error message",
  "errors": {
    "field_name": ["Validation error message"]
  },
  "error_code": "SPECIFIC_ERROR_CODE",
  "timestamp": "2025-10-21T10:30:00Z"
}
```

### Custom Exception Classes
- `AuthenticationException` - Authentication failures
- `AuthorizationException` - Permission denied
- `ValidationException` - Input validation failures
- `SyncConflictException` - Data synchronization conflicts
- `FileUploadException` - File upload failures
- `RateLimitException` - Rate limit exceeded

### Global Exception Handler
Laravel's exception handler will be customized to:
1. Log all exceptions with context
2. Return consistent JSON error responses
3. Hide sensitive information in production
4. Send critical error notifications to admins
5. Track error rates for monitoring

## Testing Strategy

### Unit Tests
- **Models**: Test relationships, scopes, accessors, mutators
- **Services**: Test business logic in isolation with mocked dependencies
- **Repositories**: Test data access patterns
- **Helpers**: Test utility functions

### Feature Tests
- **Authentication**: Registration, login, logout, password reset flows
- **CRUD Operations**: Create, read, update, delete for all resources
- **Authorization**: Role-based access control enforcement
- **File Uploads**: Invoice upload, compression, retrieval
- **Sync Operations**: Batch sync, conflict resolution
- **Export**: PDF and Excel generation
- **Rate Limiting**: Verify rate limit enforcement

### Integration Tests
- **Database Transactions**: Test complex multi-model operations
- **Queue Jobs**: Test background job execution
- **Email Notifications**: Test email sending (using Mail::fake())
- **File Storage**: Test file operations (using Storage::fake())

### API Tests
- **Endpoint Coverage**: Test all API endpoints with various scenarios
- **Request Validation**: Test validation rules
- **Response Format**: Verify JSON structure and data types
- **Error Handling**: Test error responses

### Test Data
- **Factories**: Laravel factories for all models
- **Seeders**: Test database seeders for development
- **Fixtures**: Sample files for upload testing

### Testing Tools
- PHPUnit for test execution
- Laravel's testing helpers (RefreshDatabase, WithFaker)
- Mockery for mocking dependencies
- Pest (optional, for more expressive syntax)

### Coverage Goals
- Minimum 80% code coverage
- 100% coverage for critical business logic (financial calculations, auth)
- All API endpoints must have feature tests

## Security Considerations

### Authentication & Authorization
- Laravel Sanctum for stateless API token authentication
- Tokens expire after 30 days (configurable)
- Role-based middleware for admin routes
- Policy classes for fine-grained authorization

### Data Protection
- All passwords hashed with bcrypt (BCRYPT_ROUNDS=12 in .env.example)
- Sensitive data encrypted at rest (Laravel encryption)
- HTTPS enforced in production
- CORS configured for Flutter app domains only

### Input Validation
- Form Request classes for all input validation
- SQL injection prevention via Eloquent ORM
- XSS prevention via output escaping
- File upload validation (type, size, content)

### Rate Limiting
- 60 requests per minute per authenticated user
- Separate limits for sensitive operations (login: 5/min)
- IP-based rate limiting for unauthenticated endpoints

### File Security
- File type validation (whitelist: jpg, png, pdf)
- File size limits (10MB max)
- Malware scanning for uploads (ClamAV integration)
- Secure file storage with non-guessable names
- Access control for file downloads

### Audit & Monitoring
- Comprehensive audit logging
- Failed authentication attempt tracking
- Suspicious activity alerts
- Regular security audits

## Performance Optimization

### Database Optimization
- Proper indexing on frequently queried columns
- Eager loading to prevent N+1 queries
- Database query caching for expensive operations
- Pagination for large result sets

### Caching Strategy
- Cache user permissions and roles
- Cache dashboard statistics (5-minute TTL)
- Cache exchange rates (1-hour TTL)
- Cache-aside pattern for frequently accessed data

### File Storage
- Image compression for invoices (max 1920px width)
- CDN integration for file delivery (optional)
- Lazy loading for file listings

### Queue System
- Async processing for email notifications
- Background jobs for export generation
- Delayed jobs for cleanup tasks

### API Response Optimization
- JSON response compression (gzip)
- Selective field loading (sparse fieldsets)
- Batch endpoints to reduce round trips
- ETags for conditional requests

## Deployment Considerations

### Environment Configuration
- Separate .env files for dev, staging, production
- Environment-specific service providers
- Feature flags for gradual rollouts

### Database Migrations
- Version-controlled migrations
- Rollback strategy for failed deployments
- Data seeding for initial setup

### Monitoring & Logging
- Application logging (Laravel Log)
- Error tracking (Sentry/Bugsnag)
- Performance monitoring (New Relic/DataDog)
- Uptime monitoring

### Backup Strategy
- Daily database backups
- File storage backups
- Backup retention policy (30 days)
- Disaster recovery plan

### Scaling Considerations
- Horizontal scaling with load balancer
- Database read replicas for heavy read operations
- Redis for session and cache storage
- Queue workers for background processing

## API Documentation

### OpenAPI Specification
- Complete OpenAPI 3.0 spec for all endpoints
- Interactive documentation via Swagger UI
- Request/response examples
- Authentication documentation

### Versioning Strategy
- URL-based versioning (/api/v1/, /api/v2/)
- Maintain backward compatibility within major versions
- Deprecation notices for old endpoints
- 6-month support window for deprecated versions

### Documentation Hosting
- Swagger UI at /api/documentation
- Postman collection export
- SDK generation support (optional)

## Development Workflow

### Code Standards
- PSR-12 coding standard
- Laravel best practices
- PHPStan level 5 static analysis
- PHP CS Fixer for code formatting

### Git Workflow
- Feature branch workflow
- Pull request reviews required
- Automated CI/CD pipeline
- Semantic versioning for releases

### CI/CD Pipeline
1. Run PHPStan static analysis
2. Run PHP CS Fixer checks
3. Run PHPUnit tests
4. Generate coverage report
5. Deploy to staging (on main branch)
6. Manual approval for production

### Local Development
- Laravel Sail for Docker-based development
- Artisan commands for common tasks
- Database seeding for test data
- Hot reload for rapid development

## Migration from Current State

### Current Laravel Setup Analysis
Based on the provided files:
- Fresh Laravel 11 installation
- Database configured (finance_backend)
- Vite for asset compilation
- Tailwind CSS configured
- Basic user authentication structure in place

### Implementation Phases

**Phase 1: Foundation (Week 1-2)**
- Set up Laravel Sanctum
- Create base models and migrations
- Implement repository pattern
- Set up service layer structure

**Phase 2: Core Features (Week 3-4)**
- Authentication system
- Expense management
- Transfer management
- Incoming funds management

**Phase 3: Advanced Features (Week 5-6)**
- Fund box management
- File storage system
- Admin dashboard
- Sync functionality

**Phase 4: Additional Features (Week 7-8)**
- User profile management
- Data export system
- Audit logging
- Notification system

**Phase 5: Polish & Deploy (Week 9-10)**
- API documentation
- Comprehensive testing
- Performance optimization
- Production deployment

This design provides a solid foundation for building a robust, scalable finance management backend that meets all the requirements specified in the requirements document.

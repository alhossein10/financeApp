# Laravel Backend Integration

## Overview

This specification documents the complete migration of the Flutter finance application from SQLite/Supabase/PocketBase to a Laravel REST API backend. The integration provides centralized data management, robust authentication, role-based access control, and comprehensive offline support.

## Project Status

✅ **Phase 1-12: Complete** - All implementation tasks finished
🔄 **Phase 13: In Progress** - Documentation and deployment preparation

## Quick Links

- [Requirements](requirements.md) - Detailed feature requirements
- [Design](design.md) - Architecture and technical design
- [Tasks](tasks.md) - Implementation task list
- [API Documentation](API_DOCUMENTATION.md) - Complete API reference
- [Manual Testing Guide](MANUAL_TESTING_GUIDE.md) - Testing procedures

## Architecture Overview

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

## Key Features

### ✅ Implemented Features

1. **Authentication & Authorization**
   - User registration and login
   - Laravel Sanctum token authentication
   - Password reset and change
   - Role-based access control (Admin/User)
   - Automatic token refresh

2. **Data Management**
   - Expense tracking with multi-currency support
   - Transfer management with exchange rates
   - Incoming funds tracking
   - Fund box management (Admin only)
   - File upload/download for invoices

3. **Offline Support**
   - Local caching with TTL
   - Offline operation queue
   - Automatic sync when online
   - Conflict resolution
   - Batch synchronization

4. **Admin Features**
   - Dashboard with statistics
   - User activity monitoring
   - Audit logs
   - System-wide data export
   - Fund box management

5. **Performance Optimization**
   - Request debouncing
   - Pagination and lazy loading
   - Memory and disk caching
   - Optimistic updates
   - Skeleton loaders

6. **Error Handling**
   - Comprehensive exception types
   - User-friendly error messages
   - Automatic retry with exponential backoff
   - Rate limiting handling
   - Network error recovery

## Module Documentation

### Core Modules

- [API Module](../../lib/core/api/README.md) - HTTP client and error handling
- [Services Module](../../lib/core/services/README.md) - Business logic services
- [Error Codes](../../lib/core/api/ERROR_CODES.md) - Complete error reference
- [Usage Examples](../../lib/core/USAGE_EXAMPLES.md) - Practical code examples

### Feature Modules

- **Expenses**: Create, read, update, delete expenses with invoice uploads
- **Transfers**: Manage money transfers with exchange rate tracking
- **Incoming**: Track incoming funds
- **Fund Box**: Admin-only fund management
- **Profile**: User profile and settings management
- **Admin**: Dashboard, analytics, and audit logs

## Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Dart 3.0+
- Laravel Backend API (see backend repository)
- MySQL Database

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd finance-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API URL**
   
   Create `.env` file:
   ```
   API_BASE_URL=https://api.example.com/api/v1
   ```

4. **Run the app**
   ```bash
   flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
   ```

### Build Flavors

The app supports multiple build flavors for different environments:

- **Development**: Local API server
  ```bash
  flutter run --flavor dev --dart-define=API_BASE_URL=http://localhost:8000/api/v1
  ```

- **Staging**: Staging API server
  ```bash
  flutter run --flavor staging --dart-define=API_BASE_URL=https://staging-api.example.com/api/v1
  ```

- **Production**: Production API server
  ```bash
  flutter run --flavor prod --dart-define=API_BASE_URL=https://api.example.com/api/v1
  ```

## Configuration

### API Configuration

Edit `lib/core/config/api_config.dart`:

```dart
class ApiConfig {
  // Base URL (from environment)
  static const String apiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  // Retry configuration
  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(seconds: 1);
}
```

### Cache Configuration

Edit `lib/core/services/cache_service.dart`:

```dart
// Default TTL: 24 hours
static const Duration _defaultTTL = Duration(hours: 24);

// Max cache size: 1000 entries
static const int _maxCacheSize = 1000;
```

## Testing

### Run All Tests

```bash
flutter test
```

### Run Specific Test Suites

```bash
# Unit tests
flutter test test/core/
flutter test test/features/

# Integration tests
flutter test test/integration/

# Widget tests
flutter test test/widgets/
```

### Test Coverage

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## API Endpoints

### Authentication

- `POST /auth/register` - Register new user
- `POST /auth/login` - Login user
- `POST /auth/logout` - Logout user
- `GET /auth/me` - Get current user
- `POST /auth/refresh` - Refresh token
- `POST /auth/forgot-password` - Request password reset
- `POST /auth/reset-password` - Reset password

### Expenses

- `GET /expenses` - List expenses (paginated)
- `POST /expenses` - Create expense
- `GET /expenses/{id}` - Get expense details
- `PUT /expenses/{id}` - Update expense
- `DELETE /expenses/{id}` - Delete expense
- `POST /expenses/{id}/invoice` - Upload invoice
- `GET /expenses/{id}/invoice` - Download invoice
- `DELETE /expenses/{id}/invoice` - Delete invoice

### Transfers

- `GET /transfers` - List transfers (paginated)
- `POST /transfers` - Create transfer
- `GET /transfers/{id}` - Get transfer details
- `PUT /transfers/{id}` - Update transfer
- `DELETE /transfers/{id}` - Delete transfer
- `POST /transfers/{id}/exchange` - Add exchange info

### Incoming

- `GET /incoming` - List incoming transactions
- `POST /incoming` - Create incoming transaction
- `PUT /incoming/{id}` - Update incoming transaction
- `DELETE /incoming/{id}` - Delete incoming transaction

### Admin (Admin Only)

- `GET /admin/dashboard/stats` - Dashboard statistics
- `GET /admin/dashboard/users` - User activity
- `GET /admin/dashboard/expenses` - Expense summaries
- `GET /admin/dashboard/analytics` - Analytics data
- `GET /audit-logs` - Audit logs (paginated)
- `GET /fund-box` - Get fund box
- `PUT /fund-box` - Update fund box

### Export

- `POST /export/expenses/pdf` - Export expenses to PDF
- `POST /export/expenses/excel` - Export expenses to Excel
- `GET /export/{id}/status` - Check export status
- `GET /export/{id}/download` - Download export file

### Sync

- `POST /sync/batch` - Batch sync operations
- `POST /sync/resolve` - Resolve conflicts

For complete API documentation, see [API_DOCUMENTATION.md](API_DOCUMENTATION.md).

## Error Handling

The application implements comprehensive error handling with specific exception types:

| Exception | Status Code | Description |
|-----------|-------------|-------------|
| `BadRequestException` | 400 | Invalid request |
| `UnauthorizedException` | 401 | Authentication required |
| `ForbiddenException` | 403 | Insufficient permissions |
| `NotFoundException` | 404 | Resource not found |
| `ValidationException` | 422 | Validation errors |
| `RateLimitException` | 429 | Too many requests |
| `ServerException` | 500-504 | Server errors |
| `NoInternetException` | - | No network connection |

For complete error reference, see [ERROR_CODES.md](../../lib/core/api/ERROR_CODES.md).

## Offline Support

The application provides robust offline support:

1. **Local Caching**: Frequently accessed data is cached locally
2. **Operation Queue**: Operations are queued when offline
3. **Automatic Sync**: Queue is processed when connection is restored
4. **Conflict Resolution**: Handles data conflicts gracefully
5. **Sync Status**: Users are informed of sync progress

## Security

### Authentication

- Laravel Sanctum token-based authentication
- Secure token storage using FlutterSecureStorage
- Automatic token refresh
- Token expiration handling

### Data Security

- HTTPS for all API requests
- Certificate validation
- No sensitive data in logs
- Secure cache encryption (optional)

### Best Practices

- Never log tokens or passwords
- Clear tokens on logout
- Validate all user inputs
- Sanitize data before API calls
- Implement rate limiting client-side

## Performance

### Optimization Strategies

1. **Caching**: Cache-first strategy with background refresh
2. **Pagination**: Load data in chunks (15 items per page)
3. **Lazy Loading**: Load more data on scroll
4. **Debouncing**: Prevent rapid API calls
5. **Batching**: Group multiple operations
6. **Compression**: Compress images before upload
7. **Optimistic Updates**: Update UI before API response

### Performance Metrics

- API response time: < 500ms (target)
- App startup time: < 2 seconds
- Cache hit rate: > 80%
- Offline queue processing: < 5 seconds

## Migration Guide

### From SQLite/Supabase/PocketBase

1. **Export existing data**
   ```dart
   final migrator = DataMigrator();
   await migrator.exportData();
   ```

2. **Upload to Laravel backend**
   ```dart
   await migrator.uploadData();
   ```

3. **Verify data integrity**
   ```dart
   await migrator.verifyData();
   ```

4. **Clear local database**
   ```dart
   await migrator.clearLocalData();
   ```

For detailed migration instructions, see the Migration page in the app.

## Troubleshooting

### Common Issues

**Issue**: "Connection timeout"
- **Solution**: Check network connection and API URL

**Issue**: "Unauthorized" error
- **Solution**: Token expired, log in again

**Issue**: "Validation failed"
- **Solution**: Check input data format

**Issue**: "Too many requests"
- **Solution**: Wait for rate limit to reset

**Issue**: "Offline queue not syncing"
- **Solution**: Check connectivity monitor and queue manager

For more troubleshooting tips, see [Manual Testing Guide](MANUAL_TESTING_GUIDE.md).

## Contributing

### Code Style

- Follow Dart style guide
- Use meaningful variable names
- Add comments for complex logic
- Write tests for new features

### Pull Request Process

1. Create feature branch
2. Implement changes
3. Write tests
4. Update documentation
5. Submit pull request

## Changelog

### Version 2.0.0 (Current)

- ✅ Complete Laravel backend integration
- ✅ Removed SQLite, Supabase, PocketBase
- ✅ Implemented offline support
- ✅ Added role-based access control
- ✅ Comprehensive error handling
- ✅ Performance optimizations
- ✅ Complete test coverage

### Version 1.0.0

- Initial release with SQLite
- Supabase sync support
- PocketBase integration

## License

[Your License Here]

## Support

For support and questions:

- Email: support@example.com
- Documentation: [Link to docs]
- Issue Tracker: [Link to issues]

## Acknowledgments

- Laravel team for the excellent backend framework
- Flutter team for the amazing mobile framework
- All contributors to this project

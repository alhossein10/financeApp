# Audit Logs Quick Reference Guide

## Overview

The Audit Logs feature provides comprehensive tracking of all system activities with role-based access control, filtering, and pagination.

---

## Quick Access

### Navigation
```dart
// From admin dashboard or menu
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AuditLogsPage(),
  ),
);
```

### Access Requirements
- ✅ Admin role required
- ✅ Admin flavor enabled
- ✅ Bearer token authentication

---

## API Endpoints

### 1. Get Audit Logs (Paginated)
```http
GET /api/v1/audit-logs
Authorization: Bearer {token}

Query Parameters:
  - page: 1 (default)
  - per_page: 15 (default)
  - user_id: optional
  - action: optional
  - entity_type: optional
  - start_date: optional (YYYY-MM-DD)
  - end_date: optional (YYYY-MM-DD)
```

**Response**:
```json
{
  "data": [
    {
      "id": 1,
      "user_id": 5,
      "action": "created",
      "entity_type": "expense",
      "entity_id": 123,
      "ip_address": "192.168.1.1",
      "user_agent": "Mozilla/5.0...",
      "created_at": "2024-01-15T10:30:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 15,
    "total": 75
  }
}
```

### 2. Get Audit Log Details
```http
GET /api/v1/audit-logs/{id}
Authorization: Bearer {token}
```

**Response**:
```json
{
  "data": {
    "id": 1,
    "user_id": 5,
    "user_name": "John Doe",
    "action": "updated",
    "entity_type": "expense",
    "entity_id": 123,
    "ip_address": "192.168.1.1",
    "user_agent": "Mozilla/5.0...",
    "changes": {
      "old": {"amount": 100},
      "new": {"amount": 150}
    },
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

---

## Usage Examples

### 1. Fetch Audit Logs with Filters
```dart
// In your BLoC or widget
context.read<AuditLogBloc>().add(
  FetchAuditLogsRequested(
    page: 1,
    perPage: 15,
    userId: 5,
    action: 'created',
    entityType: 'expense',
  ),
);
```

### 2. Load More Logs (Pagination)
```dart
// Triggered automatically on scroll
context.read<AuditLogBloc>().add(
  const LoadMoreAuditLogsRequested(),
);
```

### 3. Refresh Audit Logs
```dart
// Pull-to-refresh or manual refresh
context.read<AuditLogBloc>().add(
  const RefreshAuditLogsRequested(),
);
```

### 4. View Audit Log Details
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AuditLogDetailPage(logId: 123),
  ),
);
```

---

## Filter Options

### User ID Filter
```dart
TextField(
  decoration: InputDecoration(labelText: 'User ID'),
  keyboardType: TextInputType.number,
  onChanged: (value) {
    _selectedUserId = value.isEmpty ? null : int.tryParse(value);
  },
)
```

### Action Filter
Available actions:
- `created` - Resource created
- `updated` - Resource updated
- `deleted` - Resource deleted
- `login` - User login
- `logout` - User logout

### Entity Type Filter
Available types:
- `expense` - Expense records
- `transfer` - Transfer records
- `incoming` - Incoming records
- `user` - User records
- `exchange` - Exchange records

---

## State Management

### States
```dart
// Initial state
AuditLogInitial()

// Loading first page
AuditLogLoading()

// Loading more pages
AuditLogLoadingMore(currentLogs, currentPage)

// Logs loaded successfully
AuditLogLoaded(logs, currentPage, lastPage, total, hasMorePages)

// Log details loaded
AuditLogDetailsLoaded(auditLog)

// Error occurred
AuditLogError(message, requiresLogin: false)
```

### Events
```dart
// Fetch audit logs with filters
FetchAuditLogsRequested(
  page: 1,
  perPage: 15,
  userId: null,
  action: null,
  entityType: null,
  startDate: null,
  endDate: null,
)

// Load more logs (pagination)
LoadMoreAuditLogsRequested()

// Refresh logs
RefreshAuditLogsRequested()

// Fetch log details
FetchAuditLogDetailsRequested(id)
```

---

## UI Components

### Audit Logs List
```dart
// Main page with filters and infinite scroll
AuditLogsPage()
```

**Features**:
- Collapsible filter panel
- Infinite scroll pagination
- Pull-to-refresh
- Loading indicators
- Error handling
- Role-based access control

### Audit Log Detail
```dart
// Detail page for single log
AuditLogDetailPage(logId: 123)
```

**Features**:
- Full log information
- Formatted changes JSON
- User agent details
- IP address tracking

### Audit Log List Item
```dart
// Individual log card in list
_AuditLogListItem(log: log, onTap: () {})
```

**Features**:
- Color-coded action icons
- Entity type and ID
- User information
- Timestamp
- Tap to view details

---

## Access Control

### Flavor-Level Check
```dart
if (!FlavorConfig.instance.enableAuditLogs) {
  return FeatureNotAvailableScreen();
}
```

### Role-Level Check
```dart
if (!context.isAdmin) {
  return AccessDeniedScreen();
}
```

### API-Level Check
```dart
// In BLoC
await _roleService.requireAdminPermission();
```

---

## Error Handling

### 401 Unauthorized
```dart
// Automatic token refresh
// If refresh fails, redirect to login
if (state.requiresLogin) {
  Navigator.pushReplacementNamed(context, '/login');
}
```

### 403 Forbidden
```dart
// Show access denied message
if (state.isForbidden) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Admin privileges required'),
      backgroundColor: Colors.orange,
    ),
  );
}
```

### 404 Not Found
```dart
// Show not found error
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Audit log not found'),
    backgroundColor: Colors.red,
  ),
);
```

### 500 Server Error
```dart
// Show error with retry option
Column(
  children: [
    Icon(Icons.error_outline, color: Colors.red),
    Text(state.message),
    ElevatedButton(
      onPressed: () => context.read<AuditLogBloc>()
          .add(const RefreshAuditLogsRequested()),
      child: Text('Retry'),
    ),
  ],
)
```

---

## Pagination

### Configuration
```dart
final int _perPage = 15; // Logs per page
final double _scrollThreshold = 0.9; // Load more at 90% scroll
```

### Infinite Scroll Implementation
```dart
void _onScroll() {
  if (_isBottom) {
    context.read<AuditLogBloc>().add(
      const LoadMoreAuditLogsRequested(),
    );
  }
}

bool get _isBottom {
  if (!_scrollController.hasClients) return false;
  final maxScroll = _scrollController.position.maxScrollExtent;
  final currentScroll = _scrollController.offset;
  return currentScroll >= (maxScroll * 0.9);
}
```

### Loading Indicator
```dart
// At bottom of list while loading more
if (index >= logs.length) {
  return const Center(
    child: Padding(
      padding: EdgeInsets.all(16.0),
      child: CircularProgressIndicator(),
    ),
  );
}
```

---

## Data Models

### AuditLogDto
```dart
class AuditLogDto {
  final int id;
  final int userId;
  final String? userName;
  final String action;
  final String entityType;
  final int entityId;
  final String ipAddress;
  final String userAgent;
  final Map<String, dynamic>? changes;
  final DateTime createdAt;
}
```

### AuditLogListDto
```dart
class AuditLogListDto {
  final List<AuditLogDto> logs;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;
  
  bool get hasMorePages => currentPage < lastPage;
}
```

---

## Testing

### Manual Testing Checklist
- [ ] Login as admin user
- [ ] Navigate to audit logs page
- [ ] Verify logs are displayed
- [ ] Apply user ID filter
- [ ] Apply action filter
- [ ] Apply entity type filter
- [ ] Clear all filters
- [ ] Scroll to load more logs
- [ ] Pull to refresh
- [ ] Tap log to view details
- [ ] Verify all fields are shown
- [ ] Test as non-admin user
- [ ] Verify access denied message

### Unit Tests
```dart
// Test API datasource
test('getAuditLogs returns logs with Bearer token', () async {
  final result = await datasource.getAuditLogs();
  expect(result.logs, isNotEmpty);
});

// Test DTO serialization
test('AuditLogDto.fromJson creates valid object', () {
  final dto = AuditLogDto.fromJson(json);
  expect(dto.id, equals(1));
});

// Test BLoC
test('FetchAuditLogsRequested emits AuditLogLoaded', () {
  bloc.add(const FetchAuditLogsRequested());
  expectLater(
    bloc.stream,
    emitsInOrder([
      isA<AuditLogLoading>(),
      isA<AuditLogLoaded>(),
    ]),
  );
});
```

---

## Common Issues

### Issue: Logs not loading
**Solution**: Check admin role and Bearer token

### Issue: 403 Forbidden error
**Solution**: Verify user has admin role

### Issue: Infinite scroll not working
**Solution**: Check ScrollController is attached

### Issue: Filters not applying
**Solution**: Verify filter values are passed to BLoC event

---

## Best Practices

1. **Always check admin role** before showing audit logs
2. **Use infinite scroll** for better performance with large datasets
3. **Implement pull-to-refresh** for better UX
4. **Show loading indicators** during API calls
5. **Handle all error cases** with user-friendly messages
6. **Cache filter state** to maintain filters during navigation
7. **Format timestamps** consistently across the app
8. **Use color-coded icons** for different action types

---

## Performance Tips

1. **Pagination**: Load only 15 logs at a time
2. **Lazy loading**: Load more only when needed
3. **Caching**: Cache logs locally to reduce API calls
4. **Debouncing**: Debounce filter inputs to reduce API calls
5. **Efficient rendering**: Use ListView.builder for large lists

---

## Security Considerations

1. **Bearer token**: Always included automatically
2. **Role validation**: Enforced at multiple levels
3. **Sensitive data**: Changes field may contain sensitive information
4. **IP tracking**: Logs include IP address for audit trail
5. **User agent**: Tracks device/browser information

---

## Related Files

### Data Layer
- `lib/features/admin/data/datasources/audit_log_api_datasource.dart`
- `lib/features/admin/data/models/audit_log_dto.dart`
- `lib/features/admin/data/repositories/audit_log_repository_impl.dart`

### Domain Layer
- `lib/features/admin/domain/entities/audit_log.dart`
- `lib/features/admin/domain/repositories/audit_log_repository.dart`
- `lib/features/admin/domain/usecases/get_audit_logs_usecase.dart`
- `lib/features/admin/domain/usecases/get_audit_log_details_usecase.dart`

### Presentation Layer
- `lib/features/admin/presentation/pages/audit_logs_page.dart`
- `lib/features/admin/presentation/pages/audit_log_detail_page.dart`
- `lib/features/admin/presentation/bloc/audit_log_bloc.dart`
- `lib/features/admin/presentation/bloc/audit_log_state.dart`
- `lib/features/admin/presentation/bloc/audit_log_event.dart`

---

## Support

For issues or questions:
1. Check this quick reference guide
2. Review the verification document
3. Check API documentation
4. Test with Postman collection
5. Review error logs

---

**Last Updated**: Task 12 Completion
**Status**: ✅ Production Ready

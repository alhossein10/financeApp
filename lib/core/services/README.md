# Services Module

## Overview

The Services module provides core business logic services for authentication, caching, offline queue management, file uploads, and data synchronization.

## Components

### Laravel Auth Service

Handles user authentication with the Laravel backend using Sanctum tokens.

**Features:**
- User registration
- Login/logout
- Token management
- Password reset
- Password change
- Token refresh
- User profile retrieval

**Usage Example:**

```dart
// Initialize service
final authService = LaravelAuthService(
  apiClient: apiClient,
  tokenManager: tokenManager,
);

// Register new user
try {
  final user = await authService.register(
    name: 'John Doe',
    email: 'john@example.com',
    password: 'SecurePass123!',
  );
  print('Registered: ${user.name}');
} on ValidationException catch (e) {
  print('Validation errors: ${e.getValidationErrors()}');
}

// Login
try {
  final user = await authService.login(
    email: 'john@example.com',
    password: 'SecurePass123!',
  );
  print('Logged in: ${user.name}, Role: ${user.role}');
} on UnauthorizedException {
  print('Invalid credentials');
}

// Check authentication status
final isAuth = await authService.isAuthenticated();
if (isAuth) {
  final user = await authService.getCurrentUser();
  print('Current user: ${user.name}');
}

// Refresh token if needed
if (await authService.needsTokenRefresh()) {
  await authService.refreshToken();
}

// Logout
await authService.logout();
```

**Password Management:**

```dart
// Forgot password
await authService.forgotPassword('john@example.com');
// User receives email with reset link

// Reset password with token from email
await authService.resetPassword(
  token: 'reset-token-from-email',
  email: 'john@example.com',
  password: 'NewSecurePass123!',
);

// Change password (requires authentication)
await authService.changePassword(
  currentPassword: 'OldPassword123!',
  newPassword: 'NewPassword123!',
);
```

---

### Token Manager

Manages authentication tokens with secure storage and expiration tracking.

**Features:**
- Secure token storage using FlutterSecureStorage
- Token expiration checking
- Automatic token refresh detection
- Token type management (Bearer)
- Refresh token support

**Usage Example:**

```dart
// Initialize token manager
final tokenManager = TokenManager();

// Save token after login
await tokenManager.saveToken(
  token: 'eyJ0eXAiOiJKV1QiLCJhbGc...',
  tokenType: 'Bearer',
  expiresAt: DateTime.now().add(Duration(days: 30)),
  refreshToken: 'refresh-token-here',
);

// Get token
final token = await tokenManager.getToken();

// Get authorization header
final authHeader = await tokenManager.getAuthorizationHeader();
// Returns: "Bearer eyJ0eXAiOiJKV1QiLCJhbGc..."

// Check token validity
if (await tokenManager.isTokenValid()) {
  print('Token is valid');
} else {
  print('Token expired or missing');
}

// Check if token needs refresh
if (await tokenManager.willTokenExpireSoon()) {
  // Token expires in less than 5 minutes
  await authService.refreshToken();
}

// Clear tokens on logout
await tokenManager.clearTokens();
```

**Token Lifecycle:**

1. **Login**: Token saved with expiration date
2. **API Requests**: Token automatically injected
3. **Expiration Check**: Before each request
4. **Auto-Refresh**: When token expires in < 5 minutes
5. **Logout**: Token cleared from storage

---

### Cache Service

Local caching with TTL (Time-To-Live) and LRU (Least Recently Used) eviction policy.

**Features:**
- Hive-based local storage
- TTL support for automatic expiration
- LRU eviction when cache is full
- Type-safe get/set operations
- Cache statistics

**Usage Example:**

```dart
// Initialize cache service
final cacheService = CacheServiceImpl();
await cacheService.initialize();

// Cache data with default TTL (24 hours)
await cacheService.set('expenses_page_1', expensesList);

// Cache with custom TTL
await cacheService.set(
  'user_profile',
  userProfile,
  ttl: Duration(hours: 1),
);

// Retrieve cached data
final cachedExpenses = await cacheService.get<List<Expense>>('expenses_page_1');
if (cachedExpenses != null) {
  print('Using cached data');
} else {
  print('Cache miss - fetching from API');
}

// Check if entry is expired
if (cacheService.isExpired('expenses_page_1')) {
  print('Cache expired');
}

// Delete specific entry
await cacheService.delete('expenses_page_1');

// Clear all cache
await cacheService.clear();

// Get cache statistics
final stats = await cacheService.getStatistics();
print('Cache entries: ${stats['totalEntries']}');
print('Utilization: ${stats['utilizationPercent']}%');

// Dispose when done
await cacheService.dispose();
```

**Cache Strategy:**

1. **Cache-First**: Check cache before API call
2. **Background Refresh**: Fetch fresh data while showing cached
3. **Invalidation**: Clear cache on data mutations
4. **LRU Eviction**: Remove least used entries when full

**Configuration:**

- Default TTL: 24 hours
- Max cache size: 1000 entries
- Eviction policy: LRU (Least Recently Used)

---

### Queue Manager

Manages offline operations queue for data synchronization.

**Features:**
- Queue operations when offline
- Automatic processing when online
- Retry with exponential backoff
- Operation status tracking
- Persistent storage

**Usage Example:**

```dart
// Initialize queue manager
final queueManager = QueueManagerImpl(
  cacheService: cacheService,
  connectivityMonitor: connectivityMonitor,
);
await queueManager.initialize();

// Enqueue operation when offline
final queueItem = QueueItem(
  id: uuid.v4(),
  operation: QueueOperation.create,
  resourceType: 'expense',
  data: {
    'description': 'Office supplies',
    'price_usd': 50.00,
    'expense_date': '2024-01-15',
  },
  retryCount: 0,
  createdAt: DateTime.now(),
  status: QueueStatus.pending,
);

await queueManager.enqueue(queueItem);

// Process queue manually
await queueManager.processQueue();

// Get pending items
final pendingItems = await queueManager.getPendingItems();
print('Pending operations: ${pendingItems.length}');

// Listen to queue status
queueManager.queueStatus.listen((status) {
  print('Queue status: $status');
});

// Clear queue
await queueManager.clearQueue();
```

**Queue Processing:**

1. **Enqueue**: Add operation to queue when offline
2. **Monitor**: Watch connectivity changes
3. **Process**: Automatically sync when online
4. **Retry**: Exponential backoff for failures
5. **Update**: Notify UI of sync status

---

### File Upload Service

Handles file uploads with compression and progress tracking.

**Features:**
- Image compression before upload
- Progress tracking
- Retry on failure
- Multipart form data encoding
- File download support

**Usage Example:**

```dart
// Initialize file upload service
final fileUploadService = FileUploadServiceImpl(
  apiClient: apiClient,
);

// Upload file with progress
final filePath = await fileUploadService.uploadFile(
  '/expenses/1/invoice',
  File('/path/to/invoice.jpg'),
  fields: {'description': 'Invoice'},
  onProgress: (sent, total) {
    final progress = (sent / total * 100).toStringAsFixed(2);
    print('Upload progress: $progress%');
  },
);

print('File uploaded: $filePath');

// Download file
final downloadedFile = await fileUploadService.downloadFile(
  'https://api.example.com/files/invoice.jpg',
  onProgress: (received, total) {
    final progress = (received / total * 100).toStringAsFixed(2);
    print('Download progress: $progress%');
  },
);

print('File downloaded to: ${downloadedFile.path}');
```

**Image Compression:**

- Automatically compresses images before upload
- Reduces file size by up to 80%
- Maintains acceptable quality
- Configurable compression level

---

### Batch Sync Service

Synchronizes multiple records in a single API request.

**Features:**
- Batch up to 50 records per request
- Handle partial failures
- Retry failed records individually
- Conflict resolution
- Progress tracking

**Usage Example:**

```dart
// Initialize batch sync service
final batchSyncService = BatchSyncServiceImpl(
  apiClient: apiClient,
);

// Create batch request
final batchRequest = BatchSyncRequest(
  records: [
    BatchRecord(
      type: 'expense',
      action: 'create',
      data: {'description': 'Expense 1', 'price_usd': 50.00},
    ),
    BatchRecord(
      type: 'expense',
      action: 'update',
      id: 123,
      data: {'description': 'Updated expense'},
    ),
    BatchRecord(
      type: 'transfer',
      action: 'delete',
      id: 456,
      data: {},
    ),
  ],
);

// Sync batch
final response = await batchSyncService.syncBatch(batchRequest);

// Process results
for (final result in response.results) {
  if (result.success) {
    print('${result.type} ${result.action}: Success');
  } else {
    print('${result.type} ${result.action}: Failed - ${result.error}');
  }
}
```

**Batch Strategy:**

1. **Collect**: Gather pending operations
2. **Batch**: Group up to 50 records
3. **Sync**: Send batch to API
4. **Process**: Handle results
5. **Retry**: Individually retry failures

---

### Connectivity Monitor

Monitors network connectivity and triggers queue processing.

**Features:**
- Real-time connectivity status
- Stream-based updates
- Automatic queue processing on connect
- Network type detection

**Usage Example:**

```dart
// Initialize connectivity monitor
final connectivityMonitor = ConnectivityMonitorImpl();
await connectivityMonitor.initialize();

// Listen to connectivity changes
connectivityMonitor.connectivityStream.listen((isConnected) {
  if (isConnected) {
    print('Online - processing queue');
    queueManager.processQueue();
  } else {
    print('Offline - queueing operations');
  }
});

// Check current status
final isOnline = await connectivityMonitor.isConnected();
print('Network status: ${isOnline ? 'Online' : 'Offline'}');
```

---

### Role Service

Manages user roles and permissions for role-based access control.

**Features:**
- Role checking (admin/user)
- Permission validation
- Role-based UI rendering
- Admin feature access control

**Usage Example:**

```dart
// Initialize role service
final roleService = RoleService();

// Set user role after login
roleService.setUserRole('admin');

// Check if user is admin
if (roleService.isAdmin()) {
  print('User has admin access');
  // Show admin features
}

// Check if user is regular user
if (roleService.isUser()) {
  print('User has regular access');
  // Hide admin features
}

// Get current role
final role = roleService.getCurrentRole();
print('Current role: $role');
```

---

### Conflict Resolution Service

Handles data conflicts during synchronization.

**Features:**
- Server-wins strategy
- Client-wins strategy
- Manual conflict resolution
- Conflict detection

**Usage Example:**

```dart
// Initialize conflict resolution service
final conflictService = ConflictResolutionServiceImpl(
  apiClient: apiClient,
);

// Resolve conflict with server-wins strategy
final resolved = await conflictService.resolveConflict(
  resourceType: 'expense',
  resourceId: 123,
  localData: localExpense,
  serverData: serverExpense,
  strategy: ConflictResolutionStrategy.serverWins,
);

print('Conflict resolved: ${resolved.description}');
```

---

## Testing

### Unit Tests

```dart
void main() {
  group('LaravelAuthService', () {
    late MockApiClient mockApiClient;
    late MockTokenManager mockTokenManager;
    late LaravelAuthService authService;

    setUp(() {
      mockApiClient = MockApiClient();
      mockTokenManager = MockTokenManager();
      authService = LaravelAuthService(
        apiClient: mockApiClient,
        tokenManager: mockTokenManager,
      );
    });

    test('should register user successfully', () async {
      // Arrange
      when(() => mockApiClient.post(any(), body: any(named: 'body')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: ''),
                data: {
                  'token': 'test-token',
                  'token_type': 'Bearer',
                  'user': {
                    'id': 1,
                    'name': 'John Doe',
                    'email': 'john@example.com',
                    'role': 'user',
                  },
                },
                statusCode: 201,
              ));

      // Act
      final user = await authService.register(
        name: 'John Doe',
        email: 'john@example.com',
        password: 'password',
      );

      // Assert
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      verify(() => mockTokenManager.saveToken(
            token: 'test-token',
            tokenType: 'Bearer',
            expiresAt: any(named: 'expiresAt'),
          )).called(1);
    });
  });
}
```

---

## Best Practices

1. **Initialize services**: Always call `initialize()` before use
2. **Handle errors**: Wrap service calls in try-catch blocks
3. **Dispose properly**: Call `dispose()` when done
4. **Use dependency injection**: Inject services via constructor
5. **Mock for testing**: Use mock implementations in tests
6. **Monitor connectivity**: Always check network status
7. **Queue offline operations**: Never lose user data
8. **Compress files**: Reduce bandwidth usage
9. **Batch operations**: Improve sync efficiency
10. **Secure tokens**: Use secure storage for sensitive data

---

## Dependencies

- `dio`: ^5.0.0 - HTTP client
- `flutter_secure_storage`: ^9.0.0 - Secure storage
- `hive`: ^2.2.3 - Local database
- `hive_flutter`: ^1.1.0 - Hive Flutter integration
- `connectivity_plus`: ^5.0.0 - Network monitoring
- `uuid`: ^4.0.0 - UUID generation

---

## Related Modules

- [API Module](../api/README.md)
- [Data Sources](../../features/README.md)
- [Repositories](../../features/README.md)
- [BLoC](../../features/README.md)

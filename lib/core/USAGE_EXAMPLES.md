# Laravel Backend Integration - Usage Examples

## Overview

This document provides practical usage examples for common scenarios in the Laravel backend integration.

## Table of Contents

1. [Authentication](#authentication)
2. [Expense Management](#expense-management)
3. [Transfer Management](#transfer-management)
4. [Offline Support](#offline-support)
5. [File Uploads](#file-uploads)
6. [Caching](#caching)
7. [Error Handling](#error-handling)
8. [Admin Features](#admin-features)

---

## Authentication

### User Registration

```dart
import 'package:finance_app/core/services/laravel_auth_service.dart';
import 'package:finance_app/core/api/api_exception.dart';

Future<void> registerUser(BuildContext context) async {
  final authService = getIt<LaravelAuthService>();
  
  try {
    final user = await authService.register(
      name: 'John Doe',
      email: 'john@example.com',
      password: 'SecurePass123!',
    );
    
    // Registration successful
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Welcome, ${user.name}!')),
    );
    
    // Navigate to home
    Navigator.pushReplacementNamed(context, '/home');
    
  } on ValidationException catch (e) {
    // Show validation errors
    final errors = e.getValidationErrors();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Validation Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: errors.map((error) => Text(error)).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  } on ApiException catch (e) {
    // Show generic error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.getUserFriendlyMessage())),
    );
  }
}
```


### User Login

```dart
Future<void> loginUser(BuildContext context, String email, String password) async {
  final authService = getIt<LaravelAuthService>();
  
  try {
    final user = await authService.login(
      email: email,
      password: password,
    );
    
    // Login successful
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Welcome back, ${user.name}!')),
    );
    
    // Navigate based on role
    if (user.isAdmin) {
      Navigator.pushReplacementNamed(context, '/admin');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
    
  } on UnauthorizedException catch (e) {
    // Invalid credentials
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Login Failed'),
        content: Text('Invalid email or password'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  } on NoInternetException catch (e) {
    // Offline
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No internet connection')),
    );
  }
}
```

### Password Reset

```dart
// Step 1: Request password reset
Future<void> requestPasswordReset(String email) async {
  final authService = getIt<LaravelAuthService>();
  
  try {
    await authService.forgotPassword(email);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Email Sent'),
        content: Text('Check your email for password reset instructions'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  } on ApiException catch (e) {
    showError(e.getUserFriendlyMessage());
  }
}

// Step 2: Reset password with token
Future<void> resetPassword(String token, String email, String newPassword) async {
  final authService = getIt<LaravelAuthService>();
  
  try {
    await authService.resetPassword(
      token: token,
      email: email,
      password: newPassword,
    );
    
    showSuccess('Password reset successful. Please log in.');
    Navigator.pushReplacementNamed(context, '/login');
  } on ApiException catch (e) {
    showError(e.getUserFriendlyMessage());
  }
}
```

---

## Expense Management

### Create Expense

```dart
Future<void> createExpense(BuildContext context) async {
  final expenseRepository = getIt<ExpenseRepository>();
  
  final expense = Expense(
    description: 'Office supplies',
    priceUsd: 50.00,
    expenseDate: DateTime.now(),
    syncStatus: SyncStatus.pending,
  );
  
  try {
    final createdExpense = await expenseRepository.createExpense(expense);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Expense created successfully')),
    );
    
    // Navigate back to list
    Navigator.pop(context);
    
  } on NoInternetException catch (e) {
    // Queued for later sync
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved offline. Will sync when online.')),
    );
    Navigator.pop(context);
  } on ValidationException catch (e) {
    showValidationErrors(context, e.getValidationErrors());
  }
}
```

### Fetch Expenses with Pagination

```dart
class ExpenseListPage extends StatefulWidget {
  @override
  _ExpenseListPageState createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  final expenseRepository = getIt<ExpenseRepository>();
  final scrollController = ScrollController();
  
  List<Expense> expenses = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  
  @override
  void initState() {
    super.initState();
    loadExpenses();
    scrollController.addListener(_onScroll);
  }
  
  Future<void> loadExpenses() async {
    if (isLoading || !hasMore) return;
    
    setState(() => isLoading = true);
    
    try {
      final newExpenses = await expenseRepository.getExpenses(
        page: currentPage,
        perPage: 15,
      );
      
      setState(() {
        expenses.addAll(newExpenses);
        currentPage++;
        hasMore = newExpenses.length == 15;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      showError('Failed to load expenses');
    }
  }
  
  void _onScroll() {
    if (scrollController.position.pixels >= 
        scrollController.position.maxScrollExtent - 200) {
      loadExpenses();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Expenses')),
      body: ListView.builder(
        controller: scrollController,
        itemCount: expenses.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == expenses.length) {
            return Center(child: CircularProgressIndicator());
          }
          return ExpenseListItem(expense: expenses[index]);
        },
      ),
    );
  }
}
```

### Update Expense

```dart
Future<void> updateExpense(Expense expense) async {
  final expenseRepository = getIt<ExpenseRepository>();
  
  try {
    final updated = await expenseRepository.updateExpense(expense);
    
    showSuccess('Expense updated successfully');
  } on NoInternetException catch (e) {
    showInfo('Saved offline. Will sync when online.');
  } on NotFoundException catch (e) {
    showError('Expense not found. It may have been deleted.');
  }
}
```

---

## Transfer Management

### Create Transfer with Exchange

```dart
Future<void> createTransfer(BuildContext context) async {
  final transferRepository = getIt<TransferRepository>();
  
  final transfer = Transfer(
    recipientName: 'John Doe',
    amountUsd: 100.00,
    transferDate: DateTime.now(),
    notes: 'Monthly payment',
    exchange: Exchange(
      convertedAmountSyp: 450000.00,
      exchangeRateUsdToSyp: 4500.00,
      exchangeDate: DateTime.now(),
    ),
  );
  
  try {
    final created = await transferRepository.createTransfer(transfer);
    
    showSuccess('Transfer created successfully');
    Navigator.pop(context);
  } on ApiException catch (e) {
    showError(e.getUserFriendlyMessage());
  }
}
```

---

## Offline Support

### Queue Operation When Offline

```dart
Future<void> createExpenseOffline(Expense expense) async {
  final queueManager = getIt<QueueManager>();
  final connectivityMonitor = getIt<ConnectivityMonitor>();
  
  // Check if online
  final isOnline = await connectivityMonitor.isConnected();
  
  if (!isOnline) {
    // Queue for later
    final queueItem = QueueItem(
      id: uuid.v4(),
      operation: QueueOperation.create,
      resourceType: 'expense',
      data: expense.toJson(),
      retryCount: 0,
      createdAt: DateTime.now(),
      status: QueueStatus.pending,
    );
    
    await queueManager.enqueue(queueItem);
    
    showInfo('Saved offline. Will sync when online.');
  } else {
    // Create directly
    await expenseRepository.createExpense(expense);
  }
}
```

### Monitor Sync Status

```dart
class SyncStatusWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final queueManager = getIt<QueueManager>();
    
    return StreamBuilder<QueueStatus>(
      stream: queueManager.queueStatus,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }
        
        final status = snapshot.data!;
        
        return Container(
          padding: EdgeInsets.all(8),
          color: _getStatusColor(status),
          child: Row(
            children: [
              Icon(_getStatusIcon(status), size: 16),
              SizedBox(width: 8),
              Text(_getStatusText(status)),
            ],
          ),
        );
      },
    );
  }
  
  Color _getStatusColor(QueueStatus status) {
    switch (status) {
      case QueueStatus.pending:
        return Colors.orange;
      case QueueStatus.processing:
        return Colors.blue;
      case QueueStatus.failed:
        return Colors.red;
      default:
        return Colors.green;
    }
  }
  
  IconData _getStatusIcon(QueueStatus status) {
    switch (status) {
      case QueueStatus.pending:
        return Icons.cloud_upload;
      case QueueStatus.processing:
        return Icons.sync;
      case QueueStatus.failed:
        return Icons.error;
      default:
        return Icons.cloud_done;
    }
  }
  
  String _getStatusText(QueueStatus status) {
    switch (status) {
      case QueueStatus.pending:
        return 'Pending sync';
      case QueueStatus.processing:
        return 'Syncing...';
      case QueueStatus.failed:
        return 'Sync failed';
      default:
        return 'Synced';
    }
  }
}
```

---

## File Uploads

### Upload Invoice Image

```dart
Future<void> uploadInvoice(int expenseId, File imageFile) async {
  final fileUploadService = getIt<FileUploadService>();
  
  try {
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UploadProgressDialog(),
    );
    
    final filePath = await fileUploadService.uploadFile(
      '/expenses/$expenseId/invoice',
      imageFile,
      onProgress: (sent, total) {
        final progress = (sent / total * 100).toStringAsFixed(0);
        // Update progress dialog
        eventBus.fire(UploadProgressEvent(progress));
      },
    );
    
    Navigator.pop(context); // Close progress dialog
    showSuccess('Invoice uploaded successfully');
    
  } on ApiException catch (e) {
    Navigator.pop(context);
    showError(e.getUserFriendlyMessage());
  }
}
```

### Download Invoice

```dart
Future<void> downloadInvoice(String invoiceUrl) async {
  final fileUploadService = getIt<FileUploadService>();
  
  try {
    final file = await fileUploadService.downloadFile(
      invoiceUrl,
      onProgress: (received, total) {
        final progress = (received / total * 100).toStringAsFixed(0);
        print('Download progress: $progress%');
      },
    );
    
    // Open file
    OpenFile.open(file.path);
  } on ApiException catch (e) {
    showError('Failed to download invoice');
  }
}
```

---

## Caching

### Cache-First Strategy

```dart
Future<List<Expense>> getExpensesWithCache() async {
  final cacheService = getIt<CacheService>();
  final expenseRepository = getIt<ExpenseRepository>();
  
  final cacheKey = 'expenses_page_1';
  
  // Try cache first
  final cachedExpenses = await cacheService.get<List<Expense>>(cacheKey);
  
  if (cachedExpenses != null && !cacheService.isExpired(cacheKey)) {
    // Return cached data immediately
    print('Using cached data');
    
    // Fetch fresh data in background
    expenseRepository.getExpenses().then((freshExpenses) {
      cacheService.set(cacheKey, freshExpenses);
    });
    
    return cachedExpenses;
  }
  
  // Cache miss - fetch from API
  final expenses = await expenseRepository.getExpenses();
  
  // Cache for 1 hour
  await cacheService.set(
    cacheKey,
    expenses,
    ttl: Duration(hours: 1),
  );
  
  return expenses;
}
```

### Invalidate Cache on Mutation

```dart
Future<void> createExpenseAndInvalidateCache(Expense expense) async {
  final expenseRepository = getIt<ExpenseRepository>();
  final cacheService = getIt<CacheService>();
  
  // Create expense
  await expenseRepository.createExpense(expense);
  
  // Invalidate all expense caches
  await cacheService.delete('expenses_page_1');
  await cacheService.delete('expenses_page_2');
  // Or clear all
  // await cacheService.clear();
}
```

---

## Error Handling

### Comprehensive Error Handling

```dart
Future<void> performApiOperation() async {
  try {
    final result = await apiClient.post('/expenses', body: data);
    showSuccess('Operation successful');
    
  } on ValidationException catch (e) {
    // Handle validation errors
    final errors = e.getValidationErrors();
    showValidationDialog(errors);
    
  } on UnauthorizedException catch (e) {
    // Session expired - redirect to login
    await tokenManager.clearTokens();
    Navigator.pushReplacementNamed(context, '/login');
    showError('Session expired. Please log in again.');
    
  } on ForbiddenException catch (e) {
    // Insufficient permissions
    showError('You do not have permission to perform this action.');
    
  } on NotFoundException catch (e) {
    // Resource not found
    showError('The requested item was not found.');
    Navigator.pop(context);
    
  } on RateLimitException catch (e) {
    // Rate limited - wait and retry
    final retryAfter = e.getRetryAfterDuration();
    showError('Too many requests. Please wait ${retryAfter?.inSeconds} seconds.');
    
  } on NoInternetException catch (e) {
    // Offline - queue operation
    await queueManager.enqueue(queueItem);
    showInfo('Saved offline. Will sync when online.');
    
  } on ServerException catch (e) {
    // Server error - automatic retry
    showError('Server error. Please try again later.');
    
  } on ApiException catch (e) {
    // Generic API error
    showError(e.getUserFriendlyMessage());
    
  } catch (e) {
    // Unexpected error
    showError('An unexpected error occurred');
    logError(e);
  }
}
```

---

## Admin Features

### Check Admin Access

```dart
class AdminDashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final roleService = getIt<RoleService>();
    
    // Check if user is admin
    if (!roleService.isAdmin()) {
      return Scaffold(
        body: Center(
          child: Text('Access denied. Admin only.'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard')),
      body: AdminDashboardContent(),
    );
  }
}
```

### Fetch Admin Statistics

```dart
Future<void> loadAdminStats() async {
  final adminRepository = getIt<AdminRepository>();
  
  try {
    final stats = await adminRepository.getDashboardStats();
    
    setState(() {
      totalUsers = stats.totalUsers;
      totalExpenses = stats.totalExpenses;
      totalTransfers = stats.totalTransfers;
      fundBoxBalance = stats.fundBoxBalance;
    });
  } on ForbiddenException catch (e) {
    showError('Admin access required');
    Navigator.pop(context);
  }
}
```

### View Audit Logs

```dart
Future<void> loadAuditLogs() async {
  final auditLogRepository = getIt<AuditLogRepository>();
  
  try {
    final logs = await auditLogRepository.getAuditLogs(
      page: 1,
      perPage: 50,
      userId: selectedUserId,
      action: selectedAction,
      startDate: startDate,
      endDate: endDate,
    );
    
    setState(() {
      auditLogs = logs;
    });
  } on ForbiddenException catch (e) {
    showError('Admin access required');
  }
}
```

---

## Best Practices

1. **Always handle exceptions**: Wrap API calls in try-catch
2. **Use specific exceptions**: Catch specific types before generic
3. **Show user-friendly messages**: Use `getUserFriendlyMessage()`
4. **Implement offline support**: Queue operations when offline
5. **Cache frequently accessed data**: Reduce API calls
6. **Invalidate cache on mutations**: Keep data fresh
7. **Show loading indicators**: Provide feedback to users
8. **Implement pagination**: Don't load all data at once
9. **Compress files before upload**: Reduce bandwidth
10. **Monitor sync status**: Keep users informed

---

## Testing Examples

### Mock API Client

```dart
class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late ExpenseRepository expenseRepository;
  
  setUp(() {
    mockApiClient = MockApiClient();
    expenseRepository = ExpenseRepositoryImpl(
      apiDataSource: ExpenseApiDataSource(apiClient: mockApiClient),
      cacheDataSource: mockCacheDataSource,
    );
  });
  
  test('should create expense successfully', () async {
    // Arrange
    when(() => mockApiClient.post(any(), body: any(named: 'body')))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'id': 1,
                'description': 'Test expense',
                'price_usd': 50.00,
              },
              statusCode: 201,
            ));
    
    // Act
    final expense = Expense(
      description: 'Test expense',
      priceUsd: 50.00,
      expenseDate: DateTime.now(),
    );
    final result = await expenseRepository.createExpense(expense);
    
    // Assert
    expect(result.id, 1);
    expect(result.description, 'Test expense');
    verify(() => mockApiClient.post('/expenses', body: any(named: 'body')))
        .called(1);
  });
}
```

---

For more examples, see:
- [API Module README](api/README.md)
- [Services Module README](services/README.md)
- [Error Codes Reference](api/ERROR_CODES.md)

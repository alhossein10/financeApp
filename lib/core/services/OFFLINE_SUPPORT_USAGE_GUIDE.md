# Offline Support Usage Guide

This guide explains how to use the offline support functionality in the multi-flavor application.

## Overview

The offline support system provides:
- **Local caching** of financial box balances, expenses, transfers, and user profile data
- **Operation queuing** for create/update operations when offline
- **Automatic syncing** when connection restores
- **Offline indicators** to inform users of connectivity status
- **Balance operation prevention** when offline (requires real-time verification)

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   OfflineManager                         │
│  (Central coordinator for offline functionality)         │
└─────────────────┬───────────────────────────────────────┘
                  │
        ┌─────────┴─────────┬─────────────────┐
        │                   │                 │
┌───────▼────────┐  ┌──────▼──────┐  ┌──────▼──────────┐
│OfflineCache    │  │ Operation   │  │ Connectivity    │
│Service         │  │ Queue       │  │ Service         │
└────────────────┘  └─────────────┘  └─────────────────┘
```

## Components

### 1. OfflineCacheService

Handles caching of data for offline access.

```dart
// Initialize
final cacheService = OfflineCacheService();
await cacheService.initialize();

// Cache fund box
await cacheService.cacheFundBox(userId, fundBoxDto);

// Get cached fund box
final cachedFundBox = await cacheService.getCachedFundBox(userId);

// Cache expenses
await cacheService.cacheExpenses(userId, expensesList);

// Get cached expenses
final cachedExpenses = await cacheService.getCachedExpenses(userId);

// Get cache timestamp
final timestamp = cacheService.getFundBoxCacheTimestamp(userId);
```

### 2. OfflineOperationQueue

Manages queuing and syncing of operations when offline.

```dart
// Initialize
final operationQueue = OfflineOperationQueue(
  queueManager: queueManager,
  connectivityService: connectivityService,
  expenseApi: expenseApi,
  transferApi: transferApi,
  fundBoxApi: fundBoxApi,
);
await operationQueue.initialize();

// Queue operations
await operationQueue.queueExpenseCreation(expenseDto);
await operationQueue.queueTransferCreation(transferDto);

// Sync queue (happens automatically when online)
await operationQueue.syncQueue();

// Listen to sync status
operationQueue.syncStatusStream.listen((status) {
  print('Sync status: ${status.displayText}');
});

// Get statistics
final stats = await operationQueue.getStatistics();
print('Pending: ${stats['pending']}, Failed: ${stats['failed']}');
```

### 3. OfflineManager

Central coordinator that ties everything together.

```dart
// Initialize
final offlineManager = OfflineManager(
  connectivityService: connectivityService,
  cacheService: cacheService,
  operationQueue: operationQueue,
);
await offlineManager.initialize();

// Check connectivity
if (offlineManager.isOffline) {
  print('Currently offline');
}

// Cache data
await offlineManager.cacheFundBox(userId, fundBoxDto);
await offlineManager.cacheExpenses(userId, expensesList);

// Get cached data
final cachedFundBox = await offlineManager.getCachedFundBox(userId);
final cachedExpenses = await offlineManager.getCachedExpenses(userId);

// Queue operations
await offlineManager.queueExpenseCreation(expenseDto);

// Check if balance operations are allowed
if (!offlineManager.canPerformBalanceOperation()) {
  final reason = offlineManager.getBalanceOperationBlockReason();
  print(reason); // "Cannot perform this operation offline..."
}

// Get statistics
final stats = await offlineManager.getStatistics();
```

### 4. OfflineIndicator Widget

Displays connectivity status to users.

```dart
// In your scaffold
Scaffold(
  body: Column(
    children: [
      // Offline indicator banner
      OfflineIndicator(
        connectivityService: connectivityService,
        operationQueue: operationQueue,
        showSyncStatus: true,
      ),
      // Your content
      Expanded(child: YourContent()),
    ],
  ),
)
```

### 5. CachedDataIndicator Widget

Shows when displaying cached data.

```dart
// Show cached data indicator
CachedDataIndicator(
  cacheTimestamp: offlineManager.getFundBoxCacheTimestamp(userId),
  isOffline: offlineManager.isOffline,
)
```

### 6. OfflineAwareMixin

Mixin for widgets that need offline awareness.

```dart
class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with OfflineAwareMixin {
  @override
  void initState() {
    super.initState();
    
    // Initialize offline awareness
    initOfflineAwareness(
      connectivityService: getIt<ConnectivityService>(),
      operationQueue: getIt<OfflineOperationQueue>(),
    );
  }

  @override
  void onConnectivityChanged(ConnectivityStatus status) {
    if (status.isOnline) {
      // Refresh data when coming online
      _refreshData();
    }
  }

  void _createExpense() {
    // Check if balance operation is allowed
    if (!canPerformBalanceOperation(context)) {
      return; // Shows error message automatically
    }
    
    // Proceed with expense creation
    // ...
  }

  void _saveOffline() {
    // Queue operation for offline
    showOperationQueuedMessage(context);
    // ...
  }
}
```

## Usage Patterns

### Pattern 1: Fetch with Cache Fallback

```dart
Future<FundBoxDto?> getFundBox(String userId) async {
  if (offlineManager.isOnline) {
    try {
      // Fetch from API
      final fundBox = await fundBoxApi.getFundBox(userId);
      
      // Cache for offline use
      await offlineManager.cacheFundBox(userId, fundBox);
      
      return fundBox;
    } catch (e) {
      // Fall back to cache on error
      return await offlineManager.getCachedFundBox(userId);
    }
  } else {
    // Use cached data when offline
    return await offlineManager.getCachedFundBox(userId);
  }
}
```

### Pattern 2: Create with Queue

```dart
Future<void> createExpense(ExpenseDto expense) async {
  if (offlineManager.isOnline) {
    // Create directly when online
    await expenseApi.createExpense(expense);
    
    // Update cache
    await offlineManager.cacheExpenses(userId, updatedList);
  } else {
    // Queue for later when offline
    await offlineManager.queueExpenseCreation(expense);
    
    // Update cache optimistically
    await offlineManager.cacheExpenses(userId, updatedList);
    
    // Show queued message
    showOperationQueuedMessage(context);
  }
}
```

### Pattern 3: Balance-Dependent Operations

```dart
Future<void> createTransfer(TransferDto transfer) async {
  // Check if operation is allowed (requires online for balance verification)
  if (!offlineManager.canPerformBalanceOperation()) {
    throw Exception(offlineManager.getBalanceOperationBlockReason());
  }
  
  // Proceed with transfer creation
  await transferApi.createTransfer(transfer);
}
```

### Pattern 4: Display Cached Data with Indicator

```dart
Widget build(BuildContext context) {
  return FutureBuilder<FundBoxDto?>(
    future: getFundBox(userId),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return Column(
          children: [
            // Show cached data indicator if offline
            if (offlineManager.isOffline)
              CachedDataIndicator(
                cacheTimestamp: offlineManager.getFundBoxCacheTimestamp(userId),
                isOffline: true,
              ),
            // Display data
            FundBoxCard(fundBox: snapshot.data!),
          ],
        );
      }
      return CircularProgressIndicator();
    },
  );
}
```

## Integration with Dependency Injection

```dart
// In injection_container.dart

// Register services
sl.registerLazySingleton<ConnectivityService>(
  () => ConnectivityService(connectivity: Connectivity()),
);

sl.registerLazySingleton<OfflineCacheService>(
  () => OfflineCacheService(),
);

sl.registerLazySingleton<QueueManager>(
  () => QueueManagerImpl(),
);

sl.registerLazySingleton<OfflineOperationQueue>(
  () => OfflineOperationQueue(
    queueManager: sl<QueueManager>(),
    connectivityService: sl<ConnectivityService>(),
    expenseApi: sl<ExpenseApiDataSource>(),
    transferApi: sl<TransferApiDataSource>(),
    fundBoxApi: sl<FundBoxApiDataSource>(),
  ),
);

sl.registerLazySingleton<OfflineManager>(
  () => OfflineManager(
    connectivityService: sl<ConnectivityService>(),
    cacheService: sl<OfflineCacheService>(),
    operationQueue: sl<OfflineOperationQueue>(),
  ),
);

// Initialize in main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDependencies();
  
  // Initialize offline support
  final connectivityService = sl<ConnectivityService>();
  await connectivityService.initialize();
  
  final offlineManager = sl<OfflineManager>();
  await offlineManager.initialize();
  
  runApp(MyApp());
}
```

## Best Practices

1. **Always cache data after successful API calls**
   ```dart
   final data = await api.getData();
   await offlineManager.cacheData(userId, data);
   ```

2. **Check connectivity before balance operations**
   ```dart
   if (!offlineManager.canPerformBalanceOperation()) {
     // Show error and return
     return;
   }
   ```

3. **Show appropriate indicators**
   - Use `OfflineIndicator` at the top of screens
   - Use `CachedDataIndicator` when showing cached data
   - Show queued messages when operations are queued

4. **Handle sync status**
   ```dart
   operationQueue.syncStatusStream.listen((status) {
     if (status.isFailed) {
       // Show retry option
     }
   });
   ```

5. **Clear cache on logout**
   ```dart
   await offlineManager.clearUserCache(userId);
   ```

## Testing

```dart
// Mock offline manager for testing
class MockOfflineManager extends Mock implements OfflineManager {}

// Test offline behavior
test('should use cached data when offline', () async {
  when(mockOfflineManager.isOffline).thenReturn(true);
  when(mockOfflineManager.getCachedFundBox(any))
      .thenAnswer((_) async => testFundBox);
  
  final result = await repository.getFundBox(userId);
  
  expect(result, equals(testFundBox));
  verify(mockOfflineManager.getCachedFundBox(userId));
});
```

## Troubleshooting

### Issue: Data not syncing when online

**Solution**: Check if operations are in failed state
```dart
final failedCount = await offlineManager.getFailedOperationsCount();
if (failedCount > 0) {
  await offlineManager.retryFailedOperations();
}
```

### Issue: Cache not updating

**Solution**: Ensure you're caching after API calls
```dart
final data = await api.getData();
await offlineManager.cacheData(userId, data); // Don't forget this!
```

### Issue: Balance operations blocked offline

**Solution**: This is expected behavior. Balance operations require real-time verification and cannot be performed offline.

## Requirements Coverage

This implementation covers:
- ✅ Requirement 27.1: Cache financial box balances
- ✅ Requirement 27.2: Cache expenses list
- ✅ Requirement 27.3: Cache transfers list
- ✅ Requirement 27.4: Queue create/update operations
- ✅ Requirement 27.5: Sync automatically when connection restores
- ✅ Requirement 27.6: Display offline indicator
- ✅ Requirement 27.7: Prevent balance operations when offline
- ✅ Requirement 27.8: Retry with exponential backoff


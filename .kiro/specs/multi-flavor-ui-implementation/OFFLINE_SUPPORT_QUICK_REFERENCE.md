# Offline Support - Quick Reference

## Quick Start

### 1. Initialize Services

```dart
// In main.dart
final connectivityService = sl<ConnectivityService>();
await connectivityService.initialize();

final offlineManager = sl<OfflineManager>();
await offlineManager.initialize();
```

### 2. Add Offline Indicator to UI

```dart
Scaffold(
  body: Column(
    children: [
      OfflineIndicator(
        connectivityService: getIt<ConnectivityService>(),
        operationQueue: getIt<OfflineOperationQueue>(),
      ),
      Expanded(child: YourContent()),
    ],
  ),
)
```

### 3. Use Offline-Aware Mixin

```dart
class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with OfflineAwareMixin {
  @override
  void initState() {
    super.initState();
    initOfflineAwareness(
      connectivityService: getIt<ConnectivityService>(),
      operationQueue: getIt<OfflineOperationQueue>(),
    );
  }
}
```

## Common Patterns

### Fetch with Cache Fallback

```dart
Future<T> fetchData() async {
  if (offlineManager.isOnline) {
    try {
      final data = await api.getData();
      await offlineManager.cacheData(userId, data);
      return data;
    } catch (e) {
      return await offlineManager.getCachedData(userId);
    }
  } else {
    return await offlineManager.getCachedData(userId);
  }
}
```

### Create with Queue

```dart
Future<void> createItem(Item item) async {
  if (offlineManager.isOnline) {
    await api.createItem(item);
  } else {
    await offlineManager.queueItemCreation(item);
    showOperationQueuedMessage(context);
  }
}
```

### Balance Operation Check

```dart
void performBalanceOperation() {
  if (!canPerformBalanceOperation(context)) {
    return; // Error shown automatically
  }
  // Proceed with operation
}
```

### Show Cached Data

```dart
Column(
  children: [
    if (offlineManager.isOffline)
      CachedDataIndicator(
        cacheTimestamp: offlineManager.getDataCacheTimestamp(userId),
        isOffline: true,
      ),
    DataDisplay(data: data),
  ],
)
```

## Key Services

### OfflineManager

```dart
// Connectivity
offlineManager.isOnline
offlineManager.isOffline

// Caching
await offlineManager.cacheFundBox(userId, fundBox);
await offlineManager.cacheExpenses(userId, expenses);
await offlineManager.cacheTransfers(userId, transfers);

// Queuing
await offlineManager.queueExpenseCreation(expense);
await offlineManager.queueTransferCreation(transfer);

// Balance operations
offlineManager.canPerformBalanceOperation()
offlineManager.getBalanceOperationBlockReason()
```

### OfflineAwareMixin Methods

```dart
// Properties
isOffline
isOnline

// Methods
showOfflineMessage(context)
showOperationQueuedMessage(context)
canPerformBalanceOperation(context)
onConnectivityChanged(status) // Override this
```

## Widgets

### OfflineIndicator
```dart
OfflineIndicator(
  connectivityService: connectivityService,
  operationQueue: operationQueue,
  showSyncStatus: true,
)
```

### CachedDataIndicator
```dart
CachedDataIndicator(
  cacheTimestamp: timestamp,
  isOffline: isOffline,
)
```

## Sync Status

```dart
operationQueue.syncStatusStream.listen((status) {
  switch (status) {
    case OfflineSyncStatus.synced:
      // All synced
      break;
    case OfflineSyncStatus.syncing:
      // Currently syncing
      break;
    case OfflineSyncStatus.offline:
      // Device offline
      break;
    case OfflineSyncStatus.failed:
      // Sync failed
      break;
    case OfflineSyncStatus.partialSync:
      // Some synced
      break;
    case OfflineSyncStatus.queued:
      // Operations queued
      break;
  }
});
```

## Statistics

```dart
final stats = await offlineManager.getStatistics();
// Returns:
// {
//   'isOnline': true/false,
//   'cache': {
//     'fundBoxEntries': 1,
//     'expensesEntries': 5,
//     'transfersEntries': 3,
//     'totalEntries': 9
//   },
//   'queue': {
//     'total': 2,
//     'pending': 1,
//     'processing': 0,
//     'failed': 1
//   }
// }
```

## Cleanup

```dart
// Clear user cache on logout
await offlineManager.clearUserCache(userId);

// Clear all cache
await offlineManager.clearAllCache();

// Dispose on app close
await offlineManager.dispose();
```

## Requirements Covered

✅ 27.1: Cache financial box balances  
✅ 27.2: Cache expenses list  
✅ 27.3: Cache transfers list  
✅ 27.4: Queue operations when offline  
✅ 27.5: Auto-sync when online  
✅ 27.6: Display offline indicator  
✅ 27.7: Prevent balance operations offline  
✅ 27.8: Exponential backoff retry  

## Files

- `lib/core/services/offline_cache_service.dart`
- `lib/core/services/offline_operation_queue.dart`
- `lib/core/services/offline_manager.dart`
- `lib/core/widgets/offline_indicator.dart`
- `lib/core/services/OFFLINE_SUPPORT_USAGE_GUIDE.md`


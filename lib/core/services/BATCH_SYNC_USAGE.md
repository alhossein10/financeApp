# Batch Sync Service Usage Guide

This guide explains how to use the `BatchSyncService` to synchronize offline changes with the Laravel backend.

## Overview

The `BatchSyncService` implements the Laravel API specification for data synchronization:
- **POST /sync/batch** - Upload offline changes to server
- **GET /sync/changes** - Download server changes since last sync

## Basic Usage

### 1. Initialize the Service

```dart
final apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);
final batchSyncService = BatchSyncService(apiClient: apiClient);
```

### 2. Sync Offline Changes

```dart
// Prepare offline data
final offlineExpenses = [
  {
    'local_id': 'temp-1',
    'amount': 50.0,
    'category': 'Food',
    'description': 'Lunch',
    'date': '2024-10-23',
    'payment_method': 'cash',
  },
];

final data = SyncDataDto(
  expenses: offlineExpenses,
  incoming: [],
  transfers: [],
);

// Sync with server
final lastSync = DateTime.now().subtract(Duration(hours: 1));
final response = await batchSyncService.batchSync(
  lastSync: lastSync,
  data: data,
);

// Handle response
if (response.hasConflicts) {
  // Show conflict resolution UI
  for (final conflict in response.allConflicts) {
    print('Conflict: ${conflict.reason}');
  }
} else {
  // Update local database with server IDs
  for (final created in response.expenses.created) {
    print('Created: ${created.localId} -> ${created.serverId}');
  }
}
```

### 3. Get Changes from Server

```dart
final since = DateTime.now().subtract(Duration(hours: 1));
final changes = await batchSyncService.getChanges(since: since);

// Process changes
for (final expense in changes.changes.expenses.created) {
  // Insert into local database
  print('New expense from server: ${expense['id']}');
}

for (final expenseId in changes.changes.expenses.deleted) {
  // Delete from local database
  print('Deleted expense: $expenseId');
}
```

### 4. Full Sync (Push + Pull)

```dart
final lastSync = await getLastSyncTime(); // From local storage
final localChanges = await getOfflineChanges(); // From local database

final result = await batchSyncService.fullSync(
  lastSync: lastSync,
  localChanges: localChanges,
);

if (result.success) {
  print('Sync completed successfully');
  print('Created: ${result.totalCreated}');
  print('Conflicts: ${result.totalConflicts}');
  print('Server changes: ${result.totalChangesFromServer}');
  
  // Save new sync time
  await saveLastSyncTime(result.pushResponse!.syncedAt);
} else {
  print('Sync failed: ${result.error}');
}
```

## Handling Conflicts

When conflicts occur, you need to resolve them using the conflict resolution UI:

```dart
if (response.hasConflicts) {
  for (final conflict in response.expenses.conflicts) {
    // Show conflict resolution dialog
    final strategy = await showConflictDialog(
      context: context,
      conflict: conflict,
      entityType: 'expense',
    );
    
    // Resolve conflict
    await conflictResolutionService.resolveConflict(
      conflict,
      strategy,
    );
  }
}
```

## Conflict Resolution Dialog

```dart
showDialog(
  context: context,
  builder: (context) => ConflictResolutionDialog(
    conflict: conflictItem,
    entityType: 'expense',
    onResolve: (strategy, data) {
      // Handle resolution
      if (strategy == ConflictStrategy.serverWins) {
        // Use server data
      } else if (strategy == ConflictStrategy.clientWins) {
        // Use local data
      }
    },
  ),
);
```

## Best Practices

### 1. Sync Frequency

```dart
// Sync every 5 minutes when online
Timer.periodic(Duration(minutes: 5), (timer) async {
  if (await connectivityService.isOnline()) {
    await performSync();
  }
});
```

### 2. Batch Size

The service automatically handles large batches by splitting them:

```dart
// No need to manually split - service handles it
final largeData = SyncDataDto(
  expenses: List.generate(100, (i) => {...}), // 100 expenses
);

// Service will split into batches of 50
final response = await batchSyncService.batchSync(
  lastSync: lastSync,
  data: largeData,
);
```

### 3. Error Handling

```dart
try {
  final response = await batchSyncService.batchSync(
    lastSync: lastSync,
    data: data,
  );
  
  // Success
} on ApiException catch (e) {
  if (e.isUnauthorized) {
    // Redirect to login
  } else if (e.isValidationError) {
    // Show validation errors
    print(e.userFriendlyMessage);
  } else {
    // Show generic error
    print('Sync failed: ${e.message}');
  }
} catch (e) {
  // Network error or other issue
  print('Unexpected error: $e');
}
```

### 4. Offline Queue Integration

```dart
class SyncManager {
  final BatchSyncService batchSyncService;
  final QueueManager queueManager;
  
  Future<void> syncOfflineQueue() async {
    // Get all queued items
    final queuedItems = await queueManager.getAllItems();
    
    // Group by entity type
    final expenses = queuedItems
        .where((item) => item.type == 'expense')
        .map((item) => item.data)
        .toList();
    
    final incoming = queuedItems
        .where((item) => item.type == 'incoming')
        .map((item) => item.data)
        .toList();
    
    final transfers = queuedItems
        .where((item) => item.type == 'transfer')
        .map((item) => item.data)
        .toList();
    
    // Sync all at once
    final data = SyncDataDto(
      expenses: expenses,
      incoming: incoming,
      transfers: transfers,
    );
    
    final lastSync = await getLastSyncTime();
    final response = await batchSyncService.batchSync(
      lastSync: lastSync,
      data: data,
    );
    
    // Update local database with server IDs
    for (final created in response.expenses.created) {
      await updateLocalId(created.localId, created.serverId);
      await queueManager.removeItem(created.localId);
    }
    
    // Handle conflicts
    if (response.hasConflicts) {
      await handleConflicts(response.allConflicts);
    }
  }
}
```

## API Request/Response Format

### Request Format (POST /sync/batch)

```json
{
  "last_sync": "2024-10-23T09:00:00.000000Z",
  "data": {
    "expenses": [
      {
        "local_id": "temp-1",
        "amount": 50.0,
        "category": "Food",
        "date": "2024-10-23",
        "payment_method": "cash"
      }
    ],
    "incoming": [],
    "transfers": []
  }
}
```

### Response Format

```json
{
  "success": true,
  "data": {
    "synced_at": "2024-10-23T10:00:00.000000Z",
    "expenses": {
      "created": [
        {
          "local_id": "temp-1",
          "server_id": 456,
          "data": {
            "id": 456,
            "amount": 50.0,
            "category": "Food"
          }
        }
      ],
      "conflicts": []
    },
    "incoming": {
      "created": [],
      "conflicts": []
    },
    "transfers": {
      "created": [],
      "conflicts": []
    }
  }
}
```

### Changes Request (GET /sync/changes)

```
GET /sync/changes?since=2024-10-23T09:00:00.000000Z
```

### Changes Response

```json
{
  "success": true,
  "data": {
    "timestamp": "2024-10-23T10:00:00.000000Z",
    "changes": {
      "expenses": {
        "created": [
          {
            "id": 456,
            "amount": 50.0,
            "created_at": "2024-10-23T09:30:00.000000Z"
          }
        ],
        "updated": [],
        "deleted": [123]
      },
      "incoming": {
        "created": [],
        "updated": [],
        "deleted": []
      },
      "transfers": {
        "created": [],
        "updated": [],
        "deleted": []
      }
    }
  }
}
```

## Testing

Run the tests:

```bash
# Unit tests
flutter test test/core/models/sync_request_dto_test.dart
flutter test test/core/models/sync_response_dto_test.dart
flutter test test/core/models/sync_changes_dto_test.dart
flutter test test/core/services/batch_sync_service_test.dart

# Integration tests (requires running backend)
flutter test test/integration/batch_sync_offline_test.dart
```

## Troubleshooting

### Issue: Conflicts not resolving

**Solution:** Make sure you're calling the conflict resolution service after detecting conflicts:

```dart
if (response.hasConflicts) {
  for (final conflict in response.allConflicts) {
    await conflictResolutionService.resolveConflict(
      conflict,
      ConflictStrategy.serverWins,
    );
  }
}
```

### Issue: Local IDs not mapping to server IDs

**Solution:** Update your local database after successful sync:

```dart
for (final created in response.expenses.created) {
  await database.updateExpenseId(
    localId: created.localId,
    serverId: created.serverId,
  );
}
```

### Issue: Sync taking too long

**Solution:** The service automatically batches large requests. Check your network connection and consider syncing less frequently.

## See Also

- [Queue Manager Documentation](./queue_manager.dart)
- [Conflict Resolution Service](./conflict_resolution_service.dart)
- [API Client Documentation](../api/README.md)

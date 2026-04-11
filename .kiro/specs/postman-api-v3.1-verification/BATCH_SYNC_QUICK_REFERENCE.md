# Batch Sync Quick Reference

## Overview

Quick reference for using the batch synchronization features in the Finance App.

---

## Key Classes

### BatchSyncService
Main service for batch operations
```dart
final service = BatchSyncService(apiClient);
```

### ConflictResolutionService
Service for handling sync conflicts
```dart
final service = ConflictResolutionService(apiClient);
```

---

## Common Operations

### 1. Batch Sync Offline Changes

```dart
// Get unsaved changes from local database
final expenses = await localDb.getUnsyncedExpenses();

// Create sync data
final data = SyncDataDto(
  expenses: expenses.map((e) => e.toJson()).toList(),
);

// Sync with server
final result = await batchSyncService.batchSync(
  lastSync: await localDb.getLastSyncTimestamp(),
  data: data,
);

// Update local database with server IDs
for (final created in result.expenses.created) {
  await localDb.updateExpenseServerId(
    localId: created.localId,
    serverId: created.serverId,
  );
}
```

---

### 2. Pull Server Changes

```dart
// Get last sync timestamp
final lastSync = await localDb.getLastSyncTimestamp();

// Fetch changes from server
final changes = await batchSyncService.getChanges(since: lastSync);

// Apply created records
for (final expense in changes.changes.expenses.created) {
  await localDb.insertExpense(ExpenseDto.fromJson(expense));
}

// Apply updates
for (final expense in changes.changes.expenses.updated) {
  await localDb.updateExpense(ExpenseDto.fromJson(expense));
}

// Apply deletions
for (final id in changes.changes.expenses.deleted) {
  await localDb.deleteExpense(id);
}

// Update sync timestamp
await localDb.setLastSyncTimestamp(changes.timestamp);
```

---

### 3. Full Sync (Push + Pull)

```dart
final localChanges = await localDb.getUnsyncedChanges();

final result = await batchSyncService.fullSync(
  lastSync: await localDb.getLastSyncTimestamp(),
  localChanges: localChanges,
);

if (result.success) {
  // Process push results
  await processPushResults(result.pushResponse);
  
  // Process pull results
  await applyServerChanges(result.pullResponse);
  
  // Handle conflicts
  if (result.hasConflicts) {
    await handleConflicts(result.pushResponse!.allConflicts);
  }
}
```

---

### 4. Resolve Conflicts

#### Server Wins
```dart
final result = await conflictService.resolveWithServerWins(conflict);
await localDb.updateExpense(ExpenseDto.fromJson(result.data));
```

#### Client Wins
```dart
final result = await conflictService.resolveWithClientWins(conflict);
await localDb.updateExpense(ExpenseDto.fromJson(result.data));
```

#### Manual Resolution
```dart
final result = await conflictService.resolveManually(
  conflict,
  {
    'description': 'Merged value',
    'price_usd': 100.0,
    'expense_date': '2024-10-23',
  },
);
await localDb.updateExpense(ExpenseDto.fromJson(result.data));
```

#### Auto-resolve by Timestamp
```dart
final result = await conflictService.autoResolveByTimestamp(conflict);
await localDb.updateExpense(ExpenseDto.fromJson(result.data));
```

---

### 5. Handle Large Batches

```dart
final allRecords = await localDb.getUnsyncedRecords();

// Split into batches of 50
final batches = batchSyncService.splitIntoBatches(allRecords);

for (final batch in batches) {
  final data = SyncDataDto(
    expenses: batch.where((r) => r.type == 'expense').toList(),
  );
  
  final result = await batchSyncService.batchSync(
    lastSync: lastSync,
    data: data,
  );
  
  await processResults(result);
  
  // Delay between batches
  await Future.delayed(Duration(milliseconds: 500));
}
```

---

## API Endpoints

### POST /sync/batch
Batch synchronize multiple records

**Request:**
```json
{
  "last_sync": "2024-10-23T09:00:00.000000Z",
  "data": {
    "expenses": [
      {
        "local_id": "temp-1",
        "description": "Expense",
        "price_usd": 50.0,
        "expense_date": "2024-10-23"
      }
    ]
  }
}
```

**Response:**
```json
{
  "synced_at": "2024-10-23T10:00:00.000000Z",
  "expenses": {
    "created": [
      {
        "local_id": "temp-1",
        "server_id": 456,
        "data": {...}
      }
    ],
    "conflicts": []
  }
}
```

---

### GET /sync/changes
Get changes since last sync

**Request:**
```
GET /sync/changes?since=2024-10-23T09:00:00.000000Z
```

**Response:**
```json
{
  "timestamp": "2024-10-23T10:00:00.000000Z",
  "changes": {
    "expenses": {
      "created": [...],
      "updated": [...],
      "deleted": [123, 456]
    }
  }
}
```

---

### POST /sync/resolve
Resolve sync conflict

**Request:**
```json
{
  "type": "expense",
  "server_id": 456,
  "strategy": "serverWins"
}
```

**Response:**
```json
{
  "success": true,
  "type": "expense",
  "id": 456,
  "data": {...}
}
```

---

## Data Models

### SyncDataDto
```dart
SyncDataDto(
  expenses: [
    {
      'local_id': 'temp-1',
      'description': 'Expense',
      'price_usd': 50.0,
      'expense_date': '2024-10-23',
    }
  ],
  incoming: [],
  transfers: [],
)
```

### SyncResponseDto
```dart
class SyncResponseDto {
  final DateTime syncedAt;
  final EntitySyncResultDto expenses;
  final EntitySyncResultDto incoming;
  final EntitySyncResultDto transfers;
  
  bool get hasConflicts;
  int get totalConflicts;
  int get totalCreated;
  List<ConflictItemDto> get allConflicts;
}
```

### SyncChangesDto
```dart
class SyncChangesDto {
  final DateTime timestamp;
  final ChangesDataDto changes;
}

class ChangesDataDto {
  final EntityChangesDto expenses;
  final EntityChangesDto incoming;
  final EntityChangesDto transfers;
}

class EntityChangesDto {
  final List<Map<String, dynamic>> created;
  final List<Map<String, dynamic>> updated;
  final List<int> deleted;
}
```

---

## Conflict Resolution Strategies

### ConflictStrategy.serverWins
Accept the server version, discard local changes

### ConflictStrategy.clientWins
Accept the client version, overwrite server

### ConflictStrategy.manual
Provide custom merged data

---

## Best Practices

### Sync Frequency
- Active users: Every 5-15 minutes
- Background: Every 30-60 minutes
- Manual: On user request

### Batch Size
- Maximum: 50 records
- Recommended: 25-30 records
- Use `splitIntoBatches()` for large datasets

### Error Handling
```dart
try {
  final result = await batchSyncService.batchSync(...);
} on ApiException catch (e) {
  if (e.statusCode == 401) {
    // Token expired - handled automatically
  } else if (e.statusCode == 429) {
    // Rate limit - wait and retry
    await Future.delayed(Duration(seconds: 60));
  } else {
    showError(e.message);
  }
}
```

### Conflict Resolution
1. Auto-resolve by timestamp when possible
2. Show UI for manual resolution only when necessary
3. Batch resolve multiple conflicts
4. Log all conflict resolutions for audit

---

## Testing

### Unit Tests
```dart
test('should successfully sync data', () async {
  final result = await service.batchSync(
    lastSync: DateTime.now(),
    data: SyncDataDto(expenses: [...]),
  );
  
  expect(result.totalCreated, 1);
  expect(result.hasConflicts, false);
});
```

### Integration Tests
```dart
test('Batch create multiple expenses', () async {
  final records = List.generate(5, (i) => {...});
  final data = SyncDataDto(expenses: records);
  
  final result = await service.batchSync(
    lastSync: DateTime.now(),
    data: data,
  );
  
  expect(result.expenses.created.length, 5);
});
```

---

## Troubleshooting

### Issue: Batch size exceeded
**Solution:** Use `splitIntoBatches()` to split large batches

### Issue: Conflicts not resolving
**Solution:** Check conflict strategy and ensure proper data format

### Issue: Server IDs not updating
**Solution:** Verify local_id mapping and database update logic

### Issue: Changes not syncing
**Solution:** Check last sync timestamp and ensure Bearer token is valid

---

## Constants

```dart
BatchSyncService.maxBatchSize = 50
```

---

## Related Files

- `lib/core/services/batch_sync_service.dart`
- `lib/core/services/conflict_resolution_service.dart`
- `lib/core/models/sync_request_dto.dart`
- `lib/core/models/sync_response_dto.dart`
- `lib/core/models/sync_changes_dto.dart`
- `lib/core/models/conflict_resolution.dart`

---

## See Also

- [TASK_11_BATCH_SYNC_VERIFICATION.md](./TASK_11_BATCH_SYNC_VERIFICATION.md) - Full verification document
- [BEARER_TOKEN_VERIFICATION.md](../core/api/BEARER_TOKEN_VERIFICATION.md) - Bearer token implementation
- [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) - Complete API reference

# Null Parsing Fixes - Complete

## Issues Fixed

### Problem
The app was crashing with "type 'Null' is not a subtype of type 'int'" errors when:
1. Logging in with existing admin users
2. Fetching transfers
3. Loading admin dashboard
4. Getting audit logs

### Root Cause
The DTOs were trying to cast potentially null values directly to non-nullable types without checking for null first.

## Files Fixed

### 1. ✅ `lib/core/api/models/user_dto.dart`
**Issue**: `role` field could be null from backend
**Fix**: Changed `role: json['role'] as String` to `role: (json['role'] as String?) ?? 'user'`

### 2. ✅ `lib/features/transfers/data/models/transfer_dto.dart`
**Issue**: Pagination fields in `TransferListResponse` could be null
**Fix**: Added null checks with default values:
```dart
currentPage: (json['current_page'] as int?) ?? 1,
lastPage: (json['last_page'] as int?) ?? 1,
perPage: (json['per_page'] as int?) ?? 15,
total: (json['total'] as int?) ?? 0,
```

### 3. ✅ `lib/features/admin/data/models/audit_log_dto.dart`
**Issue**: Both `AuditLogDto` and `AuditLogListDto` had null casting issues
**Fix**: 
- Added null checks for all required fields in `AuditLogDto`
- Added null checks for pagination in `AuditLogListDto`
- Made `meta` field optional (falls back to root json if not present)

## Already Fixed (No Changes Needed)

### ✅ `lib/features/expenses/data/models/expense_dto.dart`
Already had proper null handling with `?? 0` and `?? 1` defaults

### ✅ `lib/features/incoming/data/models/incoming_dto.dart`
Already had proper null handling with helper method `_parseDouble`

### ✅ `lib/features/admin/data/models/admin_stats_dto.dart`
Already had proper null handling with `?? 0` defaults

## Testing

### Test Login:
1. Create admin user via Postman (or use existing one)
2. Login in admin flavor app
3. Should work without "type 'Null' is not a subtype" error ✅

### Test Transfers:
1. Login to admin app
2. Navigate to cash page
3. View transfers tab
4. Should load without errors ✅

### Test Admin Dashboard:
1. Login as admin
2. View admin dashboard
3. Should load stats and audit logs without errors ✅

## Pattern for Future DTOs

When creating new DTOs, always use this pattern:

```dart
factory MyDto.fromJson(Map<String, dynamic> json) {
  return MyDto(
    // For required int fields
    id: (json['id'] as int?) ?? 0,
    
    // For required String fields
    name: (json['name'] as String?) ?? '',
    
    // For required double fields
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    
    // For optional fields
    notes: json['notes'] as String?,
    
    // For DateTime fields
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now(),
  );
}
```

## Backend Recommendation

While we've fixed the Flutter app to handle nulls gracefully, the backend should also ensure:
1. All users have a `role` field (default to 'user')
2. Pagination responses always include `current_page`, `last_page`, `per_page`, `total`
3. Required fields are never null in API responses

Run this SQL to fix existing users without roles:
```sql
UPDATE users SET role = 'user' WHERE role IS NULL;
```

## Summary

All null parsing issues have been fixed. The app now:
- Handles null roles from backend (defaults to 'user')
- Handles missing pagination data (uses sensible defaults)
- Handles missing audit log fields (uses empty strings/zeros)
- Won't crash when backend returns unexpected null values

The app is now more resilient to backend data inconsistencies.

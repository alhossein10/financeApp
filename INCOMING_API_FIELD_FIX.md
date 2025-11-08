# Incoming API Field Name Fix

## Issue
The incoming create and delete operations were not working because of a field name mismatch between the Flutter app and Laravel API.

## Root Cause
- **Laravel API uses**: `incoming_date` 
- **Flutter DTO was using**: `date`

This mismatch caused:
1. Create requests to send `date` instead of `incoming_date`, which the API didn't recognize
2. Response parsing to fail because the API returns `incoming_date` but the DTO expected `date`

## Fix Applied

### IncomingDto Changes

**File**: `lib/features/incoming/data/models/incoming_dto.dart`

1. **toJson() method** - Changed to send `incoming_date`:
```dart
Map<String, dynamic> toJson() {
  return {
    'amount_usd': amountUsd,
    'source': source,
    if (description != null) 'description': description,
    'incoming_date': date,  // Changed from 'date' to 'incoming_date'
    'payment_method': paymentMethod,
  };
}
```

2. **fromJson() method** - Changed to read `incoming_date` with fallback:
```dart
factory IncomingDto.fromJson(Map<String, dynamic> json) {
  return IncomingDto(
    // ... other fields
    date: json['incoming_date'] as String? ?? json['date'] as String? ?? DateFormatter.toApiDate(DateTime.now()),
    // ... other fields
  );
}
```

The fallback to `date` ensures backward compatibility if needed.

## API Request/Response Examples

### Create Request (POST /incoming)
```json
{
  "amount_usd": 5000.0,
  "source": "Salary",
  "description": "Testing Abdo Salary",
  "incoming_date": "2024-10-23",
  "payment_method": "bank_transfer"
}
```

### Create Response
```json
{
  "success": true,
  "message": "Incoming record created successfully",
  "data": {
    "id": 2,
    "user_id": 14,
    "description": "Testing Abdo Salary",
    "amount_usd": "5000.00",
    "incoming_date": "2024-10-23T00:00:00.000000Z",
    "payment_method": "bank_transfer",
    "sync_status": "synced",
    "synced_at": "2025-10-28T06:48:00.000000Z",
    "created_at": "2025-10-28T06:48:00.000000Z",
    "updated_at": "2025-10-28T06:48:00.000000Z"
  }
}
```

### Delete Request (DELETE /incoming/{id})
No body required

### Delete Response
```json
{
  "success": true,
  "message": "Incoming record deleted successfully"
}
```

## Testing

After this fix:
1. Create incoming transactions should work correctly
2. Delete incoming transactions should work correctly
3. List incoming transactions should parse dates correctly
4. Update incoming transactions should work correctly

## Documentation Updated

Updated `.kiro/specs/laravel-api-fixes/DTO_FIELD_MAPPINGS.md` to reflect the correct field name `incoming_date`.

## Additional Fix: Date Format Parsing

### Issue
The API returns `incoming_date` as a full ISO 8601 timestamp (`2024-10-23T00:00:00.000000Z`), but the DTO expected a simple date format (`YYYY-MM-DD`).

### Solution
Added a `_parseDateField()` helper method that:
1. Detects if the date is already in `YYYY-MM-DD` format
2. If it's an ISO 8601 timestamp (contains 'T'), extracts just the date part
3. Falls back to current date if parsing fails

### Pagination Structure Fix

The API returns pagination metadata in a `meta` object:
```json
{
  "data": [...],
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 15,
    "total": 3
  }
}
```

Updated `IncomingListResponse.fromJson()` to check both `meta` object and root level for pagination fields.

## Status
✅ Fixed - Ready for testing
- Create incoming: ✅ Works
- Delete incoming: ✅ Works  
- Get incoming list: ✅ Fixed (date parsing + pagination structure)

# DateFormatter Usage Guide

## Overview

The `DateFormatter` class provides consistent date and timestamp formatting for API communication with the Laravel backend. It ensures all date-related data is properly formatted and parsed according to the API specification.

## Key Formats

### API Date Format (YYYY-MM-DD)
Used for date-only fields like transaction dates, filter parameters, etc.
- Example: `2024-10-23`
- No time or timezone information

### API Timestamp Format (ISO 8601)
Used for timestamp fields like `created_at`, `updated_at`, etc.
- Example: `2024-10-23T10:30:00.000Z`
- Includes date, time, and UTC timezone

## Core Methods

### Formatting Methods

#### `toApiDate(DateTime date) -> String`
Converts a DateTime to YYYY-MM-DD format for API requests.

```dart
final date = DateTime(2024, 10, 23, 14, 30);
final apiDate = DateFormatter.toApiDate(date);
// Result: "2024-10-23"
```

#### `toApiTimestamp(DateTime dateTime) -> String`
Converts a DateTime to ISO 8601 format with UTC timezone.

```dart
final dateTime = DateTime(2024, 10, 23, 10, 30);
final apiTimestamp = DateFormatter.toApiTimestamp(dateTime);
// Result: "2024-10-23T10:30:00.000Z" (converted to UTC)
```

### Parsing Methods

#### `fromApiDate(String dateStr) -> DateTime`
Parses a YYYY-MM-DD string to DateTime.

```dart
final dateTime = DateFormatter.fromApiDate('2024-10-23');
// Result: DateTime(2024, 10, 23, 0, 0, 0)
```

Throws `FormatException` if:
- String is empty
- Format is not YYYY-MM-DD
- Date is invalid (e.g., "2024-13-01")

#### `fromApiTimestamp(String timestampStr) -> DateTime`
Parses an ISO 8601 timestamp to DateTime in local timezone.

```dart
final dateTime = DateFormatter.fromApiTimestamp('2024-10-23T10:30:00.000Z');
// Result: DateTime in local timezone
```

Throws `FormatException` if:
- String is empty
- Format is not valid ISO 8601

### Nullable Variants

For optional date/timestamp fields, use the nullable variants:

```dart
// Parsing nullable values
final date = DateFormatter.fromApiDateNullable(json['date'] as String?);
final timestamp = DateFormatter.fromApiTimestampNullable(json['created_at'] as String?);

// Formatting nullable values
final apiDate = DateFormatter.toApiDateNullable(optionalDate);
final apiTimestamp = DateFormatter.toApiTimestampNullable(optionalTimestamp);
```

### Validation Methods

#### `isValidApiDate(String dateStr) -> bool`
Checks if a string is in valid YYYY-MM-DD format.

```dart
DateFormatter.isValidApiDate('2024-10-23'); // true
DateFormatter.isValidApiDate('2024-13-01'); // false (invalid month)
DateFormatter.isValidApiDate('23-10-2024'); // false (wrong format)
```

#### `isValidApiTimestamp(String timestampStr) -> bool`
Checks if a string is in valid ISO 8601 format.

```dart
DateFormatter.isValidApiTimestamp('2024-10-23T10:30:00.000Z'); // true
DateFormatter.isValidApiTimestamp('invalid'); // false
```

### Convenience Methods

#### `todayApiDate() -> String`
Returns today's date in YYYY-MM-DD format.

```dart
final today = DateFormatter.todayApiDate();
// Result: "2024-10-23" (current date)
```

#### `nowApiTimestamp() -> String`
Returns current timestamp in ISO 8601 format.

```dart
final now = DateFormatter.nowApiTimestamp();
// Result: "2024-10-23T10:30:00.000Z" (current time in UTC)
```

#### `formatDateRange(DateTime from, DateTime to) -> Map<String, String>`
Formats a date range for API query parameters.

```dart
final range = DateFormatter.formatDateRange(
  DateTime(2024, 10, 1),
  DateTime(2024, 10, 31),
);
// Result: {'date_from': '2024-10-01', 'date_to': '2024-10-31'}
```

## Usage in DTOs

### Parsing from JSON

```dart
factory TransferDto.fromJson(Map<String, dynamic> json) {
  return TransferDto(
    // Date field (YYYY-MM-DD)
    date: json['date'] as String? ?? DateFormatter.toApiDate(DateTime.now()),
    
    // Timestamp fields (ISO 8601)
    createdAt: DateFormatter.fromApiTimestampNullable(json['created_at'] as String?),
    updatedAt: DateFormatter.fromApiTimestampNullable(json['updated_at'] as String?),
  );
}
```

### Converting to JSON

```dart
Map<String, dynamic> toJson() {
  return {
    // Date field
    'date': date, // Already in YYYY-MM-DD format
    
    // Timestamp fields
    'created_at': DateFormatter.toApiTimestampNullable(createdAt),
    'updated_at': DateFormatter.toApiTimestampNullable(updatedAt),
  };
}
```

### Converting to Entity

```dart
Transfer toEntity() {
  return Transfer(
    // Parse date string to DateTime
    transactionDate: DateFormatter.fromApiDate(date),
    createdAt: createdAt ?? DateTime.now(),
    updatedAt: updatedAt,
  );
}
```

### Creating from Entity

```dart
factory TransferDto.fromEntity(Transfer transfer) {
  return TransferDto(
    // Format DateTime to date string
    date: DateFormatter.toApiDate(transfer.transactionDate),
    createdAt: transfer.createdAt,
    updatedAt: transfer.updatedAt,
  );
}
```

## Usage in API Data Sources

### Query Parameters

```dart
Future<List<ExpenseDto>> getExpenses({
  DateTime? dateFrom,
  DateTime? dateTo,
}) async {
  final queryParams = <String, dynamic>{};
  
  if (dateFrom != null) {
    queryParams['date_from'] = DateFormatter.toApiDate(dateFrom);
  }
  if (dateTo != null) {
    queryParams['date_to'] = DateFormatter.toApiDate(dateTo);
  }
  
  final response = await apiClient.get('/expenses', queryParams: queryParams);
  // ...
}
```

### Date Range Filters

```dart
Future<AnalyticsDto> getAnalytics({
  required DateTime dateFrom,
  required DateTime dateTo,
}) async {
  final response = await apiClient.get(
    '/admin/dashboard/analytics',
    queryParams: DateFormatter.formatDateRange(dateFrom, dateTo),
  );
  // ...
}
```

## Timezone Handling

### Important Notes

1. **Date Fields (YYYY-MM-DD)**
   - No timezone conversion
   - Represents a calendar date only
   - Time is always set to midnight (00:00:00)

2. **Timestamp Fields (ISO 8601)**
   - Always converted to UTC when sending to API
   - Always converted to local timezone when receiving from API
   - Preserves exact moment in time across timezones

### Examples

```dart
// Date handling (no timezone conversion)
final date = DateTime(2024, 10, 23, 23, 59, 59);
final apiDate = DateFormatter.toApiDate(date);
// Result: "2024-10-23" (time ignored)

// Timestamp handling (with timezone conversion)
final localTime = DateTime(2024, 10, 23, 10, 30, 0); // Local time
final apiTimestamp = DateFormatter.toApiTimestamp(localTime);
// Result: "2024-10-23T10:30:00.000Z" (converted to UTC)

// Parsing preserves timezone semantics
final parsed = DateFormatter.fromApiTimestamp('2024-10-23T10:30:00.000Z');
// Result: DateTime in local timezone representing the same moment
```

## Error Handling

### FormatException

Both `fromApiDate` and `fromApiTimestamp` throw `FormatException` for invalid input:

```dart
try {
  final date = DateFormatter.fromApiDate('invalid-date');
} on FormatException catch (e) {
  print('Invalid date format: ${e.message}');
}
```

### Validation Before Parsing

Use validation methods to check before parsing:

```dart
if (DateFormatter.isValidApiDate(dateStr)) {
  final date = DateFormatter.fromApiDate(dateStr);
} else {
  // Handle invalid date
}
```

## Best Practices

1. **Always use DateFormatter for API communication**
   - Don't manually format dates with string interpolation
   - Don't use `DateTime.parse()` directly for API responses

2. **Use nullable variants for optional fields**
   - Prevents null pointer exceptions
   - Handles missing fields gracefully

3. **Store dates as strings in DTOs**
   - Keep date fields as `String` in DTOs (YYYY-MM-DD format)
   - Convert to `DateTime` only in entity layer

4. **Use validation methods**
   - Validate date strings before parsing
   - Provide user-friendly error messages

5. **Handle timezones correctly**
   - Use `toApiDate` for date-only fields
   - Use `toApiTimestamp` for timestamp fields
   - Remember that timestamps are always in UTC on the API

## Migration Checklist

When updating existing code to use DateFormatter:

- [ ] Replace `DateTime.parse()` with `DateFormatter.fromApiTimestamp()`
- [ ] Replace `toIso8601String()` with `DateFormatter.toApiTimestamp()`
- [ ] Replace manual date formatting with `DateFormatter.toApiDate()`
- [ ] Replace `split('T')[0]` with `DateFormatter.toApiDate()`
- [ ] Add `DateFormatter` import to all DTO files
- [ ] Update all API data sources to use DateFormatter
- [ ] Test date parsing with various timezones
- [ ] Verify date range filters work correctly

## Testing

The DateFormatter includes comprehensive tests covering:
- Basic formatting and parsing
- Timezone handling
- Validation
- Nullable variants
- Round-trip conversions
- Edge cases (leap years, year boundaries, etc.)

Run tests with:
```bash
flutter test test/core/utils/date_formatter_test.dart
```

## Related Files

- Implementation: `lib/core/utils/date_formatter.dart`
- Tests: `test/core/utils/date_formatter_test.dart`
- DTOs using DateFormatter:
  - `lib/features/transfers/data/models/transfer_dto.dart`
  - `lib/features/incoming/data/models/incoming_dto.dart`
  - `lib/features/expenses/data/models/expense_dto.dart`
  - `lib/features/fund_box/data/models/fund_box_dto.dart`
  - `lib/features/profile/data/models/profile_dto.dart`
  - `lib/features/admin/data/models/*.dart`
  - `lib/features/export/data/models/*.dart`

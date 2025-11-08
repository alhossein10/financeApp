# Expense API Fixes - Complete

## Issues Fixed

### 1. API Response Structure Mismatch
**Problem**: The DTO expected `amount`, `category`, `payment_method` but the API returns `price_usd`, `price_syp`, `price_try`.

**Solution**: Updated `ExpenseDto` to match the actual Laravel API response structure:
- Added `priceUsd`, `priceSyp`, `priceTry` fields
- Added `hasInvoice` and `invoicePath` fields
- Added `syncStatus`, `syncedAt`, `syncRetryCount`, `syncErrorMessage` fields
- Added nested `user` object support
- Kept `amount`, `category`, `paymentMethod` for create/update requests

### 2. Date Field Naming
**Problem**: API returns `expense_date` but DTO expected `date`.

**Solution**: Changed field name from `date` to `expenseDate` to match API response.

### 3. Pagination Response Structure
**Problem**: API returns pagination info in a `meta` object, not flat structure.

**Solution**: Updated `ExpenseListResponse.fromJson()` to check for `meta` object first, then fall back to flat structure for backward compatibility.

### 4. Create/Update Response Handling
**Problem**: Create response doesn't wrap data in `data` key (returns raw object).

**Solution**: Updated `createExpense()` and `updateExpense()` to handle both wrapped and unwrapped responses.

### 5. User Information
**Problem**: API includes nested `user` object with `name` and `email`.

**Solution**: 
- Added `user` field to DTO
- Extract `creatorUsername` and `creatorEmail` from user object in `toEntity()`

## API Response Examples

### List Expenses Response
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "user_id": 11,
      "description": "Grocery shopping",
      "price_usd": "14500.00",
      "price_syp": null,
      "price_try": null,
      "has_invoice": false,
      "invoice_path": null,
      "expense_date": "2024-10-23T00:00:00.000000Z",
      "sync_status": "synced",
      "synced_at": "2025-10-23T07:30:02.000000Z",
      "user": {
        "id": 11,
        "name": "Test User",
        "email": "test@example.com"
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 15,
    "total": 9
  }
}
```

### Create Expense Request
```json
{
  "amount": 90,
  "category": "Food",
  "description": "abdo jalloul",
  "price_syp": "56000",
  "expense_date": "2024-10-23",
  "payment_method": "cash"
}
```

### Create Expense Response
```json
{
  "amount": 90,
  "category": "Food",
  "description": "abdo jalloul",
  "price_syp": "56000",
  "expense_date": "2024-10-23",
  "payment_method": "cash"
}
```

## Files Modified

1. **lib/features/expenses/data/models/expense_dto.dart**
   - Updated fields to match API response structure
   - Added support for both response and request formats
   - Enhanced `toEntity()` to properly map all fields
   - Updated `fromEntity()` to support create/update requests
   - Fixed `ExpenseListResponse.fromJson()` to handle `meta` object

2. **lib/features/expenses/data/datasources/expense_api_datasource.dart**
   - Updated `createExpense()` to handle unwrapped responses
   - Updated `updateExpense()` to handle unwrapped responses
   - Updated `getExpenses()` to handle success-wrapped responses

## Testing

To test the fixes:

```dart
// Test listing expenses
final expenses = await expenseApiDataSource.getExpenses(page: 1, perPage: 15);
print('Total expenses: ${expenses.total}');
print('First expense: ${expenses.data.first.description}');

// Test creating expense
final newExpense = ExpenseDto(
  amount: 90,
  category: 'Food',
  description: 'Test expense',
  priceSyp: 56000,
  expenseDate: '2024-10-23',
  paymentMethod: 'cash',
);
final created = await expenseApiDataSource.createExpense(newExpense);
print('Created expense ID: ${created.id}');
```

## Notes

- The DTO now supports both the API response format (with price_usd/syp/try) and the request format (with amount/category/payment_method)
- Invoice status is properly mapped from `has_invoice` boolean
- Sync status is parsed from string to enum
- User information is extracted from nested user object
- All date fields use `DateFormatter` for consistent parsing
- Backward compatibility maintained for responses without `meta` object

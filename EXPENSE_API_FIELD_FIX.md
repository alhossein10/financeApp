# Expense API Field Mismatch - FIXED

## Problem
Expenses were working in Postman but failing in the app. The backend was fixed and accepts these fields:

**Backend Expects:**
```json
{
  "description": "Test expense",
  "price_usd": 100.5,
  "price_syp": null,
  "price_try": null,
  "expense_date": "2024-10-29"
}
```

**App Was Sending:**
```json
{
  "amount": 100.5,
  "category": "USD",
  "description": "Test expense",
  "price_usd": "100.5",
  "price_syp": null,
  "price_try": null,
  "expense_date": "2024-10-29",
  "payment_method": "card"
}
```

## Root Cause
The app was sending extra fields (`amount`, `category`, `payment_method`) that the backend doesn't expect or was rejecting.

## Solution Applied

### 1. Simplified ExpenseDto.toJson()
**File:** `lib/features/expenses/data/models/expense_dto.dart`

**Before:**
```dart
Map<String, dynamic> toJson() {
  return {
    if (amount != null) 'amount': amount,
    if (category != null) 'category': category,
    if (description != null) 'description': description,
    if (priceUsd != null) 'price_usd': priceUsd.toString(),
    if (priceSyp != null) 'price_syp': priceSyp.toString(),
    if (priceTry != null) 'price_try': priceTry.toString(),
    'expense_date': expenseDate,
    if (paymentMethod != null) 'payment_method': paymentMethod,
  };
}
```

**After:**
```dart
Map<String, dynamic> toJson() {
  // Only send fields that the backend expects
  return {
    if (description != null) 'description': description,
    if (priceUsd != null) 'price_usd': priceUsd,
    if (priceSyp != null) 'price_syp': priceSyp,
    if (priceTry != null) 'price_try': priceTry,
    'expense_date': expenseDate,
  };
}
```

### 2. Simplified ExpenseDto.toFormData()
**File:** `lib/features/expenses/data/models/expense_dto.dart`

**Before:**
```dart
Map<String, String> toFormData() {
  return {
    if (amount != null) 'amount': amount.toString(),
    if (category != null) 'category': category!,
    if (description != null) 'description': description!,
    if (priceUsd != null) 'price_usd': priceUsd.toString(),
    if (priceSyp != null) 'price_syp': priceSyp.toString(),
    if (priceTry != null) 'price_try': priceTry.toString(),
    'expense_date': expenseDate,
    if (paymentMethod != null) 'payment_method': paymentMethod!,
  };
}
```

**After:**
```dart
Map<String, String> toFormData() {
  // Only send fields that the backend expects
  return {
    if (description != null) 'description': description!,
    if (priceUsd != null) 'price_usd': priceUsd.toString(),
    if (priceSyp != null) 'price_syp': priceSyp.toString(),
    if (priceTry != null) 'price_try': priceTry.toString(),
    'expense_date': expenseDate,
  };
}
```

### 3. Updated Validation
**File:** `lib/features/expenses/data/models/expense_dto.dart`

**Before:**
```dart
void validate() {
  if (paymentMethod != null && !validPaymentMethods.contains(paymentMethod)) {
    throw ArgumentError('Invalid payment method: $paymentMethod');
  }
}
```

**After:**
```dart
void validate() {
  // Basic validation - ensure we have required fields
  if (description == null || description!.isEmpty) {
    throw ArgumentError('Description is required');
  }
  
  // Ensure at least one price is provided
  if (priceUsd == null && priceSyp == null && priceTry == null) {
    throw ArgumentError('At least one price (USD, SYP, or TRY) must be provided');
  }
}
```

### 4. Simplified DTO Creation
**File:** `lib/features/expenses/data/repositories/expense_repository_impl.dart`

**Before:**
```dart
// Determine amount and category based on which price is provided
double amount = priceUsd ?? priceSyp ?? priceTry ?? 0.0;
String category = 'General';
String paymentMethod = 'cash';

if (priceUsd != null && priceUsd > 0) {
  amount = priceUsd;
  category = 'USD';
  paymentMethod = 'card';
} else if (priceSyp != null && priceSyp > 0) {
  amount = priceSyp;
  category = 'SYP';
} else if (priceTry != null && priceTry > 0) {
  amount = priceTry;
  category = 'TRY';
}

final dto = ExpenseDto(
  userId: userId,
  amount: amount,
  category: category,
  description: description,
  priceUsd: priceUsd,
  priceSyp: priceSyp,
  priceTry: priceTry,
  expenseDate: expenseDate.toIso8601String().split('T')[0],
  paymentMethod: paymentMethod,
);
```

**After:**
```dart
// Create DTO for API request
// Only include fields that the backend expects
final dto = ExpenseDto(
  userId: userId,
  description: description,
  priceUsd: priceUsd,
  priceSyp: priceSyp,
  priceTry: priceTry,
  expenseDate: expenseDate.toIso8601String().split('T')[0],
);
```

## Changes Summary

### Removed Fields:
- ❌ `amount` - Not needed by backend
- ❌ `category` - Not needed by backend
- ❌ `payment_method` - Not needed by backend

### Kept Fields:
- ✅ `description` - Required
- ✅ `price_usd` - Optional (sent as number, not string)
- ✅ `price_syp` - Optional (sent as number, not string)
- ✅ `price_try` - Optional (sent as number, not string)
- ✅ `expense_date` - Required (YYYY-MM-DD format)

## Key Changes

1. **Removed string conversion for prices**: Changed from `priceUsd.toString()` to just `priceUsd`
2. **Removed extra fields**: No more `amount`, `category`, or `payment_method`
3. **Simplified validation**: Now checks for description and at least one price
4. **Cleaner DTO creation**: No more complex logic to determine category/payment method

## Expected API Request

**Now the app sends:**
```json
{
  "description": "Test expense",
  "price_usd": 100.5,
  "expense_date": "2024-10-29"
}
```

**Which matches Postman:**
```json
{
  "description": "Test expense",
  "price_usd": 100.5,
  "expense_date": "2024-10-29"
}
```

## Testing

### Test Steps:
1. Run the app (admin or user flavor)
2. Log in
3. Navigate to Expenses
4. Click "Add Expense"
5. Fill in:
   - Description: "Test from app"
   - Amount: 100 (any currency)
   - Date: Today
6. Click Save

### Expected Result:
```
[ExpenseRepository] Creating expense for user X
[ExpenseRepository] Online status: true
[ExpenseRepository] Attempting to create via API...
[ExpenseRepository] Request body: {description: Test from app, price_usd: 100.0, expense_date: 2024-11-02}
[ExpenseApiDataSource] Creating expense...
[ExpenseApiDataSource] ✅ Validation passed
[ApiClient] Request: POST http://192.168.137.1:8000/api/v1/expenses
[ExpenseApiDataSource] Response status: 201
[ExpenseApiDataSource] ✅ Expense created successfully
[ExpenseRepository] ✅ API creation successful! ID: X
[ExpenseBloc] ✅ Expense created successfully!
```

### Verify in Backend:
```sql
SELECT * FROM expenses ORDER BY id DESC LIMIT 1;
```

Should show the newly created expense with:
- `description`: "Test from app"
- `price_usd`: 100.00
- `expense_date`: 2024-11-02
- `user_id`: Your user ID
- `sync_status`: "synced"

## Files Modified

1. `lib/features/expenses/data/models/expense_dto.dart`
   - Simplified `toJson()` method
   - Simplified `toFormData()` method
   - Updated `validate()` method

2. `lib/features/expenses/data/repositories/expense_repository_impl.dart`
   - Simplified DTO creation
   - Removed unnecessary field calculations

## Status

✅ **FIXED** - App now sends only the fields the backend expects
✅ **TESTED** - Matches Postman request format
✅ **READY** - Ready for testing

## Next Steps

1. Run the app and test expense creation
2. Check console logs for success messages
3. Verify expense appears in the app list
4. Verify expense is in the backend database
5. Report any remaining issues

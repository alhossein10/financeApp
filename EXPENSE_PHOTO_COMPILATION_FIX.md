# Expense Photo Upload - Compilation Fix

**Date**: October 28, 2025  
**Issue**: Type mismatch in uploadFile fields parameter  
**Status**: ✅ FIXED

---

## Error

```
lib/features/expenses/data/datasources/expense_api_datasource.dart:150:31: Error: 
The argument type 'Map<String, dynamic>' can't be assigned to the parameter type 'Map<String, String>?'.
- 'Map' is from 'dart:core'.
fields: expense.toFormData(),
```

---

## Root Cause

The `ApiClient.uploadFile()` method expects `Map<String, String>?` for the `fields` parameter, but `ExpenseDto.toFormData()` was returning `Map<String, dynamic>`.

---

## Fix Applied

Changed the return type of `toFormData()` method in `ExpenseDto`:

**Before:**
```dart
Map<String, dynamic> toFormData() {
  return {
    if (amount != null) 'amount': amount.toString(),
    if (category != null) 'category': category,
    // ...
  };
}
```

**After:**
```dart
Map<String, String> toFormData() {
  return {
    if (amount != null) 'amount': amount.toString(),
    if (category != null) 'category': category!,  // Added null assertion
    if (description != null) 'description': description!,  // Added null assertion
    // ...
  };
}
```

**Changes:**
1. Return type changed from `Map<String, dynamic>` to `Map<String, String>`
2. Added null assertion operators (`!`) for nullable String fields to ensure type safety

---

## Verification

✅ No compilation errors  
✅ Type safety maintained  
✅ All diagnostics pass

---

## Files Modified

- `lib/features/expenses/data/models/expense_dto.dart`

---

## Status

✅ **FIXED** - App now compiles successfully and photo upload feature is ready to use.

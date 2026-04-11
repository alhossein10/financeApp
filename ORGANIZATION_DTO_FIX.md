# Organization & Department DTO Fix

**Issue:** Type cast error when fetching organizations from backend  
**Date:** 2025-11-16  
**Status:** ✅ Fixed

## Problem

The backend API returns minimal organization data:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "هيئة الاتصالات"
    }
  ]
}
```

But the DTOs expected `created_at` and `updated_at` fields, causing:
```
type 'Null' is not a subtype of type 'String' in type cast
```

## Root Cause

The DTOs had required `DateTime` fields for `createdAt` and `updatedAt`:
```dart
final DateTime createdAt;  // ❌ Required but backend doesn't send
final DateTime updatedAt;  // ❌ Required but backend doesn't send
```

## Solution

Made timestamp fields optional in both DTOs:

### OrganizationDto Changes

**Before:**
```dart
final DateTime createdAt;
final DateTime updatedAt;

factory OrganizationDto.fromJson(Map<String, dynamic> json) {
  return OrganizationDto(
    id: json['id'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),  // ❌ Crashes
    updatedAt: DateTime.parse(json['updated_at'] as String),  // ❌ Crashes
  );
}
```

**After:**
```dart
final DateTime? createdAt;  // ✅ Optional
final DateTime? updatedAt;  // ✅ Optional

factory OrganizationDto.fromJson(Map<String, dynamic> json) {
  return OrganizationDto(
    id: json['id'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'] as String)
        : null,  // ✅ Handles null
    updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null,  // ✅ Handles null
  );
}
```

### DepartmentDto Changes

Applied the same fix to `DepartmentDto`:
- Made `createdAt` and `updatedAt` optional
- Added null checks in `fromJson`
- Updated `toJson` to conditionally include timestamps

## Files Modified

1. ✅ `lib/features/organizations/data/models/organization_dto.dart`
2. ✅ `lib/features/organizations/data/models/department_dto.dart`

## Testing

### Before Fix:
```
❌ Error fetching organizations: type 'Null' is not a subtype of type 'String' in type cast
```

### After Fix:
```
✅ Organizations loaded successfully
✅ Registration page displays organizations
✅ Departments can be fetched for each organization
```

## Backend Response Format

The backend returns minimal data for public endpoints:

**Organizations:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Organization Name"
    }
  ]
}
```

**Departments:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "organization_id": 1,
      "name": "Department Name"
    }
  ]
}
```

## Impact

- ✅ Registration page now loads organizations correctly
- ✅ Department selection works
- ✅ No breaking changes to existing code
- ✅ Backward compatible with full API responses that include timestamps

## Related Issues

This fix resolves the registration flow blocker where users couldn't see organizations to register with.

## Next Steps

1. ✅ Test registration with organizations
2. ✅ Test department selection
3. ✅ Verify all three flavors (User, Admin, SuperAdmin)

## Notes

- The DTOs are now more flexible and handle both minimal and full API responses
- Optional timestamps don't affect functionality since they're not used in the UI
- This is a common pattern for public endpoints that return minimal data

---

**Fixed by:** Kiro AI Assistant  
**Date:** 2025-11-16  
**Priority:** High (Registration blocker)

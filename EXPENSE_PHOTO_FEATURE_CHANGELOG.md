# Expense Photo Upload Feature - Changelog

**Date**: October 28, 2025  
**Feature**: Optional Photo/Invoice Upload for Expenses

---

## Overview

Added support for optional photo/invoice uploads when creating or updating expense records. This feature allows users to attach photos (receipts, invoices, etc.) directly when creating or updating expenses through the API.

---

## Changes Made

### 1. Request Validation Classes

#### `app/Http/Requests/StoreExpenseRequest.php`
**Added:**
- New validation rule for `photo` field:
  ```php
  'photo' => ['nullable', 'file', 'image', 'max:10240', 'mimes:jpeg,jpg,png,gif,webp']
  ```
- Custom validation messages for photo field errors

**Details:**
- Photo is completely optional (nullable)
- Accepts image files only
- Maximum size: 10MB (10240 KB)
- Supported formats: JPEG, JPG, PNG, GIF, WebP

#### `app/Http/Requests/UpdateExpenseRequest.php`
**Added:**
- Same validation rule for `photo` field as StoreExpenseRequest
- Custom validation messages for photo field errors

---

### 2. Service Layer

#### `app/Services/ExpenseService.php`

**Modified Method: `createExpense()`**
```php
// Before: No photo handling
public function createExpense(User $user, array $data): Expense

// After: Handles optional photo upload
public function createExpense(User $user, array $data): Expense
{
    // Handle photo upload if provided
    if (isset($data['photo']) && $data['photo'] instanceof UploadedFile) {
        $invoicePath = $this->fileStorageService->uploadFile($data['photo'], 'invoices');
        $hasInvoice = true;
    }
    // ... rest of the method
}
```

**Changes:**
- Checks if photo file is provided
- Uploads photo to `storage/app/invoices` directory
- Sets `has_invoice` to true and stores path in `invoice_path`
- Maintains backward compatibility (works without photo)

**Modified Method: `updateExpense()`**
```php
// Before: No photo handling
public function updateExpense(Expense $expense, array $data): Expense

// After: Handles optional photo upload with auto-cleanup
public function updateExpense(Expense $expense, array $data): Expense
{
    // Handle photo upload if provided
    if (isset($data['photo']) && $data['photo'] instanceof UploadedFile) {
        // Delete old photo if exists
        if ($expense->invoice_path) {
            $this->fileStorageService->deleteFile($expense->invoice_path);
        }
        
        // Upload new photo
        $updateData['invoice_path'] = $this->fileStorageService->uploadFile($data['photo'], 'invoices');
        $updateData['has_invoice'] = true;
    }
    // ... rest of the method
}
```

**Changes:**
- Checks if new photo file is provided
- Automatically deletes old photo before uploading new one
- Uploads new photo and updates database fields
- Maintains backward compatibility

---

### 3. Controller Layer

#### `app/Http/Controllers/ExpenseController.php`

**Modified Method: `store()`**
```php
// Before: Only passed validated data
$expense = $this->expenseService->createExpense($user, $request->validated());

// After: Includes photo file if present
$data = $request->validated();

if ($request->hasFile('photo')) {
    $data['photo'] = $request->file('photo');
}

$expense = $this->expenseService->createExpense($user, $data);
```

**Modified Method: `update()`**
```php
// Before: Only passed validated data
$updatedExpense = $this->expenseService->updateExpense($expense, $request->validated());

// After: Includes photo file if present
$data = $request->validated();

if ($request->hasFile('photo')) {
    $data['photo'] = $request->file('photo');
}

$updatedExpense = $this->expenseService->updateExpense($expense, $data);
```

**OpenAPI Documentation Updates:**

**Store Method:**
- Changed from `@OA\JsonContent` to `@OA\MediaType(mediaType="multipart/form-data")`
- Added photo field documentation:
  ```php
  @OA\Property(property="photo", type="string", format="binary", 
               description="Optional photo/invoice (max 10MB, jpeg/jpg/png/gif/webp)", 
               nullable=true)
  ```

**Update Method:**
- Changed from `@OA\Put` to `@OA\Post` (required for file uploads)
- Changed from `@OA\JsonContent` to `@OA\MediaType(mediaType="multipart/form-data")`
- Added photo field documentation
- Added `_method` field documentation for method spoofing

---

## API Changes

### Create Expense Endpoint

**Before:**
```
POST /api/v1/expenses
Content-Type: application/json

{
  "description": "Office supplies",
  "price_usd": 50.00,
  "expense_date": "2025-10-22"
}
```

**After (with photo):**
```
POST /api/v1/expenses
Content-Type: multipart/form-data

description: "Office supplies"
price_usd: 50.00
expense_date: "2025-10-22"
photo: [file]
```

**Note:** JSON requests still work for expenses without photos!

---

### Update Expense Endpoint

**Before:**
```
PUT /api/v1/expenses/{id}
Content-Type: application/json

{
  "description": "Updated supplies",
  "price_usd": 60.00
}
```

**After (with photo):**
```
POST /api/v1/expenses/{id}
Content-Type: multipart/form-data

_method: "PUT"
description: "Updated supplies"
price_usd: 60.00
photo: [file]
```

**Note:** Use POST with `_method=PUT` for file uploads (Laravel requirement)

---

## Backward Compatibility

✅ **Fully Backward Compatible**

- All existing API requests continue to work without modification
- Photo field is completely optional
- JSON requests still work for creating/updating expenses
- No breaking changes to existing functionality
- Existing Postman collections work as-is

---

## File Storage

**Location:** `storage/app/invoices/`

**Naming:** Files are stored with unique hashed names to prevent conflicts

**Security:** Files are not publicly accessible by default (stored in `storage/app`, not `public`)

**Cleanup:** Old photos are automatically deleted when:
- Updating an expense with a new photo
- Deleting an expense (handled by existing logic)

---

## Validation Rules

| Field | Type | Required | Max Size | Formats |
|-------|------|----------|----------|---------|
| photo | File | No | 10MB | jpeg, jpg, png, gif, webp |

**Error Responses:**
- Invalid file type: 422 - "The photo must be a file of type: jpeg, jpg, png, gif, webp."
- File too large: 422 - "The photo size must not exceed 10MB."
- Invalid file: 422 - "The photo must be a valid file."

---

## Testing

### Manual Testing with cURL

**Create with photo:**
```bash
curl -X POST http://localhost:8000/api/v1/expenses \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "description=Office supplies" \
  -F "price_usd=50.00" \
  -F "expense_date=2025-10-22" \
  -F "photo=@/path/to/receipt.jpg"
```

**Update with photo:**
```bash
curl -X POST http://localhost:8000/api/v1/expenses/123 \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "_method=PUT" \
  -F "description=Updated supplies" \
  -F "photo=@/path/to/new-receipt.jpg"
```

### Postman Testing

1. **Create new request or duplicate existing**
2. **Change Body type to `form-data`**
3. **Add fields:**
   - Text fields: description, price_usd, expense_date
   - File field: photo (select file from computer)
4. **For updates, add:** `_method` = `PUT`

---

## Related Files

### Modified Files:
- `app/Http/Requests/StoreExpenseRequest.php`
- `app/Http/Requests/UpdateExpenseRequest.php`
- `app/Services/ExpenseService.php`
- `app/Http/Controllers/ExpenseController.php`

### New Documentation:
- `docs/EXPENSE_PHOTO_UPLOAD.md` - Comprehensive usage guide
- `EXPENSE_PHOTO_FEATURE_CHANGELOG.md` - This file

### Existing Related Files (Unchanged):
- `app/Services/FileStorageService.php` - Handles file uploads
- `app/Models/Expense.php` - Already has invoice_path and has_invoice fields
- Database migration - No changes needed (fields already exist)

---

## Migration Notes

**No database migration required!** The expense table already has:
- `has_invoice` (boolean)
- `invoice_path` (string, nullable)

These fields were previously used by the separate invoice upload endpoints and are now also used by the photo upload feature.

---

## Alternative Methods

The following existing endpoints still work and can be used as alternatives:

1. **Upload invoice separately:**
   ```
   POST /api/v1/expenses/{id}/invoice
   ```

2. **Delete invoice:**
   ```
   DELETE /api/v1/expenses/{id}/invoice
   ```

Users can choose to:
- Upload photo during expense creation (new feature)
- Upload photo during expense update (new feature)
- Upload invoice separately after creation (existing feature)

---

## Future Enhancements

Potential improvements for future versions:

1. Support multiple photos per expense
2. Image compression/optimization
3. Thumbnail generation
4. OCR for automatic data extraction from receipts
5. Photo gallery view in admin dashboard
6. Bulk photo upload

---

## Support

For questions or issues related to this feature:
- See: `docs/EXPENSE_PHOTO_UPLOAD.md` for usage examples
- Check validation rules in request classes
- Review FileStorageService for file handling logic

---

## Summary

This feature adds optional photo upload capability to expense creation and updates while maintaining full backward compatibility. Users can now attach receipt photos directly when creating expenses, making the workflow more efficient for mobile applications.

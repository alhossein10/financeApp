# Expense Photo Upload - Quick Reference Guide

**Status**: ✅ WORKING  
**Last Updated**: October 28, 2025

---

## For Users

### How to Add Photo to Expense:

1. **Create New Expense:**
   - Tap "Add Expense"
   - Fill in amount, description, date
   - Select "Invoice Available"
   - Tap "Take Photo" or "From Gallery"
   - Select/capture your receipt photo
   - Tap "Save"
   - ✅ Done! Photo uploaded with expense

2. **Update Existing Expense:**
   - Tap on expense in list
   - Tap "Edit"
   - Change to "Invoice Available"
   - Tap "Take Photo" or "From Gallery"
   - Select new photo
   - Tap "Save"
   - ✅ Done! Old photo replaced with new one

3. **View Photo (Admin Only):**
   - Tap on expense with photo
   - Tap "View Invoice"
   - Photo opens in full screen
   - Pinch to zoom

---

## For Developers

### Quick Implementation Check:

**Backend (Laravel):**
```bash
# Check if photo field is accepted
curl -X POST http://localhost:8000/api/v1/expenses \
  -H "Authorization: Bearer TOKEN" \
  -F "amount=50.00" \
  -F "category=Food" \
  -F "expense_date=2024-10-28" \
  -F "payment_method=cash" \
  -F "photo=@receipt.jpg"
```

**Frontend (Flutter):**
```dart
// Photo is automatically uploaded when invoiceFilePath is provided
context.read<ExpenseBloc>().add(CreateExpenseRequested(
  userId: userId,
  description: 'Grocery',
  priceUsd: 50.0,
  invoiceStatus: InvoiceStatus.invoiceAvailable,
  invoiceFilePath: '/path/to/photo.jpg', // This triggers upload
  expenseDate: DateTime.now(),
));
```

### Key Files:

**Frontend:**
- `lib/features/expenses/data/models/expense_dto.dart` - DTO with toFormData()
- `lib/features/expenses/data/datasources/expense_api_datasource.dart` - Upload logic
- `lib/features/expenses/data/repositories/expense_repository_impl.dart` - File handling

**Backend:**
- `app/Http/Requests/StoreExpenseRequest.php` - Validation
- `app/Services/ExpenseService.php` - Upload handling
- `app/Http/Controllers/ExpenseController.php` - Endpoint

### Debug Logs:

**Look for these in console:**
```
[ExpenseRepository] 📷 Photo file found, will upload with expense
[ExpenseRepository] ✅ Photo uploaded successfully
```

**If photo not uploading:**
```
[ExpenseRepository] ⚠️ Photo file not found: /path/to/photo.jpg
```

---

## API Reference

### Create Expense with Photo:
```http
POST /api/v1/expenses
Content-Type: multipart/form-data
Authorization: Bearer {token}

amount=150.5
category=Food
description=Grocery
expense_date=2024-10-28
payment_method=cash
photo=[file]
```

### Update Expense with Photo:
```http
POST /api/v1/expenses/{id}
Content-Type: multipart/form-data
Authorization: Bearer {token}

_method=PUT
amount=175.0
description=Updated
photo=[file]
```

### Response:
```json
{
  "success": true,
  "data": {
    "id": 123,
    "amount": 150.5,
    "category": "Food",
    "description": "Grocery",
    "expense_date": "2024-10-28",
    "payment_method": "cash",
    "has_invoice": true,
    "invoice_path": "invoices/abc123.jpg",
    "created_at": "2024-10-28T10:00:00.000000Z"
  }
}
```

---

## Troubleshooting

### Photo Not Uploading?

1. **Check file exists:**
   ```dart
   final file = File(invoiceFilePath);
   print('File exists: ${await file.exists()}');
   ```

2. **Check file size:**
   - Max 10MB allowed
   - Backend returns 422 if too large

3. **Check file type:**
   - Allowed: jpeg, jpg, png, gif, webp
   - Backend returns 422 if invalid

4. **Check internet:**
   - Photos queue offline
   - Sync when connection restored

5. **Check backend logs:**
   ```bash
   tail -f storage/logs/laravel.log
   ```

6. **Check storage permissions:**
   ```bash
   chmod -R 775 storage/app/invoices
   ```

### Common Errors:

**422 Validation Error:**
- File too large (>10MB)
- Invalid file type
- Missing required fields

**File Not Found:**
- Invalid file path
- File deleted before upload
- Permission issues

**Network Error:**
- No internet connection
- Backend not running
- Invalid API URL

---

## Testing

### Quick Test:

1. **Backend running?**
   ```bash
   curl http://localhost:8000/api/v1/health
   ```

2. **Create test expense:**
   - Use app to create expense with photo
   - Check logs for success message
   - Verify in backend: `storage/app/invoices/`

3. **Check database:**
   ```sql
   SELECT id, description, has_invoice, invoice_path 
   FROM expenses 
   ORDER BY id DESC 
   LIMIT 5;
   ```

---

## File Locations

### Backend:
- **Uploaded photos**: `storage/app/invoices/`
- **Validation**: `app/Http/Requests/StoreExpenseRequest.php`
- **Service**: `app/Services/ExpenseService.php`
- **Controller**: `app/Http/Controllers/ExpenseController.php`

### Frontend:
- **DTO**: `lib/features/expenses/data/models/expense_dto.dart`
- **API**: `lib/features/expenses/data/datasources/expense_api_datasource.dart`
- **Repository**: `lib/features/expenses/data/repositories/expense_repository_impl.dart`
- **UI**: `lib/ui/expense_page.dart`

---

## Documentation

- `EXPENSE_PHOTO_UPLOAD_ANALYSIS.md` - Original problem analysis
- `EXPENSE_PHOTO_FEATURE_CHANGELOG.md` - Backend implementation details
- `EXPENSE_PHOTO_UPLOAD_IMPLEMENTATION.md` - Frontend implementation details
- `EXPENSE_PHOTO_FEATURE_COMPLETE.md` - Complete feature summary
- `EXPENSE_PHOTO_QUICK_GUIDE.md` - This file
- `test_expense_photo_upload.dart` - Test script

---

## Support

**Questions?** Check the documentation files above.

**Issues?** Look for `[ExpenseRepository]` logs in console.

**Backend issues?** Check `storage/logs/laravel.log`.

---

**Status**: ✅ Feature is working and ready for production use!

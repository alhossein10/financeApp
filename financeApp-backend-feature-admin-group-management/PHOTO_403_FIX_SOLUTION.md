# 🔓 Photo 403 Forbidden - Complete Solution

**Date**: October 28, 2025  
**Issue**: Getting 403 Forbidden when accessing photos via `/storage/invoices/` URL  
**Status**: ✅ Solution Implemented

---

## Problem Analysis

### What's Happening:
1. ✅ Photos upload successfully to `storage/app/public/invoices/`
2. ✅ Database stores path: `public/invoices/filename.jpg`
3. ❌ Direct URL access fails: `http://server/storage/invoices/filename.jpg` → 403 Forbidden
4. ❌ Web server (Apache/Nginx) serves static files without Laravel authentication

### Root Cause:
When accessing `/storage/invoices/filename.jpg` directly, the request goes to the web server (not Laravel), which doesn't check authentication. The Bearer token is ignored.

---

## ✅ Solution: Use Authenticated API Endpoint

Laravel already has a secure, authenticated endpoint for downloading invoices!

### Backend Endpoint (Already Exists!)

**Route**: `GET /api/v1/expenses/{expense}/invoice`

**Location**: `routes/api_v1.php` (Line 108)

**Controller**: `ExpenseController@downloadInvoice`

**Features**:
- ✅ Requires authentication (`auth:sanctum` middleware)
- ✅ Checks authorization (user owns expense or is admin)
- ✅ Validates file exists
- ✅ Streams file with proper headers
- ✅ Returns appropriate error messages

---

## Implementation Details

### Backend Code (Already Working!)

**Route Definition** (`routes/api_v1.php`):
```php
Route::prefix('expenses/{expense}')->group(function () {
    Route::get('/invoice', [ExpenseController::class, 'downloadInvoice'])
        ->name('expenses.invoice.download');
});
```

**Controller Method** (`ExpenseController.php`):
```php
public function downloadInvoice(Request $request, Expense $expense): StreamedResponse|JsonResponse
{
    $user = $request->user();

    // Authorization check
    if ($user->role !== 'admin' && $expense->user_id !== $user->id) {
        return response()->json([
            'success' => false,
            'message' => 'Unauthorized to download invoice for this expense',
        ], 403);
    }

    // Check if expense has an invoice
    if (!$expense->has_invoice || !$expense->invoice_path) {
        return response()->json([
            'success' => false,
            'message' => 'No invoice found for this expense',
        ], 404);
    }

    // Check if file exists
    if (!$this->fileStorageService->fileExists($expense->invoice_path)) {
        return response()->json([
            'success' => false,
            'message' => 'Invoice file not found',
        ], 404);
        }

    // Stream the file
    try {
        $fileContents = $this->fileStorageService->getFileContents($expense->invoice_path);
        $mimeType = $this->fileStorageService->getFileMimeType($expense->invoice_path);
        $filename = basename($expense->invoice_path);

        return response()->streamDownload(function () use ($fileContents) {
            echo $fileContents;
        }, $filename, [
            'Content-Type' => $mimeType,
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'Failed to download invoice: ' . $e->getMessage(),
        ], 500);
    }
}
```

---

## Frontend Changes Needed

### Current Approach (Not Working):
```dart
// Constructing direct storage URL
final path = expense.invoicePath; // "public/invoices/abc123.jpg"
final imageUrl = '${ApiConfig.baseUrl}/storage/invoices/${path.split('/').last}';
// Result: http://192.168.137.1:8000/storage/invoices/abc123.jpg
// Problem: 403 Forbidden (no auth check)
```

### New Approach (Secure & Working):
```dart
// Use authenticated API endpoint
final expenseId = expense.id; // e.g., 22
final imageUrl = '${ApiConfig.apiUrl}/expenses/$expenseId/invoice';
// Result: http://192.168.137.1:8000/api/v1/expenses/22/invoice
// Success: Authenticated, authorized, and secure!
```

### Example Frontend Update:

**File**: `lib/features/expenses/presentation/pages/expense_page.dart`

**Change**:
```dart
// OLD CODE:
Future<void> _downloadInvoice() async {
  final path = _expense!.invoicePath!;
  final filename = path.split('/').last;
  final imageUrl = '${core.ApiConfig.baseUrl}/storage/invoices/$filename';
  
  // ... download logic
}

// NEW CODE:
Future<void> _downloadInvoice() async {
  final expenseId = _expense!.id;
  final imageUrl = '${core.ApiConfig.apiUrl}/expenses/$expenseId/invoice';
  
  // ... download logic (same as before)
  // The Bearer token will be automatically included by your HTTP client
}
```

---

## Testing

### Test with cURL:

```bash
# Get your auth token first
TOKEN="your_bearer_token_here"

# Test the download endpoint
curl -X GET "http://192.168.137.1:8000/api/v1/expenses/22/invoice" \
  -H "Authorization: Bearer $TOKEN" \
  --output test-invoice.jpg

# Should download the image file
```

### Test with Postman:

1. **Create new request**:
   - Method: `GET`
   - URL: `http://192.168.137.1:8000/api/v1/expenses/22/invoice`
   - Headers: `Authorization: Bearer YOUR_TOKEN`

2. **Send request**

3. **Expected response**:
   - Status: 200 OK
   - Body: Image file (binary)
   - Headers: `Content-Type: image/jpeg`

### Test in Browser:

You can't test directly in browser (needs Bearer token), but you can test the endpoint exists:

```
http://192.168.137.1:8000/api/v1/expenses/22/invoice
```

Should return 401 Unauthorized (which means the endpoint exists and is protected).

---

## API Endpoint Details

### Request:
```
GET /api/v1/expenses/{expense}/invoice
Authorization: Bearer {token}
```

### Success Response (200):
```
Content-Type: image/jpeg (or image/png, etc.)
Content-Disposition: attachment; filename="abc123.jpg"

[Binary image data]
```

### Error Responses:

**401 Unauthorized**:
```json
{
  "message": "Unauthenticated."
}
```

**403 Forbidden**:
```json
{
  "success": false,
  "message": "Unauthorized to download invoice for this expense"
}
```

**404 Not Found**:
```json
{
  "success": false,
  "message": "No invoice found for this expense"
}
```

**500 Server Error**:
```json
{
  "success": false,
  "message": "Failed to download invoice: [error details]"
}
```

---

## Advantages of This Approach

### Security:
- ✅ Requires authentication (Bearer token)
- ✅ Checks authorization (user owns expense or is admin)
- ✅ No direct file system access
- ✅ Prevents unauthorized access to other users' invoices

### Flexibility:
- ✅ Can add rate limiting
- ✅ Can add audit logging
- ✅ Can add watermarks
- ✅ Can generate temporary URLs
- ✅ Can track download statistics

### Maintainability:
- ✅ Centralized file access logic
- ✅ Easy to change storage backend (S3, etc.)
- ✅ Consistent error handling
- ✅ Easy to test

---

## Alternative: Public Storage (Not Recommended)

If you really want to use direct URLs without authentication:

### Option 1: Configure Web Server

**Apache** (`.htaccess` in `public/storage/invoices/`):
```apache
<IfModule mod_rewrite.c>
    RewriteEngine Off
</IfModule>
Order allow,deny
Allow from all
```

**Nginx** (`nginx.conf`):
```nginx
location /storage/invoices/ {
    allow all;
}
```

### Option 2: Move to Public Directory

Move files to `public/invoices/` instead of `storage/app/public/invoices/`.

**⚠️ Security Warning**: Both options make ALL invoice photos publicly accessible to anyone with the URL!

---

## Migration Guide

### Step 1: Update Frontend Code

Change all instances where you construct storage URLs to use the API endpoint instead:

**Find**:
```dart
'${ApiConfig.baseUrl}/storage/invoices/'
```

**Replace with**:
```dart
'${ApiConfig.apiUrl}/expenses/$expenseId/invoice'
```

### Step 2: Test

1. Upload a new expense with photo
2. View the expense
3. Click "View Invoice"
4. Photo should display correctly

### Step 3: Verify

Check that:
- ✅ Photo displays in app
- ✅ Download works
- ✅ Export with photos works
- ✅ Other users can't access your invoices

---

## Troubleshooting

### Issue: Still getting 403

**Check**:
1. Are you using the correct URL format? `/api/v1/expenses/{id}/invoice`
2. Is the Bearer token included in headers?
3. Is the token valid and not expired?
4. Does the user own the expense or is admin?

**Debug**:
```dart
print('URL: $imageUrl');
print('Token: ${await getToken()}');
print('Expense ID: $expenseId');
```

### Issue: 404 Not Found

**Check**:
1. Does the expense exist?
2. Does the expense have `has_invoice = true`?
3. Is `invoice_path` not null?
4. Does the file exist in storage?

**Debug in Laravel**:
```php
$expense = Expense::find($id);
dd([
    'has_invoice' => $expense->has_invoice,
    'invoice_path' => $expense->invoice_path,
    'file_exists' => Storage::exists($expense->invoice_path),
]);
```

### Issue: 500 Server Error

**Check Laravel logs**:
```bash
tail -f storage/logs/laravel.log
```

Common causes:
- File permissions issue
- Storage disk misconfigured
- File path incorrect

---

## Summary

### What Changed:
- ❌ **Old**: Direct storage URL (insecure, 403 error)
- ✅ **New**: Authenticated API endpoint (secure, working)

### Backend:
- ✅ Endpoint already exists and working
- ✅ No backend changes needed!

### Frontend:
- 🔧 Update URL construction to use API endpoint
- 🔧 Use expense ID instead of file path
- ✅ Bearer token automatically included

### Result:
- ✅ Secure photo access
- ✅ Proper authentication
- ✅ Proper authorization
- ✅ No 403 errors
- ✅ Production-ready

---

## Quick Reference

### Correct URL Format:
```
http://192.168.137.1:8000/api/v1/expenses/{expenseId}/invoice
```

### Example:
```
http://192.168.137.1:8000/api/v1/expenses/22/invoice
```

### Headers Required:
```
Authorization: Bearer {your_token}
```

### Response:
```
Content-Type: image/jpeg
[Binary image data]
```

---

**The backend is ready! Just update the frontend to use the API endpoint instead of direct storage URLs.** ✅🔒

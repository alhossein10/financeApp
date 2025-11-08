# 🔒 Backend Photo Access Issue - 403 Forbidden

## Current Status
- ✅ Photos upload successfully
- ✅ Path is stored: `public/invoices/file.jpg`
- ✅ Frontend constructs URL: `http://server/storage/invoices/file.jpg`
- ✅ Auth token is retrieved and sent
- ❌ **Still getting 403 Forbidden**

## Root Cause
Laravel serves files from `public/storage/` directly through the web server (Apache/Nginx), **bypassing Laravel's authentication middleware**. The Bearer token in the request headers is ignored by the web server.

## Solutions

### Option 1: Use Laravel API Endpoint (Recommended - Secure)
Create an authenticated endpoint to serve files through Laravel.

**Backend Changes Needed:**

1. **Add route** in `routes/api.php`:
```php
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/expenses/{expense}/invoice', [ExpenseController::class, 'downloadInvoice']);
});
```

2. **Controller method** already exists (check `ExpenseController@downloadInvoice`)

3. **Frontend change** - Update the URL to use the API endpoint:
```dart
// Instead of: http://server/storage/invoices/file.jpg
// Use: http://server/api/v1/expenses/{expenseId}/invoice
```

### Option 2: Make Storage Public (Not Recommended - Security Risk)
Configure the web server to allow public access to storage files.

**Pros:** Simple, no code changes
**Cons:** Anyone with the URL can access any invoice photo

### Option 3: Use Signed URLs (Best for Production)
Laravel can generate temporary signed URLs that expire.

## Recommended Implementation

### Frontend Update (expense_page.dart)
Instead of constructing the URL from the path, use the expense ID to call the download endpoint:

```dart
// Change from:
final imageUrl = '${core.ApiConfig.baseUrl}/storage/$path';

// To:
final imageUrl = '${core.ApiConfig.apiUrl}/expenses/${expenseId}/invoice';
```

### What Needs to Happen

1. **Check if backend has the download endpoint:**
   - Route: `GET /api/v1/expenses/{expense}/invoice`
   - Should return the image file with proper headers
   - Should check authorization (user owns expense or is admin)

2. **Update frontend to use expense ID instead of path**

3. **Test the endpoint** in browser or Postman with Bearer token

## Quick Test

Try this URL in your browser (replace with actual expense ID):
```
http://192.168.137.1:8000/api/v1/expenses/22/invoice
```

With header:
```
Authorization: Bearer {your_token}
```

If this works, we just need to update the frontend to use this endpoint instead of the direct storage path.

## Next Steps

1. Verify the backend has the invoice download endpoint
2. Test it with Postman/browser
3. Update frontend to use the API endpoint
4. Remove the direct storage URL approach

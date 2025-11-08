# Expense Photo Upload - Status & Guide

## ✅ Photo Upload is Already Implemented!

The expense photo upload feature is fully implemented and should work with your backend.

---

## How It Works

### 1. **Frontend Implementation**

#### When Creating Expense WITHOUT Photo:
```dart
// Uses regular POST request with JSON body
await apiClient.post('/expenses', body: {
  "description": "Test expense",
  "price_usd": 100.5,
  "expense_date": "2024-10-29"
});
```

#### When Creating Expense WITH Photo:
```dart
// Uses multipart/form-data upload
await apiClient.uploadFile(
  '/expenses',
  photoFile,
  fields: {
    "description": "Test expense",
    "price_usd": "100.5",
    "expense_date": "2024-10-29"
  },
  fileFieldName: 'photo',  // ← Backend expects this field name
);
```

### 2. **Backend Response**

Your backend returns:
```json
{
  "success": true,
  "message": "Expense created successfully",
  "data": {
    "id": 1,
    "user_id": 4,
    "description": "Test expense",
    "price_usd": "100.50",
    "expense_date": "2024-10-29T00:00:00.000000Z",
    "has_invoice": true,           // ← Indicates photo was uploaded
    "invoice_path": "/storage/invoices/photo.jpg",  // ← Photo URL
    "sync_status": "synced",
    ...
  }
}
```

### 3. **App Parses Response**

The `ExpenseDto.fromJson()` method extracts:
- ✅ `has_invoice` → Boolean flag
- ✅ `invoice_path` → Photo URL/path

---

## Code Flow

### Creating Expense with Photo

**1. User selects photo in UI**
```dart
// In expense form
File? selectedPhoto = await pickImage();
```

**2. Repository prepares request**
```dart
// lib/features/expenses/data/repositories/expense_repository_impl.dart
File? photoFile;
if (invoiceFilePath != null && invoiceFilePath.isNotEmpty) {
  photoFile = File(invoiceFilePath);
  if (!await photoFile.exists()) {
    print('⚠️ Photo file not found');
    photoFile = null;
  } else {
    print('📷 Photo file found, will upload with expense');
  }
}
```

**3. API datasource sends request**
```dart
// lib/features/expenses/data/datasources/expense_api_datasource.dart
final response = photoFile != null
    ? await apiClient.uploadFile(
        '/expenses',
        photoFile,
        fields: expense.toFormData(),  // ← Converts to Map<String, String>
        fileFieldName: 'photo',
      )
    : await apiClient.post(
        '/expenses',
        body: expense.toJson(),  // ← Converts to Map<String, dynamic>
      );
```

**4. Backend processes upload**
- Receives multipart/form-data
- Saves photo to storage
- Returns `invoice_path` with photo URL

**5. App receives response**
```dart
final createdDto = ExpenseDto.fromJson(response.data['data']);
// createdDto.hasInvoice = true
// createdDto.invoicePath = "/storage/invoices/photo.jpg"
```

---

## Backend Requirements

### What Your Backend Should Accept

**Endpoint:** `POST /api/v1/expenses`

**Content-Type:** `multipart/form-data` (when photo included)

**Fields:**
- `description` (string, required)
- `price_usd` (number, optional)
- `price_syp` (number, optional)
- `price_try` (number, optional)
- `expense_date` (string, required, format: YYYY-MM-DD)
- `photo` (file, optional) ← **Photo field name**

**Response:**
```json
{
  "success": true,
  "message": "Expense created successfully",
  "data": {
    "id": 1,
    "has_invoice": true,
    "invoice_path": "/storage/invoices/filename.jpg",
    ...
  }
}
```

---

## Testing Photo Upload

### Test Steps:

1. **Run the app**
   ```bash
   flutter run --flavor user
   ```

2. **Create expense with photo**
   - Navigate to Expenses
   - Click "Add Expense"
   - Fill in description and amount
   - **Tap camera icon to add photo**
   - Take photo or select from gallery
   - Click Save

3. **Check console logs**
   ```
   [ExpenseRepository] 📷 Photo file found, will upload with expense
   [ExpenseApiDataSource] Has photo: true
   [ApiClient] Request: POST http://192.168.137.1:8000/api/v1/expenses
   [ApiClient] Content-Type: multipart/form-data
   [ExpenseApiDataSource] ✅ Expense created successfully
   [ExpenseRepository] ✅ Photo uploaded successfully
   [ExpenseRepository] 📥 Server invoice path: /storage/invoices/...
   ```

4. **Verify in backend**
   ```sql
   SELECT id, description, has_invoice, invoice_path 
   FROM expenses 
   ORDER BY id DESC 
   LIMIT 1;
   ```

5. **Check photo displays in app**
   - Open the expense details
   - Photo should display from server URL

---

## Photo Display

### How Photos Are Displayed

The app checks `invoice_path` to display photos:

```dart
if (expense.invoicePath != null && expense.invoicePath!.isNotEmpty) {
  // Display photo from server
  Image.network(
    '${ApiConfig.baseUrl}${expense.invoicePath}',
    errorBuilder: (context, error, stackTrace) {
      return Icon(Icons.broken_image);
    },
  );
} else {
  // No photo
  Icon(Icons.receipt);
}
```

### Photo URL Construction

**Backend returns:** `/storage/invoices/photo.jpg`

**App constructs full URL:** `http://192.168.137.1:8000/storage/invoices/photo.jpg`

---

## Troubleshooting

### Issue 1: Photo Not Uploading

**Check:**
- Is photo file path valid?
- Does file exist on device?
- Is backend accepting `multipart/form-data`?
- Is field name `photo` correct?

**Console logs to look for:**
```
[ExpenseRepository] 📷 Photo file found, will upload with expense
[ExpenseApiDataSource] Has photo: true
```

### Issue 2: Photo Not Displaying

**Check:**
- Does backend return `invoice_path`?
- Is `invoice_path` a valid URL or path?
- Is photo accessible from the URL?
- Check CORS settings if needed

**Console logs to look for:**
```
[ExpenseRepository] 📥 Server invoice path: /storage/invoices/...
```

### Issue 3: 422 Validation Error

**Possible causes:**
- Photo file too large
- Invalid file format
- Missing required fields

**Check backend validation rules:**
```php
'photo' => 'nullable|image|max:5120', // 5MB max
```

---

## Backend Example (Laravel)

### Controller Method:
```php
public function store(Request $request)
{
    $validated = $request->validate([
        'description' => 'required|string',
        'price_usd' => 'nullable|numeric',
        'price_syp' => 'nullable|numeric',
        'price_try' => 'nullable|numeric',
        'expense_date' => 'required|date',
        'photo' => 'nullable|image|max:5120', // 5MB max
    ]);

    // Handle photo upload
    if ($request->hasFile('photo')) {
        $path = $request->file('photo')->store('invoices', 'public');
        $validated['invoice_path'] = '/storage/' . $path;
        $validated['has_invoice'] = true;
    } else {
        $validated['has_invoice'] = false;
    }

    $expense = Expense::create($validated);

    return response()->json([
        'success' => true,
        'message' => 'Expense created successfully',
        'data' => $expense,
    ], 201);
}
```

---

## Summary

| Feature | Status | Notes |
|---------|--------|-------|
| Photo upload | ✅ Implemented | Uses multipart/form-data |
| Photo parsing | ✅ Implemented | Parses `invoice_path` and `has_invoice` |
| Photo display | ✅ Implemented | Shows from server URL |
| Field name | ✅ Correct | Uses `photo` as field name |
| Validation | ✅ Implemented | Checks file exists before upload |
| Logging | ✅ Enhanced | Detailed logs for debugging |

---

## Files Involved

1. **API Datasource:** `lib/features/expenses/data/datasources/expense_api_datasource.dart`
   - Handles photo upload with `uploadFile()`

2. **Repository:** `lib/features/expenses/data/repositories/expense_repository_impl.dart`
   - Prepares photo file
   - Validates file exists

3. **DTO:** `lib/features/expenses/data/models/expense_dto.dart`
   - Parses `has_invoice` and `invoice_path`
   - Converts to form data for upload

4. **API Client:** `lib/core/api/api_client.dart`
   - Handles multipart/form-data upload

---

## Next Steps

1. **Test without photo** - Should work (already fixed)
2. **Test with photo** - Should work (already implemented)
3. **Verify photo displays** - Check if URL is correct
4. **Check backend storage** - Ensure photos are saved

If you encounter any issues with photo upload, share:
- Console logs showing the upload attempt
- Backend response
- Any error messages

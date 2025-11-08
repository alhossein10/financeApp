# Expense Photo Upload Feature

## Overview
The expenses API now supports optional photo/invoice uploads when creating or updating expense records. Photos are stored securely and can be attached to any expense.

## Features
- **Optional**: Photo upload is completely optional - you can create expenses without photos
- **File Types**: Supports JPEG, JPG, PNG, GIF, and WebP formats
- **Size Limit**: Maximum file size is 10MB
- **Auto-cleanup**: When updating an expense with a new photo, the old photo is automatically deleted
- **Secure Storage**: Photos are stored in the `storage/app/invoices` directory

## API Usage

### Creating an Expense with Photo

**Endpoint**: `POST /api/v1/expenses`

**Content-Type**: `multipart/form-data`

**Request Body**:
```
description: "Office supplies"
price_usd: 50.00
price_syp: 125000.00 (optional)
price_try: 1500.00 (optional)
expense_date: "2025-10-22"
photo: [file] (optional)
sync_status: "synced" (optional)
```

**Example using cURL**:
```bash
curl -X POST http://localhost:8000/api/v1/expenses \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "description=Office supplies" \
  -F "price_usd=50.00" \
  -F "expense_date=2025-10-22" \
  -F "photo=@/path/to/photo.jpg"
```

**Example using JavaScript/Fetch**:
```javascript
const formData = new FormData();
formData.append('description', 'Office supplies');
formData.append('price_usd', '50.00');
formData.append('expense_date', '2025-10-22');
formData.append('photo', fileInput.files[0]); // from <input type="file">

fetch('http://localhost:8000/api/v1/expenses', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer YOUR_TOKEN'
  },
  body: formData
});
```

### Updating an Expense with Photo

**Endpoint**: `POST /api/v1/expenses/{id}` (with `_method=PUT`)

**Content-Type**: `multipart/form-data`

**Note**: Laravel requires method spoofing for file uploads with PUT/PATCH requests. Use POST with `_method=PUT`.

**Request Body**:
```
_method: "PUT"
description: "Updated office supplies" (optional)
price_usd: 60.00 (optional)
expense_date: "2025-10-23" (optional)
photo: [file] (optional)
```

**Example using cURL**:
```bash
curl -X POST http://localhost:8000/api/v1/expenses/123 \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "_method=PUT" \
  -F "description=Updated office supplies" \
  -F "photo=@/path/to/new-photo.jpg"
```

**Example using JavaScript/Fetch**:
```javascript
const formData = new FormData();
formData.append('_method', 'PUT');
formData.append('description', 'Updated office supplies');
formData.append('photo', fileInput.files[0]);

fetch('http://localhost:8000/api/v1/expenses/123', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer YOUR_TOKEN'
  },
  body: formData
});
```

## Response Format

The response includes the expense data with photo information:

```json
{
  "success": true,
  "message": "Expense created successfully",
  "data": {
    "id": 123,
    "user_id": 1,
    "description": "Office supplies",
    "price_usd": 50.00,
    "price_syp": 125000.00,
    "price_try": 1500.00,
    "expense_date": "2025-10-22",
    "has_invoice": true,
    "invoice_path": "invoices/abc123def456.jpg",
    "sync_status": "synced",
    "created_at": "2025-10-22T10:30:00.000000Z",
    "updated_at": "2025-10-22T10:30:00.000000Z"
  }
}
```

## Validation Rules

- **photo**: Optional file upload
- **Type**: Must be an image (jpeg, jpg, png, gif, webp)
- **Size**: Maximum 10MB (10240 KB)
- **Validation errors** return 422 status with error details

## Flutter/Mobile Implementation Example

```dart
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

Future<void> createExpenseWithPhoto() async {
  // Pick image
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  
  if (image == null) return;
  
  // Create multipart request
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://localhost:8000/api/v1/expenses'),
  );
  
  // Add headers
  request.headers['Authorization'] = 'Bearer YOUR_TOKEN';
  
  // Add fields
  request.fields['description'] = 'Office supplies';
  request.fields['price_usd'] = '50.00';
  request.fields['expense_date'] = '2025-10-22';
  
  // Add photo file
  request.files.add(
    await http.MultipartFile.fromPath('photo', image.path)
  );
  
  // Send request
  var response = await request.send();
  var responseData = await response.stream.bytesToString();
  
  print(responseData);
}
```

## Notes

1. **Optional Field**: The photo field is completely optional. You can create/update expenses without providing a photo.

2. **Automatic Cleanup**: When updating an expense with a new photo, the old photo is automatically deleted from storage.

3. **File Storage**: Photos are stored in `storage/app/invoices` directory and are not publicly accessible by default.

4. **Existing Invoice Endpoints**: The existing invoice upload/delete endpoints (`POST /api/v1/expenses/{id}/invoice` and `DELETE /api/v1/expenses/{id}/invoice`) still work and can be used as an alternative method.

5. **Method Spoofing**: For PUT/PATCH requests with file uploads, use POST with `_method=PUT` or `_method=PATCH` field.

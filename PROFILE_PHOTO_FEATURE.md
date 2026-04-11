# Profile Photo Upload Feature

## Overview
Users and admins can now upload, view, and delete profile photos for their accounts.

## Database Changes
- Added `profile_photo_path` column to `users` table (nullable string)
- Migration: `2025_11_16_160422_add_profile_photo_to_users_table.php`

## API Endpoints

### 1. Upload Profile Photo
**POST** `/api/v1/profile/photo`

**Headers:**
- `Authorization: Bearer {token}`
- `Content-Type: multipart/form-data`

**Body:**
- `photo` (file, required): Image file (JPEG, PNG, GIF, WEBP, max 10MB)

**Response:**
```json
{
  "success": true,
  "message": "Profile photo uploaded successfully",
  "data": {
    "profile_photo_path": "public/profile-photos/abc123.jpg",
    "profile_photo_url": "http://localhost:8000/storage/profile-photos/abc123.jpg"
  }
}
```

### 2. Delete Profile Photo
**DELETE** `/api/v1/profile/photo`

**Headers:**
- `Authorization: Bearer {token}`

**Response:**
```json
{
  "success": true,
  "message": "Profile photo deleted successfully"
}
```

### 3. Get Profile (includes photo)
**GET** `/api/v1/profile`

**Headers:**
- `Authorization: Bearer {token}`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "admin",
    "profile_photo_path": "public/profile-photos/abc123.jpg",
    "profile_photo_url": "http://localhost:8000/storage/profile-photos/abc123.jpg",
    "email_verified_at": "2025-11-16T10:00:00.000000Z",
    "created_at": "2025-11-16T10:00:00.000000Z",
    "updated_at": "2025-11-16T10:00:00.000000Z"
  }
}
```

## Features

### Image Processing
- Automatic image compression (max 1920px width)
- Supported formats: JPEG, JPG, PNG, GIF, WEBP
- Maximum file size: 10MB
- Images stored in `storage/app/public/profile-photos/`

### Security
- Users can only upload/delete their own profile photos
- File validation middleware applied
- Old photos automatically deleted when uploading new ones
- Photos deleted when user account is deleted

### Storage
- Photos stored using Laravel's FileStorageService
- Automatic cleanup on update/delete
- Public URL generation for frontend display

## Implementation Details

### Modified Files
1. **Migration**: `database/migrations/2025_11_16_160422_add_profile_photo_to_users_table.php`
2. **Model**: `app/Models/User.php` - Added `profile_photo_path` to fillable
3. **Service**: `app/Services/UserProfileService.php` - Added upload/delete methods
4. **Controller**: `app/Http/Controllers/UserProfileController.php` - Added endpoints
5. **Routes**: `routes/api_v1.php` - Added photo routes

### Service Methods
- `uploadProfilePhoto(User $user, UploadedFile $file): User`
- `deleteProfilePhoto(User $user): User`
- `getProfile(User $user): array` - Now includes photo URL

## Testing with Postman

### Upload Photo
1. Create a new POST request to `{{base_url}}/profile/photo`
2. Add Authorization header with Bearer token
3. In Body tab, select "form-data"
4. Add key "photo" with type "File"
5. Select an image file
6. Send request

### View Profile with Photo
1. Create a GET request to `{{base_url}}/profile`
2. Add Authorization header with Bearer token
3. Send request
4. Check `profile_photo_url` in response

### Delete Photo
1. Create a DELETE request to `{{base_url}}/profile/photo`
2. Add Authorization header with Bearer token
3. Send request

## Frontend Integration

### Display Profile Photo
```dart
// Flutter example
if (user.profilePhotoUrl != null) {
  Image.network(user.profilePhotoUrl!)
} else {
  // Show default avatar
  CircleAvatar(child: Icon(Icons.person))
}
```

### Upload Photo
```dart
// Flutter example
final picker = ImagePicker();
final image = await picker.pickImage(source: ImageSource.gallery);

if (image != null) {
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/profile/photo'),
  );
  request.headers['Authorization'] = 'Bearer $token';
  request.files.add(await http.MultipartFile.fromPath('photo', image.path));
  
  final response = await request.send();
  // Handle response
}
```

## Notes
- Profile photos are optional (nullable field)
- Existing users will have `null` profile_photo_path by default
- The feature works for all user roles (user, admin, superAdmin)
- Photos are automatically compressed to optimize storage and bandwidth

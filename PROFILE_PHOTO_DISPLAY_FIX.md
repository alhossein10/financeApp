# Profile Photo Display Fix

## Issue
After uploading a profile photo successfully, the photo was not appearing in the app even though the backend returned success with the photo URL.

## Root Cause
1. **Field Name Mismatch**: Backend returns `profile_photo_url` but UserDTO was only checking for `profile_image_url`
2. **Profile Refresh**: After upload, the profile data needs to be reloaded to display the new photo

## Fixes Applied

### 1. UserDTO Field Mapping (`lib/core/api/models/user_dto.dart`)
Updated to handle both `profile_photo_url` (new) and `profile_image_url` (old):

```dart
// Before
profileImageUrl: userData['profile_image_url'] as String?,

// After  
profileImageUrl: userData['profile_photo_url'] as String? ?? userData['profile_image_url'] as String?,
```

### 2. ProfileInfoCard Photo URL (`lib/features/profile/presentation/widgets/profile_info_card.dart`)
Simplified to use only the profileImageUrl from the user entity:

```dart
// Before
ProfilePhotoWidget(
  photoUrl: user.profileImageUrl ?? 
           (user.profilePicturePath != null ? 'file://${user.profilePicturePath}' : null),
  size: 100,
),

// After
ProfilePhotoWidget(
  photoUrl: user.profileImageUrl,
  size: 100,
),
```

## How It Works Now

1. **Upload Photo**:
   - User taps profile picture → selects image
   - `ProfilePhotoUploadRequested` event is triggered
   - Photo is uploaded to backend via multipart request
   - Backend returns success with `profile_photo_url`

2. **Profile Reload**:
   - After successful upload, `getUserProfileUseCase()` is called
   - Profile data is fetched from `/api/v1/profile`
   - UserDTO maps `profile_photo_url` to `profileImageUrl`
   - User entity is updated with new photo URL

3. **Display Photo**:
   - ProfilePhotoWidget receives updated `profileImageUrl`
   - Image is displayed using `NetworkImage`
   - If no photo, default avatar icon is shown

## Backend Response Format

The backend now returns:
```json
{
  "success": true,
  "data": {
    "id": 2,
    "name": "admin",
    "email": "admin@gmail.com",
    "role": "admin",
    "profile_photo_path": "public/profile-photos/xxx.jpg",
    "profile_photo_url": "http://127.0.0.1:8000/api/v1/files/download?path=encrypted_path",
    "created_at": "2025-11-08T12:25:35.000000Z",
    "updated_at": "2025-11-16T16:21:42.000000Z"
  }
}
```

## Testing Steps

1. **Hot Restart the App** (important to apply the UserDTO fix)
2. Navigate to Profile page
3. Tap on profile picture
4. Select "Take Photo" or "Choose from Gallery"
5. Select an image
6. Wait for upload success message
7. **Photo should now appear immediately**

## Notes

- The encrypted download URL from backend is handled automatically by Flutter's NetworkImage
- Photos are cached by the app for better performance
- If photo still doesn't appear, check:
  - Backend storage symlink: `php artisan storage:link`
  - File permissions on backend
  - Network connectivity
  - Backend logs for any errors

## Files Modified
1. `lib/core/api/models/user_dto.dart` - Added support for `profile_photo_url`
2. `lib/features/profile/presentation/widgets/profile_info_card.dart` - Simplified photo URL usage

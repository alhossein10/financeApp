# Profile Photo Testing Guide

## Quick Start

Your Flutter app is **fully integrated** with the Laravel backend profile photo feature. Here's how to test it:

---

## Prerequisites

1. **Backend Running**: Ensure Laravel backend is running
   ```bash
   php artisan serve
   ```

2. **Storage Linked**: Ensure storage is linked (run once)
   ```bash
   php artisan storage:link
   ```

3. **API Configuration**: Verify API URL in `lib/core/config/api_config.dart`
   ```dart
   static const String apiUrl = 'http://localhost:8000/api/v1';
   // or your production URL
   ```

---

## Testing Steps

### 1. Run the App

```bash
# User flavor
flutter run --flavor user --dart-define=FLAVOR=user

# Admin flavor
flutter run --flavor admin --dart-define=FLAVOR=admin

# SuperAdmin flavor
flutter run --flavor superadmin --dart-define=FLAVOR=superadmin
```

### 2. Navigate to Profile Page

1. Login with your credentials
2. Navigate to Profile page (usually in bottom navigation or drawer)

### 3. Test Photo Upload

#### From Gallery:
1. Tap on the profile photo (circular avatar with camera icon)
2. Select "Choose from Gallery"
3. Pick an image
4. Wait for upload (shows loading indicator)
5. Photo should appear immediately after upload

#### From Camera:
1. Tap on the profile photo
2. Select "Take Photo"
3. Take a photo
4. Wait for upload
5. Photo should appear immediately after upload

### 4. Test Photo View

1. Tap on profile photo
2. Select "View Photo"
3. Full-screen photo viewer should appear
4. Pinch to zoom should work
5. Close button should dismiss viewer

### 5. Test Photo Delete

1. Tap on profile photo
2. Select "Delete Photo"
3. Confirm deletion in dialog
4. Photo should be removed
5. Default avatar (person icon) should appear

---

## Expected Behavior

### Upload Success
- ✅ Loading indicator appears during upload
- ✅ Success message: "Profile photo uploaded successfully"
- ✅ Photo appears in profile page
- ✅ Photo persists after app restart
- ✅ Photo appears in other locations (group lists, etc.)

### Upload Failure
- ❌ Error message appears with reason
- ❌ Common errors:
  - "File too large" (max 10MB)
  - "Invalid file format" (only JPEG, PNG, GIF, WEBP)
  - "Network error" (check backend connection)
  - "Unauthorized" (token expired, re-login)

### Delete Success
- ✅ Loading indicator appears during delete
- ✅ Success message: "Profile photo deleted successfully"
- ✅ Default avatar appears
- ✅ Photo removed from backend

---

## Testing Checklist

### Basic Functionality
- [ ] Upload photo from gallery works
- [ ] Upload photo from camera works
- [ ] Photo displays correctly after upload
- [ ] Photo persists after app restart
- [ ] Delete photo works
- [ ] Default avatar shows after delete

### Image Formats
- [ ] JPEG images work
- [ ] PNG images work
- [ ] GIF images work (if supported by backend)
- [ ] WEBP images work (if supported by backend)

### Image Sizes
- [ ] Small images (< 100KB) work
- [ ] Medium images (100KB - 1MB) work
- [ ] Large images (1MB - 5MB) work and are compressed
- [ ] Very large images (> 5MB) work and are compressed

### Error Handling
- [ ] Invalid file format shows error
- [ ] Network error shows appropriate message
- [ ] Unauthorized error prompts re-login
- [ ] Backend error shows user-friendly message

### UI/UX
- [ ] Loading indicator shows during upload/delete
- [ ] Success messages appear
- [ ] Error messages are clear and helpful
- [ ] Photo viewer works (zoom, close)
- [ ] Bottom sheet options are clear

### Cross-Platform
- [ ] Works on Android
- [ ] Works on iOS
- [ ] Camera permission requested on first use
- [ ] Gallery permission requested on first use

### Integration
- [ ] Photo appears in profile page
- [ ] Photo appears in navigation drawer
- [ ] Photo appears in group member lists
- [ ] Photo appears in admin group management
- [ ] Photo appears in superadmin analytics

---

## Common Issues & Solutions

### Issue: "No authentication token available"
**Cause**: User not logged in or token expired  
**Solution**: Logout and login again

### Issue: "File does not exist"
**Cause**: Image picker returned invalid path  
**Solution**: Try again or restart app

### Issue: Photo not displaying after upload
**Cause**: Cache issue or network error  
**Solution**: 
1. Pull to refresh on profile page
2. Restart app
3. Check network connection

### Issue: "Failed to upload profile photo"
**Cause**: Backend not running or storage not linked  
**Solution**:
1. Ensure backend is running: `php artisan serve`
2. Link storage: `php artisan storage:link`
3. Check API URL in `api_config.dart`

### Issue: Upload takes too long
**Cause**: Large image file  
**Solution**: App automatically compresses images, but very large files may take time. Wait for completion.

### Issue: Photo shows 404 error
**Cause**: Backend storage not linked  
**Solution**: Run `php artisan storage:link` on backend

---

## Debug Mode

To see detailed logs during testing:

1. **Check Flutter logs**:
   ```bash
   flutter logs
   ```

2. **Look for these log messages**:
   - `🔵 [UserDTO] Parsing JSON` - User data parsing
   - `✅ [UserDTO] Parsed successfully` - User data parsed
   - `🔴 [UserDTO] Parse error` - User data parsing failed

3. **Check backend logs**:
   ```bash
   tail -f storage/logs/laravel.log
   ```

---

## API Endpoints Being Used

### Upload Photo
```
POST /api/v1/profile/photo
Content-Type: multipart/form-data
Authorization: Bearer {token}

Body:
- photo: File

Response:
{
  "success": true,
  "message": "Profile photo uploaded successfully",
  "data": {
    "profile_photo_path": "public/profile-photos/abc123.jpg",
    "profile_photo_url": "http://localhost:8000/storage/profile-photos/abc123.jpg"
  }
}
```

### Delete Photo
```
DELETE /api/v1/profile/photo
Authorization: Bearer {token}

Response:
{
  "success": true,
  "message": "Profile photo deleted successfully"
}
```

### Get Profile (includes photo URL)
```
GET /api/v1/auth/me
Authorization: Bearer {token}

Response:
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user",
      "profile_photo_url": "http://localhost:8000/storage/profile-photos/abc123.jpg",
      ...
    }
  }
}
```

---

## Performance Notes

### Image Compression
- App automatically compresses images to max 1MB
- Max dimensions: 512x512 pixels
- Quality: 85% (adjusts down if needed)
- Format: JPEG (for best compression)

### Upload Time
- Small images (< 100KB): < 1 second
- Medium images (100KB - 1MB): 1-3 seconds
- Large images (1MB - 5MB): 3-10 seconds (after compression)

---

## Next Steps After Testing

1. ✅ Verify all checklist items pass
2. ✅ Test on both Android and iOS
3. ✅ Test with different image sizes and formats
4. ✅ Test error scenarios (network off, invalid files)
5. ✅ Verify photos appear in all locations
6. ✅ Test with all three flavors (user, admin, superadmin)

---

## Support

If you encounter issues:

1. Check this guide first
2. Review `PROFILE_PHOTO_INTEGRATION_STATUS.md`
3. Check backend logs: `storage/logs/laravel.log`
4. Check Flutter logs: `flutter logs`
5. Verify API configuration in `api_config.dart`

---

**Status**: ✅ Ready for Testing  
**Last Updated**: November 16, 2025

# Profile Photo Feature - Quick Reference Guide

## For Users

### How to Upload a Profile Photo
1. Open the app and navigate to **Profile** page
2. Tap on your profile picture (or the default avatar)
3. Choose one of the options:
   - **Take Photo**: Opens camera to take a new photo
   - **Choose from Gallery**: Select an existing photo
4. Select your image
5. Wait for upload to complete
6. Your new profile photo will appear immediately

### How to View Your Profile Photo
1. Navigate to **Profile** page
2. Tap on your profile picture
3. Select **View Photo**
4. Use pinch-to-zoom to see details
5. Tap **Close** to return

### How to Delete Your Profile Photo
1. Navigate to **Profile** page
2. Tap on your profile picture
3. Select **Delete Photo**
4. Confirm deletion
5. Your profile will show the default avatar

## For Developers

### API Endpoints

#### Upload Photo
```http
POST /api/v1/profile/photo
Authorization: Bearer {token}
Content-Type: multipart/form-data

Body:
- photo: (file)
```

#### Delete Photo
```http
DELETE /api/v1/profile/photo
Authorization: Bearer {token}
```

#### Get Profile (includes photo)
```http
GET /api/v1/profile
Authorization: Bearer {token}
```

### Usage in Code

#### Upload Photo
```dart
// In your widget
context.read<ProfileBloc>().add(
  ProfilePhotoUploadRequested(filePath: '/path/to/image.jpg'),
);
```

#### Delete Photo
```dart
// In your widget
context.read<ProfileBloc>().add(
  const ProfilePhotoDeleteRequested(),
);
```

#### Display Photo
```dart
// Use ProfilePhotoWidget
ProfilePhotoWidget(
  photoUrl: user.profileImageUrl,
  size: 100,
)
```

### BLoC States to Handle

```dart
BlocListener<ProfileBloc, ProfileState>(
  listener: (context, state) {
    if (state is ProfilePhotoUploadSuccess) {
      // Photo uploaded successfully
      // state.photoUrl contains the new photo URL
    } else if (state is ProfilePhotoDeleteSuccess) {
      // Photo deleted successfully
    } else if (state is ProfileError) {
      // Handle error
      // state.message contains error details
    }
  },
)
```

## Image Requirements

### Supported Formats
- JPEG (.jpg, .jpeg)
- PNG (.png)
- GIF (.gif)
- WEBP (.webp)

### Size Limits
- **Maximum file size**: 10MB
- **Recommended dimensions**: 512x512 to 1920x1920 pixels
- **Automatic compression**: Images are compressed to max 1920px width

## Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "File does not exist" | Invalid file path | Ensure file exists before upload |
| "Validation failed" | File too large or wrong format | Check file size and format |
| "No authentication token" | Not logged in | Login again |
| "Failed to upload" | Network issue | Check internet connection |

## Testing Checklist

- [ ] Upload photo from camera
- [ ] Upload photo from gallery
- [ ] View uploaded photo
- [ ] Delete uploaded photo
- [ ] Upload different image formats (JPEG, PNG)
- [ ] Try uploading large file (>10MB) - should fail gracefully
- [ ] Test with no internet connection
- [ ] Test with expired token
- [ ] Verify photo persists after app restart
- [ ] Verify photo displays on other devices (if synced)

## Troubleshooting

### Photo Not Uploading
1. Check internet connection
2. Verify file size is under 10MB
3. Ensure file format is supported
4. Check authentication token is valid
5. Review backend logs for errors

### Photo Not Displaying
1. Verify upload was successful
2. Check `profile_photo_url` in API response
3. Ensure image URL is accessible
4. Check for CORS issues (web only)
5. Verify storage symlink on backend

### Photo Upload Slow
1. Check image file size
2. Consider reducing image quality
3. Check network speed
4. Backend may be compressing image

## Backend Configuration

### Storage Setup
```bash
# Ensure storage is linked
php artisan storage:link

# Verify permissions
chmod -R 775 storage/app/public/profile-photos
```

### Environment Variables
```env
# In .env file
FILESYSTEM_DISK=public
```

## Security Notes

- ✅ Users can only upload/delete their own photos
- ✅ File validation on both frontend and backend
- ✅ Bearer token authentication required
- ✅ Old photos automatically deleted on new upload
- ✅ Photos deleted when account is deleted
- ✅ Maximum file size enforced (10MB)
- ✅ Only image formats allowed

## Performance Tips

1. **Image Compression**: Images are automatically compressed to 1920px max width
2. **Caching**: Profile photos are cached by the browser/app
3. **Lazy Loading**: Photos load only when profile page is opened
4. **Optimized Upload**: Uses multipart form data for efficient upload

## Future Enhancements (Optional)

- [ ] Image cropping before upload
- [ ] Image filters/effects
- [ ] Multiple profile photos (gallery)
- [ ] Photo history/versioning
- [ ] Batch upload for admins
- [ ] Photo moderation for superadmins
- [ ] Custom photo frames/borders
- [ ] AI-powered photo enhancement

## Support

For issues or questions:
1. Check this guide first
2. Review backend logs
3. Check network requests in browser/app
4. Verify API endpoints are accessible
5. Contact backend team if API issues persist

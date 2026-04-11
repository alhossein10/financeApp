# Profile Image Upload - Quick Reference Guide

## For Developers

### Using ProfileImageUploadService

```dart
// Get service from dependency injection
final uploadService = di.sl<ProfileImageUploadService>();

// Pick image from gallery
final imageFile = await uploadService.pickImageFromGallery();

// Pick image from camera
final imageFile = await uploadService.pickImageFromCamera();

// Compress image
final compressedFile = await uploadService.compressImage(imageFile);

// Upload with progress tracking
final imageUrl = await uploadService.uploadProfileImage(
  imageFile,
  onProgress: (progress) {
    print('Upload progress: ${(progress * 100).toInt()}%');
  },
);
```

### Using ProfileImageUpload Widget

```dart
ProfileImageUpload(
  currentImageUrl: user.profileImageUrl,
  uploadService: di.sl<ProfileImageUploadService>(),
  onImageUploaded: (imageUrl) {
    // Handle successful upload
    print('Image uploaded: $imageUrl');
  },
  size: 100, // Optional, defaults to 120
)
```

### Integrating in Profile Page

```dart
ProfileInfoCard(
  user: profileData.user,
  onEditPressed: () => _showEditDialog(context),
  onProfilePicturePressed: () => _showOptions(context),
  uploadService: di.sl<ProfileImageUploadService>(),
  onImageUploaded: (imageUrl) {
    // Reload profile to show new image
    context.read<ProfileBloc>().add(const ProfileLoadRequested());
  },
)
```

## For Backend Developers

### Required API Endpoints

#### 1. Upload Profile Image
```
POST /profile/upload-image
Content-Type: multipart/form-data

Request:
- profile_image: File (image file)

Response:
{
  "success": true,
  "data": {
    "profile_image_url": "https://example.com/storage/profiles/user123.jpg"
  }
}
```

#### 2. Update Profile with Image URL
```
PUT /profile/image
Content-Type: application/json

Request:
{
  "profile_image_url": "https://example.com/storage/profiles/user123.jpg"
}

Response:
{
  "success": true,
  "data": {
    "id": 123,
    "name": "John Doe",
    "email": "john@example.com",
    "profile_image_url": "https://example.com/storage/profiles/user123.jpg",
    ...
  }
}
```

### Database Schema

Add `profile_image_url` column to users table:

```sql
ALTER TABLE users ADD COLUMN profile_image_url VARCHAR(255) NULL;
```

### Include in API Responses

Ensure `profile_image_url` is included in:
- User profile responses
- Group member lists (Admin group members)
- Group member lists (User group members)
- Authentication responses

## For Users

### Uploading Profile Picture

1. **Navigate to Profile:**
   - Tap on "Profile" in the bottom navigation

2. **Upload Image:**
   - Tap the camera icon on your profile picture
   - Choose "Take Photo" or "Choose from Gallery"
   - Select/capture your image
   - Wait for upload to complete (progress shown)

3. **View Result:**
   - Your new profile picture appears immediately
   - It's visible to your group manager

### Image Requirements

- **Supported Formats:** JPG, JPEG, PNG, GIF, WEBP
- **Maximum Size:** 1MB (automatically compressed)
- **Recommended Size:** 512x512 pixels or larger
- **Aspect Ratio:** Square images work best

### Troubleshooting

**Upload Failed:**
- Check internet connection
- Ensure image is valid format
- Try a smaller image
- Retry upload

**Image Not Showing:**
- Pull down to refresh profile
- Check if upload completed successfully
- Restart app if issue persists

## Image Compression Details

### Automatic Compression
- Images over 1MB are automatically compressed
- Maintains aspect ratio
- Resizes to max 512x512 pixels
- Quality starts at 85% and reduces if needed
- Minimum quality: 50%

### Compression Algorithm
```
1. Check file size
2. If > 1MB:
   a. Decode image
   b. Resize to 512x512 (maintain aspect ratio)
   c. Compress at 85% quality
   d. If still > 1MB, reduce quality by 10%
   e. Repeat until < 1MB or quality < 50%
3. Return compressed file
```

## Security Considerations

### Client-Side
- File type validation before upload
- Size validation before upload
- Secure storage of image URLs
- HTTPS for all image uploads

### Server-Side (Recommendations)
- Validate file type on server
- Scan for malware
- Limit file size (max 5MB before compression)
- Store in secure location
- Use CDN for serving images
- Implement rate limiting

## Performance Tips

### For Developers
1. **Caching:**
   - Use `CachedNetworkImage` for better performance
   - Cache profile images locally

2. **Lazy Loading:**
   - Load images only when visible
   - Use placeholders while loading

3. **Optimization:**
   - Serve different sizes for different contexts
   - Use WebP format for better compression
   - Implement progressive loading

### For Users
1. Use smaller images when possible
2. Ensure good internet connection for upload
3. Close other apps during upload

## Common Issues and Solutions

### Issue: Upload Takes Too Long
**Solution:**
- Use smaller image
- Check internet speed
- Try compressing image manually first

### Issue: Image Quality Poor
**Solution:**
- Upload higher quality original image
- Ensure original is at least 512x512 pixels
- Avoid uploading already compressed images

### Issue: Profile Image Not Updating
**Solution:**
- Pull to refresh profile page
- Check if upload completed successfully
- Verify internet connection
- Restart app

### Issue: Camera Not Working
**Solution:**
- Grant camera permissions in device settings
- Restart app
- Try gallery option instead

## Testing Checklist

### Manual Testing
- [ ] Upload from gallery works
- [ ] Upload from camera works
- [ ] Progress indicator shows correctly
- [ ] Image displays after upload
- [ ] Image shows in group lists
- [ ] Error handling works
- [ ] Compression works for large images
- [ ] Works on different devices
- [ ] Works on different network speeds

### Automated Testing
- [ ] Unit tests for compression
- [ ] Unit tests for validation
- [ ] Widget tests for UI
- [ ] Integration tests for upload flow

## API Response Examples

### Successful Upload
```json
{
  "success": true,
  "data": {
    "profile_image_url": "https://api.example.com/storage/profiles/abc123.jpg",
    "file_size": 856432,
    "uploaded_at": "2024-01-15T10:30:00Z"
  }
}
```

### Upload Error
```json
{
  "success": false,
  "message": "Invalid file format",
  "errors": {
    "profile_image": ["The file must be an image (jpg, jpeg, png, gif, webp)"]
  }
}
```

### Profile Update Success
```json
{
  "success": true,
  "data": {
    "id": 123,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "user",
    "profile_image_url": "https://api.example.com/storage/profiles/abc123.jpg",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

## File Structure

```
lib/
├── core/
│   └── services/
│       └── profile_image_upload_service.dart
├── features/
│   ├── profile/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── profile_api_datasource.dart
│   │   │   └── repositories/
│   │   │       └── profile_repository_impl.dart
│   │   └── presentation/
│   │       └── widgets/
│   │           ├── profile_image_upload.dart
│   │           └── profile_info_card.dart
│   ├── admin/
│   │   └── presentation/
│   │       └── widgets/
│   │           └── user_list_card.dart
│   ├── superadmin/
│   │   ├── data/
│   │   │   └── models/
│   │   │       └── admin_member_dto.dart
│   │   └── presentation/
│   │       └── widgets/
│   │           └── admin_list_card.dart
│   └── admin_group/
│       └── data/
│           └── models/
│               └── group_member_dto.dart
└── injection_container.dart
```

## Dependencies

```yaml
dependencies:
  image_picker: ^1.0.7  # For picking images
  image: ^4.2.0         # For image compression
  path_provider: ^2.0.0 # For temporary file storage
```

## Quick Commands

### Run with Profile Image Feature
```bash
flutter run
```

### Test Profile Image Upload
```bash
flutter test test/features/profile/
```

### Build with Profile Images
```bash
flutter build apk --release
```

## Support

For issues or questions:
1. Check this guide first
2. Review implementation summary
3. Check API documentation
4. Contact development team

# Frontend Quick Reference - Backend Updates

## What Changed?

### 1. Expense List Fix ✅
**Problem**: Expenses created from frontend weren't showing in list  
**Status**: FIXED - All expenses now appear correctly

### 2. Profile Photo Feature ✅
**New Feature**: Users can upload/delete profile photos  
**Status**: COMPLETE - Ready to integrate

---

## API Changes

### New Field in User Object
All endpoints returning user data now include:

```json
{
  "profile_photo_path": "public/profile-photos/abc123.jpg",
  "profile_photo_url": "http://localhost:8000/storage/profile-photos/abc123.jpg"
}
```

**Affected Endpoints:**
- `/auth/me`
- `/auth/login`
- `/profile`
- `/admin/group/members`
- `/superadmin/group/members`

### New Endpoints

#### 1. Upload Profile Photo
```
POST /api/v1/profile/photo
Content-Type: multipart/form-data

Body:
- photo: File (JPEG, PNG, GIF, WEBP, max 10MB)

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

#### 2. Delete Profile Photo
```
DELETE /api/v1/profile/photo

Response:
{
  "success": true,
  "message": "Profile photo deleted successfully"
}
```

---

## Flutter Integration

### 1. Update User Model

```dart
class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? profilePhotoPath;
  final String? profilePhotoUrl; // ✅ ADD THIS

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        email = json['email'],
        role = json['role'],
        profilePhotoPath = json['profile_photo_path'],
        profilePhotoUrl = json['profile_photo_url']; // ✅ ADD THIS

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'profile_photo_path': profilePhotoPath,
        'profile_photo_url': profilePhotoUrl, // ✅ ADD THIS
      };
}
```

### 2. Display Profile Photo

```dart
Widget buildProfileAvatar(User user) {
  if (user.profilePhotoUrl != null && user.profilePhotoUrl!.isNotEmpty) {
    return CircleAvatar(
      radius: 40,
      backgroundImage: NetworkImage(user.profilePhotoUrl!),
      onBackgroundImageError: (_, __) {
        // Fallback to default avatar on error
      },
    );
  }
  
  // Default avatar
  return CircleAvatar(
    radius: 40,
    backgroundColor: Colors.grey[300],
    child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
  );
}
```

### 3. Upload Profile Photo

```dart
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

Future<void> uploadProfilePhoto() async {
  final picker = ImagePicker();
  final image = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1920,
    imageQuality: 85,
  );

  if (image == null) return;

  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/profile/photo'),
    );
    
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('photo', image.path),
    );

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final jsonData = json.decode(responseData);

    if (response.statusCode == 200) {
      // Success - update user object
      final photoUrl = jsonData['data']['profile_photo_url'];
      // Update your user state with new photoUrl
      print('Photo uploaded: $photoUrl');
    } else {
      // Handle error
      print('Upload failed: ${jsonData['message']}');
    }
  } catch (e) {
    print('Error uploading photo: $e');
  }
}
```

### 4. Delete Profile Photo

```dart
Future<void> deleteProfilePhoto() async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/profile/photo'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final jsonData = json.decode(response.body);

    if (response.statusCode == 200) {
      // Success - update user object
      // Set profilePhotoUrl to null in your user state
      print('Photo deleted successfully');
    } else {
      print('Delete failed: ${jsonData['message']}');
    }
  } catch (e) {
    print('Error deleting photo: $e');
  }
}
```

### 5. Profile Page Example

```dart
class ProfilePage extends StatelessWidget {
  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Column(
        children: [
          SizedBox(height: 20),
          
          // Profile Photo with Edit Button
          Stack(
            children: [
              buildProfileAvatar(user),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    onPressed: () => _showPhotoOptions(context),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          Text(user.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(user.email, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                uploadProfilePhoto();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                // Implement camera capture
              },
            ),
            if (user.profilePhotoUrl != null)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Remove photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  deleteProfilePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }
}
```

---

## Testing Checklist

### Backend Testing (Already Done ✅)
- [x] Expense list shows all expenses
- [x] Profile photo upload works
- [x] Profile photo delete works
- [x] `/auth/me` includes photo URL
- [x] Group members include photo URLs

### Frontend Testing (Your Tasks)
- [ ] Update User model with `profilePhotoUrl` field
- [ ] Test `/auth/me` response parsing
- [ ] Implement photo upload UI
- [ ] Implement photo delete functionality
- [ ] Display photos in profile page
- [ ] Display photos in group member lists
- [ ] Test with different image formats (JPEG, PNG)
- [ ] Test with large images (compression)
- [ ] Test error handling (network errors, invalid files)
- [ ] Test on both iOS and Android

---

## Dependencies Required

Add to `pubspec.yaml`:

```yaml
dependencies:
  image_picker: ^1.0.4  # For selecting images
  http: ^1.1.0          # For API calls
  cached_network_image: ^3.3.0  # Optional: For better image caching
```

---

## Common Issues & Solutions

### Issue: Photo not displaying
**Solution**: Check if `profilePhotoUrl` is not null and is a valid URL

### Issue: Upload fails with 422 error
**Solution**: Check file size (max 10MB) and format (JPEG, PNG, GIF, WEBP only)

### Issue: Photo URL returns 404
**Solution**: Ensure Laravel storage is linked: `php artisan storage:link`

### Issue: Old photo still showing after upload
**Solution**: Clear image cache or use `UniqueKey()` on Image widget

---

## Support

If you encounter any issues:
1. Check backend logs: `storage/logs/laravel.log`
2. Verify API response in network inspector
3. Test endpoints in Postman first
4. Check this documentation for examples

---

**Last Updated**: November 16, 2025  
**Backend Version**: v1.0 with Profile Photos  
**Status**: ✅ Ready for Frontend Integration

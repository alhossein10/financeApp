# Profile Photo Not Showing - Troubleshooting Guide

## Problem
Profile photos show in the profile page but NOT in group management cards (admin/superadmin).

## Root Causes (Check in Order)

### 1. Backend Not Sending Profile Photo Field ⚠️ MOST LIKELY

The backend API endpoints for group members might not be including the `profile_photo_url` field.

**How to Check:**
1. Open browser DevTools (F12)
2. Go to Network tab
3. Navigate to group management page
4. Find the API call to `/api/admin/group/members` or `/api/superadmin/group/members`
5. Check the response JSON

**What to Look For:**
```json
{
  "data": {
    "members": {
      "data": [
        {
          "id": 1,
          "name": "John Doe",
          "email": "john@example.com",
          "profile_photo_url": "https://...",  // ← THIS FIELD
          ...
        }
      ]
    }
  }
}
```

**If Missing:** The backend needs to be updated. See `BACKEND_GROUP_MEMBERS_PROFILE_PHOTO_GUIDE.md`

---

### 2. Backend Sending Wrong Field Name

The backend might be sending `profile_image_url` or `avatar` instead of `profile_photo_url`.

**Solution:** The frontend already checks both field names:
- `profile_photo_url` (preferred)
- `profile_image_url` (fallback)

If the backend uses a different field name, update the DTOs:
- `lib/features/admin_group/data/models/group_member_dto.dart`
- `lib/features/superadmin/data/models/admin_member_dto.dart`

---

### 3. Profile Photo Path is Null/Empty

The user might not have uploaded a profile photo yet.

**How to Check:**
1. Go to Profile page
2. Check if photo shows there
3. If yes, but not in group cards → backend issue
4. If no → user needs to upload photo

---

### 4. Image URL is Invalid

The URL might be malformed or inaccessible.

**How to Check:**
1. In DevTools Network tab, find the image request
2. Check if it returns 404 or other error
3. Copy the URL and try opening it in a new tab

**Common Issues:**
- Missing `http://` or `https://`
- Wrong domain
- File doesn't exist on server
- CORS issues

---

### 5. Flutter Image Cache Issue

Sometimes Flutter caches the old state.

**Solution:**
```bash
# Stop the app
# Clear cache
flutter clean

# Rebuild
flutter pub get
flutter run
```

---

## Quick Diagnostic Steps

### Step 1: Check API Response
```bash
# Replace with your actual API URL and token
curl -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Accept: application/json" \
     https://your-api.com/api/admin/group/members
```

Look for `profile_photo_url` in the response.

### Step 2: Check Frontend Parsing
Add debug prints to the DTO:

**File:** `lib/features/superadmin/data/models/admin_member_dto.dart`

```dart
factory AdminMemberDto.fromJson(Map<String, dynamic> json) {
  print('🔍 Parsing AdminMemberDto:');
  print('  - profile_photo_url: ${json['profile_photo_url']}');
  print('  - profile_image_url: ${json['profile_image_url']}');
  
  return AdminMemberDto(
    // ... rest of code
  );
}
```

### Step 3: Check Widget Rendering
Add debug print to the widget:

**File:** `lib/features/superadmin/presentation/widgets/admin_list_card.dart`

```dart
@override
Widget build(BuildContext context) {
  print('🖼️ AdminListCard rendering:');
  print('  - Name: ${admin.name}');
  print('  - Profile URL: ${admin.profileImageUrl}');
  
  // ... rest of code
}
```

---

## Backend Fix Required

If the backend is NOT sending `profile_photo_url`, you need to update it:

### Laravel Backend Fix

**File:** `app/Models/User.php`

```php
class User extends Authenticatable
{
    // Add accessor
    public function getProfilePhotoUrlAttribute()
    {
        if (!$this->profile_photo_path) {
            return null;
        }
        
        if (filter_var($this->profile_photo_path, FILTER_VALIDATE_URL)) {
            return $this->profile_photo_path;
        }
        
        return Storage::url($this->profile_photo_path);
    }
    
    // Add to appends array
    protected $appends = ['profile_photo_url'];
}
```

**File:** `app/Http/Controllers/Api/V1/Admin/GroupController.php`

```php
public function getMembers(Request $request)
{
    $admin = Auth::user();
    
    // Make sure to select profile_photo_path
    $members = User::where('admin_group_id', $admin->admin_group_id)
        ->select(['id', 'name', 'email', 'role', 'profile_photo_path', 'created_at'])
        ->paginate(15);
    
    // profile_photo_url will be automatically appended
    return response()->json([
        'success' => true,
        'data' => [
            'members' => $members
        ]
    ]);
}
```

**File:** `app/Http/Controllers/Api/V1/SuperAdmin/GroupController.php`

```php
public function getMembers(Request $request)
{
    // Make sure to select profile_photo_path
    $members = User::where('role', 'admin')
        ->select(['id', 'name', 'email', 'role', 'profile_photo_path', 'admin_group_id', 'created_at'])
        ->with(['adminGroup:id,name'])
        ->paginate(15);
    
    // profile_photo_url will be automatically appended
    return response()->json([
        'success' => true,
        'data' => $members
    ]);
}
```

---

## Testing Checklist

After making changes:

- [ ] Backend returns `profile_photo_url` in API response
- [ ] Profile photo shows in profile page
- [ ] Profile photo shows in admin group management cards
- [ ] Profile photo shows in superadmin group management cards
- [ ] Fallback initials show when no photo exists
- [ ] Image loads correctly (no 404 errors)
- [ ] Works for both new and existing users

---

## Still Not Working?

1. **Check console logs** - Look for error messages
2. **Check network tab** - Verify API responses
3. **Try hot restart** - Sometimes hot reload isn't enough
4. **Clear app data** - Uninstall and reinstall the app
5. **Check backend logs** - Look for errors on the server

---

## Contact Points

- Frontend DTOs: `lib/features/*/data/models/*_dto.dart`
- Frontend Widgets: `lib/features/*/presentation/widgets/*_card.dart`
- Backend Model: `app/Models/User.php`
- Backend Controllers: `app/Http/Controllers/Api/V1/*/GroupController.php`

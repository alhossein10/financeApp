# Profile Photo Debug Instructions

## Issue
Profile photos show in profile page but NOT in group management cards.

## Changes Made

### 1. Frontend DTOs Updated ✅
Both DTOs now support `profile_photo_url` and `profile_image_url`:
- `lib/features/superadmin/data/models/admin_member_dto.dart`
- `lib/features/admin_group/data/models/group_member_dto.dart`

### 2. Debug Logging Added ✅
Added console logging to see what the API is actually returning.

### 3. Widgets Already Correct ✅
All widgets properly display profile photos:
- `lib/features/superadmin/presentation/widgets/admin_list_card.dart`
- `lib/features/superadmin/presentation/widgets/admin_detail_sheet.dart`
- `lib/features/admin/presentation/widgets/user_list_card.dart`
- `lib/features/admin_group/presentation/widgets/group_member_card.dart`

## Next Steps: Debug the Issue

### Step 1: Run the App and Check Console

1. **Hot restart the app** (not just hot reload):
   ```bash
   # In terminal
   r  # for hot restart
   ```

2. **Navigate to group management page**
   - For SuperAdmin: Go to Group Management
   - For Admin: Go to Group Management

3. **Check the console output** - Look for these debug messages:
   ```
   [AdminMemberDto] Parsing member: John Doe
   [AdminMemberDto]   - profile_photo_url: null
   [AdminMemberDto]   - profile_image_url: null
   [AdminMemberDto]   - All keys: [id, name, email, role, ...]
   [AdminMemberDto]   - Final profileImageUrl: null
   ```

### Step 2: Analyze the Output

#### Scenario A: profile_photo_url is null
```
[AdminMemberDto]   - profile_photo_url: null
[AdminMemberDto]   - profile_image_url: null
```

**Problem:** Backend is NOT sending the profile photo field.

**Solution:** Update the backend to include `profile_photo_url`. See `BACKEND_GROUP_MEMBERS_PROFILE_PHOTO_GUIDE.md`

#### Scenario B: profile_photo_url has a value
```
[AdminMemberDto]   - profile_photo_url: https://api.example.com/storage/profile-photos/abc123.jpg
[AdminMemberDto]   - Final profileImageUrl: https://api.example.com/storage/profile-photos/abc123.jpg
```

**Problem:** Frontend is receiving the URL but image isn't displaying.

**Possible causes:**
1. Image URL is invalid (404)
2. CORS issue
3. Network error
4. Widget rendering issue

**Solution:** Check browser DevTools Network tab for image loading errors.

#### Scenario C: Different field name
```
[AdminMemberDto]   - All keys: [id, name, email, avatar, ...]
```

**Problem:** Backend is using a different field name (e.g., `avatar`).

**Solution:** Update the DTO to check that field name:
```dart
profileImageUrl: json['profile_photo_url'] as String? ?? 
                 json['profile_image_url'] as String? ?? 
                 json['avatar'] as String?,
```

### Step 3: Check Backend Response

Open browser DevTools (F12) → Network tab:

1. Find the API call to `/api/admin/group/members` or `/api/superadmin/group/members`
2. Click on it
3. Go to "Response" tab
4. Look for the profile photo field

**Example of CORRECT response:**
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": 1,
        "name": "John Doe",
        "email": "john@example.com",
        "profile_photo_url": "https://api.example.com/storage/profile-photos/abc123.jpg",
        "role": "admin",
        "created_at": "2024-01-01T00:00:00.000000Z"
      }
    ]
  }
}
```

**Example of INCORRECT response (missing field):**
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": 1,
        "name": "John Doe",
        "email": "john@example.com",
        "role": "admin",
        "created_at": "2024-01-01T00:00:00.000000Z"
        // ❌ NO profile_photo_url field!
      }
    ]
  }
}
```

## Backend Fix (If Needed)

If the backend is NOT sending `profile_photo_url`, you need to update it:

### Quick Backend Fix

**File:** `app/Models/User.php`

```php
class User extends Authenticatable
{
    // Add this accessor
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

**File:** Controller (Admin or SuperAdmin)

```php
// Make sure to select profile_photo_path in the query
$members = User::select([
    'id', 
    'name', 
    'email', 
    'role', 
    'profile_photo_path',  // ← IMPORTANT!
    'created_at'
])->get();

// profile_photo_url will be automatically appended
```

## Remove Debug Logging (After Fix)

Once the issue is resolved, remove the debug print statements from:
- `lib/features/superadmin/data/models/admin_member_dto.dart`
- `lib/features/admin_group/data/models/group_member_dto.dart`

## Summary

1. ✅ Frontend code is correct
2. ✅ Debug logging added
3. ⏳ Run app and check console output
4. ⏳ Identify if backend is sending profile_photo_url
5. ⏳ Fix backend if needed
6. ⏳ Remove debug logging after fix

The most likely issue is that the backend is NOT including the `profile_photo_url` field in the group members API response.

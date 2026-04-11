# Backend Fix Required: Add profile_photo_url to /auth/me Endpoint

## Issue
The `/auth/me` endpoint currently returns `profile_photo_path` but NOT `profile_photo_url`. The app needs the full URL to display the photo.

## Current Response (Missing photo URL)
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 2,
      "name": "admin",
      "email": "admin@gmail.com",
      "role": "admin",
      "profile_photo_path": "public/profile-photos/xxx.jpg",
      // ❌ Missing: "profile_photo_url"
      "created_at": "2025-11-08T12:25:35.000000Z",
      "updated_at": "2025-11-16T16:30:08.000000Z"
    }
  }
}
```

## Required Response (With photo URL)
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 2,
      "name": "admin",
      "email": "admin@gmail.com",
      "role": "admin",
      "profile_photo_path": "public/profile-photos/xxx.jpg",
      "profile_photo_url": "http://127.0.0.1:8000/api/v1/files/download?path=encrypted_path",
      // ✅ Added: Full URL for downloading the photo
      "created_at": "2025-11-08T12:25:35.000000Z",
      "updated_at": "2025-11-16T16:30:08.000000Z"
    }
  }
}
```

## Backend Implementation

### Option 1: Add Accessor to User Model (Recommended)

In your `app/Models/User.php`:

```php
<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens;

    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'profile_photo_path',
        // ... other fields
    ];

    protected $appends = [
        'profile_photo_url', // Add this to automatically include in JSON
    ];

    /**
     * Get the profile photo URL attribute
     */
    public function getProfilePhotoUrlAttribute(): ?string
    {
        if (!$this->profile_photo_path) {
            return null;
        }

        // Generate encrypted download URL
        $encryptedPath = encrypt($this->profile_photo_path);
        return url("/api/v1/files/download?path={$encryptedPath}");
    }
}
```

### Option 2: Modify AuthController Response

If you can't modify the User model, update your `AuthController`:

```php
<?php

namespace App\Http\Controllers\Api\V1;

use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function me(Request $request)
    {
        $user = $request->user();
        
        // Generate profile photo URL if path exists
        $profilePhotoUrl = null;
        if ($user->profile_photo_path) {
            $encryptedPath = encrypt($user->profile_photo_path);
            $profilePhotoUrl = url("/api/v1/files/download?path={$encryptedPath}");
        }
        
        return response()->json([
            'success' => true,
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                    'profile_photo_path' => $user->profile_photo_path,
                    'profile_photo_url' => $profilePhotoUrl, // Add this
                    'organization_id' => $user->organization_id,
                    'department_id' => $user->department_id,
                    'organization_name' => $user->organization_name,
                    'department_name' => $user->department_name,
                    'admin_group_id' => $user->admin_group_id,
                    'super_admin_group_id' => $user->super_admin_group_id,
                    'email_verified_at' => $user->email_verified_at,
                    'created_at' => $user->created_at,
                    'updated_at' => $user->updated_at,
                ]
            ]
        ]);
    }
}
```

## Also Update Group Member Endpoints

For photos to show in group management pages, also update these endpoints:

### 1. Get Group Members (`/api/v1/admin-groups/members`)

```php
public function getMembers(Request $request)
{
    $members = $adminGroup->users()->get();
    
    return response()->json([
        'success' => true,
        'data' => $members->map(function ($user) {
            return [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'profile_photo_path' => $user->profile_photo_path,
                'profile_photo_url' => $user->profile_photo_url, // Add this
                // ... other fields
            ];
        })
    ]);
}
```

### 2. SuperAdmin Get Admins (`/api/v1/superadmin/groups/{id}/admins`)

```php
public function getAdmins($groupId)
{
    $admins = SuperAdminGroup::findOrFail($groupId)->admins;
    
    return response()->json([
        'success' => true,
        'data' => $admins->map(function ($admin) {
            return [
                'id' => $admin->id,
                'name' => $admin->name,
                'email' => $admin->email,
                'profile_photo_path' => $admin->profile_photo_path,
                'profile_photo_url' => $admin->profile_photo_url, // Add this
                // ... other fields
            ];
        })
    ]);
}
```

## Testing

After making these changes, test with:

```bash
# Test /auth/me endpoint
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:8000/api/v1/auth/me

# Should return profile_photo_url in response
```

## Why This Fix is Needed

1. **Profile Page**: Uses `/auth/me` to get current user data
2. **Group Management**: Uses group member endpoints to list users
3. **SuperAdmin**: Uses admin list endpoints to show admins

All these endpoints need to return `profile_photo_url` for photos to display correctly in the app.

## After Backend Fix

Once you've updated the backend:
1. **Hot restart** the Flutter app
2. Navigate to Profile page
3. Photo should now appear
4. Check Group Management pages - member photos should also appear

## Alternative: Use Resource Classes (Laravel Best Practice)

For a cleaner approach, create a UserResource:

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray($request)
    {
        $profilePhotoUrl = null;
        if ($this->profile_photo_path) {
            $encryptedPath = encrypt($this->profile_photo_path);
            $profilePhotoUrl = url("/api/v1/files/download?path={$encryptedPath}");
        }

        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'role' => $this->role,
            'profile_photo_path' => $this->profile_photo_path,
            'profile_photo_url' => $profilePhotoUrl,
            'organization_name' => $this->organization_name,
            'department_name' => $this->department_name,
            'admin_group_id' => $this->admin_group_id,
            'super_admin_group_id' => $this->super_admin_group_id,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
```

Then use it in your controllers:

```php
use App\Http\Resources\UserResource;

public function me(Request $request)
{
    return response()->json([
        'success' => true,
        'data' => [
            'user' => new UserResource($request->user())
        ]
    ]);
}
```

This approach is cleaner and more maintainable!

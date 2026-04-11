# Backend Guide: Profile Photos in Group Members API

## Overview

This guide shows how to add `profile_photo_url` to group members API responses in your Laravel backend.

---

## Quick Summary

**What to Add**: Include `profile_photo_url` field in all group members API responses

**Affected Endpoints**:
- Admin: `GET /api/v1/admin/group/members`
- SuperAdmin: `GET /api/v1/superadmin/group/members`

---

## Step 1: Update User Model

Ensure your User model has the profile photo accessor.

**File**: `app/Models/User.php`

```php
<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Support\Facades\Storage;

class User extends Authenticatable
{
    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'profile_photo_path',
        // ... other fields
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the profile photo URL attribute
     * This automatically generates the full URL for the profile photo
     */
    public function getProfilePhotoUrlAttribute()
    {
        if (!$this->profile_photo_path) {
            return null;
        }

        // If it's already a full URL, return as is
        if (filter_var($this->profile_photo_path, FILTER_VALIDATE_URL)) {
            return $this->profile_photo_path;
        }

        // Generate full URL from storage path
        // Assumes photos are stored in storage/app/public/profile-photos/
        return Storage::url($this->profile_photo_path);
    }

    /**
     * Append profile_photo_url to JSON responses
     */
    protected $appends = ['profile_photo_url'];
}
```

---

## Step 2: Update Admin Group Members Controller

**File**: `app/Http/Controllers/Api/V1/Admin/GroupController.php`

### Option A: Using Eloquent Relationships (Recommended)

```php
<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class GroupController extends Controller
{
    /**
     * Get group members with profile photos
     * 
     * @return \Illuminate\Http\JsonResponse
     */
    public function getMembers(Request $request)
    {
        $admin = Auth::user();
        
        // Get admin's group
        $adminGroup = $admin->managedGroup;
        
        if (!$adminGroup) {
            return response()->json([
                'success' => false,
                'message' => 'No group found for this admin',
            ], 404);
        }

        // Get members with pagination
        $members = $adminGroup->users()
            ->select([
                'id',
                'name',
                'email',
                'role',
                'profile_photo_path',  // Include this for the accessor
                'organization_name',
                'department_name',
                'created_at',
            ])
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => [
                'members' => $members,
            ],
        ]);
    }
}
```

### Option B: Manual Field Selection

```php
public function getMembers(Request $request)
{
    $admin = Auth::user();
    $adminGroup = $admin->managedGroup;
    
    if (!$adminGroup) {
        return response()->json([
            'success' => false,
            'message' => 'No group found for this admin',
        ], 404);
    }

    // Get members with manual profile_photo_url generation
    $members = $adminGroup->users()
        ->select([
            'id',
            'name',
            'email',
            'role',
            'profile_photo_path',
            'organization_name',
            'department_name',
            'created_at',
        ])
        ->get()
        ->map(function ($user) {
            return [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'profile_photo_url' => $user->profile_photo_url,  // Uses accessor
                'organization_name' => $user->organization_name,
                'department_name' => $user->department_name,
                'created_at' => $user->created_at->toIso8601String(),
            ];
        });

    return response()->json([
        'success' => true,
        'data' => [
            'members' => [
                'data' => $members,
                'current_page' => 1,
                'last_page' => 1,
                'per_page' => $members->count(),
                'total' => $members->count(),
            ],
        ],
    ]);
}
```

---

## Step 3: Update SuperAdmin Group Members Controller

**File**: `app/Http/Controllers/Api/V1/SuperAdmin/GroupController.php`

```php
<?php

namespace App\Http\Controllers\Api\V1\SuperAdmin;

use App\Http\Controllers\Controller;
use App\Models\AdminGroup;
use Illuminate\Http\Request;

class GroupController extends Controller
{
    /**
     * Get members of a specific admin group
     * 
     * @param int $groupId
     * @return \Illuminate\Http\JsonResponse
     */
    public function getGroupMembers($groupId)
    {
        $adminGroup = AdminGroup::find($groupId);
        
        if (!$adminGroup) {
            return response()->json([
                'success' => false,
                'message' => 'Admin group not found',
            ], 404);
        }

        // Get admin and user members
        $admin = $adminGroup->admin()
            ->select([
                'id',
                'name',
                'email',
                'role',
                'profile_photo_path',
                'created_at',
            ])
            ->first();

        $users = $adminGroup->users()
            ->select([
                'id',
                'name',
                'email',
                'role',
                'profile_photo_path',
                'organization_name',
                'department_name',
                'created_at',
            ])
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => [
                'admin' => $admin,  // Includes profile_photo_url via accessor
                'members' => $users,  // Includes profile_photo_url via accessor
            ],
        ]);
    }

    /**
     * Get all admin groups with their admins
     * 
     * @return \Illuminate\Http\JsonResponse
     */
    public function getAllGroups()
    {
        $groups = AdminGroup::with(['admin' => function ($query) {
            $query->select([
                'id',
                'name',
                'email',
                'role',
                'profile_photo_path',
                'created_at',
            ]);
        }])
        ->withCount('users')
        ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => [
                'groups' => $groups,
            ],
        ]);
    }
}
```

---

## Step 4: Create API Resource (Optional but Recommended)

For cleaner code, create a User Resource.

**File**: `app/Http/Resources/UserResource.php`

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array
     */
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'role' => $this->role,
            'profile_photo_url' => $this->profile_photo_url,  // Automatically included
            'profile_photo_path' => $this->when($request->user()->isAdmin(), $this->profile_photo_path),
            'organization_name' => $this->organization_name,
            'department_name' => $this->department_name,
            'created_at' => $this->created_at->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
```

**Usage in Controller**:

```php
use App\Http\Resources\UserResource;

public function getMembers(Request $request)
{
    $admin = Auth::user();
    $adminGroup = $admin->managedGroup;
    
    if (!$adminGroup) {
        return response()->json([
            'success' => false,
            'message' => 'No group found for this admin',
        ], 404);
    }

    $members = $adminGroup->users()->paginate(15);

    return response()->json([
        'success' => true,
        'data' => [
            'members' => UserResource::collection($members),
        ],
    ]);
}
```

---

## Step 5: Verify Storage is Linked

Ensure Laravel storage is linked so photos are accessible via URL.

```bash
php artisan storage:link
```

This creates a symbolic link from `public/storage` to `storage/app/public`.

---

## Expected API Response

### Admin Group Members Endpoint

**Request**: `GET /api/v1/admin/group/members`

**Response**:
```json
{
  "success": true,
  "data": {
    "members": {
      "data": [
        {
          "id": 1,
          "name": "John Doe",
          "email": "john@example.com",
          "role": "user",
          "profile_photo_url": "http://localhost:8000/storage/profile-photos/abc123.jpg",
          "organization_name": "Tech Corp",
          "department_name": "Engineering",
          "created_at": "2025-11-16T10:00:00Z"
        },
        {
          "id": 2,
          "name": "Jane Smith",
          "email": "jane@example.com",
          "role": "user",
          "profile_photo_url": null,
          "organization_name": "Tech Corp",
          "department_name": "Marketing",
          "created_at": "2025-11-15T09:00:00Z"
        }
      ],
      "current_page": 1,
      "last_page": 1,
      "per_page": 15,
      "total": 2
    }
  }
}
```

### SuperAdmin Group Members Endpoint

**Request**: `GET /api/v1/superadmin/group/{groupId}/members`

**Response**:
```json
{
  "success": true,
  "data": {
    "admin": {
      "id": 10,
      "name": "Admin User",
      "email": "admin@example.com",
      "role": "admin",
      "profile_photo_url": "http://localhost:8000/storage/profile-photos/xyz789.jpg",
      "created_at": "2025-11-10T08:00:00Z"
    },
    "members": {
      "data": [
        {
          "id": 1,
          "name": "John Doe",
          "email": "john@example.com",
          "role": "user",
          "profile_photo_url": "http://localhost:8000/storage/profile-photos/abc123.jpg",
          "organization_name": "Tech Corp",
          "department_name": "Engineering",
          "created_at": "2025-11-16T10:00:00Z"
        }
      ],
      "current_page": 1,
      "last_page": 1,
      "per_page": 15,
      "total": 1
    }
  }
}
```

---

## Testing

### Test with Postman

1. **Get Admin Group Members**:
   ```
   GET http://localhost:8000/api/v1/admin/group/members
   Headers:
     Authorization: Bearer {admin_token}
     Accept: application/json
   ```

2. **Get SuperAdmin Group Members**:
   ```
   GET http://localhost:8000/api/v1/superadmin/group/1/members
   Headers:
     Authorization: Bearer {superadmin_token}
     Accept: application/json
   ```

3. **Verify Response**:
   - Check that `profile_photo_url` field exists
   - For users with photos: URL should be valid
   - For users without photos: Should be `null`

### Test with cURL

```bash
# Admin endpoint
curl -X GET "http://localhost:8000/api/v1/admin/group/members" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Accept: application/json"

# SuperAdmin endpoint
curl -X GET "http://localhost:8000/api/v1/superadmin/group/1/members" \
  -H "Authorization: Bearer YOUR_SUPERADMIN_TOKEN" \
  -H "Accept: application/json"
```

---

## Troubleshooting

### Issue: `profile_photo_url` is null for all users

**Solution**: Check if `$appends` is set in User model:
```php
protected $appends = ['profile_photo_url'];
```

### Issue: URL returns 404

**Solution**: Ensure storage is linked:
```bash
php artisan storage:link
```

### Issue: URL is relative instead of absolute

**Solution**: Update the accessor in User model:
```php
public function getProfilePhotoUrlAttribute()
{
    if (!$this->profile_photo_path) {
        return null;
    }
    
    // Use Storage::url() for absolute URL
    return Storage::url($this->profile_photo_path);
}
```

### Issue: Field not appearing in response

**Solution**: Ensure field is selected in query:
```php
->select([
    'id',
    'name',
    'email',
    'profile_photo_path',  // Required for accessor
    // ... other fields
])
```

---

## Alternative: Using API Resources (Best Practice)

If you want cleaner, more maintainable code:

### 1. Create Resource

```bash
php artisan make:resource GroupMemberResource
```

### 2. Define Resource

**File**: `app/Http/Resources/GroupMemberResource.php`

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class GroupMemberResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'role' => $this->role,
            'profile_photo_url' => $this->profile_photo_url,
            'organization_name' => $this->organization_name,
            'department_name' => $this->department_name,
            'created_at' => $this->created_at->toIso8601String(),
        ];
    }
}
```

### 3. Use in Controller

```php
use App\Http\Resources\GroupMemberResource;

public function getMembers()
{
    $members = $adminGroup->users()->paginate(15);
    
    return response()->json([
        'success' => true,
        'data' => [
            'members' => GroupMemberResource::collection($members),
        ],
    ]);
}
```

---

## Summary Checklist

- [ ] Add `profile_photo_url` accessor to User model
- [ ] Add `profile_photo_url` to `$appends` array
- [ ] Include `profile_photo_path` in select queries
- [ ] Run `php artisan storage:link`
- [ ] Test admin group members endpoint
- [ ] Test superadmin group members endpoint
- [ ] Verify URLs are accessible
- [ ] Update frontend to display photos

---

## Quick Copy-Paste Solution

If you just want it to work quickly, add this to your User model:

```php
// In app/Models/User.php

protected $appends = ['profile_photo_url'];

public function getProfilePhotoUrlAttribute()
{
    return $this->profile_photo_path 
        ? Storage::url($this->profile_photo_path) 
        : null;
}
```

Then ensure your controllers select `profile_photo_path` field, and it will automatically include `profile_photo_url` in responses!

---

**Last Updated**: November 16, 2025  
**Laravel Version**: 10.x / 11.x  
**Status**: Production Ready

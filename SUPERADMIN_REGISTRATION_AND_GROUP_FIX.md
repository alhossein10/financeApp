# SuperAdmin Registration and Group Management Fix

## Issues Identified

### 1. ❌ SuperAdmin Registration Doesn't Return Group Code

**Problem:** When a SuperAdmin registers, the backend doesn't return the `super_admin_group_code` in the response, so the success dialog can't display it.

**Expected Backend Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 8,
      "name": "superadmin",
      "email": "superadmin@gmail.com",
      "role": "superAdmin",
      "admin_group_id": 123
    },
    "token": "89|qPno05E2diyKmzZGc...",
    "super_admin_group_code": "SA-ABC123",
    "admin_group_name": "هيئة الاتصالات"
  }
}
```

**Current Backend Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 8,
      "name": "superadmin",
      "email": "superadmin@gmail.com",
      "role": "superAdmin",
      "admin_group_id": null  // ❌ NULL
    },
    "token": "89|qPno05E2diyKmzZGc..."
    // ❌ Missing super_admin_group_code
    // ❌ Missing admin_group_name
  }
}
```

### 2. ❌ Admin Group Endpoints Failing for SuperAdmin

**Problem:** SuperAdmin is trying to access `/api/v1/admin/group/*` endpoints which are for regular admins only.

**Error Logs:**
```
[ApiClient] Request: GET http://192.168.137.1:8000/api/v1/admin/group/members?page=1&per_page=15
[AdminGroupBloc] ❌ Failed to load admin group: Failed to fetch admin group
[AdminGroupBloc] ❌ Failed to load group members: Failed to fetch group members
```

**Root Cause:** SuperAdmin should use `/api/v1/superadmin/group/*` endpoints, not `/api/v1/admin/group/*`.

---

## Backend Fixes Required

### Fix 1: SuperAdmin Registration Response

**File:** `app/Http/Controllers/Api/AuthController.php` (or similar)

**Current Code:**
```php
public function register(Request $request) {
    // ... validation ...
    
    $user = User::create([
        'name' => $request->name,
        'email' => $request->email,
        'password' => Hash::make($request->password),
        'role' => $request->role,
    ]);
    
    $token = $user->createToken('auth_token')->plainTextToken;
    
    return response()->json([
        'success' => true,
        'data' => [
            'user' => $user,
            'token' => $token,
        ]
    ]);
}
```

**Fixed Code:**
```php
public function register(Request $request) {
    // ... validation ...
    
    $user = User::create([
        'name' => $request->name,
        'email' => $request->email,
        'password' => Hash::make($request->password),
        'role' => $request->role,
    ]);
    
    $token = $user->createToken('auth_token')->plainTextToken;
    
    $responseData = [
        'user' => $user,
        'token' => $token,
    ];
    
    // If SuperAdmin, create admin_group and return group code
    if ($request->role === 'superAdmin') {
        // Create admin group
        $adminGroup = AdminGroup::create([
            'name' => $request->admin_group_name ?? 'Default Group',
            'group_code' => $this->generateGroupCode('SA-'), // SA-ABC123
            'created_by' => $user->id,
        ]);
        
        // Associate user with admin group
        $user->admin_group_id = $adminGroup->id;
        $user->save();
        
        // Add group code to response
        $responseData['super_admin_group_code'] = $adminGroup->group_code;
        $responseData['admin_group_name'] = $adminGroup->name;
        
        // Reload user to include admin_group_id
        $responseData['user'] = $user->fresh();
    }
    
    return response()->json([
        'success' => true,
        'data' => $responseData
    ]);
}

private function generateGroupCode($prefix = '') {
    do {
        $code = $prefix . strtoupper(Str::random(6));
    } while (AdminGroup::where('group_code', $code)->exists());
    
    return $code;
}
```

### Fix 2: SuperAdmin Group Endpoints

**Create:** `app/Http/Controllers/Api/SuperAdminGroupController.php`

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\AdminGroup;
use App\Models\User;

class SuperAdminGroupController extends Controller
{
    /**
     * Get SuperAdmin's group information
     * GET /api/v1/superadmin/group
     */
    public function getGroup(Request $request)
    {
        $user = $request->user();
        
        // Verify user is SuperAdmin
        if ($user->role !== 'superAdmin') {
            return response()->json([
                'success' => false,
                'message' => 'Access denied. SuperAdmin privileges required.'
            ], 403);
        }
        
        // Get admin group
        $adminGroup = AdminGroup::where('id', $user->admin_group_id)->first();
        
        if (!$adminGroup) {
            return response()->json([
                'success' => false,
                'message' => 'Admin group not found'
            ], 404);
        }
        
        // Count members
        $memberCount = User::where('admin_group_id', $adminGroup->id)
            ->where('role', 'admin')
            ->count();
        
        return response()->json([
            'success' => true,
            'data' => [
                'id' => $adminGroup->id,
                'name' => $adminGroup->name,
                'group_code' => $adminGroup->group_code,
                'created_at' => $adminGroup->created_at,
                'member_count' => $memberCount,
            ]
        ]);
    }
    
    /**
     * Get list of admin members in SuperAdmin's group
     * GET /api/v1/superadmin/group/members
     */
    public function getMembers(Request $request)
    {
        $user = $request->user();
        
        // Verify user is SuperAdmin
        if ($user->role !== 'superAdmin') {
            return response()->json([
                'success' => false,
                'message' => 'Access denied. SuperAdmin privileges required.'
            ], 403);
        }
        
        $page = $request->input('page', 1);
        $perPage = $request->input('per_page', 15);
        
        // Get admin members in the same group
        $members = User::where('admin_group_id', $user->admin_group_id)
            ->where('role', 'admin')
            ->paginate($perPage, ['*'], 'page', $page);
        
        return response()->json([
            'success' => true,
            'data' => [
                'members' => $members->items(),
                'pagination' => [
                    'current_page' => $members->currentPage(),
                    'per_page' => $members->perPage(),
                    'total' => $members->total(),
                    'last_page' => $members->lastPage(),
                ]
            ]
        ]);
    }
    
    /**
     * Regenerate group code
     * POST /api/v1/superadmin/group/regenerate-code
     */
    public function regenerateCode(Request $request)
    {
        $user = $request->user();
        
        // Verify user is SuperAdmin
        if ($user->role !== 'superAdmin') {
            return response()->json([
                'success' => false,
                'message' => 'Access denied. SuperAdmin privileges required.'
            ], 403);
        }
        
        $adminGroup = AdminGroup::find($user->admin_group_id);
        
        if (!$adminGroup) {
            return response()->json([
                'success' => false,
                'message' => 'Admin group not found'
            ], 404);
        }
        
        // Generate new code
        do {
            $newCode = 'SA-' . strtoupper(Str::random(6));
        } while (AdminGroup::where('group_code', $newCode)->exists());
        
        $adminGroup->group_code = $newCode;
        $adminGroup->save();
        
        return response()->json([
            'success' => true,
            'message' => 'Group code regenerated successfully',
            'data' => [
                'group_code' => $newCode
            ]
        ]);
    }
    
    /**
     * Remove admin member from group
     * DELETE /api/v1/superadmin/group/members/{id}
     */
    public function removeMember(Request $request, $memberId)
    {
        $user = $request->user();
        
        // Verify user is SuperAdmin
        if ($user->role !== 'superAdmin') {
            return response()->json([
                'success' => false,
                'message' => 'Access denied. SuperAdmin privileges required.'
            ], 403);
        }
        
        $member = User::find($memberId);
        
        if (!$member) {
            return response()->json([
                'success' => false,
                'message' => 'Member not found'
            ], 404);
        }
        
        // Verify member is in SuperAdmin's group
        if ($member->admin_group_id !== $user->admin_group_id) {
            return response()->json([
                'success' => false,
                'message' => 'Member not in your group'
            ], 403);
        }
        
        // Remove from group
        $member->admin_group_id = null;
        $member->save();
        
        return response()->json([
            'success' => true,
            'message' => 'Member removed successfully'
        ]);
    }
}
```

**Add Routes:** `routes/api.php`

```php
// SuperAdmin Group Management Routes
Route::middleware(['auth:sanctum'])->prefix('v1/superadmin')->group(function () {
    Route::get('/group', [SuperAdminGroupController::class, 'getGroup']);
    Route::get('/group/members', [SuperAdminGroupController::class, 'getMembers']);
    Route::post('/group/regenerate-code', [SuperAdminGroupController::class, 'regenerateCode']);
    Route::delete('/group/members/{id}', [SuperAdminGroupController::class, 'removeMember']);
});
```

---

## Frontend Fixes Required

The frontend is already correctly set up to:
1. ✅ Parse `super_admin_group_code` from registration response
2. ✅ Display the group code in `SuperAdminRegistrationSuccessDialog`
3. ✅ Allow copying the code to clipboard

However, we need to update the admin group datasource to use the correct endpoints for SuperAdmin.

### Option 1: Create Separate SuperAdmin Group Datasource

Create `lib/features/admin_group/data/datasources/superadmin_group_api_datasource.dart` that uses `/superadmin/group/*` endpoints.

### Option 2: Make Admin Group Datasource Role-Aware

Update the existing datasource to detect user role and use appropriate endpoints.

**Recommended:** Option 2 (simpler, less code duplication)

---

## Testing Checklist

### Backend Testing

- [ ] SuperAdmin registration creates admin_group
- [ ] SuperAdmin registration returns `super_admin_group_code`
- [ ] SuperAdmin registration returns `admin_group_name`
- [ ] SuperAdmin registration sets `admin_group_id` on user
- [ ] GET `/api/v1/superadmin/group` returns group info
- [ ] GET `/api/v1/superadmin/group/members` returns admin members
- [ ] POST `/api/v1/superadmin/group/regenerate-code` generates new code
- [ ] DELETE `/api/v1/superadmin/group/members/{id}` removes member

### Frontend Testing

- [ ] SuperAdmin registration shows success dialog
- [ ] Success dialog displays group code
- [ ] Copy button works
- [ ] Group code is in format `SA-XXXXXX`
- [ ] SuperAdmin can view group info
- [ ] SuperAdmin can view admin members
- [ ] SuperAdmin can regenerate code
- [ ] SuperAdmin can remove members

---

## Database Schema

Ensure the `admin_groups` table exists:

```sql
CREATE TABLE IF NOT EXISTS admin_groups (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    group_code VARCHAR(20) UNIQUE NOT NULL,
    created_by BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_group_code (group_code)
);
```

Ensure the `users` table has `admin_group_id`:

```sql
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS admin_group_id BIGINT UNSIGNED NULL,
ADD FOREIGN KEY (admin_group_id) REFERENCES admin_groups(id) ON DELETE SET NULL;
```

---

## Summary

**Backend Issues:**
1. ❌ SuperAdmin registration doesn't create admin_group
2. ❌ SuperAdmin registration doesn't return group code
3. ❌ SuperAdmin group management endpoints don't exist

**Frontend Status:**
- ✅ Already set up to parse and display group code
- ✅ Success dialog ready to show group code
- ⏳ Needs role-aware endpoint selection for group management

**Priority:** 🔴 **CRITICAL** - SuperAdmin cannot share group code with admins

---

## Related Documentation

- `SUPERADMIN_BACKEND_ISSUES_SUMMARY.md` - All backend issues
- `.kiro/specs/superadmin-flavor-customization/API_DOCUMENTATION.md` - Full API spec
- `BACKEND_SUPERADMIN_ENDPOINTS_NEEDED.md` - Endpoint requirements

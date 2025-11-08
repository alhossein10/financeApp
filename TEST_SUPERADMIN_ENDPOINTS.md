# Test SuperAdmin Endpoints - Quick Guide

## Status: Backend Endpoints Added to Postman Collection ✅

The backend team has added the SuperAdmin endpoints to the Postman collection. Now we need to verify they actually work.

## Quick Test Steps

### 1. Test SuperAdmin Registration

**Endpoint:** `POST {{base_url}}/auth/register`

**Request:**
```json
{
  "name": "Test SuperAdmin",
  "email": "testsuperadmin@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "role": "superAdmin",
  "organization_name": "Test Organization",
  "admin_group_name": "Test SuperAdmin Group"
}
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 8,
      "name": "Test SuperAdmin",
      "email": "testsuperadmin@example.com",
      "role": "superAdmin",
      "admin_group_id": 1  // ✅ Should NOT be null
    },
    "token": "89|qPno05E2diyKmzZGc...",
    "super_admin_group_code": "123456",  // ✅ Should be present
    "admin_group_name": "Test SuperAdmin Group"  // ✅ Should be present
  }
}
```

**Check:**
- ✅ Response includes `super_admin_group_code`
- ✅ Response includes `admin_group_name`
- ✅ User's `admin_group_id` is NOT null
- ✅ Status code is 201

---

### 2. Test Get SuperAdmin Group Info

**Endpoint:** `GET {{base_url}}/superadmin/group`

**Headers:**
```
Authorization: Bearer {token_from_step_1}
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Test SuperAdmin Group",
    "group_code": "123456",
    "created_at": "2025-11-08T10:00:00.000000Z",
    "member_count": 0
  }
}
```

**Check:**
- ✅ Status code is 200 (NOT 404)
- ✅ Group code matches registration response
- ✅ Group name matches registration request

---

### 3. Test Get Admin Members

**Endpoint:** `GET {{base_url}}/superadmin/group/members?page=1&per_page=15`

**Headers:**
```
Authorization: Bearer {token_from_step_1}
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "members": [],
    "pagination": {
      "current_page": 1,
      "per_page": 15,
      "total": 0,
      "last_page": 1
    }
  }
}
```

**Check:**
- ✅ Status code is 200 (NOT 404)
- ✅ Returns empty array (no admins yet)
- ✅ Pagination structure is correct

---

### 4. Test Admin Registration with Group Code

**Endpoint:** `POST {{base_url}}/auth/register`

**Request:**
```json
{
  "name": "Test Admin",
  "email": "testadmin@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "role": "admin",
  "organization_name": "Test Organization",
  "super_admin_group_code": "123456"  // Use code from step 1
}
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 9,
      "name": "Test Admin",
      "email": "testadmin@example.com",
      "role": "admin",
      "super_admin_group_id": 1  // ✅ Should match SuperAdmin's group
    },
    "token": "90|abc123...",
    "admin_group": {
      "id": 2,
      "name": "Test Admin - Group",
      "group_code": "789012"
    }
  }
}
```

**Check:**
- ✅ Status code is 201
- ✅ Admin's `super_admin_group_id` matches SuperAdmin's group
- ✅ Admin gets their own `admin_group` for managing users

---

### 5. Test Get Members Again (Should Show Admin)

**Endpoint:** `GET {{base_url}}/superadmin/group/members?page=1&per_page=15`

**Headers:**
```
Authorization: Bearer {superadmin_token_from_step_1}
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "members": [
      {
        "id": 9,
        "name": "Test Admin",
        "email": "testadmin@example.com",
        "role": "admin",
        "organization_name": "Test Organization",
        "created_at": "2025-11-08T10:05:00.000000Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 15,
      "total": 1,
      "last_page": 1
    }
  }
}
```

**Check:**
- ✅ Admin appears in members list
- ✅ Total count is 1

---

### 6. Test Regenerate Group Code

**Endpoint:** `POST {{base_url}}/superadmin/group/regenerate-code`

**Headers:**
```
Authorization: Bearer {superadmin_token_from_step_1}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Group code regenerated successfully",
  "data": {
    "group_code": "789012"  // New code, different from "123456"
  }
}
```

**Check:**
- ✅ Status code is 200
- ✅ New code is different from original
- ✅ New code is 6 digits

---

### 7. Test Remove Admin Member

**Endpoint:** `DELETE {{base_url}}/superadmin/group/members/9`

**Headers:**
```
Authorization: Bearer {superadmin_token_from_step_1}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Member removed successfully"
}
```

**Check:**
- ✅ Status code is 200
- ✅ Admin is removed from group
- ✅ Get members returns empty array again

---

## Using Postman Collection

The backend team has already set up the Postman collection with:

1. **Collection Variables** - Automatically saves tokens and IDs
2. **Test Scripts** - Auto-extracts values from responses
3. **Organized Folders** - Easy to find endpoints

### To Test:

1. **Import the Collection**
   - Open Postman
   - Import `Finance-API-Complete-v3-SuperAdmin-MultiCurrency.postman_collection.json`

2. **Set Base URL**
   - Click on collection
   - Variables tab
   - Set `base_url` to `http://192.168.137.1:8000/api/v1`

3. **Run Tests in Order**
   - Navigate to "2. Authentication" folder
   - Run "Register SuperAdmin"
   - Check if `super_admin_group_code` is saved to variables
   - Navigate to "2.1. SuperAdmin Group Management" folder
   - Run each endpoint in order

---

## Common Issues & Solutions

### Issue 1: 404 Not Found
**Symptom:** `GET /superadmin/group` returns 404

**Solution:** Backend routes not registered. Check:
```php
// routes/api_v1.php
Route::middleware(['auth:sanctum'])->prefix('superadmin')->group(function () {
    Route::get('/group', [SuperAdminGroupController::class, 'getGroup']);
    Route::get('/group/members', [SuperAdminGroupController::class, 'getMembers']);
    Route::post('/group/regenerate-code', [SuperAdminGroupController::class, 'regenerateCode']);
    Route::delete('/group/members/{id}', [SuperAdminGroupController::class, 'removeMember']);
});
```

### Issue 2: No Group Code in Registration Response
**Symptom:** Registration succeeds but no `super_admin_group_code` in response

**Solution:** Backend not creating SuperAdmin group. Check `AuthController::register()` or `AuthService::register()`

### Issue 3: admin_group_id is NULL
**Symptom:** User registered but `admin_group_id` is null

**Solution:** Backend not setting `admin_group_id` after creating group

### Issue 4: 403 Forbidden
**Symptom:** Endpoints return 403 even with valid token

**Solution:** Middleware not checking for 'superAdmin' role. Check middleware:
```php
if ($user->role !== 'superAdmin') {
    return response()->json(['error' => 'Forbidden'], 403);
}
```

---

## Frontend Testing

Once backend endpoints work, test in the Flutter app:

1. **Register SuperAdmin**
   - Use SuperAdmin flavor
   - Register new user
   - Verify success dialog shows group code

2. **View Group Info**
   - Navigate to Profile/Settings
   - Should see group code
   - Should see "0 members"

3. **Register Admin**
   - Use Admin flavor
   - Enter SuperAdmin's group code
   - Verify registration succeeds

4. **View Members**
   - Login as SuperAdmin
   - Navigate to group management
   - Should see the admin in members list

---

## Success Criteria

✅ All 7 test steps pass  
✅ No 404 errors  
✅ No 403 errors  
✅ Group code is returned and saved  
✅ Admin can join using group code  
✅ SuperAdmin can see admin in members list  
✅ SuperAdmin can regenerate code  
✅ SuperAdmin can remove members  

---

## Next Steps

1. **Run Postman Tests** - Verify all endpoints work
2. **Fix Any Issues** - Work with backend team
3. **Test in Flutter App** - Once backend works
4. **Deploy to Production** - After successful testing

---

## Contact

- **Backend Issues:** Check Laravel logs in `storage/logs/laravel.log`
- **Frontend Issues:** Check Flutter logs
- **Documentation:** See `SUPERADMIN_REGISTRATION_AND_GROUP_FIX.md`

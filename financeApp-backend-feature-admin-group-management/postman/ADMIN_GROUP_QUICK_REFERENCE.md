# Admin Group Management - Quick Reference

Quick reference guide for Admin Group Management API endpoints in Postman.

## 📋 Endpoints Overview

| Endpoint | Method | Role | Description |
|----------|--------|------|-------------|
| `/admin/group` | GET | Admin | Get admin's group info and code |
| `/admin/group/regenerate` | POST | Admin | Regenerate group code |
| `/admin/group/members` | GET | Admin | List group members (paginated) |
| `/admin/group/members/{id}` | DELETE | Admin | Remove member from group |
| `/user/join-group` | POST | User | Join group using code |
| `/user/group-info` | GET | User | Get current group info |

## 🔑 Collection Variables

These variables are automatically set by test scripts:

- `{{group_code}}` - Admin's group code (4-6 digits)
- `{{member_id}}` - Group member user ID
- `{{token}}` - Authentication token
- `{{user_id}}` - Current user ID

## 🚀 Quick Start Workflow

### 1. Admin Setup (3 steps)

```
1. Register Admin User
   → POST /auth/register
   → Auto-creates group with unique code

2. Get Group Info
   → GET /admin/group
   → Saves group_code to variable

3. Share Code
   → Give {{group_code}} to team members
```

### 2. User Joins Group (2 options)

**Option A: During Registration**
```
POST /auth/register
Body: {
  "name": "User Name",
  "email": "user@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "organization_name": "Acme Corp",
  "group_code": "123456",
  "role": "user"
}
```

**Option B: After Registration**
```
POST /user/join-group
Body: {
  "group_code": "123456"
}
```

### 3. Admin Manages Members

```
1. View Members
   → GET /admin/group/members

2. Remove Member
   → DELETE /admin/group/members/{id}

3. Regenerate Code (if needed)
   → POST /admin/group/regenerate
```

## 📝 Request Examples

### Get Admin Group Info

```http
GET {{base_url}}/admin/group
Authorization: Bearer {{token}}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "group_code": "123456",
    "is_active": true,
    "admin": {
      "id": 1,
      "name": "Admin User",
      "organization_name": "Acme Corp"
    }
  }
}
```

### Regenerate Group Code

```http
POST {{base_url}}/admin/group/regenerate
Authorization: Bearer {{token}}
```

**Response:**
```json
{
  "success": true,
  "message": "Group code regenerated successfully",
  "data": {
    "group_code": "789012"
  }
}
```

### Get Group Members

```http
GET {{base_url}}/admin/group/members?per_page=15&page=1
Authorization: Bearer {{token}}
```

**Query Parameters:**
- `per_page` - Items per page (default: 15)
- `page` - Page number (default: 1)
- `search` - Search by name or email
- `department` - Filter by department name

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 2,
      "name": "Team Member",
      "email": "user@example.com",
      "organization_name": "Acme Corp",
      "department_name": "Finance",
      "admin_group_id": 1,
      "created_at": "2024-11-01T10:00:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total": 1,
    "per_page": 15
  }
}
```

### Remove Group Member

```http
DELETE {{base_url}}/admin/group/members/{{member_id}}
Authorization: Bearer {{token}}
```

**Response:**
```json
{
  "success": true,
  "message": "User removed from group successfully"
}
```

### User Join Group

```http
POST {{base_url}}/user/join-group
Authorization: Bearer {{token}}
Content-Type: application/json

{
  "group_code": "123456"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Successfully joined group",
  "data": {
    "id": 2,
    "name": "User Name",
    "admin_group_id": 1,
    "admin_group": {
      "id": 1,
      "group_code": "123456",
      "admin": {
        "name": "Admin User"
      }
    }
  }
}
```

### Get User Group Info

```http
GET {{base_url}}/user/group-info
Authorization: Bearer {{token}}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "admin_group_id": 1,
    "admin_group": {
      "id": 1,
      "group_code": "123456",
      "is_active": true,
      "admin": {
        "id": 1,
        "name": "Admin User",
        "email": "admin@example.com",
        "organization_name": "Acme Corp"
      }
    }
  }
}
```

## ⚠️ Common Errors

### 404 - Group code not found
```json
{
  "success": false,
  "message": "Group code not found"
}
```
**Solution**: Verify the group code is correct and hasn't been regenerated.

### 403 - Cannot join group from different organization
```json
{
  "success": false,
  "message": "Cannot join group from different organization"
}
```
**Solution**: Ensure user's `organization_name` matches admin's organization (case-insensitive).

### 409 - User already belongs to a group
```json
{
  "success": false,
  "message": "User already belongs to a group"
}
```
**Solution**: User must be removed from current group before joining another.

### 403 - Unauthorized
```json
{
  "success": false,
  "message": "This action is unauthorized"
}
```
**Solution**: Ensure you're using an admin token for admin endpoints.

## 🧪 Test Scripts

The collection includes automated test scripts:

### Admin - Get Group Info
```javascript
if (pm.response.code === 200) {
    var jsonData = pm.response.json();
    pm.collectionVariables.set('group_code', jsonData.data.group_code);
    
    pm.test('Group code exists', function() {
        pm.expect(jsonData.data.group_code).to.be.a('string');
        pm.expect(jsonData.data.group_code.length).to.be.within(4, 6);
    });
}
```

### Admin - Get Group Members
```javascript
if (pm.response.code === 200) {
    var jsonData = pm.response.json();
    
    // Save first member ID for testing
    if (jsonData.data.length > 0) {
        pm.collectionVariables.set('member_id', jsonData.data[0].id);
    }
    
    pm.test('Members list returned', function() {
        pm.expect(jsonData.data).to.be.an('array');
    });
}
```

### User - Join Group
```javascript
pm.test('Successfully joined group', function() {
    pm.response.to.have.status(200);
});

if (pm.response.code === 200) {
    var jsonData = pm.response.json();
    
    pm.test('User assigned to group', function() {
        pm.expect(jsonData.data.admin_group_id).to.not.be.null;
    });
}
```

## 🔄 Data Scoping

After joining a group, data visibility changes:

### Regular Users
- ✅ See only their own expenses
- ✅ See only their own transfers
- ✅ See only their own incoming transactions
- ❌ Cannot see other users' data

### Admin Users
- ✅ See all group member expenses
- ✅ See all group member transfers
- ✅ See all group member incoming transactions
- ❌ Cannot see data from other groups
- ✅ Can only transfer to group members

## 🎯 Testing Scenarios

### Scenario 1: Basic Group Setup
1. Register admin → Group created
2. Get group info → Code saved
3. Register user with code → User joins
4. Admin views members → User appears

### Scenario 2: Post-Registration Join
1. Register user without code
2. User joins group later
3. Verify group assignment

### Scenario 3: Member Management
1. Admin views members
2. Admin removes member
3. Verify member removed

### Scenario 4: Code Regeneration
1. Get current code
2. Regenerate code
3. Verify new code different
4. Old code no longer works

### Scenario 5: Organization Mismatch
1. User from different org
2. Attempts to join group
3. Receives 403 error

### Scenario 6: Data Isolation
1. Create expenses as user
2. Admin sees user's expenses
3. Other admins don't see expenses

## 📊 Filtering & Pagination

### Get Group Members with Filters

```http
GET {{base_url}}/admin/group/members?per_page=10&page=1&search=john&department=Finance
```

**Available Filters:**
- `per_page` - Results per page (1-100)
- `page` - Page number
- `search` - Search name or email
- `department` - Filter by department name

## 🔐 Authorization

| Endpoint | Required Role | Notes |
|----------|--------------|-------|
| `/admin/group` | Admin | Must be authenticated admin |
| `/admin/group/regenerate` | Admin | Must own the group |
| `/admin/group/members` | Admin | Only sees own group members |
| `/admin/group/members/{id}` | Admin | Can only remove own group members |
| `/user/join-group` | User | Any authenticated user |
| `/user/group-info` | User | Any authenticated user |

## 💡 Tips

1. **Save group code immediately** after admin registration
2. **Use test scripts** to auto-capture variables
3. **Test organization matching** with different orgs
4. **Verify data isolation** between groups
5. **Test member removal** and re-joining
6. **Check transfer restrictions** to group members

## 🔗 Related Resources

- [Complete Testing Guide](ADMIN_GROUP_TESTING_GUIDE.md)
- [Admin Group Documentation](../docs/ADMIN_GROUP_MANAGEMENT.md)
- [API Design Document](../.kiro/specs/admin-group-management/design.md)
- [Requirements Document](../.kiro/specs/admin-group-management/requirements.md)

## 📞 Support

For issues or questions:
- Check test results in Postman Console
- Review error messages in responses
- Verify authentication tokens are valid
- Ensure correct role for endpoints

---

**Quick Reference v1.0** | Last Updated: November 2024

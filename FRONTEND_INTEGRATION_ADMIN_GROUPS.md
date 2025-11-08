# Frontend Integration Guide - Admin Group Management

## 🎯 Overview

This document provides complete integration instructions for the Admin Group Management feature in the frontend application. This feature replaces the traditional organization/department dropdown selection with a group-based system using 6-character group codes.

## 📋 Table of Contents

1. [Breaking Changes](#breaking-changes)
2. [New API Endpoints](#new-api-endpoints)
3. [Modified API Endpoints](#modified-api-endpoints)
4. [Data Model Changes](#data-model-changes)
5. [User Flows](#user-flows)
6. [UI/UX Requirements](#uiux-requirements)
7. [Error Handling](#error-handling)
8. [Testing Checklist](#testing-checklist)

---

## 🚨 Breaking Changes

### Registration Flow Changes

**OLD BEHAVIOR** (Before Admin Groups):
```json
POST /api/v1/auth/register
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "role": "user",
  "organization_id": 1,
  "department_id": 2
}
```

**NEW BEHAVIOR** (With Admin Groups):
```json
POST /api/v1/auth/register
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "role": "user",
  "group_code": "ABC123"
}
```

### Key Changes
- ❌ **REMOVED**: `organization_id` and `department_id` fields
- ✅ **ADDED**: `group_code` field (6 characters, case-insensitive)
- ✅ **ADDED**: `organization_name` and `department_name` (text fields, optional)

---

## 🆕 New API Endpoints

### 1. Get Admin Group Information

**Endpoint**: `GET /api/v1/admin/group`

**Authentication**: Required (Admin role only)

**Description**: Get the admin's group information including group code and member count.

**Request**:
```http
GET /api/v1/admin/group
Authorization: Bearer {token}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "admin_user_id": 5,
    "group_code": "ABC123",
    "group_name": "Marketing Team",
    "is_active": true,
    "members_count": 12,
    "created_at": "2025-11-01T10:00:00.000000Z",
    "updated_at": "2025-11-01T10:00:00.000000Z"
  }
}
```

**Error Responses**:
- `404`: Admin group not found (admin hasn't created a group yet)
- `401`: Unauthorized (not logged in)
- `403`: Forbidden (not an admin)

---

### 2. Regenerate Group Code

**Endpoint**: `POST /api/v1/admin/group/regenerate`

**Authentication**: Required (Admin role only)

**Description**: Generate a new 6-character group code for the admin's group.

**Request**:
```http
POST /api/v1/admin/group/regenerate
Authorization: Bearer {token}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Group code regenerated successfully",
  "data": {
    "id": 1,
    "admin_user_id": 5,
    "group_code": "XYZ789",
    "group_name": "Marketing Team",
    "is_active": true,
    "members_count": 12,
    "created_at": "2025-11-01T10:00:00.000000Z",
    "updated_at": "2025-11-01T12:30:00.000000Z"
  }
}
```

**Use Cases**:
- Admin wants to revoke access to old group code
- Security concern (code was shared publicly)
- Admin wants a more memorable code

---

### 3. Get Group Members

**Endpoint**: `GET /api/v1/admin/group/members`

**Authentication**: Required (Admin role only)

**Description**: Get list of all users in the admin's group.

**Request**:
```http
GET /api/v1/admin/group/members
Authorization: Bearer {token}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": 10,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user",
      "organization_name": "Acme Corp",
      "department_name": "Marketing",
      "created_at": "2025-11-01T10:00:00.000000Z"
    },
    {
      "id": 11,
      "name": "Jane Smith",
      "email": "jane@example.com",
      "role": "user",
      "organization_name": "Acme Corp",
      "department_name": "Sales",
      "created_at": "2025-11-01T11:00:00.000000Z"
    }
  ]
}
```

---

### 4. Remove Group Member

**Endpoint**: `DELETE /api/v1/admin/group/members/{id}`

**Authentication**: Required (Admin role only)

**Description**: Remove a user from the admin's group.

**Request**:
```http
DELETE /api/v1/admin/group/members/10
Authorization: Bearer {token}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Member removed from group successfully"
}
```

**Error Responses**:
- `404`: User not found or not in admin's group
- `403`: Cannot remove yourself (admin)
- `403`: Cannot remove other admins

---

### 5. Join Group (User)

**Endpoint**: `POST /api/v1/user/join-group`

**Authentication**: Required (Any authenticated user)

**Description**: Join an admin group using a group code.

**Request**:
```http
POST /api/v1/user/join-group
Authorization: Bearer {token}
Content-Type: application/json

{
  "group_code": "ABC123"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Successfully joined the group",
  "data": {
    "group_code": "ABC123",
    "group_name": "Marketing Team",
    "admin_name": "Admin User"
  }
}
```

**Error Responses**:
- `404`: Group code not found
- `400`: Already in a group
- `403`: Admins cannot join other groups

---

### 6. Get User's Group Info

**Endpoint**: `GET /api/v1/user/group-info`

**Authentication**: Required (Any authenticated user)

**Description**: Get information about the user's current group.

**Request**:
```http
GET /api/v1/user/group-info
Authorization: Bearer {token}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "group_code": "ABC123",
    "group_name": "Marketing Team",
    "admin_name": "Admin User",
    "admin_email": "admin@example.com",
    "members_count": 12,
    "joined_at": "2025-11-01T10:00:00.000000Z"
  }
}
```

**Error Responses**:
- `404`: User is not in any group

---

## 🔄 Modified API Endpoints

### Registration Endpoint

**Endpoint**: `POST /api/v1/auth/register`

**Changes**:
- ✅ Added `group_code` field (required for users, optional for admins)
- ✅ Added `organization_name` field (optional, max 255 chars)
- ✅ Added `department_name` field (optional, max 255 chars)
- ❌ Removed `organization_id` field
- ❌ Removed `department_id` field

**New Request Format**:
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "role": "user",
  "group_code": "ABC123",
  "organization_name": "Acme Corp",
  "department_name": "Marketing"
}
```

**Validation Rules**:
- `group_code`: Required if role is "user", must be 6 characters, must exist
- `organization_name`: Optional, max 255 characters
- `department_name`: Optional, max 255 characters
- Admins: Group is auto-created on registration

---

### User Profile Endpoints

All user profile responses now include:
```json
{
  "id": 10,
  "name": "John Doe",
  "email": "john@example.com",
  "role": "user",
  "organization_name": "Acme Corp",
  "department_name": "Marketing",
  "admin_group_id": 1,
  "created_at": "2025-11-01T10:00:00.000000Z",
  "updated_at": "2025-11-01T10:00:00.000000Z"
}
```

**Changes**:
- ✅ Added `organization_name` (string)
- ✅ Added `department_name` (string)
- ✅ Added `admin_group_id` (integer, nullable)
- ⚠️ `organization_id` and `department_id` still exist but are deprecated

---

## 📊 Data Model Changes

### User Model

**New Fields**:
```typescript
interface User {
  id: number;
  name: string;
  email: string;
  role: 'admin' | 'user';
  
  // NEW FIELDS
  organization_name: string | null;
  department_name: string | null;
  admin_group_id: number | null;
  
  // DEPRECATED (still present for backward compatibility)
  organization_id: number | null;
  department_id: number | null;
  
  created_at: string;
  updated_at: string;
}
```

### Admin Group Model

**New Model**:
```typescript
interface AdminGroup {
  id: number;
  admin_user_id: number;
  group_code: string; // 6 characters, unique
  group_name: string | null;
  is_active: boolean;
  members_count?: number; // Included in some responses
  created_at: string;
  updated_at: string;
}
```

---

## 👥 User Flows

### Flow 1: Admin Registration

1. Admin fills registration form
2. Admin selects role: "admin"
3. Admin optionally enters organization_name and department_name
4. Submit registration
5. Backend auto-creates admin group with unique 6-character code
6. Admin receives success response with group_code
7. Admin can share group_code with team members

**UI Requirements**:
- Show organization_name and department_name as optional text inputs
- Remove organization and department dropdowns
- After successful registration, display the generated group_code prominently
- Provide copy-to-clipboard functionality for group_code

---

### Flow 2: User Registration

1. User receives group_code from their admin
2. User fills registration form
3. User selects role: "user"
4. User enters the 6-character group_code
5. User optionally enters organization_name and department_name
6. Submit registration
7. User is added to the admin's group
8. User can now see data from their group

**UI Requirements**:
- Show group_code input field (6 characters, case-insensitive)
- Validate group_code format (exactly 6 alphanumeric characters)
- Show organization_name and department_name as optional text inputs
- Display helpful error if group_code is invalid
- Show success message with group name after joining

---

### Flow 3: Admin Managing Group

1. Admin logs in
2. Admin navigates to "Group Management" section
3. Admin sees current group_code and member count
4. Admin can:
   - View list of all group members
   - Remove members from group
   - Regenerate group_code (invalidates old code)
   - Update group_name

**UI Requirements**:
- Display group_code prominently with copy button
- Show member count
- List all members with remove button
- Confirm before removing member
- Confirm before regenerating code (warn about invalidation)
- Show success/error messages for all actions

---

### Flow 4: User Joining Group Later

1. User registers without group_code (if allowed)
2. User later receives group_code from admin
3. User navigates to "Join Group" section
4. User enters group_code
5. User joins the group
6. User can now see group data

**UI Requirements**:
- Provide "Join Group" option in user settings
- Show current group status (if already in a group)
- Prevent joining if already in a group
- Show success message with group details

---

## 🎨 UI/UX Requirements

### Registration Screen Changes

#### For Admin Registration:
```
┌─────────────────────────────────────┐
│  Register as Admin                  │
├─────────────────────────────────────┤
│  Name: [________________]           │
│  Email: [________________]          │
│  Password: [________________]       │
│  Confirm: [________________]        │
│                                     │
│  Role: ● Admin  ○ User              │
│                                     │
│  Organization (optional):           │
│  [________________]                 │
│                                     │
│  Department (optional):             │
│  [________________]                 │
│                                     │
│  [    Register    ]                 │
└─────────────────────────────────────┘

After Success:
┌─────────────────────────────────────┐
│  ✅ Registration Successful!        │
├─────────────────────────────────────┤
│  Your Group Code:                   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │     ABC123     📋 Copy      │   │
│  └─────────────────────────────┘   │
│                                     │
│  Share this code with your team     │
│  members so they can join your      │
│  group during registration.         │
│                                     │
│  [   Continue to Dashboard   ]      │
└─────────────────────────────────────┘
```

#### For User Registration:
```
┌─────────────────────────────────────┐
│  Register as User                   │
├─────────────────────────────────────┤
│  Name: [________________]           │
│  Email: [________________]          │
│  Password: [________________]       │
│  Confirm: [________________]        │
│                                     │
│  Role: ○ Admin  ● User              │
│                                     │
│  Group Code (required):             │
│  [______] (6 characters)            │
│  ℹ️ Get this from your admin        │
│                                     │
│  Organization (optional):           │
│  [________________]                 │
│                                     │
│  Department (optional):             │
│  [________________]                 │
│                                     │
│  [    Register    ]                 │
└─────────────────────────────────────┘
```

### Admin Dashboard - Group Management Section

```
┌─────────────────────────────────────────────────────┐
│  Group Management                                   │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Your Group Code:                                   │
│  ┌───────────────────────────────────────────┐     │
│  │  ABC123  📋 Copy  🔄 Regenerate          │     │
│  └───────────────────────────────────────────┘     │
│                                                     │
│  Group Name: Marketing Team                         │
│  Members: 12                                        │
│                                                     │
│  ┌─────────────────────────────────────────┐       │
│  │  Group Members                          │       │
│  ├─────────────────────────────────────────┤       │
│  │  👤 John Doe                            │       │
│  │     john@example.com                    │       │
│  │     Marketing                      [❌] │       │
│  ├─────────────────────────────────────────┤       │
│  │  👤 Jane Smith                          │       │
│  │     jane@example.com                    │       │
│  │     Sales                          [❌] │       │
│  └─────────────────────────────────────────┘       │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### User Settings - Group Info Section

```
┌─────────────────────────────────────────────────────┐
│  My Group                                           │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Group Code: ABC123                                 │
│  Group Name: Marketing Team                         │
│  Admin: Admin User (admin@example.com)              │
│  Members: 12                                        │
│  Joined: Nov 1, 2025                                │
│                                                     │
│  ℹ️ Contact your admin to leave the group          │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## ⚠️ Error Handling

### Registration Errors

**Invalid Group Code**:
```json
{
  "success": false,
  "message": "The selected group code is invalid.",
  "errors": {
    "group_code": ["The selected group code is invalid."]
  }
}
```
**UI**: Show error below group_code input field

**Group Code Required**:
```json
{
  "success": false,
  "message": "The group code field is required.",
  "errors": {
    "group_code": ["The group code field is required."]
  }
}
```
**UI**: Show error below group_code input field

### Join Group Errors

**Already in Group**:
```json
{
  "success": false,
  "message": "You are already in a group"
}
```
**UI**: Show alert/toast notification

**Admin Cannot Join**:
```json
{
  "success": false,
  "message": "Admins cannot join other groups"
}
```
**UI**: Show alert/toast notification

### Remove Member Errors

**Cannot Remove Self**:
```json
{
  "success": false,
  "message": "You cannot remove yourself from the group"
}
```
**UI**: Disable remove button for admin's own entry

**Member Not Found**:
```json
{
  "success": false,
  "message": "User not found or not in your group"
}
```
**UI**: Show error toast and refresh member list

---

## ✅ Testing Checklist

### Registration Testing

- [ ] Admin can register without group_code
- [ ] Admin receives unique 6-character group_code after registration
- [ ] User cannot register without group_code
- [ ] User can register with valid group_code
- [ ] User cannot register with invalid group_code
- [ ] User cannot register with non-existent group_code
- [ ] Group_code is case-insensitive (ABC123 = abc123)
- [ ] Organization_name and department_name are optional
- [ ] Organization_name and department_name are saved correctly

### Admin Group Management Testing

- [ ] Admin can view their group_code
- [ ] Admin can copy group_code to clipboard
- [ ] Admin can regenerate group_code
- [ ] Old group_code becomes invalid after regeneration
- [ ] Admin can view list of group members
- [ ] Admin can remove group members
- [ ] Admin cannot remove themselves
- [ ] Admin cannot remove other admins
- [ ] Member count updates after adding/removing members

### User Group Testing

- [ ] User can view their group information
- [ ] User can join a group using group_code
- [ ] User cannot join if already in a group
- [ ] User sees correct group name and admin info
- [ ] User is removed from group when admin removes them

### Data Scoping Testing

- [ ] Users only see expenses from their group
- [ ] Users only see transfers from their group
- [ ] Users only see incoming transactions from their group
- [ ] Users only see fund boxes from their group
- [ ] Admins see all data from their group members
- [ ] Users from different groups cannot see each other's data

### API Testing

- [ ] All new endpoints return correct status codes
- [ ] All new endpoints return correct data structure
- [ ] Authentication is enforced on all endpoints
- [ ] Authorization is enforced (admin-only endpoints)
- [ ] Error responses are consistent and helpful
- [ ] Validation errors are clear and actionable

---

## 🔧 Implementation Steps

### Step 1: Update Type Definitions

```typescript
// types/user.ts
export interface User {
  id: number;
  name: string;
  email: string;
  role: 'admin' | 'user';
  organization_name: string | null;
  department_name: string | null;
  admin_group_id: number | null;
  created_at: string;
  updated_at: string;
}

// types/adminGroup.ts
export interface AdminGroup {
  id: number;
  admin_user_id: number;
  group_code: string;
  group_name: string | null;
  is_active: boolean;
  members_count?: number;
  created_at: string;
  updated_at: string;
}

export interface GroupMember {
  id: number;
  name: string;
  email: string;
  role: string;
  organization_name: string | null;
  department_name: string | null;
  created_at: string;
}

export interface GroupInfo {
  group_code: string;
  group_name: string | null;
  admin_name: string;
  admin_email: string;
  members_count: number;
  joined_at: string;
}
```

### Step 2: Create API Service Methods

```typescript
// services/adminGroupService.ts
export const adminGroupService = {
  // Get admin's group info
  getAdminGroup: async (): Promise<AdminGroup> => {
    const response = await api.get('/api/v1/admin/group');
    return response.data.data;
  },

  // Regenerate group code
  regenerateGroupCode: async (): Promise<AdminGroup> => {
    const response = await api.post('/api/v1/admin/group/regenerate');
    return response.data.data;
  },

  // Get group members
  getGroupMembers: async (): Promise<GroupMember[]> => {
    const response = await api.get('/api/v1/admin/group/members');
    return response.data.data;
  },

  // Remove group member
  removeMember: async (userId: number): Promise<void> => {
    await api.delete(`/api/v1/admin/group/members/${userId}`);
  },

  // Join group (user)
  joinGroup: async (groupCode: string): Promise<GroupInfo> => {
    const response = await api.post('/api/v1/user/join-group', {
      group_code: groupCode
    });
    return response.data.data;
  },

  // Get user's group info
  getUserGroupInfo: async (): Promise<GroupInfo> => {
    const response = await api.get('/api/v1/user/group-info');
    return response.data.data;
  }
};
```

### Step 3: Update Registration Form

```typescript
// components/RegistrationForm.tsx
interface RegistrationFormData {
  name: string;
  email: string;
  password: string;
  password_confirmation: string;
  role: 'admin' | 'user';
  group_code?: string; // Required for users
  organization_name?: string; // Optional
  department_name?: string; // Optional
}

// Remove organization_id and department_id fields
// Add group_code input for users
// Add organization_name and department_name text inputs
```

### Step 4: Create Group Management Components

```typescript
// components/AdminGroupManagement.tsx
// - Display group code with copy button
// - Display member list
// - Implement remove member functionality
// - Implement regenerate code functionality

// components/UserGroupInfo.tsx
// - Display current group information
// - Display admin contact info
// - Show member count

// components/JoinGroupForm.tsx
// - Input for group code
// - Validation for 6-character code
// - Submit to join group
```

### Step 5: Update State Management

```typescript
// store/authSlice.ts or similar
// Update user state to include new fields:
// - organization_name
// - department_name
// - admin_group_id

// Add admin group state:
// - currentGroup: AdminGroup | null
// - groupMembers: GroupMember[]
```

---

## 📱 Mobile App Considerations

### Flutter/React Native Changes

1. Update registration screens
2. Add group management screens for admins
3. Add group info display for users
4. Update API client with new endpoints
5. Handle group_code validation
6. Implement copy-to-clipboard for group codes
7. Add error handling for group-related errors

### Offline Support

- Cache group_code locally after registration
- Cache group member list for admins
- Sync group changes when online
- Handle conflicts if group_code changes while offline

---

## 🔐 Security Considerations

### Group Code Security

- Group codes are 6 characters (alphanumeric)
- Codes are unique across all groups
- Codes can be regenerated by admin
- Old codes become invalid immediately after regeneration

### Access Control

- Only admins can manage their group
- Users can only view their own group info
- Users cannot remove themselves from groups
- Admins cannot join other groups

### Data Scoping

- All financial data is scoped to admin groups
- Users only see data from their group members
- Cross-group data access is prevented at API level

---

## 📞 Support & Questions

For questions or issues during integration:

1. Review the [Admin Group Management Guide](docs/ADMIN_GROUP_MANAGEMENT.md)
2. Check the [API Documentation](API_ENDPOINTS_REFERENCE.md)
3. Test endpoints using the [Postman Collection](postman/Finance-API-Complete-v2.postman_collection.json)
4. Review [Testing Guide](postman/ADMIN_GROUP_TESTING_GUIDE.md)

---

## 📝 Migration Notes

### Backward Compatibility

- `organization_id` and `department_id` fields still exist in database
- Old API endpoints still work but are deprecated
- Frontend should migrate to new fields gradually
- Both old and new fields are returned in API responses during transition

### Migration Timeline

1. **Phase 1**: Add support for new fields (organization_name, department_name, group_code)
2. **Phase 2**: Update UI to use new registration flow
3. **Phase 3**: Add group management features
4. **Phase 4**: Remove old organization/department dropdowns
5. **Phase 5**: Deprecate old fields completely

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-01  
**Backend Version**: Compatible with API v1  
**Status**: Ready for Frontend Integration

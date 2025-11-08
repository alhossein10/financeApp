# Admin Group Management API Documentation

## Overview

The Admin Group Management system allows admin users to create and manage groups of regular users within their organization. This feature enables data isolation and group-based access control for financial transactions.

## Key Concepts

### Admin Groups
- Each admin user automatically gets a group created upon registration
- Groups are identified by a unique 4-6 digit numeric code
- Admins can share their group code with regular users to invite them to join
- Each admin can only manage one group

### Group Codes
- **Format**: 4-6 digit numeric code (e.g., "1234", "56789", "123456")
- **Generation**: Automatically generated using cryptographically secure random number generation
- **Uniqueness**: Each group code is unique across the entire system
- **Regeneration**: Admins can regenerate their group code at any time
- **Security**: Group codes are validated on every join attempt

### Organization Matching
- Users can only join groups where the admin's organization name matches their own
- Organization name comparison is **case-insensitive**
- Department names do NOT need to match
- This ensures organizational boundaries are maintained

### Data Scoping
- **Admin users**: Can view and manage financial data for all users in their group
- **Regular users**: Can only view and manage their own financial data
- **Cross-group isolation**: Admins cannot access data from other admin groups

## Registration Workflows

### Admin Registration Workflow

1. Admin registers with organization name and department name (optional)
2. System automatically creates an AdminGroup with a unique group code
3. Admin receives their group code in the registration response
4. Admin can share this code with regular users to invite them

**Example Request:**
```json
POST /api/v1/auth/register
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "role": "admin",
  "organization_name": "Acme Corporation",
  "department_name": "Finance"
}
```

**Example Response:**
```json
{
  "success": true,
  "message": "User registered successfully.",
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "admin",
      "organization_name": "Acme Corporation",
      "department_name": "Finance",
      "admin_group_id": null,
      "created_at": "2025-11-01T10:00:00.000000Z"
    },
    "token": "1|abcdef123456...",
    "token_type": "Bearer",
    "expires_in": 2592000,
    "group": {
      "id": 1,
      "group_code": "123456",
      "group_name": "Acme Corporation - John Doe"
    }
  }
}
```

### Regular User Registration (Without Group Code)

1. User registers with organization name and department name (optional)
2. User is created but not assigned to any group
3. User can join a group later using the join-group endpoint

**Example Request:**
```json
POST /api/v1/auth/register
{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "role": "user",
  "organization_name": "Acme Corporation",
  "department_name": "Marketing"
}
```

### Regular User Registration (With Group Code)

1. User registers with organization name, department name (optional), and group code
2. System validates the group code exists
3. System validates organization name matches admin's organization (case-insensitive)
4. User is automatically assigned to the admin's group

**Example Request:**
```json
POST /api/v1/auth/register
{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "role": "user",
  "organization_name": "Acme Corporation",
  "department_name": "Marketing",
  "group_code": "123456"
}
```

**Example Response:**
```json
{
  "success": true,
  "message": "User registered successfully.",
  "data": {
    "user": {
      "id": 2,
      "name": "Jane Smith",
      "email": "jane@example.com",
      "role": "user",
      "organization_name": "Acme Corporation",
      "department_name": "Marketing",
      "admin_group_id": 1,
      "created_at": "2025-11-01T10:05:00.000000Z"
    },
    "token": "2|xyz789...",
    "token_type": "Bearer",
    "expires_in": 2592000,
    "group": {
      "id": 1,
      "group_name": "Acme Corporation - John Doe"
    }
  }
}
```

## API Endpoints

### Admin Group Management Endpoints

#### 1. Get Admin's Group Information
**Endpoint:** `GET /api/v1/admin/group`  
**Authentication:** Required (Admin only)  
**Description:** Returns the authenticated admin's group information including the group code

**Response:**
```json
{
  "success": true,
  "message": "Group information retrieved successfully.",
  "data": {
    "group": {
      "id": 1,
      "admin_user_id": 1,
      "group_code": "123456",
      "group_name": "Acme Corporation - John Doe",
      "is_active": true,
      "created_at": "2025-11-01T10:00:00.000000Z",
      "updated_at": "2025-11-01T10:00:00.000000Z"
    }
  }
}
```

#### 2. Regenerate Group Code
**Endpoint:** `POST /api/v1/admin/group/regenerate`  
**Authentication:** Required (Admin only)  
**Description:** Generates a new unique group code for the admin. The old code becomes invalid.

**Response:**
```json
{
  "success": true,
  "message": "Group code regenerated successfully.",
  "data": {
    "group": {
      "id": 1,
      "admin_user_id": 1,
      "group_code": "654321",
      "group_name": "Acme Corporation - John Doe",
      "is_active": true,
      "created_at": "2025-11-01T10:00:00.000000Z",
      "updated_at": "2025-11-01T11:00:00.000000Z"
    }
  }
}
```

#### 3. Get Group Members
**Endpoint:** `GET /api/v1/admin/group/members`  
**Authentication:** Required (Admin only)  
**Description:** Returns paginated list of users in the admin's group

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `per_page` (optional): Items per page (default: 15, max: 100)
- `search` (optional): Search by name or email

**Example Request:**
```
GET /api/v1/admin/group/members?page=1&per_page=15&search=jane
```

**Response:**
```json
{
  "success": true,
  "message": "Group members retrieved successfully.",
  "data": {
    "members": {
      "current_page": 1,
      "data": [
        {
          "id": 2,
          "name": "Jane Smith",
          "email": "jane@example.com",
          "organization_name": "Acme Corporation",
          "department_name": "Marketing",
          "created_at": "2025-11-01T10:05:00.000000Z"
        }
      ],
      "per_page": 15,
      "total": 1,
      "last_page": 1
    }
  }
}
```

#### 4. Remove Member from Group
**Endpoint:** `DELETE /api/v1/admin/group/members/{id}`  
**Authentication:** Required (Admin only)  
**Description:** Removes a user from the admin's group

**Path Parameters:**
- `id`: User ID to remove

**Response:**
```json
{
  "success": true,
  "message": "Member removed from group successfully."
}
```

### User Group Management Endpoints

#### 5. Join Group Using Code
**Endpoint:** `POST /api/v1/user/join-group`  
**Authentication:** Required (Regular user only)  
**Description:** Allows a regular user to join an admin's group using a group code

**Request Body:**
```json
{
  "group_code": "123456"
}
```

**Success Response:**
```json
{
  "success": true,
  "message": "Successfully joined group.",
  "data": {
    "group": {
      "id": 1,
      "group_name": "Acme Corporation - John Doe",
      "admin": {
        "id": 1,
        "name": "John Doe",
        "email": "john@example.com"
      }
    }
  }
}
```

**Error Response (Organization Mismatch):**
```json
{
  "success": false,
  "message": "Failed to join group.",
  "errors": {
    "group_code": ["Cannot join group from different organization."]
  }
}
```

#### 6. Get User's Group Information
**Endpoint:** `GET /api/v1/user/group-info`  
**Authentication:** Required (Regular user only)  
**Description:** Returns the authenticated user's group information

**Response:**
```json
{
  "success": true,
  "message": "Group information retrieved successfully.",
  "data": {
    "group": {
      "id": 1,
      "group_name": "Acme Corporation - John Doe",
      "admin": {
        "id": 1,
        "name": "John Doe",
        "email": "john@example.com"
      }
    }
  }
}
```

## Validation Rules

### Registration Validation

| Field | Type | Required | Rules | Description |
|-------|------|----------|-------|-------------|
| name | string | Yes | min:2, max:255 | User's full name |
| email | string | Yes | email, unique | User's email address |
| password | string | Yes | min:8, confirmed | User's password |
| password_confirmation | string | Yes | matches password | Password confirmation |
| role | string | Yes | in:admin,user | User role |
| organization_name | string | Yes | min:2, max:255 | Free-text organization name |
| department_name | string | No | min:2, max:255 | Free-text department name |
| group_code | string | No | digits:4-6, exists | Group invitation code |

### Group Code Validation

| Rule | Description |
|------|-------------|
| Format | Must be 4-6 digit numeric string |
| Uniqueness | Must be unique across all admin groups |
| Existence | Must exist in admin_groups table when joining |
| Organization Match | User's organization must match admin's organization (case-insensitive) |
| Active Status | Admin group must be active |

### Join Group Validation

| Field | Type | Required | Rules | Description |
|-------|------|----------|-------|-------------|
| group_code | string | Yes | digits:4-6, exists | Valid group code |

**Additional Validation:**
- User must not already be in a group
- User's organization name must match admin's organization name (case-insensitive)
- Admin group must be active
- User must have role='user' (admins cannot join other groups)

## Error Responses

### Common Error Codes

| Status Code | Error Type | Description |
|-------------|------------|-------------|
| 401 | Unauthenticated | User is not authenticated |
| 403 | Forbidden | User doesn't have permission (e.g., organization mismatch) |
| 404 | Not Found | Resource not found (e.g., invalid group code, user not in group) |
| 409 | Conflict | User already in a group |
| 422 | Validation Error | Request validation failed |
| 500 | Server Error | Internal server error |

### Example Error Responses

**Invalid Group Code:**
```json
{
  "success": false,
  "message": "Failed to join group.",
  "errors": {
    "group_code": ["The selected group code is invalid."]
  }
}
```

**Organization Mismatch:**
```json
{
  "success": false,
  "message": "Failed to join group.",
  "errors": {
    "group_code": ["Cannot join group from different organization."]
  }
}
```

**User Already in Group:**
```json
{
  "success": false,
  "message": "Failed to join group.",
  "errors": {
    "group_code": ["User already belongs to a group."]
  }
}
```

**User Not Found:**
```json
{
  "success": false,
  "message": "User not found.",
  "errors": {
    "user": ["User not found."]
  }
}
```

## Data Scoping Examples

### Admin Data Access

When an admin requests expenses, transfers, or incoming transactions, they see data for all users in their group:

**Request:**
```
GET /api/v1/expenses
Authorization: Bearer {admin_token}
```

**Response includes:**
- All expenses created by users in the admin's group
- Each expense includes the user information
- Expenses are filtered by admin_group_id

### Regular User Data Access

When a regular user requests expenses, transfers, or incoming transactions, they only see their own data:

**Request:**
```
GET /api/v1/expenses
Authorization: Bearer {user_token}
```

**Response includes:**
- Only expenses created by the authenticated user
- Expenses are filtered by user_id

### Transfer Restrictions

Admins can only create transfers to users within their group:

**Valid Transfer (within group):**
```json
POST /api/v1/transfers
{
  "recipient_user_id": 2,
  "amount_usd": 100.00,
  "transfer_date": "2025-11-01",
  "notes": "Payment to team member"
}
```

**Invalid Transfer (outside group):**
```json
POST /api/v1/transfers
{
  "recipient_user_id": 99,
  "amount_usd": 100.00,
  "transfer_date": "2025-11-01"
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Validation failed.",
  "errors": {
    "recipient_user_id": ["Cannot transfer to user outside your group."]
  }
}
```

## Multi-Admin Scenarios

### Multiple Admins in Same Organization

The system supports multiple admins within the same organization, each managing their own separate group:

**Scenario:**
- Admin A (John Doe) - Organization: "Acme Corporation" - Group Code: "123456"
- Admin B (Sarah Johnson) - Organization: "Acme Corporation" - Group Code: "789012"
- User 1 (Jane Smith) - Organization: "Acme Corporation" - Joins Admin A's group
- User 2 (Bob Wilson) - Organization: "Acme Corporation" - Joins Admin B's group

**Data Isolation:**
- Admin A can only see data from User 1
- Admin B can only see data from User 2
- User 1 cannot see User 2's data and vice versa
- Each admin has a unique group code

### Cross-Organization Isolation

Users from different organizations cannot join each other's groups:

**Scenario:**
- Admin A - Organization: "Acme Corporation" - Group Code: "123456"
- User 1 - Organization: "Beta Industries" - Tries to join with code "123456"

**Result:**
- Join attempt fails with organization mismatch error
- User 1 cannot join Admin A's group

## Best Practices

### For Admins

1. **Share Group Code Securely**: Only share your group code with users you want in your group
2. **Regenerate Code if Compromised**: If your group code is shared publicly, regenerate it immediately
3. **Regular Member Review**: Periodically review your group members and remove inactive users
4. **Organization Name Consistency**: Ensure all team members use the exact same organization name (case doesn't matter)

### For Regular Users

1. **Verify Organization Name**: Make sure your organization name matches your admin's exactly
2. **Get Code from Admin**: Only use group codes provided by your organization's admin
3. **One Group Only**: You can only be in one group at a time
4. **Contact Admin for Issues**: If you can't join a group, contact your admin to verify the code and organization name

### For Developers

1. **Case-Insensitive Comparison**: Always use case-insensitive comparison for organization names
2. **Validate Group Membership**: Always check group membership before displaying or modifying data
3. **Scope Queries Properly**: Use the repository methods that automatically scope by group
4. **Handle Errors Gracefully**: Provide clear error messages for group-related validation failures
5. **Audit Group Changes**: Log all group membership changes for security auditing

## Security Considerations

### Group Code Security

- Group codes are generated using cryptographically secure random number generation
- Codes are 4-6 digits to balance security and usability
- Admins can regenerate codes if compromised
- Rate limiting should be implemented on join attempts

### Authorization Checks

- All admin group endpoints verify the user is an admin
- All user group endpoints verify the user is a regular user
- Group membership is verified before data access
- Cross-group access is prevented at the repository level

### Data Isolation

- Repository methods enforce group-based scoping
- Admins cannot access data from other admin groups
- Regular users cannot access data from other users
- Database queries include group membership checks

## Testing Scenarios

### Test Case 1: Admin Registration and Group Creation
1. Register as admin with organization name
2. Verify group is created automatically
3. Verify group code is returned
4. Verify group code is unique

### Test Case 2: User Joins Group with Valid Code
1. Register admin and get group code
2. Register user with same organization name and group code
3. Verify user is assigned to admin's group
4. Verify user can see their own data
5. Verify admin can see user's data

### Test Case 3: Organization Mismatch Prevention
1. Register admin with organization "Acme Corp"
2. Register user with organization "Beta Industries" and admin's group code
3. Verify join fails with organization mismatch error

### Test Case 4: Group Code Regeneration
1. Register admin and get initial group code
2. Regenerate group code
3. Verify new code is different and unique
4. Verify old code no longer works

### Test Case 5: Data Isolation Between Groups
1. Register two admins in same organization
2. Register users in each admin's group
3. Create expenses for each user
4. Verify Admin A only sees their group's expenses
5. Verify Admin B only sees their group's expenses

### Test Case 6: Remove Member from Group
1. Admin adds user to group
2. Admin removes user from group
3. Verify user's admin_group_id is null
4. Verify admin can no longer see user's data

### Test Case 7: Transfer Restrictions
1. Admin creates transfer to user in their group (should succeed)
2. Admin creates transfer to user outside their group (should fail)
3. Verify appropriate error message

## Migration Guide

### Migrating from Organization/Department IDs to Free-Text

If you're migrating from the old system with organization_id and department_id foreign keys:

1. **Data Migration**: The migration automatically copies organization and department names to the new text fields
2. **Backward Compatibility**: Old organization_id and department_id columns are made nullable but kept for reference
3. **API Changes**: Update your client applications to send organization_name and department_name instead of IDs
4. **Validation Updates**: Remove foreign key validation and add text field validation

### Rollback Strategy

If you need to rollback to the old system:

1. Run the down() migration to remove new columns
2. Restore organization_id and department_id as required fields
3. Update API endpoints to use old field names
4. Remove admin group functionality

## Frequently Asked Questions

**Q: Can a user be in multiple groups?**  
A: No, a user can only be in one admin group at a time.

**Q: Can an admin be a member of another admin's group?**  
A: No, admin users cannot join other groups. They can only manage their own group.

**Q: What happens if an admin is deleted?**  
A: The admin's group is also deleted (cascade), and all members are removed from the group.

**Q: Can I change my organization name after registration?**  
A: Yes, but be aware this may affect your ability to join groups or have users join your group.

**Q: Are group codes case-sensitive?**  
A: No, group codes are numeric only (4-6 digits).

**Q: How long are group codes valid?**  
A: Group codes are valid indefinitely until the admin regenerates them or the admin account is deleted.

**Q: Can I see which admin manages my group?**  
A: Yes, use the GET /api/v1/user/group-info endpoint to see your group's admin information.

**Q: What happens to my data if I'm removed from a group?**  
A: Your data remains in the system, but the admin can no longer see it. You can join another group or create your own data independently.

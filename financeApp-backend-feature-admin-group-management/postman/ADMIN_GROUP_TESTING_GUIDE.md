# Admin Group Management Testing Guide

This guide provides step-by-step instructions for testing the Admin Group Management feature using the Postman collection.

## Overview

The Admin Group Management system allows:
- **Admins** to create groups with unique codes and manage group members
- **Regular users** to join admin groups using group codes
- **Data isolation** between different admin groups
- **Transfer restrictions** to group members only

## Prerequisites

1. Import the `Finance-API-Complete-v2.postman_collection.json` into Postman
2. Import either the Local or Production environment file
3. Ensure the backend server is running

## Testing Workflow

### Scenario 1: Admin Group Creation and Management

#### Step 1: Register an Admin User

1. Navigate to **2. Authentication → Register Admin User**
2. Update the email to be unique (e.g., `admin1@example.com`)
3. Set the organization_name to `Acme Corporation`
4. Send the request
5. **Expected Result**: 
   - Status 201 Created
   - Token automatically saved to collection variables
   - Admin group automatically created in the background

#### Step 2: Get Admin Group Information

1. Navigate to **12. Admin Group Management → Admin - Get Group Info**
2. Send the request (uses the token from Step 1)
3. **Expected Result**:
   - Status 200 OK
   - Response includes `group_code` (4-6 digits)
   - `is_active` is true
   - Group code automatically saved to `{{group_code}}` variable

**Example Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "admin_user_id": 1,
    "group_code": "123456",
    "group_name": null,
    "is_active": true,
    "created_at": "2024-11-01T10:00:00.000000Z",
    "admin": {
      "id": 1,
      "name": "Admin User",
      "email": "admin1@example.com",
      "organization_name": "Acme Corporation"
    }
  }
}
```

#### Step 3: View Group Members (Initially Empty)

1. Navigate to **12. Admin Group Management → Admin - Get Group Members**
2. Send the request
3. **Expected Result**:
   - Status 200 OK
   - Empty array (no members yet)
   - Pagination metadata included

### Scenario 2: User Joins Admin Group

#### Step 4: Register a Regular User with Group Code

1. Navigate to **2. Authentication → Register Regular User with Group Code**
2. Update the email to be unique (e.g., `user1@example.com`)
3. Set `organization_name` to `Acme Corporation` (must match admin's organization)
4. The `group_code` variable is already set from Step 2
5. Send the request
6. **Expected Result**:
   - Status 201 Created
   - User automatically assigned to admin's group
   - `admin_group_id` is not null

**Example Request Body:**
```json
{
  "name": "Test User",
  "email": "user1@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "organization_name": "Acme Corporation",
  "department_name": "Finance",
  "group_code": "123456",
  "role": "user"
}
```

#### Step 5: User Views Their Group Info

1. Navigate to **12. Admin Group Management → User - Get Group Info**
2. Send the request (uses user's token from Step 4)
3. **Expected Result**:
   - Status 200 OK
   - Group information with admin details included

### Scenario 3: Admin Manages Group Members

#### Step 6: Admin Views Updated Member List

1. Switch back to admin token (or re-login as admin)
2. Navigate to **12. Admin Group Management → Admin - Get Group Members**
3. Send the request
4. **Expected Result**:
   - Status 200 OK
   - Array contains the user from Step 4
   - Member ID automatically saved to `{{member_id}}` variable

**Example Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 2,
      "name": "Test User",
      "email": "user1@example.com",
      "organization_name": "Acme Corporation",
      "department_name": "Finance",
      "admin_group_id": 1,
      "created_at": "2024-11-01T10:05:00.000000Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total": 1,
    "per_page": 15
  }
}
```

#### Step 7: Admin Removes a Member

1. Navigate to **12. Admin Group Management → Admin - Remove Group Member**
2. The `{{member_id}}` is already set from Step 6
3. Send the request
4. **Expected Result**:
   - Status 200 OK
   - Success message confirming removal
   - User's `admin_group_id` set to null

#### Step 8: Verify Member Removed

1. Navigate to **12. Admin Group Management → Admin - Get Group Members**
2. Send the request
3. **Expected Result**:
   - Status 200 OK
   - Empty array (member was removed)

### Scenario 4: User Joins Group After Registration

#### Step 9: Register User Without Group Code

1. Navigate to **2. Authentication → Register Regular User**
2. Update email to be unique (e.g., `user2@example.com`)
3. Set `organization_name` to `Acme Corporation`
4. Do NOT include `group_code`
5. Send the request
6. **Expected Result**:
   - Status 201 Created
   - User created without group assignment
   - `admin_group_id` is null

#### Step 10: User Joins Group Using Code

1. Navigate to **12. Admin Group Management → User - Join Group**
2. Ensure you're using the user token from Step 9
3. The `{{group_code}}` variable is already set
4. Send the request
5. **Expected Result**:
   - Status 200 OK
   - User successfully assigned to group
   - Group information returned

### Scenario 5: Group Code Regeneration

#### Step 11: Admin Regenerates Group Code

1. Switch to admin token
2. Navigate to **12. Admin Group Management → Admin - Regenerate Group Code**
3. Send the request
4. **Expected Result**:
   - Status 200 OK
   - New group code generated (different from previous)
   - New code automatically saved to `{{group_code}}` variable

#### Step 12: Verify Old Code is Invalid

1. Try to join group with old code (manually set old code in request)
2. Navigate to **12. Admin Group Management → User - Join Group**
3. Send the request with old code
4. **Expected Result**:
   - Status 404 Not Found
   - Error message: "Group code not found"

### Scenario 6: Organization Mismatch Prevention

#### Step 13: User from Different Organization Attempts to Join

1. Register a new user with different organization
2. Navigate to **2. Authentication → Register Regular User**
3. Set `organization_name` to `Different Corp` (not matching admin's)
4. Send the request
5. Navigate to **12. Admin Group Management → User - Join Group**
6. Try to join with the admin's group code
7. **Expected Result**:
   - Status 403 Forbidden
   - Error message: "Cannot join group from different organization"

### Scenario 7: Data Scoping Verification

#### Step 14: Create Expenses as Group Member

1. Login as a user who is in the admin's group
2. Navigate to **3. Expenses Management → Create Expense**
3. Create 2-3 test expenses
4. **Expected Result**: Expenses created successfully

#### Step 15: Admin Views Group Member Expenses

1. Switch to admin token
2. Navigate to **3. Expenses Management → List Expenses**
3. Send the request
4. **Expected Result**:
   - Status 200 OK
   - Admin sees expenses from all group members
   - Expenses from users outside the group are NOT visible

#### Step 16: User Views Only Own Expenses

1. Switch back to regular user token
2. Navigate to **3. Expenses Management → List Expenses**
3. Send the request
4. **Expected Result**:
   - Status 200 OK
   - User sees only their own expenses
   - Other users' expenses are NOT visible

### Scenario 8: Transfer Restrictions

#### Step 17: Admin Creates Transfer to Group Member

1. Login as admin
2. Ensure you have at least one user in your group
3. Navigate to **4. Transfers Management → Create Transfer**
4. Set `recipient_user_id` to a group member's ID
5. Send the request
6. **Expected Result**:
   - Status 201 Created
   - Transfer created successfully

#### Step 18: Admin Attempts Transfer to Non-Group Member

1. Still logged in as admin
2. Navigate to **4. Transfers Management → Create Transfer**
3. Set `recipient_user_id` to a user NOT in the group
4. Send the request
5. **Expected Result**:
   - Status 403 Forbidden
   - Error message: "Cannot transfer to user outside your group"

## Testing with Multiple Admins

### Scenario 9: Multiple Admins in Same Organization

#### Step 19: Register Second Admin

1. Navigate to **2. Authentication → Register Admin User**
2. Use different email (e.g., `admin2@example.com`)
3. Use SAME `organization_name`: `Acme Corporation`
4. Send the request
5. **Expected Result**:
   - Status 201 Created
   - New admin group created with different group code

#### Step 20: Verify Data Isolation

1. Create expenses as users in Admin 1's group
2. Login as Admin 2
3. Navigate to **3. Expenses Management → List Expenses**
4. **Expected Result**:
   - Admin 2 does NOT see Admin 1's group expenses
   - Complete data isolation between groups

## Query Parameters and Filters

### Group Members Filtering

The **Admin - Get Group Members** endpoint supports:

- `per_page`: Number of results per page (default: 15)
- `page`: Page number
- `search`: Search by name or email
- `department`: Filter by department name

**Example:**
```
GET {{base_url}}/admin/group/members?per_page=10&search=john&department=Finance
```

## Common Test Scenarios

### Test Case 1: User Cannot Join Multiple Groups

1. User joins Admin 1's group
2. User attempts to join Admin 2's group
3. **Expected**: Error - user already in a group

### Test Case 2: Invalid Group Code

1. User attempts to join with non-existent code
2. **Expected**: 404 Not Found

### Test Case 3: Admin Cannot Remove Non-Group Members

1. Admin attempts to remove user from different group
2. **Expected**: 403 Forbidden

### Test Case 4: Inactive Admin Group

1. Admin account is deactivated
2. Users attempt to join with that group code
3. **Expected**: Error - group not active

## Automated Test Scripts

The collection includes automated test scripts that:

1. **Save variables automatically**: group_code, member_id, tokens
2. **Validate responses**: Check status codes and data structure
3. **Verify business logic**: Organization matching, group assignment
4. **Test data isolation**: Ensure proper scoping

### Running All Tests

1. Open Postman Collection Runner
2. Select "Finance API - Complete Collection v2"
3. Select "12. Admin Group Management" folder
4. Click "Run Finance API"
5. Review test results

## Troubleshooting

### Issue: "Group code not found"
- **Cause**: Invalid or regenerated group code
- **Solution**: Get fresh group code from admin

### Issue: "Cannot join group from different organization"
- **Cause**: Organization name mismatch
- **Solution**: Ensure exact match (case-insensitive)

### Issue: "User already belongs to a group"
- **Cause**: User trying to join second group
- **Solution**: Remove from current group first

### Issue: "Unauthorized"
- **Cause**: Token expired or wrong role
- **Solution**: Re-login and ensure correct role

## Best Practices

1. **Use unique emails** for each test user
2. **Save group codes** immediately after admin registration
3. **Test with multiple admins** to verify isolation
4. **Clean up test data** between test runs
5. **Use environment variables** for different environments

## API Endpoints Summary

| Endpoint | Method | Role | Description |
|----------|--------|------|-------------|
| `/admin/group` | GET | Admin | Get admin's group info and code |
| `/admin/group/regenerate` | POST | Admin | Regenerate group code |
| `/admin/group/members` | GET | Admin | List group members (paginated) |
| `/admin/group/members/{id}` | DELETE | Admin | Remove member from group |
| `/user/join-group` | POST | User | Join group using code |
| `/user/group-info` | GET | User | Get current group info |

## Next Steps

After completing these tests:

1. Test with the Flutter mobile app
2. Verify data synchronization across devices
3. Test edge cases and error scenarios
4. Perform load testing with multiple groups
5. Validate audit logs for group operations

## Support

For issues or questions:
- Check the API documentation at `/api/documentation`
- Review the design document at `.kiro/specs/admin-group-management/design.md`
- Check the requirements at `.kiro/specs/admin-group-management/requirements.md`

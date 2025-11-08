# Admin Group Management - Quick Reference

## Overview

Admin Group Management allows admins to create groups and invite users using unique codes. Users can only join groups within their organization.

## Key Concepts

- **Group Code**: 4-6 digit numeric code (e.g., "123456")
- **Organization Matching**: Users must have the same organization name as admin (case-insensitive)
- **Data Scoping**: Admins see all group member data; users see only their own data

## Quick Start

### For Admins

1. **Register as Admin**
   ```bash
   POST /api/v1/auth/register
   {
     "role": "admin",
     "organization_name": "Acme Corp",
     ...
   }
   ```
   → Automatically creates group with unique code

2. **Get Your Group Code**
   ```bash
   GET /api/v1/admin/group
   ```
   → Returns your group code to share with users

3. **View Group Members**
   ```bash
   GET /api/v1/admin/group/members
   ```

4. **Remove a Member**
   ```bash
   DELETE /api/v1/admin/group/members/{user_id}
   ```

5. **Regenerate Code** (if compromised)
   ```bash
   POST /api/v1/admin/group/regenerate
   ```

### For Regular Users

1. **Register with Group Code**
   ```bash
   POST /api/v1/auth/register
   {
     "role": "user",
     "organization_name": "Acme Corp",
     "group_code": "123456",
     ...
   }
   ```
   → Automatically joins admin's group

2. **Join Group Later**
   ```bash
   POST /api/v1/user/join-group
   {
     "group_code": "123456"
   }
   ```

3. **View Your Group Info**
   ```bash
   GET /api/v1/user/group-info
   ```

## Validation Rules

### Group Code Format
- Must be 4-6 digits
- Numeric only
- Unique across all groups

### Organization Matching
- User's organization name must match admin's
- Comparison is case-insensitive
- Department names don't need to match

### Restrictions
- Users can only be in one group at a time
- Admins cannot join other groups
- Group code must exist and be active

## Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "Invalid group code" | Code doesn't exist | Verify code with admin |
| "Organization mismatch" | Different organization | Use same organization name as admin |
| "Already in group" | User already has group | Leave current group first |
| "Admin does not have a group" | Admin registration failed | Contact support |

## API Endpoints Summary

### Admin Endpoints
- `GET /api/v1/admin/group` - Get group info
- `POST /api/v1/admin/group/regenerate` - New code
- `GET /api/v1/admin/group/members` - List members
- `DELETE /api/v1/admin/group/members/{id}` - Remove member

### User Endpoints
- `POST /api/v1/user/join-group` - Join with code
- `GET /api/v1/user/group-info` - View group info

## Data Scoping

### What Admins See
- All expenses from group members
- All transfers from group members
- All incoming funds from group members
- All fund box data from group members

### What Users See
- Only their own expenses
- Only their own transfers
- Only their own incoming funds
- Only their own fund box data

## Best Practices

### For Admins
✅ Share group code securely (email, chat)
✅ Regenerate code if shared publicly
✅ Review members regularly
✅ Use consistent organization name

### For Users
✅ Verify organization name matches admin's
✅ Get code directly from your admin
✅ Contact admin if join fails
✅ Check group info after joining

## Example Workflow

1. **Admin registers** → Gets group code "123456"
2. **Admin shares code** with team members
3. **User 1 registers** with code "123456" → Joins group
4. **User 2 registers** with code "123456" → Joins group
5. **Admin views members** → Sees User 1 and User 2
6. **Admin views expenses** → Sees all expenses from User 1 and User 2
7. **User 1 views expenses** → Sees only their own expenses

## Documentation Links

- **Full Documentation**: `docs/ADMIN_GROUP_MANAGEMENT.md`
- **API Reference**: `API_ENDPOINTS_REFERENCE.md`
- **OpenAPI Docs**: `http://localhost:8000/api/documentation`

## Support

For issues or questions:
1. Check full documentation
2. Review API error messages
3. Verify organization names match
4. Contact system administrator

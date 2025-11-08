# PocketBase Collection Rules Configuration

This document provides the security rules for PocketBase collections used in the dual-version finance application.

## Collections Overview

1. **expenses** - Stores expense records synced from user versions
2. **invoice_files** - Stores invoice image files uploaded by users
3. **users** - Built-in PocketBase users collection (extended with role field)

## Collection Schema

### 1. Expenses Collection

**Collection Name:** `expenses`

**Fields:**
- `user_id` (Number, Required) - ID of the user who created the expense
- `username` (Text, Required) - Username of the creator
- `user_email` (Email, Required) - Email of the creator
- `local_expense_id` (Number, Required) - Local database ID from user's device
- `description` (Text, Required) - Expense description
- `price_usd` (Number, Optional) - Price in USD
- `price_syp` (Number, Optional) - Price in SYP
- `price_try` (Number, Optional) - Price in TRY
- `invoice_status` (Number, Required) - Invoice status enum value
- `invoice_file_id` (Text, Optional) - Reference to invoice_files record
- `expense_date` (Date, Required) - Date of the expense
- `synced_at` (Date, Required) - Timestamp when synced to cloud

**API Rules:**

**List/Search Rule:**
```javascript
// Users can only see their own expenses
// Admins can see all expenses
@request.auth.id != "" && 
(@request.auth.role = "admin" || user_id = @request.auth.id)
```

**View Rule:**
```javascript
// Users can only view their own expenses
// Admins can view all expenses
@request.auth.id != "" && 
(@request.auth.role = "admin" || user_id = @request.auth.id)
```

**Create Rule:**
```javascript
// Users can only create expenses for themselves
// Must be authenticated
@request.auth.id != "" && 
@request.data.user_id = @request.auth.id
```

**Update Rule:**
```javascript
// No updates allowed - expenses are immutable once synced
@request.auth.id = ""
```

**Delete Rule:**
```javascript
// No deletes allowed - expenses are immutable for audit trail
@request.auth.id = ""
```

---

### 2. Invoice Files Collection

**Collection Name:** `invoice_files`

**Fields:**
- `user_id` (Number, Required) - ID of the user who uploaded the file
- `expense_id` (Number, Required) - Local expense ID this file belongs to
- `file` (File, Required) - The actual invoice image file

**API Rules:**

**List/Search Rule:**
```javascript
// Users can only see their own files
// Admins can see all files
@request.auth.id != "" && 
(@request.auth.role = "admin" || user_id = @request.auth.id)
```

**View Rule:**
```javascript
// Users can only view their own files
// Admins can view all files
@request.auth.id != "" && 
(@request.auth.role = "admin" || user_id = @request.auth.id)
```

**Create Rule:**
```javascript
// Users can only upload files for themselves
// Must be authenticated
@request.auth.id != "" && 
@request.data.user_id = @request.auth.id
```

**Update Rule:**
```javascript
// No updates allowed - files are immutable
@request.auth.id = ""
```

**Delete Rule:**
```javascript
// Only admins can delete files (for cleanup)
@request.auth.id != "" && 
@request.auth.role = "admin"
```

---

### 3. Users Collection (Extended)

**Collection Name:** `users` (built-in PocketBase collection)

**Additional Fields:**
- `role` (Select, Required, Default: "user") - User role: "user" or "admin"

**API Rules:**

**List/Search Rule:**
```javascript
// Only admins can list users
@request.auth.id != "" && 
@request.auth.role = "admin"
```

**View Rule:**
```javascript
// Users can view their own profile
// Admins can view all profiles
@request.auth.id != "" && 
(@request.auth.role = "admin" || id = @request.auth.id)
```

**Create Rule:**
```javascript
// Public registration allowed
// New users default to "user" role
@request.data.role = "user"
```

**Update Rule:**
```javascript
// Users can update their own profile (except role)
// Admins can update any profile
@request.auth.id != "" && 
(
  (id = @request.auth.id && @request.data.role = role) || 
  @request.auth.role = "admin"
)
```

**Delete Rule:**
```javascript
// Only admins can delete users
@request.auth.id != "" && 
@request.auth.role = "admin"
```

---

## Setup Instructions

### Step 1: Create Collections

1. Open PocketBase Admin UI (http://localhost:8090/_/)
2. Navigate to "Collections"
3. Create the following collections:

#### Create "expenses" Collection:
- Click "New Collection"
- Name: `expenses`
- Type: Base
- Add fields as specified above
- Apply API rules as specified

#### Create "invoice_files" Collection:
- Click "New Collection"
- Name: `invoice_files`
- Type: Base
- Add fields as specified above
- Apply API rules as specified

### Step 2: Extend Users Collection

1. Navigate to "Collections" → "users"
2. Click "Edit"
3. Add new field:
   - Name: `role`
   - Type: Select
   - Options: `user`, `admin`
   - Default: `user`
   - Required: Yes
4. Update API rules as specified above

### Step 3: Create Admin User

1. Navigate to "Collections" → "users"
2. Click "New Record"
3. Fill in:
   - Email: admin@example.com
   - Password: (secure password)
   - Role: admin
4. Save

### Step 4: Test Rules

#### Test User Access:
1. Create a test user with role "user"
2. Authenticate as that user
3. Try to:
   - Create an expense (should succeed)
   - View own expenses (should succeed)
   - View other users' expenses (should fail)
   - Update an expense (should fail)
   - Delete an expense (should fail)

#### Test Admin Access:
1. Authenticate as admin user
2. Try to:
   - View all expenses (should succeed)
   - View all invoice files (should succeed)
   - List all users (should succeed)
   - Delete files (should succeed)

---

## Security Considerations

### 1. Authentication Required
All API operations require authentication (`@request.auth.id != ""`). This prevents anonymous access to sensitive financial data.

### 2. User Data Isolation
Users can only access their own data through the `user_id` check. This ensures privacy and prevents data leakage between users.

### 3. Admin Privileges
Admins have read access to all data but cannot modify synced expenses (immutability for audit trail).

### 4. Immutable Records
Once synced, expenses and files cannot be updated or deleted (except files by admin). This maintains data integrity and audit trail.

### 5. Role-Based Access Control
The `role` field in users collection determines access levels:
- `user`: Limited to own data
- `admin`: Full read access, limited write access

### 6. Prevent Privilege Escalation
Users cannot change their own role through the update rule. Only admins can modify user roles.

---

## Troubleshooting

### Issue: "Failed to create record"
- Check that user is authenticated
- Verify `user_id` matches authenticated user ID
- Ensure all required fields are provided

### Issue: "Failed to fetch records"
- Verify user is authenticated
- Check that user has permission (own data or admin role)
- Ensure collection rules are properly configured

### Issue: "Unauthorized"
- Verify authentication token is valid
- Check user role in database
- Ensure API rules match the documentation

---

## Migration Notes

If you have existing PocketBase collections:

1. **Backup your data** before making changes
2. Add the `role` field to users collection
3. Set existing users to appropriate roles
4. Update API rules for all collections
5. Test thoroughly before deploying to production

---

## Additional Resources

- [PocketBase Rules Documentation](https://pocketbase.io/docs/manage-collections/#rules-filters)
- [PocketBase API Rules Syntax](https://pocketbase.io/docs/api-rules-and-filters/)
- [PocketBase Authentication](https://pocketbase.io/docs/authentication/)

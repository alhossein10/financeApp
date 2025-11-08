# PocketBase Collections Setup Guide

This guide walks you through setting up the required collections and security rules for the dual-version finance application.

## Prerequisites

- PocketBase installed and running locally
- Access to PocketBase Admin UI (http://localhost:8090/_/)
- Admin account created in PocketBase

## Quick Setup Steps

### 1. Start PocketBase

```bash
cd pocketbase-backend-files
./pocketbase serve
```

Access the admin UI at: http://localhost:8090/_/

### 2. Create Collections

#### A. Create "expenses" Collection

1. Navigate to **Collections** in the sidebar
2. Click **New Collection**
3. Select **Base Collection**
4. Set **Name**: `expenses`
5. Click **New field** and add the following fields:

| Field Name | Type | Required | Options |
|------------|------|----------|---------|
| user_id | Number | Yes | Min: 1 |
| username | Text | Yes | Max: 255 |
| user_email | Email | Yes | - |
| local_expense_id | Number | Yes | Min: 1 |
| description | Text | Yes | Max: 1000 |
| price_usd | Number | No | Min: 0 |
| price_syp | Number | No | Min: 0 |
| price_try | Number | No | Min: 0 |
| invoice_status | Number | Yes | Min: 0, Max: 10 |
| invoice_file_id | Text | No | Max: 255 |
| expense_date | Date | Yes | - |
| synced_at | Date | Yes | - |

6. Click **API Rules** tab
7. Set the following rules:

**List/Search Rule:**
```
@request.auth.id != "" && (@request.auth.role = "admin" || user_id = @request.auth.id)
```

**View Rule:**
```
@request.auth.id != "" && (@request.auth.role = "admin" || user_id = @request.auth.id)
```

**Create Rule:**
```
@request.auth.id != "" && @request.data.user_id = @request.auth.id
```

**Update Rule:**
```
(leave empty - no updates allowed)
```

**Delete Rule:**
```
(leave empty - no deletes allowed)
```

8. Click **Save**

#### B. Create "invoice_files" Collection

1. Click **New Collection**
2. Select **Base Collection**
3. Set **Name**: `invoice_files`
4. Add the following fields:

| Field Name | Type | Required | Options |
|------------|------|----------|---------|
| user_id | Number | Yes | Min: 1 |
| expense_id | Number | Yes | Min: 1 |
| file | File | Yes | Max size: 10MB, Types: image/jpeg, image/png, image/jpg, image/heic, image/webp |

5. Click **API Rules** tab
6. Set the following rules:

**List/Search Rule:**
```
@request.auth.id != "" && (@request.auth.role = "admin" || user_id = @request.auth.id)
```

**View Rule:**
```
@request.auth.id != "" && (@request.auth.role = "admin" || user_id = @request.auth.id)
```

**Create Rule:**
```
@request.auth.id != "" && @request.data.user_id = @request.auth.id
```

**Update Rule:**
```
(leave empty - no updates allowed)
```

**Delete Rule:**
```
@request.auth.id != "" && @request.auth.role = "admin"
```

7. Click **Save**

### 3. Extend Users Collection

1. Navigate to **Collections** → **users** (built-in collection)
2. Click **Edit** (pencil icon)
3. Click **New field**
4. Add the following field:

| Field Name | Type | Required | Options |
|------------|------|----------|---------|
| role | Select | Yes | Options: "user", "admin" (Default: "user") |

5. Click **API Rules** tab
6. Update the rules:

**List/Search Rule:**
```
@request.auth.id != "" && @request.auth.role = "admin"
```

**View Rule:**
```
@request.auth.id != "" && (@request.auth.role = "admin" || id = @request.auth.id)
```

**Create Rule:**
```
@request.data.role = "user"
```

**Update Rule:**
```
@request.auth.id != "" && ((id = @request.auth.id && @request.data.role = role) || @request.auth.role = "admin")
```

**Delete Rule:**
```
@request.auth.id != "" && @request.auth.role = "admin"
```

7. Click **Save**

### 4. Create Admin User

1. Navigate to **Collections** → **users**
2. Click **New Record**
3. Fill in the form:
   - **Email**: admin@example.com (or your preferred email)
   - **Password**: (choose a secure password)
   - **Password Confirm**: (repeat password)
   - **role**: Select "admin" from dropdown
4. Click **Create**

### 5. Create Test User

1. Click **New Record** again
2. Fill in the form:
   - **Email**: testuser@example.com
   - **Password**: testpass123
   - **Password Confirm**: testpass123
   - **role**: Select "user" from dropdown
3. Click **Create**

## Testing the Setup

### Test 1: User Can Create Expense

1. Open your API client (Postman, Insomnia, or curl)
2. Authenticate as test user:

```bash
curl -X POST http://localhost:8090/api/collections/users/auth-with-password \
  -H "Content-Type: application/json" \
  -d '{
    "identity": "testuser@example.com",
    "password": "testpass123"
  }'
```

3. Save the returned `token`
4. Create an expense:

```bash
curl -X POST http://localhost:8090/api/collections/expenses/records \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "user_id": 1,
    "username": "testuser",
    "user_email": "testuser@example.com",
    "local_expense_id": 1,
    "description": "Test expense",
    "price_usd": 100.50,
    "invoice_status": 0,
    "expense_date": "2024-01-15",
    "synced_at": "2024-01-15T10:00:00Z"
  }'
```

**Expected**: Success (201 Created)

### Test 2: User Cannot View Other Users' Expenses

1. Create another expense with different user_id (should fail)
2. Try to list all expenses (should only see own expenses)

### Test 3: Admin Can View All Expenses

1. Authenticate as admin:

```bash
curl -X POST http://localhost:8090/api/collections/users/auth-with-password \
  -H "Content-Type: application/json" \
  -d '{
    "identity": "admin@example.com",
    "password": "YOUR_ADMIN_PASSWORD"
  }'
```

2. List all expenses:

```bash
curl -X GET http://localhost:8090/api/collections/expenses/records \
  -H "Authorization: Bearer ADMIN_TOKEN_HERE"
```

**Expected**: See all expenses from all users

### Test 4: Expenses Are Immutable

1. Try to update an expense (should fail):

```bash
curl -X PATCH http://localhost:8090/api/collections/expenses/records/RECORD_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "description": "Updated description"
  }'
```

**Expected**: Forbidden (403)

### Test 5: Users Cannot Delete Expenses

1. Try to delete an expense (should fail):

```bash
curl -X DELETE http://localhost:8090/api/collections/expenses/records/RECORD_ID \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected**: Forbidden (403)

## Verification Checklist

- [ ] expenses collection created with all fields
- [ ] invoice_files collection created with all fields
- [ ] users collection extended with role field
- [ ] All API rules configured correctly
- [ ] Admin user created with role="admin"
- [ ] Test user created with role="user"
- [ ] User can create own expenses
- [ ] User can only view own expenses
- [ ] Admin can view all expenses
- [ ] Expenses cannot be updated
- [ ] Expenses cannot be deleted by users
- [ ] Files can only be deleted by admins

## Troubleshooting

### Issue: "Failed to create collection"
- Ensure you're logged in as admin in PocketBase UI
- Check that collection name doesn't already exist
- Verify all required fields are properly configured

### Issue: "Rule validation failed"
- Double-check the rule syntax (no typos)
- Ensure you're using the correct field names
- Test rules with simple cases first

### Issue: "Cannot create record"
- Verify authentication token is valid
- Check that all required fields are provided
- Ensure user_id matches authenticated user

### Issue: "Role field not working"
- Make sure you saved the users collection after adding role field
- Verify role field has "user" and "admin" as options
- Check that default value is set to "user"

## Next Steps

After completing this setup:

1. Update your Flutter app's PocketBase configuration
2. Test the sync functionality from the app
3. Monitor PocketBase logs for any issues
4. Consider deploying PocketBase to production (Render, etc.)

## Production Deployment Notes

When deploying to production:

1. **Change default passwords** for all users
2. **Enable HTTPS** for secure communication
3. **Set up backups** for PocketBase data
4. **Configure CORS** if needed for web clients
5. **Monitor logs** for unauthorized access attempts
6. **Set up rate limiting** to prevent abuse
7. **Use environment variables** for sensitive configuration

## Additional Resources

- [PocketBase Documentation](https://pocketbase.io/docs/)
- [PocketBase API Rules](https://pocketbase.io/docs/api-rules-and-filters/)
- [PocketBase Collections](https://pocketbase.io/docs/collections/)

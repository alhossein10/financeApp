# PocketBase Fresh Start Guide

## Problem
The schema import is failing because there are existing collections in your PocketBase database that conflict with the new schema.

## Solution: Start Fresh

### Option 1: Delete PocketBase Data (Recommended)

1. **Stop PocketBase** (Close the Command Prompt window or press Ctrl+C)

2. **Delete the data folder**:
   ```cmd
   cd C:\pocketbase
   rmdir /s /q pb_data
   ```

3. **Start PocketBase again**:
   ```cmd
   pocketbase serve --http="0.0.0.0:8090"
   ```

4. **Setup admin account** (it will ask you to create one again):
   - Open browser: `http://localhost:8090/_/`
   - Create new admin account

5. **Import schema**:
   - Go to Settings → Import collections
   - Click "Load from JSON file"
   - Select `pocketbase-backend-files/pb_schema.json`
   - Click "Confirm and import"
   - Should now work without errors!

### Option 2: Use a New PocketBase Folder

1. **Create new folder**:
   ```cmd
   mkdir C:\pocketbase-new
   ```

2. **Copy PocketBase executable**:
   ```cmd
   copy C:\pocketbase\pocketbase.exe C:\pocketbase-new\
   ```

3. **Start PocketBase from new folder**:
   ```cmd
   cd C:\pocketbase-new
   pocketbase serve --http="0.0.0.0:8090"
   ```

4. **Setup and import** (same as Option 1, steps 4-5)

## After Fresh Start

### 1. Verify Collections Created

In PocketBase Admin UI, you should see:
- ✅ `expenses` collection
- ✅ `invoice_files` collection
- ✅ `users` collection (created automatically by PocketBase)

### 2. Check Collection Rules

Click on each collection and verify the API Rules tab shows rules (not empty).

### 3. Test API

```cmd
curl http://localhost:8090/api/health
```

Should return: `{"code":200,"message":"API is healthy"}`

### 4. Update App and Test

Your app should now be able to:
- Register new users
- Create expenses
- Upload invoice images
- Sync data to PocketBase

## Understanding the Collections

### expenses Collection
Stores expense records synced from user devices:
- `user_id` - Local user ID from app
- `username` - User's name
- `user_email` - User's email
- `local_expense_id` - Expense ID from local database
- `description` - Expense description
- `price_usd`, `price_syp`, `price_try` - Prices in different currencies
- `invoice_status` - Whether invoice is available
- `invoice_file_id` - Reference to invoice image
- `expense_date` - When expense occurred
- `synced_at` - When synced to cloud

### invoice_files Collection
Stores invoice images:
- `user_id` - Local user ID
- `expense_id` - Local expense ID
- `file` - The actual image file (max 10MB)

### users Collection (Auto-created)
PocketBase's built-in user authentication:
- `email` - User email
- `username` - Username
- `password` - Hashed password
- `role` - Custom field for admin/user role

## Troubleshooting

### Still Getting Import Error?

1. **Make sure PocketBase is stopped** before deleting pb_data
2. **Check for multiple PocketBase instances** running:
   ```cmd
   netstat -ano | findstr :8090
   ```
3. **Kill all PocketBase processes**:
   ```cmd
   taskkill /F /IM pocketbase.exe
   ```
4. **Try again** from step 1

### Collections Not Showing?

- Refresh the browser
- Check PocketBase logs in Command Prompt
- Verify JSON file is valid (should be valid from project)

### Import Shows "Detected Changes"?

This is normal! It shows:
- **Deleted**: Old collections being removed
- **Added**: New collections being created

Click **"Confirm and import"** to proceed.

If it says "Replace with original ids", click that button.

## Quick Commands

**Stop PocketBase**:
```cmd
# Press Ctrl+C in the Command Prompt window
```

**Delete Data**:
```cmd
cd C:\pocketbase
rmdir /s /q pb_data
```

**Start Fresh**:
```cmd
cd C:\pocketbase
pocketbase serve --http="0.0.0.0:8090"
```

**Check if Running**:
```cmd
netstat -ano | findstr :8090
```

## Next Steps

After successful import:

1. ✅ Collections are created
2. ✅ Rules are configured
3. ✅ Ready to connect app
4. ✅ Test registration and sync

Continue with **SETUP_LOCAL_POCKETBASE_SERVER.md** Step 7 (Configure App).

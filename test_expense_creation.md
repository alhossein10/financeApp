# Test Expense Creation

## Quick Test Steps

### 1. Run the App
```bash
# For admin flavor
flutter run --flavor admin

# For user flavor
flutter run --flavor user
```

### 2. Create an Expense
1. Log in
2. Navigate to Expenses page
3. Click "Add Expense" button
4. Fill in the form:
   - Description: "Test Expense"
   - Amount: 100 (in any currency)
   - Date: Today
5. Click "Save"

### 3. Check Console Logs

Look for these specific log messages in order:

#### Step 1: Bloc receives request
```
[ExpenseBloc] Creating expense: Test Expense
```

#### Step 2: Repository processes
```
[ExpenseRepository] Creating expense for user X
[ExpenseRepository] Description: Test Expense
[ExpenseRepository] Online status: true/false
```

#### Step 3: API call (if online)
```
[ExpenseRepository] Attempting to create via API...
[ExpenseRepository] Request body: {...}
[ExpenseApiDataSource] Creating expense...
[ExpenseApiDataSource]   Description: Test Expense
[ExpenseApiDataSource]   USD: X, SYP: Y, TRY: Z
```

#### Step 4: Validation
```
[ExpenseApiDataSource] ✅ Validation passed
```

#### Step 5: API Response
```
[ApiClient] Request: POST http://192.168.137.1:8000/api/v1/expenses
[ExpenseApiDataSource] Response status: 201
[ExpenseApiDataSource] Response data: {...}
```

#### Step 6: Success or Failure

**If Success:**
```
[ExpenseApiDataSource] ✅ Expense created successfully
[ExpenseRepository] ✅ API creation successful! ID: X
[ExpenseBloc] ✅ Expense created successfully!
```

**If Failure:**
```
[ExpenseApiDataSource] ❌ ApiException: [error message]
[ExpenseRepository] ⚠️ API failed: [error message]
[ExpenseRepository] Status code: XXX
```

### 4. Common Error Scenarios

#### Error 1: 401 Unauthorized
```
[ExpenseApiDataSource] ❌ ApiException: Unauthorized
[ExpenseRepository] Status code: 401
```
**Solution:** Token expired. Log out and log in again.

#### Error 2: 422 Validation Error
```
[ExpenseApiDataSource] ❌ ApiException: Validation failed
[ExpenseRepository] Status code: 422
[ExpenseRepository] Validation errors: {...}
```
**Solution:** Check which fields are missing or invalid in the validation errors.

#### Error 3: 500 Server Error
```
[ExpenseApiDataSource] ❌ ApiException: Server error
[ExpenseRepository] Status code: 500
```
**Solution:** Backend issue. Check Laravel logs.

#### Error 4: Network Error
```
[ExpenseRepository] ⚠️ Unexpected error: SocketException
```
**Solution:** Check network connection and API URL.

#### Error 5: Offline
```
[ExpenseRepository] Online status: false
[ExpenseRepository] Offline - queuing for later sync
```
**Solution:** This is normal. Expense will sync when online.

### 5. Check Database

After successful creation, verify in your Laravel backend:

```sql
SELECT * FROM expenses ORDER BY id DESC LIMIT 1;
```

Should show the newly created expense.

### 6. Check App UI

After creation:
- Expense should appear in the list
- Should show sync status (synced/pending/failed)
- Should be able to view details

## Troubleshooting Checklist

- [ ] Is the API server running?
- [ ] Is the API URL correct in flavor config?
- [ ] Is the device/emulator connected to the network?
- [ ] Is the auth token valid? (Try logging out and in)
- [ ] Are all required fields filled in the form?
- [ ] Check Laravel logs for backend errors
- [ ] Check Flutter console for detailed error messages

## Report Template

When reporting the issue, include:

```
**Environment:**
- Flavor: admin/user
- Device: Android/iOS/Emulator
- Network: Connected/Offline

**Steps Taken:**
1. Logged in as [role]
2. Navigated to Expenses
3. Filled form with: [details]
4. Clicked Save

**Console Logs:**
[Paste relevant logs here]

**Result:**
- [ ] Expense appeared in list
- [ ] Expense NOT in list
- [ ] Error message shown: [message]
- [ ] App crashed

**Backend Check:**
- [ ] Expense in database
- [ ] Expense NOT in database
- [ ] Laravel logs show: [error]
```

# Postman Collection Quick Start Guide

## SuperAdmin & Multi-Currency Collection

### Import Collection

1. Open Postman
2. Click **Import** button
3. Select `postman/SuperAdmin_MultiCurrency_Collection.json`
4. Collection will be imported with all endpoints organized by feature

---

## Environment Variables

The collection includes these variables:

- `base_url` - API base URL (default: `http://127.0.0.1:8000/api/v1`)
- `super_admin_token` - SuperAdmin authentication token
- `admin_token` - Admin authentication token
- `user_token` - User authentication token
- `user_id` - User ID
- `admin_id` - Admin ID
- `super_admin_id` - SuperAdmin ID
- `expense_id` - Expense ID
- `transfer_id` - Transfer ID
- `exchange_id` - Exchange ID
- `incoming_id` - Incoming ID
- `admin_group_id` - Admin Group ID
- `super_admin_group_code` - SuperAdmin Group Code

### Auto-Population

Many endpoints automatically populate variables:
- Registration endpoints set tokens and IDs
- Login endpoint sets token based on user role
- Create endpoints set respective IDs

---

## Quick Testing Flow

### 1. Create SuperAdmin
- **Endpoint**: `Register SuperAdmin`
- **What it does**: Creates SuperAdmin user and SuperAdmin group
- **Auto-sets**: `super_admin_token`, `super_admin_id`, `super_admin_group_code`

### 2. Create Admin (with SuperAdmin code)
- **Endpoint**: `Register Admin with SuperAdmin Group Code`
- **What it does**: Creates Admin user and joins to SuperAdmin group
- **Auto-sets**: `admin_token`, `admin_id`, `admin_group_id`
- **Note**: Use `super_admin_group_code` from step 1

### 3. Create User
- **Endpoint**: `Register User`
- **What it does**: Creates regular user
- **Auto-sets**: `user_token`, `user_id`

### 4. SuperAdmin Transfer to Admin
- **Endpoint**: `SuperAdmin Transfer to Admin`
- **What it does**: Transfers funds from SuperAdmin to Admin
- **Auto-sets**: `transfer_id`
- **Balance**: Admin's USD balance increases automatically

### 5. Admin Transfer to User
- **Endpoint**: `Admin Transfer to User`
- **What it does**: Transfers funds from Admin to User
- **Auto-sets**: `transfer_id`
- **Balance**: User's USD balance increases automatically

### 6. Check Balance
- **Endpoint**: `Get All Balances`
- **What it does**: Shows USD, SYP, and TRY balances
- **Use**: Any authenticated user can check their balance

### 7. Create Exchange (USD to SYP)
- **Endpoint**: `Create Exchange to SYP`
- **What it does**: Exchanges USD from balance box to SYP
- **Auto-sets**: `exchange_id`
- **Balance**: USD decreases, SYP increases

### 8. Create Exchange (USD to TRY)
- **Endpoint**: `Create Exchange to TRY`
- **What it does**: Exchanges USD from balance box to TRY
- **Auto-sets**: `exchange_id`
- **Balance**: USD decreases, TRY increases

### 9. Create Expense
- **Endpoint**: `Create Expense in USD` (or SYP/TRY)
- **What it does**: Creates expense and decreases balance
- **Auto-sets**: `expense_id`
- **Balance**: Decreases balance for expense currency

### 10. View SuperAdmin Analytics
- **Endpoint**: `Get Analytics`
- **What it does**: Shows aggregated analytics for all admin groups
- **Filters**: Use `period=15days`, `period=month`, or `period=all`

---

## Key Features Tested

### Multi-Currency Balance Box
- ✅ Get all balances: `GET /fund-box`
- ✅ Get specific currency: `GET /fund-box?currency=USD|SYP|TRY`

### Balance-Based Exchanges
- ✅ Exchange to SYP: `POST /exchanges` (target_currency: "SYP")
- ✅ Exchange to TRY: `POST /exchanges` (target_currency: "TRY")
- ✅ Transfer ID is optional (for audit trail only)

### Exchange History Filtering
- ✅ All exchanges: `GET /exchanges`
- ✅ SYP only: `GET /exchanges?currency=SYP`
- ✅ TRY only: `GET /exchanges?currency=TRY`

### SuperAdmin Features
- ✅ Analytics: `GET /super-admin/analytics?period=all`
- ✅ Transfer to Admin: `POST /transfers` (from SuperAdmin)

### Admin Restrictions
- ✅ Admin cannot create incoming: `POST /incoming` (will fail for admins)
- ✅ Admin can create exchanges: `POST /exchanges` (works for admins)

---

## Common Request Bodies

### Create Exchange (SYP)
```json
{
  "target_currency": "SYP",
  "amount_usd": 100.00,
  "exchange_rate": 11600.00,
  "exchange_date": "2025-11-05",
  "notes": "Exchange for daily expenses"
}
```

### Create Exchange (TRY)
```json
{
  "target_currency": "TRY",
  "amount_usd": 50.00,
  "exchange_rate": 32.50,
  "exchange_date": "2025-11-05",
  "notes": "Exchange for Turkish expenses"
}
```

### Create Expense (USD)
```json
{
  "description": "Office supplies",
  "price_usd": 50.00,
  "expense_date": "2025-11-05"
}
```

### Create Expense (SYP)
```json
{
  "description": "Local expenses",
  "price_syp": 10000.00,
  "expense_date": "2025-11-05"
}
```

### Create Expense (TRY)
```json
{
  "description": "Turkish expenses",
  "price_try": 1500.00,
  "expense_date": "2025-11-05"
}
```

### SuperAdmin Transfer to Admin
```json
{
  "recipient_user_id": 2,
  "recipient_name": "Admin User",
  "amount_usd": 1000.00,
  "transfer_date": "2025-11-05",
  "notes": "Monthly funding for admin"
}
```

---

## Error Handling

### Common Errors

1. **Insufficient Balance**
   - **Error**: "Insufficient USD balance. Available: X USD"
   - **Solution**: Check balance before creating exchange/expense

2. **Admin Cannot Create Incoming**
   - **Error**: "Admins cannot create incoming records"
   - **Solution**: Admins receive funds from SuperAdmin transfers only

3. **Invalid Currency**
   - **Error**: "Invalid target currency. Must be SYP or TRY"
   - **Solution**: Use "SYP" or "TRY" for target_currency

4. **Unauthorized Access**
   - **Error**: "Unauthorized. SuperAdmin access required"
   - **Solution**: Use SuperAdmin token for SuperAdmin endpoints

---

## Performance Notes

### Pagination Limits
- **Maximum `per_page`: 100 items**
- Requests for more than 100 items will be automatically limited to 100
- Default: 15 items per page
- Example: `GET /expenses?per_page=100` (maximum)

### Response Compression
- JSON responses over 1KB are automatically compressed with gzip
- Postman and most HTTP clients handle decompression automatically
- Improves response times for large datasets

## Tips

1. **Token Management**: Use separate tokens for different roles to test access control
2. **Balance Tracking**: Always check balance before creating exchanges/expenses
3. **Currency Filtering**: Use currency parameter to filter exchange history
4. **Period Filtering**: Use period parameter for SuperAdmin analytics (15days, month, all)
5. **Auto-Variables**: Let Postman auto-populate variables from responses
6. **Pagination**: Use `per_page` parameter (max 100) to control response size

---

## Collection Structure

```
1. Authentication
   - Register SuperAdmin
   - Register Admin with SuperAdmin Group Code
   - Register Admin (without SuperAdmin code)
   - Register User
   - Login
   - Get Current User
   - Logout

2. SuperAdmin Endpoints
   - Get Analytics (all/15days/month)

3. Balance Box (Multi-Currency)
   - Get All Balances
   - Get USD/SYP/TRY Balance
   - Update Balance (Admin only)

4. Transfers
   - SuperAdmin Transfer to Admin
   - Admin Transfer to User
   - List/Get/Update/Delete Transfers

5. Exchanges (Balance-Based)
   - Create Exchange to SYP/TRY
   - List Exchanges (with currency filter)
   - Get Exchange by ID

6. Expenses
   - Create Expense (USD/SYP/TRY)
   - List/Get/Update/Delete Expenses

7. Incoming
   - Create Incoming (User/SuperAdmin only)
   - List/Get/Update/Delete Incoming

8. Admin Groups
   - Get Admin Group Info
   - Regenerate Group Code
   - Get/Remove Group Members
   - Join Group (User)
```

---

For complete API documentation, see `FRONTEND_INTEGRATION_GUIDE.md`.


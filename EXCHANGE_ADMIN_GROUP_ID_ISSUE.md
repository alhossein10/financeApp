# Exchange admin_group_id Issue

## Problem

When an admin creates an exchange:
1. The exchange is created successfully in the database
2. **BUT**: The exchange does not appear in:
   - The app's exchange history list
   - The API endpoint `/exchanges` response

## Root Cause

The `admin_group_id` field in the exchanges table is **NULL** for newly created exchanges.

The backend filters exchanges by `admin_group_id`:
- For Admin: Should show exchanges where `admin_group_id` = Admin's `admin_group_id`
- For Regular Users: Should show exchanges where `user_id` = User's ID AND `admin_group_id` = User's `admin_group_id`

When `admin_group_id` is NULL, these filters exclude the exchange from the results.

## Expected Behavior

When creating an exchange:
1. Backend should automatically set `admin_group_id` from the authenticated user's `admin_group_id`
2. This ensures:
   - Exchange appears in Admin's exchange list (filtered by `admin_group_id`)
   - Exchange appears in User's exchange list (filtered by `user_id` AND `admin_group_id`)

## Database Evidence

From the database query result:
```sql
SELECT * FROM exchanges;
```

The exchange record shows:
- `id`: 1
- `user_id`: 2
- `admin_group_id`: **NULL** ❌ (This is the problem)
- `transfer_id`: NULL
- `amount_usd`: 50.00
- `target_currency`: SYP
- `amount_syp`: 592500.00

## Backend Fix Required

The backend exchange creation endpoint needs to automatically set `admin_group_id` similar to how transfer creation was fixed.

### Backend Implementation Needed:

In `ExchangeService::createExchange()` or `ExchangeController::store()`:

```php
// Determine admin_group_id for the exchange
// Priority: 1. Explicitly provided in request, 2. From user's admin_group_id
$adminGroupId = $data['admin_group_id'] ?? null;

// If not provided, use authenticated user's admin_group_id
if (!$adminGroupId) {
    $adminGroupId = $user->admin_group_id;
}

// Use $adminGroupId when creating the exchange
$exchange = Exchange::create([
    'user_id' => $user->id,
    'admin_group_id' => $adminGroupId, // Set from user's admin_group_id
    'transfer_id' => $data['transfer_id'] ?? null,
    'target_currency' => $data['target_currency'],
    'amount_usd' => $data['amount_usd'],
    'exchange_rate' => $data['exchange_rate'],
    'amount_syp' => $data['target_currency'] === 'SYP' ? $calculatedAmount : null,
    'amount_try' => $data['target_currency'] === 'TRY' ? $calculatedAmount : null,
    'exchange_date' => $data['exchange_date'],
    'notes' => $data['notes'] ?? null,
]);
```

### Exchange Filtering Logic

The backend should filter exchanges by `admin_group_id`:

**For Admin users:**
```php
$exchanges = Exchange::where('admin_group_id', $user->admin_group_id)
    ->where('user_id', $user->id) // Optional: if admin should only see their own
    ->get();
```

**For Regular users:**
```php
$exchanges = Exchange::where('admin_group_id', $user->admin_group_id)
    ->where('user_id', $user->id)
    ->get();
```

**For SuperAdmin:**
```php
// SuperAdmin might see all exchanges or exchanges from specific groups
// Depending on requirements
```

## Frontend Status

✅ **Frontend is correct** - It doesn't send `admin_group_id` in the request, which is the right approach. The backend should handle it automatically.

The Flutter app's exchange creation code (`lib/features/exchanges/data/datasources/exchange_api_datasource.dart`):
- Sends only the required fields: `transfer_id`, `target_currency`, `amount_usd`, `exchange_rate`, `exchange_date`, `notes`
- Does NOT send `admin_group_id` (correct - backend should set it)

## Testing

### 1. Test Exchange Creation (After Backend Fix)

1. **Create Exchange as Admin**:
   - Create an exchange with amount and exchange rate
   - Verify exchange is created successfully
   - Verify `admin_group_id` is set correctly in database (NOT NULL)
   - Verify `admin_group_id` matches admin's `admin_group_id`

2. **Check Database**:
   ```sql
   SELECT id, user_id, admin_group_id, amount_usd, target_currency 
   FROM exchanges 
   WHERE user_id = <admin_id> 
   ORDER BY created_at DESC;
   ```
   - Verify `admin_group_id` is NOT NULL
   - Verify `admin_group_id` matches admin's `admin_group_id`

3. **Check API Response**:
   ```
   GET {{base_url}}/exchanges
   ```
   - Verify exchange appears in the response
   - Verify exchange has correct `admin_group_id`

4. **Check App Exchange History**:
   - Open exchange history page in the app
   - Verify exchange appears in the list
   - Verify exchange details are correct

### 2. Test Exchange Filtering

1. **Create Exchange as Admin in Group A**:
   - Verify exchange has `admin_group_id` = Group A's ID
   - Verify exchange appears for Admin in Group A
   - Verify exchange does NOT appear for Admin in Group B

2. **Create Exchange as Regular User in Group A**:
   - Verify exchange has `admin_group_id` = Group A's ID
   - Verify exchange appears for User in Group A
   - Verify exchange appears for Admin in Group A (if admin should see all exchanges in their group)
   - Verify exchange does NOT appear for User in Group B

## Temporary Workaround

If you need to fix existing exchanges in the database, you can run this SQL:

```sql
-- Update exchanges with NULL admin_group_id to match the user's admin_group_id
UPDATE exchanges e
INNER JOIN users u ON e.user_id = u.id
SET e.admin_group_id = u.admin_group_id
WHERE e.admin_group_id IS NULL AND u.admin_group_id IS NOT NULL;
```

**Warning**: Only run this if you're sure the user's `admin_group_id` is correct and the exchange should belong to that group.

## Related Issues

- Similar issue was fixed for transfers: See `SUPERADMIN_TRANSFER_ADMIN_GROUP_ID_ISSUE.md`
- The same pattern should be applied to exchanges
- Expenses might have the same issue - should be checked

## Current Status

- ❌ Backend does not set `admin_group_id` when creating exchanges
- ✅ Frontend correctly doesn't send `admin_group_id` (backend should handle it)
- ❌ Exchanges with `admin_group_id = NULL` don't appear in API responses
- ❌ Exchanges don't appear in the app's exchange history

## Next Steps

1. **Backend Team**: Update exchange creation endpoint to automatically set `admin_group_id` from authenticated user's `admin_group_id`
2. **Backend Team**: Verify exchange filtering logic uses `admin_group_id` correctly
3. **Testing**: Test exchange creation and retrieval after backend fix
4. **Database**: Update existing exchanges with NULL `admin_group_id` (if needed)

## Notes

- The exchange creation works (saves to database)
- The issue is purely with exchange visibility/filtering
- Backend should handle `admin_group_id` automatically - frontend sending it explicitly should be optional
- This is similar to the transfer issue that was already fixed


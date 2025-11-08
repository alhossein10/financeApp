# SuperAdmin Transfer admin_group_id Issue

## Problem

When SuperAdmin creates a transfer to an admin:
1. The transfer is created successfully in the database
2. The fundbox balance is updated correctly (shows in admin's fundbox)
3. **BUT**: The transfer does not appear in:
   - SuperAdmin's outgoing transfers list
   - Admin's incoming transfers list

## Root Cause

The `admin_group_id` field in the transfers table is **NULL** for SuperAdmin transfers.

The backend filters transfers by `admin_group_id`:
- For SuperAdmin: Should show transfers where `user_id` = SuperAdmin's ID
- For Admin (incoming): Should show transfers where `recipient_user_id` = Admin's ID AND `admin_group_id` = Admin's `admin_group_id`

When `admin_group_id` is NULL, these filters exclude the transfer from the results.

## Expected Behavior

When SuperAdmin creates a transfer with `recipient_user_id`:
1. Backend should look up the recipient user
2. Get the recipient's `admin_group_id` from the users table
3. Set the transfer's `admin_group_id` to the recipient's `admin_group_id`
4. This ensures:
   - Transfer appears in SuperAdmin's outgoing list (filtered by `user_id`)
   - Transfer appears in Admin's incoming list (filtered by `recipient_user_id` AND `admin_group_id`)

## Frontend Changes Made

### 1. Added `adminGroupId` Support

Added `adminGroupId` field throughout the transfer creation flow:
- `TransferDto`: Added `adminGroupId` field
- `CreateTransferParams`: Added `adminGroupId` parameter
- `CreateTransferEvent`: Added `adminGroupId` field
- `TransferRepository`: Added `adminGroupId` parameter
- `TransferApiDataSource`: Sends `admin_group_id` in request body if present

### 2. Queue Support

Updated offline queue to include `admin_group_id` for queued transfers.

## Backend Fix Implemented ✅

**The backend has been updated to automatically set `admin_group_id` from the recipient's `admin_group_id` when creating transfers.**

### Backend Implementation:

In `TransferService::createTransfer()`:

```php
// Determine admin_group_id for the transfer
// Priority: 1. Explicitly provided in request, 2. From recipient if user is SuperAdmin/null, 3. From user's admin_group_id
$adminGroupId = $data['admin_group_id'] ?? null;
$recipient = null;

// Fetch recipient if recipient_user_id is provided
if (isset($data['recipient_user_id']) && $data['recipient_user_id']) {
    $recipient = User::find($data['recipient_user_id']);
    
    // If admin_group_id is not provided and user is SuperAdmin (or has no admin_group_id), 
    // use recipient's admin_group_id
    if (!$adminGroupId && $recipient && ($user->isSuperAdmin() || !$user->admin_group_id)) {
        // Set admin_group_id from recipient's admin_group_id
        $adminGroupId = $recipient->admin_group_id;
    }
}

// If still not set, use user's admin_group_id
if (!$adminGroupId) {
    $adminGroupId = $user->admin_group_id;
}

// Use $adminGroupId when creating the transfer
```

### Backend Accepts `admin_group_id` in Request (Optional)

The backend now accepts `admin_group_id` in the request body (optional):
1. If provided, backend uses it directly
2. If not provided, backend automatically determines it from recipient's `admin_group_id` (for SuperAdmin) or user's `admin_group_id`
3. Frontend can optionally send `admin_group_id` explicitly, but it's not required as backend handles it automatically

## Transfer Filtering Logic

### SuperAdmin Transfers (Outgoing) ✅
- Filter: `WHERE user_id = ?` (SuperAdmin's user ID)
- Shows all transfers created by SuperAdmin
- Updated in `TransferRepository::getUserTransfers()` to handle SuperAdmin correctly

### Admin Transfers (Incoming) ✅
- Filter: `WHERE recipient_user_id = ? AND admin_group_id = ?` (Admin's user ID and admin_group_id)
- Shows transfers where:
  - Admin is the recipient (`recipient_user_id` matches)
  - Transfer belongs to Admin's group (`admin_group_id` matches Admin's `admin_group_id`)
- Updated in `TransferRepository::getAllTransfers()` and `getUserTransfers()` to show incoming transfers for admins

## Testing

1. **Create Transfer as SuperAdmin**:
   - Select an admin recipient
   - Create transfer with amount
   - Verify transfer appears in SuperAdmin's outgoing list
   - Verify transfer appears in Admin's incoming list
   - Verify `admin_group_id` is set correctly in database

2. **Check Database**:
   ```sql
   SELECT id, user_id, recipient_user_id, admin_group_id, amount_usd 
   FROM transfers 
   WHERE user_id = <superadmin_id> 
   ORDER BY created_at DESC;
   ```
   - Verify `admin_group_id` is NOT NULL
   - Verify `admin_group_id` matches recipient's `admin_group_id`

3. **Check Admin's Incoming List**:
   - Login as the recipient admin
   - Go to incoming transfers page
   - Verify transfer appears in the list
   - Verify transfer amount matches

## Current Status

- ✅ Frontend support for `admin_group_id` added
- ✅ Backend automatically sets `admin_group_id` from recipient's `admin_group_id` when SuperAdmin creates a transfer
- ✅ Transfer filtering handles SuperAdmin transfers correctly
- ✅ SuperAdmin's outgoing transfers are visible in their list
- ✅ Admin's incoming transfers are visible when `admin_group_id` is set correctly

## Backend Changes Made

### 1. TransferService.php
- Updated `createTransfer()` method to automatically determine `admin_group_id`:
  - If `admin_group_id` is provided in request, use it
  - If not provided and user is SuperAdmin (or has no `admin_group_id`) with a recipient, use recipient's `admin_group_id`
  - Otherwise, use user's `admin_group_id`
- Optimized recipient fetching to avoid duplicate database queries
- Enhanced logging to include `admin_group_id` and `recipient_user_id` for debugging

### 2. StoreTransferRequest.php
- Added `admin_group_id` validation rule (optional, nullable, must exist in `admin_groups` table)
- Allows frontend to optionally send `admin_group_id` explicitly

### 3. TransferRepository.php
- Updated `getUserTransfers()` to handle SuperAdmin correctly:
  - SuperAdmin sees transfers they created (outgoing)
  - SuperAdmin also sees incoming transfers (if any)
  - Admins see transfers they created and incoming transfers
  - Regular users see transfers where they are recipient or sender
- Updated `getAllTransfers()` to handle SuperAdmin:
  - SuperAdmin sees all transfers they created
  - SuperAdmin also sees transfers to admins in their superAdmin group
  - Enhanced admin filtering to show incoming transfers

### 4. TransferController.php
- Updated comments to clarify role-based transfer filtering logic
- SuperAdmin and regular users use `getUserTransfers()`
- Admin users use `getAllTransfers()`

## Notes

- The fundbox balance update works correctly (backend is processing the transfer)
- The issue was purely with transfer visibility/filtering
- Backend now handles `admin_group_id` automatically - frontend sending it explicitly is optional
- All changes are backward compatible and don't break existing functionality



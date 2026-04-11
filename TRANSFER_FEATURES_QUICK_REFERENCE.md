# Transfer Features Quick Reference

## Overview

This guide provides quick reference for the newly implemented transfer features that enable SuperAdmin-to-Admin and Admin-to-User fund transfers.

## Features

### 1. SuperAdmin to Admin Transfer

**File:** `lib/features/superadmin/presentation/pages/superadmin_transfer_page.dart`

**Purpose:** Allows SuperAdmin users to transfer USD funds to admin users in their SuperAdmin group.

**Key Features:**
- Select admin recipient from group members
- View admin's current USD balance
- Enter transfer amount
- Select transfer date
- Add optional notes
- Confirmation dialog before transfer

**Usage:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BlocProvider.value(
      value: sl<TransferBloc>(),
      child: const SuperAdminTransferPage(),
    ),
  ),
);
```

### 2. Admin to User Transfer

**File:** `lib/features/admin/presentation/pages/admin_transfer_page.dart`

**Purpose:** Allows Admin users to transfer USD funds to regular users in their admin group.

**Key Features:**
- Select user recipient from group members (filtered to role='user')
- View own balance and user's current balance
- Validate sufficient balance before transfer
- Enter transfer amount
- Select transfer date
- Add optional notes
- Confirmation dialog showing balance after transfer

**Usage:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BlocProvider.value(
      value: sl<TransferBloc>(),
      child: const AdminTransferPage(),
    ),
  ),
);
```

### 3. Transfer List with Filtering

**File:** `lib/features/transfers/presentation/pages/transfer_list_page.dart`

**Purpose:** Display paginated list of transfers with filtering options.

**Key Features:**
- Filter by type: All, Sent, Received
- Filter by date range
- Show recipient name and user ID
- Display transfer amount and date
- Show "Sent" or "Received" indicator
- View detailed transfer information
- Pull-to-refresh
- Pagination support

**Usage:**
```dart
// Show all transfers
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BlocProvider.value(
      value: sl<TransferBloc>(),
      child: const TransferListPage(
        initialType: TransferType.all,
      ),
    ),
  ),
);

// Show only sent transfers
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BlocProvider.value(
      value: sl<TransferBloc>(),
      child: const TransferListPage(
        initialType: TransferType.outgoing,
      ),
    ),
  ),
);

// Show only received transfers
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BlocProvider.value(
      value: sl<TransferBloc>(),
      child: const TransferListPage(
        initialType: TransferType.incoming,
      ),
    ),
  ),
);
```

## Data Flow

### SuperAdmin Transfer Flow

```
1. SuperAdmin opens transfer page
2. Page loads admin members from SuperAdminGroupApiDatasource
3. SuperAdmin selects admin recipient
4. Page loads admin's balance from FundBoxApiDataSource
5. SuperAdmin enters amount, date, and notes
6. SuperAdmin confirms transfer
7. TransferBloc creates transfer with recipientUserId and adminGroupId
8. Backend validates recipient is in SuperAdmin's group
9. Backend increases admin's USD balance
10. Success message shown, page closes
```

### Admin Transfer Flow

```
1. Admin opens transfer page
2. Page loads own balance from FundBoxApiDataSource
3. Page loads group members from AdminGroupApiDataSource (filtered to users)
4. Admin selects user recipient
5. Page loads user's balance from FundBoxApiDataSource
6. Admin enters amount, date, and notes
7. Page validates sufficient balance
8. Admin confirms transfer (sees projected balance)
9. TransferBloc creates transfer with recipientUserId
10. Backend validates recipient is in admin's group
11. Backend checks admin has sufficient balance
12. Backend increases user's USD balance
13. Success message shown, page closes
```

### Transfer List Flow

```
1. User opens transfer list
2. Page loads transfers from TransferBloc
3. TransferBloc fetches from TransferRepository
4. Repository calls TransferApiDataSource
5. Backend filters by user's admin_group_id
6. Transfers displayed with type filter (All/Sent/Received)
7. User can apply date range filter
8. User can tap transfer to view details
9. User can pull to refresh
```

## API Integration

### Transfer Creation

**Endpoint:** `POST /api/v1/transfers`

**Request Body:**
```json
{
  "recipient_name": "John Doe",
  "recipient_user_id": 123,
  "admin_group_id": 456,
  "amount_usd": 100.00,
  "transfer_date": "2024-01-15",
  "notes": "Monthly allowance"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 789,
    "user_id": 1,
    "recipient_user_id": 123,
    "admin_group_id": 456,
    "recipient_name": "John Doe",
    "amount_usd": 100.00,
    "transfer_date": "2024-01-15",
    "notes": "Monthly allowance",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

### Transfer List

**Endpoint:** `GET /api/v1/transfers?page=1&per_page=15`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 789,
      "user_id": 1,
      "recipient_user_id": 123,
      "recipient_name": "John Doe",
      "amount_usd": 100.00,
      "transfer_date": "2024-01-15",
      "notes": "Monthly allowance",
      "created_at": "2024-01-15T10:30:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 15,
    "total": 73
  }
}
```

## Backend Requirements

### SuperAdmin to Admin Transfer

The backend must:
1. Validate `recipient_user_id` is an admin user
2. Validate recipient is in SuperAdmin's group
3. Set `admin_group_id` from recipient's admin_group_id
4. Increase admin's `balance_usd` in fund_box table
5. Return 403 error if recipient not in group

### Admin to User Transfer

The backend must:
1. Validate `recipient_user_id` is a regular user
2. Validate recipient is in admin's group
3. Check admin has sufficient `balance_usd`
4. Decrease admin's `balance_usd`
5. Increase user's `balance_usd` in fund_box table
6. Return 403 error if recipient not in group
7. Return 422 error if insufficient balance

### Transfer List

The backend must:
1. Filter transfers by authenticated user's admin_group_id
2. Include `recipient_user_id` and `recipient_name` in response
3. Support pagination with `page` and `per_page` parameters
4. Return transfers in reverse chronological order

## Error Handling

### Common Errors

**Recipient not in group:**
```
Error: "Recipient not in your group"
Status: 403 Forbidden
```

**Insufficient balance:**
```
Error: "Insufficient funds"
Status: 422 Unprocessable Entity
```

**Invalid recipient:**
```
Error: "Invalid recipient user ID"
Status: 404 Not Found
```

**Validation errors:**
```
Error: "Amount must be greater than zero"
Status: 422 Unprocessable Entity
```

## Testing Checklist

### SuperAdmin Transfer
- [ ] Load admin members successfully
- [ ] Display admin's current balance
- [ ] Validate amount input
- [ ] Show confirmation dialog
- [ ] Create transfer successfully
- [ ] Handle "recipient not in group" error
- [ ] Handle network errors gracefully

### Admin Transfer
- [ ] Load user members (only users, not admins)
- [ ] Display own balance
- [ ] Display user's current balance
- [ ] Validate sufficient balance
- [ ] Show projected balance in confirmation
- [ ] Create transfer successfully
- [ ] Handle "insufficient balance" error
- [ ] Handle "recipient not in group" error

### Transfer List
- [ ] Display all transfers
- [ ] Filter by "Sent" transfers
- [ ] Filter by "Received" transfers
- [ ] Apply date range filter
- [ ] Clear date filter
- [ ] Show correct sent/received indicators
- [ ] Display recipient information
- [ ] View transfer details
- [ ] Pull to refresh works
- [ ] Handle empty state
- [ ] Handle error state

## Integration Steps

1. **Add to Navigation:**
   - Add "Transfer" button in SuperAdmin navigation
   - Add "Transfer" button in Admin navigation
   - Add "Transfers" menu item for all roles

2. **Update Dependency Injection:**
   ```dart
   // Ensure TransferBloc is registered in injection_container.dart
   sl.registerFactory(() => TransferBloc(
     createTransferUseCase: sl(),
     getTransfersUseCase: sl(),
     updateTransferUseCase: sl(),
     deleteTransferUseCase: sl(),
     connectivityMonitor: sl(),
   ));
   ```

3. **Add Localization:**
   - Add translations for new UI strings
   - Support multiple languages

4. **Backend Verification:**
   - Test SuperAdmin to Admin transfer endpoint
   - Test Admin to User transfer endpoint
   - Verify balance updates correctly
   - Test error scenarios

## Related Files

### Core Files
- `lib/features/transfers/data/models/transfer_dto.dart` - Transfer data model
- `lib/features/transfers/data/datasources/transfer_api_datasource.dart` - API calls
- `lib/features/transfers/presentation/bloc/transfer_bloc.dart` - State management
- `lib/features/transfers/domain/usecases/create_transfer_usecase.dart` - Business logic

### New Files
- `lib/features/superadmin/presentation/pages/superadmin_transfer_page.dart`
- `lib/features/admin/presentation/pages/admin_transfer_page.dart`
- `lib/features/transfers/presentation/pages/transfer_list_page.dart`

### Supporting Files
- `lib/features/superadmin/data/datasources/superadmin_group_api_datasource.dart`
- `lib/features/admin_group/data/datasources/admin_group_api_datasource.dart`
- `lib/features/fund_box/data/datasources/fund_box_api_datasource.dart`

## Summary

The transfer features enable:
- ✅ SuperAdmin → Admin fund transfers
- ✅ Admin → User fund transfers
- ✅ Enhanced transfer list with filtering
- ✅ Balance validation
- ✅ Recipient validation
- ✅ User-friendly UI with confirmations

All features are ready for integration and testing!

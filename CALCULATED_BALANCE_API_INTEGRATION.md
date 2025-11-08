# Calculated Balance API Integration

## Overview

Integrated the new calculated balance API endpoint (`/api/v1/calculated-balance`) into the Flutter app. This endpoint provides real-time balance calculations from transactions, separate from the existing fund-box API.

## Changes Made

### 1. Data Source Layer

**File**: `lib/features/fund_box/data/datasources/fund_box_api_datasource.dart`

- Added `getCalculatedBalance({String? currency})` method to `FundBoxApiDataSource` interface
- Implemented the method to call `/api/v1/calculated-balance` endpoint
- Supports optional currency filter (`?currency=USD|SYP|TRY`)

### 2. Data Transfer Object

**File**: `lib/features/fund_box/data/models/fund_box_dto.dart`

- Updated `fromJson` to handle `calculated_at` field from calculated balance API response
- Maintains backward compatibility with `last_calculated_at` field

### 3. Repository Layer

**File**: `lib/features/fund_box/domain/repositories/fund_box_repository.dart`
**File**: `lib/features/fund_box/data/repositories/fund_box_repository_impl.dart`

- Added `getCalculatedBalance({String? currency})` method to repository interface
- Implemented repository method to call data source's calculated balance method

### 4. Use Case Layer

**File**: `lib/features/fund_box/domain/usecases/get_calculated_balance_usecase.dart`

- Created new `GetCalculatedBalanceUseCase` for getting calculated balance
- Available to all authenticated users (SuperAdmin, Admin, and Regular Users)

### 5. BLoC Layer

**File**: `lib/features/fund_box/presentation/bloc/fund_box_bloc.dart`
**File**: `lib/features/fund_box/presentation/bloc/fund_box_event.dart`

- Added `GetCalculatedBalanceUseCase` to `FundBoxBloc`
- Added new `LoadCalculatedBalance` event for explicitly loading calculated balance
- Updated `LoadFundBox` handler:
  - **Regular users**: Automatically uses calculated balance endpoint for real-time accuracy
  - **Admins/SuperAdmins**: Uses standard fund-box endpoint (stored balance)
- Updated `RefreshFundBox` handler:
  - **Regular users**: Refreshes calculated balance for real-time accuracy
  - **Admins/SuperAdmins**: Refreshes stored balance

### 6. Dependency Injection

**File**: `lib/injection_container.dart`

- Registered `GetCalculatedBalanceUseCase` in dependency injection container
- Updated `FundBoxBloc` factory to include `GetCalculatedBalanceUseCase`

## API Endpoints

### New Endpoint: `/api/v1/calculated-balance`

**Description**: Returns real-time calculated balance from all transactions

**Authentication**: Required (Sanctum token)

**Access**: All authenticated users (SuperAdmin, Admin, and Regular Users)

**Query Parameters**:
- `currency` (optional): Filter by specific currency (USD, SYP, or TRY)

**Response Format**:
```json
{
  "success": true,
  "data": {
    "balance_usd": 1500.00,
    "balance_syp": 750000.00,
    "balance_try": 45000.00,
    "calculated_at": "2025-11-08T10:30:00Z"
  }
}
```

### Updated Endpoint: `/api/v1/fund-box`

**For Regular Users**:
- Now returns calculated balance from transactions (same as `/calculated-balance`)
- Uses formula: Incoming - Exchanges - Expenses

**For Admins and SuperAdmins**:
- Continues to return stored balance from database
- Can be updated manually or recalculated

## Balance Calculation Formulas

### For SuperAdmin
```
USD Balance = Incoming from SuperAdmin - Outgoing to users - Exchanges (USD) - Expenses (USD)
SYP Balance = Exchanges to SYP - Expenses (SYP)
TRY Balance = Exchanges to TRY - Expenses (TRY)
```

### For Admin/User
```
USD Balance = Incoming from admins - Exchanges (USD) - Expenses (USD)
SYP Balance = Exchanges to SYP - Expenses (SYP)
TRY Balance = Exchanges to TRY - Expenses (TRY)
```

## Usage

### Automatic Usage (Recommended)

The app automatically uses calculated balance for regular users:

```dart
// Regular users automatically get calculated balance
context.read<FundBoxBloc>().add(LoadFundBox(userId));

// Refresh also uses calculated balance for regular users
context.read<FundBoxBloc>().add(RefreshFundBox(userId));
```

### Explicit Usage

To explicitly load calculated balance (useful for admins/superadmins who want real-time balance):

```dart
// Load calculated balance explicitly
context.read<FundBoxBloc>().add(LoadCalculatedBalance(currency: 'USD'));
```

### Currency-Specific Balance

```dart
// Get specific currency balance
context.read<FundBoxBloc>().add(LoadCalculatedBalance(currency: 'SYP'));
```

## Flavor Support

### User Flavor
- ✅ Automatically uses calculated balance endpoint
- ✅ Real-time balance from transactions
- ✅ No stored balance (always calculated)

### Admin Flavor
- ✅ Uses stored balance from database (standard fund-box endpoint)
- ✅ Can optionally use calculated balance endpoint via `LoadCalculatedBalance` event
- ✅ Can update stored balance manually

### SuperAdmin Flavor
- ✅ Uses stored balance from database (standard fund-box endpoint)
- ✅ Can optionally use calculated balance endpoint via `LoadCalculatedBalance` event
- ✅ Can update stored balance manually

## Key Features

1. **Multi-currency support**: USD, SYP, TRY
2. **Expenses included**: Expenses subtracted in all currencies
3. **Real-time calculation**: Always up-to-date balance from transactions
4. **Role-based logic**: Different formulas for SuperAdmin, Admin, and User
5. **No conflicts**: Separate endpoint from existing fund-box API
6. **Automatic fallback**: Falls back to standard fund-box endpoint if calculated balance fails
7. **Backward compatible**: Existing code continues to work

## Benefits

1. **Accurate balances**: Real-time calculation ensures balances are always accurate
2. **No sync issues**: No need to manually update balances after transactions
3. **Transparency**: Balances are calculated from actual transactions
4. **Flexibility**: Can use stored balance (admins) or calculated balance (users) as needed

## Testing

### Test Regular User Balance
1. Create incoming record as user
2. Create exchange
3. Create expense
4. Call `LoadFundBox` or `LoadCalculatedBalance`
5. Verify: Balance = Incoming - Exchanges - Expenses

### Test Admin/SuperAdmin Balance
1. Load fund box (gets stored balance)
2. Optionally load calculated balance for real-time balance
3. Verify both endpoints work correctly

## Notes

- Calculated balance endpoint is read-only (cannot update)
- Balances are never negative (capped at 0)
- Soft deletes are excluded from calculations
- All calculations are done on the backend for accuracy
- The app automatically chooses the appropriate endpoint based on user role

## Migration Notes

- Existing code continues to work without changes
- Regular users automatically benefit from calculated balance
- Admins/SuperAdmins can continue using stored balance or switch to calculated balance
- No breaking changes to existing API or UI


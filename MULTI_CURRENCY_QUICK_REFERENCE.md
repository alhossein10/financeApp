# Multi-Currency Fund Box - Quick Reference

## Overview

The Finance App now supports multi-currency fund boxes with USD, SYP, and TRY currencies. This document provides a quick reference for developers.

## API Endpoints

### Get Fund Box (All Currencies)
```dart
GET /fund-box
Authorization: Bearer {token}

Response:
{
  "data": {
    "id": 1,
    "balance_usd": 1000.00,
    "balance_syp": 500000.00,
    "balance_try": 25000.00,
    "last_calculated_at": "2024-11-15T10:00:00Z",
    "updated_at": "2024-11-15T10:00:00Z"
  }
}
```

### Get Fund Box (Specific Currency)
```dart
GET /fund-box?currency=USD
Authorization: Bearer {token}

Response:
{
  "data": {
    "id": 1,
    "currency": "USD",
    "balance": 1000.00,
    "last_calculated_at": "2024-11-15T10:00:00Z",
    "updated_at": "2024-11-15T10:00:00Z"
  }
}
```

### Get Calculated Balance (Real-time)
```dart
GET /calculated-balance
Authorization: Bearer {token}

Response: Same as /fund-box
```

### Get User Fund Box (Admin/SuperAdmin)
```dart
GET /fund-box?user_id=123
Authorization: Bearer {token}

Response: Same as /fund-box
```

### Update Fund Box (Admin Only)
```dart
PUT /fund-box
Authorization: Bearer {token}
Content-Type: application/json

Body:
{
  "balance_usd": 1500.00,
  "balance_syp": 600000.00,
  "balance_try": 30000.00
}

Response: Updated fund box data
```

## Code Examples

### Fetching Fund Box

```dart
// Get all currencies
final fundBox = await fundBoxApiDatasource.getFundBox();
print('USD: ${fundBox.balanceUsd}');
print('SYP: ${fundBox.balanceSyp}');
print('TRY: ${fundBox.balanceTry}');

// Get specific currency
final usdOnly = await fundBoxApiDatasource.getFundBox(currency: 'USD');
print('USD Balance: ${usdOnly.balance}');

// Get calculated balance (real-time)
final calculated = await fundBoxApiDatasource.getCalculatedBalance();
print('Real-time USD: ${calculated.balanceUsd}');

// Get user fund box (Admin/SuperAdmin)
final userFundBox = await fundBoxApiDatasource.getFundBoxByUserId(123);
print('User USD: ${userFundBox.balanceUsd}');
```

### Creating Multi-Currency Expense

```dart
// Create expense with USD only
context.read<ExpenseBloc>().add(CreateExpenseRequested(
  userId: userId,
  description: 'Office supplies',
  priceUsd: 50.00,
  priceS yp: null,
  priceTry: null,
  expenseDate: DateTime.now(),
));

// Create expense with multiple currencies
context.read<ExpenseBloc>().add(CreateExpenseRequested(
  userId: userId,
  description: 'Travel expenses',
  priceUsd: 100.00,
  priceSyp: 50000.00,
  priceTry: 2500.00,
  expenseDate: DateTime.now(),
));
```

### Updating Fund Box (Admin)

```dart
context.read<FundBoxBloc>().add(UpdateFundBalance(
  userId: userId,
  balanceUsd: 1500.00,
  balanceSyp: 600000.00,
  balanceTry: 30000.00,
));
```

## UI Components

### Fund Box Display

The fund box is displayed in `cash_inbox_page.dart` using a PageView with three cards:

```dart
PageView(
  scrollDirection: Axis.horizontal,
  children: [
    // USD Card (Green)
    _buildCurrencyCard(
      currency: 'USD',
      icon: Icons.attach_money,
      color: Colors.green,
      balance: fundBox.balanceUsd,
      symbol: '\$',
    ),
    // SYP Card (Orange)
    _buildCurrencyCard(
      currency: 'SYP',
      icon: Icons.currency_pound,
      color: Colors.orange,
      balance: fundBox.balanceSyp,
      symbol: 'ل.س',
    ),
    // TRY Card (Blue)
    _buildCurrencyCard(
      currency: 'TRY',
      icon: Icons.currency_lira,
      color: Colors.blue,
      balance: fundBox.balanceTry,
      symbol: '₺',
    ),
  ],
)
```

### Expense Creation Form

The expense form in `expense_page.dart` has three input fields:

```dart
Row(
  children: [
    Expanded(
      child: TextField(
        controller: usdCtrl,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: 'Price (USD)'),
      ),
    ),
    Expanded(
      child: TextField(
        controller: sypCtrl,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: 'Price (SYP)'),
      ),
    ),
    Expanded(
      child: TextField(
        controller: tryCtrl,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: 'Price (TRY)'),
      ),
    ),
  ],
)
```

## Currency Symbols

| Currency | Symbol | Code |
|----------|--------|------|
| US Dollar | $ | USD |
| Syrian Pound | ل.س | SYP |
| Turkish Lira | ₺ | TRY |

## Validation Rules

### Expense Creation
- At least one currency amount must be provided
- Currency amounts must be positive numbers
- Decimal values are supported (e.g., 10.50)

### Fund Box Update (Admin)
- Only admins can update fund box
- All three currencies can be updated simultaneously
- Negative values may be rejected by backend

## Error Handling

### Common Errors

| Error Code | Description | Solution |
|------------|-------------|----------|
| 401 | Unauthorized | Token expired, will auto-refresh |
| 403 | Forbidden | User lacks admin privileges |
| 404 | Not Found | User fund box doesn't exist |
| 422 | Validation Error | Check input values |

### Error Messages

```dart
// Insufficient balance
"Insufficient USD balance"
"Insufficient SYP balance"
"Insufficient TRY balance"

// Validation errors
"At least one price (USD, SYP, or TRY) must be provided"
"The total balance must be a positive number"

// Permission errors
"Access denied. Admin privileges required"
"You must be logged in to access fund box"
```

## BLoC Events

### FundBoxBloc Events

```dart
// Load fund box for user
LoadFundBox(userId, currency: 'USD')

// Load calculated balance (real-time)
LoadCalculatedBalance(currency: 'SYP')

// Update fund box (Admin only)
UpdateFundBalance(
  userId: userId,
  balanceUsd: 1000.00,
  balanceSyp: 500000.00,
  balanceTry: 25000.00,
)

// Refresh fund box
RefreshFundBox(userId, currency: null)
```

### ExpenseBloc Events

```dart
// Create expense with multi-currency
CreateExpenseRequested(
  userId: userId,
  description: 'Description',
  priceUsd: 100.00,
  priceSyp: 50000.00,
  priceTry: 2500.00,
  expenseDate: DateTime.now(),
)
```

## Bearer Token Authentication

All fund box and expense endpoints automatically include Bearer token authentication:

```
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

The `BearerTokenInterceptor` handles:
- ✅ Adding token to all protected endpoints
- ✅ Skipping token for public endpoints
- ✅ Automatic token refresh on 401 errors
- ✅ Redirect to login on refresh failure

## Testing Checklist

### Manual Testing

- [ ] Display fund box with all three currencies
- [ ] Swipe between currency cards
- [ ] Create expense with USD only
- [ ] Create expense with SYP only
- [ ] Create expense with TRY only
- [ ] Create expense with multiple currencies
- [ ] Verify balance decreases after expense
- [ ] Update fund box as admin
- [ ] Query user fund box as admin
- [ ] Verify Bearer token in network logs
- [ ] Test token refresh on 401 error

### Automated Testing

- [ ] Unit tests for FundBoxDto
- [ ] Unit tests for ExpenseDto
- [ ] Unit tests for FundBoxApiDatasource
- [ ] Integration tests for multi-currency flow
- [ ] Widget tests for fund box UI
- [ ] Widget tests for expense creation UI

## Related Files

### Data Layer
- `lib/features/fund_box/data/models/fund_box_dto.dart`
- `lib/features/fund_box/data/datasources/fund_box_api_datasource.dart`
- `lib/features/expenses/data/models/expense_dto.dart`
- `lib/features/expenses/data/datasources/expense_api_datasource.dart`

### Presentation Layer
- `lib/features/fund_box/presentation/bloc/fund_box_bloc.dart`
- `lib/features/expenses/presentation/bloc/expense_bloc.dart`
- `lib/ui/cash_inbox_page.dart`
- `lib/ui/expense_page.dart`

### Core
- `lib/core/api/bearer_token_interceptor.dart`
- `lib/core/api/api_client.dart`
- `lib/core/services/token_manager.dart`

## Support

For issues or questions:
1. Check `TASK_3_MULTI_CURRENCY_VERIFICATION.md` for detailed implementation
2. Check `TASK_3_COMPLETION_SUMMARY.md` for completion status
3. Review the design document at `.kiro/specs/postman-api-v3.1-verification/design.md`
4. Review the requirements at `.kiro/specs/postman-api-v3.1-verification/requirements.md`

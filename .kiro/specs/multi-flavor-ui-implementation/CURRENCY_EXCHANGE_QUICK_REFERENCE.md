# Currency Exchange - Quick Reference Guide

## Overview
The Currency Exchange feature allows Admins and Users to convert USD to SYP (Syrian Pounds) or TRY (Turkish Lira) with automatic balance updates.

## Key Features

### ✅ Exchange Creation
- Convert USD to SYP or TRY
- Enter either exchange rate OR converted amount (auto-calculates the other)
- Balance verification before submission
- Date selection for exchange
- Optional notes field

### ✅ Exchange History/Log
- View all exchanges with filtering
- Filter by currency (All, SYP, TRY)
- Filter by user (Admin only)
- Total exchanged amounts display
- Export to PDF

## Admin Features

### Exchange Creation Page
**Location:** `lib/features/admin/presentation/pages/admin_exchange_page.dart`

**Access:** Bottom Navigation → Exchange

**Features:**
- Create exchanges from USD balance
- View current USD balance
- "Exchange Log" button in app bar
- Automatic navigation to log after creation

### Exchange Log
**Features:**
- View own exchanges
- View all group members' exchanges
- Filter by user (dropdown with "Admin Owner" + all members)
- Filter by currency
- Total SYP and TRY amounts displayed
- Export to PDF with filters

## User Features

### Exchange Creation Page
**Location:** `lib/features/exchanges/presentation/pages/user_exchange_page.dart`

**Access:** Bottom Navigation → Exchange

**Features:**
- Create exchanges from USD balance
- Multi-currency balance card (USD, SYP, TRY)
- Collapsible balance display
- Calculated exchange rate shown
- History icon in app bar

### Exchange Log
**Features:**
- View ONLY own exchanges
- Filter by currency
- Total SYP and TRY amounts displayed
- Export to PDF

## Reusable Components

### ExchangeForm Widget
**Location:** `lib/features/exchanges/presentation/widgets/exchange_form.dart`

**Props:**
- `currentUsdBalance` - Current USD balance for validation
- `onSubmit` - Callback with ExchangeFormData
- `isLoading` - Loading state for submit button

**Features:**
- Target currency selector (SYP/TRY)
- USD amount input with validation
- Toggle between rate/amount input modes
- Real-time calculation display
- Date picker
- Notes field
- Balance verification

## API Endpoints

### Create Exchange
```
POST /api/v1/exchanges
Body: {
  "target_currency": "SYP" | "TRY",
  "amount_usd": 100.00,
  "exchange_rate": 15000.00,      // Optional if converted_amount provided
  "converted_amount": 1500000.00, // Optional if exchange_rate provided
  "exchange_date": "2024-01-15",
  "notes": "Optional notes"
}
```

### Get Exchanges
```
GET /api/v1/exchanges?currency=SYP
```

### Get Transfer Exchanges
```
GET /api/v1/exchanges/transfer/{transferId}
```

## Balance Verification

### Client-Side Check
```dart
final hasBalance = await BalanceVerificationService.verifyBalance(
  currency: 'USD',
  amount: amount,
  currentBalance: currentUsdBalance,
);
```

### Error Handling
- Insufficient balance → Red SnackBar with current balance
- Invalid amount → Form validation error
- API error → Red SnackBar with error message

## Exchange Rate Calculation

### Mode 1: Enter Exchange Rate
User enters: `1 USD = 15,000 SYP`
System calculates: `100 USD = 1,500,000 SYP`

### Mode 2: Enter Converted Amount
User enters: `100 USD → 1,500,000 SYP`
System calculates: `1 USD = 15,000 SYP`

## Data Flow

### Exchange Creation Flow
1. User fills form
2. Client validates balance
3. Submit to API
4. API validates and creates exchange
5. API updates fund box balances
6. Client receives success response
7. Client reloads fund box
8. Navigate to exchange log

### Exchange Log Flow
1. Load exchanges from API
2. Backend filters by authenticated user
3. Apply client-side filters (currency, user)
4. Calculate totals (SYP, TRY)
5. Display in list
6. Support export to PDF

## State Management

### BLoCs Used
- **ExchangeBloc** - Exchange operations (create, load, filter)
- **FundBoxBloc** - Balance loading and updates
- **AdminGroupBloc** - Group member loading (Admin only)
- **AuthBloc** - Current user information

### Events
- `CreateExchangeEvent` - Create new exchange
- `LoadAllExchangesEvent` - Load exchanges with optional currency filter
- `LoadFundBox` - Reload balance after exchange

### States
- `ExchangeLoading` - Operation in progress
- `ExchangeCreated` - Exchange created successfully
- `ExchangesLoaded` - Exchanges loaded successfully
- `ExchangeError` - Error occurred

## Filtering

### Currency Filter
- **All** - Show all exchanges (SYP + TRY)
- **SYP** - Show only SYP exchanges
- **TRY** - Show only TRY exchanges

### User Filter (Admin Only)
- **All** - Show all group members' exchanges
- **Admin Owner** - Show only admin's own exchanges
- **[Member Name]** - Show specific member's exchanges

### Filter Persistence
Filters are maintained during session using `ValueListenableBuilder` and `RecipientFilterNotifier`.

## Export Functionality

### Export to PDF
- Applies active filters (currency, user)
- Includes exchange details (date, amount, rate, notes)
- Shows totals for SYP and TRY
- Watermark included
- Saves to device downloads

### Export Data
- Exchange date
- USD amount
- Exchange rate
- Converted amount (SYP or TRY)
- Notes (if any)
- User name (Admin export only)

## Localization

### Supported Languages
- English (en)
- Arabic (ar)

### Key Translation Keys
- `currency_exchange` - Page title
- `create_exchange` - Button text
- `exchange_log` - Log button text
- `target_currency` - Currency selector label
- `amount_usd` - USD amount label
- `exchange_rate` - Rate label
- `converted_amount` - Converted amount label
- `available_balance` - Balance display
- `you_will_receive` - Calculation preview
- `insufficient_usd_balance` - Error message
- `exchange_created_success` - Success message

## Error Messages

### Validation Errors
- "Please enter amount" - Empty amount field
- "Please enter valid amount" - Invalid number
- "Amount exceeds available balance" - Insufficient funds
- "Please enter exchange rate" - Empty rate (when in rate mode)
- "Please enter converted amount" - Empty amount (when in amount mode)

### API Errors
- "Insufficient USD balance" - Backend balance check failed
- "Invalid currency" - Invalid target currency
- "Exchange creation failed" - General API error

## Testing Checklist

### Manual Testing
- [ ] Create exchange with rate input
- [ ] Create exchange with amount input
- [ ] Verify balance deduction
- [ ] Verify target currency addition
- [ ] Test insufficient balance error
- [ ] Test currency filter
- [ ] Test user filter (Admin)
- [ ] Test export to PDF
- [ ] Test date picker
- [ ] Test notes field
- [ ] Verify totals calculation
- [ ] Test pull-to-refresh

### Edge Cases
- [ ] Zero balance
- [ ] Exact balance amount
- [ ] Very large amounts
- [ ] Very small amounts
- [ ] Special characters in notes
- [ ] Past dates
- [ ] Today's date
- [ ] Multiple exchanges same day

## Performance Considerations

### Optimization
- Balance loaded once on page load
- Exchanges cached during session
- Filters applied client-side (no API calls)
- Calculations done in real-time (no debouncing needed)

### Best Practices
- Use `ListView.builder` for exchange list
- Lazy load images if added in future
- Cache exchange data locally
- Batch API requests where possible

## Security

### Client-Side
- Balance verification before submission
- Input validation and sanitization
- Secure token storage
- HTTPS for all API calls

### Server-Side
- Balance verification on backend
- User authentication required
- Role-based access control
- Transaction logging

## Troubleshooting

### Issue: Balance not updating
**Solution:** Reload fund box after exchange creation

### Issue: Exchanges not showing
**Solution:** Check backend filters, verify user authentication

### Issue: Export fails
**Solution:** Check file permissions, verify data format

### Issue: Calculation incorrect
**Solution:** Verify input format, check decimal places

## Future Enhancements

### Potential Features
- [ ] Exchange rate history/trends
- [ ] Bulk exchange operations
- [ ] Exchange reversal/cancellation
- [ ] Exchange notifications
- [ ] Exchange analytics dashboard
- [ ] Multi-step exchange wizard
- [ ] Exchange templates/presets
- [ ] Exchange scheduling

## Related Documentation

- [Task 11 Implementation Summary](./TASK_11_CURRENCY_EXCHANGE_SUMMARY.md)
- [Balance Verification Service](../../core/services/BALANCE_VERIFICATION_USAGE_GUIDE.md)
- [Exchange API Documentation](../../features/exchanges/data/datasources/exchange_api_datasource.dart)
- [Exchange DTO Documentation](../../features/exchanges/data/models/exchange_dto.dart)

## Support

For issues or questions:
1. Check this quick reference
2. Review implementation summary
3. Check API documentation
4. Review BLoC state management
5. Contact development team

---

**Last Updated:** 2024-01-15
**Version:** 1.0.0
**Status:** ✅ Complete

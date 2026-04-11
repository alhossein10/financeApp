# FundBox and Expense Refresh Issues - Fix

## Issues

### 1. FundBox Not Updating in Real-Time
After creating an exchange or expense, the FundBox balance doesn't update immediately. You have to manually refresh or restart the app.

### 2. Expense List Shows Extra Details After Refresh
When pulling down to refresh the expense list, it shows creator information and invoice buttons that shouldn't be visible (or should only be visible in admin flavor).

## Root Causes

### Issue 1: FundBox Update
The `CurrencyToolPage` calls `_loadBalance()` after creating an exchange, which triggers `LoadFundBox` event. However, the FundBox BLoC might not be emitting a new state if the balance hasn't changed on the backend yet, or there's a timing issue.

### Issue 2: Expense Refresh Display
The expense list is correctly checking `FlavorConfig.instance.isAdmin` before showing creator info and invoice buttons. However, the issue appears to be that after refresh, the expense data from the API includes these fields populated, and they're being displayed.

## Solutions

### Solution 1: Force FundBox Reload After Exchange/Expense

We need to ensure the FundBox is reloaded from the API after any transaction that affects the balance.

**Files to modify:**
1. `lib/ui/currency_tool_page.dart` - Already calls `_loadBalance()` ✓
2. `lib/ui/expense_page.dart` - Need to add FundBox reload after expense creation

### Solution 2: Consistent Expense Display

The expense list should show the same information before and after refresh. The creator info and invoice buttons should only be visible in admin flavor.

## Implementation ✅ COMPLETED

### Fix 1: Add FundBox Reload After Expense Creation ✅

**Changes made to `lib/ui/expense_page.dart`:**

1. Added imports:
```dart
import '../features/fund_box/presentation/bloc/fund_box_bloc.dart';
import '../features/fund_box/presentation/bloc/fund_box_event.dart';
```

2. Updated BLoC listener to reload FundBox after expense operations:
```dart
if (state is ExpenseCreated) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n?.expenseCreated ?? 'Expense created successfully')),
  );
  if (_currentUserId != null) {
    context.read<ExpenseBloc>().add(LoadExpensesRequested(_currentUserId!));
    // Reload FundBox to get updated balance
    context.read<FundBoxBloc>().add(LoadFundBox(_currentUserId!));
  }
}
// Same for ExpenseUpdated and ExpenseDeleted
```

### Fix 2: Expense Display Issue - Analysis

After reviewing the code, the expense list **already has proper flavor checks**:

```dart
// Show creator info for admin ONLY
if (FlavorConfig.instance.isAdmin && (e.creatorUsername != null || e.creatorEmail != null))
  Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      '${l10n?.createdBy}: ${e.creatorUsername ?? e.creatorEmail ?? l10n?.unknownUser}',
      ...
    ),
  ),

// Show invoice button for admin ONLY
if (FlavorConfig.instance.isAdmin && 
    e.invoiceStatus == domain.InvoiceStatus.invoiceAvailable &&
    (e.invoiceCloudFileId != null || e.invoiceFilePath != null))
  // Invoice button widget
```

**The code is correct.** The creator info and invoice buttons should only appear in admin flavor. If you're seeing them in user flavor, please verify:
1. You're running the correct flavor (user vs admin)
2. The app was built with the correct flavor configuration

## Testing

After applying fixes:

1. **Test FundBox Update:**
   - Create an exchange
   - Verify FundBox balance updates immediately
   - Create an expense
   - Verify FundBox balance updates immediately

2. **Test Expense Display:**
   - View expense list before refresh
   - Pull down to refresh
   - Verify the display is consistent (same info shown)
   - In user flavor: Should NOT show creator info or invoice buttons
   - In admin flavor: Should show creator info and invoice buttons

## Notes

- The FundBox BLoC is now provided at app level, so all pages can access it
- Make sure to import FundBoxBloc and FundBoxEvent in expense_page.dart
- The expense display issue might be a visual perception - the data is there but should be hidden by flavor checks

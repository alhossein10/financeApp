# Remaining Issues - Troubleshooting Guide

## Issue 1: Expense Refresh Display Problem

### Symptom
When pulling down to refresh the expense list, it shows extra details (creator info, invoice buttons) that shouldn't be visible or should only be visible in admin flavor.

### Current Code Analysis
The expense list has proper flavor checks:
```dart
// Show creator info for admin ONLY
if (FlavorConfig.instance.isAdmin && (e.creatorUsername != null || e.creatorEmail != null))
  // Display creator info

// Show invoice button for admin ONLY  
if (FlavorConfig.instance.isAdmin && 
    e.invoiceStatus == domain.InvoiceStatus.invoiceAvailable &&
    (e.invoiceCloudFileId != null || e.invoiceFilePath != null))
  // Display invoice button
```

### Possible Causes

1. **Running Wrong Flavor**
   - You might be running the admin flavor instead of user flavor
   - Check which flavor is active: Look at the app title or check logs

2. **Flavor Not Initialized Properly**
   - The flavor configuration might not be set correctly
   - Check `FlavorConfig.instance.flavor` value

3. **Visual Perception**
   - The data is there in the API response but should be hidden
   - The UI might be showing it briefly during loading state

### Debugging Steps

1. **Verify Current Flavor:**
```dart
// Add this temporarily to expense_page.dart build method
print('🔍 Current Flavor: ${FlavorConfig.instance.flavor}');
print('🔍 Is Admin: ${FlavorConfig.instance.isAdmin}');
```

2. **Check Expense Data:**
```dart
// Add this when displaying expenses
print('🔍 Expense creator: ${e.creatorUsername}');
print('🔍 Should show creator: ${FlavorConfig.instance.isAdmin && e.creatorUsername != null}');
```

3. **Verify Build Configuration:**
   - Make sure you're running: `flutter run` (defaults to user flavor)
   - NOT running: `flutter run --flavor admin` or `flutter run --dart-define=FLAVOR=admin`

### Solution

If you're seeing creator info in user flavor, the issue is likely:
- Running admin flavor by mistake
- OR the flavor check is not working

**Quick Fix:** Add explicit logging to confirm flavor state.

---

## Issue 2: Exchange API 400 Error (Intermittent)

### Symptom
Sometimes when creating an exchange, you get an API 400 error. After a few retries, it works.

### Possible Causes

1. **Validation Error - Missing/Invalid Data**
   - The backend is rejecting the request due to validation failure
   - Common issues:
     - `amount_usd` is 0 or negative
     - `converted_amount` is 0 or negative
     - `exchange_date` format is invalid
     - `target_currency` is not 'SYP' or 'TRY'

2. **Race Condition - Insufficient Balance**
   - The FundBox balance hasn't updated yet from a previous transaction
   - You try to create an exchange that exceeds the current balance
   - After a retry, the balance has updated and it works

3. **Backend Validation Timing**
   - The backend checks balance at the time of request
   - If there's a delay in balance update, it might fail temporarily

### Debugging Steps

1. **Add Detailed Logging:**

In `lib/ui/currency_tool_page.dart`, add logging before creating exchange:

```dart
void _createExchange() {
  if (_formKey.currentState?.validate() ?? false) {
    final amountUsd = double.tryParse(_amountController.text) ?? 0.0;
    final convertedAmount = double.tryParse(_convertedAmountController.text) ?? 0.0;

    // ADD THIS LOGGING
    print('🔍 Creating Exchange:');
    print('  Amount USD: $amountUsd');
    print('  Converted Amount: $convertedAmount');
    print('  Target Currency: $_targetCurrency');
    print('  Exchange Date: $_selectedDate');
    print('  Current FundBox Balance: ${fundBoxState is FundBoxLoaded ? fundBoxState.fundBox.balanceUsd : "unknown"}');

    // Validate amount
    if (amountUsd <= 0) {
      // ... error handling
    }
    
    // ... rest of code
  }
}
```

2. **Check Backend Logs:**
   - Look at your Laravel backend logs
   - Check what validation error is being returned
   - The error message should tell you exactly what's wrong

3. **Add Error Display:**

Update the error listener to show more details:

```dart
} else if (state is ExchangeError) {
  final l10n = AppLocalizations.of(context);
  print('🔴 Exchange Error: ${state.message}'); // ADD THIS
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${l10n?.error ?? 'Error'}: ${state.message}'),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 5), // Longer duration to read error
    ),
  );
}
```

### Common 400 Error Scenarios

1. **Scenario: Amount is 0**
   - **Cause:** User didn't enter amount or entered 0
   - **Fix:** Already validated in UI, but backend also checks

2. **Scenario: Insufficient Balance**
   - **Cause:** FundBox balance is less than amount_usd
   - **Backend Response:** "Insufficient USD balance"
   - **Fix:** Wait for balance to update, or reduce amount

3. **Scenario: Invalid Date Format**
   - **Cause:** Date format doesn't match backend expectation
   - **Expected:** 'YYYY-MM-DD' format
   - **Fix:** Check date formatting in code

4. **Scenario: Missing converted_amount**
   - **Cause:** User didn't enter converted amount
   - **Fix:** Already validated in UI

### Solutions

#### Solution 1: Add Retry Logic with Delay

```dart
Future<void> _createExchangeWithRetry({int retries = 3}) async {
  for (int i = 0; i < retries; i++) {
    try {
      context.read<ExchangeBloc>().add(CreateExchangeEvent(...));
      break; // Success, exit loop
    } catch (e) {
      if (i == retries - 1) {
        // Last retry failed, show error
        rethrow;
      }
      // Wait before retry
      await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
    }
  }
}
```

#### Solution 2: Validate Balance Before Submission

```dart
void _createExchange() {
  if (_formKey.currentState?.validate() ?? false) {
    final amountUsd = double.tryParse(_amountController.text) ?? 0.0;
    final convertedAmount = double.tryParse(_convertedAmountController.text) ?? 0.0;

    // Get current fund box balance
    final fundBoxState = context.read<FundBoxBloc>().state;
    double maxUsdBalance = 0.0;
    if (fundBoxState is FundBoxLoaded) {
      maxUsdBalance = fundBoxState.fundBox.balanceUsd;
    }

    // ADD THIS: Reload balance before validation
    if (maxUsdBalance == 0) {
      // Balance might not be loaded, reload it
      final authState = context.read<AuthBloc>().state;
      final userId = authState.user?.id;
      if (userId != null) {
        context.read<FundBoxBloc>().add(LoadFundBox(userId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading balance, please try again...')),
        );
        return;
      }
    }

    // Validate amount doesn't exceed fund box balance
    if (amountUsd > maxUsdBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Amount exceeds available balance: \$${maxUsdBalance.toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create exchange
    context.read<ExchangeBloc>().add(CreateExchangeEvent(...));
  }
}
```

#### Solution 3: Show Detailed Error Messages

The backend should return specific error messages. Make sure to display them:

```dart
} else if (state is ExchangeError) {
  final l10n = AppLocalizations.of(context);
  
  // Parse error message for specific issues
  String errorMessage = state.message;
  if (errorMessage.contains('Insufficient')) {
    errorMessage = 'Insufficient balance. Please check your FundBox balance.';
  } else if (errorMessage.contains('validation')) {
    errorMessage = 'Invalid data. Please check all fields.';
  }
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${l10n?.error ?? 'Error'}: $errorMessage'),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Retry',
        textColor: Colors.white,
        onPressed: () {
          // Retry the exchange
          _createExchange();
        },
      ),
    ),
  );
}
```

### Next Steps

1. **Add the logging code** to see what data is being sent
2. **Check the backend logs** to see the exact validation error
3. **Test with different scenarios:**
   - Create exchange immediately after expense
   - Create exchange after waiting a few seconds
   - Create exchange with different amounts
4. **Report back** with the exact error message from the logs

---

## Summary

- **Expense refresh issue:** Likely a flavor configuration problem. Verify you're running the correct flavor.
- **Exchange 400 error:** Likely a validation or timing issue. Add logging to see the exact error, and consider adding balance reload before submission.

Both issues need more debugging information to pinpoint the exact cause. The logging additions above will help identify the root cause.

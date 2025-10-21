# Transfer Amount Fix

## Problem
When creating a new transfer with:
- Amount USD: 500
- Converted Amount: 150

The fund box was decreasing by 350 instead of 500.

## Root Cause
The code was calculating `actualTransferAmount = amount - convertedAmount` (500 - 150 = 350) and saving only 350 to the database. This caused the fund box to decrease by 350 instead of the full 500.

## Solution
Changed the logic to save the **full amount** (500) to the database, so the fund box correctly decreases by 500.

### Data Model Clarification
- `amountUsd` = Total transfer amount (e.g., 500) - **this is what gets deducted from fund box**
- `convertedAmountUsd` = Portion converted to SYP (e.g., 150) - **for tracking purposes only**

So in the example:
- Total transfer: 500 USD
- Converted to SYP: 150 USD
- Remaining in USD: 350 USD (calculated as: amountUsd - convertedAmountUsd)
- **Fund box decreases by: 500 USD** (the full amount)

## Changes Made

### 1. Create Transfer (lib/ui/cash_inbox_page.dart)

**Before:**
```dart
// Calculate actual transfer amount: total amount - converted amount
final actualTransferAmount = amount - convertedAmount;
if (actualTransferAmount < 0) {
  // error
}

await _db.createTransfer(
  recipientName: name,
  amountUsd: actualTransferAmount,  // ❌ Only 350
  convertedAmountUsd: convertedAmount,
  ...
);
```

**After:**
```dart
// Validate that converted amount doesn't exceed total amount
if (convertedAmount > amount) {
  // error
}

await _db.createTransfer(
  recipientName: name,
  amountUsd: amount,  // ✅ Full 500
  convertedAmountUsd: convertedAmount,
  ...
);
```

### 2. Edit Transfer (lib/ui/cash_inbox_page.dart)

**Before:**
```dart
final newConvertedAmount = double.tryParse(convertedUsdCtrl.text.trim()) ?? 0.0;
final originalTotal = t.amountUsd + (t.convertedAmountUsd ?? 0.0);  // ❌ Wrong calculation
final newTransferAmount = originalTotal - newConvertedAmount;

final updated = t.copyWith(
  amountUsd: newTransferAmount,  // ❌ Changing the total amount
  convertedAmountUsd: newConvertedAmount,
  ...
);
```

**After:**
```dart
final newConvertedAmount = double.tryParse(convertedUsdCtrl.text.trim()) ?? 0.0;

// Validate that converted amount doesn't exceed total transfer amount
if (newConvertedAmount > t.amountUsd) {
  // error
}

final updated = t.copyWith(
  convertedAmountUsd: newConvertedAmount,  // ✅ Only update converted amount
  // amountUsd stays the same - no need to change it
  ...
);
```

## Result
✅ Creating a transfer with Amount USD = 500 and Converted Amount = 150 now correctly decreases the fund box by 500
✅ Editing a transfer only updates the converted amount, not the total amount
✅ The display shows the actual USD transferred (500 - 150 = 350) in the transfer list
✅ The subtitle shows the converted amount details (e.g., "150 USD → 15000 SYP")

## Display Logic
The card now shows:
- **Title**: "Steve • 400 USD" (actual USD transferred = 500 - 100)
- **Subtitle**: "Converted Amount: 100 USD → 10000 SYP" (if conversion exists)

### Example Scenarios

**Scenario 1: Transfer with conversion**
- Input: Amount USD = 500, Converted Amount = 100, Rate = 100
- Fund box decreases by: **500**
- Card displays: "Steve • **400 USD**"
- Subtitle: "Converted Amount: 100 USD → 10000 SYP"

**Scenario 2: Edit conversion**
- Original: 500 total, 100 converted → shows 400 USD
- Edit to: 200 converted
- Fund box: **unchanged** (still -500)
- Card now displays: "Steve • **300 USD**"
- Subtitle: "Converted Amount: 200 USD → 20000 SYP"

**Scenario 3: No conversion**
- Input: Amount USD = 500, no conversion
- Fund box decreases by: **500**
- Card displays: "Steve • **500 USD**"
- Subtitle: "No SYP recorded"

## Testing
To verify the fix:
1. Create a new transfer with Amount USD = 500 and Converted Amount = 100
2. Check that the fund box decreases by 500
3. Check that the card shows "400 USD" (500 - 100)
4. Edit the transfer and change the converted amount to 200
5. Verify that the card now shows "300 USD" (500 - 200)
6. Verify that the fund box remains unchanged

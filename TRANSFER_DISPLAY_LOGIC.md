# Transfer Display Logic - How It Works

## Overview
The transfer system now correctly handles the fund box deduction and displays the actual USD transferred after conversion.

## Data Model

### Stored in Database
- `amountUsd`: Total transfer amount (e.g., 500) - **This is what gets deducted from fund box**
- `convertedAmountUsd`: Amount converted to SYP (e.g., 100)
- `amountSypAtExchange`: SYP amount received (e.g., 10000)
- `manualUsdToSypRate`: Exchange rate used (e.g., 100)

### Calculated for Display
- **Actual USD Transferred** = `amountUsd - convertedAmountUsd`
  - Example: 500 - 100 = **400 USD**

## Visual Examples

### Example 1: Transfer with Conversion

**Input:**
```
Recipient: Steve
Amount USD: 500
Converted Amount: 100
Exchange Rate: 100 (USD → SYP)
```

**What Happens:**
1. Fund box decreases by: **500 USD**
2. Database stores:
   - amountUsd = 500
   - convertedAmountUsd = 100
   - amountSypAtExchange = 10000

**Card Display:**
```
┌─────────────────────────────────────┐
│ Steve • 400 USD                  ⋮  │
│ المبلغ المحول: 100 دولار ← 10000    │
│ ليرة سورية                          │
└─────────────────────────────────────┘
```

**Breakdown:**
- Steve receives: **400 USD** (in USD) + **10000 SYP** (converted)
- Total value: 500 USD equivalent
- Fund box: -500 USD

---

### Example 2: Edit Conversion Amount

**Original Transfer:**
```
Amount USD: 500
Converted Amount: 100
Display: Steve • 400 USD
```

**Edit Conversion to 200:**
```
Amount USD: 500 (unchanged)
Converted Amount: 200 (updated)
Display: Steve • 300 USD (updated)
```

**What Happens:**
1. Fund box: **No change** (still -500)
2. Database updates:
   - amountUsd = 500 (unchanged)
   - convertedAmountUsd = 200 (updated)
   - amountSypAtExchange = 20000 (updated)

**New Card Display:**
```
┌─────────────────────────────────────┐
│ Steve • 300 USD                  ⋮  │
│ المبلغ المحول: 200 دولار ← 20000    │
│ ليرة سورية                          │
└─────────────────────────────────────┘
```

**Breakdown:**
- Steve now receives: **300 USD** + **20000 SYP**
- Total value: still 500 USD equivalent
- Fund box: unchanged (-500 USD)

---

### Example 3: No Conversion

**Input:**
```
Recipient: John
Amount USD: 500
Converted Amount: 0 (or empty)
```

**What Happens:**
1. Fund box decreases by: **500 USD**
2. Database stores:
   - amountUsd = 500
   - convertedAmountUsd = 0 or null
   - amountSypAtExchange = null

**Card Display:**
```
┌─────────────────────────────────────┐
│ John • 500 USD                   ⋮  │
│ لا يوجد ليرة سورية مسجلة            │
└─────────────────────────────────────┘
```

**Breakdown:**
- John receives: **500 USD** (all in USD)
- Fund box: -500 USD

---

## Code Logic

### Display Calculation
```dart
// Calculate actual USD transferred
final actualUsdTransferred = t.amountUsd - (t.convertedAmountUsd ?? 0.0);

// Display in card title
Text('${t.recipientName} • ${actualUsdTransferred.toStringAsFixed(2)} USD')
```

### Subtitle Logic
```dart
if (convertedAmount > 0 && t.amountSypAtExchange != null) {
  // Show conversion details
  subtitle = 'Converted: 100 USD → 10000 SYP';
} else if (t.amountSypAtExchange != null) {
  // Show only SYP amount
  subtitle = 'SYP: 10000';
} else {
  // No conversion
  subtitle = 'No SYP recorded';
}
```

## Benefits

✅ **Clear Display**: Shows exactly how much USD the recipient gets
✅ **Accurate Fund Tracking**: Fund box always decreases by the total amount
✅ **Flexible Editing**: Can adjust conversion without affecting fund box
✅ **Transparent**: Subtitle shows conversion details
✅ **Consistent**: Same logic for create and edit operations

## Summary Table

| Scenario | Total | Converted | USD Shown | SYP Shown | Fund Box |
|----------|-------|-----------|-----------|-----------|----------|
| Full USD | 500 | 0 | 500 | - | -500 |
| Partial Conversion | 500 | 100 | 400 | 10000 | -500 |
| High Conversion | 500 | 400 | 100 | 40000 | -500 |
| Edit Conversion | 500 | 100→200 | 400→300 | 10000→20000 | -500 (unchanged) |

## Validation

The system validates that:
- Converted amount cannot exceed total amount
- Example: If total is 500, converted cannot be 600
- Error message: "لا يمكن أن يتجاوز المبلغ المحول إجمالي مبلغ التحويل"

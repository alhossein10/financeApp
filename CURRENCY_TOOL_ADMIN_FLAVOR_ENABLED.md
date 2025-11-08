# Currency Tool (تصريف) Enabled in Admin Flavor

## Changes Made

Enabled the Currency Tool page (تصريف) in the admin flavor and positioned it between Cash page and Expenses page.

### Files Modified

#### `lib/core/config/flavor_config.dart`

**Changed:**
```dart
// Before:
enableCurrencyModule: false, // Disabled for admin flavor

// After:
enableCurrencyModule: true, // Enabled for admin flavor - تصريف page
```

## Navigation Order - Admin Flavor

After this change, the admin flavor navigation order is:

1. **Group Management** (إدارة المجموعات) - Admin only
2. **Cash Inbox** (الصندوق) - Cash transactions
3. **Currency Tool** (تصريف) - Currency conversion ← **Now enabled**
4. **Expenses** (المصاريف) - Expense management
5. **Export** (تصدير) - Data export

## What This Enables

The Currency Tool page provides:
- Currency conversion calculator
- Exchange rate management
- Multi-currency support (USD, SYP, TRY)
- Real-time conversion calculations

## Navigation Icons

The Currency Tool appears with:
- **Icon**: Currency exchange icon (outlined/filled)
- **Label**: "تصريف" or "Convert" (based on locale)

## Technical Details

### How It Works

The page visibility is controlled by the `enableCurrencyModule` flag in `FlavorConfig`:

```dart
if (_flavorConfig.enableCurrencyModule) {
  pages.add(const CurrencyToolPage());
}
```

And in navigation destinations:

```dart
if (_flavorConfig.enableCurrencyModule) {
  destinations.add(NavigationDestination(
    icon: const Icon(Icons.currency_exchange_outlined),
    selectedIcon: const Icon(Icons.currency_exchange),
    label: l10n.translate('convert'),
  ));
}
```

### Position in Code

The Currency Tool is already positioned correctly in `main.dart`:
- It's added after `CashInboxPage`
- It's added before `ExpensePage`

This means it naturally appears between Cash and Expenses in the navigation.

## User Flavor

Note: The Currency Tool remains enabled in the user flavor as well, where it serves a different purpose for regular users.

## Testing

To verify this change:

1. **Build admin flavor:**
   ```bash
   flutter run --flavor admin
   ```

2. **Check navigation:**
   - Login as admin user
   - Verify Currency Tool appears in bottom navigation
   - Verify it's positioned between Cash and Expenses
   - Tap on Currency Tool icon
   - Verify the page loads correctly

3. **Test functionality:**
   - Enter amounts in different currencies
   - Verify conversion calculations work
   - Test all currency combinations (USD, SYP, TRY)

## Rollback

If you need to disable the Currency Tool in admin flavor:

Change in `lib/core/config/flavor_config.dart`:
```dart
enableCurrencyModule: false, // Disabled for admin flavor
```

## Benefits

1. **Unified Experience**: Admins can now use the same currency conversion tool as users
2. **Better Workflow**: Currency conversion is accessible between cash management and expenses
3. **Consistency**: All currency-related features are available in one place
4. **Convenience**: No need to switch to user flavor for currency conversions

## Notes

- The Currency Tool page (`lib/ui/currency_tool_page.dart`) is shared between both flavors
- No changes were needed to the page itself
- Only the flavor configuration was modified
- The page position in navigation was already correct

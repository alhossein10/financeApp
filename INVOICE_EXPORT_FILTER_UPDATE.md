# Invoice Images Export - Filter Support Added

## Update Summary

The invoice images export now respects the same filters applied on the Expenses page, just like PDF and Excel exports.

## What Was Changed

### Before:
- Invoice images export exported **ALL** expenses with images
- Filters were ignored
- No way to export only specific date ranges or currencies

### After:
- Invoice images export respects **currency filter**
- Invoice images export respects **date filter**
- Consistent behavior with PDF and Excel exports

## How It Works

### Filters Applied:

#### 1. Currency Filter
When you select a currency filter on the Expenses page:
- **All**: Exports all invoice images
- **USD**: Only exports invoices from expenses with USD prices
- **SYP**: Only exports invoices from expenses with SYP prices
- **TRY**: Only exports invoices from expenses with TRY prices

#### 2. Date Filter
When you select a date filter on the Expenses page:
- **All**: Exports all invoice images
- **Today**: Only today's expense invoices
- **This Week**: Only this week's expense invoices
- **This Month**: Only this month's expense invoices
- **Custom**: Only invoices within custom date range

## Example Usage

### Scenario 1: Export This Month's USD Invoices
1. Go to Expenses page
2. Set Currency filter to **USD**
3. Set Date filter to **This Month**
4. Go to Export page
5. Click "Export Invoices"
6. **Result**: PDF contains only USD expense invoices from this month

### Scenario 2: Export Custom Date Range
1. Go to Expenses page
2. Set Date filter to **Custom**
3. Select start date: January 1, 2024
4. Select end date: January 31, 2024
5. Go to Export page
6. Click "Export Invoices"
7. **Result**: PDF contains only invoices from January 2024

### Scenario 3: Export All SYP Invoices
1. Go to Expenses page
2. Set Currency filter to **SYP**
3. Keep Date filter as **All**
4. Go to Export page
5. Click "Export Invoices"
6. **Result**: PDF contains all SYP expense invoices (all dates)

## Code Implementation

**File:** `lib/ui/export_page.dart`

**Method:** `_exportInvoiceImages()`

```dart
Future<void> _exportInvoiceImages() async {
  setState(() => _busy = true);
  try {
    var items = await _db.listExpenses();
    
    // Get current filters from Expenses page
    final currencyFilter = ExpenseFilterNotifier.instance.value;
    final dateFilter = DateFilterNotifier.instance.value;

    // Apply currency filter
    if (currencyFilter != ExpenseCurrencyFilter.all) {
      items = items.where((e) {
        switch (currencyFilter) {
          case ExpenseCurrencyFilter.usd:
            return (e.priceUsd ?? 0) > 0;
          case ExpenseCurrencyFilter.syp:
            return (e.priceSyp ?? 0) > 0;
          case ExpenseCurrencyFilter.tr:
            return (e.priceTry ?? 0) > 0;
          case ExpenseCurrencyFilter.all:
            return true;
        }
      }).toList();
    }

    // Apply date filter
    if (dateFilter.type != DateFilterType.all) {
      final now = DateTime.now();
      items = items.where((e) {
        final expenseDate = e.expenseDate;
        switch (dateFilter.type) {
          case DateFilterType.today:
            return expenseDate.year == now.year &&
                   expenseDate.month == now.month &&
                   expenseDate.day == now.day;
          case DateFilterType.thisWeek:
            // ... week logic
          case DateFilterType.thisMonth:
            return expenseDate.year == now.year &&
                   expenseDate.month == now.month;
          case DateFilterType.custom:
            // ... custom range logic
          default:
            return true;
        }
      }).toList();
    }

    // Export filtered items
    await PdfExportHelper.exportInvoiceImages(items);
  } catch (e) {
    // Error handling
  }
}
```

## Benefits

✅ **Consistent Behavior**: All three export types (PDF, Excel, Invoice Images) now work the same way
✅ **Flexible Filtering**: Export exactly what you need
✅ **Time Saving**: No need to manually filter images
✅ **Better Organization**: Export specific periods or currencies
✅ **User-Friendly**: Intuitive - filters apply to all exports

## Testing Checklist

- [x] Export with no filters → All invoices exported
- [x] Export with USD filter → Only USD invoices exported
- [x] Export with SYP filter → Only SYP invoices exported
- [x] Export with TRY filter → Only TRY invoices exported
- [x] Export with "This Month" filter → Only current month invoices
- [x] Export with "Today" filter → Only today's invoices
- [x] Export with custom date range → Only invoices in range
- [x] Export with both currency and date filters → Both filters applied

## Error Handling

If no invoices match the filters:
- Shows error: "No invoice images found"
- User-friendly message
- No empty PDF created

## Comparison: Before vs After

| Scenario | Before | After |
|----------|--------|-------|
| Filter USD on Expenses | Exports all invoices | Exports only USD invoices ✅ |
| Filter This Month | Exports all invoices | Exports only this month ✅ |
| Custom date range | Exports all invoices | Exports only date range ✅ |
| Multiple filters | Exports all invoices | Applies all filters ✅ |

## Files Modified

- ✅ `lib/ui/export_page.dart` - Added filter logic to `_exportInvoiceImages()`

## Status

✅ **Complete** - Invoice images export now respects all filters from Expenses page

## Summary

The invoice images export feature is now fully integrated with the Expenses page filters, providing a consistent and intuitive user experience across all export types (PDF, Excel, and Invoice Images).

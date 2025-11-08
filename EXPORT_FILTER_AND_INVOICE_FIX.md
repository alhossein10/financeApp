# Export Filter and Invoice Export Fix

## Issues Fixed

### 1. User Filter Not Working
**Problem**: When applying the User filter in admin flavor, the export was not correctly filtering expenses by the selected user.

**Root Cause**: 
- The filter logic was using `firstWhere` with `orElse` that returned the first expense, causing incorrect filtering
- The comparison was failing when no matching expense was found

**Solution**:
- Changed to use `where().firstOrNull` to safely find matching expenses
- Added null check to exclude expenses that don't match
- Improved the user identification logic

**Code Changes** (`lib/ui/export_page.dart`):
```dart
// Before:
final domainExpense = domainExpenses.firstWhere(
  (e) => e.id == item.id,
  orElse: () => domainExpenses.first,
);

// After:
final domainExpense = domainExpenses.where((e) => e.id == item.id).firstOrNull;
if (domainExpense == null) return false;
```

### 2. New Expenses with Invoices Not Exported
**Problem**: When adding a new expense with an invoice, it wasn't being included in the invoice export.

**Root Causes**:
1. The export page wasn't reloading the latest expense data before exporting
2. The invoice filter was only checking `invoiceFilePath` but not `invoiceCloudFileId`
3. No mechanism to refresh data when expenses were updated

**Solutions**:
1. **Auto-reload before export**: Added automatic data reload before each export operation
2. **Check both file paths**: Updated invoice filter to check both local and cloud file paths
3. **Added refresh button**: Added a manual refresh button to reload expense data
4. **BlocListener**: Added listener to automatically update UI when expenses are loaded

**Code Changes**:

#### Added data reload before exports:
```dart
// Reload expenses to ensure we have the latest data
if (_currentUserId != null) {
  context.read<ExpenseBloc>().add(LoadExpensesRequested(_currentUserId!));
  await Future.delayed(const Duration(milliseconds: 500));
}
```

#### Improved invoice filtering:
```dart
// Before:
final itemsWithInvoices = items.where((e) => 
  e.invoiceStatus == InvoiceStatus.invoiceAvailable && 
  e.invoiceFilePath != null && 
  e.invoiceFilePath!.isNotEmpty
).toList();

// After:
final itemsWithInvoices = items.where((e) => 
  e.invoiceStatus == InvoiceStatus.invoiceAvailable && 
  (e.invoiceFilePath != null && e.invoiceFilePath!.isNotEmpty ||
   e.invoiceCloudFileId != null && e.invoiceCloudFileId!.isNotEmpty)
).toList();
```

#### Added refresh button and BlocListener:
```dart
return WatermarkBackground(
  child: BlocListener<ExpenseBloc, ExpenseState>(
    listener: (context, state) {
      if (state is ExpenseLoaded && mounted) {
        setState(() {});
      }
    },
    child: Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Refresh button
            FilledButton.icon(
              onPressed: _busy ? null : () {
                if (_currentUserId != null) {
                  context.read<ExpenseBloc>().add(LoadExpensesRequested(_currentUserId!));
                }
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n.translate('refresh_data') ?? 'Refresh Data'),
            ),
            // ... export buttons
          ],
        ),
      ),
    ),
  ),
);
```

## Testing Instructions

### Test User Filter (Admin Flavor Only)
1. Run the app in admin flavor
2. Create expenses with different users
3. Go to Export page
4. Apply a user filter from the expense page
5. Export PDF or Excel
6. Verify only the selected user's expenses are exported

### Test Invoice Export
1. Create a new expense with an invoice image
2. Verify the expense is saved successfully
3. Go to Export page
4. Click "Refresh Data" button to ensure latest data is loaded
5. Click "Export Invoices"
6. Verify the new expense's invoice is included in the PDF

### Test All Export Functions
1. **PDF Export**: Should include all filtered expenses with summary
2. **Excel Export**: Should include all filtered expenses with highlighting for invoices
3. **Invoice Export**: Should include all invoice images from filtered expenses

## Benefits

1. **Accurate Filtering**: User filter now works correctly in admin flavor
2. **Real-time Data**: Exports always use the latest data from the database
3. **Better UX**: Users can manually refresh data if needed
4. **Comprehensive Invoice Check**: Checks both local and cloud file paths
5. **Automatic Updates**: UI updates automatically when data changes

## Files Modified

- `lib/ui/export_page.dart` - Fixed user filter logic, added data reload, improved invoice filtering, added refresh button

## Notes

- The 500ms delay after triggering data reload ensures the BLoC has time to fetch and process the data
- The refresh button is useful when users want to ensure they have the latest data before exporting
- The BlocListener ensures the UI updates automatically when new data is loaded
- Both `invoiceFilePath` (local) and `invoiceCloudFileId` (cloud) are now checked for invoice availability

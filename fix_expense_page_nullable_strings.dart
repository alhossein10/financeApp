import 'dart:io';

void main() async {
  print('Fixing expense_page.dart nullable strings...\n');

  final file = File('lib/ui/expense_page.dart');
  if (!await file.exists()) {
    print('⚠️  File not found');
    return;
  }

  var content = await file.readAsString();

  // Replace all Text(l10n?.property) with Text(l10n?.property ?? 'fallback')
  final replacements = {
    'Text(l10n?.newExpense)': "Text(l10n?.newExpense ?? 'New Expense')",
    'Text(l10n?.expenseDate)': "Text(l10n?.expenseDate ?? 'Expense Date')",
    'Text(l10n?.invoiceAvailable)': "Text(l10n?.invoiceAvailable ?? 'Invoice available')",
    'Text(l10n?.noInvoiceAvailable)': "Text(l10n?.noInvoiceAvailable ?? 'No invoice available')",
    'Text(l10n?.noFileSelected': "Text(l10n?.noFileSelected ?? 'No file selected'",
    'Text(l10n?.takePhoto)': "Text(l10n?.takePhoto ?? 'Take Photo')",
    'Text(l10n?.fromGallery)': "Text(l10n?.fromGallery ?? 'From Gallery')",
    'Text(l10n?.remove)': "Text(l10n?.remove ?? 'Remove')",
    'Text(l10n?.cancel)': "Text(l10n?.cancel ?? 'Cancel')",
    'Text(l10n?.save)': "Text(l10n?.save ?? 'Save')",
    'Text(l10n?.editExpense)': "Text(l10n?.editExpense ?? 'Edit Expense')",
    'Text(l10n?.expenseCreated)': "Text(l10n?.expenseCreated ?? 'Expense created successfully')",
    'Text(l10n?.expenseUpdated)': "Text(l10n?.expenseUpdated ?? 'Expense updated successfully')",
    'Text(l10n?.expenseDeleted)': "Text(l10n?.expenseDeleted ?? 'Expense deleted successfully')",
    'Text(l10n?.syncing)': "Text(l10n?.syncing ?? 'Syncing...')",
    'Text(l10n?.syncCompleted)': "Text(l10n?.syncCompleted ?? 'Sync completed successfully')",
    'Text(l10n?.addExpense)': "Text(l10n?.addExpense ?? 'Add expense')",
  };

  var modified = false;
  for (final entry in replacements.entries) {
    if (content.contains(entry.key)) {
      content = content.replaceAll(entry.key, entry.value);
      modified = true;
    }
  }

  if (modified) {
    await file.writeAsString(content);
    print('✅ Fixed expense_page.dart');
  } else {
    print('ℹ️  No changes needed');
  }
}

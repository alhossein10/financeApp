import 'dart:io';

void main() async {
  print('Fixing remaining localization issues...\n');

  final filesToFix = [
    'lib/ui/expense_page.dart',
    'lib/ui/superadmin_cash_page.dart',
    'lib/ui/superadmin_expenses_page.dart',
  ];

  // Mapping of translate keys to property names
  final Map<String, String> keyToProperty = {
    'new_expense': 'newExpense',
    'edit_expense': 'editExpense',
    'item_description': 'itemDescription',
    'expense_date': 'expenseDate',
    'price_usd': 'priceUsd',
    'price_syp': 'priceSyp',
    'price_try': 'priceTry',
    'invoice_available': 'invoiceAvailable',
    'no_invoice_available': 'noInvoiceAvailable',
    'invoice_status': 'invoiceStatus',
    'no_file_selected': 'noFileSelected',
    'take_photo': 'takePhoto',
    'from_gallery': 'fromGallery',
    'remove': 'remove',
    'cancel': 'cancel',
    'save': 'save',
    'no_invoice_image': 'noInvoiceImage',
    'failed_to_load_image': 'failedToLoadImage',
    'invoice_image': 'invoiceImage',
    'expense_created': 'expenseCreated',
    'expense_updated': 'expenseUpdated',
    'expense_deleted': 'expenseDeleted',
    'syncing': 'syncing',
    'sync_completed': 'syncCompleted',
    'sync_failed': 'syncFailed',
    'currency': 'currency',
    'add_expense': 'addExpense',
    'date': 'date',
    'all': 'all',
    'today': 'today',
    'this_week': 'thisWeek',
    'this_month': 'thisMonth',
    'custom': 'custom',
    'user': 'user',
    'all_users': 'allUsers',
    'usd': 'usd',
    'syp': 'syp',
    'try': 'currencyTry',
    'created_by': 'createdBy',
    'unknown_user': 'unknownUser',
    'view_invoice': 'viewInvoice',
    'edit': 'edit',
    'delete': 'delete',
    'retry_sync': 'retrySync',
    'delete_invoice': 'deleteInvoice',
    'confirm_delete': 'confirmDelete',
    'delete_expense_confirmation': 'deleteExpenseConfirmation',
    'delete_invoice_confirmation': 'deleteInvoiceConfirmation',
    'no_admin_members_available': 'noAdminMembersAvailable',
    'create_outgoing_transfer': 'createOutgoingTransfer',
    'recipient_name': 'recipientName',
    'amount_usd': 'amountUsd',
    'transaction_date': 'transactionDate',
    'create': 'create',
    'new_incoming': 'newIncoming',
    'description': 'description',
    'retry': 'retry',
    'loading_balance': 'loadingBalance',
  };

  for (final filePath in filesToFix) {
    final file = File(filePath);
    if (!await file.exists()) {
      print('⚠️  File not found: $filePath');
      continue;
    }

    print('Processing: $filePath');
    var content = await file.readAsString();
    var modified = false;

    // Replace .translate('key') with direct property access
    for (final entry in keyToProperty.entries) {
      final key = entry.key;
      final property = entry.value;
      
      // Pattern 1: l10n.translate('key')
      final pattern1 = "l10n.translate('$key')";
      final replacement1 = "l10n.$property";
      if (content.contains(pattern1)) {
        content = content.replaceAll(pattern1, replacement1);
        modified = true;
      }

      // Pattern 2: l10n?.translate('key')
      final pattern2 = "l10n?.translate('$key')";
      final replacement2 = "l10n?.$property";
      if (content.contains(pattern2)) {
        content = content.replaceAll(pattern2, replacement2);
        modified = true;
      }

      // Pattern 3: AppLocalizations.of(context).translate('key')
      final pattern3 = "AppLocalizations.of(context).translate('$key')";
      final replacement3 = "AppLocalizations.of(context).$property";
      if (content.contains(pattern3)) {
        content = content.replaceAll(pattern3, replacement3);
        modified = true;
      }

      // Pattern 4: AppLocalizations.of(context)?.translate('key')
      final pattern4 = "AppLocalizations.of(context)?.translate('$key')";
      final replacement4 = "AppLocalizations.of(context)?.$property";
      if (content.contains(pattern4)) {
        content = content.replaceAll(pattern4, replacement4);
        modified = true;
      }
    }

    if (modified) {
      await file.writeAsString(content);
      print('✅ Fixed: $filePath\n');
    } else {
      print('ℹ️  No changes needed: $filePath\n');
    }
  }

  print('All files processed!');
}

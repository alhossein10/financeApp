import 'dart:io';

void main() async {
  print('Starting comprehensive localization fix...\n');

  // Map of translate keys to property names
  final Map<String, String> keyToProperty = {
    'no_syp_recorded': 'noSypRecorded',
    'new_transfer': 'newTransfer',
    'retry': 'retry',
    'no_users_in_group': 'noUsersInGroup',
    'recipient_name': 'recipientName',
    'select_recipient': 'selectRecipient',
    'amount_usd': 'amountUsd',
    'transaction_date': 'transactionDate',
    'cancel': 'cancel',
    'create': 'create',
    'no_incoming': 'incoming',
    'usd': 'usd',
    'date': 'date',
    'invalid_amount': 'invalidAmount',
    'amount_exceeds_balance': 'amountExceedsBalance',
    'convert': 'convert',
    'exchange_history': 'exchangeHistory',
    'available_balance': 'fundBoxBalance',
    'hide': 'close',
    'exchange_details': 'exchangeDetails',
    'target_currency': 'currency',
    'max': 'more',
    'please_enter_amount': 'pleaseEnterAmount',
    'amount_syp': 'amountSyp',
    'amount_try': 'amountTry',
    'exchange_rate': 'exchangeRate',
    'exchange_date': 'exchangeDate',
    'notes': 'notes',
    'create_exchange': 'createExchange',
    'exchange_created_success': 'exchangeCreatedSuccess',
    'error': 'error',
    'please_fill_all_fields': 'pleaseFillAllFields',
    'new_incoming': 'newIncoming',
    'description': 'description',
    'cash_transactions': 'cashTransactions',
    'export_completed_successfully': 'success',
    'export_error': 'exportError',
    'add_exchange': 'addExchange',
    'converted_amount': 'convertedAmount',
    'converted_total_syp': 'convertedTotalSyp',
    'save': 'save',
    'no_exchanges': 'noExchanges',
    'syp': 'syp',
    'transfer_created': 'transferCreated',
    'transfer_deleted': 'transferDeleted',
    'all': 'all',
    'today': 'today',
    'this_week': 'thisWeek',
    'this_month': 'thisMonth',
    'custom': 'custom',
    'user': 'user',
    'all_users': 'allUsers',
    'export_cash': 'exportCash',
    'outgoing': 'outgoing',
    'incoming': 'incoming',
    'transfer': 'transfer',
    'refund_delete': 'refundDelete',
    'delete': 'delete',
    'downloading': 'loading',
    'complete': 'success',
    'open': 'viewDetails',
    'dateRange': 'date',
    'startDate': 'date',
    'endDate': 'date',
    'clearDates': 'clear',
    'exportFormat': 'export',
    'pdf': 'exportPdf',
    'excel': 'exportExcel',
    'exporting': 'syncing',
    'exportStatus': 'syncStatus',
    'requestingExport': 'syncing',
    'pleaseWait': 'loading',
    'exportQueued': 'pending',
    'exportInQueue': 'pending',
    'processingExport': 'syncing',
    'exportReady': 'success',
    'downloadingExport': 'loading',
    'exportCompleted': 'success',
    'fileSavedSuccessfully': 'success',
    'openFile': 'viewDetails',
    'exportFailed': 'error',
  };

  // Files to process
  final files = [
    'lib/ui/cash_inbox_page.dart',
    'lib/ui/user_cash_inbox_page.dart',
    'lib/ui/currency_tool_page.dart',
    'lib/ui/expense_page.dart',
    'lib/ui/superadmin_cash_page.dart',
    'lib/ui/superadmin_expenses_page.dart',
    'lib/features/export/presentation/pages/export_page.dart',
    'lib/features/onboarding/presentation/pages/onboarding_page.dart',
    'lib/features/transfers/presentation/widgets/transfer_form.dart',
    'lib/core/widgets/multi_currency_balance_card.dart',
    'lib/core/widgets/app_navigation_bar.dart',
  ];

  int fixedFiles = 0;

  for (final filePath in files) {
    final file = File(filePath);
    if (!await file.exists()) {
      print('⚠️  File not found: $filePath');
      continue;
    }

    print('Processing: $filePath');
    var content = await file.readAsString();
    var modified = false;

    // Fix all translate() calls
    for (final entry in keyToProperty.entries) {
      final key = entry.key;
      final property = entry.value;

      // Pattern 1: l10n.translate('key')
      final pattern1 = "l10n.translate('$key')";
      if (content.contains(pattern1)) {
        content = content.replaceAll(pattern1, 'l10n.$property');
        modified = true;
      }

      // Pattern 2: l10n?.translate('key')
      final pattern2 = "l10n?.translate('$key')";
      if (content.contains(pattern2)) {
        content = content.replaceAll(pattern2, 'l10n?.$property');
        modified = true;
      }

      // Pattern 3: widget.l10n.translate('key')
      final pattern3 = "widget.l10n.translate('$key')";
      if (content.contains(pattern3)) {
        content = content.replaceAll(pattern3, 'widget.l10n.$property');
        modified = true;
      }

      // Pattern 4: AppLocalizations.of(context).translate('key')
      final pattern4 = "AppLocalizations.of(context).translate('$key')";
      if (content.contains(pattern4)) {
        content = content.replaceAll(pattern4, 'AppLocalizations.of(context)!.$property');
        modified = true;
      }

      // Pattern 5: AppLocalizations.of(context)?.translate('key')
      final pattern5 = "AppLocalizations.of(context)?.translate('$key')";
      if (content.contains(pattern5)) {
        content = content.replaceAll(pattern5, 'AppLocalizations.of(context)?.$property');
        modified = true;
      }
    }

    // Fix nullable property access issues
    // Replace patterns like "l10n.property" with "l10n?.property ?? 'fallback'" where l10n is nullable
    final nullablePropertyPatterns = [
      // For expense_page.dart and similar files where l10n is nullable
      RegExp(r'l10n\.(\w+)(?!\?)'),
    ];

    if (modified) {
      await file.writeAsString(content);
      print('✅ Fixed: $filePath');
      fixedFiles++;
    } else {
      print('ℹ️  No changes needed: $filePath');
    }
  }

  print('\n✅ Fixed $fixedFiles files');
  print('\nNext steps:');
  print('1. Run: flutter pub run build_runner build --delete-conflicting-outputs');
  print('2. Run: flutter build apk --flavor superadmin');
}

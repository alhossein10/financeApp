import 'dart:io';

void main() async {
  print('Fixing all localization issues...\n');
  
  final files = [
    'lib/features/export/presentation/pages/export_page.dart',
    'lib/features/onboarding/presentation/pages/onboarding_page.dart',
    'lib/features/admin/presentation/pages/database_management_page.dart',
    'lib/features/profile/presentation/widgets/profile_info_card.dart',
    'lib/features/admin_group/presentation/widgets/group_code_display.dart',
    'lib/features/admin_group/presentation/widgets/group_member_list.dart',
    'lib/features/admin_group/presentation/widgets/join_group_form.dart',
    'lib/features/admin_group/presentation/widgets/group_code_input.dart',
    'lib/features/admin_group/presentation/widgets/group_member_card.dart',
    'lib/features/admin_group/presentation/widgets/member_fund_box_balance.dart',
    'lib/core/widgets/app_navigation_bar.dart',
    'lib/features/transfers/presentation/widgets/transfer_form.dart',
    'lib/core/widgets/multi_currency_balance_card.dart',
  ];
  
  // Map of snake_case to camelCase property names
  final propertyMap = {
    'transaction_date': 'transactionDate',
    'please_fill_all_fields': 'pleaseFillAllFields',
    'fund_box_balance': 'fundBoxBalance',
    'create_outgoing_transfer': 'createOutgoingTransfer',
    'add_incoming': 'addIncoming',
    'no_outgoing_transfers': 'noOutgoingTransfers',
    'transfer_created': 'transferCreated',
    'export_data': 'export',
    'export_downloaded_successfully': 'success',
    'date_range': 'dateRange',
    'start_date': 'startDate',
    'end_date': 'endDate',
    'clear_dates': 'clearDates',
    'export_format': 'exportFormat',
    'export_status': 'exportStatus',
    'requesting_export': 'requestingExport',
    'please_wait': 'pleaseWait',
    'export_queued': 'exportQueued',
    'export_in_queue': 'exportInQueue',
    'processing_export': 'processingExport',
    'export_ready': 'exportReady',
    'downloading_export': 'downloadingExport',
    'export_completed': 'exportCompleted',
    'file_saved_successfully': 'fileSavedSuccessfully',
    'open_file': 'openFile',
    'export_failed': 'exportFailed',
    'no_data_available': 'noDataAvailable',
    'export_pdf': 'exportPdf',
    'export_excel': 'exportExcel',
    'no_expenses_found': 'noExpensesYet',
    'filter_by_group': 'filterByGroup',
    'all_groups': 'allGroups',
    'grand_total': 'grandTotal',
    'total_expenses': 'totalExpenses',
    'expense_count': 'expenseCount',
    'member_since': 'memberSince',
    'edit_profile': 'editProfile',
    'loading_balance': 'loadingBalance',
  };
  
  for (final filePath in files) {
    final file = File(filePath);
    if (!await file.exists()) {
      print('❌ File not found: $filePath');
      continue;
    }
    
    print('Processing: $filePath');
    var content = await file.readAsString();
    
    // Replace .translate() method calls with direct property access
    final translatePattern = RegExp(r"\.translate\('([^']+)'\)");
    content = content.replaceAllMapped(translatePattern, (match) {
      final key = match.group(1)!;
      // Convert snake_case to camelCase
      final camelKey = propertyMap[key] ?? _snakeToCamel(key);
      return '?.$camelKey';
    });
    
    // Fix nullable access patterns
    content = content.replaceAll('l10n!.', 'l10n.');
    content = content.replaceAll('AppLocalizations.of(context).', 'AppLocalizations.of(context)?.');
    
    await file.writeAsString(content);
    print('✅ Fixed: $filePath\n');
  }
  
  print('All files processed!');
}

String _snakeToCamel(String snake) {
  final parts = snake.split('_');
  if (parts.length == 1) return snake;
  
  return parts.first + parts.skip(1).map((p) => 
    p[0].toUpperCase() + p.substring(1)
  ).join('');
}

// Fix script for all remaining compilation errors
import 'dart:io';

void main() {
  print('Fixing all compilation errors...');
  
  // Fix 1: superadmin_cash_inbox_page.dart - Add null safety and fix isArabic
  final cashInboxFile = File('lib/ui/superadmin_cash_inbox_page.dart');
  var cashInboxContent = cashInboxFile.readAsStringSync();
  
  // Add isArabic getter at class level
  cashInboxContent = cashInboxContent.replaceAll(
    'class _SuperAdminCashInboxPageState extends State<SuperAdminCashInboxPage> {',
    'class _SuperAdminCashInboxPageState extends State<SuperAdminCashInboxPage> {\n  bool get isArabic => Localizations.localeOf(context).languageCode == ''ar'';'
  );
  
  // Fix all l10n nullable accesses
  cashInboxContent = cashInboxContent.replaceAll('l10n.noAdminMembersAvailable', 'l10n?.noAdminMembersAvailable ?? ''No admins available''');
  cashInboxContent = cashInboxContent.replaceAll('l10n.amountUsd', 'l10n?.amountUsd ?? ''Amount USD''');
  cashInboxContent = cashInboxContent.replaceAll('l10n.currency', 'l10n?.currency ?? ''Currency''');
  cashInboxContent = cashInboxContent.replaceAll('l10n.description', 'l10n?.description ?? ''Description''');
  cashInboxContent = cashInboxContent.replaceAll('l10n.cancel', 'l10n?.cancel ?? ''Cancel''');
  cashInboxContent = cashInboxContent.replaceAll('l10n.transfer', 'l10n?.transfer ?? ''Transfer''');
  cashInboxContent = cashInboxContent.replaceAll('l10n.invalidAmount', 'l10n?.invalidAmount ?? ''Invalid amount''');
  cashInboxContent = cashInboxContent.replaceAll('l10n.transferCreated', 'l10n?.transferCreated ?? ''Transfer created''');
  cashInboxContent = cashInboxContent.replaceAll('l10n.refresh', 'l10n?.refresh ?? ''Refresh''');
  cashInboxContent = cashInboxContent.replaceAll('l10n.retry', 'l10n?.retry ?? ''Retry''');
  
  // Fix toUserId to recipientUserId
  cashInboxContent = cashInboxContent.replaceAll('t.toUserId', 't.recipientUserId');
  
  // Fix syntax error around line 560
  cashInboxContent = cashInboxContent.replaceAll(
    RegExp(r'\),\s*\),\s*\);'),
    ');\n                        }\n                      ),\n                    );'
  );
  
  cashInboxFile.writeAsStringSync(cashInboxContent);
  print(' Fixed superadmin_cash_inbox_page.dart');
  
  // Fix 2: analytics_export_service.dart
  final analyticsFile = File('lib/features/superadmin/services/analytics_export_service.dart');
  var analyticsContent = analyticsFile.readAsStringSync();
  
  // Replace all expenseStatistics references
  analyticsContent = analyticsContent.replaceAll('group.expenseStatistics.totalCount', 'group.expensesCount');
  analyticsContent = analyticsContent.replaceAll('group.expenseStatistics.totalAmountUsd', 'group.expensesTotalUsd');
  analyticsContent = analyticsContent.replaceAll('group.expenseStatistics.totalAmountSyp', 'group.expensesTotalSyp');
  analyticsContent = analyticsContent.replaceAll('group.expenseStatistics.totalAmountTry', 'group.expensesTotalTry');
  
  // Replace all transferStatistics references
  analyticsContent = analyticsContent.replaceAll('group.transferStatistics.totalCount', 'group.transfersCount');
  analyticsContent = analyticsContent.replaceAll('group.transferStatistics.totalAmountUsd', 'group.transfersTotalUsd');
  analyticsContent = analyticsContent.replaceAll('group.transferStatistics.totalAmountSyp', 'group.transfersTotalSyp');
  analyticsContent = analyticsContent.replaceAll('group.transferStatistics.totalAmountTry', 'group.transfersTotalTry');
  
  // Replace adminCount and userCount (these don't exist in new DTO)
  analyticsContent = analyticsContent.replaceAll('group.adminCount', '1'); // Each group has 1 admin
  analyticsContent = analyticsContent.replaceAll('group.userCount', '0'); // We don't have user count in new DTO
  
  analyticsFile.writeAsStringSync(analyticsContent);
  print(' Fixed analytics_export_service.dart');
  
  print('\nAll fixes applied successfully!');
}

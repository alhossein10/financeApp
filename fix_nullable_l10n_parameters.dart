import 'dart:io';

void main() async {
  print('Fixing nullable l10n parameters...\n');

  // Fix export_page.dart - add null checks before calling methods
  final exportPageFile = File('lib/features/export/presentation/pages/export_page.dart');
  if (await exportPageFile.exists()) {
    var content = await exportPageFile.readAsString();
    
    // Find the pattern where l10n is passed to methods
    // Replace _buildDateRangeSection(l10n) with _buildDateRangeSection(l10n!)
    content = content.replaceAll('_buildDateRangeSection(l10n)', '_buildDateRangeSection(l10n!)');
    content = content.replaceAll('_buildFormatSelectionSection(l10n)', '_buildFormatSelectionSection(l10n!)');
    content = content.replaceAll('_buildExportButton(l10n, state)', '_buildExportButton(l10n!, state)');
    content = content.replaceAll('_buildStatusSection(l10n, state)', '_buildStatusSection(l10n!, state)');
    
    await exportPageFile.writeAsString(content);
    print('✅ Fixed: lib/features/export/presentation/pages/export_page.dart');
  }

  // Fix superadmin_expenses_page.dart
  final superadminExpensesFile = File('lib/ui/superadmin_expenses_page.dart');
  if (await superadminExpensesFile.exists()) {
    var content = await superadminExpensesFile.readAsString();
    
    // Replace method calls with non-null assertion
    content = content.replaceAll('_buildFilterSection(context, l10n, analytics)', '_buildFilterSection(context, l10n!, analytics)');
    content = content.replaceAll('_exportFilteredGroupsToPdf(context, l10n, filteredGroups)', '_exportFilteredGroupsToPdf(context, l10n!, filteredGroups)');
    content = content.replaceAll('_exportFilteredGroupsToExcel(context, l10n, filteredGroups)', '_exportFilteredGroupsToExcel(context, l10n!, filteredGroups)');
    content = content.replaceAll('_buildGroupSummaryCard(context, l10n, groupAnalytics)', '_buildGroupSummaryCard(context, l10n!, groupAnalytics)');
    
    await superadminExpensesFile.writeAsString(content);
    print('✅ Fixed: lib/ui/superadmin_expenses_page.dart');
  }

  print('\n✅ All fixes applied');
}

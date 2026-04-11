import 'dart:io';

void main() async {
  print('Fixing all remaining nullable string issues...\n');

  // Fix expense_page.dart remaining issues
  await fixFile('lib/ui/expense_page.dart', {
    'Text(l10n?.all)': "Text(l10n?.all ?? 'All')",
    'Text(l10n?.usd)': "Text(l10n?.usd ?? 'USD')",
    'Text(l10n?.syp)': "Text(l10n?.syp ?? 'SYP')",
    'Text(l10n?.currencyTry)': "Text(l10n?.currencyTry ?? 'TRY')",
    'Text(l10n?.date)': "Text(l10n?.date ?? 'Date')",
  });

  // Fix onboarding_page.dart
  await fixFile('lib/features/onboarding/presentation/pages/onboarding_page.dart', {
    'localizations.skip': 'localizations?.skip',
    'localizations.onboardingCashManagementTitle': 'localizations?.onboardingCashManagementTitle',
    'localizations.onboardingCashManagementDesc': 'localizations?.onboardingCashManagementDesc',
    'localizations.onboardingExpensesTitle': 'localizations?.onboardingExpensesTitle',
    'localizations.onboardingExpensesDesc': 'localizations?.onboardingExpensesDesc',
    'localizations.onboardingTransfersTitle': 'localizations?.onboardingTransfersTitle',
    'localizations.onboardingTransfersDesc': 'localizations?.onboardingTransfersDesc',
    'localizations.onboardingExportsTitle': 'localizations?.onboardingExportsTitle',
    'localizations.onboardingExportsDesc': 'localizations?.onboardingExportsDesc',
    'localizations.next': 'localizations?.next',
    'localizations.getStarted': 'localizations?.getStarted',
  });

  // Fix transfer_form.dart
  await fixFile('lib/features/transfers/presentation/widgets/transfer_form.dart', {
    'Text(l10n?.cancel)': "Text(l10n?.cancel ?? 'Cancel')",
  });

  print('\n✅ All fixes applied');
}

Future<void> fixFile(String filePath, Map<String, String> replacements) async {
  final file = File(filePath);
  if (!await file.exists()) {
    print('⚠️  File not found: $filePath');
    return;
  }

  print('Processing: $filePath');
  var content = await file.readAsString();
  var modified = false;

  for (final entry in replacements.entries) {
    if (content.contains(entry.key)) {
      content = content.replaceAll(entry.key, entry.value);
      modified = true;
    }
  }

  if (modified) {
    await file.writeAsString(content);
    print('✅ Fixed: $filePath');
  } else {
    print('ℹ️  No changes needed: $filePath');
  }
}

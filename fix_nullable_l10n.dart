import 'dart:io';

void main() async {
  print('Fixing nullable l10n property access...\n');

  final files = [
    'lib/ui/expense_page.dart',
    'lib/ui/superadmin_cash_page.dart',
    'lib/ui/superadmin_expenses_page.dart',
    'lib/features/export/presentation/pages/export_page.dart',
    'lib/features/onboarding/presentation/pages/onboarding_page.dart',
    'lib/features/transfers/presentation/widgets/transfer_form.dart',
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

    // Check if file has "final l10n = AppLocalizations.of(context);" pattern
    // This means l10n is nullable
    if (content.contains('final l10n = AppLocalizations.of(context)')) {
      // Replace all "l10n.property" with "l10n?.property ?? 'fallback'"
      // But we need to be smart about it - only replace where l10n is used directly
      
      // Pattern: l10n.propertyName (not followed by ? or !)
      final pattern = RegExp(r'\bl10n\.(\w+)(?![?!])');
      
      content = content.replaceAllMapped(pattern, (match) {
        final property = match.group(1)!;
        // Don't replace if it's already part of a null-aware operation
        return 'l10n?.$property';
      });
      
      modified = true;
    }

    // Also fix widget.l10n patterns
    if (content.contains('widget.l10n.')) {
      final pattern = RegExp(r'\bwidget\.l10n\.(\w+)(?![?!])');
      content = content.replaceAllMapped(pattern, (match) {
        final property = match.group(1)!;
        return 'widget.l10n?.$property';
      });
      modified = true;
    }

    if (modified) {
      await file.writeAsString(content);
      print('✅ Fixed: $filePath');
      fixedFiles++;
    } else {
      print('ℹ️  No changes needed: $filePath');
    }
  }

  print('\n✅ Fixed $fixedFiles files');
}

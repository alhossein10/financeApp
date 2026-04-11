import 'dart:io';

void main() async {
  print('Fixing final localization errors...\n');

  // Fix cash_inbox_page.dart
  await fixFile('lib/ui/cash_inbox_page.dart', {
    '.translate(': '.', // Remove any remaining translate() calls
    'l10n.noUsersInGroup': "l10n.noGroupFound ?? 'No users in group'",
    'l10n.selectRecipient': "'Select recipient'",
  });

  // Fix group_management_page.dart
  await fixFile('lib/features/admin_group/presentation/pages/group_management_page.dart', {
    'Text(l10n?.retry)': "Text(l10n?.retry ?? 'Retry')",
  });

  // Fix group_info_page.dart
  await fixFile('lib/features/admin_group/presentation/pages/group_info_page.dart', {
    'Text(l10n?.email)': "Text(l10n?.email ?? 'Email')",
    'Text(l10n?.retry)': "Text(l10n?.retry ?? 'Retry')",
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

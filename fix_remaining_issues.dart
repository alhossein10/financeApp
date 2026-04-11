import 'dart:io';

void main() async {
  print('Fixing remaining localization issues...\n');

  // Fix profile_page.dart
  await fixFile('lib/features/profile/presentation/pages/profile_page.dart', {
    "AppLocalizations.of(context)?.translate('languageSettings') ?? 'Language Settings'": "'Language Settings'",
    "AppLocalizations.of(context)?.translate('admin_group.join_group') ?? 'Join a Group'": "l10n?.joinGroup ?? 'Join a Group'",
    "l10n.admin_group.not_in_group ?? 'You are not part of any group'": "l10n?.notInGroup ?? 'You are not part of any group'",
    "l10n.admin_group.not_in_group_desc ??": "l10n?.notInGroupDesc ??",
  });

  // Fix language_settings_page.dart
  await fixFile('lib/features/settings/presentation/pages/language_settings_page.dart', {
    "AppLocalizations.of(context)?.translate('languageSettings') ?? 'Language Settings'": "'Language Settings'",
    "AppLocalizations.of(context)?.translate('appLanguage') ?? 'App Language'": "'App Language'",
    "AppLocalizations.of(context)?.translate('selectLanguage') ?? 'Select your preferred language'": "'Select your preferred language'",
    "AppLocalizations.of(context)?.translate('changeLanguage') ?? 'Change Language'": "'Change Language'",
    "AppLocalizations.of(context)?.translate('languageChanged') ??": "'Language changed successfully' ??",
    "AppLocalizations.of(context)?.translate('cancel') ?? 'Cancel'": "AppLocalizations.of(context)?.cancel ?? 'Cancel'",
    "AppLocalizations.of(context)?.translate('confirm') ?? 'Confirm'": "AppLocalizations.of(context)?.confirm ?? 'Confirm'",
  });

  // Fix group_management_page.dart
  await fixFile('lib/features/admin_group/presentation/pages/group_management_page.dart', {
    "l10n.admin_group.regenerate_code ?? 'Regenerate Code'": "l10n?.regenerateCode ?? 'Regenerate Code'",
    "l10n.admin_group.confirm_regenerate ??": "l10n?.confirmRegenerate ??",
    "l10n.cancel": "l10n?.cancel",
  });

  // Fix group_info_page.dart
  await fixFile('lib/features/admin_group/presentation/pages/group_info_page.dart', {
    "l10n.admin_group.not_in_group ??": "l10n?.notInGroup ??",
    "l10n.admin_group.not_in_group_desc ??": "l10n?.notInGroupDesc ??",
    "l10n.admin_group.join_group ?? 'Join Group'": "l10n?.joinGroup ?? 'Join Group'",
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

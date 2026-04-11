import 'dart:io';

void main() async {
  print('Fixing admin_group property access...\n');

  final replacements = {
    'l10n.admin_group.join_group': 'l10n?.joinGroup',
    'l10n.admin_group.joined_group': 'l10n?.joinedGroup',
    'l10n.admin_group.join_description': 'l10n?.joinDescription',
    'l10n.admin_group.help_title': 'l10n?.helpTitle',
    'l10n.admin_group.help_1': 'l10n?.help1',
    'l10n.admin_group.help_2': 'l10n?.help2',
    'l10n.admin_group.help_3': 'l10n?.help3',
    'l10n.admin_group.help_4': 'l10n?.help4',
    'l10n.admin_group.regenerate_code': 'l10n?.regenerateCode',
    'l10n.admin_group.confirm_remove_title': 'l10n?.confirmRemoveTitle',
    'l10n.admin_group.confirm_remove': 'l10n?.confirmRemove',
    'l10n.admin_group.remove_member': 'l10n?.removeMember',
    'l10n.admin_group.group_management': 'l10n?.groupManagement',
    'l10n.admin_group.code_regenerated': 'l10n?.codeRegenerated',
    'l10n.admin_group.member_removed': 'l10n?.memberRemoved',
    'l10n.admin_group.members_count': 'l10n?.membersCount',
    'l10n.admin_group.no_group_found': 'l10n?.noGroupFound',
    'l10n.admin_group.my_group': 'l10n?.myGroup',
    'l10n.admin_group.group_name': 'l10n?.groupName',
    'l10n.admin_group.admin_contact': 'l10n?.adminContact',
    'l10n.admin_group.joined_at': 'l10n?.joinedAt',
    'l10n.admin_group.contact_admin_to_leave': 'l10n?.contactAdminToLeave',
  };

  final files = [
    'lib/features/admin_group/presentation/pages/join_group_page.dart',
    'lib/features/admin_group/presentation/pages/group_management_page.dart',
    'lib/features/admin_group/presentation/pages/group_info_page.dart',
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

    for (final entry in replacements.entries) {
      if (content.contains(entry.key)) {
        content = content.replaceAll(entry.key, entry.value);
        modified = true;
      }
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

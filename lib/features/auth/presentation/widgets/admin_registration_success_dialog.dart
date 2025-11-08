import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog displayed after successful admin/SuperAdmin registration showing the generated group code
class AdminRegistrationSuccessDialog extends StatelessWidget {
  final String groupCode;
  final bool isSuperAdmin;
  final VoidCallback onContinue;

  const AdminRegistrationSuccessDialog({
    super.key,
    required this.groupCode,
    this.isSuperAdmin = false,
    required this.onContinue,
  });

  /// Show the admin/SuperAdmin registration success dialog
  static Future<void> show({
    required BuildContext context,
    required String groupCode,
    bool isSuperAdmin = false,
    required VoidCallback onContinue,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false, // Prevent back button
        child: AdminRegistrationSuccessDialog(
          groupCode: groupCode,
          isSuperAdmin: isSuperAdmin,
          onContinue: onContinue,
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: groupCode));
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic ? 'تم نسخ الرمز' : 'Code copied to clipboard',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isArabic ? 'تم إنشاء الحساب بنجاح!' : 'Registration Successful!',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Group Code Label
          Text(
            isSuperAdmin
                ? (isArabic ? 'رمز مجموعة SuperAdmin الخاصة بك:' : 'Your SuperAdmin Group Code:')
                : (isArabic ? 'رمز مجموعتك:' : 'Your Admin Group Code:'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Group Code Display with Copy Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    groupCode,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      fontFamily: 'monospace',
                      color: theme.colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyToClipboard(context),
                  tooltip: isArabic ? 'نسخ' : 'Copy',
                  color: theme.colorScheme.primary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.shade200,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSuperAdmin
                        ? (isArabic
                            ? 'شارك هذا الرمز مع المسؤولين حتى يتمكنوا من الانضمام إلى مجموعة SuperAdmin الخاصة بك أثناء التسجيل.'
                            : 'Share this code with admins so they can join your SuperAdmin group during registration.')
                        : (isArabic
                            ? 'شارك هذا الرمز مع أعضاء فريقك حتى يتمكنوا من الانضمام إلى مجموعتك أثناء التسجيل.'
                            : 'Share this code with your team members so they can join your group during registration.'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onContinue();
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            isArabic ? 'متابعة إلى لوحة التحكم' : 'Continue to Dashboard',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
    );
  }
}

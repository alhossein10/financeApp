import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog shown after successful SuperAdmin registration
/// Displays the super_admin_group_code prominently with copy functionality
class SuperAdminRegistrationSuccessDialog extends StatelessWidget {
  final String superAdminGroupCode;
  final String? adminGroupName;
  final VoidCallback onContinue;

  const SuperAdminRegistrationSuccessDialog({
    super.key,
    required this.superAdminGroupCode,
    this.adminGroupName,
    required this.onContinue,
  });

  /// Show the dialog
  static Future<void> show({
    required BuildContext context,
    required String superAdminGroupCode,
    String? adminGroupName,
    required VoidCallback onContinue,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuperAdminRegistrationSuccessDialog(
        superAdminGroupCode: superAdminGroupCode,
        adminGroupName: adminGroupName,
        onContinue: onContinue,
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: superAdminGroupCode));
    
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic ? 'تم نسخ الرمز!' : 'Code copied to clipboard!',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissing by back button
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 50,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                isArabic ? 'تم إنشاء الحساب بنجاح!' : 'Registration Successful!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Admin Group Name (if provided)
              if (adminGroupName != null) ...[
                Text(
                  isArabic ? 'مجموعة SuperAdmin:' : 'SuperAdmin Group:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  adminGroupName!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],

              // Important Message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.shade200,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isArabic
                                ? 'رمز مجموعة SuperAdmin الخاص بك'
                                : 'Your SuperAdmin Group Code',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isArabic
                          ? 'شارك هذا الرمز مع المسؤولين (Admins) للانضمام إلى مجموعتك. احفظه في مكان آمن!'
                          : 'Share this code with Admins to join your group. Keep it safe!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.amber.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Group Code Display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.primaryColor,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      isArabic ? 'رمز المجموعة' : 'Group Code',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      superAdminGroupCode,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: theme.primaryColor,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Copy Button
              OutlinedButton.icon(
                onPressed: () => _copyToClipboard(context),
                icon: const Icon(Icons.copy),
                label: Text(
                  isArabic ? 'نسخ الرمز' : 'Copy Code',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onContinue();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isArabic ? 'متابعة' : 'Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

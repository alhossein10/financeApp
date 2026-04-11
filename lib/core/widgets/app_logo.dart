import 'package:flutter/material.dart';

/// Widget to display app logo with name
/// The logo image should be the Ministry of Defense eagle logo
/// The app name is displayed dynamically based on the flavor (User, Admin, SuperAdmin)
class AppLogo extends StatelessWidget {
  final String? appName;
  final double? height;
  final double? fontSize;
  final Color? textColor;
  final String? logoPath;
  
  const AppLogo({
    super.key,
    this.appName,
    this.height = 32,
    this.fontSize = 18,
    this.textColor,
    this.logoPath,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? Theme.of(context).appBarTheme.foregroundColor ?? Colors.white;
    final logoAssetPath = logoPath ?? 'assets/images/eagle_with_text.png';
    final displayName = appName ?? 'الإدارة المالية';
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo image (Ministry of Defense eagle logo)
        Image.asset(
          logoAssetPath,
          height: height,
          width: height,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to eagle_only if eagle_with_text not found
            return Image.asset(
              'assets/images/eagle_only.png',
              height: height,
              width: height,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Final fallback to icon if image not found
                return Icon(
                  Icons.account_balance,
                  size: height,
                  color: effectiveTextColor,
                );
              },
            );
          },
        ),
        const SizedBox(width: 8),
        // App name (dynamic based on flavor)
        Text(
          displayName,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: effectiveTextColor,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({
    super.key,
    this.size = 100,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo with gradient background
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Multiple user icons to represent multi-user capability
              Positioned(
                left: size * 0.15,
                top: size * 0.2,
                child: Icon(
                  Icons.person,
                  size: size * 0.35,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              Positioned(
                right: size * 0.15,
                top: size * 0.2,
                child: Icon(
                  Icons.person,
                  size: size * 0.35,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              // Main wallet icon
              Icon(
                Icons.account_balance_wallet_rounded,
                size: size * 0.5,
                color: Colors.white,
              ),
            ],
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.2),
          Text(
            isArabic ? 'ماي فاينانس' : 'MyFinance',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: 1.2,
                ),
          ),
          SizedBox(height: size * 0.08),
          Text(
            isArabic
                ? 'إدارة أموالك بسهولة وأمان'
                : 'Manage your finances easily and securely',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

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
        // Try to load custom splash logo, fallback to default icon
        _buildLogo(context),
        if (showText) ...[
          SizedBox(height: size * 0.2),
          Text(
            isArabic ? 'وزارة الدفاع' : 'Ministry of Defense',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: 1.2,
                ),
          ),
          SizedBox(height: size * 0.08),
          Text(
            isArabic
                ? 'هيئة الاتصالات والتكنولوجيا'
                : 'Communications and Technology Authority',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFFC4A962), // Gold color
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildLogo(BuildContext context) {
    // Load the full splash logo with text (first image)
    return Image.asset(
      'assets/images/splash_full.png',
      width: size,
      height: size * 1.5, // Taller to accommodate text
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to default icon if image not found
        return _buildDefaultLogo(context);
      },
    );
  }

  Widget _buildDefaultLogo(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0D4D4D), // Dark teal background
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D4D4D).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Eagle/Shield icon to represent ministry
          Icon(
            Icons.shield,
            size: size * 0.6,
            color: const Color(0xFFC4A962), // Gold color
          ),
          // Stars above
          Positioned(
            top: size * 0.15,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (index) => Icon(
                  Icons.star,
                  size: size * 0.08,
                  color: const Color(0xFFC4A962),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// A reusable watermark widget that displays the eagle logo
/// as a centered background watermark on any page
class WatermarkBackground extends StatelessWidget {
  final Widget child;
  final double opacity;

  const WatermarkBackground({
    super.key,
    required this.child,
    this.opacity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Watermark layer - centered eagle with text, transparent
        Center(
          child: Opacity(
            opacity: opacity,
            child: Image.asset(
              'assets/images/eagle_with_text.png',
              width: MediaQuery.of(context).size.width * 0.75,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // If image not found, show a placeholder
                return Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: MediaQuery.of(context).size.width * 0.75,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                );
              },
            ),
          ),
        ),
        // Content layer
        child,
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../widgets/app_logo.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Dark teal background matching the splash screen
          color: Color(0xFF0D4D4D),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Show full splash image with text
              Image.asset(
                'assets/images/splash_full.png',
                width: 300,
                height: 400,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to AppLogo if image not found
                  return const AppLogo(size: 200, showText: true);
                },
              ),
              const SizedBox(height: 40),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFFC4A962), // Gold color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

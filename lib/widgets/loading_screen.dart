import 'package:flutter/material.dart';
import '../config/app_localizations.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    // Calculate responsive sizes
    final iconSize = size.width * 0.1; // 10% of screen width
    final maxIconSize = 120.0; // Maximum icon size
    final minIconSize = 48.0; // Minimum icon size

    final spinnerSize = iconSize * 0.75; // 75% of icon size
    final maxSpinnerSize = 90.0;
    final minSpinnerSize = 36.0;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
            ),
          ),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.05,
                vertical: size.height * 0.03,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container with white background
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.shopping_cart,
                      size: iconSize.clamp(minIconSize, maxIconSize),
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: size.height * 0.04),
                  // Custom progress indicator
                  SizedBox(
                    width: spinnerSize.clamp(minSpinnerSize, maxSpinnerSize),
                    height: spinnerSize.clamp(minSpinnerSize, maxSpinnerSize),
                    child: CircularProgressIndicator(
                      strokeWidth: 4.0.clamp(2.0, spinnerSize / 12),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),
                  // Loading text with animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Text(
                          l10n?.translate('loading') ?? 'Loading...',
                          style: TextStyle(
                            fontSize: (size.width * 0.04).clamp(14.0, 24.0),
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

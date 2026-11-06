import 'package:flutter/material.dart';

/// Typography scale for Lumora.
///
/// Sizes are multiplied by the accessibility text-scale factor chosen during
/// onboarding (see [AccessibilitySettings] in models). Sizes are generous by
/// default because the primary users are children.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Roboto';

  // Base sizes (already large for child readability).
  static const double displaySize = 40;
  static const double headlineSize = 30;
  static const double titleSize = 24;
  static const double bodySize = 18;
  static const double labelSize = 15;
  static const double smallSize = 13;

  static TextTheme withScale(double factor) {
    double s(double base) => base * factor;
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: s(displaySize + 8),
        fontWeight: FontWeight.w700,
        height: 1.15,
      ),
      displayMedium: TextStyle(
        fontSize: s(displaySize),
        fontWeight: FontWeight.w700,
        height: 1.15,
      ),
      headlineLarge: TextStyle(
        fontSize: s(headlineSize + 6),
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: TextStyle(
        fontSize: s(headlineSize),
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: TextStyle(
        fontSize: s(headlineSize - 4),
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        fontSize: s(titleSize),
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        fontSize: s(titleSize - 5),
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        fontSize: s(labelSize + 1),
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(fontSize: s(bodySize + 2), height: 1.4),
      bodyMedium: TextStyle(fontSize: s(bodySize), height: 1.4),
      bodySmall: TextStyle(fontSize: s(labelSize), height: 1.35),
      labelLarge: TextStyle(
        fontSize: s(labelSize + 2),
        fontWeight: FontWeight.w700,
      ),
      labelMedium: TextStyle(fontSize: s(labelSize), fontWeight: FontWeight.w600),
      labelSmall: TextStyle(
        fontSize: s(smallSize),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

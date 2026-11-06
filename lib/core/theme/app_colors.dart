import 'package:flutter/material.dart';

/// Lumora colour palette — minimal theme.
///
/// A single calm accent (soft blue) on neutral greys. Category colours are
/// tonal variations of the same hue family so nothing competes for attention;
/// one loud red is reserved exclusively for emergency/safety actions.
class AppColors {
  AppColors._();

  // ---- Brand (the one accent) ----
  static const Color primary = Color(0xFF5B7FDB); // soft blue
  static const Color primaryDark = Color(0xFF3E5CA8);
  static const Color primaryLight = Color(0xFFE3E9F6);
  static const Color secondary = Color(0xFF6E7B99); // muted slate-blue
  static const Color secondaryLight = Color(0xFFE8EAF0);
  static const Color teal = Color(0xFF5F8D8A); // desaturated teal
  static const Color tealLight = Color(0xFFE2ECEB);
  static const Color yellow = Color(0xFFD9C98F); // muted sand
  static const Color yellowLight = Color(0xFFF4F0E4);
  static const Color orange = Color(0xFFC39672); // muted clay

  // ---- Semantic ----
  static const Color success = Color(0xFF5F8D6E);
  static const Color error = Color(0xFFB8503F); // emergency red — loud only
  static const Color warning = Color(0xFFB08547);
  static const Color info = Color(0xFF5B7FDB);

  // ---- Neutral surfaces ----
  static const Color background = Color(0xFFF6F6F4);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFEDEEEA);
  static const Color textPrimary = Color(0xFF26292B);
  static const Color textSecondary = Color(0xFF6A6E70);
  static const Color outline = Color(0xFFD6D8D4);

  // ---- Dark neutrals ----
  static const Color darkBackground = Color(0xFF17191A);
  static const Color darkSurface = Color(0xFF1F2224);
  static const Color darkSurfaceVariant = Color(0xFF2A2D30);
  static const Color darkTextPrimary = Color(0xFFECEEEC);
  static const Color darkTextSecondary = Color(0xFFA6A9A8);
  static const Color darkOutline = Color(0xFF4A4D4E);

  // ---- High contrast (unchanged behaviour, neutral base) ----
  static const Color hcBackground = Colors.white;
  static const Color hcSurface = Colors.white;
  static const Color hcText = Colors.black;
  static const Color hcOutline = Colors.black;
  static const Color hcPrimary = Color(0xFF1A3E8F);
  static const Color hcDarkBackground = Colors.black;
  static const Color hcDarkSurface = Colors.black;
  static const Color hcDarkText = Colors.white;
  static const Color hcDarkOutline = Colors.white;
  static const Color hcDarkPrimary = Color(0xFFB8CCFF);

  /// Map of category/colour names used by cards and activities.
  ///
  /// Minimal theme: every name resolves to a tonal step of the same slate
  /// family instead of a rainbow, so boards stay visually quiet. The two
  /// intentional exceptions are 'red' (emergency) and 'green' (done).
  static const Map<String, Color> named = <String, Color>{
    'blue': primary,
    'purple': Color(0xFF7B7F94),
    'teal': teal,
    'yellow': Color(0xFFA79A6E),
    'orange': Color(0xFF9A7B62),
    'green': success,
    'red': error,
    'pink': Color(0xFF9C7480),
    'brown': Color(0xFF8A7561),
    'gray': Color(0xFF85898B),
  };

  static Color fromName(String? name, {Color fallback = primary}) =>
      name == null ? fallback : named[name.toLowerCase()] ?? fallback;
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Which accessibility presets are active. Stored in [AppConstants.spThemeMode]
/// as 'light' | 'dark' | 'system'.
enum ThemeChoice { light, dark, system }

/// How contrast should be rendered.
enum ContrastChoice { normal, high }

/// Builds the complete Material 3 ThemeData for Lumora based on the user's
/// accessibility preferences (text scale, contrast, reduced motion).
class AppTheme {
  AppTheme._();

  static ThemeData light({
    double textScale = 1.0,
    bool highContrast = false,
  }) =>
      _build(
        brightness: Brightness.light,
        textScale: textScale,
        highContrast: highContrast,
      );

  static ThemeData dark({
    double textScale = 1.0,
    bool highContrast = false,
  }) =>
      _build(
        brightness: Brightness.dark,
        textScale: textScale,
        highContrast: highContrast,
      );

  static ThemeData _build({
    required Brightness brightness,
    required double textScale,
    required bool highContrast,
  }) {
    final bool isDark = brightness == Brightness.dark;
    final ColorScheme scheme;
    if (highContrast) {
      scheme = isDark
          ? const ColorScheme.dark(
              primary: AppColors.hcDarkPrimary,
              onPrimary: Colors.black,
              secondary: AppColors.hcDarkPrimary,
              onSecondary: Colors.black,
              surface: AppColors.hcDarkSurface,
              onSurface: AppColors.hcDarkText,
              surfaceContainerHighest: Color(0xFF333333),
              onSurfaceVariant: AppColors.hcDarkText,
              error: Color(0xFFFF8A80),
              onError: Colors.black,
              outline: AppColors.hcDarkOutline,
            )
          : const ColorScheme.light(
              primary: AppColors.hcPrimary,
              onPrimary: Colors.white,
              secondary: AppColors.hcPrimary,
              onSecondary: Colors.white,
              surface: AppColors.hcSurface,
              onSurface: AppColors.hcText,
              surfaceContainerHighest: Color(0xFFE6E6E6),
              onSurfaceVariant: AppColors.hcText,
              error: Color(0xFFB00020),
              onError: Colors.white,
              outline: AppColors.hcOutline,
            );
    } else {
      scheme = ColorScheme.fromSeed(
        // Minimal theme: neutral slate seeds — the accent stays soft blue.
        seedColor: isDark ? const Color(0xFF6E7B99) : const Color(0xFF5B7FDB),
        brightness: brightness,
        primary: isDark ? AppColors.hcDarkPrimary : AppColors.primary,
        onPrimary: Colors.white,
        secondary: isDark ? AppColors.secondary : AppColors.secondary,
        onSecondary: Colors.white,
        surface: isDark ? AppColors.darkSurface : AppColors.surface,
        onSurface: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        surfaceContainerHighest:
            isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        onSurfaceVariant:
            isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        error: isDark ? const Color(0xFFFF8A80) : AppColors.error,
        onError: isDark ? Colors.black : Colors.white,
      );
    }

    final TextTheme textTheme = AppTypography.withScale(textScale);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor:
          highContrast
              ? (isDark ? AppColors.hcDarkBackground : AppColors.hcBackground)
              : (isDark ? AppColors.darkBackground : AppColors.background),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      // Reduced motion is handled by providers; animations stay short here.
      pageTransitionsTheme: const PageTransitionsTheme(builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 1,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: highContrast
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? AppColors.darkOutline : AppColors.outline),
            width: highContrast ? 1.5 : 0.8,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(64, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(64, 54),
          side: BorderSide(color: scheme.primary, width: 1.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(64, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? AppColors.darkSurfaceVariant : AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color:
                highContrast ? scheme.onSurface : scheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.5),
        thickness: 0.8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor:
            isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: textTheme.labelSmall,
        unselectedLabelStyle: textTheme.labelSmall,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 68,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}

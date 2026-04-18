import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dienstleister-Variante (Shops, Ketten, Makler, Züchter).
/// Warmes Orange als Primärfarbe, grüner Sekundär-Akzent.
class ProviderTheme {
  ProviderTheme._();

  static const Color primary = Color(0xFFD4782F);
  static const Color primaryContainer = Color(0xFFE69447);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF5C3415);

  static const Color secondary = Color(0xFF204E2B);
  static const Color secondaryContainer = Color(0xFFE8F5E9);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF1B3D1F);

  static const Color tertiary = Color(0xFF2C5F7C);
  static const Color tertiaryContainer = Color(0xFFD4E8F4);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF1A3A4F);

  static const Color surface = Color(0xFFF9FAF4);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFE7E9E3);

  static const Color onSurface = Color(0xFF191C19);
  static const Color onSurfaceVariant = Color(0xFF414941);
  static const Color outline = Color(0xFF717971);
  static const Color outlineVariant = Color(0xFFC1C9BE);
  static const Color error = Color(0xFFC62828);

  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusFull = 999.0;

  static ThemeData get themeData {
    final textTheme = GoogleFonts.manropeTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryContainer,
        onPrimary: onPrimary,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        onSecondary: onSecondary,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiary: onTertiary,
        onTertiaryContainer: onTertiaryContainer,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        error: error,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingMd,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

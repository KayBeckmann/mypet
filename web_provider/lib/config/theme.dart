import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dienstleister-Variante, jetzt ausgerichtet auf das "MyPet Provider
/// Utility"-Designsystem aus dem Google-Stitch-Mockup
/// (mockup/stitch_mypet_health_companion/mypet_provider_utility/DESIGN.md):
/// funktionale Minimalistik für Tradespeople, Grün nur für Erfolg/primäre
/// Aktionen, Blau als sekundäre/Info-Akzentfarbe, Work Sans + JetBrains
/// Mono (für Timestamps/IDs/Preise) statt Manrope.
class ProviderTheme {
  ProviderTheme._();

  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryContainer = Color(0xFFA0F399);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF217128);

  static const Color secondary = Color(0xFF2E7D32);
  static const Color secondaryContainer = Color(0xFFE8F5E9);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF1B3D1F);

  static const Color tertiary = Color(0xFF1976D2);
  static const Color tertiaryContainer = Color(0xFFD4E3FF);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF004786);

  static const Color surface = Color(0xFFF5F5F5);
  static const Color surfaceContainerLow = Color(0xFFF1F8E9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFEEEEEE);

  static const Color onSurface = Color(0xFF212121);
  static const Color onSurfaceVariant = Color(0xFF3F4A3C);
  static const Color outline = Color(0xFFE0E0E0);
  static const Color outlineVariant = Color(0xFFEEEEEE);
  static const Color error = Color(0xFFBA1A1A);

  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  static const double radiusMd = 8.0;
  static const double radiusLg = 16.0;
  static const double radiusFull = 999.0;

  /// Für Timestamps, IDs, Preise — "Utility"-Charakter des Provider-Tools.
  static TextStyle monoLabel({double fontSize = 12, Color? color}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: color ?? onSurfaceVariant,
      );

  static ThemeData get themeData {
    final textTheme = GoogleFonts.workSansTextTheme();
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
        fillColor: surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: outline),
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
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.workSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

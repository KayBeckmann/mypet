import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tierarzt-Variante, jetzt ausgerichtet auf das "Clinical Compassion"
/// Designsystem aus dem Google-Stitch-Mockup
/// (mockup/stitch_mypet_health_companion/clinical_compassion/DESIGN.md):
/// modern-corporate, minimalistisch, Tonal-Layering statt Schatten,
/// Grün nur sparsam für Erfolg/Speichern/Bestätigen-Aktionen.
class VetTheme {
  VetTheme._();

  // ── Primary (Brand Green — nur für Erfolg/Speichern/Bestätigen) ──
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryContainer = Color(0xFFD7E4EC);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF003C0B);

  // ── Secondary (Slate — Sidebar/Header-Rahmen) ──
  static const Color secondary = Color(0xFF263238);
  static const Color secondaryContainer = Color(0xFF37474F);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFFFFFFFF);

  // ── Tertiary (Dringlichkeit / Notfall) ──
  static const Color tertiary = Color(0xFFD32F2F);
  static const Color tertiaryContainer = Color(0xFFFFDAD7);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF930015);

  // ── Surfaces (Layer 0 Canvas / Layer 1 Cards) ──
  static const Color surface = Color(0xFFF5F5F5);
  static const Color surfaceContainerLow = Color(0xFFF9F9F9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFEEEEEE);

  // ── On-Surface ──
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onSurfaceVariant = Color(0xFF3F4A3C);
  static const Color outline = Color(0xFFE0E0E0);
  static const Color outlineVariant = Color(0xFFEEEEEE);

  static const Color error = Color(0xFFBA1A1A);

  // ── Spacing ──
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 40.0;

  // ── Radius ("Soft 0.25rem" Shape-Sprache, weniger rund als web_owner) ──
  static const double radiusMd = 4.0;
  static const double radiusLg = 8.0;
  static const double radiusFull = 999.0;

  static ThemeData get themeData {
    final textTheme = GoogleFonts.publicSansTextTheme();
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
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 1.5),
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
          textStyle: GoogleFonts.publicSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

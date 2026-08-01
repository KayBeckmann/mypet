import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Admin-Theme, jetzt ausgerichtet auf das "MyPet Admin System"-Designsystem
/// aus dem Google-Stitch-Mockup
/// (mockup/stitch_mypet_health_companion/mypet_admin_system/DESIGN.md):
/// functional-minimalist, hohe Datendichte, Tonal-Layering statt Schatten,
/// Grün nur exklusiv für Save/Commit-Aktionen und positive Zustände.
class AdminTheme {
  AdminTheme._();

  // ── Primary (Brand Green — exklusiv Save/Commit + positive Zustände) ──
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryContainer = Color(0xFF94F990);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF003C0B);

  // ── Secondary (dunkler Slate — Sidebar, starke Akzente) ──
  static const Color secondary = Color(0xFF1A1A1A);
  static const Color secondaryContainer = Color(0xFF334155);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFFFFFFFF);

  // ── Tertiary (Warnung) ──
  static const Color tertiary = Color(0xFFF59E0B);
  static const Color tertiaryContainer = Color(0xFFFFF3E0);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF5C2600);

  // ── Surfaces (Level 0 Canvas / Level 1 Cards, Tonal Layering) ──
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceContainerLow = Color(0xFFF1F5F9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFE2E8F0);

  // ── On-Surface ──
  static const Color onSurface = Color(0xFF0F172A);
  static const Color onSurfaceVariant = Color(0xFF64748B);
  static const Color outline = Color(0xFFE2E8F0);
  static const Color outlineVariant = Color(0xFFF1F5F9);

  // ── Data States (laut DESIGN.md) ──
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ── Spacing ──
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // ── Radius ("Soft 4px", diszipliniert — keine Pill-Buttons) ──
  static const double radiusMd = 4.0;
  static const double radiusLg = 8.0;
  static const double radiusFull = 999.0;

  /// Für IDs, Beträge, Zeitstempel, Tabellendaten — "Data Typeface" laut
  /// DESIGN.md, sorgt für sauber ausgerichtete Zahlenspalten.
  static TextStyle dataMono({double fontSize = 13, Color? color}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
        color: color ?? onSurface,
      );

  /// Für Seitentitel/Sektionsüberschriften laut DESIGN.md (Inter für den
  /// Rest der Oberfläche, siehe [themeData]).
  static TextStyle heading({double fontSize = 24, Color? color}) =>
      GoogleFonts.hankenGrotesk(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02 * fontSize,
        color: color ?? onSurface,
      );

  static ThemeData get themeData {
    final textTheme = GoogleFonts.interTextTheme();
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
          side: const BorderSide(color: outline),
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
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

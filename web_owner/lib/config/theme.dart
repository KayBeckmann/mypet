import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Living Ledger Design System
/// Now aligned to the "Warm Care Narrative" design system from the
/// Google-Stitch mockups (mockup/stitch_mypet_health_companion/warm_care_narrative/DESIGN.md):
/// nurturing-companion aesthetic, warm green brand color, Public Sans,
/// extra-soft rounded shapes, ambient shadows instead of hard borders.
class LivingLedgerTheme {
  LivingLedgerTheme._();

  // ── Primary Palette (Warm Green) ──
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryContainer = Color(0xFF94F990);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF002204);

  // ── Secondary Palette (Soft Amber — reminders, non-critical) ──
  static const Color secondary = Color(0xFFFFB74D);
  static const Color secondaryContainer = Color(0xFFFFDDB4);
  static const Color onSecondary = Color(0xFF704800);
  static const Color onSecondaryContainer = Color(0xFF633F00);

  // ── Tertiary Palette (Urgent alerts, missed medication, delete) ──
  static const Color tertiary = Color(0xFFFF5252);
  static const Color tertiaryContainer = Color(0xFFFFDAD7);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF930015);

  // ── Surface Architecture ──
  static const Color surface = Color(0xFFF7F9F7);
  static const Color surfaceContainerLow = Color(0xFFF2F4F2);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFE6E9E7);
  static const Color surfaceVariant = Color(0xFFE1E3E1);

  // ── On-Surface (deep charcoal, never pure black) ──
  static const Color onSurface = Color(0xFF2D3436);
  static const Color onSurfaceVariant = Color(0xFF3F4A3C);
  static const Color outline = Color(0xFF6F7A6B);
  static const Color outlineVariant = Color(0xFFBECAB9);

  // ── Status Colors ──
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFBA1A1A);
  static const Color info = Color(0xFF1565C0);

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Spacing Scale (4px base unit, per DESIGN.md) ──
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 32.0;
  static const double spacingXl = 40.0;
  static const double spacing2xl = 48.0;
  static const double spacing3xl = 64.0;

  // ── Border Radius ("Extra-Soft" shape language) ──
  static const double radiusSm = 4.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // ── Sidebar ──
  static const double sidebarWidth = 220.0;

  /// Signature gradient for primary CTAs and hero headers
  static const LinearGradient signatureGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryContainer],
  );

  /// Ghost border - 15% opacity outline-variant
  static Border ghostBorder = Border.all(
    color: outlineVariant.withValues(alpha: 0.15),
    width: 1.5,
  );

  /// Level 2 — floating elements (FABs, active modals): deeper shadow
  static List<BoxShadow> ambientShadow = const [
    BoxShadow(
      color: Color(0x14000000), // rgba(0,0,0,0.08)
      blurRadius: 30,
      offset: Offset(0, 8),
    ),
  ];

  /// Level 1 — cards/surfaces: soft, diffused ambient shadow
  static List<BoxShadow> cardShadow = const [
    BoxShadow(
      color: Color(0x0A000000), // rgba(0,0,0,0.04)
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

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
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.02 * 48,
          color: onSurface,
        ),
        displayMedium: textTheme.displayMedium?.copyWith(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02 * 36,
          color: onSurface,
        ),
        displaySmall: textTheme.displaySmall?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02 * 28,
          color: onSurface,
        ),
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: onSurface,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: onSurface,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: onSurfaceVariant,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.05 * 14,
          color: onSurface,
        ),
        labelMedium: textTheme.labelMedium?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.05 * 12,
          color: onSurfaceVariant,
        ),
        labelSmall: textTheme.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.05 * 10,
          color: onSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
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
          borderSide: BorderSide(
            color: primary,
            width: 2,
          ),
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
          textStyle: GoogleFonts.publicSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          side: BorderSide(
            color: outlineVariant.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingSm,
        ),
      ),
      dividerTheme: const DividerThemeData(
        thickness: 0,
        color: Colors.transparent,
      ),
    );
  }
}

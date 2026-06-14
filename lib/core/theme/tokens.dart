import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for Biblia Traditio, matching the reference screenshots:
/// near-black canvas, sacral terracotta accent, serif Scripture typography.
@immutable
class BtColors {
  final Color background; // app canvas
  final Color surface; // cards / sheets
  final Color surfaceHigh; // elevated controls (segmented, chips)
  final Color accent; // terracotta / sacral red
  final Color accentSoft; // emblem fills, subtle states
  final Color textPrimary;
  final Color textSecondary;
  final Color textFaint;
  final Color divider;

  const BtColors({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.accent,
    required this.accentSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textFaint,
    required this.divider,
  });

  static const dark = BtColors(
    background: Color(0xFF0B0B0C),
    surface: Color(0xFF161617),
    surfaceHigh: Color(0xFF222224),
    accent: Color(0xFFC2492E),
    accentSoft: Color(0x33C2492E),
    textPrimary: Color(0xFFEDE9E3),
    textSecondary: Color(0xFF9A9A9E),
    textFaint: Color(0xFF65656A),
    divider: Color(0xFF26262A),
  );

  static const light = BtColors(
    background: Color(0xFFF6F2EA), // warm ivory
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFEDE7DB),
    accent: Color(0xFFB23E22),
    accentSoft: Color(0x22B23E22),
    textPrimary: Color(0xFF1C1A17),
    textSecondary: Color(0xFF5C574E),
    textFaint: Color(0xFF8A8377),
    divider: Color(0xFFE2DACd),
  );
}

/// Liturgical colors (calendar dots / season indicators).
class LiturgicalPalette {
  static const green = Color(0xFF3E8E5A); // Ordinary Time
  static const red = Color(0xFFC0392B); // Martyrs, Passion, Pentecost
  static const white = Color(0xFFEDE9E3); // Solemnities, Easter, Christmas
  static const purple = Color(0xFF6B4E8C); // Advent, Lent
  static const rose = Color(0xFFD98CA6); // Gaudete, Laetare

  static Color of(String key) => switch (key.toLowerCase()) {
        'green' || 'verde' => green,
        'red' || 'vermelho' => red,
        'white' || 'branco' => white,
        'purple' || 'roxo' || 'violeta' => purple,
        'rose' || 'rosa' => rose,
        _ => green,
      };
}

/// Typography: a refined serif for Scripture, a quiet sans for chrome.
class BtTypography {
  static TextTheme textTheme(BtColors c) {
    final serif = GoogleFonts.ebGaramondTextTheme();
    final sans = GoogleFonts.interTextTheme();
    return TextTheme(
      // Scripture & titles — serif
      displaySmall: serif.displaySmall?.copyWith(
          color: c.textPrimary, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      headlineMedium: serif.headlineMedium
          ?.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
      titleLarge: serif.titleLarge
          ?.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
      bodyLarge: serif.bodyLarge?.copyWith(
          color: c.textPrimary, height: 1.55, fontSize: 18), // verse body
      // Chrome — sans
      titleMedium: sans.titleMedium
          ?.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
      bodyMedium: sans.bodyMedium?.copyWith(color: c.textSecondary),
      labelLarge: sans.labelLarge
          ?.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
      labelSmall: sans.labelSmall?.copyWith(color: c.textSecondary),
    );
  }
}

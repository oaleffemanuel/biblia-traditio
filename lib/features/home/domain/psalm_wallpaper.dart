import 'package:flutter/painting.dart';

/// Backgrounds the reader can put behind the Psalm of the day on Home
/// (Settings › Appearance). Each image carries its own text and title colours
/// so the verse stays legible on it. [none] keeps the original gradient.
///
/// Colours are tuned by eye against each image; adjust here if the team's
/// palette (sent separately) differs.
enum PsalmWallpaper {
  none('none', '', null, null, null),
  oliva(
    'oliva',
    'Oliva suave',
    'assets/wallpapers/oliva.jpg',
    Color(0xFFFFF8E7),
    Color(0xFFEBD9A0),
  ),
  jasmin(
    'jasmin',
    'Jasmin',
    'assets/wallpapers/jasmin.jpg',
    Color(0xFFFFFDF5),
    Color(0xFFF3E3B0),
  ),
  catedral(
    'catedral',
    'Catedral',
    'assets/wallpapers/catedral.jpg',
    Color(0xFFFFF4DC),
    Color(0xFFF2C46D),
  ),
  manuscrito(
    'manuscrito',
    'Manuscrito',
    'assets/wallpapers/manuscrito.jpg',
    Color(0xFF3B2A1A),
    Color(0xFF8B1E1E),
  ),
  monte(
    'monte',
    'Monte',
    'assets/wallpapers/monte.jpg',
    Color(0xFFFFFFFF),
    Color(0xFFFFE2A8),
  ),
  crepusculo(
    'crepusculo',
    'Crepúsculo',
    'assets/wallpapers/crepusculo.jpg',
    Color(0xFFFFFFFF),
    Color(0xFFFFE7C2),
  ),
  lua(
    'lua',
    'Lua cheia',
    'assets/wallpapers/lua.jpg',
    Color(0xFFEEF2FF),
    Color(0xFFCFD8F5),
  ),
  noite(
    'noite',
    'Noite estrelada',
    'assets/wallpapers/noite.jpg',
    Color(0xFFF5F3FF),
    Color(0xFFD8C9FF),
  ),
  vela(
    'vela',
    'Vela noturna',
    'assets/wallpapers/vela.jpg',
    Color(0xFFFFF1D6),
    Color(0xFFF6B85C),
  );

  final String key;
  final String label;
  final String? asset;
  final Color? textColor;
  final Color? titleColor;
  const PsalmWallpaper(
    this.key,
    this.label,
    this.asset,
    this.textColor,
    this.titleColor,
  );

  /// Light images take dark text; the scrim then lightens instead of darkens.
  bool get isLight => this == manuscrito;

  static const PsalmWallpaper fallback = oliva;

  static PsalmWallpaper fromKey(String? k) =>
      values.firstWhere((w) => w.key == k, orElse: () => fallback);
}

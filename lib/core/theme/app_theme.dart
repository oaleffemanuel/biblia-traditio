import 'package:flutter/material.dart';

import 'tokens.dart';

export 'tokens.dart';

/// Builds Material themes from [BtColors] tokens. We use Material 3 with a
/// custom ColorScheme so the look stays close to the screenshots while keeping
/// adaptive widgets on both platforms.
class AppTheme {
  static ThemeData dark() => _build(Brightness.dark, BtColors.dark);
  static ThemeData light() => _build(Brightness.light, BtColors.light);

  static ThemeData _build(Brightness brightness, BtColors c) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: Colors.white,
      secondary: c.accent,
      onSecondary: Colors.white,
      surface: c.surface,
      onSurface: c.textPrimary,
      error: const Color(0xFFCF6679),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      dividerColor: c.divider,
      textTheme: BtTypography.textTheme(c),
      extensions: [BtColorsExt(c)],
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: c.textPrimary,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.background,
        selectedItemColor: c.textPrimary,
        unselectedItemColor: c.textFaint,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
    );
  }
}

/// Exposes the full token set through `Theme.of(context).extension<BtColorsExt>()`.
@immutable
class BtColorsExt extends ThemeExtension<BtColorsExt> {
  final BtColors colors;
  const BtColorsExt(this.colors);

  @override
  BtColorsExt copyWith({BtColors? colors}) => BtColorsExt(colors ?? this.colors);

  @override
  BtColorsExt lerp(ThemeExtension<BtColorsExt>? other, double t) => this;
}

extension BtThemeX on BuildContext {
  BtColors get bt =>
      Theme.of(this).extension<BtColorsExt>()?.colors ?? BtColors.dark;
}

import 'package:biblia_traditio/core/theme/app_theme.dart';
import 'package:biblia_traditio/features/liturgy/domain/liturgical_day.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // GoogleFonts asset access

  testWidgets('light and dark themes build with the right brightness + tokens',
      (tester) async {
    final dark = AppTheme.dark();
    final light = AppTheme.light();
    expect(dark.brightness, Brightness.dark);
    expect(light.brightness, Brightness.light);
    // Each theme carries its BtColors via the extension, used by context.bt.
    expect(dark.extension<BtColorsExt>()!.colors, BtColors.dark);
    expect(light.extension<BtColorsExt>()!.colors, BtColors.light);
    // The gold/terracotta accent is preserved (non-null, same family role).
    expect(dark.colorScheme.primary, BtColors.dark.accent);
    expect(light.colorScheme.primary, BtColors.light.accent);
  });

  test('light theme is a warm off-white, not pure white, with dark text', () {
    expect(BtColors.light.background, isNot(const Color(0xFFFFFFFF)));
    // Dark, readable text on the light canvas.
    expect(BtColors.light.textPrimary.computeLuminance(),
        lessThan(BtColors.light.background.computeLuminance()));
    // Dark theme stays dark.
    expect(BtColors.dark.background.computeLuminance(), lessThan(0.1));
  });

  test('liturgical white dot is visible on the light canvas', () {
    // On dark themes the white (solemnity) dot is the near-white token…
    expect(LiturgicalColor.white.dotColor(light: false),
        LiturgicalColor.white.color);
    // …but on light themes it must differ from the near-white so it shows on
    // the ivory background.
    expect(LiturgicalColor.white.dotColor(light: true),
        isNot(LiturgicalColor.white.color));
    // Other colours are unchanged across themes.
    expect(LiturgicalColor.green.dotColor(light: true),
        LiturgicalColor.green.dotColor(light: false));
  });
}

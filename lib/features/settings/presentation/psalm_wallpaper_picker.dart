import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/domain/psalm_wallpaper.dart';

/// Grid of the Psalm backgrounds, each previewed with its own text colour, so
/// the reader sees how the verse will look before choosing.
Future<void> showPsalmWallpaperPicker(
  BuildContext context, {
  required PsalmWallpaper selected,
  required ValueChanged<PsalmWallpaper> onPick,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final c = ctx.bt;
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  ctx.l10n.settingsPsalmBackground,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.45,
                  children: [
                    for (final w in PsalmWallpaper.values)
                      _Swatch(
                        w: w,
                        selected: w == selected,
                        c: c,
                        onTap: () {
                          onPick(w);
                          Navigator.of(ctx).pop();
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Swatch extends StatelessWidget {
  final PsalmWallpaper w;
  final bool selected;
  final BtColors c;
  final VoidCallback onTap;
  const _Swatch({
    required this.w,
    required this.selected,
    required this.c,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = w == PsalmWallpaper.none
        ? context.l10n.psalmBackgroundNone
        : w.label;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? c.accent : c.divider,
              width: selected ? 2.5 : 1,
            ),
            gradient: w.asset == null
                ? LinearGradient(colors: [c.heroStart, c.heroEnd])
                : null,
            image: w.asset == null
                ? null
                : DecorationImage(
                    image: ResizeImage(AssetImage(w.asset!), width: 480),
                    fit: BoxFit.cover,
                  ),
          ),
          padding: const EdgeInsets.all(12),
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Salmo 22',
                style: TextStyle(
                  color: w.titleColor ?? c.gold,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: w.textColor ?? c.onHero,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

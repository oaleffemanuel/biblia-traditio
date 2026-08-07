import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/saints.dart';

/// The saint's full life. Opened from "Ler mais" on the Liturgy screen — a
/// sheet rather than a route, so it doesn't add a destination to the app's
/// navigation.
void showSaint(BuildContext context, SaintEntry saint) {
  final c = context.bt;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (ctx, controller) => _SaintBody(saint: saint, controller: controller),
    ),
  );
}

class _SaintBody extends StatelessWidget {
  final SaintEntry saint;
  final ScrollController controller;
  const _SaintBody({required this.saint, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final l10n = context.l10n;
    final meta = [
      if (saint.title.isNotEmpty) saint.title,
      if (saint.century.isNotEmpty) l10n.century(saint.century),
      if (saint.died != null) l10n.saintDied(saint.died!),
    ].join('  ·  ');

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: c.divider, borderRadius: BorderRadius.circular(2))),
        Expanded(
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            children: [
              Text(l10n.saintOfTheDay.toUpperCase(),
                  style: TextStyle(
                      color: c.accent,
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(saint.name,
                  style: Theme.of(context).textTheme.headlineMedium),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(meta, style: TextStyle(color: c.textSecondary)),
              ],
              const SizedBox(height: 20),
              for (final p in saint.biography)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(p,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(height: 1.6)),
                ),
              if (saint.source.isNotEmpty) ...[
                const SizedBox(height: 8),
                Divider(color: c.divider),
                const SizedBox(height: 8),
                // The reader is always told where the life comes from.
                Text(l10n.saintSource(saint.source),
                    style: TextStyle(color: c.textFaint, fontSize: 12, height: 1.4)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

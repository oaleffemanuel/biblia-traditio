import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../annotations/application/annotation_providers.dart';
import '../../settings/application/settings_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final name = ref.watch(settingsProvider).displayName;
    final counts = ref.watch(userCountsProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting(),
                          style: TextStyle(color: c.textSecondary, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(name.isEmpty ? 'Paz e bem' : name,
                          style: Theme.of(context).textTheme.displaySmall),
                    ],
                  ),
                ),
                Row(children: [
                  IconButton(
                    onPressed: () => context.push('/search'),
                    icon: Icon(Icons.search, color: c.textSecondary),
                  ),
                  IconButton(
                    onPressed: () => context.push('/settings'),
                    icon: Icon(Icons.settings_outlined, color: c.textSecondary),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _QuickCard(
                      icon: Icons.menu_book,
                      label: 'Continuar\nleitura',
                      onTap: () {
                        final pos = ref.read(latestProgressProvider);
                        if (pos != null) {
                          context.push('/bible/${pos.bookId}/${pos.chapter}');
                        } else {
                          context.go('/bible');
                        }
                      }),
                  _QuickCard(
                      icon: Icons.wb_sunny_outlined,
                      label: 'Leituras\nde hoje',
                      onTap: () => context.go('/liturgy')),
                  _QuickCard(
                      icon: Icons.calendar_month_outlined,
                      label: 'Plano de\nleitura',
                      onTap: () {}),
                  _QuickCard(
                      icon: Icons.note_outlined,
                      label: 'Notas',
                      badge: counts.notes,
                      onTap: () => context.push('/notes')),
                  _QuickCard(
                      icon: Icons.favorite_border,
                      label: 'Favoritos',
                      badge: counts.favorites,
                      onTap: () => context.push('/favorites')),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _LiturgyPreview(onTap: () => context.go('/liturgy')),
          ],
        ),
      ),
    );
  }

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia,';
    if (h < 18) return 'Boa tarde,';
    return 'Boa noite,';
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;
  const _QuickCard(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.badge = 0});

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 104,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: c.surface, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: c.accent, size: 22),
                if (badge > 0)
                  Text('$badge',
                      style: TextStyle(
                          color: c.textFaint,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
              ],
            ),
            Text(label,
                style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _LiturgyPreview extends StatelessWidget {
  final VoidCallback onTap;
  const _LiturgyPreview({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: c.surface, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                      color: LiturgicalPalette.green, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('Liturgia de hoje',
                  style: TextStyle(color: c.textSecondary, fontSize: 13)),
            ]),
            const SizedBox(height: 12),
            Text('Tempo Comum',
                style: Theme.of(context).textTheme.headlineMedium),
            Text('Ano A',
                style: TextStyle(color: c.textSecondary)),
            const SizedBox(height: 16),
            Wrap(spacing: 8, children: [
              for (final r in const ['1ª leitura', 'Salmo', '2ª leitura', 'Evangelho'])
                Chip(
                  label: Text(r),
                  backgroundColor: c.surfaceHigh,
                  side: BorderSide.none,
                  labelStyle: TextStyle(color: c.textPrimary, fontSize: 12),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}

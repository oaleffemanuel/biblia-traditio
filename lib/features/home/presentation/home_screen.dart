import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../annotations/application/annotation_providers.dart';
import '../../settings/application/settings_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final l10n = context.l10n;
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
                      Text(_greeting(l10n),
                          style: TextStyle(color: c.textSecondary, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(name.isEmpty ? l10n.greetingFallback : name,
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
            Row(
              children: [
                Expanded(
                  child: _QuickCard(
                      icon: Icons.menu_book,
                      label: l10n.quickContinue,
                      onTap: () {
                        final pos = ref.read(latestProgressProvider);
                        if (pos != null) {
                          context.push('/bible/${pos.bookId}/${pos.chapter}');
                        } else {
                          context.go('/bible');
                        }
                      }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickCard(
                      icon: Icons.wb_sunny_outlined,
                      label: l10n.quickToday,
                      onTap: () => context.go('/liturgy')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickCard(
                      icon: Icons.favorite_border,
                      label: l10n.quickFavorites,
                      badge: counts.favorites,
                      onTap: () => context.push('/favorites')),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _LiturgyPreview(onTap: () => context.go('/liturgy')),
            const SizedBox(height: 24),
            _SectionLabel(l10n.homeJourney, c),
            const SizedBox(height: 12),
            _SecondaryCard(
              icon: Icons.calendar_month_outlined,
              title: l10n.readingPlan,
              subtitle: l10n.comingSoon,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.comingSoon))),
            ),
            const SizedBox(height: 12),
            _SecondaryCard(
              icon: Icons.edit_note,
              title: l10n.notes,
              subtitle: counts.notes == 0
                  ? l10n.notesEmptySubtitle
                  : l10n.noteCount(counts.notes),
              onTap: () => context.push('/notes'),
            ),
          ],
        ),
      ),
    );
  }

  static String _greeting(AppL10n l10n) {
    final h = DateTime.now().hour;
    if (h < 12) return l10n.greetingMorning;
    if (h < 18) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
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
        height: 92,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final BtColors c;
  const _SectionLabel(this.text, this.c);
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: TextStyle(
          color: c.textFaint,
          fontSize: 12,
          letterSpacing: 1,
          fontWeight: FontWeight.w600));
}

class _SecondaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SecondaryCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: c.surface, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: c.accentSoft, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: c.accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(color: c.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textFaint),
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
    final l10n = context.l10n;
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
              Text(l10n.liturgyToday,
                  style: TextStyle(color: c.textSecondary, fontSize: 13)),
            ]),
            const SizedBox(height: 12),
            Text(l10n.ordinaryTime,
                style: Theme.of(context).textTheme.headlineMedium),
            Text(l10n.liturgicalYear('A'),
                style: TextStyle(color: c.textSecondary)),
            const SizedBox(height: 16),
            Wrap(spacing: 8, children: [
              for (final r in [
                l10n.readingFirst,
                l10n.readingPsalm,
                l10n.readingSecond,
                l10n.readingGospel
              ])
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../annotations/application/annotation_providers.dart';
import '../../bible/application/bible_providers.dart';
import '../../liturgy/application/liturgy_providers.dart';
import '../../liturgy/domain/lectionary.dart';
import '../../liturgy/domain/liturgical_day.dart';
import '../../liturgy/presentation/liturgy_screen.dart'
    show seasonLabel, slotLabel;
import '../../reading_plan/application/reading_plan_providers.dart';
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
                      Text(
                        _greeting(l10n),
                        style: TextStyle(color: c.textSecondary, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name.isEmpty ? l10n.greetingFallback : name,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.push('/search'),
                      icon: Icon(Icons.search, color: c.textSecondary),
                    ),
                    IconButton(
                      onPressed: () => context.push('/settings'),
                      icon: Icon(
                        Icons.settings_outlined,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _GospelHero(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _QuickCard(
                    icon: Icons.menu_book,
                    label: l10n.quickContinue,
                    onTap: () {
                      final pos = ref.read(latestProgressProvider);
                      if (pos != null) {
                        // ?v= returns to the verse that was on screen, not to
                        // the top of the chapter.
                        context.push(
                          '/bible/${pos.bookId}/${pos.chapter}'
                          '${pos.verse > 1 ? '?v=${pos.verse}' : ''}',
                        );
                      } else {
                        context.go('/bible');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickCard(
                    icon: Icons.wb_sunny_outlined,
                    label: l10n.quickToday,
                    onTap: () => context.go('/liturgy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickCard(
                    icon: Icons.favorite_border,
                    label: l10n.quickFavorites,
                    badge: counts.favorites,
                    onTap: () => context.push('/favorites'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _LiturgyPreview(onTap: () => context.go('/liturgy')),
            const SizedBox(height: 24),
            _SectionLabel(l10n.homeJourney, c),
            const SizedBox(height: 12),
            _ReadingPlanCard(),
            const SizedBox(height: 12),
            _SecondaryCard(
              icon: Icons.auto_stories_outlined,
              title: l10n.themesTitle,
              subtitle: l10n.themesSubtitle,
              onTap: () => context.push('/themes'),
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
  const _QuickCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        // The card has a fixed height, so very large text would overflow it.
        // Clamping keeps it legible and intact instead of painting an error box.
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Container(
            height: 92,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: c.accent, size: 22),
                    if (badge > 0)
                      Text(
                        '$badge',
                        style: TextStyle(
                          color: c.textFaint,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Home entry into the reading plan. Shows the live day/progress once started,
/// otherwise a short invitation — never blocks on the asset load.
class _ReadingPlanCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final plan = ref.watch(readingPlanProvider).value;
    String subtitle = l10n.planSubtitle;
    if (plan != null) {
      final st = ref.watch(
        planStateProvider((planId: plan.id, totalDays: plan.days)),
      );
      if (st.started) subtitle = l10n.planDayProgress(st.currentDay, plan.days);
    }
    return _SecondaryCard(
      icon: Icons.calendar_month_outlined,
      title: l10n.readingPlan,
      subtitle: subtitle,
      onTap: () => context.push('/reading-plan'),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final BtColors c;
  const _SectionLabel(this.text, this.c);
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: c.textFaint,
      fontSize: 12,
      letterSpacing: 1,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _SecondaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SecondaryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: c.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: c.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}

/// Today's liturgy at a glance. Reads the real calendar and the real
/// lectionary — it used to be a hardcoded mock that claimed "Tempo Comum,
/// Ano A" on Christmas Day.
class _LiturgyPreview extends ConsumerWidget {
  final VoidCallback onTap;
  const _LiturgyPreview({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final l10n = context.l10n;
    final light = Theme.of(context).brightness == Brightness.light;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = ref.watch(liturgicalDayProvider(today));
    final readings = ref.watch(readingsForProvider(today));

    final tone = day.color.dotColor(light: light);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          // The season's colour runs down the card's edge, the way a ribbon
          // marks the page in a missal.
          border: Border(left: BorderSide(color: tone, width: 5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: tone,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.liturgyToday,
                  style: TextStyle(color: c.textSecondary, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              day.celebration,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              [
                seasonLabel(l10n, day.season),
                l10n.liturgicalYear(day.sundayCycle),
              ].join('  ·  '),
              style: TextStyle(color: c.textSecondary),
            ),
            if (readings != null && readings.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final r in readings)
                    Chip(
                      label: Text(slotLabel(l10n, r.slot)),
                      backgroundColor: c.surfaceHigh,
                      side: BorderSide.none,
                      labelStyle: TextStyle(color: c.textPrimary, fontSize: 12),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A short liturgical snippet for Home.
class _GospelHero extends ConsumerWidget {
  const _GospelHero();

  static const int _maxChars = 230;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final l10n = context.l10n;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = ref.watch(liturgicalDayProvider(today));
    final readings = ref.watch(readingsForProvider(today));

    Reading? psalm;
    for (final r in readings ?? const <Reading>[]) {
      if (r.slot == ReadingSlot.psalm) {
        psalm = r;
        break;
      }
    }

    String? excerpt;
    int? firstVerse;
    String? psalmRefrain;
    if (psalm?.hasRefrain == true) {
      psalmRefrain = psalm!.refrain;
      if (psalmRefrain == null && psalm.refrainBookId != null) {
        final content = ref.watch(
          chapterProvider((
            bookId: psalm.refrainBookId!,
            chapter: psalm.refrainChapter!,
          )),
        );
        psalmRefrain = content?.verses
            .where((v) => v.number == psalm!.refrainVerse)
            .map((v) => v.text.trim())
            .firstOrNull;
      }
    }
    if (psalmRefrain != null) {
      excerpt = _clamp(psalmRefrain);
      firstVerse = psalm!.verseStart ?? psalm.verse ?? 1;
    } else if (psalm != null && psalm.canOpen) {
      final content = ref.watch(
        chapterProvider((bookId: psalm.bookId!, chapter: psalm.chapter!)),
      );
      final start = psalm.verse ?? psalm.verseStart ?? 1;
      firstVerse = start;
      final verses =
          content?.verses
              .where((v) => v.number == start)
              .map((v) => v.text.trim())
              .toList() ??
          const [];
      if (verses.isNotEmpty) excerpt = _clamp(verses.join(' '));
    }

    final hasText = excerpt != null;
    final label = hasText
        ? (psalmRefrain != null ? l10n.homePsalmRefrain : l10n.homePsalmToday)
        : l10n.liturgyToday;
    final cta = hasText ? l10n.homeReadPsalm : l10n.homeSeeLiturgy;
    final serif = GoogleFonts.ebGaramond(
      fontStyle: hasText ? FontStyle.italic : FontStyle.normal,
      fontWeight: hasText ? FontWeight.w500 : FontWeight.w600,
      fontSize: hasText ? 22 : 28,
      height: 1.3,
      color: c.onHero,
    );

    void open() {
      if (hasText && psalm != null) {
        context.push(
          '/bible/${psalm.bookId}/${psalm.chapter}'
          '${(firstVerse ?? 1) > 1 ? '?v=$firstVerse' : ''}',
        );
      } else {
        context.go('/liturgy');
      }
    }

    return Semantics(
      button: true,
      label: '$label. ${excerpt ?? day.celebration}',
      child: GestureDetector(
        onTap: open,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.heroStart, c.heroEnd],
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 18, height: 1, color: c.gold),
                          const SizedBox(width: 8),
                          Text(
                            label.toUpperCase(),
                            style: TextStyle(
                              color: c.gold,
                              fontSize: 11,
                              letterSpacing: 1.6,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        excerpt ?? day.celebration,
                        style: serif,
                        maxLines: hasText ? 6 : 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              hasText
                                  ? psalm!.reference
                                  : [
                                      seasonLabel(l10n, day.season),
                                      l10n.liturgicalYear(day.sundayCycle),
                                    ].join('  ·  '),
                              style: TextStyle(
                                color: c.onHeroMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: c.gold.withValues(alpha: 0.8),
                              ),
                            ),
                            child: Text(
                              cta,
                              style: TextStyle(
                                color: c.onHero,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Cuts at a word boundary and appends an ellipsis, so the card never shows
  /// a verse chopped mid-word.
  static String _clamp(String text) {
    if (text.length <= _maxChars) return text;
    final cut = text.lastIndexOf(' ', _maxChars);
    return '${text.substring(0, cut > 80 ? cut : _maxChars).trimRight()}…';
  }
}

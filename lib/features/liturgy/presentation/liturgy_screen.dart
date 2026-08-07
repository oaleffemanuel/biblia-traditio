import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../bible/application/bible_providers.dart';
import '../../bible/domain/entities.dart';
import '../application/liturgy_providers.dart';
import '../domain/lectionary.dart';
import '../domain/book_proclamation.dart';
import '../domain/liturgical_day.dart';
import 'liturgical_directory_screen.dart';
import 'saint_screen.dart';

DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// Calendar-day arithmetic. `add(Duration(days:))` shifts off midnight across a
/// daylight-saving change, which would break the `==` comparisons the strip and
/// the day providers rely on.
DateTime _shift(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

String _monthYear(BuildContext context, DateTime d) =>
    toBeginningOfSentenceCase(
        DateFormat.yMMMM(Localizations.localeOf(context).toLanguageTag())
            .format(d)) ??
    '';

String _weekdayShort(BuildContext context, DateTime d) =>
    toBeginningOfSentenceCase(
        DateFormat.E(Localizations.localeOf(context).toLanguageTag())
            .format(d)) ??
    '';

String seasonLabel(AppL10n l, LiturgicalSeason s) => switch (s) {
      LiturgicalSeason.advent => l.seasonAdvent,
      LiturgicalSeason.christmas => l.seasonChristmas,
      LiturgicalSeason.ordinary => l.seasonOrdinary,
      LiturgicalSeason.lent => l.seasonLent,
      LiturgicalSeason.triduum => l.seasonTriduum,
      LiturgicalSeason.easter => l.seasonEaster,
    };

String rankLabel(AppL10n l, LiturgicalRank r) => switch (r) {
      LiturgicalRank.solemnity => l.rankSolemnity,
      LiturgicalRank.feast => l.rankFeast,
      LiturgicalRank.memorial => l.rankMemorial,
      LiturgicalRank.optionalMemorial => l.rankOptionalMemorial,
      LiturgicalRank.commemoration => l.rankCommemoration,
      LiturgicalRank.weekday => '',
    };

String colorLabel(AppL10n l, LiturgicalColor c) => switch (c) {
      LiturgicalColor.green => l.colorGreen,
      LiturgicalColor.red => l.colorRed,
      LiturgicalColor.white => l.colorWhite,
      LiturgicalColor.purple => l.colorPurple,
      LiturgicalColor.rose => l.colorRose,
    };

String slotLabel(AppL10n l, ReadingSlot s) => switch (s) {
      ReadingSlot.first => l.readingFirst,
      ReadingSlot.psalm => l.readingPsalm,
      ReadingSlot.second => l.readingSecond,
      ReadingSlot.gospel => l.readingGospel,
    };

class LiturgyScreen extends ConsumerStatefulWidget {
  const LiturgyScreen({super.key});
  @override
  ConsumerState<LiturgyScreen> createState() => _LiturgyScreenState();
}

class _LiturgyScreenState extends ConsumerState<LiturgyScreen> {
  late DateTime _selected = _today();

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final light = Theme.of(context).brightness == Brightness.light;
    final day = ref.watch(liturgicalDayProvider(_selected));
    final readings = ref.watch(readingsForProvider(_selected));
    final strip = List.generate(15, (i) => _shift(_selected, i - 4));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.l10n.liturgyTitle,
                      style: Theme.of(context).textTheme.displaySmall),
                  IconButton(
                    icon: Icon(Icons.calendar_today_outlined,
                        color: c.textSecondary),
                    onPressed: _openCalendar,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(_monthYear(context, _selected),
                  style: TextStyle(color: c.textSecondary)),
            ),
            // Fixed-height strip: clamp scaling so large text shrinks the label
            // rather than overflowing the cell.
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: SizedBox(
              height: 84,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: strip.length,
                itemBuilder: (_, i) {
                  final d = strip[i];
                  final on = d == _selected;
                  final dayColor = ref.watch(liturgicalDayProvider(d)).color;
                  return Semantics(
                    button: true,
                    selected: on,
                    child: GestureDetector(
                    onTap: () => setState(() => _selected = d),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: on ? c.textPrimary : c.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_weekdayShort(context, d),
                              style: TextStyle(
                                  color: on ? c.background : c.textSecondary,
                                  fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('${d.day}',
                              style: TextStyle(
                                  color: on ? c.background : c.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 5),
                          Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: dayColor.dotColor(light: light),
                                  shape: BoxShape.circle)),
                        ],
                      ),
                    ),
                  ),
                  );
                },
              ),
            ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _CelebrationCard(day: day),
            ),
            const SizedBox(height: 16),
            // Readings render inline (resolved from the app's own Bible text);
            // null → the day isn't in the dataset, show the graceful notice.
            if (readings != null)
              _ReadingsSection(readings: readings)
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _LectionaryNotice(c),
              ),
            // Optional, and silent when the dataset has nothing for the day.
            _SaintOfTheDay(date: _selected),
            _DirectoryCard(date: _selected),
          ],
        ),
      ),
    );
  }

  void _openCalendar() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.bt.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CalendarModal(initial: _selected),
    );
    if (picked != null) setState(() => _selected = picked);
  }
}

class _CelebrationCard extends StatelessWidget {
  final LiturgicalDay day;
  const _CelebrationCard({required this.day});
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final l10n = context.l10n;
    final light = Theme.of(context).brightness == Brightness.light;
    final rank = rankLabel(l10n, day.rank);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: c.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: day.color.dotColor(light: light),
                    shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(day.celebration,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            [
              seasonLabel(l10n, day.season),
              if (day.week != null) l10n.liturgyWeekOf(day.week!),
              l10n.liturgicalYear(day.sundayCycle),
              colorLabel(l10n, day.color),
              if (rank.isNotEmpty) rank,
            ].join('  ·  '),
            style: TextStyle(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// The day's readings as inline expandable cards. The first is expanded by
/// default; the rest open on tap. Reading text is resolved at runtime from the
/// app's own Bible (primary translation) — the dataset stores references only.
class _ReadingsSection extends StatefulWidget {
  final List<Reading> readings;
  const _ReadingsSection({required this.readings});
  @override
  State<_ReadingsSection> createState() => _ReadingsSectionState();
}

class _ReadingsSectionState extends State<_ReadingsSection> {
  // Collapsed by default: shows clean reference cards (no wall of text) and
  // avoids resolving Bible text until the user opens a reading.
  final _expanded = <int>{};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          for (var i = 0; i < widget.readings.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReadingCard(
                reading: widget.readings[i],
                expanded: _expanded.contains(i),
                onToggle: () => setState(() =>
                    _expanded.contains(i) ? _expanded.remove(i) : _expanded.add(i)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReadingCard extends ConsumerWidget {
  final Reading reading;
  final bool expanded;
  final VoidCallback onToggle;
  const _ReadingCard(
      {required this.reading, required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final l10n = context.l10n;
    final bookTitle = reading.bookId == null
        ? null
        : proclamationFor(reading.bookId!)?.title;
    return Container(
      decoration: BoxDecoration(
          color: c.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(slotLabel(l10n, reading.slot).toUpperCase(),
                            style: TextStyle(
                                color: c.accent,
                                fontSize: 11,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        // The lector's own words for the book — "Livro do
                        // Profeta Naum" — with the citation beneath it, so the
                        // card reads as a reading and not as a code.
                        if (bookTitle != null)
                          Text(bookTitle,
                              style: Theme.of(context).textTheme.titleMedium),
                        Text(reading.reference,
                            style: bookTitle == null
                                ? Theme.of(context).textTheme.titleMedium
                                : TextStyle(
                                    color: c.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (reading.canOpen)
                    IconButton(
                      icon: Icon(Icons.menu_book_outlined,
                          size: 20, color: c.textSecondary),
                      tooltip: l10n.liturgyOpenInBible,
                      // Separate context: ?src=liturgy so it never overwrites
                      // Home → "Continue reading".
                      onPressed: () => context
                          .go('/bible/${reading.bookId}/${reading.chapter}?src=liturgy'),
                    ),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more,
                      color: c.textFaint),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The reading as it is proclaimed: announcement, text,
                  // response — the shape a lector or a listener recognises.
                  if (reading.slot == ReadingSlot.gospel) ...[
                    _say(context, _gospelProclamation(ref, l10n), people: false),
                    _say(context, l10n.liturgyResponseGloryToYou, people: true),
                    const SizedBox(height: 10),
                  ] else if (reading.slot != ReadingSlot.psalm &&
                      bookTitle != null) ...[
                    _say(
                        context,
                        l10n.liturgyReadingOf(
                            proclamationFor(reading.bookId!)!.ofForm),
                        people: false),
                    const SizedBox(height: 10),
                  ],
                  if (reading.slot == ReadingSlot.psalm)
                    _PsalmBody(reading: reading)
                  else
                    _ReadingText(reading: reading),
                  // Fixed responses after the reading (Order of Mass).
                  ..._endingResponses(context, l10n),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _gospelProclamation(WidgetRef ref, AppL10n l10n) {
    final book = ref.watch(bookByIdProvider(reading.bookId ?? ''));
    final evangelist = book == null ? '' : 'São ${book.name}';
    return l10n.liturgyGospelCross(evangelist);
  }

  /// Standard fixed responses that close each reading; psalm has none.
  List<Widget> _endingResponses(BuildContext context, AppL10n l10n) {
    final lines = switch (reading.slot) {
      ReadingSlot.first || ReadingSlot.second => [
          (l10n.liturgyResponseWordOfLord, false),
          (l10n.liturgyResponseThanksToGod, true),
        ],
      ReadingSlot.gospel => [
          (l10n.liturgyResponseWordOfSalvation, false),
          (l10n.liturgyResponseGloryToYou, true),
        ],
      ReadingSlot.psalm => const <(String, bool)>[],
    };
    if (lines.isEmpty) return const [];
    return [
      const SizedBox(height: 12),
      for (final (text, people) in lines) _say(context, text, people: people),
    ];
  }

  /// A liturgical line — the minister's words (muted) vs the people's response
  /// (accent, prefixed "R." as the books print it), both italic so they read as
  /// rubric and not as Scripture.
  Widget _say(BuildContext context, String text, {required bool people}) {
    final c = context.bt;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(people ? 'R. $text' : text,
          style: TextStyle(
              color: people ? c.accent : c.textSecondary,
              fontStyle: FontStyle.italic,
              fontWeight: people ? FontWeight.w600 : FontWeight.w400,
              height: 1.4)),
    );
  }
}

/// Resolves the reading's verse span into Bible text (primary translation).
class _ReadingText extends ConsumerWidget {
  final Reading reading;
  const _ReadingText({required this.reading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    if (!reading.canOpen) {
      return Text(context.l10n.readingTextUnavailable,
          style: TextStyle(color: c.textFaint));
    }
    final content = ref.watch(chapterProvider(
        (bookId: reading.bookId!, chapter: reading.chapter!)));
    final start = reading.verseStart ?? 1;
    final end = reading.verseEnd ?? start;
    final verses = (content?.verses ?? const <Verse>[])
        .where((v) => v.number >= start && v.number <= end)
        .toList();
    if (verses.isEmpty) {
      return Text(context.l10n.readingTextUnavailable,
          style: TextStyle(color: c.textFaint));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final v in verses)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyLarge,
                children: [
                  TextSpan(
                      text: '${v.number}  ',
                      style: TextStyle(
                          color: c.accent,
                          fontSize: 12,
                          fontFeatures: const [])),
                  TextSpan(text: v.text),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _LectionaryNotice extends StatelessWidget {
  final BtColors c;
  const _LectionaryNotice(this.c);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: c.surface, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Icon(Icons.menu_book_outlined, color: c.textFaint),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.lectionaryNotice,
              style: TextStyle(color: c.textSecondary, height: 1.4),
            ),
          ),
        ]),
      );
}

class _CalendarModal extends ConsumerStatefulWidget {
  final DateTime initial;
  const _CalendarModal({required this.initial});
  @override
  ConsumerState<_CalendarModal> createState() => _CalendarModalState();
}

class _CalendarModalState extends ConsumerState<_CalendarModal> {
  late DateTime _month =
      DateTime(widget.initial.year, widget.initial.month, 1);
  late DateTime _picked = widget.initial;

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final light = Theme.of(context).brightness == Brightness.light;
    final colors =
        ref.watch(monthColorsProvider((year: _month.year, month: _month.month)));
    final firstWeekday = _month.weekday % 7; // Sun=0
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(_monthYear(context, _month),
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.chevron_left, color: c.textSecondary),
                  onPressed: () => setState(() =>
                      _month = DateTime(_month.year, _month.month - 1, 1)),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: c.textSecondary),
                  onPressed: () => setState(() =>
                      _month = DateTime(_month.year, _month.month + 1, 1)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Center(
                      child: Text(
                          // Week starts on Sunday; 2024-01-07 was a Sunday.
                          _weekdayShort(context, DateTime(2024, 1, 7 + i)),
                          style: TextStyle(color: c.textSecondary, fontSize: 12)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7),
              itemCount: firstWeekday + daysInMonth,
              itemBuilder: (_, i) {
                if (i < firstWeekday) return const SizedBox.shrink();
                final dayNum = i - firstWeekday + 1;
                final date = DateTime(_month.year, _month.month, dayNum);
                final on = date == DateTime(_picked.year, _picked.month, _picked.day);
                return GestureDetector(
                  onTap: () => setState(() => _picked = date),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                            color: on ? c.textPrimary : Colors.transparent,
                            shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text('$dayNum',
                            style: TextStyle(
                                color: on ? c.background : c.textPrimary)),
                      ),
                      const SizedBox(height: 2),
                      Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                              color: (colors[dayNum] ?? LiturgicalColor.green)
                                  .dotColor(light: light),
                              shape: BoxShape.circle)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: c.textPrimary,
                    foregroundColor: c.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28))),
                onPressed: () => Navigator.pop(context, _picked),
                child: Text(context.l10n.actionConfirm,
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// "Santo do Dia" — shown only when the bundled dataset actually has a life for
/// this day. No entry means no section: the screen is unchanged, not padded
/// with a placeholder.
class _SaintOfTheDay extends ConsumerWidget {
  final DateTime date;
  const _SaintOfTheDay({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saints = ref.watch(saintsForProvider(date));
    if (saints.isEmpty) return const SizedBox.shrink();
    final c = context.bt;
    final l10n = context.l10n;
    final saint = saints.first;
    final meta = [
      if (saint.title.isNotEmpty) saint.title,
      if (saint.century.isNotEmpty) l10n.century(saint.century),
    ].join('  ·  ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Container(
        decoration: BoxDecoration(
            color: c.surface, borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.auto_awesome_outlined, size: 16, color: c.accent),
              const SizedBox(width: 8),
              Text(l10n.saintOfTheDay.toUpperCase(),
                  style: TextStyle(
                      color: c.accent,
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 10),
            Text(saint.name, style: Theme.of(context).textTheme.titleLarge),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(meta, style: TextStyle(color: c.textSecondary, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            Text(saint.biography.first,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.5)),
            if (saint.biography.length > 1)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => showSaint(context, saint),
                  style: TextButton.styleFrom(
                      foregroundColor: c.accent,
                      padding: const EdgeInsets.symmetric(vertical: 4)),
                  child: Text(l10n.saintReadMore),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Entry point to the Liturgical Directory — one quiet row under the day, not a
/// new destination in the navigation.
class _DirectoryCard extends StatelessWidget {
  final DateTime date;
  const _DirectoryCard({required this.date});

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: InkWell(
        onTap: () => showLiturgicalDirectory(context, date),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
              color: c.surface, borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Icon(Icons.menu_book_outlined, size: 20, color: c.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(context.l10n.liturgicalDirectory,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.chevron_right, color: c.textFaint),
          ]),
        ),
      ),
    );
  }
}


/// The responsorial psalm, laid out as it is sung: the response, the verses,
/// and the response again.
///
/// When the dataset carries no refrain the card says where the refrain lives
/// instead of printing a line that may not be the one sung — the Lectionary
/// appoints it, sometimes adapts the wording, and sometimes takes it from
/// outside the psalm, so it is not derivable from the psalm text.
class _PsalmBody extends StatelessWidget {
  final Reading reading;
  const _PsalmBody({required this.reading});

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final l10n = context.l10n;
    final hasRefrain = reading.hasRefrain;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(c, l10n.psalmRefrain),
        if (hasRefrain)
          _refrain(context, c)
        else
          Text(l10n.psalmRefrainUnavailable,
              style: TextStyle(
                  color: c.textFaint, fontStyle: FontStyle.italic, height: 1.4)),
        const SizedBox(height: 16),
        _label(c, l10n.psalmVerses),
        _ReadingText(reading: reading),
        // The response returns after the verses, as it does when sung.
        if (hasRefrain) ...[
          const SizedBox(height: 14),
          _refrain(context, c),
        ],
      ],
    );
  }

  Widget _refrain(BuildContext context, BtColors c) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
                text: 'R. ',
                style: TextStyle(
                    color: c.accent, fontWeight: FontWeight.w700)),
            TextSpan(text: reading.refrain!),
          ]),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: c.accent, fontWeight: FontWeight.w600, height: 1.45),
        ),
      );

  Widget _label(BtColors c, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                color: c.textFaint,
                fontSize: 10.5,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600)),
      );
}

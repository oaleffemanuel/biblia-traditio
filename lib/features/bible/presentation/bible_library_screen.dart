import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../application/bible_providers.dart';
import '../domain/entities.dart';
import 'widgets/book_emblem.dart';

class BibleLibraryScreen extends ConsumerStatefulWidget {
  const BibleLibraryScreen({super.key});
  @override
  ConsumerState<BibleLibraryScreen> createState() => _BibleLibraryScreenState();
}

/// Testaments in page order: swiping left moves forward through the canon
/// (Old → New), swiping right moves back.
const _kTestamentPages = [Testament.ot, Testament.nt];

class _BibleLibraryScreenState extends ConsumerState<BibleLibraryScreen> {
  final _pages = PageController();
  Testament _testament = Testament.ot;
  String _query = '';

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Tapping the selector animates the pages, so tap and swipe end in the same
  /// place — the toggle can never disagree with what's on screen.
  void _selectTestament(Testament t) {
    setState(() => _testament = t);
    _pages.animateToPage(
      _kTestamentPages.indexOf(t),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Settings lives on Home; the Bible screen no longer carries
                  // a redundant overflow menu.
                  Text(
                    context.l10n.bibleTitle,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SearchField(onChanged: (v) => setState(() => _query = v)),
                  const SizedBox(height: 16),
                  _TestamentToggle(
                    value: _testament,
                    onChanged: _selectTestament,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) =>
                    setState(() => _testament = _kTestamentPages[i]),
                children: [
                  for (final t in _kTestamentPages)
                    _TestamentList(testament: t, query: _query),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One testament's books. The PageStorageKey keeps each testament's scroll
/// offset across swipes, so returning to the Old Testament lands where the
/// reader left it rather than back at Genesis.
class _TestamentList extends ConsumerWidget {
  final Testament testament;
  final String query;
  const _TestamentList({required this.testament, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final all = ref.watch(booksByTestamentProvider(testament));
    final books = query.isEmpty
        ? all
        : all
              .where((b) => b.name.toLowerCase().contains(query.toLowerCase()))
              .toList();

    if (books.isEmpty) return _EmptyLibrary(installed: all.isNotEmpty);

    // Canonical sections (Pentateuch, Prophets, Gospels…) head the list the
    // way a printed Bible's contents page does. A search shows a flat list.
    final items = <Object>[];
    String? section;
    for (final b in books) {
      final s = query.isEmpty ? _sectionOf(context, b) : null;
      if (s != null && s != section) {
        items.add(s);
        section = s;
      }
      items.add(b);
    }

    return ListView.builder(
      key: PageStorageKey('books-${testament.name}'),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final it = items[i];
        if (it is String) return _SectionHeader(it);
        final b = it as BibleBook;
        final nextIsHeader = i + 1 < items.length && items[i + 1] is String;
        return Column(
          children: [
            _BookRow(book: b),
            if (!nextIsHeader && i + 1 < items.length)
              Divider(height: 1, color: c.divider, indent: 80),
          ],
        );
      },
    );
  }

  /// Section by canonical order (73-book Catholic canon).
  static String? _sectionOf(BuildContext context, BibleBook b) {
    final l10n = context.l10n;
    final o = b.order;
    if (b.testament == Testament.ot) {
      if (o <= 5) return l10n.sectionPentateuch;
      if (o <= 21) return l10n.sectionHistorical;
      if (o <= 28) return l10n.sectionWisdom;
      return l10n.sectionProphets;
    }
    if (o <= 50) return l10n.sectionGospels;
    if (o == 51) return l10n.sectionActs;
    if (o <= 65) return l10n.sectionPauline;
    if (o <= 72) return l10n.sectionCatholicLetters;
    return l10n.sectionApocalypse;
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: c.gold,
              fontSize: 11,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(height: 1, color: c.gold.withValues(alpha: 0.28)),
          ),
        ],
      ),
    );
  }
}

class _BookRow extends StatelessWidget {
  final BibleBook book;
  const _BookRow({required this.book});

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return InkWell(
      onTap: () => context.push('/bible/${book.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            BookEmblem(bookId: book.id, abbrev: book.abbrev),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                book.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            if (book.isDeutero)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  context.l10n.deuterocanonicalShort,
                  style: TextStyle(color: c.textFaint, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TestamentToggle extends StatelessWidget {
  final Testament value;
  final ValueChanged<Testament> onChanged;
  const _TestamentToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    Widget seg(String label, Testament t) {
      final on = value == t;
      return Expanded(
        // Swiping is the shortcut, not the only way in: the segments stay
        // real, tappable, selectable controls for screen readers.
        child: Semantics(
          button: true,
          selected: on,
          label: label,
          child: GestureDetector(
            onTap: () => onChanged(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: on ? c.surfaceHigh : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: on ? c.textPrimary : c.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          seg(context.l10n.oldTestament, Testament.ot),
          seg(context.l10n.newTestament, Testament.nt),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return TextField(
      onChanged: onChanged,
      style: TextStyle(color: c.textPrimary),
      decoration: InputDecoration(
        hintText: context.l10n.search,
        hintStyle: TextStyle(color: c.textFaint),
        prefixIcon: Icon(Icons.search, color: c.textFaint),
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  final bool installed;
  const _EmptyLibrary({required this.installed});
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 48, color: c.textFaint),
            const SizedBox(height: 16),
            Text(
              installed
                  ? context.l10n.noBooksFound
                  : context.l10n.contentNotInstalled,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

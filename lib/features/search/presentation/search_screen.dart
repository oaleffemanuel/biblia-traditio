import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../annotations/domain/entities.dart';
import '../../bible/application/bible_providers.dart';
import '../../bible/domain/entities.dart';
import '../application/search_providers.dart';

enum SearchScope { all, verses, fathers, notes }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  SearchScope _scope = SearchScope.all;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(searchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final results = ref.watch(searchResultsProvider);
    final q = ref.watch(searchQueryProvider).trim();
    final showVerses = _scope == SearchScope.all || _scope == SearchScope.verses;
    final showFathers = _scope == SearchScope.all || _scope == SearchScope.fathers;
    final showNotes = _scope == SearchScope.all || _scope == SearchScope.notes;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          style: TextStyle(color: c.textPrimary),
          decoration: InputDecoration(
            hintText: 'Pesquisar Escritura, Padres, notas…',
            hintStyle: TextStyle(color: c.textFaint),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close, color: c.textSecondary),
              onPressed: () {
                _controller.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final s in SearchScope.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_scopeLabel(s, results)),
                      selected: _scope == s,
                      onSelected: (_) => setState(() => _scope = s),
                      backgroundColor: c.surface,
                      selectedColor: c.accentSoft,
                      side: BorderSide.none,
                      labelStyle: TextStyle(
                          color: _scope == s ? c.accent : c.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: q.length < 2
                ? _hint(c, 'Escreva ao menos 2 letras para pesquisar.')
                : results.isEmpty
                    ? _hint(c, 'Nenhum resultado para “$q”.')
                    : ListView(
                        children: [
                          if (showVerses && results.verses.isNotEmpty) ...[
                            _SectionHeader('Escritura', results.verses.length, c),
                            for (final v in results.verses)
                              _ResultTile(
                                refLabel: _label(v.ref),
                                snippet: v.snippet,
                                icon: Icons.menu_book_outlined,
                                onTap: () => context
                                    .push('/bible/${v.ref.bookId}/${v.ref.chapter}'),
                              ),
                          ],
                          if (showFathers && results.commentaries.isNotEmpty) ...[
                            _SectionHeader(
                                'Padres da Igreja', results.commentaries.length, c),
                            for (final m in results.commentaries)
                              _ResultTile(
                                refLabel:
                                    '${m.fatherName} · ${_label(m.ref)}',
                                snippet: m.snippet,
                                icon: Icons.auto_stories,
                                accent: true,
                                onTap: () => context
                                    .push('/bible/${m.ref.bookId}/${m.ref.chapter}'),
                              ),
                          ],
                          if (showNotes && results.notes.isNotEmpty) ...[
                            _SectionHeader('Notas', results.notes.length, c),
                            for (final n in results.notes)
                              _ResultTile(
                                refLabel: _label(n.ref),
                                snippet: n.body,
                                icon: Icons.note_outlined,
                                onTap: () => context
                                    .push('/bible/${n.ref.bookId}/${n.ref.chapter}'),
                              ),
                          ],
                          const SizedBox(height: 32),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  String _label(VerseRef r) {
    final b = ref.read(bookByIdProvider(r.bookId));
    return '${b?.name ?? r.bookId} ${r.chapter},${r.verse}';
  }

  String _scopeLabel(SearchScope s, SearchResults r) => switch (s) {
        SearchScope.all => 'Tudo (${r.total})',
        SearchScope.verses => 'Escritura (${r.verses.length})',
        SearchScope.fathers => 'Padres (${r.commentaries.length})',
        SearchScope.notes => 'Notas (${r.notes.length})',
      };

  Widget _hint(BtColors c, String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(msg,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary)),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final BtColors c;
  const _SectionHeader(this.title, this.count, this.c);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Text('${title.toUpperCase()}  ·  $count',
            style: TextStyle(
                color: c.textFaint,
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w600)),
      );
}

class _ResultTile extends StatelessWidget {
  final String refLabel;
  final String snippet;
  final IconData icon;
  final bool accent;
  final VoidCallback onTap;
  const _ResultTile({
    required this.refLabel,
    required this.snippet,
    required this.icon,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return ListTile(
      leading: Icon(icon, size: 20, color: accent ? c.accent : c.textSecondary),
      title: Text(refLabel,
          style: TextStyle(
              color: accent ? c.accent : c.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14)),
      subtitle: Text.rich(_emphasise(snippet, c),
          maxLines: 3, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }

  /// Renders U+2068…U+2069-marked matches in bold accent.
  TextSpan _emphasise(String s, BtColors c) {
    const open = '\u2068', close = '\u2069';
    final spans = <TextSpan>[];
    var i = 0;
    while (i < s.length) {
      final start = s.indexOf(open, i);
      if (start == -1) {
        spans.add(TextSpan(text: s.substring(i)));
        break;
      }
      if (start > i) spans.add(TextSpan(text: s.substring(i, start)));
      final end = s.indexOf(close, start + 1);
      if (end == -1) {
        spans.add(TextSpan(text: s.substring(start + 1)));
        break;
      }
      spans.add(TextSpan(
        text: s.substring(start + 1, end),
        style: TextStyle(color: c.accent, fontWeight: FontWeight.w700),
      ));
      i = end + 1;
    }
    return TextSpan(
        style: TextStyle(color: c.textSecondary, height: 1.4), children: spans);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../bible/application/bible_providers.dart';
import '../application/annotation_providers.dart';
import '../domain/entities.dart';
import 'note_editor.dart';

String _ref(WidgetRef ref, VerseRef r) {
  final b = ref.read(bookByIdProvider(r.bookId));
  return '${b?.name ?? r.bookId} ${r.chapter},${r.verse}';
}

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});
  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final notes = ref.watch(allNotesProvider(_q.isEmpty ? null : _q));
    return Scaffold(
      appBar: AppBar(title: const Text('Notas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Pesquisar notas',
                hintStyle: TextStyle(color: c.textFaint),
                prefixIcon: Icon(Icons.search, color: c.textFaint),
                filled: true,
                fillColor: c.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          if (notes.isEmpty)
            Expanded(child: _empty(c, Icons.note_outlined, 'Nenhuma nota ainda.'))
          else
            Expanded(
              child: ListView.separated(
                itemCount: notes.length,
                separatorBuilder: (_, _) => Divider(height: 1, color: c.divider),
                itemBuilder: (_, i) {
                  final n = notes[i];
                  return ListTile(
                    title: Text(_ref(ref, n.ref),
                        style: TextStyle(
                            color: c.accent, fontWeight: FontWeight.w600)),
                    subtitle: Text(n.body,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => showNoteEditor(context, ref, n.ref, existing: n),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final favorites = ref.watch(allFavoritesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: favorites.isEmpty
          ? _empty(c, Icons.favorite_border, 'Nenhum favorito ainda.')
          : ListView.separated(
              itemCount: favorites.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: c.divider),
              itemBuilder: (_, i) {
                final f = favorites[i];
                return ListTile(
                  leading: Icon(Icons.favorite, color: c.accent, size: 20),
                  title: Text(f.snapshot,
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                  onTap: () => context
                      .push('/bible/${f.ref.bookId}/${f.ref.chapter}'),
                );
              },
            ),
    );
  }
}

class HighlightsScreen extends ConsumerWidget {
  const HighlightsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final items = ref.watch(allHighlightsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Destaques')),
      body: items.isEmpty
          ? _empty(c, Icons.format_color_fill, 'Nenhum destaque ainda.')
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: c.divider),
              itemBuilder: (_, i) {
                final h = items[i];
                return ListTile(
                  leading: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                          color: h.color.color, shape: BoxShape.circle)),
                  title: Text(_ref(ref, h.ref)),
                  onTap: () => context
                      .push('/bible/${h.ref.bookId}/${h.ref.chapter}'),
                );
              },
            ),
    );
  }
}

Widget _empty(BtColors c, IconData icon, String msg) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: c.textFaint),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: c.textSecondary)),
        ],
      ),
    );

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../application/bible_providers.dart';
import '../domain/entities.dart';
import 'widgets/book_emblem.dart';

class BibleLibraryScreen extends ConsumerStatefulWidget {
  const BibleLibraryScreen({super.key});
  @override
  ConsumerState<BibleLibraryScreen> createState() => _BibleLibraryScreenState();
}

class _BibleLibraryScreenState extends ConsumerState<BibleLibraryScreen> {
  Testament _testament = Testament.ot;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final all = ref.watch(booksByTestamentProvider(_testament));
    final books = _query.isEmpty
        ? all
        : all
            .where((b) => b.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bíblia',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        IconButton(
                          onPressed: () => context.push('/settings'),
                          icon: Icon(Icons.more_horiz, color: c.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _SearchField(onChanged: (v) => setState(() => _query = v)),
                    const SizedBox(height: 16),
                    _TestamentToggle(
                      value: _testament,
                      onChanged: (t) => setState(() => _testament = t),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            if (books.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyLibrary(installed: all.isNotEmpty),
              )
            else
              SliverList.separated(
                itemCount: books.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: c.divider, indent: 80),
                itemBuilder: (_, i) => _BookRow(book: books[i]),
              ),
          ],
        ),
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
              child: Text(book.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w500)),
            ),
            if (book.isDeutero)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text('DC',
                    style: TextStyle(color: c.textFaint, fontSize: 11)),
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
            child: Text(label,
                style: TextStyle(
                    color: on ? c.textPrimary : c.textSecondary,
                    fontWeight: FontWeight.w600)),
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
      child: Row(children: [
        seg('Antigo testamento', Testament.ot),
        seg('Novo testamento', Testament.nt),
      ]),
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
        hintText: 'Pesquisar',
        hintStyle: TextStyle(color: c.textFaint),
        prefixIcon: Icon(Icons.search, color: c.textFaint),
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
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
                  ? 'Nenhum livro encontrado.'
                  : 'Conteúdo ainda não instalado.\nInstale um pacote de tradução em Ajustes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

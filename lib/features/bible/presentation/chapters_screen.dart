import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../application/bible_providers.dart';
import '../domain/psalm_numbering.dart';
import 'widgets/book_emblem.dart';

class ChaptersScreen extends ConsumerWidget {
  final String bookId;
  const ChaptersScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final book = ref.watch(bookByIdProvider(bookId));
    if (book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(context.l10n.scriptureNotInstalled,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, height: 1.5)),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(book.name)),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            BookEmblem(bookId: book.id, abbrev: book.abbrev, size: 72),
            const SizedBox(height: 12),
            Text(book.name,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: book.chapterCount,
                itemBuilder: (_, i) {
                  final n = i + 1;
                  // For Psalms, show the traditional Vulgate number with the
                  // Hebrew/modern number beneath it (e.g. 22 / (23)).
                  final hebrew =
                      book.id == 'ps' ? PsalmNumbering.hebrewLabel(n) : null;
                  return InkWell(
                    onTap: () => context.push('/bible/${book.id}/$n'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$n',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w500)),
                          if (hebrew != null)
                            Text('($hebrew)',
                                style: TextStyle(
                                    color: c.textFaint, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

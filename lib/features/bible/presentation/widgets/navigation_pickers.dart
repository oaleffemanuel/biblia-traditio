import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/bible_providers.dart';
import '../../domain/entities.dart';
import 'book_emblem.dart';

/// Book picker with an Antigo/Novo Testamento toggle. Returns the chosen book id.
Future<String?> showBookPicker(
    BuildContext context, WidgetRef ref, String currentBookId) {
  final current = ref.read(bookByIdProvider(currentBookId));
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.bt.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _BookPickerSheet(
        initialTestament: current?.testament ?? Testament.ot,
        currentBookId: currentBookId),
  );
}

class _BookPickerSheet extends ConsumerStatefulWidget {
  final Testament initialTestament;
  final String currentBookId;
  const _BookPickerSheet(
      {required this.initialTestament, required this.currentBookId});
  @override
  ConsumerState<_BookPickerSheet> createState() => _BookPickerSheetState();
}

class _BookPickerSheetState extends ConsumerState<_BookPickerSheet> {
  late Testament _t = widget.initialTestament;

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final books = ref.watch(booksByTestamentProvider(_t));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: c.divider, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _Segmented(
              value: _t,
              onChanged: (t) => setState(() => _t = t),
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: controller,
              itemCount: books.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: c.divider, indent: 76),
              itemBuilder: (_, i) {
                final b = books[i];
                final selected = b.id == widget.currentBookId;
                return ListTile(
                  leading: BookEmblem(bookId: b.id, abbrev: b.abbrev, size: 40),
                  title: Text(b.name,
                      style: TextStyle(
                          color: selected ? c.accent : c.textPrimary,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500)),
                  trailing: selected
                      ? Icon(Icons.check, color: c.accent, size: 18)
                      : null,
                  onTap: () => Navigator.pop(context, b.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final Testament value;
  final ValueChanged<Testament> onChanged;
  const _Segmented({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    Widget seg(String label, Testament t) {
      final on = value == t;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: on ? c.surfaceHigh : Colors.transparent,
                borderRadius: BorderRadius.circular(24)),
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
          color: c.surfaceHigh.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(28)),
      child: Row(children: [
        seg(context.l10n.oldTestament, Testament.ot),
        seg(context.l10n.newTestament, Testament.nt),
      ]),
    );
  }
}

/// Chapter grid picker. Returns the chosen chapter number.
Future<int?> showChapterPicker(
    BuildContext context, String bookName, int chapterCount, int current) {
  final c = context.bt;
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, controller) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: c.divider, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(context.l10n.chapterPickerTitle(bookName),
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: GridView.builder(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5, mainAxisSpacing: 10, crossAxisSpacing: 10),
              itemCount: chapterCount,
              itemBuilder: (_, i) {
                final n = i + 1;
                final on = n == current;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, n),
                  child: Container(
                    decoration: BoxDecoration(
                        color: on ? c.accentSoft : c.surfaceHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: on
                            ? Border.all(color: c.accent)
                            : null),
                    alignment: Alignment.center,
                    child: Text('$n',
                        style: TextStyle(
                            color: on ? c.accent : c.textPrimary,
                            fontWeight: FontWeight.w600)),
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

/// Verse-number picker (jump within the open chapter). Returns the verse number.
Future<int?> showVersePicker(
    BuildContext context, int verseCount, int current) {
  final c = context.bt;
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, controller) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: c.divider, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(context.l10n.goToVerse,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: GridView.builder(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6, mainAxisSpacing: 10, crossAxisSpacing: 10),
              itemCount: verseCount,
              itemBuilder: (_, i) {
                final n = i + 1;
                final on = n == current;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, n),
                  child: Container(
                    decoration: BoxDecoration(
                        color: on ? c.accentSoft : c.surfaceHigh,
                        borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: Text('$n',
                        style: TextStyle(
                            color: on ? c.accent : c.textPrimary)),
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

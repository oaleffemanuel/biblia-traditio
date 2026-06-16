import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../bible/application/bible_providers.dart';
import '../application/annotation_providers.dart';
import '../domain/entities.dart';

/// Bottom-sheet note editor. Creates a new note or edits [existing].
void showNoteEditor(BuildContext context, WidgetRef ref, VerseRef vref,
    {Note? existing}) {
  final c = context.bt;
  final controller = TextEditingController(text: existing?.body ?? '');
  // Localized book name for the title (never the raw id like "gn").
  final bookName = ref.read(bookByIdProvider(vref.bookId))?.name ?? vref.bookId;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetCtx) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: c.divider, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.note_alt_outlined, color: c.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                  sheetCtx.l10n.noteEditorTitle(
                      '$bookName ${vref.chapter},${vref.verse}'),
                  style: Theme.of(sheetCtx).textTheme.titleMedium),
              const Spacer(),
              if (existing != null)
                IconButton(
                  tooltip: sheetCtx.l10n.actionDelete,
                  icon: Icon(Icons.delete_outline, color: c.textSecondary),
                  onPressed: () async {
                    final l10n = sheetCtx.l10n;
                    final confirmed = await showDialog<bool>(
                      context: sheetCtx,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.deleteNoteTitle),
                        content: Text(l10n.deleteNoteMessage),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(l10n.actionCancel)),
                          FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(l10n.actionDelete)),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    ref
                        .read(annotationControllerProvider)
                        .deleteNote(existing.uuid);
                    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            maxLines: 6,
            minLines: 3,
            style: TextStyle(color: c.textPrimary, height: 1.4),
            decoration: InputDecoration(
              hintText: sheetCtx.l10n.noteHint,
              hintStyle: TextStyle(color: c.textFaint),
              filled: true,
              fillColor: c.background,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () {
              final text = controller.text.trim();
              final ctrl = ref.read(annotationControllerProvider);
              if (text.isEmpty) {
                if (existing != null) ctrl.deleteNote(existing.uuid);
              } else if (existing == null) {
                ctrl.addNote(vref, text);
              } else {
                ctrl.updateNote(existing.uuid, text);
              }
              Navigator.pop(sheetCtx);
            },
            child: Text(sheetCtx.l10n.actionSave),
          ),
        ],
      ),
    ),
  );
}

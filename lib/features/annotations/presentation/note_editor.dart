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
  // Localized book name for the title (never the raw id like "gn").
  final bookName = ref.read(bookByIdProvider(vref.bookId))?.name ?? vref.bookId;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) =>
        _NoteEditorSheet(vref: vref, bookName: bookName, existing: existing),
  );
}

/// Stateful so the sheet itself owns the text controller: it is disposed with
/// the widget, after the field that uses it is gone. (Disposing it from the
/// route future instead races the closing animation.)
class _NoteEditorSheet extends ConsumerStatefulWidget {
  final VerseRef vref;
  final String bookName;
  final Note? existing;
  const _NoteEditorSheet(
      {required this.vref, required this.bookName, this.existing});

  @override
  ConsumerState<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends ConsumerState<_NoteEditorSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.existing?.body ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
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
    ref.read(annotationControllerProvider).deleteNote(existing.uuid);
    if (mounted) Navigator.pop(context);
  }

  void _save() {
    final text = _controller.text.trim();
    final ctrl = ref.read(annotationControllerProvider);
    // Clearing the text and saving is NOT a silent delete: an existing note is
    // left untouched, and deleting stays behind the confirmed action above.
    if (text.isNotEmpty) {
      if (widget.existing == null) {
        ctrl.addNote(widget.vref, text);
      } else {
        ctrl.updateNote(widget.existing!.uuid, text);
      }
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
              Expanded(
                child: Text(
                    l10n.noteEditorTitle('${widget.bookName} '
                        '${widget.vref.chapter},${widget.vref.verse}'),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              if (widget.existing != null)
                IconButton(
                  tooltip: l10n.actionDelete,
                  icon: Icon(Icons.delete_outline, color: c.textSecondary),
                  onPressed: _delete,
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 6,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: c.textPrimary, height: 1.4),
            decoration: InputDecoration(
              hintText: l10n.noteHint,
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
            onPressed: _save,
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
  }
}

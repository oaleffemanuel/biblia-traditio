import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../annotations/domain/entities.dart';

/// What the selection menu can do with a span of one verse. Offsets are
/// character offsets into the verse text.
class VerseMarkActions {
  /// Paint the span with the highlighter at once (one tap on a colour).
  final void Function(int start, int end, HighlightColor color) quick;

  /// Open the full mark sheet: underline, trim to a letter, other colours.
  final void Function(int start, int end) more;

  /// Clear the marks touching the span.
  final void Function(int start, int end) remove;

  /// Note on the verse the span belongs to.
  final VoidCallback note;

  /// The marks already on this verse (to offer "remove" only when useful).
  final List<TextMark> marks;

  const VerseMarkActions({
    required this.quick,
    required this.more,
    required this.remove,
    required this.note,
    this.marks = const [],
  });
}

/// The selection menu of a verse, as a reading app sets it out: a row of
/// colours on top (one tap paints the selected words), then the actions —
/// note, underline/adjust, remove, and the platform's copy/search items.
/// Without a selection it falls back to the platform toolbar.
Widget verseContextMenu(
  BuildContext context,
  EditableTextState state,
  VerseMarkActions? actions,
) {
  final sel = state.textEditingValue.selection;
  if (actions == null || !sel.isValid || sel.isCollapsed) {
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: state.contextMenuAnchors,
      buttonItems: state.contextMenuButtonItems,
    );
  }
  final a = sel.start, b = sel.end;
  void close() {
    ContextMenuController.removeAny();
    state.hideToolbar();
    state.userUpdateTextEditingValue(
      state.textEditingValue.copyWith(
        selection: TextSelection.collapsed(offset: b),
      ),
      SelectionChangedCause.toolbar,
    );
  }

  final l10n = context.l10n;
  final platform = [
    for (final item in state.contextMenuButtonItems)
      if (item.type != ContextMenuButtonType.selectAll)
        _MenuEntry(
          icon: _iconFor(item.type),
          label: AdaptiveTextSelectionToolbar.getButtonLabel(context, item),
          onTap: () {
            item.onPressed?.call();
            ContextMenuController.removeAny();
          },
        ),
  ];
  final touches = actions.marks.any((m) => m.overlaps(a, b));
  return _MarkToolbar(
    anchors: state.contextMenuAnchors,
    onColor: (color) {
      HapticFeedback.lightImpact();
      close();
      actions.quick(a, b, color);
    },
    entries: [
      _MenuEntry(
        key: const ValueKey('menu-note'),
        icon: Icons.note_add_outlined,
        label: l10n.markAddNote,
        onTap: () {
          close();
          actions.note();
        },
      ),
      _MenuEntry(
        key: const ValueKey('menu-more'),
        icon: Icons.format_underlined,
        label: l10n.markAdjust,
        onTap: () {
          close();
          actions.more(a, b);
        },
      ),
      if (touches)
        _MenuEntry(
          key: const ValueKey('menu-remove'),
          icon: Icons.format_color_reset_outlined,
          label: l10n.markRemoveShort,
          onTap: () {
            close();
            actions.remove(a, b);
          },
        ),
      ...platform,
    ],
  );
}

IconData _iconFor(ContextMenuButtonType t) => switch (t) {
  ContextMenuButtonType.copy => Icons.copy_outlined,
  ContextMenuButtonType.cut => Icons.content_cut,
  ContextMenuButtonType.paste => Icons.content_paste,
  ContextMenuButtonType.share => Icons.ios_share,
  ContextMenuButtonType.searchWeb => Icons.search,
  ContextMenuButtonType.lookUp => Icons.manage_search,
  ContextMenuButtonType.selectAll => Icons.select_all,
  _ => Icons.more_horiz,
};

class _MenuEntry {
  final Key? key;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuEntry({
    this.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _MarkToolbar extends StatelessWidget {
  final TextSelectionToolbarAnchors anchors;
  final void Function(HighlightColor) onColor;
  final List<_MenuEntry> entries;
  const _MarkToolbar({
    required this.anchors,
    required this.onColor,
    required this.entries,
  });

  static const _width = 216.0;
  static const _rowHeight = 44.0;
  static const _colorsHeight = 52.0;
  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final pad = MediaQuery.paddingOf(context);
    final screen = EdgeInsets.fromLTRB(8, pad.top + 8, 8, pad.bottom + 8);
    final height = _colorsHeight + 1 + entries.length * _rowHeight + 8;
    final above = anchors.primaryAnchor - Offset(screen.left, screen.top);
    final below =
        (anchors.secondaryAnchor ?? anchors.primaryAnchor) -
        Offset(screen.left, screen.top);
    return Padding(
      padding: screen,
      child: CustomSingleChildLayout(
        delegate: TextSelectionToolbarLayoutDelegate(
          anchorAbove: above - const Offset(0, _gap),
          anchorBelow: below + const Offset(0, _gap + 20),
          fitsAbove: above.dy - _gap >= height,
        ),
        child: SizedBox(
          width: _width,
          child: Material(
            color: c.surfaceHigh,
            elevation: 6,
            shadowColor: Colors.black38,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: _colorsHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final hc in HighlightColor.values)
                        Semantics(
                          button: true,
                          label: hc.key,
                          child: InkResponse(
                            key: ValueKey('menu-color-${hc.key}'),
                            radius: 22,
                            onTap: () => onColor(hc),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: hc.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: c.divider),
                const SizedBox(height: 4),
                for (final e in entries)
                  InkWell(
                    key: e.key,
                    onTap: e.onTap,
                    child: SizedBox(
                      height: _rowHeight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Icon(e.icon, size: 20, color: c.textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                e.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: c.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

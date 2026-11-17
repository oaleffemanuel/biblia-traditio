import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../annotations/domain/entities.dart';

/// What the reader decided in the mark sheet.
sealed class TextMarkAction {
  const TextMarkAction();
}

/// Paint [start, end) with [color] in [style].
class AddTextMark extends TextMarkAction {
  final int start;
  final int end;
  final HighlightColor color;
  final MarkStyle style;
  const AddTextMark(this.start, this.end, this.color, this.style);
}

/// Clear the marks that touch [start, end).
class RemoveTextMarks extends TextMarkAction {
  final int start;
  final int end;
  const RemoveTextMarks(this.start, this.end);
}

/// Opens the mark sheet for a selection inside one verse. The reader sees the
/// whole verse with the span lit up live, can trim or widen it one character
/// at a time (down to a single letter), choose highlighter or underline, and
/// paint with one tap on a colour.
Future<TextMarkAction?> showTextMarkSheet(
  BuildContext context, {
  required String verseText,
  required int start,
  required int end,
  required List<TextMark> existing,
  TextStyle? verseStyle,
}) {
  final c = context.bt;
  return showModalBottomSheet<TextMarkAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _TextMarkSheet(
      text: verseText,
      start: start,
      end: end,
      existing: existing,
      verseStyle: verseStyle,
    ),
  );
}

class _TextMarkSheet extends StatefulWidget {
  final String text;
  final int start;
  final int end;
  final List<TextMark> existing;
  final TextStyle? verseStyle;
  const _TextMarkSheet({
    required this.text,
    required this.start,
    required this.end,
    required this.existing,
    this.verseStyle,
  });

  @override
  State<_TextMarkSheet> createState() => _TextMarkSheetState();
}

class _TextMarkSheetState extends State<_TextMarkSheet> {
  late int _a = widget.start.clamp(0, widget.text.length);
  late int _b = widget.end.clamp(_a, widget.text.length);
  MarkStyle _style = MarkStyle.highlight;
  HighlightColor _preview = HighlightColor.gold;

  int get _len => widget.text.length;

  void _nudge({required bool startEdge, required int delta}) {
    HapticFeedback.selectionClick();
    setState(() {
      if (startEdge) {
        _a = (_a + delta).clamp(0, _b - 1);
      } else {
        _b = (_b + delta).clamp(_a + 1, _len);
      }
    });
  }

  bool get _touchesExisting => widget.existing.any((m) => m.overlaps(_a, _b));

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final l10n = context.l10n;
    final base = (widget.verseStyle ?? Theme.of(context).textTheme.bodyLarge)
        ?.copyWith(fontSize: 18, height: 1.5);
    final painted = applyTextMarks(
      [TextSpan(text: widget.text, style: base)],
      [
        ...widget.existing,
        TextMark(
          '_preview',
          const VerseRef('', 0, 0),
          start: _a,
          end: _b,
          color: _preview,
          style: _style,
          createdAt: DateTime.now(),
        ),
      ],
      text: widget.text,
    );

    Widget nudger(String label, {required bool startEdge}) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: c.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            IconButton(
              key: ValueKey('mark-${startEdge ? 'start' : 'end'}-left'),
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chevron_left),
              color: c.textSecondary,
              onPressed: () => _nudge(startEdge: startEdge, delta: -1),
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, fontSize: 13),
              ),
            ),
            IconButton(
              key: ValueKey('mark-${startEdge ? 'start' : 'end'}-right'),
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chevron_right),
              color: c.textSecondary,
              onPressed: () => _nudge(startEdge: startEdge, delta: 1),
            ),
          ],
        ),
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.highlightPickColor,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.3,
              ),
              child: SingleChildScrollView(
                child: Text.rich(TextSpan(children: painted)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '“${widget.text.substring(_a, _b)}”',
              key: const ValueKey('mark-excerpt'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.textFaint, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                nudger(l10n.markStart, startEdge: true),
                const SizedBox(width: 10),
                nudger(l10n.markEnd, startEdge: false),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.markLetterHint,
              style: TextStyle(color: c.textFaint, fontSize: 12),
            ),
            const SizedBox(height: 14),
            SegmentedButton<MarkStyle>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: MarkStyle.highlight,
                  icon: const Icon(Icons.border_color_outlined, size: 18),
                  label: Text(l10n.markStyleHighlight),
                ),
                ButtonSegment(
                  value: MarkStyle.underline,
                  icon: const Icon(Icons.format_underlined, size: 18),
                  label: Text(l10n.markStyleUnderline),
                ),
              ],
              selected: {_style},
              onSelectionChanged: (s) => setState(() => _style = s.first),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final hc in HighlightColor.values)
                  Semantics(
                    button: true,
                    label: hc.key,
                    child: GestureDetector(
                      key: ValueKey('mark-color-${hc.key}'),
                      // Hovering/pressing previews; the tap paints and closes.
                      onTapDown: (_) => setState(() => _preview = hc),
                      onTap: () => Navigator.pop(
                        context,
                        AddTextMark(_a, _b, hc, _style),
                      ),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _style == MarkStyle.highlight
                                ? hc.color
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _style == MarkStyle.highlight
                                  ? c.divider
                                  : hc.color,
                              width: _style == MarkStyle.highlight ? 0.5 : 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (_touchesExisting) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('mark-remove'),
                  onPressed: () =>
                      Navigator.pop(context, RemoveTextMarks(_a, _b)),
                  icon: const Icon(Icons.format_color_reset_outlined),
                  label: Text(l10n.markRemoveHere),
                  style: TextButton.styleFrom(foregroundColor: c.textSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Paints text marks over already-built verse spans by splitting them at
/// every mark boundary. Marks may overlap: for each piece the newest
/// highlighter mark gives the background and the newest underline mark the
/// line, so a word can be both highlighted and underlined. Spans outside every
/// mark are passed through untouched (the raised initial and script styling
/// survive).
///
/// When [text] is given, a mark whose stored words no longer match the text
/// (e.g. made on another translation) is skipped rather than drawn on the
/// wrong letters.
List<InlineSpan> applyTextMarks(
  List<InlineSpan> spans,
  List<TextMark> marks, {
  String? text,
}) {
  final valid = [
    for (final m in marks)
      if (m.end > m.start &&
          (text == null ||
              (m.end <= text.length &&
                  (m.excerpt == null ||
                      text.substring(m.start, m.end) == m.excerpt))))
        m,
  ];
  if (valid.isEmpty) return spans;
  final cuts = <int>{
    for (final m in valid) ...[m.start, m.end],
  };
  final out = <InlineSpan>[];
  var pos = 0;
  for (final sp in spans) {
    if (sp is! TextSpan || sp.text == null) {
      out.add(sp);
      continue;
    }
    final t = sp.text!;
    final a = pos, b = pos + t.length;
    pos = b;
    final inner = [
      a,
      ...(cuts.where((x) => x > a && x < b).toList()..sort()),
      b,
    ];
    for (var i = 0; i + 1 < inner.length; i++) {
      final s0 = inner[i], s1 = inner[i + 1];
      if (s1 <= s0) continue;
      TextMark? bg, line;
      for (final m in valid) {
        if (m.start <= s0 && m.end >= s1) {
          if (m.style == MarkStyle.highlight) {
            bg = m;
          } else {
            line = m;
          }
        }
      }
      final piece = t.substring(s0 - a, s1 - a);
      if (bg == null && line == null) {
        out.add(TextSpan(text: piece, style: sp.style));
        continue;
      }
      var style = sp.style ?? const TextStyle();
      if (bg != null) {
        style = style.copyWith(
          backgroundColor: bg.color.color.withValues(alpha: 0.38),
        );
      }
      if (line != null) {
        style = style.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: line.color.color,
          decorationThickness: 2.4,
        );
      }
      out.add(TextSpan(text: piece, style: style));
    }
  }
  return out;
}

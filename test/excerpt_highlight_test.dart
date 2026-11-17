import 'package:biblia_traditio/features/annotations/domain/entities.dart';
import 'package:biblia_traditio/features/bible/presentation/reader_screen.dart';
import 'package:biblia_traditio/features/bible/presentation/widgets/text_mark_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String _plain(List<InlineSpan> spans) =>
    spans.map((s) => (s as TextSpan).text ?? '').join();

void main() {
  const base = TextStyle(fontSize: 18);
  final spans = <InlineSpan>[
    const TextSpan(text: 'N', style: TextStyle(fontSize: 38)),
    const TextSpan(
      text: 'o princípio criou Deus o céu e a terra.',
      style: base,
    ),
  ];

  test('a range inside one span splits it and keeps the text intact', () {
    final out = applyHighlightRange(
      spans,
      const HighlightMark(HighlightColor.sky, start: 3, end: 12),
    );
    expect(_plain(out), 'No princípio criou Deus o céu e a terra.');
    final painted = out
        .whereType<TextSpan>()
        .where((s) => s.style?.backgroundColor != null)
        .map((s) => s.text)
        .join();
    expect(painted, 'princípio');
  });

  test('a range across the raised initial paints both pieces', () {
    final out = applyHighlightRange(
      spans,
      const HighlightMark(HighlightColor.gold, start: 0, end: 4),
    );
    final painted = out
        .whereType<TextSpan>()
        .where((s) => s.style?.backgroundColor != null)
        .map((s) => s.text)
        .join();
    expect(painted, 'No p');
    // The initial keeps its own size.
    expect((out.first as TextSpan).style?.fontSize, 38);
  });

  test('whole-verse marks leave the spans alone', () {
    final out = applyHighlightRange(
      spans,
      const HighlightMark(HighlightColor.rose),
    );
    expect(identical(out, spans), isTrue);
  });

  TextMark mark(
    int a,
    int b,
    HighlightColor c, {
    MarkStyle style = MarkStyle.highlight,
    String? excerpt,
  }) => TextMark(
    'id$a$b',
    const VerseRef('gn', 1, 1),
    start: a,
    end: b,
    color: c,
    style: style,
    excerpt: excerpt,
    createdAt: DateTime(2026),
  );
  const verse = 'No princípio criou Deus o céu e a terra.';

  test('several marks on one verse, including a single letter', () {
    final out = applyTextMarks(spans, [
      mark(3, 12, HighlightColor.sky),
      mark(19, 23, HighlightColor.gold, style: MarkStyle.underline),
      mark(0, 1, HighlightColor.rose),
    ], text: verse);
    expect(_plain(out), verse);
    final bg = out
        .whereType<TextSpan>()
        .where((s) => s.style?.backgroundColor != null)
        .map((s) => s.text)
        .toList();
    expect(bg, ['N', 'princípio']);
    final lined = out
        .whereType<TextSpan>()
        .where((s) => s.style?.decoration == TextDecoration.underline)
        .map((s) => s.text)
        .join();
    expect(lined, 'Deus');
    expect((out.first as TextSpan).style?.fontSize, 38); // initial intact
  });

  test('overlap: newest highlight wins, underline stacks on top', () {
    final out = applyTextMarks(spans, [
      mark(3, 12, HighlightColor.sky),
      mark(6, 9, HighlightColor.rose),
      mark(3, 5, HighlightColor.gold, style: MarkStyle.underline),
    ], text: verse);
    final pieces = out.whereType<TextSpan>().toList();
    final rose = pieces.firstWhere((s) => s.text == 'ncí');
    expect(
      rose.style?.backgroundColor,
      HighlightColor.rose.color.withValues(alpha: 0.38),
    );
    final both = pieces.firstWhere((s) => s.text == 'pr');
    expect(both.style?.backgroundColor, isNotNull);
    expect(both.style?.decoration, TextDecoration.underline);
  });

  test('a mark made on other words (another translation) is not drawn', () {
    final out = applyTextMarks(spans, [
      mark(3, 12, HighlightColor.sky, excerpt: 'principio'),
    ], text: verse);
    expect(identical(out, spans), isTrue);
  });
}


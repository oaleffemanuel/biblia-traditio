import 'package:biblia_traditio/features/annotations/domain/entities.dart';
import 'package:biblia_traditio/features/bible/presentation/reader_screen.dart';
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
}

import 'package:flutter/material.dart';

import '../../bible/domain/entities.dart';

export '../../bible/domain/entities.dart' show VerseRef;

/// Highlight palette (keys persisted; colors resolved per theme).
/// Declaration order is the order the colour bar paints them — yellow, green,
/// blue, pink, purple. The `key` is what's stored, so reordering here can never
/// disturb highlights already on disk.
enum HighlightColor {
  gold('gold', Color(0xFFE3B23C)),
  sage('sage', Color(0xFF8CB48C)),
  sky('sky', Color(0xFF7FA8D4)),
  rose('rose', Color(0xFFD98CA6)),
  lilac('lilac', Color(0xFFB39DDB));

  final String key;
  final Color color;
  const HighlightColor(this.key, this.color);

  static HighlightColor fromKey(String k) =>
      values.firstWhere((c) => c.key == k, orElse: () => gold);
}

/// What the reader painted on one verse: the colour and, for an excerpt
/// highlight (a few words selected inside the verse), the character range.
/// A whole-verse highlight carries no range.
class HighlightMark {
  final HighlightColor color;
  final int? start;
  final int? end;
  const HighlightMark(this.color, {this.start, this.end});
  bool get isPartial => start != null && end != null && end! > start!;
}

/// How a text mark is drawn: a highlighter stroke behind the letters, or a
/// pen line under them. The `key` is what's stored.
enum MarkStyle {
  highlight('highlight'),
  underline('underline');

  final String key;
  const MarkStyle(this.key);

  static MarkStyle fromKey(String? k) =>
      values.firstWhere((m) => m.key == k, orElse: () => highlight);
}

/// A mark on part of a verse — a word, a phrase or a single letter. A verse
/// can carry any number of them (they may overlap; the newest is drawn on
/// top). [start]/[end] are character offsets into the verse text.
class TextMark {
  final String uuid;
  final VerseRef ref;
  final int start;
  final int end;
  final HighlightColor color;
  final MarkStyle style;
  final String? excerpt;
  final DateTime createdAt;
  const TextMark(
    this.uuid,
    this.ref, {
    required this.start,
    required this.end,
    required this.color,
    this.style = MarkStyle.highlight,
    this.excerpt,
    required this.createdAt,
  });

  bool overlaps(int a, int b) => start < b && a < end;
}

class Highlight {
  final String uuid;
  final VerseRef ref;
  final HighlightColor color;
  final DateTime createdAt;
  final int? start;
  final int? end;
  final String? excerpt;
  Highlight(
    this.uuid,
    this.ref,
    this.color,
    this.createdAt, {
    this.start,
    this.end,
    this.excerpt,
  });
  HighlightMark get mark => HighlightMark(color, start: start, end: end);
}

class Bookmark {
  final String uuid;
  final VerseRef ref;
  final String? label;
  final DateTime createdAt;
  Bookmark(this.uuid, this.ref, this.label, this.createdAt);
}

class Favorite {
  final String uuid;
  final VerseRef ref;
  final String snapshot; // cached verse text + reference
  final DateTime createdAt;
  Favorite(this.uuid, this.ref, this.snapshot, this.createdAt);
}

class Note {
  final String uuid;
  final VerseRef ref;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  Note(this.uuid, this.ref, this.body, this.createdAt, this.updatedAt);
}

class ReadingPosition {
  final String translationId;
  final String bookId;
  final int chapter;
  final int verse;
  final DateTime updatedAt;
  ReadingPosition(
    this.translationId,
    this.bookId,
    this.chapter,
    this.verse,
    this.updatedAt,
  );
}

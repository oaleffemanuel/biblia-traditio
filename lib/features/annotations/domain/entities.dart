import 'package:flutter/material.dart';

import '../../bible/domain/entities.dart';

export '../../bible/domain/entities.dart' show VerseRef;

/// Highlight palette (keys persisted; colors resolved per theme).
enum HighlightColor {
  gold('gold', Color(0xFFE3B23C)),
  rose('rose', Color(0xFFD98CA6)),
  sky('sky', Color(0xFF7FA8D4)),
  sage('sage', Color(0xFF8CB48C)),
  lilac('lilac', Color(0xFFB39DDB));

  final String key;
  final Color color;
  const HighlightColor(this.key, this.color);

  static HighlightColor fromKey(String k) =>
      values.firstWhere((c) => c.key == k, orElse: () => gold);
}

class Highlight {
  final String uuid;
  final VerseRef ref;
  final HighlightColor color;
  final DateTime createdAt;
  Highlight(this.uuid, this.ref, this.color, this.createdAt);
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
      this.translationId, this.bookId, this.chapter, this.verse, this.updatedAt);
}

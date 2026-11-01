import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// A Scripture passage listed under a theme. Chapter/verse are in the app's
/// own (Vulgate) numbering so the passage opens exactly where it should; the
/// human citation in [ref] may carry both psalm numbers ("Sl 50(51)").
@immutable
class ThemePassage {
  final String ref;
  final String bookId;
  final int chapter;
  final int verseStart;
  final int verseEnd;
  const ThemePassage({
    required this.ref,
    required this.bookId,
    required this.chapter,
    required this.verseStart,
    required this.verseEnd,
  });

  factory ThemePassage.fromJson(Map<String, dynamic> j) => ThemePassage(
    ref: j['ref'] as String,
    bookId: j['book'] as String,
    chapter: (j['chapter'] as num).toInt(),
    verseStart: (j['vStart'] as num).toInt(),
    verseEnd: (j['vEnd'] as num).toInt(),
  );
}

@immutable
class ThemeSubtopic {
  final String title;
  final List<ThemePassage> passages;
  const ThemeSubtopic({required this.title, required this.passages});
}

/// A commentary attached to a theme, carried with the provenance line the
/// compilers gave ("2014 (© da edição digital)") so the reader can see where
/// the text comes from.
@immutable
class ThemeComment {
  final String author;
  final String role;
  final String edition;
  final String text;
  const ThemeComment({
    required this.author,
    required this.role,
    required this.edition,
    required this.text,
  });
}

@immutable
class BibleTheme {
  final String id;
  final String groupId;
  final String title;
  final String summary;
  final List<ThemePassage> passages;
  final List<ThemeSubtopic> subtopics;
  final List<ThemeComment> comments;
  const BibleTheme({
    required this.id,
    required this.groupId,
    required this.title,
    required this.summary,
    required this.passages,
    this.subtopics = const [],
    this.comments = const [],
  });

  /// Theme-level passages plus those under every subtopic.
  int get passageCount =>
      passages.length + subtopics.fold(0, (n, s) => n + s.passages.length);

  static List<ThemePassage> _passages(Object? list) => [
    for (final p in (list as List? ?? const []))
      ThemePassage.fromJson(p as Map<String, dynamic>),
  ];

  factory BibleTheme.fromJson(Map<String, dynamic> j) => BibleTheme(
    id: j['id'] as String,
    groupId: j['group'] as String,
    title: j['title'] as String,
    summary: (j['summary'] as String?) ?? '',
    passages: _passages(j['passages']),
    subtopics: [
      for (final st in (j['subtopics'] as List? ?? const []))
        ThemeSubtopic(
          title: (st as Map)['title'] as String,
          passages: _passages(st['passages']),
        ),
    ],
    comments: [
      for (final c in (j['comments'] as List? ?? const []))
        ThemeComment(
          author: ((c as Map)['author'] as String?) ?? '',
          role: (c['role'] as String?) ?? '',
          edition: (c['edition'] as String?) ?? '',
          text: (c['text'] as String?) ?? '',
        ),
    ],
  );
}

@immutable
class ThemeGroup {
  final String id;
  final String title;
  const ThemeGroup(this.id, this.title);
}

/// The thematic index: curated Scripture passages per theme (Eucharist,
/// Baptism, Prayer…), read against the installed Bible and the Fathers. The
/// data is a bundled asset; nothing here is generated at runtime.
@immutable
class ThemeLibrary {
  final List<ThemeGroup> groups;
  final List<BibleTheme> themes;
  const ThemeLibrary({required this.groups, required this.themes});

  static const asset = 'assets/themes/themes.json';

  BibleTheme? byId(String id) {
    for (final t in themes) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<BibleTheme> inGroup(String groupId) =>
      themes.where((t) => t.groupId == groupId).toList();

  static ThemeLibrary parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return ThemeLibrary(
      groups: [
        for (final g in (j['groups'] as List? ?? const []))
          ThemeGroup((g as Map)['id'] as String, g['title'] as String),
      ],
      themes: [
        for (final t in (j['themes'] as List? ?? const []))
          BibleTheme.fromJson(t as Map<String, dynamic>),
      ],
    );
  }

  static Future<ThemeLibrary> load([String path = asset]) async =>
      parse(await rootBundle.loadString(path));
}

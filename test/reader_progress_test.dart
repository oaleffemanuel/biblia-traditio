import 'dart:io';

import 'package:biblia_traditio/core/di/providers.dart';
import 'package:biblia_traditio/core/storage/user/user_database.dart';
import 'package:biblia_traditio/core/theme/app_theme.dart';
import 'package:biblia_traditio/core/l10n_ext.dart';
import 'package:biblia_traditio/features/annotations/domain/entities.dart';
import 'package:biblia_traditio/features/bible/presentation/reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps the reader for [bookId]/[chapter] with a fake user DB and no content
/// DB, then returns the recorded reading progress (null if none).
Future<ReadingPosition?> _pumpReader(
  WidgetTester t, {
  required String bookId,
  required int chapter,
  required bool recordProgress,
  ReadingPosition? seed,
}) async {
  final dir = Directory.systemTemp.createTempSync('bt_reader');
  final db = UserDatabase.open('${dir.path}/user.db');
  if (seed != null) {
    db.setProgress(seed.translationId, VerseRef(seed.bookId, seed.chapter, seed.verse));
  }
  await t.pumpWidget(ProviderScope(
    overrides: [
      userDbProvider.overrideWithValue(db),
      contentDatabaseProvider.overrideWithValue(null),
    ],
    child: MaterialApp(
      theme: AppTheme.dark(),
      locale: const Locale('pt'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: ReaderScreen(
          bookId: bookId, chapter: chapter, recordProgress: recordProgress),
    ),
  ));
  await t.pump(); // run the post-frame recordProgress callback
  await t.pump(const Duration(milliseconds: 50));
  final pos = db.latestProgress();
  db.dispose();
  dir.deleteSync(recursive: true);
  return pos;
}

void main() {
  testWidgets('personal Bible browsing records Continue Reading', (t) async {
    final pos = await _pumpReader(t, bookId: 'mt', chapter: 5, recordProgress: true);
    expect(pos, isNotNull);
    expect(pos!.bookId, 'mt');
    expect(pos.chapter, 5);
  });

  testWidgets('liturgy/plan reading does NOT overwrite Continue Reading',
      (t) async {
    // Seed a personal position (Genesis 3); opening a liturgy passage (Matthew
    // 5) with recordProgress:false must leave the personal position intact.
    final pos = await _pumpReader(
      t,
      bookId: 'mt',
      chapter: 5,
      recordProgress: false,
      seed: ReadingPosition('pt_matos_soares', 'gn', 3, 1, DateTime(2026)),
    );
    expect(pos, isNotNull);
    expect(pos!.bookId, 'gn', reason: 'personal position must be preserved');
    expect(pos.chapter, 3);
  });
}

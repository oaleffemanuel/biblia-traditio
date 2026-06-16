import 'dart:io';

import 'package:biblia_traditio/core/storage/user/user_database.dart';
import 'package:biblia_traditio/features/settings/domain/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late UserDatabase db;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('bt_settings');
    db = UserDatabase.open('${dir.path}/user.db');
  });
  tearDown(() {
    db.dispose();
    dir.deleteSync(recursive: true);
  });

  test('defaults before any onboarding', () {
    final s = Settings.fromMap(db.allSettings());
    expect(s.onboardingCompleted, isFalse);
    expect(s.language, AppLanguage.pt);
    expect(s.primaryTranslationId, 'pt_beta');
    expect(s.themeMode, ThemeMode.dark);
    // Parallel Reading off by default, no secondary, auto layout.
    expect(s.parallelReadingEnabled, isFalse);
    expect(s.secondaryTranslationId, '');
    expect(s.parallelLayout, ParallelLayout.auto);
  });

  test('parallel reading preferences persist and reconstruct', () {
    db.setSetting('parallelReadingEnabled', 'true');
    db.setSetting('secondaryTranslationId', 'drb');
    db.setSetting('parallelLayout', Settings.parallelLayoutKey(ParallelLayout.sideBySide));

    final s = Settings.fromMap(db.allSettings());
    expect(s.parallelReadingEnabled, isTrue);
    expect(s.secondaryTranslationId, 'drb');
    expect(s.parallelLayout, ParallelLayout.sideBySide);
  });

  test('onboarding choices persist and reconstruct', () {
    db.setSetting('displayName', 'Gabriel');
    db.setSetting('language', 'la');
    db.setSetting('primaryTranslationId', 'vulgata');
    db.setSetting('themeMode', 'light');
    db.setSetting('notificationsEnabled', 'true');
    db.setSetting('wantsReadingPlan', 'true');
    db.setSetting('onboardingCompleted', 'true');

    final s = Settings.fromMap(db.allSettings());
    expect(s.displayName, 'Gabriel');
    expect(s.language, AppLanguage.la);
    expect(s.primaryTranslationId, 'vulgata');
    expect(s.themeMode, ThemeMode.light);
    expect(s.notificationsEnabled, isTrue);
    expect(s.wantsReadingPlan, isTrue);
    expect(s.onboardingCompleted, isTrue);
  });

  test('setSetting upserts (no duplicate key)', () {
    db.setSetting('displayName', 'A');
    db.setSetting('displayName', 'B');
    expect(Settings.fromMap(db.allSettings()).displayName, 'B');
  });
}

import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateProvider (Riverpod 3)
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../storage/content/content_database.dart';
import '../storage/user/user_database.dart';

/// The content DB is shipped as a bundled asset and copied to the app's private
/// support directory on first launch (sqlite can't open a read-only asset in
/// place). Bump this when the bundled DB changes to trigger a re-copy.
const String _contentAsset = 'assets/content/biblia_traditio.sqlite';
const int _contentAssetVersion = 1;

/// Resolves the on-device content DB path, copying the bundled asset in on
/// first launch (cross-platform; no machine-specific paths). Returns null only
/// if the asset is absent from the build (app then shows an "install" state).
final contentDbPathProvider = FutureProvider<String?>((ref) async {
  final dir = await getApplicationSupportDirectory();
  final contentDir = Directory(p.join(dir.path, 'content'));
  await contentDir.create(recursive: true);
  final dest = p.join(contentDir.path, 'biblia_traditio.sqlite');
  final stamp = File(p.join(contentDir.path, '.version'));

  final installed = File(dest).existsSync() &&
      stamp.existsSync() &&
      stamp.readAsStringSync().trim() == '$_contentAssetVersion';

  if (!installed) {
    try {
      final bytes = await rootBundle.load(_contentAsset);
      await File(dest).writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          flush: true);
      await stamp.writeAsString('$_contentAssetVersion');
    } on Exception {
      return null; // asset not bundled in this build
    }
  }
  return dest;
});

/// The opened content database (null until a pack is installed).
final contentDatabaseProvider = Provider<ContentDatabase?>((ref) {
  final path = ref.watch(contentDbPathProvider).value;
  if (path == null) return null;
  final db = ContentDatabase.open(path);
  ref.onDispose(db.dispose);
  return db;
});

/// Writable user-data DB (notes/highlights/bookmarks/favorites/progress).
final userDatabaseProvider = FutureProvider<UserDatabase>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final db = UserDatabase.open(p.join(dir.path, 'user.db'));
  ref.onDispose(db.dispose);
  return db;
});

/// Synchronous handle to the user DB once opened (null during the brief open).
final userDbProvider = Provider<UserDatabase?>(
    (ref) => ref.watch(userDatabaseProvider).value);

/// Bumped after every user-data write so read providers re-query.
final userDataRevisionProvider = StateProvider<int>((_) => 0);

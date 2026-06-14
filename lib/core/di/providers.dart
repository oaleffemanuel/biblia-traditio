import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateProvider (Riverpod 3)
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../storage/content/content_database.dart';
import '../storage/user/user_database.dart';

/// Dev-only fallback: the importer's output on this machine. In production the
/// DB is shipped as a downloadable/bundled resource pack into [appContentDir].
const String _devContentDbSource =
    '/Users/aleffemanuel/workspace/biblia-traditio/tool/importer/data/biblia_traditio.sqlite';

/// Resolves the on-device content DB path, copying the dev build in on first
/// run if present. Returns null if no content DB is available yet.
final contentDbPathProvider = FutureProvider<String?>((ref) async {
  final dir = await getApplicationSupportDirectory();
  final contentDir = Directory(p.join(dir.path, 'content'));
  await contentDir.create(recursive: true);
  final dest = p.join(contentDir.path, 'biblia_traditio.sqlite');

  if (!File(dest).existsSync()) {
    final devSrc = File(_devContentDbSource);
    if (devSrc.existsSync()) {
      await devSrc.copy(dest);
    } else {
      return null; // pack not installed yet
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

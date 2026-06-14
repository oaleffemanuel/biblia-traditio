import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateProvider (Riverpod 3)
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/packages/application/package_providers.dart';
import '../storage/content/content_database.dart';
import '../storage/user/user_database.dart';

/// The opened content database, built from the installed Scripture (required)
/// and patristics (optional) package DBs. Null until the Bible is installed.
final contentDatabaseProvider = Provider<ContentDatabase?>((ref) {
  final paths = ref.watch(contentReadyProvider).value;
  if (paths?.bible == null) return null;
  final db = ContentDatabase.open(
      biblePath: paths!.bible!, patristicsPath: paths.patristics);
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

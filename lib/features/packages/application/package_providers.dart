import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../domain/content_package.dart';
import 'content_package_manager.dart';

final packageManagerProvider = Provider((ref) => ContentPackageManager());

final manifestProvider = FutureProvider<List<ContentPackage>>(
    (ref) => ref.watch(packageManagerProvider).loadManifest());

/// Bumped after any install/remove so dependent providers re-evaluate.
final installRevisionProvider = StateProvider<int>((_) => 0);

class ContentPaths {
  final String? bible;
  final String? patristics;
  const ContentPaths({this.bible, this.patristics});
}

/// Ensures required packages (the core Bible) are installed on first launch,
/// then resolves the installed Scripture + patristics DB paths.
final contentReadyProvider = FutureProvider<ContentPaths>((ref) async {
  ref.watch(installRevisionProvider);
  final mgr = ref.watch(packageManagerProvider);
  final pkgs = await ref.watch(manifestProvider.future);
  await mgr.ensureRequiredInstalled(pkgs);

  ContentPackage? pick(PackageType t) {
    for (final p in pkgs) {
      if (p.type == t && mgr.isInstalled(p)) return p;
    }
    return null;
  }

  final bible = pick(PackageType.bibleTranslation);
  final patr = pick(PackageType.patristics);
  return ContentPaths(
    bible: bible == null ? null : mgr.installedPathSync(bible.id),
    patristics: patr == null ? null : mgr.installedPathSync(patr.id),
  );
});

/// Packages with their install state + size, for the Settings manager.
final installablePackagesProvider =
    Provider<List<({ContentPackage pkg, bool installed})>>((ref) {
  ref.watch(installRevisionProvider);
  final mgr = ref.watch(packageManagerProvider);
  final pkgs = ref.watch(manifestProvider).value ?? const [];
  return pkgs
      .map((p) => (pkg: p, installed: mgr.isInstalled(p)))
      .toList();
});

/// Install/remove a package and refresh the app.
final packageControllerProvider = Provider((ref) => PackageController(ref));

class PackageController {
  final Ref _ref;
  PackageController(this._ref);

  Future<void> install(ContentPackage pkg,
      {void Function(double) onProgress = _noop}) async {
    await _ref
        .read(packageManagerProvider)
        .install(pkg, onProgress: (_, p) => onProgress(p));
    _ref.read(installRevisionProvider.notifier).state++;
  }

  Future<void> remove(ContentPackage pkg) async {
    await _ref.read(packageManagerProvider).remove(pkg);
    _ref.read(installRevisionProvider.notifier).state++;
  }

  static void _noop(double _) {}
}

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/content_package.dart';

const _manifestAsset = 'assets/packages/manifest.json';

class PackageInstallException implements Exception {
  final String message;
  PackageInstallException(this.message);
  @override
  String toString() => 'PackageInstallException: $message';
}

/// Installs/removes content packages: decompress a bundled (or future remote)
/// gzip into a standalone SQLite file in app-private storage, verified by
/// SHA-256. Decompression runs off the main isolate so the UI never freezes.
class ContentPackageManager {
  Directory? _dir;
  List<ContentPackage>? _manifest;

  Future<Directory> _contentDir() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationSupportDirectory();
    final d = Directory(p.join(base.path, 'content'));
    await d.create(recursive: true);
    return _dir = d;
  }

  Future<List<ContentPackage>> loadManifest() async {
    if (_manifest != null) return _manifest!;
    try {
      final raw = await rootBundle.loadString(_manifestAsset);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final list = (json['packages'] as List)
          .map((e) => ContentPackage.fromJson(e as Map<String, dynamic>))
          .toList();
      return _manifest = list;
    } on Exception {
      return _manifest = const []; // no packages bundled in this build
    }
  }

  String installedPathSync(String id) {
    // Safe to call after [_contentDir] has been created at least once.
    return p.join(_dir!.path, '$id.sqlite');
  }

  File _okMarker(String id) => File(p.join(_dir!.path, '$id.ok'));

  bool isInstalled(ContentPackage pkg) {
    if (_dir == null) return false;
    final db = File(installedPathSync(pkg.id));
    final ok = _okMarker(pkg.id);
    return db.existsSync() &&
        ok.existsSync() &&
        ok.readAsStringSync().trim() == '${pkg.version}';
  }

  Future<void> ensureRequiredInstalled(List<ContentPackage> packages,
      {void Function(String id, double progress)? onProgress}) async {
    await _contentDir();
    for (final pkg in packages.where((p) => p.required)) {
      if (!isInstalled(pkg)) await install(pkg, onProgress: onProgress);
    }
  }

  /// A bundled package that was installed at a *different* (older) version than
  /// the one shipping in this build — i.e. a content update is available.
  bool _presentButStale(ContentPackage pkg) {
    if (_dir == null) return false;
    final db = File(installedPathSync(pkg.id));
    final ok = _okMarker(pkg.id);
    return db.existsSync() &&
        ok.existsSync() &&
        ok.readAsStringSync().trim() != '${pkg.version}';
  }

  /// Refreshes bundled packages the user *already has* when their version
  /// increased (e.g. corrected commentary). Never installs a package the user
  /// never chose — optional packs stay opt-in; this only keeps existing ones
  /// current so a content update can't strand availability (e.g. gold dots).
  Future<void> refreshOutdatedBundled(List<ContentPackage> packages,
      {void Function(String id, double progress)? onProgress}) async {
    await _contentDir();
    for (final pkg in packages.where((p) => p.isBundled && _presentButStale(p))) {
      await install(pkg, onProgress: onProgress);
    }
  }

  Future<void> install(ContentPackage pkg,
      {void Function(String id, double progress)? onProgress}) async {
    await _contentDir();
    onProgress?.call(pkg.id, 0);

    final List<int> gzBytes;
    if (pkg.isBundled) {
      final data = await rootBundle.load(pkg.asset!);
      gzBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } else {
      // Remote packages (future): download pkg.url here. Not yet enabled.
      throw PackageInstallException(
          'Remote package "${pkg.id}" requires download (not enabled).');
    }
    onProgress?.call(pkg.id, 0.4);

    final dest = installedPathSync(pkg.id);
    // Decompress + write + checksum off the main isolate (no UI jank).
    final sha = await Isolate.run<String>(() {
      final out = gzip.decode(gzBytes);
      File(dest).writeAsBytesSync(out, flush: true);
      return sha256.convert(out).toString();
    });
    onProgress?.call(pkg.id, 0.9);

    if (pkg.sha256.isNotEmpty && sha != pkg.sha256) {
      File(dest).deleteSync();
      throw PackageInstallException(
          'Checksum mismatch for "${pkg.id}" (expected ${pkg.sha256}, got $sha).');
    }
    await _okMarker(pkg.id).writeAsString('${pkg.version}');
    onProgress?.call(pkg.id, 1);
  }

  Future<void> remove(ContentPackage pkg) async {
    await _contentDir();
    final db = File(installedPathSync(pkg.id));
    if (db.existsSync()) db.deleteSync();
    final ok = _okMarker(pkg.id);
    if (ok.existsSync()) ok.deleteSync();
  }
}

import 'package:flutter/foundation.dart';

enum PackageType {
  bibleTranslation,
  patristics,
  liturgy,
  catechism,
  churchDocuments,
  unknown;

  static PackageType from(String s) => switch (s) {
        'bible_translation' => bibleTranslation,
        'patristics' => patristics,
        'liturgy' => liturgy,
        'catechism' => catechism,
        'church_documents' => churchDocuments,
        _ => unknown,
      };
}

/// A unit of installable content. Bundled packages ship compressed in the app
/// (`asset`); remote packages are downloaded (`url`) — both decompress to a
/// standalone SQLite file in the app's private storage and are verified by
/// SHA-256. User data is never a content package.
@immutable
class ContentPackage {
  final String id;
  final String title;
  final String language;
  final PackageType type;
  final int version;
  final String source;
  final String license;
  final String? asset; // bundled gz asset path
  final String? url; // remote gz url (future)
  final int sizeBytes; // decompressed
  final int compressedBytes;
  final String sha256; // of the decompressed sqlite
  final bool required; // installed automatically on first launch

  const ContentPackage({
    required this.id,
    required this.title,
    required this.language,
    required this.type,
    required this.version,
    required this.source,
    required this.license,
    required this.asset,
    required this.url,
    required this.sizeBytes,
    required this.compressedBytes,
    required this.sha256,
    required this.required,
  });

  bool get isBundled => asset != null && asset!.isNotEmpty;

  factory ContentPackage.fromJson(Map<String, dynamic> j) => ContentPackage(
        id: j['id'] as String,
        title: j['title'] as String,
        language: j['language'] as String? ?? '',
        type: PackageType.from(j['type'] as String? ?? ''),
        version: (j['version'] as num?)?.toInt() ?? 1,
        source: j['source'] as String? ?? '',
        license: j['license'] as String? ?? '',
        asset: j['asset'] as String?,
        url: j['url'] as String?,
        sizeBytes: (j['sizeBytes'] as num?)?.toInt() ?? 0,
        compressedBytes: (j['compressedBytes'] as num?)?.toInt() ?? 0,
        sha256: j['sha256'] as String? ?? '',
        required: j['required'] as bool? ?? false,
      );

  /// Required metadata fields for release validation.
  static const requiredFields = [
    'id', 'title', 'language', 'type', 'version', 'source', 'license', 'sha256',
  ];
}

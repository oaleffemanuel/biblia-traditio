import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Psalm refrains for days the app does not bundle (years after the baked
/// `assets/lectionary/refrains.json`), fetched from the community liturgy API
/// (liturgia.up.railway.app, a mirror of the CNBB daily liturgy) and cached in
/// a small JSON file so each day is asked once.
class OnlineRefrains {
  OnlineRefrains._();
  static final instance = OnlineRefrains._();

  static const _host = 'liturgia.up.railway.app';
  Map<String, String>? _cache;
  final Map<String, Future<String?>> _inFlight = {};

  static String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<File> _file() async => File(
    '${(await getApplicationSupportDirectory()).path}/refrains_cache.json',
  );

  Future<Map<String, String>> _load() async {
    if (_cache != null) return _cache!;
    try {
      final f = await _file();
      if (await f.exists()) {
        _cache = (jsonDecode(await f.readAsString()) as Map).map(
          (k, v) => MapEntry('$k', '$v'),
        );
        return _cache!;
      }
    } on Object {
      // A damaged cache is simply rebuilt.
    }
    return _cache = {};
  }

  Future<String?> refrainFor(DateTime date) {
    final key = _key(date);
    return _inFlight[key] ??= _fetch(date, key);
  }

  Future<String?> _fetch(DateTime date, String key) async {
    final cache = await _load();
    if (cache.containsKey(key)) return cache[key];
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final uri = Uri.https(_host, '/v2/', {
        'dia': '${date.day}',
        'mes': '${date.month}',
        'ano': '${date.year}',
      });
      final req = await client.getUrl(uri);
      final res = await req.close().timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(await res.transform(utf8.decoder).join()) as Map;
      final psalms = ((j['leituras'] as Map?)?['salmo'] as List?) ?? const [];
      for (final p in psalms) {
        final r = '${(p as Map)['refrao'] ?? ''}'.trim();
        if (r.isNotEmpty) {
          cache[key] = r;
          (await _file()).writeAsString(jsonEncode(cache)).ignore();
          return r;
        }
      }
      return null;
    } on Object {
      return null; // offline / service down: the card degrades gracefully
    } finally {
      client.close();
    }
  }
}

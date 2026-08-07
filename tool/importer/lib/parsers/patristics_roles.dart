/// The commentator "função" (role/title) vocabulary shipped with the corrected
/// commentary corpus (`lista_funcoes_portugues.txt`). Each author entry carries
/// a semicolon-separated list drawn from this closed vocabulary — nothing here
/// is invented; every tag below appears verbatim in the source documents.
///
/// The app needs three things out of it:
///   • a stable slug per tag, so the UI can localise the label (pt/en);
///   • one concise *primary* label per author (item: "choose a concise primary
///     label"), picked by the [_primaryOrder] priority below;
///   • coarse groups (patrística / escolástica / santos) that back the
///     commentary preference filters.
library;

/// Canonical tag slugs, in the priority order used to pick an author's primary
/// label. Era/office beats vocation, and "santo" is last because "Santo — séc.
/// IV" says nothing the name doesn't already say.
const List<String> _primaryOrder = [
  'doutor-da-igreja',
  'papa',
  'documento-patristico',
  'documento-medieval',
  'documento-historico',
  'documento-geral',
  'liturgia',
  'patristica',
  'medieval',
  'cristao-primitivo',
  'exegeta',
  'teologo',
  'historiador',
  'poeta',
  'bispo',
  'monge',
  'sacerdote',
  'diacono',
  'santo',
  'santa',
];

/// Portuguese/Italian source spellings → canonical slug. Keys are normalised
/// (lowercase, accent-stripped) before lookup, so only distinct spellings need
/// an entry.
const Map<String, String> _tagBySpelling = {
  'doutor da igreja': 'doutor-da-igreja',
  'dottore della chiesa': 'doutor-da-igreja',
  'doctor of the church': 'doutor-da-igreja',
  'papa': 'papa',
  'pope': 'papa',
  'documento patristico': 'documento-patristico',
  'documento dell epoca patristica': 'documento-patristico',
  'patristic document': 'documento-patristico',
  'documento medieval': 'documento-medieval',
  'medieval document': 'documento-medieval',
  'documento historico': 'documento-historico',
  'documento storico': 'documento-historico',
  'historical document': 'documento-historico',
  'documento geral': 'documento-geral',
  'documento generale': 'documento-geral',
  'general document': 'documento-geral',
  'liturgia': 'liturgia',
  'liturgy': 'liturgia',
  'patristica': 'patristica',
  'patristics': 'patristica',
  'medieval': 'medieval',
  'cristao primitivo': 'cristao-primitivo',
  'cristianesimo antico': 'cristao-primitivo',
  'early christian': 'cristao-primitivo',
  'exegeta': 'exegeta',
  'esegeta': 'exegeta',
  'exegete': 'exegeta',
  'teologo': 'teologo',
  'teologa': 'teologo',
  'theologian': 'teologo',
  'historiador': 'historiador',
  'storico': 'historiador',
  'historian': 'historiador',
  'poeta': 'poeta',
  'poet': 'poeta',
  'bispo': 'bispo',
  'vescovo': 'bispo',
  'bishop': 'bispo',
  'monge': 'monge',
  'monaco': 'monge',
  'monk': 'monge',
  'sacerdote': 'sacerdote',
  'priest': 'sacerdote',
  'diacono': 'diacono',
  'deacon': 'diacono',
  'santo': 'santo',
  'saint': 'santo',
  'santa': 'santa',
  'beato': 'santo',
  'beata': 'santa',
  'martir': 'santo',
  'apologista': 'teologo',
  'asceta': 'monge',
  'frate': 'monge',
  'cardeal': 'bispo',
  'cardinale': 'bispo',
  'filosofo': 'teologo',
  'escritor': 'poeta',
  'scrittore': 'poeta',
  'estudioso': 'exegeta',
  'studioso': 'exegeta',
  'mistico': 'teologo',
  'retore': 'poeta',
  'fondatore': 'monge',
  'medico': 'historiador',
  'soldato': 'historiador',
  'canonico regolare': 'sacerdote',
  'vergine consacrata': 'santa',
};

/// Coarse groups backing the commentary preference filters. An author can sit
/// in more than one (a medieval saint is both "escolastica" and "santos").
const Map<String, List<String>> _groupTags = {
  'patristica': ['patristica', 'documento-patristico', 'cristao-primitivo'],
  'escolastica': ['medieval', 'documento-medieval'],
  'santos': ['santo', 'santa'],
};

/// Everything the app stores about a commentator's function/title.
class RoleInfo {
  /// The raw `função` string exactly as the corpus wrote it.
  final String raw;

  /// Canonical tag slugs, deduped, in source order.
  final List<String> tags;

  /// The single concise label to show under the author's name, as a slug.
  /// Empty when the corpus gave no recognisable function.
  final String primary;

  /// Coarse group slugs (`patristica`, `escolastica`, `santos`).
  final List<String> groups;

  const RoleInfo(this.raw, this.tags, this.primary, this.groups);

  static const empty = RoleInfo('', [], '', []);

  bool get isEmpty => tags.isEmpty;

  /// `doutor-da-igreja;santo;patristica` — the storage form.
  String get tagsColumn => tags.join(';');
  String get groupsColumn => groups.join(';');

  static RoleInfo parse(String rawFuncao) {
    final raw = rawFuncao.trim();
    if (raw.isEmpty) return empty;
    final tags = <String>[];
    for (final part in raw.split(RegExp(r'[;,/]'))) {
      final key = _normalise(part);
      if (key.isEmpty) continue;
      final slug = _tagBySpelling[key];
      // Unknown spellings are dropped rather than invented into a title.
      if (slug != null && !tags.contains(slug)) tags.add(slug);
    }
    if (tags.isEmpty) return RoleInfo(raw, const [], '', const []);
    final primary = _primaryOrder.firstWhere(tags.contains, orElse: () => '');
    final groups = <String>[
      for (final entry in _groupTags.entries)
        if (entry.value.any(tags.contains)) entry.key,
    ];
    return RoleInfo(raw, tags, primary, groups);
  }

  static String _normalise(String s) => s
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[áàâãä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòôõö]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u')
      .replaceAll(RegExp(r'[ç]'), 'c')
      .replaceAll(RegExp(r"[^a-z0-9]+"), ' ')
      .trim();
}

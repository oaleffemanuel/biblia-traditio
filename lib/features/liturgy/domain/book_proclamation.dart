/// How each book is named when the reading is announced at Mass.
///
/// The reader sees "Livro do Profeta Naum", not "Na" — the lector's own words.
/// Two forms are needed because Portuguese contracts the preposition:
///   • [title]  — "Livro do Profeta Naum"     (heading on the card)
///   • [ofForm] — "do Livro do Profeta Naum"  ("Leitura **do** Livro…")
///
/// Gospels are announced differently ("Evangelho de Jesus Cristo segundo São
/// Marcos") and are handled by the card, not by this table.
class BookProclamation {
  final String title;
  final String ofForm;
  const BookProclamation(this.title, this.ofForm);
}

/// `da`/`do` is fixed per book by its grammatical gender, so it is written out
/// rather than guessed from the title.
BookProclamation? proclamationFor(String bookId) => _byId[bookId];

BookProclamation _p(String title, {bool feminine = false}) =>
    BookProclamation(title, '${feminine ? 'da' : 'do'} $title');

final Map<String, BookProclamation> _byId = {
  // ── Pentateuch & historical ──────────────────────────────────────────────
  'gn': _p('Livro do Gênesis'),
  'ex': _p('Livro do Êxodo'),
  'lv': _p('Livro do Levítico'),
  'nm': _p('Livro dos Números'),
  'dt': _p('Livro do Deuteronômio'),
  'jo': _p('Livro de Josué'),
  'jgs': _p('Livro dos Juízes'),
  'rt': _p('Livro de Rute'),
  '1sm': _p('Primeiro Livro de Samuel'),
  '2sm': _p('Segundo Livro de Samuel'),
  '1kgs': _p('Primeiro Livro dos Reis'),
  '2kgs': _p('Segundo Livro dos Reis'),
  '1chr': _p('Primeiro Livro das Crônicas'),
  '2chr': _p('Segundo Livro das Crônicas'),
  'ezr': _p('Livro de Esdras'),
  'neh': _p('Livro de Neemias'),
  'tb': _p('Livro de Tobias'),
  'jdt': _p('Livro de Judite'),
  'est': _p('Livro de Ester'),
  '1mac': _p('Primeiro Livro dos Macabeus'),
  '2mac': _p('Segundo Livro dos Macabeus'),

  // ── Wisdom ───────────────────────────────────────────────────────────────
  'jb': _p('Livro de Jó'),
  'ps': _p('Livro dos Salmos'),
  'prv': _p('Livro dos Provérbios'),
  'eccl': _p('Livro do Eclesiastes'),
  'sg': _p('Cântico dos Cânticos', feminine: false),
  'ws': _p('Livro da Sabedoria'),
  'sir': _p('Livro do Eclesiástico'),

  // ── Prophets ─────────────────────────────────────────────────────────────
  'is': _p('Livro do Profeta Isaías'),
  'jer': _p('Livro do Profeta Jeremias'),
  'lam': _p('Livro das Lamentações'),
  'bar': _p('Livro do Profeta Baruc'),
  'ez': _p('Livro do Profeta Ezequiel'),
  'dn': _p('Livro do Profeta Daniel'),
  'hos': _p('Livro do Profeta Oseias'),
  'jl': _p('Livro do Profeta Joel'),
  'am': _p('Livro do Profeta Amós'),
  'ob': _p('Livro do Profeta Abdias'),
  'jon': _p('Livro do Profeta Jonas'),
  'mi': _p('Livro do Profeta Miqueias'),
  'na': _p('Livro do Profeta Naum'),
  'hb': _p('Livro do Profeta Habacuc'),
  'zep': _p('Livro do Profeta Sofonias'),
  'hg': _p('Livro do Profeta Ageu'),
  'zec': _p('Livro do Profeta Zacarias'),
  'mal': _p('Livro do Profeta Malaquias'),

  // ── Gospels (announced separately; kept for the card heading) ────────────
  'mt': _p('Evangelho segundo São Mateus'),
  'mk': _p('Evangelho segundo São Marcos'),
  'lk': _p('Evangelho segundo São Lucas'),
  'jn': _p('Evangelho segundo São João'),

  // ── Acts & Letters ───────────────────────────────────────────────────────
  'acts': _p('Livro dos Atos dos Apóstolos'),
  'rom': _p('Carta de São Paulo aos Romanos', feminine: true),
  '1cor': _p('Primeira Carta de São Paulo aos Coríntios', feminine: true),
  '2cor': _p('Segunda Carta de São Paulo aos Coríntios', feminine: true),
  'gal': _p('Carta de São Paulo aos Gálatas', feminine: true),
  'eph': _p('Carta de São Paulo aos Efésios', feminine: true),
  'phil': _p('Carta de São Paulo aos Filipenses', feminine: true),
  'col': _p('Carta de São Paulo aos Colossenses', feminine: true),
  '1thes':
      _p('Primeira Carta de São Paulo aos Tessalonicenses', feminine: true),
  '2thes': _p('Segunda Carta de São Paulo aos Tessalonicenses', feminine: true),
  '1tm': _p('Primeira Carta de São Paulo a Timóteo', feminine: true),
  '2tm': _p('Segunda Carta de São Paulo a Timóteo', feminine: true),
  'tit': _p('Carta de São Paulo a Tito', feminine: true),
  'phlm': _p('Carta de São Paulo a Filêmon', feminine: true),
  'heb': _p('Carta aos Hebreus', feminine: true),
  'jas': _p('Carta de São Tiago', feminine: true),
  '1pt': _p('Primeira Carta de São Pedro', feminine: true),
  '2pt': _p('Segunda Carta de São Pedro', feminine: true),
  '1jn': _p('Primeira Carta de São João', feminine: true),
  '2jn': _p('Segunda Carta de São João', feminine: true),
  '3jn': _p('Terceira Carta de São João', feminine: true),
  'jud': _p('Carta de São Judas', feminine: true),
  'rv': _p('Livro do Apocalipse de São João'),
};

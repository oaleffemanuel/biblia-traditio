/// Canonical Catholic 73-book registry.
///
/// Book `id`s deliberately match the codes used by the patristic corpus
/// (`jo` = Josué, `jn` = João, etc.) so commentaries map 1:1 with no remap.
/// `aliases_normalizados.json` resolves any source-code variants onto these.
library;

enum Testament { ot, nt }

class CanonBook {
  final String id;
  final Testament testament;
  final int order; // 1..73, Catholic (Vulgate/CNBB) order
  final bool deutero;
  final int chapterCount; // default count; scripture validation uses as a hint
  final String namePt;
  final String abbrevPt;

  const CanonBook(this.id, this.testament, this.order, this.deutero,
      this.chapterCount, this.namePt, this.abbrevPt);
}

const List<CanonBook> kCanon = [
  // ── Old Testament (46) ──
  CanonBook('gn', Testament.ot, 1, false, 50, 'Gênesis', 'Gn'),
  CanonBook('ex', Testament.ot, 2, false, 40, 'Êxodo', 'Ex'),
  CanonBook('lv', Testament.ot, 3, false, 27, 'Levítico', 'Lv'),
  CanonBook('nm', Testament.ot, 4, false, 36, 'Números', 'Nm'),
  CanonBook('dt', Testament.ot, 5, false, 34, 'Deuteronômio', 'Dt'),
  CanonBook('jo', Testament.ot, 6, false, 24, 'Josué', 'Js'),
  CanonBook('jgs', Testament.ot, 7, false, 21, 'Juízes', 'Jz'),
  CanonBook('rt', Testament.ot, 8, false, 4, 'Rute', 'Rt'),
  CanonBook('1sm', Testament.ot, 9, false, 31, 'I Samuel', '1Sm'),
  CanonBook('2sm', Testament.ot, 10, false, 24, 'II Samuel', '2Sm'),
  CanonBook('1kgs', Testament.ot, 11, false, 22, 'I Reis', '1Rs'),
  CanonBook('2kgs', Testament.ot, 12, false, 25, 'II Reis', '2Rs'),
  CanonBook('1chr', Testament.ot, 13, false, 29, 'I Crônicas', '1Cr'),
  CanonBook('2chr', Testament.ot, 14, false, 36, 'II Crônicas', '2Cr'),
  CanonBook('ezr', Testament.ot, 15, false, 10, 'Esdras', 'Esd'),
  CanonBook('neh', Testament.ot, 16, false, 13, 'Neemias', 'Ne'),
  CanonBook('tb', Testament.ot, 17, true, 14, 'Tobias', 'Tb'),
  CanonBook('jdt', Testament.ot, 18, true, 16, 'Judite', 'Jt'),
  CanonBook('est', Testament.ot, 19, false, 16, 'Ester', 'Est'),
  CanonBook('1mac', Testament.ot, 20, true, 16, 'I Macabeus', '1Mac'),
  CanonBook('2mac', Testament.ot, 21, true, 15, 'II Macabeus', '2Mac'),
  CanonBook('jb', Testament.ot, 22, false, 42, 'Jó', 'Jó'),
  CanonBook('ps', Testament.ot, 23, false, 150, 'Salmos', 'Sl'),
  CanonBook('prv', Testament.ot, 24, false, 31, 'Provérbios', 'Pr'),
  CanonBook('eccl', Testament.ot, 25, false, 12, 'Eclesiastes', 'Ecl'),
  CanonBook('sg', Testament.ot, 26, false, 8, 'Cântico dos Cânticos', 'Ct'),
  CanonBook('ws', Testament.ot, 27, true, 19, 'Sabedoria', 'Sb'),
  CanonBook('sir', Testament.ot, 28, true, 51, 'Eclesiástico', 'Eclo'),
  CanonBook('is', Testament.ot, 29, false, 66, 'Isaías', 'Is'),
  CanonBook('jer', Testament.ot, 30, false, 52, 'Jeremias', 'Jr'),
  CanonBook('lam', Testament.ot, 31, false, 5, 'Lamentações', 'Lm'),
  CanonBook('bar', Testament.ot, 32, true, 6, 'Baruc', 'Br'),
  CanonBook('ez', Testament.ot, 33, false, 48, 'Ezequiel', 'Ez'),
  CanonBook('dn', Testament.ot, 34, false, 14, 'Daniel', 'Dn'),
  CanonBook('hos', Testament.ot, 35, false, 14, 'Oseias', 'Os'),
  CanonBook('jl', Testament.ot, 36, false, 3, 'Joel', 'Jl'),
  CanonBook('am', Testament.ot, 37, false, 9, 'Amós', 'Am'),
  CanonBook('ob', Testament.ot, 38, false, 1, 'Abdias', 'Ab'),
  CanonBook('jon', Testament.ot, 39, false, 4, 'Jonas', 'Jn'),
  CanonBook('mi', Testament.ot, 40, false, 7, 'Miqueias', 'Mq'),
  CanonBook('na', Testament.ot, 41, false, 3, 'Naum', 'Na'),
  CanonBook('hb', Testament.ot, 42, false, 3, 'Habacuc', 'Hab'),
  CanonBook('zep', Testament.ot, 43, false, 3, 'Sofonias', 'Sf'),
  CanonBook('hg', Testament.ot, 44, false, 2, 'Ageu', 'Ag'),
  CanonBook('zec', Testament.ot, 45, false, 14, 'Zacarias', 'Zc'),
  CanonBook('mal', Testament.ot, 46, false, 4, 'Malaquias', 'Ml'),
  // ── New Testament (27) ──
  CanonBook('mt', Testament.nt, 47, false, 28, 'Mateus', 'Mt'),
  CanonBook('mk', Testament.nt, 48, false, 16, 'Marcos', 'Mc'),
  CanonBook('lk', Testament.nt, 49, false, 24, 'Lucas', 'Lc'),
  CanonBook('jn', Testament.nt, 50, false, 21, 'João', 'Jo'),
  CanonBook('acts', Testament.nt, 51, false, 28, 'Atos dos Apóstolos', 'At'),
  CanonBook('rom', Testament.nt, 52, false, 16, 'Romanos', 'Rm'),
  CanonBook('1cor', Testament.nt, 53, false, 16, 'I Coríntios', '1Cor'),
  CanonBook('2cor', Testament.nt, 54, false, 13, 'II Coríntios', '2Cor'),
  CanonBook('gal', Testament.nt, 55, false, 6, 'Gálatas', 'Gl'),
  CanonBook('eph', Testament.nt, 56, false, 6, 'Efésios', 'Ef'),
  CanonBook('phil', Testament.nt, 57, false, 4, 'Filipenses', 'Fp'),
  CanonBook('col', Testament.nt, 58, false, 4, 'Colossenses', 'Cl'),
  CanonBook('1thes', Testament.nt, 59, false, 5, 'I Tessalonicenses', '1Ts'),
  CanonBook('2thes', Testament.nt, 60, false, 3, 'II Tessalonicenses', '2Ts'),
  CanonBook('1tm', Testament.nt, 61, false, 6, 'I Timóteo', '1Tm'),
  CanonBook('2tm', Testament.nt, 62, false, 4, 'II Timóteo', '2Tm'),
  CanonBook('tit', Testament.nt, 63, false, 3, 'Tito', 'Tt'),
  CanonBook('phlm', Testament.nt, 64, false, 1, 'Filêmon', 'Fm'),
  CanonBook('heb', Testament.nt, 65, false, 13, 'Hebreus', 'Hb'),
  CanonBook('jas', Testament.nt, 66, false, 5, 'Tiago', 'Tg'),
  CanonBook('1pt', Testament.nt, 67, false, 5, 'I Pedro', '1Pd'),
  CanonBook('2pt', Testament.nt, 68, false, 3, 'II Pedro', '2Pd'),
  CanonBook('1jn', Testament.nt, 69, false, 5, 'I João', '1Jo'),
  CanonBook('2jn', Testament.nt, 70, false, 1, 'II João', '2Jo'),
  CanonBook('3jn', Testament.nt, 71, false, 1, 'III João', '3Jo'),
  CanonBook('jud', Testament.nt, 72, false, 1, 'Judas', 'Jd'),
  CanonBook('rv', Testament.nt, 73, false, 22, 'Apocalipse', 'Ap'),
];

final Map<String, CanonBook> kCanonById = {
  for (final b in kCanon) b.id: b,
};

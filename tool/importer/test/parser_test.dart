import 'package:biblia_traditio_importer/parsers/scripture_parser.dart';
import 'package:biblia_traditio_importer/validators/verse_validator.dart';
import 'package:test/test.dart';

void main() {
  group('anti-drift parsing', () {
    test('section title is NOT imported as a verse and does not shift numbers',
        () {
      // The exact failure case from the spec.
      const raw = '''
CAPÍTULO I
LIVRO SAPIENCIAL
1 O temor do Senhor é o princípio da sabedoria, e a coroa dos justos.
2 A sabedoria foi criada antes de todas as coisas pela vontade de Deus.
''';
      final chapters = ScriptureParser().parseBook(raw);
      expect(chapters, hasLength(1));
      final ch = chapters.first;

      // Heading captured as metadata, above verse 1.
      expect(ch.headings.any((h) => h.text == 'LIVRO SAPIENCIAL'), isTrue);
      expect(ch.headings.first.beforeVerse, 1);

      // Verse 1 is genuine scripture — NOT "LIVRO SAPIENCIAL".
      expect(ch.verses.first.verse, 1);
      expect(ch.verses.first.text, startsWith('O temor do Senhor'));

      // No drift: verse 2 is still verse 2.
      expect(ch.verses[1].verse, 2);
      expect(ch.verses, hasLength(2));
    });

    test('numbered line whose body is a title is rejected as a verse', () {
      const raw = '''
CAPÍTULO I
1 LIVRO SAPIENCIAL
2 Verdadeiro princípio da sabedoria é o temor de Deus entre os homens.
''';
      final chapters = ScriptureParser().parseBook(raw);
      final ch = chapters.first;
      // "LIVRO SAPIENCIAL" must not be stored as verse 1's text.
      expect(ch.verses.any((v) => v.text == 'LIVRO SAPIENCIAL'), isFalse);
    });

    test('numbered all-caps title is filtered before it can reach the DB', () {
      const raw = '''
CAPÍTULO I
1 PRIMEIRA PARTE
2 Bem-aventurado o homem que teme ao Senhor e anda nos seus caminhos.
''';
      final chapters = ScriptureParser().parseBook(raw);
      final report = VerseValidator().validate('sir', chapters);
      // "PRIMEIRA PARTE" was caught by the detector as a heading, so the verse
      // list never contains it — and the validator sees no all-caps verse.
      final ch = chapters.first;
      expect(ch.verses.any((v) => v.text == 'PRIMEIRA PARTE'), isFalse);
      expect(ch.headings.any((h) => h.text == 'PRIMEIRA PARTE'), isTrue);
      expect(report.findings.any((f) => f.code == 'allcaps_verse'), isFalse);
      expect(report.findings.any((f) => f.code == 'heading_as_verse'), isFalse);
    });

    test('roman + arabic chapter markers both parse', () {
      const raw = '''
CAPÍTULO I
1 Texto do primeiro capítulo com palavras suficientes.
CAPÍTULO 2
1 Texto do segundo capítulo com palavras suficientes aqui.
''';
      final chapters = ScriptureParser().parseBook(raw);
      expect(chapters.map((c) => c.chapter), [1, 2]);
    });
  });
}

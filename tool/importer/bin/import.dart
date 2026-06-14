import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:biblia_traditio_importer/builders/sqlite_builder.dart';
import 'package:biblia_traditio_importer/models/blocks.dart';
import 'package:biblia_traditio_importer/parsers/bible_json_parser.dart';
import 'package:biblia_traditio_importer/parsers/patristics_parser.dart';
import 'package:biblia_traditio_importer/parsers/usfx_parser.dart';
import 'package:biblia_traditio_importer/parsers/scripture_parser.dart';
import 'package:biblia_traditio_importer/validators/verse_validator.dart';
import 'package:path/path.dart' as p;

/// Biblia Traditio content build pipeline.
///
///   dart run bin/import.dart patristics --src <dir> --out <db>
///   dart run bin/import.dart scripture  --book <id> --translation <id> \
///                                       --src <file.txt> --out <db> [--no-strict]
///   dart run bin/import.dart stats      --out <db>
Future<void> main(List<String> argv) async {
  if (argv.isEmpty) {
    _usageAndExit();
  }
  final cmd = argv.first;
  final rest = argv.skip(1).toList();
  switch (cmd) {
    case 'patristics':
      await _patristics(rest);
      break;
    case 'scripture':
      await _scripture(rest);
      break;
    case 'biblejson':
      await _bibleJson(rest);
      break;
    case 'usfx':
      await _usfx(rest);
      break;
    case 'stats':
      await _stats(rest);
      break;
    default:
      _usageAndExit();
  }
}

Future<void> _patristics(List<String> argv) async {
  final a = (ArgParser()
        ..addOption('src', help: 'Comentários dir with coment-*.json')
        ..addOption('out', defaultsTo: 'biblia_traditio.sqlite'))
      .parse(argv);
  final src = a['src'] as String?;
  if (src == null) _fail('patristics: --src <dir> required');

  stdout.writeln('▶ Ingesting patristics from: $src');
  final parser = await PatristicsParser.fromDir(src!);
  final res = await parser.parseDir(src);

  stdout.writeln('  files: ${res.filesProcessed}'
      ' · commentaries: ${res.commentaries.length}'
      ' · fathers: ${res.fathers.length}'
      ' · unresolved books: ${res.orphans}');
  for (final w in res.warnings.take(20)) {
    stdout.writeln('  ⚠ $w');
  }

  final builder = ContentDbBuilder.open(a['out'] as String);
  builder.insertPatristics(res);
  builder.setMeta('patristics_count', '${res.commentaries.length}');
  builder.setMeta('built_patristics_at_files', '${res.filesProcessed}');
  builder.finish();
  stdout.writeln('✓ Patristics written to ${a['out']}');
}

Future<void> _scripture(List<String> argv) async {
  final a = (ArgParser()
        ..addOption('book')
        ..addOption('translation')
        ..addOption('lang', defaultsTo: 'pt')
        ..addOption('title', defaultsTo: '')
        ..addOption('src')
        ..addOption('out', defaultsTo: 'biblia_traditio.sqlite')
        ..addOption('report-dir', defaultsTo: 'data/reports')
        ..addOption('normalized-dir', defaultsTo: 'data/normalized')
        ..addFlag('strict', defaultsTo: true,
            help: 'Refuse to write the DB if validation has errors'))
      .parse(argv);

  final book = a['book'] as String?;
  final translation = a['translation'] as String?;
  final src = a['src'] as String?;
  if (book == null || translation == null || src == null) {
    _fail('scripture: --book, --translation and --src are required');
  }

  final raw = await File(src!).readAsString();
  stdout.writeln('▶ Parsing scripture: book=$book translation=$translation');

  // Stage 1+2: parse → chapters.
  final chapters = ScriptureParser().parseBook(raw);
  final verseTotal = chapters.fold<int>(0, (s, c) => s + c.verses.length);
  final headingTotal = chapters.fold<int>(0, (s, c) => s + c.headings.length);
  stdout.writeln('  chapters: ${chapters.length}'
      ' · verses: $verseTotal · headings(metadata): $headingTotal');

  // Stage 2: validate.
  final report = VerseValidator().validate(book!, chapters);
  Directory(a['report-dir'] as String).createSync(recursive: true);
  final reportPath = p.join(a['report-dir'] as String, '$book.report.json');
  await File(reportPath)
      .writeAsString(const JsonEncoder.withIndent('  ').convert(report.toJson()));
  stdout.writeln('  validation: ${report.errorCount} errors,'
      ' ${report.warningCount} warnings → $reportPath');
  for (final f in report.findings.where((f) => f.severity == Severity.error).take(15)) {
    stdout.writeln('  ✗ [${f.code}] ch ${f.chapter}:${f.verse} ${f.message}'
        '${f.sample != null ? '  «${_clip(f.sample!)}»' : ''}');
  }

  // Stage 3: normalized JSON (review artifact).
  Directory(a['normalized-dir'] as String).createSync(recursive: true);
  final normPath = p.join(a['normalized-dir'] as String, '$book.json');
  await File(normPath).writeAsString(const JsonEncoder.withIndent('  ').convert({
    'book': book,
    'translation': translation,
    'chapters': chapters.map((c) => c.toJson()).toList(),
  }));
  stdout.writeln('  normalized → $normPath');

  // Stage 4: build (gated by strict mode).
  if (report.hasErrors && (a['strict'] as bool)) {
    _fail('Refusing to build: ${report.errorCount} validation error(s). '
        'Fix the source or re-run with --no-strict.');
  }
  final builder = ContentDbBuilder.open(a['out'] as String);
  builder.upsertTranslation(translation, a['lang'] as String,
      (a['title'] as String).isEmpty ? translation : a['title'] as String);
  builder.insertScripture(translation, book, chapters);
  builder.finish();
  stdout.writeln('✓ Scripture written to ${a['out']}');
}

Future<void> _bibleJson(List<String> argv) async {
  final a = (ArgParser()
        ..addOption('src', help: 'Structured Bible JSON (antigo/novoTestamento)')
        ..addOption('translation', defaultsTo: 'pt_cat')
        ..addOption('lang', defaultsTo: 'pt')
        ..addOption('title', defaultsTo: 'Bíblia Católica (PT)')
        ..addOption('license', defaultsTo: '')
        ..addOption('out', defaultsTo: 'biblia_traditio.sqlite')
        ..addOption('report-dir', defaultsTo: 'data/reports')
        ..addFlag('strict', defaultsTo: false))
      .parse(argv);
  final src = a['src'] as String?;
  if (src == null) _fail('biblejson: --src <file.json> required');

  stdout.writeln('▶ Parsing structured Bible JSON: $src');
  final parser = BibleJsonParser();
  await parser.parseFile(src!);
  for (final w in parser.warnings) {
    stdout.writeln('  ⚠ $w');
  }
  stdout.writeln('  books: ${parser.books.length} · verses: ${parser.verseCount}');

  // Validate every book; collect errors.
  Directory(a['report-dir'] as String).createSync(recursive: true);
  var totalErrors = 0, totalWarnings = 0;
  final validator = VerseValidator();
  for (final entry in parser.books.entries) {
    final report = validator.validate(entry.key, entry.value);
    totalErrors += report.errorCount;
    totalWarnings += report.warningCount;
    if (report.hasErrors) {
      for (final f in report.findings.where((f) => f.severity == Severity.error).take(5)) {
        stdout.writeln('  ✗ ${entry.key} ${f.chapter}:${f.verse} [${f.code}] ${f.message}');
      }
    }
  }
  stdout.writeln('  validation: $totalErrors errors, $totalWarnings warnings');
  if (totalErrors > 0 && (a['strict'] as bool)) {
    _fail('Refusing to build: $totalErrors validation error(s).');
  }

  final builder = ContentDbBuilder.open(a['out'] as String);
  builder.upsertTranslation(
    a['translation'] as String,
    a['lang'] as String,
    a['title'] as String,
    license: (a['license'] as String).isEmpty ? null : a['license'] as String,
    versification: 'vulgate',
  );
  for (final entry in parser.books.entries) {
    builder.insertScripture(a['translation'] as String, entry.key, entry.value);
  }
  builder.setMeta('scripture_verses', '${parser.verseCount}');
  builder.finish();
  stdout.writeln('✓ Scripture written to ${a['out']} '
      '(translation=${a['translation']})');
}

Future<void> _usfx(List<String> argv) async {
  final a = (ArgParser()
        ..addOption('src', help: 'USFX XML (e.g. Clementine Vulgate)')
        ..addOption('translation', defaultsTo: 'vulgata')
        ..addOption('lang', defaultsTo: 'la')
        ..addOption('title', defaultsTo: 'Vulgata Clementina')
        ..addOption('license', defaultsTo: 'Domínio público')
        ..addOption('out', defaultsTo: 'biblia_traditio.sqlite')
        ..addOption('report-dir', defaultsTo: 'data/reports')
        ..addFlag('strict', defaultsTo: false))
      .parse(argv);
  final src = a['src'] as String?;
  if (src == null) _fail('usfx: --src <file.xml> required');

  stdout.writeln('▶ Parsing USFX: $src');
  final parser = UsfxParser();
  await parser.parseFile(src!);
  for (final w in parser.warnings) {
    stdout.writeln('  ⚠ $w');
  }
  stdout.writeln('  books: ${parser.books.length} · verses: ${parser.verseCount}');

  _validateAndInsertBible(
    books: parser.books,
    translation: a['translation'] as String,
    lang: a['lang'] as String,
    title: a['title'] as String,
    license: a['license'] as String,
    out: a['out'] as String,
    reportDir: a['report-dir'] as String,
    strict: a['strict'] as bool,
  );
}

/// Shared: validate every book, write reports, refuse on errors under --strict,
/// then insert the translation and record a validation flag in `meta`.
void _validateAndInsertBible({
  required Map<String, List<ParsedChapter>> books,
  required String translation,
  required String lang,
  required String title,
  required String license,
  required String out,
  required String reportDir,
  required bool strict,
}) {
  Directory(reportDir).createSync(recursive: true);
  var totalErrors = 0, totalWarnings = 0;
  final validator = VerseValidator();
  for (final entry in books.entries) {
    final report = validator.validate(entry.key, entry.value);
    totalErrors += report.errorCount;
    totalWarnings += report.warningCount;
    if (report.hasErrors) {
      for (final f
          in report.findings.where((f) => f.severity == Severity.error).take(5)) {
        stdout.writeln('  ✗ ${entry.key} ${f.chapter}:${f.verse} '
            '[${f.code}] ${f.message}');
      }
    }
  }
  stdout.writeln('  validation: $totalErrors errors, $totalWarnings warnings');
  if (totalErrors > 0 && strict) {
    _fail('Refusing to build: $totalErrors validation error(s).');
  }

  final builder = ContentDbBuilder.open(out);
  builder.upsertTranslation(translation, lang, title,
      license: license.isEmpty ? null : license, versification: 'vulgate');
  for (final entry in books.entries) {
    builder.insertScripture(translation, entry.key, entry.value);
  }
  builder.setMeta('bible_validation_errors', '$totalErrors');
  builder.finish();
  stdout.writeln('✓ Scripture written to $out (translation=$translation)');
}

Future<void> _stats(List<String> argv) async {
  final a = (ArgParser()..addOption('out', defaultsTo: 'biblia_traditio.sqlite'))
      .parse(argv);
  final path = a['out'] as String;
  if (!File(path).existsSync()) _fail('stats: $path not found');
  // Use the sqlite3 CLI-free path via the builder's open just to query.
  final b = ContentDbBuilder.open(path);
  int q(String sql) => (b.db.select(sql).first.values.first as int);
  stdout.writeln('── $path ──');
  stdout.writeln('books:        ${q('SELECT COUNT(*) FROM book')}');
  stdout.writeln('translations: ${q('SELECT COUNT(*) FROM translation')}');
  stdout.writeln('verses:       ${q('SELECT COUNT(*) FROM verse')}');
  stdout.writeln('fathers:      ${q('SELECT COUNT(*) FROM father')}');
  stdout.writeln('commentaries: ${q('SELECT COUNT(*) FROM commentary')}');
  final byBook = b.db.select(
      'SELECT book_id, COUNT(*) n FROM commentary GROUP BY book_id ORDER BY n DESC LIMIT 5');
  stdout.writeln('top books by commentary:');
  for (final r in byBook) {
    stdout.writeln('  ${r['book_id']}: ${r['n']}');
  }
  b.db.dispose();
}

String _clip(String s) => s.length > 60 ? '${s.substring(0, 60)}…' : s;

Never _fail(String msg) {
  stderr.writeln('ERROR: $msg');
  exit(1);
}

Never _usageAndExit() {
  stderr.writeln('''
Biblia Traditio importer
  dart run bin/import.dart patristics --src <Comentários dir> --out <db>
  dart run bin/import.dart scripture  --book gn --translation matos1932 --src book.txt --out <db>
  dart run bin/import.dart stats      --out <db>
''');
  exit(64);
}

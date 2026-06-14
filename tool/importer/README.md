# Biblia Traditio — Content Importer

Offline build pipeline that turns raw sources into the bundled read-only
**SQLite (+FTS5)** content database the app ships. **Not** part of the Flutter app.

Pipeline: `RAW → [1 Parse] → [2 Validate] → [3 Normalize JSON] → [4 Build DB]`.
Correctness over speed: editorial headings are never stored as verses, and verse
numbers come from the source marker (never a position counter), so a
misclassified heading can't shift subsequent verse numbering.

## Setup
```bash
cd tool/importer
dart pub get
dart test          # proves the anti-drift parsing rules
```

## Ingest the patristic corpus (verse-keyed JSON)
```bash
dart run bin/import.dart patristics \
  --src "/path/to/Comentários" \
  --out data/biblia_traditio.sqlite
```
Current real corpus → **73 books, 223 Fathers, 57,485 commentaries**, 0 unresolved.

## Import a scripture translation (plain text, one verse per line)
```bash
dart run bin/import.dart scripture \
  --book gn --translation matos1932 --lang pt --title "Matos Soares (1932)" \
  --src data/raw/gn.txt --out data/biblia_traditio.sqlite
# add --no-strict to build despite validation errors (writes report either way)
```
Artifacts: `data/reports/<book>.report.json` (validation), `data/normalized/<book>.json` (review).

## Inspect a built DB
```bash
dart run bin/import.dart stats --out data/biblia_traditio.sqlite
```

## Detection rules (heading vs verse)
A line is a **verse** only with a leading source verse number **and** genuine
scripture text. Everything else → metadata: fully-uppercase short lines and
title-case lines = `section`; `CAPÍTULO N` = chapter marker (consumed);
`INTRODUÇÃO/NOTA/PREFÁCIO/…` = editorial note; long unnumbered prose after a
verse = continuation (appended). See `lib/detectors/heading_detector.dart`.

## Validation findings (errors block the build under `--strict`)
duplicate_verse · verse_order · allcaps_verse · heading_as_verse · empty_verse
(errors) — verse_gap · missing_first · short_verse · chapter_count (warnings).

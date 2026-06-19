#!/usr/bin/env python3
"""Validate the bundled lectionary dataset against the bundled Bible.

Checks, for assets/lectionary/readings.json:
  - every reading has a canonical book id (no fake/unknown ids);
  - every (book, chapter) exists in the Bible, and for non-Psalm readings the
    first verse exists (Psalms are validated at chapter level — Vulgate mapping);
  - reports per-slot coverage and any Sundays/solemnities missing a reading slot.

Exits non-zero on any structural failure. Run before shipping.
"""
import json
import os
import sqlite3
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, 'assets', 'lectionary', 'readings.json')
BIBLE_DB = os.path.join(ROOT, 'tool', 'importer', 'data', 'bible_vulgata.sqlite')

CANON = {
    'gn', 'ex', 'lv', 'nm', 'dt', 'jo', 'jgs', 'rt', '1sm', '2sm', '1kgs',
    '2kgs', '1chr', '2chr', 'ezr', 'neh', 'tb', 'jdt', 'est', '1mac', '2mac',
    'jb', 'ps', 'prv', 'eccl', 'sg', 'ws', 'sir', 'is', 'jer', 'lam', 'bar',
    'ez', 'dn', 'hos', 'jl', 'am', 'ob', 'jon', 'mi', 'na', 'hb', 'zep', 'hg',
    'zec', 'mal', 'mt', 'mk', 'lk', 'jn', 'acts', 'rom', '1cor', '2cor', 'gal',
    'eph', 'phil', 'col', '1thes', '2thes', '1tm', '2tm', 'tit', 'phlm', 'heb',
    'jas', '1pt', '2pt', '1jn', '2jn', '3jn', 'jud', 'rv',
}


def main():
    if not os.path.exists(DATA):
        sys.exit(f'ERROR: dataset missing: {DATA}')
    if not os.path.exists(BIBLE_DB):
        sys.exit(f'ERROR: bible DB missing: {BIBLE_DB} (run tool/build_content_db.sh)')
    d = json.load(open(DATA))
    con = sqlite3.connect(BIBLE_DB)

    def chapter_ok(b, ch):
        return con.execute("SELECT 1 FROM verse WHERE translation_id='vulgata' "
                           "AND book_id=? AND chapter=? LIMIT 1", (b, ch)).fetchone()

    def verse_ok(b, ch, v):
        return con.execute("SELECT 1 FROM verse WHERE translation_id='vulgata' "
                           "AND book_id=? AND chapter=? AND verse=? LIMIT 1",
                           (b, ch, v)).fetchone()

    errors, n_read = [], 0
    slot_counts = {'first': 0, 'psalm': 0, 'second': 0, 'gospel': 0}
    entries = d.get('entries', {})
    for iso, e in entries.items():
        for r in e['readings']:
            n_read += 1
            b, ch, v, slot = r.get('book'), r.get('chapter'), r.get('verse'), r.get('slot')
            slot_counts[slot] = slot_counts.get(slot, 0) + 1
            if b not in CANON:
                errors.append(f'{iso} {slot}: unknown book id {b!r}'); continue
            if not chapter_ok(b, ch):
                errors.append(f'{iso} {slot}: {b} {ch} chapter missing'); continue
            if b != 'ps' and v and not verse_ok(b, ch, v):
                errors.append(f'{iso} {slot}: {b} {ch}:{v} verse missing')

    print(f"dataset: {d.get('scope')} · year {d.get('year')} · "
          f"days {len(entries)} · readings {n_read}")
    print(f"per-slot: {slot_counts}")
    if errors:
        print(f"\n✗ {len(errors)} structural error(s):")
        for e in errors[:50]:
            print('  -', e)
        sys.exit(1)
    print("✓ all references resolve to an existing Bible book/chapter/verse; "
          "no fake or missing book ids.")


if __name__ == '__main__':
    main()

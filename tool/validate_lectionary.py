#!/usr/bin/env python3
"""Validate the bundled lectionary dataset against the bundled Bible.

Checks (errors fail the build; warnings are reported only):
  ERRORS  - unknown/fake book id; chapter missing in the Bible; first verse of a
            non-Psalm reading missing; Psalm target not the Vulgate mapping of
            its displayed (Hebrew) number; duplicate slot on a day.
  WARN    - days with no readings; days missing a Gospel / first reading / psalm.
            (A missing SECOND reading is normal on weekdays, not reported.)

Also reports date coverage and per-slot counts. Run before shipping.
"""
import datetime
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


def psalm_heb_to_vulgate(h):
    if h <= 8: return h
    if h in (9, 10): return 9
    if h <= 113: return h - 1
    if h in (114, 115): return 113
    if h == 116: return 114
    if h <= 146: return h - 1
    if h == 147: return 146
    return h


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

    entries = d.get('entries', {})
    year = d.get('year')
    errors, warnings, n_read = [], [], 0
    slot_counts = {'first': 0, 'psalm': 0, 'second': 0, 'gospel': 0}

    for iso, e in sorted(entries.items()):
        slots_seen = set()
        for r in e['readings']:
            n_read += 1
            b, ch, v = r.get('book'), r.get('chapter'), r.get('verse')
            slot, disp = r.get('slot'), r.get('displayChapter')
            slot_counts[slot] = slot_counts.get(slot, 0) + 1
            if slot in slots_seen:
                errors.append(f'{iso}: duplicate slot {slot!r}')
            slots_seen.add(slot)
            if b not in CANON:
                errors.append(f'{iso} {slot}: unknown book id {b!r}'); continue
            if not chapter_ok(b, ch):
                errors.append(f'{iso} {slot}: {b} {ch} chapter missing'); continue
            if b != 'ps' and v and not verse_ok(b, ch, v):
                errors.append(f'{iso} {slot}: {b} {ch}:{v} verse missing')
            if b == 'ps' and disp and ch != psalm_heb_to_vulgate(disp):
                errors.append(
                    f'{iso} {slot}: psalm {disp}→{ch} ≠ Vulgate {psalm_heb_to_vulgate(disp)}')
        if not e['readings']:
            warnings.append(f'{iso}: no readings')
        for need in ('first', 'psalm', 'gospel'):
            if need not in slots_seen:
                warnings.append(f'{iso}: missing {need}')

    # Date coverage across the year.
    if year:
        start = datetime.date(year, 1, 1)
        days_in_year = (datetime.date(year + 1, 1, 1) - start).days
        present = set(entries)
        missing = [
            (start + datetime.timedelta(days=i)).isoformat()
            for i in range(days_in_year)
            if (start + datetime.timedelta(days=i)).isoformat() not in present
        ]
    else:
        missing = []

    print(f"dataset: {d.get('scope')} · year {year} · days {len(entries)} · "
          f"readings {n_read}")
    print(f"per-slot: {slot_counts}")
    print(f"date coverage: {len(entries)} day(s); missing calendar days: {len(missing)}")
    if missing:
        print(f"  e.g. {missing[:6]}")
    if warnings:
        print(f"⚠ {len(warnings)} warning(s) (non-fatal):")
        for w in warnings[:30]:
            print('  -', w)
    if errors:
        print(f"\n✗ {len(errors)} structural error(s):")
        for e in errors[:50]:
            print('  -', e)
        sys.exit(1)
    print("✓ all references resolve; psalm mapping correct; no fake ids, "
          "missing chapters/verses, or duplicate slots.")


if __name__ == '__main__':
    main()

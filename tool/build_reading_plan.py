#!/usr/bin/env python3
"""Build the bundled "Bible in a Year" plan asset from the structured schedule.

Source (external): CronogramaDeLeituraBiblia_estruturado_app.json — a JSON array
of {dia, leituras: [{secao, livro, capitulo, tipo, capitulo_inteiro,
versiculos}]}. Unlike the earlier free-text schedule, it carries the exact verse
range for the 187 readings that are not whole chapters (Proverbs and Psalm 119),
which is what lets the Reading Plan screen render the assigned passage inline
instead of dumping the surrounding chapter.

Output (committed): assets/plans/bible_in_a_year.json — each day's readings with
their human label, the section they belong to, and resolved {book, chapter,
verseStart?, verseEnd?} targets the Reader can open.

Usage:
  python3 tool/build_reading_plan.py [SOURCE_JSON]

Validates that every day resolves and all 73 books appear, then (when the built
Bible DB is available) reconciles every emitted verse range against the app's
own Scripture — so a Psalm mapped from Hebrew to Vulgate numbering can never
cite a verse the reader doesn't have.
"""
import json
import os
import sqlite3
import sys

DEFAULT_SRC = os.path.expanduser(
    "~/Downloads/Biblia Traditio/Cronograma Bíblia em um ano! (PRONTO!!)/"
    "CronogramaDeLeituraBiblia_estruturado_app.json")
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "plans", "bible_in_a_year.json")
BIBLE_DB = os.path.join(HERE, "importer", "data", "bible_vulgata.sqlite")

# Portuguese book names (incl. plan spelling variants) → canonical book id.
NAME2ID = {
    'Gênesis': 'gn', 'Êxodo': 'ex', 'Levítico': 'lv', 'Números': 'nm',
    'Deuteronômio': 'dt', 'Josué': 'jo', 'Juízes': 'jgs', 'Rute': 'rt',
    'I Samuel': '1sm', 'II Samuel': '2sm', 'I Reis': '1kgs', 'II Reis': '2kgs',
    'I Crônicas': '1chr', 'II Crônicas': '2chr', 'Esdras': 'ezr',
    'Neemias': 'neh', 'Tobias': 'tb', 'Judite': 'jdt', 'Ester': 'est',
    'I Macabeus': '1mac', 'II Macabeus': '2mac', 'Jó': 'jb', 'Salmos': 'ps',
    'Salmo': 'ps', 'Provérbios': 'prv', 'Eclesiastes': 'eccl',
    'Cântico dos Cânticos': 'sg', 'Sabedoria': 'ws', 'Eclesiástico': 'sir',
    'Isaías': 'is', 'Jeremias': 'jer', 'Lamentações': 'lam', 'Baruc': 'bar',
    'Ezequiel': 'ez', 'Daniel': 'dn', 'Oséias': 'hos', 'Oseias': 'hos',
    'Joel': 'jl', 'Amós': 'am', 'Obadias': 'ob', 'Abdias': 'ob', 'Jonas': 'jon',
    'Miquéias': 'mi', 'Miqueias': 'mi', 'Naum': 'na', 'Habacuc': 'hb',
    'Sofonias': 'zep', 'Ageu': 'hg', 'Zacarias': 'zec', 'Malaquias': 'mal',
    'São Mateus': 'mt', 'São Marcos': 'mk', 'São Lucas': 'lk', 'São João': 'jn',
    'Atos': 'acts', 'Atos dos Apóstolos': 'acts', 'Romanos': 'rom',
    'I Coríntios': '1cor', 'II Coríntios': '2cor', 'Gálatas': 'gal',
    'Efésios': 'eph', 'Filipenses': 'phil', 'Colossenses': 'col',
    'I Tessalonicenses': '1thes', 'II Tessalonicenses': '2thes',
    'I Timóteo': '1tm', 'II Timóteo': '2tm', 'Tito': 'tit', 'Filêmon': 'phlm',
    'Hebreus': 'heb', 'São Tiago': 'jas', 'Tiago': 'jas', 'I São Pedro': '1pt',
    'II São Pedro': '2pt', 'I São João': '1jn', 'II São João': '2jn',
    'III São João': '3jn', 'S. Judas': 'jud', 'São Judas': 'jud',
    'Judas': 'jud', 'Apocalipse': 'rv',
}

CANON73 = set(NAME2ID.values())


def heb_to_vulgate_ps(h):
    """The source schedule uses Hebrew/modern Psalm numbers (e.g. 'Salmo 119' is
    the long acrostic); the app stores Vulgate numbering. Map so 'Salmo 23'
    opens the Good Shepherd (Vulgate 22). Keep the displayed label as-is."""
    if h <= 8:
        return h
    if h in (9, 10):
        return 9
    if h <= 113:
        return h - 1
    if h in (114, 115):
        return 113
    if h == 116:
        return 114
    if h <= 146:
        return h - 1
    if h == 147:
        return 146
    return h


def chapter_span(chapters):
    """[1,2,3] → '1-3'; [4] → '4'; [1,2,5] → '1-2,5'."""
    out, start, prev = [], chapters[0], chapters[0]
    for c in chapters[1:]:
        if c == prev + 1:
            prev = c
            continue
        out.append(str(start) if start == prev else f'{start}-{prev}')
        start = prev = c
    out.append(str(start) if start == prev else f'{start}-{prev}')
    return ','.join(out)


def group(readings):
    """Collapses the source's one-entry-per-chapter listing into the readings a
    reader recognises: consecutive entries from the same book and section become
    a single card ("São Marcos 1-2"). Verse-specific entries never merge — their
    range is the whole point."""
    groups = []
    for r in readings:
        book = NAME2ID[r['livro']]
        verses = r.get('versiculos') or None
        key = (r['secao'], book, bool(verses))
        if groups and groups[-1]['key'] == key and not verses:
            groups[-1]['chapters'].append(r['capitulo'])
        else:
            groups.append({
                'key': key,
                'section': r['secao'],
                'name': r['livro'],
                'book': book,
                'chapters': [r['capitulo']],
                'verses': verses,
            })
    return groups


def to_reading(g):
    book, chapters, verses = g['book'], g['chapters'], g['verses']
    if verses:
        ch = chapters[0]
        target_ch = heb_to_vulgate_ps(ch) if book == 'ps' else ch
        ref = f"{g['name']} {ch},{verses[0]}-{verses[-1]}"
        targets = [{'book': book, 'chapter': target_ch,
                    'verseStart': verses[0], 'verseEnd': verses[-1]}]
    else:
        ref = f"{g['name']} {chapter_span(chapters)}"
        targets = [
            {'book': book,
             'chapter': heb_to_vulgate_ps(c) if book == 'ps' else c}
            for c in chapters
        ]
    return {'section': g['section'], 'ref': ref, 'targets': targets}


def reconcile_verse_ranges(entries):
    """Reconciles every emitted verse range against the app's own Scripture.

    The schedule was written against a versification that occasionally runs a
    verse past the Vulgate's (Proverbs 19 ends at 29, the schedule cites 30), so
    a range is clamped to the chapter's real last verse and its label rewritten
    to match. A range that starts past the end of the chapter is dropped
    entirely and the reading falls back to the whole chapter — better a wider
    reading than a citation the reader cannot open. Skipped, with a notice, when
    the Bible DB hasn't been built on this machine."""
    if not os.path.exists(BIBLE_DB):
        print("  ! bible DB not found — verse ranges not reconciled")
        return
    db = sqlite3.connect(f'file:{BIBLE_DB}?mode=ro', uri=True)
    cur = db.cursor()
    last_verse = {}

    def chapter_end(book, chapter):
        key = (book, chapter)
        if key not in last_verse:
            row = cur.execute(
                "SELECT MAX(verse) FROM verse WHERE translation_id='vulgata'"
                " AND book_id=? AND chapter=?", key).fetchone()
            last_verse[key] = row[0] or 0
        return last_verse[key]

    checked = clamped = dropped = 0
    for e in entries:
        for r in e['readings']:
            for t in r['targets']:
                if 'verseStart' not in t:
                    continue
                checked += 1
                end = chapter_end(t['book'], t['chapter'])
                if end == 0 or t['verseStart'] > end:
                    print(f"  ! day {e['day']}: {r['ref']} starts past the end of"
                          f" the chapter — reading the whole chapter instead")
                    t.pop('verseStart'), t.pop('verseEnd')
                    r['ref'] = r['ref'].split(',')[0]
                    dropped += 1
                elif t['verseEnd'] > end:
                    t['verseEnd'] = end
                    r['ref'] = f"{r['ref'].split(',')[0]},{t['verseStart']}-{end}"
                    clamped += 1
    db.close()
    print(f"  ✓ {checked} verse ranges reconciled with the Vulgate"
          f" ({clamped} clamped, {dropped} widened to the chapter)")


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SRC
    plan = json.load(open(src))
    entries = []
    for e in plan:
        unknown = [r['livro'] for r in e['leituras'] if r['livro'] not in NAME2ID]
        assert not unknown, f"day {e['dia']}: unknown book(s) {unknown}"
        entries.append({
            'day': e['dia'],
            'readings': [to_reading(g) for g in group(e['leituras'])],
        })

    books = {t['book'] for e in entries for r in e['readings'] for t in r['targets']}
    assert all(e['readings'] for e in entries), "a day has no resolvable reading"
    missing = CANON73 - books
    assert not missing, f"books missing from plan: {sorted(missing)}"
    reconcile_verse_ranges(entries)

    ranged = sum(1 for e in entries for r in e['readings']
                 for t in r['targets'] if 'verseStart' in t)
    out = {
        'id': 'bible_in_a_year',
        'version': 3,
        'days': len(entries),
        'title': {'pt': 'Bíblia em um ano', 'en': 'Bible in a Year'},
        'source': 'Cronograma de leitura — Victor Sales Pinheiro',
        'entries': entries,
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(out, open(OUT, 'w'), ensure_ascii=False, separators=(',', ':'))
    print(f"✓ {len(entries)} days · {len(books)}/73 books · {ranged} verse-ranged"
          f" readings · {os.path.getsize(OUT)} bytes → {OUT}")


if __name__ == '__main__':
    main()

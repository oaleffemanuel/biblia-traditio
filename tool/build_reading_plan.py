#!/usr/bin/env python3
"""Build the bundled "Bible in a Year" plan asset from the source schedule.

Source (external): a JSON array of {Dia, "Leitura Livro", "Leitura Sapienciais"}.
Output (committed): assets/plans/bible_in_a_year.json — each day's readings with
their human label plus resolved {book, chapter} targets the Reader can open.

Usage:
  python3 tool/build_reading_plan.py [SOURCE_JSON]

SOURCE_JSON defaults to the Victor Sales Pinheiro schedule in ~/Downloads.
Navigation is chapter-level, so verse suffixes (e.g. "Salmo 119:1-25") collapse
to their chapter. Validates that every day resolves and all 73 books appear.
"""
import json
import os
import re
import sys

DEFAULT_SRC = os.path.expanduser(
    "~/Downloads/Biblia Catolica Tradicional Comentada/"
    "Cronograma Bíblia em um ano!/CronogramaDeLeituraBiblia_victor salles.json")
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "plans",
                   "bible_in_a_year.json")

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
NAMES_SORTED = sorted(NAME2ID, key=len, reverse=True)

# Compound/irregular book-readings that the generic scanner can't split cleanly.
OVERRIDES = {
    'Tito e Filêmon 1-3,1': [('tit', [1, 2, 3]), ('phlm', [1])],
    'II e III São João, S. Judas 1': [('2jn', [1]), ('3jn', [1]), ('jud', [1])],
}

CANON73 = {
    'gn', 'ex', 'lv', 'nm', 'dt', 'jo', 'jgs', 'rt', '1sm', '2sm', '1kgs',
    '2kgs', '1chr', '2chr', 'ezr', 'neh', 'tb', 'jdt', 'est', '1mac', '2mac',
    'jb', 'ps', 'prv', 'eccl', 'sg', 'ws', 'sir', 'is', 'jer', 'lam', 'bar',
    'ez', 'dn', 'hos', 'jl', 'am', 'ob', 'jon', 'mi', 'na', 'hb', 'zep', 'hg',
    'zec', 'mal', 'mt', 'mk', 'lk', 'jn', 'acts', 'rom', '1cor', '2cor', 'gal',
    'eph', 'phil', 'col', '1thes', '2thes', '1tm', '2tm', 'tit', 'phlm', 'heb',
    'jas', '1pt', '2pt', '1jn', '2jn', '3jn', 'jud', 'rv',
}


def parse_chapters(spec):
    out = []
    for part in spec.split(','):
        part = part.strip()
        m = re.match(r'^(\d+)\s*-\s*(\d+)$', part)
        if m:
            out.extend(range(int(m.group(1)), int(m.group(2)) + 1))
        elif re.match(r'^\d+$', part):
            out.append(int(part))
    return out


def parse(text):
    s = text.strip()
    if s in OVERRIDES:
        return OVERRIDES[s], []
    rest, segs, unresolved, guard = s, [], [], 0
    while rest.strip() and guard < 20:
        guard += 1
        rest = re.sub(r'^e\s+', '', rest.strip().lstrip(',').strip())
        matched = next((nm for nm in NAMES_SORTED if rest.startswith(nm)), None)
        if not matched:
            unresolved.append(rest)
            break
        rest = rest[len(matched):].strip()
        m = re.match(r'^([\d,\s-]*)', rest)
        chspec = m.group(1) if m else ''
        rest = rest[len(chspec):]
        rest = re.sub(r'^:\s*[\d,\s-]+', '', rest)  # drop verse range (chapter-level nav)
        segs.append((NAME2ID[matched], parse_chapters(chspec) or [1]))
    return segs, unresolved


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SRC
    plan = json.load(open(src))
    entries, problems = [], []
    for e in plan:
        readings = []
        for txt in (e.get('Leitura Livro', ''), e.get('Leitura Sapienciais', '')):
            txt = txt.strip()
            segs, unres = parse(txt)
            if unres:
                problems.append((e['Dia'], txt, unres))
            targets = [{'book': b, 'chapter': c} for (b, chs) in segs for c in chs]
            if targets:
                readings.append({'ref': txt, 'targets': targets})
        entries.append({'day': e['Dia'], 'readings': readings})

    books = {t['book'] for e in entries for r in e['readings'] for t in r['targets']}
    assert not problems, f"unresolved references: {problems[:5]}"
    assert all(e['readings'] for e in entries), "a day has no resolvable reading"
    missing = CANON73 - books
    assert not missing, f"books missing from plan: {sorted(missing)}"

    out = {
        'id': 'bible_in_a_year',
        'version': 1,
        'days': len(entries),
        'title': {'pt': 'Bíblia em um ano', 'en': 'Bible in a Year'},
        'source': 'Cronograma de leitura — Victor Sales Pinheiro',
        'entries': entries,
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(out, open(OUT, 'w'), ensure_ascii=False, separators=(',', ':'))
    print(f"✓ {len(entries)} days · {len(books)}/73 books · {os.path.getsize(OUT)} bytes → {OUT}")


if __name__ == '__main__':
    main()

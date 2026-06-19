#!/usr/bin/env python3
"""Build the bundled lectionary (daily Mass reading references) for Biblia Traditio.

Source: cpbjr/catholic-readings-api (MIT) — date-keyed JSON of the General Roman
Calendar daily readings (First, Psalm, Second, Gospel). We import only the
*references* (citations are facts, not the copyrighted text); the app shows them
against its own bundled Bible. Coverage: Sundays + principal solemnities.

Pipeline: fetch/read date files → keep Sundays + solemnities → parse each
reference (English book → canonical id, chapter, first verse, PT display
citation) → map Psalms Hebrew→Vulgate for the open target → validate every
reference resolves in the bundled Bible → write assets/lectionary/readings.json.

Usage:
  python3 tool/build_lectionary.py [--src DIR] [--year 2026]
  --src: a local 'readings/<year>' dir (e.g. an extracted cpbjr checkout).
         If omitted, the script downloads the cpbjr tarball.
"""
import argparse
import io
import json
import os
import re
import sqlite3
import sys
import tarfile
import unicodedata
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets', 'lectionary', 'readings.json')
BIBLE_DB = os.path.join(ROOT, 'tool', 'importer', 'data', 'bible_vulgata.sqlite')
TARBALL = 'https://codeload.github.com/cpbjr/catholic-readings-api/tar.gz/refs/heads/main'

# Canonical registry: canon id -> (namePt, abbrevPt, chapterCount).
CANON = {
    'gn': ('Gênesis', 'Gn', 50), 'ex': ('Êxodo', 'Ex', 40), 'lv': ('Levítico', 'Lv', 27),
    'nm': ('Números', 'Nm', 36), 'dt': ('Deuteronômio', 'Dt', 34), 'jo': ('Josué', 'Js', 24),
    'jgs': ('Juízes', 'Jz', 21), 'rt': ('Rute', 'Rt', 4), '1sm': ('I Samuel', '1Sm', 31),
    '2sm': ('II Samuel', '2Sm', 24), '1kgs': ('I Reis', '1Rs', 22), '2kgs': ('II Reis', '2Rs', 25),
    '1chr': ('I Crônicas', '1Cr', 29), '2chr': ('II Crônicas', '2Cr', 36), 'ezr': ('Esdras', 'Esd', 10),
    'neh': ('Neemias', 'Ne', 13), 'tb': ('Tobias', 'Tb', 14), 'jdt': ('Judite', 'Jt', 16),
    'est': ('Ester', 'Est', 16), '1mac': ('I Macabeus', '1Mac', 16), '2mac': ('II Macabeus', '2Mac', 15),
    'jb': ('Jó', 'Jó', 42), 'ps': ('Salmos', 'Sl', 150), 'prv': ('Provérbios', 'Pr', 31),
    'eccl': ('Eclesiastes', 'Ecl', 12), 'sg': ('Cântico dos Cânticos', 'Ct', 8), 'ws': ('Sabedoria', 'Sb', 19),
    'sir': ('Eclesiástico', 'Eclo', 51), 'is': ('Isaías', 'Is', 66), 'jer': ('Jeremias', 'Jr', 52),
    'lam': ('Lamentações', 'Lm', 5), 'bar': ('Baruc', 'Br', 6), 'ez': ('Ezequiel', 'Ez', 48),
    'dn': ('Daniel', 'Dn', 14), 'hos': ('Oseias', 'Os', 14), 'jl': ('Joel', 'Jl', 3), 'am': ('Amós', 'Am', 9),
    'ob': ('Abdias', 'Ab', 1), 'jon': ('Jonas', 'Jn', 4), 'mi': ('Miqueias', 'Mq', 7), 'na': ('Naum', 'Na', 3),
    'hb': ('Habacuc', 'Hab', 3), 'zep': ('Sofonias', 'Sf', 3), 'hg': ('Ageu', 'Ag', 2), 'zec': ('Zacarias', 'Zc', 14),
    'mal': ('Malaquias', 'Ml', 4), 'mt': ('Mateus', 'Mt', 28), 'mk': ('Marcos', 'Mc', 16),
    'lk': ('Lucas', 'Lc', 24), 'jn': ('João', 'Jo', 21), 'acts': ('Atos dos Apóstolos', 'At', 28),
    'rom': ('Romanos', 'Rm', 16), '1cor': ('I Coríntios', '1Cor', 16), '2cor': ('II Coríntios', '2Cor', 13),
    'gal': ('Gálatas', 'Gl', 6), 'eph': ('Efésios', 'Ef', 6), 'phil': ('Filipenses', 'Fp', 4),
    'col': ('Colossenses', 'Cl', 4), '1thes': ('I Tessalonicenses', '1Ts', 5), '2thes': ('II Tessalonicenses', '2Ts', 3),
    '1tm': ('I Timóteo', '1Tm', 6), '2tm': ('II Timóteo', '2Tm', 4), 'tit': ('Tito', 'Tt', 3),
    'phlm': ('Filêmon', 'Fm', 1), 'heb': ('Hebreus', 'Hb', 13), 'jas': ('Tiago', 'Tg', 5),
    '1pt': ('I Pedro', '1Pd', 5), '2pt': ('II Pedro', '2Pd', 3), '1jn': ('I João', '1Jo', 5),
    '2jn': ('II João', '2Jo', 1), '3jn': ('III João', '3Jo', 1), 'jud': ('Judas', 'Jd', 1),
    'rv': ('Apocalipse', 'Ap', 22),
}

# English (USCCB) book names → canonical id (longest names matched first).
EN2ID = {
    'genesis': 'gn', 'exodus': 'ex', 'leviticus': 'lv', 'numbers': 'nm',
    'deuteronomy': 'dt', 'joshua': 'jo', 'judges': 'jgs', 'ruth': 'rt',
    '1 samuel': '1sm', '2 samuel': '2sm', '1 kings': '1kgs', '2 kings': '2kgs',
    '1 chronicles': '1chr', '2 chronicles': '2chr', 'ezra': 'ezr', 'nehemiah': 'neh',
    'tobit': 'tb', 'judith': 'jdt', 'esther': 'est', '1 maccabees': '1mac',
    '2 maccabees': '2mac', 'job': 'jb', 'psalms': 'ps', 'psalm': 'ps',
    'proverbs': 'prv', 'ecclesiastes': 'eccl', 'song of songs': 'sg',
    'song of solomon': 'sg', 'wisdom': 'ws', 'sirach': 'sir', 'ecclesiasticus': 'sir',
    'isaiah': 'is', 'jeremiah': 'jer', 'lamentations': 'lam', 'baruch': 'bar',
    'ezekiel': 'ez', 'daniel': 'dn', 'hosea': 'hos', 'joel': 'jl', 'amos': 'am',
    'obadiah': 'ob', 'jonah': 'jon', 'micah': 'mi', 'nahum': 'na', 'habakkuk': 'hb',
    'zephaniah': 'zep', 'haggai': 'hg', 'zechariah': 'zec', 'malachi': 'mal',
    'matthew': 'mt', 'mark': 'mk', 'luke': 'lk', 'john': 'jn',
    'acts of the apostles': 'acts', 'acts': 'acts', 'romans': 'rom',
    '1 corinthians': '1cor', '2 corinthians': '2cor', 'galatians': 'gal',
    'ephesians': 'eph', 'philippians': 'phil', 'colossians': 'col',
    '1 thessalonians': '1thes', '2 thessalonians': '2thes', '1 timothy': '1tm',
    '2 timothy': '2tm', 'titus': 'tit', 'philemon': 'phlm', 'hebrews': 'heb',
    'james': 'jas', '1 peter': '1pt', '2 peter': '2pt', '1 john': '1jn',
    '2 john': '2jn', '3 john': '3jn', 'jude': 'jud', 'revelation': 'rv',
    'phiippians': 'phil',  # known source typo
}
EN_NAMES = sorted(EN2ID, key=len, reverse=True)

# Single-chapter books: the lectionary cites them as "Jude 17" / "Philemon 7-20"
# where the number is the VERSE within the only chapter (chapter 1).
SINGLE_CHAPTER = {'ob', 'phlm', '2jn', '3jn', 'jud'}

SLOTS = [('first', 'firstReading'), ('psalm', 'psalm'),
         ('second', 'secondReading'), ('gospel', 'gospel')]


def psalm_heb_to_vulgate(h):
    if h <= 8: return h
    if h in (9, 10): return 9
    if h <= 113: return h - 1
    if h in (114, 115): return 113
    if h == 116: return 114
    if h <= 146: return h - 1
    if h == 147: return 146
    return h


def norm(s):
    s = s.replace('\xa0', ' ')
    s = ''.join(ch for ch in unicodedata.normalize('NFD', s.lower())
                if unicodedata.category(ch) != 'Mn')
    return re.sub(r'\s+', ' ', s).strip()


def parse_ref(raw):
    """('Jeremiah 20:10-13') -> dict(book, chapter, verse, ref) or None."""
    s = re.sub(r'\s+', ' ', raw.replace('\xa0', ' ')).strip().rstrip('.').strip()
    if not s:
        return None
    s = re.split(r'\s+\bor\b\s+', s)[0].strip()      # first option only
    low = norm(s)
    book = next((n for n in EN_NAMES if low.startswith(n + ' ')), None)
    if not book:
        return None
    bid = EN2ID[book]
    rest = s[len(book):].strip()
    single = bid in SINGLE_CHAPTER and ':' not in rest
    if single:
        chapter, versespec = 1, rest  # "Jude 17" → chapter 1, verse 17
    else:
        m = re.match(r'^(\d+)\s*[:.]\s*(.+)$', rest) or re.match(r'^(\d+)\s*$', rest)
        if not m:
            return None
        chapter = int(m.group(1))
        versespec = (m.group(2) if m.lastindex and m.lastindex >= 2 else '').strip()
    fv = re.search(r'\d+', versespec)
    verse = int(fv.group()) if fv else 1
    # Open target: Psalms map Hebrew→Vulgate; others unchanged.
    target_ch = psalm_heb_to_vulgate(chapter) if bid == 'ps' else chapter
    # PT display citation: "Jr 20,10-13" (Hebrew psalm number kept; reader shows
    # the Vulgate number with the Hebrew in parentheses, so they reconcile).
    abbr = CANON[bid][1]
    # For display, keep only the starting chapter's verse list (drop any
    # cross-chapter "…—9:3" tail), and use PT separators ("." between segments).
    disp = re.split(r'[—–]', versespec)[0].strip() if versespec else ''
    vtxt = disp.replace(' ', '').replace(',', '.')
    if single:
        ref = f'{abbr} {vtxt}' if vtxt else abbr  # "Jd 17-25" (no chapter)
    else:
        ref = f'{abbr} {chapter},{vtxt}' if vtxt else f'{abbr} {chapter}'
    return {'slot': None, 'book': bid, 'chapter': target_ch,
            'displayChapter': chapter, 'verse': verse, 'ref': ref}


def load_source(args):
    if args.src:
        base = args.src
        return {f[:-5]: json.load(open(os.path.join(base, f)))
                for f in os.listdir(base) if f.endswith('.json')}
    print('↓ downloading cpbjr lectionary tarball…')
    data = urllib.request.urlopen(TARBALL, timeout=60).read()
    out = {}
    with tarfile.open(fileobj=io.BytesIO(data)) as tar:
        pref = f'/readings/{args.year}/'
        for m in tar.getmembers():
            if pref in m.name and m.name.endswith('.json'):
                out[os.path.basename(m.name)[:-5]] = json.load(tar.extractfile(m))
    return out


def main():
    import datetime
    ap = argparse.ArgumentParser()
    ap.add_argument('--src')
    ap.add_argument('--year', type=int, default=2026)
    args = ap.parse_args()

    files = load_source(args)
    con = sqlite3.connect(BIBLE_DB)

    def verse_exists(bid, ch, v):
        return con.execute(
            "SELECT 1 FROM verse WHERE translation_id='vulgata' AND book_id=? "
            "AND chapter=? AND verse=? LIMIT 1", (bid, ch, v)).fetchone() is not None

    def chapter_exists(bid, ch):
        return con.execute(
            "SELECT 1 FROM verse WHERE translation_id='vulgata' AND book_id=? "
            "AND chapter=? LIMIT 1", (bid, ch)).fetchone() is not None

    entries, problems, skipped_refs = {}, [], 0
    for md, payload in sorted(files.items()):
        try:
            dt = datetime.date(args.year, int(md[:2]), int(md[3:5]))
        except ValueError:
            continue
        rd = payload.get('readings', {})
        readings = []
        for slot, key in SLOTS:
            raw = (rd.get(key) or '').strip()
            if not raw:
                continue
            p = parse_ref(raw)
            if not p:
                problems.append(f"{dt} {slot}: unparseable «{raw}»")
                skipped_refs += 1
                continue
            # Validate against the bundled Bible.
            ok = chapter_exists(p['book'], p['chapter']) if p['book'] == 'ps' \
                else verse_exists(p['book'], p['chapter'], p['verse'])
            if not ok:
                problems.append(
                    f"{dt} {slot}: {p['book']} {p['chapter']}:{p['verse']} not in Bible «{raw}»")
                skipped_refs += 1
                continue
            p['slot'] = slot
            readings.append(p)
        if readings:
            iso = dt.isoformat()
            entries[iso] = {'date': iso, 'readings': readings}

    out = {'id': 'lectionary', 'version': 2,
           'source': 'cpbjr/catholic-readings-api (MIT) — General Roman Calendar references',
           'scope': 'Full daily lectionary (weekdays, feasts, solemnities, all seasons)',
           'year': args.year, 'days': len(entries), 'entries': entries}
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(out, open(OUT, 'w'), ensure_ascii=False, separators=(',', ':'))

    n_ref = sum(len(e['readings']) for e in entries.values())
    print(f"days: {len(entries)} · readings: {n_ref} · unresolved/skipped: {skipped_refs}")
    if problems:
        print(f"⚠ {len(problems)} issue(s):")
        for p in problems[:40]:
            print('  -', p)
    print(f"→ {OUT}")
    # Hard-fail only if a *large* share is unresolved (data drift); a few odd
    # USCCB-only refs degrading to fewer readings is acceptable for the MVP.
    if n_ref == 0 or skipped_refs > n_ref:
        sys.exit('ERROR: too many unresolved references — aborting.')


if __name__ == '__main__':
    main()

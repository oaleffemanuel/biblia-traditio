#!/usr/bin/env python3
"""Fetch the Padre Matos Soares Bible (public-domain translation) and convert it
to the importer's `biblejson` shape.

Source: padrepauloricardo.org serves each book's full text as a server-rendered
JSON blob embedded in the page (one request returns every chapter). That blob is
clean and properly versified — unlike the older innerText scrape, it carries no
section headings mixed into verse text. Verses are positional; we number them
1..N per chapter (the edition's own numbering).

Usage:
  python3 tool/importer/fetch_matos_soares.py OUT.json [BOOKS_FILE]

BOOKS_FILE defaults to the site book map in the Drive dataset. Output is the
{antigoTestamento, novoTestamento} structure consumed by
`dart run bin/import.dart biblejson`. Validates 73 books, chapter counts vs the
Catholic canon, non-empty chapters, and absence of heading-like verses.
"""
import html as htmllib
import json
import os
import re
import ssl
import sys
import time
import unicodedata
import urllib.parse
import urllib.request

try:  # verified TLS when certifi is available; fall back otherwise (PD text)
    import certifi
    _SSL = ssl.create_default_context(cafile=certifi.where())
except Exception:  # noqa: BLE001
    _SSL = ssl._create_unverified_context()

URL = "https://padrepauloricardo.org/biblia/{site_abbr}?cap=1&edition=matos-soares"
DEFAULT_BOOKS = os.path.expanduser(
    "~/Downloads/Biblia Catolica Tradicional Comentada/Bíblia Matos Soares/"
    "Pe. Paulo Biblia/books_ppr_final.json")
KEYS = ('book_id|book_name|book_abbrev|chapters_count|chapters|number|title|'
        'verses|verses_count')

# Canonical Catholic registry: namePt, testament, chapter count (mirrors canon.dart).
CANON = [
    ('Gênesis', 'OT', 50), ('Êxodo', 'OT', 40), ('Levítico', 'OT', 27),
    ('Números', 'OT', 36), ('Deuteronômio', 'OT', 34), ('Josué', 'OT', 24),
    ('Juízes', 'OT', 21), ('Rute', 'OT', 4), ('I Samuel', 'OT', 31),
    ('II Samuel', 'OT', 24), ('I Reis', 'OT', 22), ('II Reis', 'OT', 25),
    ('I Crônicas', 'OT', 29), ('II Crônicas', 'OT', 36), ('Esdras', 'OT', 10),
    ('Neemias', 'OT', 13), ('Tobias', 'OT', 14), ('Judite', 'OT', 16),
    ('Ester', 'OT', 16), ('I Macabeus', 'OT', 16), ('II Macabeus', 'OT', 15),
    ('Jó', 'OT', 42), ('Salmos', 'OT', 150), ('Provérbios', 'OT', 31),
    ('Eclesiastes', 'OT', 12), ('Cântico dos Cânticos', 'OT', 8),
    ('Sabedoria', 'OT', 19), ('Eclesiástico', 'OT', 51), ('Isaías', 'OT', 66),
    ('Jeremias', 'OT', 52), ('Lamentações', 'OT', 5), ('Baruc', 'OT', 6),
    ('Ezequiel', 'OT', 48), ('Daniel', 'OT', 14), ('Oseias', 'OT', 14),
    ('Joel', 'OT', 3), ('Amós', 'OT', 9), ('Abdias', 'OT', 1), ('Jonas', 'OT', 4),
    ('Miqueias', 'OT', 7), ('Naum', 'OT', 3), ('Habacuc', 'OT', 3),
    ('Sofonias', 'OT', 3), ('Ageu', 'OT', 2), ('Zacarias', 'OT', 14),
    ('Malaquias', 'OT', 4), ('Mateus', 'NT', 28), ('Marcos', 'NT', 16),
    ('Lucas', 'NT', 24), ('João', 'NT', 21), ('Atos dos Apóstolos', 'NT', 28),
    ('Romanos', 'NT', 16), ('I Coríntios', 'NT', 16), ('II Coríntios', 'NT', 13),
    ('Gálatas', 'NT', 6), ('Efésios', 'NT', 6), ('Filipenses', 'NT', 4),
    ('Colossenses', 'NT', 4), ('I Tessalonicenses', 'NT', 5),
    ('II Tessalonicenses', 'NT', 3), ('I Timóteo', 'NT', 6),
    ('II Timóteo', 'NT', 4), ('Tito', 'NT', 3), ('Filêmon', 'NT', 1),
    ('Hebreus', 'NT', 13), ('Tiago', 'NT', 5), ('I Pedro', 'NT', 5),
    ('II Pedro', 'NT', 3), ('I João', 'NT', 5), ('II João', 'NT', 1),
    ('III João', 'NT', 1), ('Judas', 'NT', 1), ('Apocalipse', 'NT', 22),
]


def norm(s):
    s = ''.join(c for c in unicodedata.normalize('NFD', s.lower())
                if unicodedata.category(c) != 'Mn')
    s = re.sub(r'\bsao\b', '', s)
    return re.sub(r'\s+', ' ', s).strip()


NORM2CANON = {norm(name): (name, test, ch) for name, test, ch in CANON}


# The dataset's site_abbr is wrong for a few books; override by canon name.
SITE_ABBR_OVERRIDE = {'Jó': 'job'}


def fetch(site_abbr, attempts=3):
    url = URL.format(site_abbr=urllib.parse.quote(site_abbr))
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    last = None
    for _ in range(attempts):
        try:
            with urllib.request.urlopen(req, timeout=45, context=_SSL) as r:
                return r.read().decode('utf-8', 'replace')
        except Exception as e:  # noqa: BLE001 — retry transient network errors
            last = e
            time.sleep(2)
    raise last


def extract(htmltext):
    # The book's full data is a JS object inside a single-quoted HTML attribute
    # (content='...{book_id:...}'). Inner quotes are entity-encoded, so the first
    # raw single-quote after the blob is the attribute terminator — a more robust
    # end than brace-counting (verse text can contain stray braces).
    i = htmltext.find('book_id:')
    if i < 0:
        return None
    start = htmltext.rfind('{', 0, i)
    end = htmltext.find("'", i)
    if start < 0 or end < 0:
        return None
    blob = htmllib.unescape(htmltext[start:end])
    blob = re.sub(r'([{,\[]\s*)(' + KEYS + r')(\s*:)',
                  lambda m: f'{m.group(1)}"{m.group(2)}"{m.group(3)}', blob)
    return json.loads(blob)


def sanitize(t):
    """Strip HTML the source embeds for cross-references, keeping the inner
    citation text: '(<a href=...>Is 40, 3</a>)' -> '(Is 40, 3)'. Also unescape
    entities and collapse whitespace left behind."""
    t = re.sub(r'<[^>]*>', '', t)          # drop tags, keep inner text
    t = htmllib.unescape(t)                 # &quot; &amp; &#39; -> " & '
    t = re.sub(r'\s+([,.;:!?])', r'\1', t)  # tidy space before punctuation
    t = re.sub(r'\(\s+', '(', t)            # tidy "( Is" -> "(Is"
    t = re.sub(r'\s+\)', ')', t)
    return re.sub(r'\s{2,}', ' ', t).strip()


def looks_like_heading(t):
    s = t.strip()
    letters = [c for c in s if c.isalpha()]
    return bool(letters) and all(c == c.upper() for c in letters) and len(s) <= 40


def main():
    if len(sys.argv) < 2:
        sys.exit('usage: fetch_matos_soares.py OUT.json [BOOKS_FILE]')
    out_path = sys.argv[1]
    books_file = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_BOOKS
    books = json.load(open(books_file))

    ot, nt, problems, seen = [], [], [], set()
    for b in books:
        site = b['site_abbr']
        resolved = NORM2CANON.get(norm(b['nome']))
        if not resolved:
            problems.append(f"{b['nome']}: no canon match")
            continue
        name, test, expect_ch = resolved
        seen.add(name)
        site = SITE_ABBR_OVERRIDE.get(name, site)
        try:
            data = extract(fetch(site))
        except Exception as e:  # noqa: BLE001
            problems.append(f"{name} ({site}): fetch/parse failed: {e}")
            continue
        if data is None or not data.get('chapters'):
            problems.append(f"{name} ({site}): no data blob found on page")
            continue
        chapters = []
        for c in data['chapters']:
            verses = [sanitize(v) for v in c['verses']]
            for vi, txt in enumerate(verses, 1):
                if looks_like_heading(txt):
                    problems.append(f"{name} {c['number']}:{vi}: heading-like «{txt}»")
            chapters.append({
                'capitulo': c['number'],
                'versiculos': [{'versiculo': vi, 'texto': txt}
                               for vi, txt in enumerate(verses, 1) if txt],
            })
        nch = len(chapters)
        if nch != expect_ch:
            problems.append(f"{name}: {nch} chapters, canon expects {expect_ch}")
        if any(not c['versiculos'] for c in chapters):
            problems.append(f"{name}: has empty chapter(s)")
        (ot if test == 'OT' else nt).append({'nome': name, 'capitulos': chapters})
        time.sleep(0.3)

    missing = {n for n, _, _ in CANON} - seen
    if missing:
        problems.append(f"books never seen: {sorted(missing)}")

    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    json.dump({'antigoTestamento': ot, 'novoTestamento': nt},
              open(out_path, 'w'), ensure_ascii=False)
    nv = sum(len(c['versiculos']) for sec in (ot, nt) for bk in sec
             for c in bk['capitulos'])
    print(f"books: {len(ot)+len(nt)}/73 · verses: {nv} · "
          f"chapters: {sum(len(bk['capitulos']) for sec in (ot,nt) for bk in sec)}")
    print(f"→ {out_path}")
    if problems:
        print(f"\n⚠ {len(problems)} issue(s):")
        for p in problems[:40]:
            print('  -', p)
        sys.exit(1)
    print("✓ all 73 books, chapter counts match canon, no heading-like verses")


if __name__ == '__main__':
    main()

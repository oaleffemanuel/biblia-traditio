#!/usr/bin/env python3
"""Fetch the SBL Greek New Testament (SBLGNT) and convert it to the importer's
`biblejson` shape.

Source: morphgnt/sblgnt (the SBLGNT text merged with MorphGNT analysis). The
SBLGNT *text* is licensed CC BY 4.0 (Society of Biblical Literature & Logos Bible
Software); we import the reading text only (the CC-BY-SA morphology is not
bundled here). Editorial apparatus sigla (⸀ ⸂ ⸃ …) are stripped for a clean text.

Usage:
  python3 tool/importer/fetch_sblgnt.py OUT.json [--src DIR]

--src: a local checkout's dir of NN-Xx-morphgnt.txt files; otherwise the GitHub
tarball is downloaded. Output: {novoTestamento:[…]} for `dart run bin/import.dart
biblejson --translation grc_sblgnt`.
"""
import argparse
import io
import json
import os
import re
import sys
import tarfile
import unicodedata
import urllib.request

TARBALL = 'https://codeload.github.com/morphgnt/sblgnt/tar.gz/refs/heads/master'

# MorphGNT book number (1..27, NT order) → canonical id + Portuguese name.
NT = [
    ('mt', 'Mateus'), ('mk', 'Marcos'), ('lk', 'Lucas'), ('jn', 'João'),
    ('acts', 'Atos dos Apóstolos'), ('rom', 'Romanos'), ('1cor', 'I Coríntios'),
    ('2cor', 'II Coríntios'), ('gal', 'Gálatas'), ('eph', 'Efésios'),
    ('phil', 'Filipenses'), ('col', 'Colossenses'), ('1thes', 'I Tessalonicenses'),
    ('2thes', 'II Tessalonicenses'), ('1tm', 'I Timóteo'), ('2tm', 'II Timóteo'),
    ('tit', 'Tito'), ('phlm', 'Filêmon'), ('heb', 'Hebreus'), ('jas', 'Tiago'),
    ('1pt', 'I Pedro'), ('2pt', 'II Pedro'), ('1jn', 'I João'), ('2jn', 'II João'),
    ('3jn', 'III João'), ('jud', 'Judas'), ('rv', 'Apocalipse'),
]


def strip_sigla(s):
    """Remove SBLGNT editorial apparatus marks (Supplemental Punctuation block,
    U+2E00–U+2E7F) and tidy whitespace/spacing before punctuation."""
    s = ''.join(ch for ch in s if not (0x2E00 <= ord(ch) <= 0x2E7F))
    s = re.sub(r'\s+([,.;·:])', r'\1', s)
    return re.sub(r'\s{2,}', ' ', s).strip()


def parse_book(text):
    """morphgnt lines → {chapter: {verse: 'joined text'}} (uses the `text` col)."""
    chapters = {}
    for line in text.splitlines():
        parts = line.split(' ')
        if len(parts) < 4 or not parts[0].isdigit() or len(parts[0]) != 6:
            continue
        ch, vs = int(parts[0][2:4]), int(parts[0][4:6])
        word = parts[3]  # text column (with punctuation + sigla)
        chapters.setdefault(ch, {}).setdefault(vs, []).append(word)
    return chapters


def load_files(args):
    if args.src:
        out = {}
        for f in sorted(os.listdir(args.src)):
            if f.endswith('-morphgnt.txt'):
                out[f] = open(os.path.join(args.src, f), encoding='utf-8').read()
        return out
    print('↓ downloading SBLGNT (morphgnt) tarball…')
    data = urllib.request.urlopen(TARBALL, timeout=90).read()
    out = {}
    with tarfile.open(fileobj=io.BytesIO(data)) as tar:
        for m in tar.getmembers():
            if m.name.endswith('-morphgnt.txt'):
                out[os.path.basename(m.name)] = tar.extractfile(m).read().decode('utf-8')
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--src')
    args = ap.parse_args()

    files = load_files(args)
    by_booknum = {}
    for name, text in files.items():
        m = re.match(r'^(\d{2})-', name)
        if not m:
            continue
        by_booknum[int(m.group(1)) - 60] = parse_book(text)  # 61-Mt → 1 … 87-Re → 27

    nt, verse_total, problems = [], 0, []
    for i, (cid, nome) in enumerate(NT, start=1):
        chapters = by_booknum.get(i)
        if not chapters:
            problems.append(f'{nome}: no data (book #{i})')
            continue
        cap = []
        for ch in sorted(chapters):
            versiculos = []
            for vs in sorted(chapters[ch]):
                txt = strip_sigla(' '.join(chapters[ch][vs]))
                if txt:
                    versiculos.append({'versiculo': vs, 'texto': txt})
                    verse_total += 1
            cap.append({'capitulo': ch, 'versiculos': versiculos})
        nt.append({'nome': nome, 'capitulos': cap})

    os.makedirs(os.path.dirname(os.path.abspath(args.out)) or '.', exist_ok=True)
    json.dump({'antigoTestamento': [], 'novoTestamento': nt},
              open(args.out, 'w'), ensure_ascii=False)
    print(f"books: {len(nt)}/27 · verses: {verse_total} → {args.out}")
    if problems:
        print('⚠ ' + '; '.join(problems))
        sys.exit(1)
    # Sanity: John 3:16 should start with Οὕτως.
    jn = next(b for b in nt if b['nome'] == 'João')
    v = next(v for c in jn['capitulos'] if c['capitulo'] == 3
             for v in c['versiculos'] if v['versiculo'] == 16)
    print('  Jn 3:16:', v['texto'][:60])


if __name__ == '__main__':
    main()

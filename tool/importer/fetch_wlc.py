#!/usr/bin/env python3
"""Fetch the Hebrew Old Testament — Westminster Leningrad Codex (WLC) — from the
Open Scriptures Hebrew Bible project (morphhb) and convert it to the importer's
`biblejson` shape.

Source: openscriptures/morphhb, `wlc/<Book>.xml` (OSIS, one <w> per word). The
WLC *text* is in the public domain; the OSHB lemma/morphology layer is CC BY
4.0 and is NOT bundled — only the reading text is taken. Credit: Open
Scriptures Hebrew Bible Project.

Why not open-bibles' heb-leningrad.usfx.xml: that conversion lost the spaces
between words (verses are one long token), so it cannot be read.

Output: {antigoTestamento:[{nome, capitulos:[{capitulo, versiculos:[{versiculo,
texto}]}]}], novoTestamento: []} for
  dart run bin/import.dart biblejson --translation hbo_wlc --lang hbo

Psalms are renumbered from the Masoretic to the Vulgate/Septuagint chapters the
app stores (mirror of `psalmHebrewToVulgate` in patristics_parser.dart), so a
Hebrew psalm lines up with the Latin and Portuguese in Parallel Reading. Other
chapter-division differences (Joel, Malachi, Jonah 2, 1 Kgs 5 …) are left as the
Masoretic text has them: Parallel Reading shows "verse not available" rather
than guessing. Ketiv is kept in the running text; qere readings live in notes
that are dropped. Cantillation and vowel points are preserved.

Usage:
  python3 tool/importer/fetch_wlc.py OUT.json [--src DIR]

--src: a local checkout's `wlc/` dir; otherwise each file is downloaded from
GitHub (39 requests, ~45 MB).
"""
import argparse
import json
import os
import re
import sys
import urllib.request
import xml.etree.ElementTree as ET

RAW = 'https://raw.githubusercontent.com/openscriptures/morphhb/master/wlc/'
NS = '{http://www.bibletechnologies.net/2003/OSIS/namespace}'

# OSIS book id → (file name, Portuguese canon name as the importer resolves it)
BOOKS = [
    ('Gen', 'Gênesis'), ('Exod', 'Êxodo'), ('Lev', 'Levítico'), ('Num', 'Números'),
    ('Deut', 'Deuteronômio'), ('Josh', 'Josué'), ('Judg', 'Juízes'), ('Ruth', 'Rute'),
    ('1Sam', 'I Samuel'), ('2Sam', 'II Samuel'), ('1Kgs', 'I Reis'), ('2Kgs', 'II Reis'),
    ('1Chr', 'I Crônicas'), ('2Chr', 'II Crônicas'), ('Ezra', 'Esdras'), ('Neh', 'Neemias'),
    ('Esth', 'Ester'), ('Job', 'Jó'), ('Ps', 'Salmos'), ('Prov', 'Provérbios'),
    ('Eccl', 'Eclesiastes'), ('Song', 'Cântico dos Cânticos'), ('Isa', 'Isaías'),
    ('Jer', 'Jeremias'), ('Lam', 'Lamentações'), ('Ezek', 'Ezequiel'), ('Dan', 'Daniel'),
    ('Hos', 'Oseias'), ('Joel', 'Joel'), ('Amos', 'Amós'), ('Obad', 'Abdias'),
    ('Jonah', 'Jonas'), ('Mic', 'Miqueias'), ('Nah', 'Naum'), ('Hab', 'Habacuc'),
    ('Zeph', 'Sofonias'), ('Hag', 'Ageu'), ('Zech', 'Zacarias'), ('Mal', 'Malaquias'),
]


def psalm_hebrew_to_vulgate(hc, hv):
    """Mirror of psalmHebrewToVulgate (tool/importer/lib/parsers/patristics_parser.dart)."""
    if hc <= 8:
        return hc, hv
    if hc == 9:
        return 9, hv
    if hc == 10:
        return 9, hv + 21
    if hc <= 113:
        return hc - 1, hv
    if hc == 114:
        return 113, hv
    if hc == 115:
        return 113, hv + 8
    if hc == 116:
        return (114, hv) if hv <= 9 else (115, hv - 9)
    if hc <= 146:
        return hc - 1, hv
    if hc == 147:
        return (146, hv) if hv <= 11 else (147, hv - 11)
    return hc, hv


def verse_text(verse):
    """Join the verse's words. Maqqef joins without spaces; sof pasuq attaches
    to the last word; paragraph marks (פ/ס) and notes are dropped."""
    parts = []
    for el in verse:
        tag = el.tag.replace(NS, '')
        if tag == 'w':
            word = (el.text or '').replace('/', '')  # morpheme separators
            parts.append(word)
        elif tag == 'seg':
            kind = el.get('type', '')
            if kind == 'x-maqqef' and parts:
                parts[-1] += '־'
                parts.append(None)  # marker: next word glues to previous
            elif kind == 'x-sof-pasuq' and parts:
                parts[-1] = (parts[-1] or '') + '׃'
            elif kind == 'x-paseq':
                parts.append('׀')
            # x-pe / x-samekh: paragraph markers, not text
        # notes (variants, exegesis) are skipped
    out = []
    glue = False
    for p in parts:
        if p is None:
            glue = True
            continue
        if glue and out:
            out[-1] += p
        else:
            out.append(p)
        glue = False
    text = ' '.join(x for x in out if x)
    return re.sub(r'\s{2,}', ' ', text).strip()


def load(osis, src):
    if src:
        return open(os.path.join(src, f'{osis}.xml'), encoding='utf-8').read()
    url = RAW + f'{osis}.xml'
    try:
        import ssl
        try:
            import certifi  # python.org builds ship without system CAs
            ctx = ssl.create_default_context(cafile=certifi.where())
        except ImportError:
            ctx = ssl.create_default_context()
        return urllib.request.urlopen(url, timeout=90, context=ctx).read().decode('utf-8')
    except Exception:  # noqa: BLE001 — fall back to curl, which has its own CA store
        import subprocess
        return subprocess.run(['curl', '-fsSL', url], check=True,
                              capture_output=True).stdout.decode('utf-8')


def parse_book(xml_text, osis):
    root = ET.fromstring(xml_text)
    chapters = {}
    for verse in root.iter(NS + 'verse'):
        osis_id = verse.get('osisID', '')
        m = re.match(rf'^{re.escape(osis)}\.(\d+)\.(\d+)$', osis_id)
        if not m:
            continue
        ch, vs = int(m.group(1)), int(m.group(2))
        if osis == 'Ps':
            ch, vs = psalm_hebrew_to_vulgate(ch, vs)
        txt = verse_text(verse)
        if txt:
            chapters.setdefault(ch, {})[vs] = txt
    return chapters


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--src')
    args = ap.parse_args()

    ot, total, problems = [], 0, []
    for osis, nome in BOOKS:
        try:
            chapters = parse_book(load(osis, args.src), osis)
        except Exception as e:  # noqa: BLE001 — report and keep going
            problems.append(f'{nome}: {e}')
            continue
        if not chapters:
            problems.append(f'{nome}: no verses')
            continue
        cap = []
        for ch in sorted(chapters):
            vv = [{'versiculo': v, 'texto': chapters[ch][v]} for v in sorted(chapters[ch])]
            total += len(vv)
            cap.append({'capitulo': ch, 'versiculos': vv})
        ot.append({'nome': nome, 'capitulos': cap})
        print(f'  {nome}: {len(cap)} ch, {sum(len(c["versiculos"]) for c in cap)} vv')

    os.makedirs(os.path.dirname(os.path.abspath(args.out)) or '.', exist_ok=True)
    json.dump({'antigoTestamento': ot, 'novoTestamento': []},
              open(args.out, 'w'), ensure_ascii=False)
    print(f'books: {len(ot)}/39 · verses: {total} → {args.out}')
    if problems:
        print('⚠ ' + '; '.join(problems))
        sys.exit(1)
    # Sanity: Gen 1:1 must start with בְּרֵאשִׁית (with points).
    gn = next(b for b in ot if b['nome'] == 'Gênesis')
    v1 = gn['capitulos'][0]['versiculos'][0]['texto']
    print('  Gn 1:1:', v1[:40])
    ps = next(b for b in ot if b['nome'] == 'Salmos')
    print('  Psalms chapters:', len(ps['capitulos']), '(Vulgate numbering; 150 expected)')


if __name__ == '__main__':
    main()

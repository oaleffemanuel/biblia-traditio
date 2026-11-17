#!/usr/bin/env python3
"""Build assets/themes/themes.json from the team's thematic library export
(`biblioteca_tematica_traditio.json`, compiled from the Apologistas Católicos
site: secoes → temas → referencias / subtopicos / comentarios).

What this does, and why:
- References ("dt 6,4-9", "ps 90,1-4", "gn 5") are parsed into book/chapter/verse
  ranges in the app's canon ids. A few source codes differ from ours (2mc→2mac,
  jude→jud, ru→rt, ti→tit). Psalms in the source use the Hebrew numbering; they
  are converted to the Vulgate chapters the app stores and labelled "Sl 89(90)".
- Every range is checked against the Vulgate verse counts in the built content
  DB: an end verse past the chapter is clamped (and reported), a chapter that
  does not exist is dropped (and reported). Nothing is invented.
- Duplicate references within a theme are collapsed, keeping first occurrence.
- Commentaries are carried through with author, role and the edition/year line
  exactly as given, so the provenance stays visible in the app.

Usage: python3 -I tool/build_themes.py SRC.json assets/themes/themes.json [--db bible.sqlite]
"""
import argparse
import json
import re
import sqlite3
import sys

ALIAS = {'2mc': '2mac', '1mc': '1mac', 'jude': 'jud', 'ru': 'rt', 'ti': 'tit', 'job': 'jb', 'wis': 'ws'}
ABBR = {
    'gn': 'Gn', 'ex': 'Ex', 'lv': 'Lv', 'nm': 'Nm', 'dt': 'Dt', 'jo': 'Js', 'jgs': 'Jz', 'rt': 'Rt', '1sm': '1Sm',
    '2sm': '2Sm', '1kgs': '1Rs', '2kgs': '2Rs', '1chr': '1Cr', '2chr': '2Cr', 'ezr': 'Esd', 'neh': 'Ne', 'tb': 'Tb',
    'jdt': 'Jt', 'est': 'Est', '1mac': '1Mac', '2mac': '2Mac', 'jb': 'Jó', 'ps': 'Sl', 'prv': 'Pr', 'eccl': 'Ecl',
    'sg': 'Ct', 'ws': 'Sb', 'sir': 'Eclo', 'is': 'Is', 'jer': 'Jr', 'lam': 'Lm', 'bar': 'Br', 'ez': 'Ez', 'dn': 'Dn',
    'hos': 'Os', 'jl': 'Jl', 'am': 'Am', 'ob': 'Ab', 'jon': 'Jn', 'mi': 'Mq', 'na': 'Na', 'hb': 'Hab', 'zep': 'Sf',
    'hg': 'Ag', 'zec': 'Zc', 'mal': 'Ml', 'mt': 'Mt', 'mk': 'Mc', 'lk': 'Lc', 'jn': 'Jo', 'acts': 'At', 'rom': 'Rm',
    '1cor': '1Cor', '2cor': '2Cor', 'gal': 'Gl', 'eph': 'Ef', 'phil': 'Fl', 'col': 'Cl', '1thes': '1Ts', '2thes': '2Ts',
    '1tm': '1Tm', '2tm': '2Tm', 'tit': 'Tt', 'phlm': 'Fm', 'heb': 'Hb', 'jas': 'Tg', '1pt': '1Pd', '2pt': '2Pd',
    '1jn': '1Jo', '2jn': '2Jo', '3jn': '3Jo', 'jud': 'Jd', 'rv': 'Ap',
}


def psalm_h2v(hc, hv):
    """Hebrew (chapter, verse) → Vulgate (chapter, verse); mirror of
    psalmHebrewToVulgate in tool/importer/lib/parsers/patristics_parser.dart."""
    if hc <= 8: return hc, hv
    if hc == 9: return 9, hv
    if hc == 10: return 9, hv + 21
    if hc <= 113: return hc - 1, hv
    if hc == 114: return 113, hv
    if hc == 115: return 113, hv + 8
    if hc == 116: return (114, hv) if hv <= 9 else (115, hv - 9)
    if hc <= 146: return hc - 1, hv
    if hc == 147: return (146, hv) if hv <= 11 else (147, hv - 11)
    return hc, hv


def slug(s):
    import unicodedata
    s = unicodedata.normalize('NFKD', s).encode('ascii', 'ignore').decode()
    return re.sub(r'[^a-z0-9]+', '-', s.lower()).strip('-')


class Builder:
    def __init__(self, db):
        self.maxv = {}
        if db:
            con = sqlite3.connect(db)
            for b, c, m in con.execute("select book_id, chapter, max(verse) from verse where translation_id='vulgata' group by book_id, chapter"):
                self.maxv[(b, c)] = m
        self.clamped, self.dropped = [], []

    def passage(self, ref):
        m = re.match(r'^\s*([0-9]?[a-z]+)\s+(\d+)(?:\s*,\s*(\d+)(?:\s*-\s*(\d+))?)?\s*$', ref.lower())
        if not m:
            self.dropped.append(f'{ref} (unparsed)'); return None
        book, ch, v1, v2 = m.group(1), int(m.group(2)), m.group(3), m.group(4)
        book = ALIAS.get(book, book)
        if book not in ABBR:
            self.dropped.append(f'{ref} (unknown book)'); return None
        label_ch = str(ch)
        vs = int(v1) if v1 else 1
        ve = int(v2) if v2 else (int(v1) if v1 else None)
        if book == 'ps':
            hch = ch
            vch, vs = psalm_h2v(hch, vs)
            if ve is not None:
                vch2, ve = psalm_h2v(hch, ve)
                if vch2 != vch:  # range crosses a Vulgate split — keep the first part
                    ve = self.maxv.get((book, vch), ve)
            label_ch = f'{vch}({hch})' if vch != hch else str(hch)
            ch = vch
        mx = self.maxv.get((book, ch))
        if self.maxv and mx is None:
            self.dropped.append(f'{ref} (no such chapter)'); return None
        if ve is None: ve = mx or 1
        if mx and ve > mx:
            self.clamped.append(f'{ref} → {mx}'); ve = mx
        if mx and vs > mx:
            self.dropped.append(f'{ref} (start past chapter)'); return None
        if ve < vs: ve = vs
        label = f'{ABBR[book]} {label_ch}' + (f',{vs}' + (f'-{ve}' if ve != vs else '') if v1 else '')
        return {'ref': label, 'book': book, 'chapter': ch, 'vStart': vs, 'vEnd': ve}

    def passages(self, refs):
        out, seen = [], set()
        for r in refs:
            p = self.passage(r)
            if not p: continue
            key = (p['book'], p['chapter'], p['vStart'], p['vEnd'])
            if key in seen: continue
            seen.add(key); out.append(p)
        return out


def comments(node):
    """Commentaries of a theme or subtopic: author, role, date, the work and
    the place in it. The compilers' internal `fonte` link (a private research
    library) is never shipped."""
    out = []
    for c in node.get('comentarios', []) or []:
        txt = (c.get('comment') or '').strip()
        if not txt: continue
        cm = {'author': c.get('commentator', '').strip(), 'role': c.get('função', '').strip(),
              'edition': c.get('year', '').strip(), 'text': txt}
        for src, dst in (('documento', 'document'), ('localizacao', 'location')):
            v = (c.get(src) or '').strip()
            if v: cm[dst] = v
        out.append(cm)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('src'); ap.add_argument('out'); ap.add_argument('--db')
    a = ap.parse_args()
    src = json.load(open(a.src, encoding='utf-8'))
    b = Builder(a.db)
    groups, themes, used = [], [], set()
    for sec in src['secoes']:
        gid = slug(sec['titulo']); groups.append({'id': gid, 'title': sec['titulo']})
        for t in sec['temas']:
            tid = slug(t['titulo'])
            while tid in used: tid += '-2'
            used.add(tid)
            theme = {'id': tid, 'group': gid, 'title': t['titulo'], 'summary': t.get('resumo', '') or '',
                     'passages': b.passages(t.get('referencias', []))}
            subs = []
            for st in t.get('subtopicos', []) or []:
                ps = b.passages(st.get('referencias', []))
                cs = comments(st)
                if ps or cs:
                    sub = {'title': st['titulo'], 'passages': ps}
                    if cs: sub['comments'] = cs
                    subs.append(sub)
            if subs: theme['subtopics'] = subs
            cms = comments(t)
            if cms: theme['comments'] = cms
            themes.append(theme)
    out = {'version': 3, 'source': 'Biblioteca temática compilada pela equipe, revisão de 2026-11-17 (citações verificadas, com obra e localização)',
           'groups': groups, 'themes': themes}
    json.dump(out, open(a.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    np = sum(len(t['passages']) + sum(len(s['passages']) for s in t.get('subtopics', [])) for t in themes)
    nc = sum(len(t.get('comments', [])) + sum(len(s.get('comments', [])) for s in t.get('subtopics', [])) for t in themes)
    print(f'groups {len(groups)} · themes {len(themes)} · passages {np} · comments {nc} → {a.out}')
    if b.clamped: print(f'clamped ({len(b.clamped)}):', '; '.join(sorted(set(b.clamped))))
    if b.dropped: print(f'dropped ({len(b.dropped)}):', '; '.join(sorted(set(b.dropped))))


if __name__ == '__main__':
    main()

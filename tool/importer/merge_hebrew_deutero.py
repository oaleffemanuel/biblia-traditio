#!/usr/bin/env python3
"""Adds the surviving Hebrew/Aramaic text of Sirach and Tobit to the WLC
Hebrew Bible JSON, so the "Hebraico" column covers the deuterocanon too.

Input: the team's per-book pack (`sir-hb.json`, `tb-hb.json`, …). The other
deuterocanonical files in that pack (1–2 Mc, Jdt, Wis, Bar) are the Swete
Septuagint — those books survive only in Greek — so they are NOT copied into a
Hebrew translation: the app falls back to the Septuagint column for them
(`secondaryTranslationForBookProvider`).

Fragments are taken exactly as the editions give them: a verse is kept only
when it carries at least one Hebrew/Aramaic letter (a bare "[…]" is a gap,
not text). Nothing is reconstructed or filled from the Greek.

- Sirach: Rey & Reymond (2024), metz-theolab/bensira-xml — CC BY-SA 4.0.
- Tobit: Dead Sea Scrolls 4Q196–4Q200, ETCBC/dss (M. Abegg) — CC BY-NC 4.0
  (non-commercial: drop `tb-hb.json` if the app is ever sold or monetised).

Usage: python3 -I merge_hebrew_deutero.py WLC.json PACK_DIR OUT.json
"""
import json
import re
import sys

HEB = re.compile(r'[א-ת]')
BOOKS = [('sir-hb.json', 'Eclesiástico'), ('tb-hb.json', 'Tobias')]


def main(wlc_path, pack_dir, out_path):
    wlc = json.load(open(wlc_path, encoding='utf-8'))
    ot = [b for b in wlc['antigoTestamento'] if b['nome'] not in {n for _, n in BOOKS}]
    for fname, nome in BOOKS:
        try:
            src = json.load(open(f'{pack_dir}/{fname}', encoding='utf-8'))
        except FileNotFoundError:
            print(f'  {fname}: not in pack — skipped')
            continue
        caps, n = [], 0
        for ch in src['chapters']:
            vs = [{'versiculo': v['verse'], 'texto': v['text'].strip()}
                  for v in ch['verses'] if HEB.search(v.get('text') or '')]
            if vs:
                caps.append({'capitulo': ch['chapter'], 'versiculos': vs})
                n += len(vs)
        ot.append({'nome': nome, 'capitulos': caps})
        print(f'  {nome}: {n} verses with surviving text in {len(caps)} chapters')
    wlc['antigoTestamento'] = ot
    json.dump(wlc, open(out_path, 'w', encoding='utf-8'), ensure_ascii=False)


if __name__ == '__main__':
    main(*sys.argv[1:4])

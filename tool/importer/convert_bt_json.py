#!/usr/bin/env python3
"""Convert the team's per-book Bible JSON folder (one `<abbr>-gk.json` /
`<abbr>-hb.json` per book, shape {id, name, language, source, chapters:[{chapter,
verses:[{verse, text, words…}]}]}) into the importer's `biblejson` shape.

Only `text` is taken; word-level morphology stays out of the app. Book identity
comes from the file's USFM-style `id` (GEN, 1SA, SIR…), mapped to the canon id
and the canonical Portuguese name the importer resolves — never from the loose
`name` field. Chapters beyond the canon's count (LXX Psalm 151) are dropped and
reported, since the reader can't navigate to them.

Usage: python3 convert_bt_json.py SRC_DIR OUT.json [--max-chapters-from CANON]
"""
import argparse
import glob
import json
import os
import sys

# USFM id → (canon id, Portuguese name as in tool/importer/lib/models/canon.dart, chapter count)
CANON = {
    'GEN': ('gn', 'Gênesis', 50), 'EXO': ('ex', 'Êxodo', 40), 'LEV': ('lv', 'Levítico', 27),
    'NUM': ('nm', 'Números', 36), 'DEU': ('dt', 'Deuteronômio', 34), 'JOS': ('jo', 'Josué', 24),
    'JDG': ('jgs', 'Juízes', 21), 'RUT': ('rt', 'Rute', 4), '1SA': ('1sm', 'I Samuel', 31),
    '2SA': ('2sm', 'II Samuel', 24), '1KI': ('1kgs', 'I Reis', 22), '2KI': ('2kgs', 'II Reis', 25),
    '1CH': ('1chr', 'I Crônicas', 29), '2CH': ('2chr', 'II Crônicas', 36), 'EZR': ('ezr', 'Esdras', 10),
    'NEH': ('neh', 'Neemias', 13), 'TOB': ('tb', 'Tobias', 14), 'JDT': ('jdt', 'Judite', 16),
    'EST': ('est', 'Ester', 16), '1MA': ('1mac', 'I Macabeus', 16), '2MA': ('2mac', 'II Macabeus', 15),
    'JOB': ('jb', 'Jó', 42), 'PSA': ('ps', 'Salmos', 150), 'PRO': ('prv', 'Provérbios', 31),
    'ECC': ('eccl', 'Eclesiastes', 12), 'SNG': ('sg', 'Cântico dos Cânticos', 8), 'WIS': ('ws', 'Sabedoria', 19),
    'SIR': ('sir', 'Eclesiástico', 51), 'ISA': ('is', 'Isaías', 66), 'JER': ('jer', 'Jeremias', 52),
    'LAM': ('lam', 'Lamentações', 5), 'BAR': ('bar', 'Baruc', 6), 'EZK': ('ez', 'Ezequiel', 48),
    'DAN': ('dn', 'Daniel', 14), 'HOS': ('hos', 'Oseias', 14), 'JOL': ('jl', 'Joel', 3),
    'AMO': ('am', 'Amós', 9), 'OBA': ('ob', 'Abdias', 1), 'JON': ('jon', 'Jonas', 4),
    'MIC': ('mi', 'Miqueias', 7), 'NAM': ('na', 'Naum', 3), 'HAB': ('hb', 'Habacuc', 3),
    'ZEP': ('zep', 'Sofonias', 3), 'HAG': ('hg', 'Ageu', 2), 'ZEC': ('zec', 'Zacarias', 14),
    'MAL': ('mal', 'Malaquias', 4),
    'MAT': ('mt', 'Mateus', 28), 'MRK': ('mk', 'Marcos', 16), 'LUK': ('lk', 'Lucas', 24), 'JHN': ('jn', 'João', 21),
    'ACT': ('acts', 'Atos dos Apóstolos', 28), 'ROM': ('rom', 'Romanos', 16), '1CO': ('1cor', 'I Coríntios', 16),
    '2CO': ('2cor', 'II Coríntios', 13), 'GAL': ('gal', 'Gálatas', 6), 'EPH': ('eph', 'Efésios', 6),
    'PHP': ('phil', 'Filipenses', 4), 'COL': ('col', 'Colossenses', 4), '1TH': ('1thes', 'I Tessalonicenses', 5),
    '2TH': ('2thes', 'II Tessalonicenses', 3), '1TI': ('1tm', 'I Timóteo', 6), '2TI': ('2tm', 'II Timóteo', 4),
    'TIT': ('tit', 'Tito', 3), 'PHM': ('phlm', 'Filêmon', 1), 'HEB': ('heb', 'Hebreus', 13), 'JAS': ('jas', 'Tiago', 5),
    '1PE': ('1pt', 'I Pedro', 5), '2PE': ('2pt', 'II Pedro', 3), '1JN': ('1jn', 'I João', 5), '2JN': ('2jn', 'II João', 1),
    '3JN': ('3jn', 'III João', 1), 'JUD': ('jud', 'Judas', 1), 'REV': ('rv', 'Apocalipse', 22),
}
OT_IDS = {v[0] for k, v in CANON.items()} - {'mt','mk','lk','jn','acts','rom','1cor','2cor','gal','eph','phil','col','1thes','2thes','1tm','2tm','tit','phlm','heb','jas','1pt','2pt','1jn','2jn','3jn','jud','rv'}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('src')
    ap.add_argument('out')
    args = ap.parse_args()
    ot, nt, total, dropped, problems = [], [], 0, [], []
    for f in sorted(glob.glob(os.path.join(args.src, '*.json'))):
        d = json.load(open(f, encoding='utf-8'))
        usfm = str(d.get('id', '')).upper()
        if usfm not in CANON:
            problems.append(f'{os.path.basename(f)}: unknown id {usfm!r}')
            continue
        cid, nome, maxch = CANON[usfm]
        caps = []
        for ch in d.get('chapters', []):
            n = int(ch['chapter'])
            if n < 1 or n > maxch:
                dropped.append(f'{cid} {n}')
                continue
            vv = [{'versiculo': int(v['verse']), 'texto': (v.get('text') or '').strip()}
                  for v in ch.get('verses', []) if (v.get('text') or '').strip()]
            total += len(vv)
            caps.append({'capitulo': n, 'versiculos': vv})
        caps.sort(key=lambda c: c['capitulo'])
        (ot if cid in OT_IDS else nt).append({'nome': nome, 'capitulos': caps})
    json.dump({'antigoTestamento': ot, 'novoTestamento': nt}, open(args.out, 'w'), ensure_ascii=False)
    print(f'books: OT {len(ot)} · NT {len(nt)} · verses {total} → {args.out}')
    if dropped:
        print('dropped chapters beyond canon:', ', '.join(dropped))
    if problems:
        print('⚠ ' + '; '.join(problems)); sys.exit(1)


if __name__ == '__main__':
    main()

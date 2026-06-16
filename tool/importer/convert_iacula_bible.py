#!/usr/bin/env python3
"""Convert the iacula-mobile Portuguese Catholic Bible (73 per-book JSON files)
into the single combined-JSON shape the Biblia Traditio importer's `biblejson`
command expects:

    { "antigoTestamento": [ {nome, capitulos:[{capitulo, versiculos:[{versiculo,texto}]}]} ],
      "novoTestamento":   [ ... ] }

iacula uses its own book codes (file stems) that do NOT match our canon
abbreviations (e.g. iacula `jn`=Jonas vs canon Jonas=`jon`; iacula `jo`=João).
We therefore map by an explicit code -> (canonical PT name, testament) table and
emit `nome` as the EXACT canon name so the importer resolves 73/73 books with no
name-matching ambiguity.

Verse text in some books (e.g. Genesis) carries a leading "[N] " marker; it is
stripped. Verse numbers are coerced to int (a range like "1-2" takes the first).
Duplicate verse numbers within a chapter are merged (text appended) so the
builder's (translation,book,chapter,verse) primary key never collides.

Usage:
  python3 convert_iacula_bible.py [IACULA_BIBLE_DIR] [OUT_JSON]
"""
import json
import os
import re
import sys

# iacula file-stem -> (canonical PT name exactly as in canon.dart, testament)
BOOKS = {
    # ── Old Testament (46) ──
    "gn": ("Gênesis", "ot"), "ex": ("Êxodo", "ot"), "lv": ("Levítico", "ot"),
    "nm": ("Números", "ot"), "dt": ("Deuteronômio", "ot"),
    "js": ("Josué", "ot"), "ju": ("Juízes", "ot"), "rt": ("Rute", "ot"),
    "1sm": ("I Samuel", "ot"), "2sm": ("II Samuel", "ot"),
    "1rs": ("I Reis", "ot"), "2rs": ("II Reis", "ot"),
    "1pa": ("I Crônicas", "ot"), "2pa": ("II Crônicas", "ot"),
    "esd": ("Esdras", "ot"), "ne": ("Neemias", "ot"),
    "tob": ("Tobias", "ot"), "jdi": ("Judite", "ot"), "est": ("Ester", "ot"),
    "1ma": ("I Macabeus", "ot"), "2ma": ("II Macabeus", "ot"),
    "job": ("Jó", "ot"), "ps": ("Salmos", "ot"), "pv": ("Provérbios", "ot"),
    "ees": ("Eclesiastes", "ot"), "cc": ("Cântico dos Cânticos", "ot"),
    "sa": ("Sabedoria", "ot"), "eus": ("Eclesiástico", "ot"),
    "is": ("Isaías", "ot"), "je": ("Jeremias", "ot"),
    "lm": ("Lamentações", "ot"), "ba": ("Baruc", "ot"),
    "ez": ("Ezequiel", "ot"), "dn": ("Daniel", "ot"),
    "os": ("Oseias", "ot"), "jl": ("Joel", "ot"), "am": ("Amós", "ot"),
    "ab": ("Abdias", "ot"), "jn": ("Jonas", "ot"), "mic": ("Miqueias", "ot"),
    "na": ("Naum", "ot"), "hc": ("Habacuc", "ot"), "so": ("Sofonias", "ot"),
    "ag": ("Ageu", "ot"), "zc": ("Zacarias", "ot"), "ml": ("Malaquias", "ot"),
    # ── New Testament (27) ──
    "mt": ("Mateus", "nt"), "mc": ("Marcos", "nt"), "lc": ("Lucas", "nt"),
    "jo": ("João", "nt"), "act": ("Atos dos Apóstolos", "nt"),
    "rm": ("Romanos", "nt"), "1co": ("I Coríntios", "nt"),
    "2co": ("II Coríntios", "nt"), "gl": ("Gálatas", "nt"),
    "ef": ("Efésios", "nt"), "fp": ("Filipenses", "nt"),
    "cl": ("Colossenses", "nt"), "1ts": ("I Tessalonicenses", "nt"),
    "2ts": ("II Tessalonicenses", "nt"), "1tm": ("I Timóteo", "nt"),
    "2tm": ("II Timóteo", "nt"), "tt": ("Tito", "nt"),
    "fm": ("Filêmon", "nt"), "hb": ("Hebreus", "nt"), "tg": ("Tiago", "nt"),
    "1pe": ("I Pedro", "nt"), "2pe": ("II Pedro", "nt"),
    "1jo": ("I João", "nt"), "2jo": ("II João", "nt"), "3jo": ("III João", "nt"),
    "jda": ("Judas", "nt"), "ap": ("Apocalipse", "nt"),
}

LEAD_MARKER = re.compile(r"^\s*\[\d+[a-z]?\]\s*")
LEAD_INT = re.compile(r"^\s*(\d+)")


def first_int(value):
    if isinstance(value, int):
        return value
    m = LEAD_INT.match(str(value))
    return int(m.group(1)) if m else None


def find_book_file(root, code):
    for sub in ("antigotestamento", "novotestamento"):
        p = os.path.join(root, sub, code + ".json")
        if os.path.exists(p):
            return p
    return None


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else (
        os.path.expanduser(
            "~/workspace/iacula-mobile/iacula_app/assets/seed/bible"))
    out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "data", "pt_iacula.json")

    sections = {"ot": [], "nt": []}
    total_verses = 0
    merged = 0
    skipped = 0
    missing = []

    for code, (name, testament) in BOOKS.items():
        path = find_book_file(root, code)
        if not path:
            missing.append(code)
            continue
        data = json.load(open(path, encoding="utf-8"))
        chapters_out = []
        for ch in data.get("capitulos", []):
            cap = first_int(ch.get("capitulo"))
            if cap is None:
                continue
            # merge duplicate verse numbers within the chapter
            by_num = {}
            order = []
            for v in ch.get("versiculos", []):
                n = first_int(v.get("numero"))
                text = LEAD_MARKER.sub("", str(v.get("texto", ""))).strip()
                if n is None or not text:
                    skipped += 1
                    continue
                if n in by_num:
                    by_num[n] = by_num[n] + " " + text
                    merged += 1
                else:
                    by_num[n] = text
                    order.append(n)
            verses = [{"versiculo": n, "texto": by_num[n]} for n in order]
            total_verses += len(verses)
            chapters_out.append({"capitulo": cap, "versiculos": verses})
        sections[testament].append({"nome": name, "capitulos": chapters_out})

    payload = {
        "antigoTestamento": sections["ot"],
        "novoTestamento": sections["nt"],
    }
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False)

    print(f"✓ wrote {out}")
    print(f"  books: OT={len(sections['ot'])} NT={len(sections['nt'])} "
          f"(expected 46/27)")
    print(f"  verses: {total_verses}  merged-dups: {merged}  "
          f"skipped-empty: {skipped}")
    if missing:
        print(f"  ⚠ MISSING source files for codes: {missing}")
        sys.exit(1)


if __name__ == "__main__":
    main()

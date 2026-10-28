#!/usr/bin/env python3
"""Download a CrossWire USFM repository and emit the app's Bible JSON shape."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import tarfile
import tempfile
from pathlib import Path


# CrossWire's Catholic USFM repositories use the Catholic canon order with
# gaps in the historical filename numbering for deuterocanonical books.
BOOK_IDS = [
    "gn", "ex", "lv", "nm", "dt", "jo", "jgs", "rt", "1sm", "2sm",
    "1kgs", "2kgs", "1chr", "2chr", "ezr", "neh", "est", "jb", "ps", "prv",
    "eccl", "sg", "is", "jer", "lam", "ez", "dn", "hos", "jl", "am", "ob",
    "jon", "mi", "na", "hb", "zep", "hg", "zec", "mal", "mt", "mk", "lk",
    "jn", "acts", "rom", "1cor", "2cor", "gal", "eph", "phil", "col", "1thes",
    "2thes", "1tm", "2tm", "tit", "phlm", "heb", "jas", "1pt", "2pt", "1jn",
    "2jn", "3jn", "jud", "rv", "tb", "jdt", "ws", "sir", "bar", "1mac", "2mac",
]

NAMES = {
    "gn": "Gênesis", "ex": "Êxodo", "lv": "Levítico", "nm": "Números", "dt": "Deuteronômio",
    "jo": "Josué", "jgs": "Juízes", "rt": "Rute", "1sm": "I Samuel", "2sm": "II Samuel",
    "1kgs": "I Reis", "2kgs": "II Reis", "1chr": "I Crônicas", "2chr": "II Crônicas",
    "ezr": "Esdras", "neh": "Neemias", "est": "Ester", "jb": "Jó", "ps": "Salmos",
    "prv": "Provérbios", "eccl": "Eclesiastes", "sg": "Cântico dos Cânticos", "is": "Isaías",
    "jer": "Jeremias", "lam": "Lamentações", "ez": "Ezequiel", "dn": "Daniel", "hos": "Oseias",
    "jl": "Joel", "am": "Amós", "ob": "Abdias", "jon": "Jonas", "mi": "Miqueias", "na": "Naum",
    "hb": "Habacuc", "zep": "Sofonias", "hg": "Ageu", "zec": "Zacarias", "mal": "Malaquias",
    "mt": "Mateus", "mk": "Marcos", "lk": "Lucas", "jn": "João", "acts": "Atos dos Apóstolos",
    "rom": "Romanos", "1cor": "I Coríntios", "2cor": "II Coríntios", "gal": "Gálatas", "eph": "Efésios",
    "phil": "Filipenses", "col": "Colossenses", "1thes": "I Tessalonicenses", "2thes": "II Tessalonicenses",
    "1tm": "I Timóteo", "2tm": "II Timóteo", "tit": "Tito", "phlm": "Filêmon", "heb": "Hebreus",
    "jas": "Tiago", "1pt": "I Pedro", "2pt": "II Pedro", "1jn": "I João", "2jn": "II João",
    "3jn": "III João", "jud": "Judas", "rv": "Apocalipse", "tb": "Tobias", "jdt": "Judite",
    "ws": "Sabedoria", "sir": "Eclesiástico", "bar": "Baruc", "1mac": "I Macabeus", "2mac": "II Macabeus",
}
NT_BOOKS = {
    "mt", "mk", "lk", "jn", "acts", "rom", "1cor", "2cor", "gal", "eph", "phil",
    "col", "1thes", "2thes", "1tm", "2tm", "tit", "phlm", "heb", "jas", "1pt",
    "2pt", "1jn", "2jn", "3jn", "jud", "rv",
}


def clean(text: str) -> str:
    text = re.sub(r"\\f .*?\\f\*", "", text)
    text = re.sub(r"\\x .*?\\x\*", "", text)
    # Section headings can follow the final verse of a chapter on the same
    # physical line; they are metadata, not part of the verse.
    text = re.sub(r"\\(?:ms|s\d?|r|d|sp|sr)\s+.*$", "", text)
    text = re.sub(r"\\[a-z0-9]+\*?", "", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def download(url: str, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["curl", "--fail", "--silent", "--show-error", "--max-time", "180", url, "-o", str(destination)],
        check=True,
    )


def parse_file(path: Path) -> list[dict]:
    chapters: list[dict] = []
    current: dict | None = None
    current_verse: dict | None = None
    for raw in path.read_text(encoding="utf-8-sig").splitlines():
        line = raw.strip()
        chapter = re.match(r"^\\c\s+(\d+)", line)
        if chapter:
            current = {"capitulo": int(chapter.group(1)), "versiculos": []}
            chapters.append(current)
            current_verse = None
            continue
        verse = re.match(r"^\\v\s+(\d+)(?:-(\d+))?\s*(.*)$", line)
        if verse:
            if current is None:
                # USFM permits omitting \c 1 in one-chapter books.
                current = {"capitulo": 1, "versiculos": []}
                chapters.append(current)
            current_verse = {"versiculo": int(verse.group(1)), "texto": clean(verse.group(3))}
            if current_verse["texto"]:
                current["versiculos"].append(current_verse)
            continue
        if current_verse is not None and line:
            continuation = re.match(
                r"^\\(?:q\d?|qa|p|m|li\d*)(?=\s|$)\s*(.*)$", line
            )
            if continuation:
                fragment = clean(continuation.group(1))
                if fragment:
                    current_verse["texto"] = clean(
                        current_verse["texto"] + " " + fragment
                    )
                    if current_verse not in current["versiculos"]:
                        current["versiculos"].append(current_verse)
            elif not line.startswith("\\"):
                current_verse["texto"] = clean(current_verse["texto"] + " " + line)
    return chapters


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("repo", help="GitLab project, e.g. crosswire-bible-society/spaplatense")
    parser.add_argument("output", type=Path)
    parser.add_argument("--subdir", default="usfm")
    args = parser.parse_args()

    with tempfile.TemporaryDirectory() as temp:
        archive = Path(temp) / "source.tar.gz"
        download(f"https://gitlab.com/{args.repo}/-/archive/master/{args.repo.rsplit('/', 1)[-1]}-master.tar.gz", archive)
        with tarfile.open(archive, "r:gz") as tar:
            tar.extractall(temp, filter="data")
        root = next(p for p in Path(temp).iterdir() if p.is_dir()) / args.subdir
        files = sorted(root.glob("*.usfm"), key=lambda p: int(p.name.split("_", 1)[0]))
        if len(files) != len(BOOK_IDS):
            raise SystemExit(f"expected {len(BOOK_IDS)} USFM files, found {len(files)}")
        output = {"antigoTestamento": [], "novoTestamento": []}
        for index, path in enumerate(files):
            book_id = BOOK_IDS[index]
            book = {"nome": NAMES[book_id], "capitulos": parse_file(path)}
            output["novoTestamento" if book_id in NT_BOOKS else "antigoTestamento"].append(book)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, ensure_ascii=False), encoding="utf-8")
    print(f"wrote USFM JSON: {args.output}")


if __name__ == "__main__":
    main()

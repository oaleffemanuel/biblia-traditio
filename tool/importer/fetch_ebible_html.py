#!/usr/bin/env python3
"""Download an eBible HTML archive and emit the app's Bible JSON shape."""

from __future__ import annotations

import argparse
import html
import json
import re
import subprocess
import tempfile
import zipfile
from html.parser import HTMLParser
from pathlib import Path

from fetch_crosswire_usfm import BOOK_IDS, NAMES, NT_BOOKS


PREFIXES = [
    "GEN", "EXO", "LEV", "NUM", "DEU", "JOS", "JDG", "RUT", "1SA", "2SA",
    "1KI", "2KI", "1CH", "2CH", "EZR", "NEH", "EST", "JOB", "PSA", "PRO",
    "ECC", "SNG", "ISA", "JER", "LAM", "EZK", "DAN", "HOS", "JOL", "AMO",
    "OBA", "JON", "MIC", "NAM", "HAB", "ZEP", "HAG", "ZEC", "MAL", "MAT",
    "MRK", "LUK", "JHN", "ACT", "ROM", "1CO", "2CO", "GAL", "EPH", "PHP",
    "COL", "1TH", "2TH",
    "1TI", "2TI", "TIT", "PHM", "HEB", "JAS", "1PE", "2PE", "1JN", "2JN",
    "3JN", "JUD", "REV", "TOB", "JDT", "WIS", "SIR", "BAR", "1MA", "2MA",
]


class ChapterParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.chapter: int | None = None
        self.verses: list[dict] = []
        self.current: dict | None = None
        self.skip_depth = 0

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        classes = set((dict(attrs).get("class") or "").split())
        if classes & {"copyright", "footnote", "mt", "ms", "s2", "r"}:
            self.current = None
        if "chapterlabel" in classes:
            self.current = None
        if "verse" in classes:
            ident = dict(attrs).get("id", "")
            match = re.fullmatch(r"V(\d+)", ident)
            if match:
                number = int(match.group(1))
                previous = next((v for v in self.verses if v["versiculo"] == number), None)
                # A handful of eBible pages retain an older wording immediately
                # before the revised wording under the same verse number. Keep
                # the final (revised) text instead of creating an invalid
                # duplicate verse.
                self.current = previous or {"versiculo": number, "texto": ""}
                self.current["texto"] = ""
                if previous is None:
                    self.verses.append(self.current)
        if "notemark" in classes or "popup" in classes:
            self.skip_depth += 1
        if tag == "div" and "chapterlabel" in classes:
            self._chapter_text = ""

    def handle_endtag(self, tag: str) -> None:
        if self.skip_depth:
            self.skip_depth -= 1

    def handle_data(self, data: str) -> None:
        if self.skip_depth:
            return
        text = html.unescape(re.sub(r"\s+", " ", data)).strip()
        if not text:
            return
        if self.current is not None:
            self.current["texto"] = (self.current["texto"] + " " + text).strip()


def download(url: str, destination: Path) -> None:
    subprocess.run(
        ["curl", "--fail", "--silent", "--show-error", "--max-time", "180", url, "-o", str(destination)],
        check=True,
    )


def parse(path: Path) -> dict:
    parser = ChapterParser()
    parser.feed(path.read_text(encoding="utf-8-sig"))
    for verse in parser.verses:
        verse["texto"] = re.sub(r"^\d+\s+", "", verse["texto"]).strip()
    chapter_match = re.search(r"(\d+)$", path.stem)
    chapter = int(chapter_match.group(1)) if chapter_match else 1
    return {"capitulo": chapter, "versiculos": [v for v in parser.verses if v["texto"]]}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    with tempfile.TemporaryDirectory() as temp:
        archive = Path(temp) / "source.zip"
        download(args.url, archive)
        with zipfile.ZipFile(archive) as zipped:
            names = set(zipped.namelist())
            output = {"antigoTestamento": [], "novoTestamento": []}
            if not all(any(name.startswith(prefix) and name.endswith(".htm") for name in names) for prefix in PREFIXES):
                raise SystemExit("archive does not contain all 73 canonical book prefixes")
            for book_id, prefix in zip(BOOK_IDS, PREFIXES):
                chapters = []
                for name in sorted(names):
                    if re.fullmatch(prefix + r"\d+\.htm", name):
                        if name == f"{prefix}00.htm":
                            continue
                        extracted = Path(temp) / Path(name).name
                        extracted.write_bytes(zipped.read(name))
                        chapters.append(parse(extracted))
                book = {"nome": NAMES[book_id], "capitulos": chapters}
                output["novoTestamento" if book_id in NT_BOOKS else "antigoTestamento"].append(book)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, ensure_ascii=False), encoding="utf-8")
    print(f"wrote eBible HTML JSON: {args.output}")


if __name__ == "__main__":
    main()

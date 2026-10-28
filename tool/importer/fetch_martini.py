#!/usr/bin/env python3
"""Fetch the public-domain Catholic Bibbia Martini from Parola Viva.

The API publishes the historical Martini translation (1769–1781) and its
structured data under CC BY 4.0. Responses are cached per chapter so a failed
run can resume without repeating successful requests.
"""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import json
import subprocess
import time
from pathlib import Path


BASE = "https://parolaviva.art/api/v1/bibbia"

# Parola Viva's stable abbreviations mapped to the app's canonical Portuguese
# names. The importer resolves those names to the existing 73-book registry.
BOOKS = {
    "gen": "Gênesis", "es": "Êxodo", "lv": "Levítico", "nm": "Números",
    "dt": "Deuteronômio", "gs": "Josué", "gdc": "Juízes", "rt": "Rute",
    "1sam": "I Samuel", "2sam": "II Samuel", "1re": "I Reis", "2re": "II Reis",
    "1cr": "I Crônicas", "2cr": "II Crônicas", "esd": "Esdras", "ne": "Neemias",
    "tb": "Tobias", "gdt": "Judite", "est": "Ester", "1mac": "I Macabeus",
    "2mac": "II Macabeus", "gb": "Jó", "sal": "Salmos", "pr": "Provérbios",
    "qo": "Eclesiastes", "ct": "Cântico dos Cânticos", "sap": "Sabedoria",
    "sir": "Eclesiástico", "is": "Isaías", "ger": "Jeremias", "lam": "Lamentações",
    "bar": "Baruc", "ez": "Ezequiel", "dn": "Daniel", "os": "Oseias",
    "gl": "Joel", "am": "Amós", "abd": "Abdias", "gio": "Jonas", "mi": "Miqueias",
    "na": "Naum", "ab": "Habacuc", "sof": "Sofonias", "ag": "Ageu",
    "zc": "Zacarias", "ml": "Malaquias", "mt": "Mateus", "mc": "Marcos",
    "lc": "Lucas", "gv": "João", "at": "Atos dos Apóstolos", "rm": "Romanos",
    "1cor": "I Coríntios", "2cor": "II Coríntios", "gal": "Gálatas", "ef": "Efésios",
    "fil": "Filipenses", "col": "Colossenses", "1ts": "I Tessalonicenses",
    "2ts": "II Tessalonicenses", "1tm": "I Timóteo", "2tm": "II Timóteo",
    "tt": "Tito", "fm": "Filêmon", "eb": "Hebreus", "gc": "Tiago",
    "1pt": "I Pedro", "2pt": "II Pedro", "1gv": "I João", "2gv": "II João",
    "3gv": "III João", "gd": "Judas", "ap": "Apocalipse",
}


def fetch(url: str, delay: float, retries: int = 3) -> dict:
    last_error = None
    for attempt in range(retries):
        try:
            response = subprocess.run(
                [
                    "curl", "--fail", "--silent", "--show-error",
                    "--max-time", "30", "--user-agent",
                    "BibliaTraditio-content-builder/1.0", url,
                ],
                check=True,
                capture_output=True,
                text=True,
            )
            payload = json.loads(response.stdout)
            time.sleep(delay)
            return payload
        except Exception as error:  # noqa: BLE001 - retry network failures
            last_error = error
            if attempt + 1 < retries:
                time.sleep(delay * (attempt + 2))
    raise RuntimeError(f"failed to fetch {url}: {last_error}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path)
    parser.add_argument("--cache", type=Path, default=None)
    parser.add_argument("--delay", type=float, default=0.25)
    parser.add_argument("--workers", type=int, default=3)
    args = parser.parse_args()
    cache = args.cache or args.output.with_suffix(".martini-cache")
    cache.mkdir(parents=True, exist_ok=True)

    index_path = cache / "index.json"
    if index_path.exists():
        index = json.loads(index_path.read_text(encoding="utf-8"))
    else:
        index = fetch(f"{BASE}/indice.json", args.delay)
        index_path.write_text(json.dumps(index, ensure_ascii=False), encoding="utf-8")

    pending: list[tuple[str, int, Path]] = []
    for entry in index:
        slug = entry["s"]
        if slug not in BOOKS:
            raise RuntimeError(f"unmapped Martini book: {slug}")
        for chapter in range(1, int(entry["c"]) + 1):
            chapter_path = cache / f"{slug}-{chapter}.json"
            if not chapter_path.exists():
                pending.append((slug, chapter, chapter_path))

    def fetch_chapter(item: tuple[str, int, Path]) -> None:
        slug, chapter, chapter_path = item
        payload = fetch(f"{BASE}/{slug}/{chapter}.json", args.delay)
        chapter_path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")

    if pending:
        print(f"fetching {len(pending)} Martini chapters with {max(1, args.workers)} workers")
        with ThreadPoolExecutor(max_workers=max(1, args.workers)) as pool:
            futures = {pool.submit(fetch_chapter, item): item for item in pending}
            for number, future in enumerate(as_completed(futures), start=1):
                future.result()
                if number % 25 == 0 or number == len(pending):
                    print(f"  fetched {number}/{len(pending)}")

    result = {"antigoTestamento": [], "novoTestamento": []}
    for position, entry in enumerate(index):
        slug = entry["s"]
        if slug not in BOOKS:
            raise RuntimeError(f"unmapped Martini book: {slug}")
        chapters = []
        for chapter in range(1, int(entry["c"]) + 1):
            chapter_path = cache / f"{slug}-{chapter}.json"
            if chapter_path.exists():
                payload = json.loads(chapter_path.read_text(encoding="utf-8"))
            else:
                raise RuntimeError(f"missing cached chapter after download: {chapter_path}")
            verses = [
                {"versiculo": int(verse["n"]), "texto": verse["t"]}
                for verse in payload.get("v", [])
                if str(verse.get("t", "")).strip()
            ]
            chapters.append({"capitulo": chapter, "versiculos": verses})
        book = {"nome": BOOKS[slug], "capitulos": chapters}
        # The first 46 entries are the Catholic Old Testament in the API index.
        result["antigoTestamento" if position < 46 else "novoTestamento"].append(book)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, ensure_ascii=False), encoding="utf-8")
    print(f"wrote Martini JSON: {args.output}")


if __name__ == "__main__":
    main()

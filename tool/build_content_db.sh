#!/usr/bin/env bash
# Builds modular content packages into assets/packages/:
#   bible_vulgata.sqlite.gz  (required, public-domain Clementine Vulgate)
#   patristics.sqlite.gz     (optional, Church Fathers commentary)
#   manifest.json            (metadata + SHA-256 of each decompressed DB)
#
# The .sqlite.gz files are gitignored build artifacts. Reproducible: fetches the
# PD Vulgate from open-bibles. Patristic corpus path via PATRISTICS_DIR.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMP="$ROOT/tool/importer"
DATA="$IMP/data"
PKG="$ROOT/assets/packages"
VUL="$DATA/lat-clementine.usfx.xml"
PATRISTICS_DIR="${PATRISTICS_DIR:-$HOME/Downloads/Bíblia Católica Tradicional - Comentada/Comentários}"
VUL_URL="https://raw.githubusercontent.com/seven1m/open-bibles/master/lat-clementine.usfx.xml"

mkdir -p "$DATA" "$PKG"
[ -f "$VUL" ] || { echo "↓ fetching public-domain Clementine Vulgate…"; curl -fsSL "$VUL_URL" -o "$VUL"; }

cd "$IMP"; dart pub get >/dev/null

echo "▶ Bible (Vulgata Clementina)"
rm -f "$DATA/bible_vulgata.sqlite" "$DATA/bible_vulgata.sqlite-wal" "$DATA/bible_vulgata.sqlite-shm"
dart run bin/import.dart usfx --src "$VUL" --translation vulgata --lang la \
  --title "Vulgata Clementina" --license "Domínio público" --out "$DATA/bible_vulgata.sqlite"

echo "▶ Patristics"
rm -f "$DATA/patristics.sqlite" "$DATA/patristics.sqlite-wal" "$DATA/patristics.sqlite-shm"
dart run bin/import.dart patristics --src "$PATRISTICS_DIR" --out "$DATA/patristics.sqlite"

sha() { shasum -a 256 "$1" | awk '{print $1}'; }
sz()  { stat -f%z "$1"; }

echo "▶ compress + checksum"
gzip -9 -c "$DATA/bible_vulgata.sqlite" > "$PKG/bible_vulgata.sqlite.gz"
gzip -9 -c "$DATA/patristics.sqlite"    > "$PKG/patristics.sqlite.gz"

BV_SHA=$(sha "$DATA/bible_vulgata.sqlite"); BV_SZ=$(sz "$DATA/bible_vulgata.sqlite"); BV_GZ=$(sz "$PKG/bible_vulgata.sqlite.gz")
PA_SHA=$(sha "$DATA/patristics.sqlite");    PA_SZ=$(sz "$DATA/patristics.sqlite");    PA_GZ=$(sz "$PKG/patristics.sqlite.gz")

cat > "$PKG/manifest.json" <<JSON
{
  "schema": 1,
  "packages": [
    {
      "id": "bible_vulgata",
      "title": "Vulgata Clementina",
      "language": "la",
      "type": "bible_translation",
      "version": 1,
      "source": "open-bibles (Clementine Vulgate, USFX)",
      "license": "Domínio público",
      "asset": "assets/packages/bible_vulgata.sqlite.gz",
      "url": null,
      "sizeBytes": $BV_SZ,
      "compressedBytes": $BV_GZ,
      "sha256": "$BV_SHA",
      "required": true
    },
    {
      "id": "patristics",
      "title": "Comentário dos Padres da Igreja",
      "language": "pt-BR",
      "type": "patristics",
      "version": 1,
      "source": "Catena / Haydock (tradução automática de fontes em domínio público)",
      "license": "Fontes em domínio público; tradução automática",
      "asset": "assets/packages/patristics.sqlite.gz",
      "url": null,
      "sizeBytes": $PA_SZ,
      "compressedBytes": $PA_GZ,
      "sha256": "$PA_SHA",
      "required": false
    }
  ]
}
JSON

echo "✓ packages → assets/packages/"
ls -lh "$PKG"/*.gz "$PKG"/manifest.json | awk '{print "  "$5"\t"$9}'

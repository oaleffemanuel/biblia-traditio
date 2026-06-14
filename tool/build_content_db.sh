#!/usr/bin/env bash
# Builds the bundled content DB (Scripture + patristics) into assets/content/.
# Reproducible: fetches the public-domain Clementine Vulgate from open-bibles.
# The patristic corpus path is supplied via PATRISTICS_DIR (machine-local data).
#
#   PATRISTICS_DIR=/path/to/Comentários ./tool/build_content_db.sh
#   # optional DEV-only Portuguese (NEVER ship): BT_DEV_PT=/path/avemaria.json ...
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMP="$ROOT/tool/importer"
DATA="$IMP/data"
OUT="$DATA/biblia_traditio.sqlite"
VUL="$DATA/lat-clementine.usfx.xml"
PATRISTICS_DIR="${PATRISTICS_DIR:-$HOME/Downloads/Bíblia Católica Tradicional - Comentada/Comentários}"
VUL_URL="https://raw.githubusercontent.com/seven1m/open-bibles/master/lat-clementine.usfx.xml"

mkdir -p "$DATA"
[ -f "$VUL" ] || { echo "↓ fetching public-domain Clementine Vulgate…"; curl -fsSL "$VUL_URL" -o "$VUL"; }

rm -f "$OUT" "$OUT"-*
cd "$IMP"
dart pub get >/dev/null

echo "▶ patristics"
dart run bin/import.dart patristics --src "$PATRISTICS_DIR" --out "$OUT"
echo "▶ Vulgata Clementina (public domain)"
dart run bin/import.dart usfx --src "$VUL" --translation vulgata --lang la \
  --title "Vulgata Clementina" --license "Domínio público" --out "$OUT"

if [ -n "${BT_DEV_PT:-}" ]; then
  echo "▶ DEV Portuguese (NOT for release)"
  dart run bin/import.dart biblejson --src "$BT_DEV_PT" --translation pt_cat \
    --title "Bíblia Católica (PT, DEV)" --license "DEV — não publicar" --out "$OUT"
fi

mkdir -p "$ROOT/assets/content"
cp "$OUT" "$ROOT/assets/content/biblia_traditio.sqlite"
echo "✓ content DB → assets/content/biblia_traditio.sqlite ($(du -h "$OUT" | cut -f1))"

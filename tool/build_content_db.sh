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
# Patristic corpus. PATRISTICS_DIR is the coverage floor (original corpus);
# PATRISTICS_CORRECTED_DIR (optional) is an overlay of curated/blacklist-fixed
# books that take precedence per-book. The two are merged before import so a
# missing corrected book never drops coverage. See the "Patristics" step below.
PATRISTICS_DIR="${PATRISTICS_DIR:-$HOME/Downloads/Bíblia Católica Tradicional - Comentada/Comentários}"
PATRISTICS_CORRECTED_DIR="${PATRISTICS_CORRECTED_DIR:-$HOME/Downloads/Biblia Catolica Tradicional Comentada/Comentários Corrigidos (GPT)}"
VUL_URL="https://raw.githubusercontent.com/seven1m/open-bibles/master/lat-clementine.usfx.xml"

mkdir -p "$DATA" "$PKG"
[ -f "$VUL" ] || { echo "↓ fetching public-domain Clementine Vulgate…"; curl -fsSL "$VUL_URL" -o "$VUL"; }

cd "$IMP"; dart pub get >/dev/null

echo "▶ Bible (Vulgata Clementina)"
rm -f "$DATA/bible_vulgata.sqlite" "$DATA/bible_vulgata.sqlite-wal" "$DATA/bible_vulgata.sqlite-shm"
dart run bin/import.dart usfx --src "$VUL" --translation vulgata --lang la \
  --title "Vulgata Clementina" --license "Domínio público" --out "$DATA/bible_vulgata.sqlite"

# Portuguese (BETA): an internal Catholic PT corpus (iacula) added as a second
# translation in the SAME bible DB so it appears in translation selection and
# Parallel Reading. Provenance unconfirmed → flagged "beta" (see check_release).
# Degrades to a Latin-only build if the source isn't present.
PT_SRC="${IACULA_BIBLE_DIR:-$HOME/workspace/iacula-mobile/iacula_app/assets/seed/bible}"
if [ -d "$PT_SRC" ]; then
  echo "▶ Bible (Português — beta, corpus interno)"
  python3 "$IMP/convert_iacula_bible.py" "$PT_SRC" "$DATA/pt_iacula.json"
  dart run bin/import.dart biblejson --src "$DATA/pt_iacula.json" --translation pt_beta --lang pt \
    --title "Bíblia Católica (Português)" \
    --license "Uso interno (beta) — origem da tradução a confirmar" \
    --out "$DATA/bible_vulgata.sqlite"
else
  echo "▶ Bible (Português) — SKIPPED: source not found at $PT_SRC (Latin-only build)"
fi

# Portuguese — Padre Matos Soares (public-domain candidate). A third translation
# in the same DB. Fetched once from padrepauloricardo.org (clean structured blob,
# proper versification) and cached; regenerate by deleting the cached JSON.
MS_JSON="$DATA/pt_matos_soares.json"
[ -f "$MS_JSON" ] || python3 "$IMP/fetch_matos_soares.py" "$MS_JSON" || true
if [ -f "$MS_JSON" ]; then
  echo "▶ Bible (Português — Padre Matos Soares)"
  dart run bin/import.dart biblejson --src "$MS_JSON" --translation pt_matos_soares --lang pt \
    --title "Padre Matos Soares" \
    --license "Domínio público (Pe. Matos Soares †1950) — verificação de proveniência em beta" \
    --out "$DATA/bible_vulgata.sqlite"
else
  echo "▶ Bible (Matos Soares) — SKIPPED: $MS_JSON not available"
fi

echo "▶ Patristics"
# Merge: original corpus = coverage floor; corrected corpus overlaid per book.
# Drops the redundant coment-jude.json (alias jude→jud would double-import Jude).
PAT_SRC="$PATRISTICS_DIR"
if [ -d "$PATRISTICS_CORRECTED_DIR" ]; then
  MERGED="$DATA/patristics_merged"
  rm -rf "$MERGED"; mkdir -p "$MERGED"
  cp -f "$PATRISTICS_DIR"/coment-*.json "$MERGED"/ 2>/dev/null || true
  [ -f "$PATRISTICS_DIR/aliases_normalizados.json" ] && cp -f "$PATRISTICS_DIR/aliases_normalizados.json" "$MERGED"/
  cp -f "$PATRISTICS_CORRECTED_DIR"/coment-*.json "$MERGED"/ 2>/dev/null || true
  rm -f "$MERGED/coment-jude.json"   # dedup: keep coment-jud.json (canonical Jude)
  PAT_SRC="$MERGED"
  echo "  merged corrected overlay → $MERGED ($(ls "$MERGED"/coment-*.json | wc -l | tr -d ' ') books)"
else
  echo "  corrected overlay not found at $PATRISTICS_CORRECTED_DIR — using base corpus only"
fi
rm -f "$DATA/patristics.sqlite" "$DATA/patristics.sqlite-wal" "$DATA/patristics.sqlite-shm"
dart run bin/import.dart patristics --src "$PAT_SRC" --out "$DATA/patristics.sqlite"

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
      "title": "Bíblia (Vulgata Clementina + Português)",
      "language": "la",
      "type": "bible_translation",
      "version": 3,
      "source": "Vulgata: open-bibles (Clementine, USFX). Português: corpus interno (iacula) — origem da tradução a confirmar. Matos Soares: padrepauloricardo.org (edição matos-soares).",
      "license": "Vulgata: domínio público. Português (beta): uso interno — origem da tradução a confirmar. Matos Soares: domínio público (Pe. Matos Soares †1950) — verificação de proveniência em beta.",
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
      "version": 2,
      "source": "Catena / Haydock (tradução automática de fontes em domínio público; revisão e curadoria de autoria)",
      "license": "Fontes em domínio público; tradução automática revisada",
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

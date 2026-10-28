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
# Patristic corpus, two layers:
#   PATRISTICS_DIR            original corpus (coment-*.json) — the coverage floor.
#   PATRISTICS_CORRECTED_DIR  legacy per-book corrections, merged into the floor.
#   PATRISTICS_IMPROVED_DIR   the revised corpus ("Comentários melhorados",
#                             <book>_pt.json) carrying corrected text plus each
#                             commentator's `função` and year. It wins PER VERSE;
#                             verses it doesn't cover keep the original text, so
#                             an incomplete revision can never shrink coverage.
PATRISTICS_DIR="${PATRISTICS_DIR:-$ROOT/tool/importer/data/patristics_merged}"
PATRISTICS_CORRECTED_DIR="${PATRISTICS_CORRECTED_DIR:-$HOME/Downloads/Biblia Catolica Tradicional Comentada/Comentários Corrigidos (GPT)}"
PATRISTICS_IMPROVED_DIR="${PATRISTICS_IMPROVED_DIR:-$HOME/Downloads/Biblia Traditio/Comentários melhorados (PRONTO!!)/Português (PRONTO!!)}"
VUL_URL="https://raw.githubusercontent.com/seven1m/open-bibles/master/lat-clementine.usfx.xml"

mkdir -p "$DATA" "$DATA/reports" "$PKG"
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
    --license "Pe. Matos Soares †1957 — domínio público só a partir de 01/01/2028; NÃO publicar sem licença (beta)" \
    --out "$DATA/bible_vulgata.sqlite"
else
  echo "▶ Bible (Matos Soares) — SKIPPED: $MS_JSON not available"
fi

# Greek New Testament — SBLGNT (CC BY 4.0). Original-language NT; verse
# numbering aligns with the NT canon, so it works in Parallel Reading. Fetched
# once from morphgnt/sblgnt and cached.
GRC_JSON="$DATA/grc_sblgnt.json"
[ -f "$GRC_JSON" ] || python3 "$IMP/fetch_sblgnt.py" "$GRC_JSON" || true
if [ -f "$GRC_JSON" ]; then
  echo "▶ Bible (Grego — SBLGNT)"
  dart run bin/import.dart biblejson --src "$GRC_JSON" --translation grc_sblgnt --lang grc \
    --title "Novo Testamento Grego (SBLGNT)" \
    --license "CC BY 4.0 — SBL Greek New Testament (Society of Biblical Literature & Logos Bible Software)" \
    --out "$DATA/bible_vulgata.sqlite"
else
  echo "▶ Bible (SBLGNT) — SKIPPED: $GRC_JSON not available"
fi

# Hebrew Old Testament — Westminster Leningrad Codex via Open Scriptures
# (morphhb, OSIS). WLC text is public domain; the OSHB morphology (CC BY 4.0)
# is not bundled. Psalms are stored in Vulgate numbering (fetch_wlc.py maps
# them) so the Masoretic text aligns in Parallel Reading. Fetched once, cached.
HBO_JSON="$DATA/hbo_wlc.json"
[ -f "$HBO_JSON" ] || python3 "$IMP/fetch_wlc.py" "$HBO_JSON" || true
if [ -f "$HBO_JSON" ]; then
  echo "▶ Bible (Hebraico — Códice de Leningrado, WLC)"
  dart run bin/import.dart biblejson --src "$HBO_JSON" --translation hbo_wlc --lang hbo \
    --title "Texto Hebraico (Códice de Leningrado)" \
    --license "Domínio público — Westminster Leningrad Codex; texto via Open Scriptures Hebrew Bible Project" \
    --out "$DATA/bible_vulgata.sqlite"
else
  echo "▶ Bible (WLC) — SKIPPED: $HBO_JSON not available"
fi

# Italian — Bibbia Martini (1769–1781), the historical Catholic translation
# from the Vulgate. The text is public domain; Parola Viva's structured data
# is CC BY 4.0. Chapter responses are cached so interrupted builds resume.
MARTINI_JSON="$DATA/it_martini.json"
if [ -f "$MARTINI_JSON" ] || {
  [ "${ENABLE_MARTINI:-0}" = "1" ] &&
  python3 "$IMP/fetch_martini.py" "$MARTINI_JSON";
}; then
  echo "▶ Bible (Italiano — Bibbia Martini)"
  dart run bin/import.dart biblejson --src "$MARTINI_JSON" --translation it_martini --lang it \
    --title "Bibbia Martini" \
    --license "Texto histórico em domínio público (Antonio Martini, 1769–1781); dados estruturados CC BY 4.0 — Parola Viva" \
    --out "$DATA/bible_vulgata.sqlite"
else
  echo "▶ Bible (Martini) — SKIPPED: source unavailable"
fi

# Spanish — Biblia Platense (Straubinger), a Catholic translation whose
# CrossWire source repository is public domain. USFM is converted locally and
# validated before it enters the same scripture database.
ES_JSON="$DATA/es_straubinger.json"
if [ -f "$ES_JSON" ] || python3 "$IMP/fetch_crosswire_usfm.py" \
    crosswire-bible-society/spaplatense "$ES_JSON"; then
  echo "▶ Bible (Español — Biblia Platense/Straubinger)"
  dart run bin/import.dart biblejson --src "$ES_JSON" --translation es_straubinger --lang es \
    --title "Biblia Platense (Straubinger)" \
    --license "Domínio público — CrossWire SpaPlatense; tradução católica de Juan Straubinger" \
    --out "$DATA/bible_vulgata.sqlite" --strict
else
  echo "▶ Bible (Straubinger) — SKIPPED: source unavailable"
fi

# French — néo-Crampon Libre, a Catholic revision of Crampon published by
# Fraternité de Tibériade under CC BY-SA 4.0 via eBible. The archive is cached
# locally and parsed into the same canonical 73-book shape.
FR_JSON="$DATA/fr_neocrampon.json"
FR_URL="https://eBible.org/Scriptures/francl_html.zip"
if [ -f "$FR_JSON" ] || python3 "$IMP/fetch_ebible_html.py" "$FR_URL" "$FR_JSON"; then
  echo "▶ Bible (Français — néo-Crampon Libre)"
  dart run bin/import.dart biblejson --src "$FR_JSON" --translation fr_neocrampon --lang fr \
    --title "Bible néo-Crampon Libre" \
    --license "CC BY-SA 4.0 — Fraternité de Tibériade via eBible; modernisation catholique de Crampon" \
    --out "$DATA/bible_vulgata.sqlite" --strict
else
  echo "▶ Bible (néo-Crampon Libre) — SKIPPED: source unavailable"
fi

sha() { shasum -a 256 "$1" | awk '{print $1}'; }
sz()  { stat -f%z "$1"; }

echo "▶ Patristics"
# Merge: original corpus = coverage floor; corrected corpus overlaid per book.
# Drops the redundant coment-jude.json (alias jude→jud would double-import Jude).
PAT_SRC="$PATRISTICS_DIR"
if [ -d "$PATRISTICS_CORRECTED_DIR" ] && [ -d "$PATRISTICS_DIR" ]; then
  MERGED="$DATA/patristics_merged"
  rm -rf "$MERGED"; mkdir -p "$MERGED"
  cp -f "$PATRISTICS_DIR"/coment-*.json "$MERGED"/ 2>/dev/null || true
  [ -f "$PATRISTICS_DIR/aliases_normalizados.json" ] && cp -f "$PATRISTICS_DIR/aliases_normalizados.json" "$MERGED"/
  cp -f "$PATRISTICS_CORRECTED_DIR"/coment-*.json "$MERGED"/ 2>/dev/null || true
  rm -f "$MERGED/coment-jude.json"   # dedup: keep coment-jud.json (canonical Jude)
  PAT_SRC="$MERGED"
  echo "  merged corrected overlay → $MERGED ($(ls "$MERGED"/coment-*.json | wc -l | tr -d ' ') books)"
fi
gzip -9 -c "$DATA/bible_vulgata.sqlite" > "$PKG/bible_vulgata.sqlite.gz"
BV_SHA=$(sha "$DATA/bible_vulgata.sqlite"); BV_SZ=$(sz "$DATA/bible_vulgata.sqlite"); BV_GZ=$(sz "$PKG/bible_vulgata.sqlite.gz")
PAT_ARGS=()
[ -d "$PAT_SRC" ] && PAT_ARGS+=(--src "$PAT_SRC")
if [ -d "$PATRISTICS_IMPROVED_DIR" ]; then
  PAT_ARGS+=(--overlay "$PATRISTICS_IMPROVED_DIR")
  echo "  revised corpus overlay → $PATRISTICS_IMPROVED_DIR"
else
  echo "  revised corpus not found at $PATRISTICS_IMPROVED_DIR — original only"
fi
# Never regress the shipped pack: the revised corpus (função + curated text) is
# what v4+ ships. If it is absent on this machine but a pack already exists,
# reuse the pack instead of rebuilding from the original-only corpus.
if [ ! -d "$PATRISTICS_IMPROVED_DIR" ] && [ -f "$PKG/patristics.sqlite.gz" ]; then
  echo "  revised corpus absent — keeping the existing patristics package untouched"
  PAT_ARGS=()
fi
if [ ${#PAT_ARGS[@]} -gt 0 ]; then
  rm -f "$DATA/patristics.sqlite" "$DATA/patristics.sqlite-wal" "$DATA/patristics.sqlite-shm"
  dart run bin/import.dart patristics "${PAT_ARGS[@]}" \
    --report "$DATA/reports/patristics_coverage.json" \
    --out "$DATA/patristics.sqlite"
  gzip -9 -c "$DATA/patristics.sqlite" > "$PKG/patristics.sqlite.gz"
  PA_SHA=$(sha "$DATA/patristics.sqlite"); PA_SZ=$(sz "$DATA/patristics.sqlite")
elif [ -f "$PKG/patristics.sqlite.gz" ]; then
  # Source not present (build-machine corpus absent) — keep the existing pack.
  echo "  patristics source not found at $PAT_SRC — reusing existing package (unchanged)"
  PA_SZ=$(gzip -dc "$PKG/patristics.sqlite.gz" | wc -c | tr -d ' ')
  PA_SHA=$(gzip -dc "$PKG/patristics.sqlite.gz" | shasum -a 256 | awk '{print $1}')
else
  echo "  ✗ no patristics source and no existing pack — aborting"; exit 1
fi
PA_GZ=$(sz "$PKG/patristics.sqlite.gz")

BIBLE_TITLE="Bíblia (Vulgata + Português + Grego + Hebraico + Espanhol + Francês)"
BIBLE_VERSION=10
BIBLE_SOURCE="Vulgata: open-bibles (Clementine, USFX). Português: corpus interno (iacula) — origem da tradução a confirmar. Matos Soares: padrepauloricardo.org (edição matos-soares). Grego: SBLGNT via morphgnt. Hebraico: Westminster Leningrad Codex via Open Scriptures (morphhb). Espanhol: Biblia Platense (Straubinger) via CrossWire SpaPlatense. Francês: néo-Crampon Libre via eBible."
BIBLE_LICENSE="Vulgata: domínio público. Português (beta): uso interno — origem da tradução a confirmar. Matos Soares: Pe. Matos Soares †1957 — domínio público só a partir de 01/01/2028; não publicar sem licença (beta). Grego: CC BY 4.0 (SBLGNT, SBL & Logos). Hebraico: domínio público (WLC). Espanhol: domínio público — CrossWire SpaPlatense. Francês: CC BY-SA 4.0 — Fraternité de Tibériade via eBible."
if [ -f "$FR_JSON" ]; then
  BIBLE_VERSION=11
fi
if [ -f "$MARTINI_JSON" ]; then
  BIBLE_TITLE="Bíblia (Vulgata + Português + Grego + Hebraico + Italiano + Espanhol + Francês)"
  BIBLE_VERSION=12
  BIBLE_SOURCE="$BIBLE_SOURCE Italiano: Bibbia Martini via Parola Viva."
  BIBLE_LICENSE="$BIBLE_LICENSE Italiano: texto histórico em domínio público; dados estruturados CC BY 4.0."
fi

cat > "$PKG/manifest.json" <<JSON
{
  "schema": 1,
  "packages": [
    {
      "id": "bible_vulgata",
      "title": "$BIBLE_TITLE",
      "language": "la",
      "type": "bible_translation",
      "version": $BIBLE_VERSION,
      "source": "$BIBLE_SOURCE",
      "license": "$BIBLE_LICENSE",
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
      "version": 5,
      "source": "Catena Aurea / Haydock (tradução automática de fontes em domínio público; revisão e curadoria de autoria, com função e século de cada comentador)",
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

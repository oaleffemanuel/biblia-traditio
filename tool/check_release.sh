#!/usr/bin/env bash
# Release safeguard. Fails (exit 1) if the build is not safe to publish:
#  - content DB missing
#  - DB has no Scripture / has validation errors
#  - a dev or copyrighted translation is bundled (id pt_cat, or license ~ DEV)
#  - a hardcoded machine path leaked into lib/
#  - the content DB is not gitignored, or any .sqlite is tracked in git
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DB="$ROOT/assets/content/biblia_traditio.sqlite"
fail=0
ok()  { echo "  ✓ $1"; }
err() { echo "  ✗ $1"; fail=1; }

echo "Biblia Traditio — release check"

if [ ! -f "$DB" ]; then
  err "content DB missing (run tool/build_content_db.sh)"
else
  verses=$(sqlite3 "$DB" "SELECT COUNT(*) FROM verse;" 2>/dev/null || echo 0)
  [ "${verses:-0}" -gt 0 ] && ok "scripture present ($verses verses)" \
    || err "no verses in content DB"

  ve=$(sqlite3 "$DB" "SELECT COALESCE((SELECT value FROM meta WHERE key='bible_validation_errors'),'0');" 2>/dev/null || echo "?")
  [ "$ve" = "0" ] && ok "bible validation clean" || err "bible validation errors: $ve"

  dev=$(sqlite3 "$DB" "SELECT COUNT(*) FROM translation WHERE id='pt_cat' OR UPPER(IFNULL(license,'')) LIKE '%DEV%';" 2>/dev/null || echo "?")
  [ "$dev" = "0" ] && ok "no dev/copyrighted translation bundled" \
    || err "dev/copyrighted translation present (id=pt_cat or license~DEV) — NOT shippable"
fi

if grep -rnE "['\"]/(Users|home)/" "$ROOT/lib" >/dev/null 2>&1; then
  err "hardcoded machine path in lib/:"; grep -rnE "['\"]/(Users|home)/" "$ROOT/lib"
else
  ok "no machine paths in lib/"
fi

git -C "$ROOT" check-ignore assets/content/biblia_traditio.sqlite >/dev/null 2>&1 \
  && ok "content DB is gitignored" || err "content DB is NOT gitignored"

if git -C "$ROOT" ls-files | grep -qE '\.sqlite$'; then
  err "a .sqlite file is tracked in git"; git -C "$ROOT" ls-files | grep -E '\.sqlite$'
else
  ok "no .sqlite tracked in git"
fi

echo
if [ "$fail" = 0 ]; then echo "RELEASE CHECK PASSED"; else echo "RELEASE CHECK FAILED"; exit 1; fi

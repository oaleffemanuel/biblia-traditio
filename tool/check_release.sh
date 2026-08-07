#!/usr/bin/env bash
# Release safeguard. Exit 1 if the build is not safe to publish:
#  - content manifest missing or a package is missing required metadata
#  - a bundled package's gz asset is missing or its SHA-256 ≠ manifest
#  - a dev/copyrighted Bible is bundled (id ~ pt_cat/avemaria, or license ~ DEV)
#  - a user database is bundled by mistake
#  - a hardcoded machine path exists in lib/
#  - any content artifact (.sqlite/.gz) or the manifest is tracked in git
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$ROOT/assets/packages"
MAN="$PKG/manifest.json"
fail=0
ok()  { echo "  ✓ $1"; }
err() { echo "  ✗ $1"; fail=1; }

echo "Biblia Traditio — release check"

# 1–4: manifest + packages + checksums + no dev/copyrighted content
if [ ! -f "$MAN" ]; then
  err "content manifest missing ($MAN) — run tool/build_content_db.sh"
else
  python3 - "$PKG" <<'PY' || fail=1
import json, sys, os, hashlib, gzip
pkgdir = sys.argv[1]
man = json.load(open(os.path.join(pkgdir, "manifest.json")))
req = ["id","title","language","type","version","source","license","sha256"]
pkgs = man.get("packages", [])
if not pkgs:
    print("  ✗ manifest has no packages"); sys.exit(1)
bad = 0
has_bible = False
for p in pkgs:
    pid = p.get("id","?")
    missing = [f for f in req if not p.get(f)]
    if missing:
        print(f"  ✗ {pid}: missing metadata {missing}"); bad = 1
    if p.get("type") == "bible_translation":
        has_bible = True
        lic = (p.get("license") or "").upper()
        if "DEV" in lic or "AVE MARIA" in lic or pid in ("pt_cat","avemaria"):
            print(f"  ✗ {pid}: dev/copyrighted Bible bundled — NOT shippable"); bad = 1
        # Beta/internal-provenance scripture is acceptable for an INTERNAL beta
        # build but must never reach a public release. Gated by the BETA env var.
        blob = " ".join(str(p.get(k, "")) for k in ("id", "license", "source")).lower()
        if any(w in blob for w in ("beta", "interno", "a confirmar", "unverified")):
            if os.environ.get("BETA"):
                print(f"  ⚠ {pid}: beta/internal scripture — allowed for internal beta (BETA=1)")
            else:
                print(f"  ✗ {pid}: beta/internal scripture — NOT for public release "
                      f"(set BETA=1 for an internal beta build)"); bad = 1
    asset = p.get("asset")
    if asset:
        gz = os.path.join(pkgdir, os.path.basename(asset))
        if not os.path.exists(gz):
            print(f"  ✗ {pid}: bundled asset missing ({gz})"); bad = 1
            continue
        h = hashlib.sha256()
        with gzip.open(gz, "rb") as f:
            for chunk in iter(lambda: f.read(1 << 20), b""):
                h.update(chunk)
        if h.hexdigest() != p.get("sha256"):
            print(f"  ✗ {pid}: checksum mismatch (asset ≠ manifest)"); bad = 1
        else:
            print(f"  ✓ {pid}: checksum OK")
if not has_bible:
    print("  ✗ no bible_translation package in manifest"); bad = 1
sys.exit(1 if bad else 0)
PY
fi

# 5: no user database bundled
if ls "$PKG"/user*.sqlite* >/dev/null 2>&1 || grep -q '"type"[[:space:]]*:[[:space:]]*"user"' "$MAN" 2>/dev/null; then
  err "a user database is present in assets/packages"
else
  ok "no user database bundled"
fi

# 6: no machine paths in lib/
if grep -rnE "['\"]/(Users|home)/" "$ROOT/lib" >/dev/null 2>&1; then
  err "hardcoded machine path in lib/:"; grep -rnE "['\"]/(Users|home)/" "$ROOT/lib"
else
  ok "no machine paths in lib/"
fi

# 7: nothing heavy tracked in git
tracked=$(git -C "$ROOT" ls-files | grep -E '\.(sqlite|sqlite\.gz|gz)$|assets/packages/manifest\.json$' || true)
if [ -n "$tracked" ]; then
  err "content artifacts tracked in git:"; echo "$tracked"
else
  ok "no content artifacts tracked in git"
fi

# 8: Android release configuration. Signing itself is only *warned* about here —
# a developer machine legitimately has no keystore — but everything that must be
# true of a publishable build is checked.
GRADLE="$ROOT/android/app/build.gradle.kts"
MANIFEST="$ROOT/android/app/src/main/AndroidManifest.xml"
if [ ! -f "$GRADLE" ]; then
  err "android/app/build.gradle.kts missing"
else
  grep -q 'applicationId = "br.com.bibliatraditio' "$GRADLE" \
    && ok "applicationId set" || err "applicationId not set to the published id"
  grep -qE 'targetSdk = 3[5-9]' "$GRADLE" \
    && ok "targetSdk meets the Play requirement" \
    || err "targetSdk must be pinned to 35+ for Play"
  grep -qE 'minSdk = 2[1-9]' "$GRADLE" && ok "minSdk pinned" || err "minSdk not pinned"
  grep -q 'signingConfigs.getByName("release")' "$GRADLE" \
    && ok "release signing config wired" || err "no release signing config"
  # Secrets must never be inline.
  if grep -qE '(storePassword|keyPassword)\s*=\s*"' "$GRADLE"; then
    err "a signing password is hardcoded in build.gradle.kts"
  else
    ok "no signing secrets in build.gradle.kts"
  fi
fi
if [ -f "$ROOT/android/key.properties" ]; then
  git -C "$ROOT" ls-files --error-unmatch android/key.properties >/dev/null 2>&1 \
    && err "android/key.properties is tracked in git — remove it from the index" \
    || ok "android/key.properties present and untracked"
else
  echo "  ⚠ android/key.properties absent — release builds fall back to the debug key (not publishable)"
fi
if [ -f "$MANIFEST" ]; then
  grep -q 'uses-permission' "$MANIFEST" \
    && err "release manifest requests permissions (Data Safety declares none)" \
    || ok "release manifest requests no permissions"
  grep -q 'android:label="Biblia Traditio"' "$MANIFEST" \
    && ok "app display name set" || err "app display name missing"
fi
if git -C "$ROOT" ls-files | grep -qE '\.(jks|keystore)$'; then
  err "a keystore is tracked in git"
else
  ok "no keystore tracked in git"
fi

echo
if [ "$fail" = 0 ]; then echo "RELEASE CHECK PASSED"; else echo "RELEASE CHECK FAILED"; exit 1; fi

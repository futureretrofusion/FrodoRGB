#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "VERIFY FAILED: $*" >&2; exit 1; }

echo "=== FrodoRGB repository verification ==="
for f in FRFBuildConfig.h Makefile.PiStorm060 C64.cpp Display_Amiga.i main_Amiga.i FRFEasyFlash.cpp COPYING LICENSE LICENSES/FRODO-GPL-2.0.txt LICENSES/README.md NOTICE.md; do
    [ -f "$f" ] || fail "missing required file: $f"
done
VERSION="$(sed -n 's/^[[:space:]]*#define[[:space:]]\+FRF_EDITION_VERSION[[:space:]]\+"\([^"]\+\)".*/\1/p' FRFBuildConfig.h | head -n1)"
[ -n "$VERSION" ] || fail "FRF version missing"
grep -q 'FRF 2026 Frodo RTG' FRFBuildConfig.h || fail "FRF identity missing"
grep -q '^FrodoRGB:' Makefile.PiStorm060 || fail "FrodoRGB target missing"
grep -q 'FRF_RGBFAST' Makefile.PiStorm060 || fail "FRF_RGBFAST missing"
grep -q 'PC_IS_POINTER=1' Makefile.PiStorm060 || fail "direct-PC RGB path missing"
grep -q 'FRFMagic64LineBackIsSafe' Display_Amiga.i || fail "non-blocking RGB path missing"
grep -q 'native RGB swap busy; frame repeated' Display_Amiga.i || fail "non-blocking RGB swap marker missing"
grep -q 'WritePixelArray' Display_Amiga.i || fail "RTG output marker missing"

if grep -q 'FrodoAmigaCompat\.o' Makefile.PiStorm060
then
    if [ ! -f FrodoAmigaCompat.cpp ] && [ ! -f FrodoAmigaCompat.c ]
    then
        fail "Makefile links FrodoAmigaCompat.o but its source is missing"
    fi
fi

grep -q 'GNU GENERAL PUBLIC LICENSE' COPYING ||
    fail "COPYING is not recognisable as GNU GPL text"

grep -q 'Version 2, June 1991' COPYING ||
    fail "COPYING is not GPL version 2 text"

cmp -s COPYING LICENSE ||
    fail "LICENSE is not byte-identical to COPYING"

cmp -s COPYING LICENSES/FRODO-GPL-2.0.txt ||
    fail "LICENSES/FRODO-GPL-2.0.txt is not byte-identical to COPYING"

# Preserve historical upstream whitespace; reject only real merge conflicts.
CONFLICTS="$(grep -RInE --exclude-dir=.git --include='*.c' --include='*.cpp' --include='*.h' --include='*.i' '^(<<<<<<< .+|>>>>>>> .+)$' . 2>/dev/null || true)"
[ -z "$CONFLICTS" ] || { echo "$CONFLICTS"; fail "merge conflict markers found"; }

BAD_MEDIA="$(find . -type f ! -path './.git/*' \( -iname '*.crt' -o -iname '*.prg' -o -iname '*.p00' -o -iname '*.d64' -o -iname '*.d71' -o -iname '*.d81' -o -iname '*.g64' -o -iname '*.x64' -o -iname '*.t64' -o -iname '*.tap' -o -iname '*.reu' -o -iname '*.vsf' -o -iname '*.snapshot' -o -iname '*.sav' -o -iname '*.sna' -o -iname '*.rom' \) -print)"
[ -z "$BAD_MEDIA" ] || { echo "$BAD_MEDIA"; fail "ROM/media/runtime files found"; }
for r in 'Basic ROM' 'Kernal ROM' 'Char ROM' '1541 ROM'; do
    FOUND="$(find . -type f ! -path './.git/*' -name "$r" -print)"
    [ -z "$FOUND" ] || { echo "$FOUND"; fail "C64 system ROM found"; }
done

BAD_BUILD="$(find . -type f ! -path './.git/*' \( -name '*.o' -o -name '*.obj' -o -name '*.d' -o -name Frodo -o -name FrodoPC -o -name FrodoSC -o -name FrodoRGB -o -name FrodoDiagnostic \) -print)"
[ -z "$BAD_BUILD" ] || { echo "$BAD_BUILD"; fail "generated build output found"; }

BAD_ARCHIVE="$(find . -type f ! -path './.git/*' \( -iname '*.zip' -o -iname '*.7z' -o -iname '*.rar' -o -iname '*.lha' -o -iname '*.lzh' -o -iname '*.lzx' -o -iname '*.tar' -o -iname '*.tgz' -o -iname '*.tar.gz' -o -iname '*.tar.xz' \) -print)"
[ -z "$BAD_ARCHIVE" ] || { echo "$BAD_ARCHIVE"; fail "archive found"; }

LOCAL_CFG="$(find . -type f ! -path './.git/*' -iname 'frodo-fullscreen*.cfg' -print)"
[ -z "$LOCAL_CFG" ] || { echo "$LOCAL_CFG"; fail "machine-local fullscreen config found"; }

PERSONAL_HOME="${HOME%/}/"
PERSONAL="$(grep -RInF --exclude-dir=.git --exclude='verify-repo.sh' -- "$PERSONAL_HOME" . 2>/dev/null || true)"
[ -z "$PERSONAL" ] || { echo "$PERSONAL"; fail "personal home path found"; }

BAD_SECRET="$(find . -type f ! -path './.git/*' \( -name '.env' -o -name '.env.*' -o -name '*.pem' -o -name '*.p12' -o -name '*.pfx' -o -name id_rsa -o -name id_ed25519 \) -print)"
[ -z "$BAD_SECRET" ] || { echo "$BAD_SECRET"; fail "credential-like file found"; }
KEYS="$(grep -RIl --exclude-dir=.git -E 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY' . 2>/dev/null || true)"
[ -z "$KEYS" ] || { echo "$KEYS"; fail "private key material found"; }

BIG="$(find . -type f ! -path './.git/*' -size +90M -print)"
[ -z "$BIG" ] || { echo "$BIG"; fail "file over 90 MiB found"; }

echo "FRF edition: $VERSION"
echo "Verification PASS."

#!/usr/bin/env bash
set -euo pipefail

MAKEFILE="Makefile.PiStorm060"
OUTDIR="phase-sweep-binaries"
BASE_CPPFLAGS="-I/opt/amiga/m68k-amigaos/sys-include -I."

if [[ ! -f "$MAKEFILE" || ! -f VIC.cpp ]]; then
    echo "Run this script from the v1.0.13 phase-sweep source directory."
    exit 1
fi

mkdir -p "$OUTDIR"
rm -f "$OUTDIR"/Frodo-FIX46-YBIAS*

python3 tests/test_vic_fix46_source.py

for bias in 0 1 2 3; do
    echo
    echo "=== Building FIX46 Y phase bias $bias ==="
    make -f "$MAKEFILE" clean || true
    rm -f ./*.o Frodo FrodoPC FrodoSC
    make -f "$MAKEFILE" -j2 \
        CPPFLAGS="$BASE_CPPFLAGS -DFRF_VIC_PHASE_BIAS_NORMAL=$bias -DFRF_VIC_PHASE_BIAS_EXPANDED=$bias" \
        Frodo
    cp -f Frodo "$OUTDIR/Frodo-FIX46-YBIAS$bias"
    chmod +x "$OUTDIR/Frodo-FIX46-YBIAS$bias"
    echo "Built: $OUTDIR/Frodo-FIX46-YBIAS$bias"
    strings -a "$OUTDIR/Frodo-FIX46-YBIAS$bias" \
        | grep -E 'FRF_VIC_FIX46_PHASE_SWEEP|FRF 2026 Frodo RTG|1\.0\.13' \
        | head -n 8 || true
done

(
    cd "$OUTDIR"
    sha256sum Frodo-FIX46-YBIAS* > SHA256SUMS.txt
)

echo
echo "Phase sweep complete."
echo "Test in this order:"
echo "  1. Frodo-FIX46-YBIAS2"
echo "  2. Frodo-FIX46-YBIAS3 if bias 2 improves but does not remove the seam"
echo "  3. Frodo-FIX46-YBIAS1 to confirm it matches v1.0.12"
echo "  4. Frodo-FIX46-YBIAS0 as the original FIX42 phase reference"

#!/bin/sh
set -eu

MAKEFILE=${MAKEFILE:-Makefile.PiStorm060}
JOBS=${JOBS:-2}

make -f "$MAKEFILE" clean
make -f "$MAKEFILE" -j"$JOBS" Frodo

printf '%s
' "Built: $(pwd)/Frodo"

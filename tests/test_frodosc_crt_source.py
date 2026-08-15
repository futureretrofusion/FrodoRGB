#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
sc = (root / "CPUC64_SC.cpp").read_text(encoding="utf-8", errors="replace")
mk = (root / "Makefile.PiStorm060").read_text(encoding="utf-8", errors="replace")

required = [
    '#include "FRFEasyFlash.h"',
    'FRFEasyFlashReadROML',
    'FRFEasyFlashReadROMH',
    'FRFEasyFlashReadIO1',
    'FRFEasyFlashReadIO2',
    'FRFEasyFlashWriteIO1',
    'FRFEasyFlashWriteIO2',
    'FRFEasyFlashWriteUnderROML',
    'FRFEasyFlashCPUReset',
    'FRF_FRODOSC_CRT_MAPPING_1.0.15',
]
for token in required:
    if token not in sc:
        raise SystemExit('missing cycle-exact cartridge hook: ' + token)

line = next((x for x in mk.splitlines() if x.startswith('SCOBJS')), '')
for token in ('FRFEasyFlash.o', 'FrodoAmigaCompat.o'):
    if token not in line:
        raise SystemExit('FrodoSC link omits ' + token)

if 'copy FrodoSC /' in mk:
    raise SystemExit('FrodoSC target still uses AmigaDOS copy on Linux host')

print('FrodoSC cartridge/source integration checks passed')

#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
s = (root / "Display_Amiga.i").read_text(encoding="utf-8")

assert '#include "C64.h"' in s
assert '#include "VIC.h"' in s, "Display_Amiga.i must include VIC.h before calling MOS6569::ReInitColors()"
assert s.index('#include "VIC.h"') < s.index('c64->TheVIC->ReInitColors();')
assert s.count('c64->TheVIC->ReInitColors();') == 2

print("fullscreen VIC complete-type include checks passed")

#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
s = (root / "Display_Amiga.i").read_text(encoding="utf-8")

start = s.index("static void FRFToggleAslFullscreen")
end = s.index("#ifndef RECTFMT_RGB", start)
helper = s[start:end]

assert "C64 *c64" in helper, "fullscreen helper must receive the owning C64 pointer"
assert "TheC64" not in helper, "file-level helper must not reference the C64Display member directly"
assert "c64 != NULL && c64->TheVIC != NULL" in helper
assert helper.count("c64->TheVIC->ReInitColors();") == 2
assert "frf_fullscreen_mode, TheC64);" in s, "C64Display must pass its member pointer to the helper"

print("fullscreen helper C64 scope and VIC palette refresh checks passed")

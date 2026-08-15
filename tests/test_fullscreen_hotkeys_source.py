#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
s = (root / "Display_Amiga.i").read_text(encoding="utf-8")

required = [
    "FRF_FULLSCREEN_PENDING_LOCKED_RTG",
    "FRF_FULLSCREEN_PENDING_REQUESTER",
    "IEQUALIFIER_LALT",
    "IEQUALIFIER_LCOMMAND",
    "CTRL+LALT+U locked RTG detected",
    "CTRL+LALT+LAMIGA+U requester detected",
    "ULONG id = 0x502e1203",
    "PROGDIR:frodo-fullscreen.cfg",
    "locked fullscreen mode rejected because it is not RTG",
    "requester native screen rejected below 4 bitplanes",
    "FRFFullscreenNativePensActive",
    "native PAL fixed 16-colour palette installed",
    "RTG fullscreen retaining proven windowed C64 pen mapping",
    "c64->TheVIC->ReInitColors()",
    "Select FRF Frodo fullscreen mode (RTG or RGB PAL)",
]

for token in required:
    assert token in s, f"missing fullscreen feature token: {token}"

# Direct RTG must use the proven fixed mode/legacy override only.
assert "frodo-fullscreen-x1.cfg" not in s
assert "frodo-fullscreen-x2.cfg" not in s
assert "FRFSaveLockedFullscreenRTGMode" not in s

# LShift must no longer select the requester.
key = s[s.index("case IDCMP_RAWKEY:"):s.index("switch (code)", s.index("case IDCMP_RAWKEY:"))]
assert "IEQUALIFIER_LCOMMAND" in key
assert "IEQUALIFIER_LSHIFT" not in key

# The direct path must not silently open the requester.
toggle = s[s.index("static void FRFToggleAslFullscreen"):s.index("#ifndef RECTFMT_RGB")]
assert "scr = FRFOpenLockedFullscreenScreen();" in toggle
assert "scr = FRFAskAndOpenScreen();" in toggle

# Pen changes are native-only and must reinitialise VIC colours.
native = toggle[toggle.index("FRFFullscreenNativePensActive = 0;"):toggle.index("FRFSetFullscreenCenteredViewport(scr);")]
assert "if (!FRFScreenIsCyberGfxMode(scr))" in native
assert "FRFInstallNativeFixed16Palette(scr, pens)" in native
assert "c64->TheVIC->ReInitColors();" in native
assert "else" in native

print("fixed RTG mode, native-only palette, and LAmiga requester checks passed")

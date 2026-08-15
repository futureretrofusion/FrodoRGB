#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
main = (root / "main_Amiga.i").read_text()
display = (root / "Display_Amiga.i").read_text()
config = (root / "FRFBuildConfig.h").read_text()

required_main = [
    "int FrodoFRFStartupScreenModeRequester = 0;",
    "int FrodoFRFNativePlanar16 = 0;",
    'FrodoFRFStartsNoCase(p, "SCREENMODE")',
    'FrodoFRFStartsNoCase(p, "SCREENMODE=")',
    'FrodoFRFStartsNoCase(p, "FULLSCREEN=")',
    'FrodoFRFStartsNoCase(p, "--fullscreen-requester")',
    "FrodoFRFStartupScreenModeRequester = 1;",
    "FrodoFRFStartupScreenModeRequester)\n                frf_start_emulator = 1;",
]
required_display = [
    "extern int FrodoFRFStartupScreenModeRequester;",
    "extern int FrodoFRFNativePlanar16;",
    "FRFFullscreenPendingMode = FRF_FULLSCREEN_PENDING_REQUESTER;",
    'FrodoFRFTrace("startup screenmode requester queued")',
    "if (!FrodoFRFNativePlanar16 ||",
]
for token in required_main:
    assert token in main, token
for token in required_display:
    assert token in display, token
assert 'FRF_EDITION_VERSION "1.0.26"' in config
print("startup screenmode requester and optional planar16 checks passed")

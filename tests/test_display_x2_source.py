#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
main = (root / "main_Amiga.i").read_text()
display = (root / "Display_Amiga.i").read_text()
vic = (root / "VIC.cpp").read_text()

required_main = [
    "int FrodoFRFDisplayScale = 1;",
    "int FrodoFRFPresentVSync = 0;",
    "FrodoFRFParseDisplayRawArgs();",
    'FrodoFRFStartsNoCase(p, "X2")',
    'FrodoFRFStartsNoCase(p, "SCALE=")',
    'FrodoFRFStartsNoCase(p, "--scale")',
    'FrodoFRFStartsNoCase(p, "VSYNC=")',
    'FrodoFRFStartsNoCase(p, "PRESENT=")',
]
required_display = [
    "static LONG FRFOutputWidth(void)",
    "static LONG FRFOutputHeight(void)",
    "static void FRFScaleIndexed2x",
    "static void FRFConvertRGBFrame",
    "FRFScaledBuf8",
    "WaitBOVP(&the_screen->ViewPort)",
    "WA_InnerWidth, output_w",
    "WA_InnerHeight, output_h + 16",
    "AllocBitMap(output_w, 1, 8, 0, NULL)",
]
for text in required_main:
    assert text in main, text
for text in required_display:
    assert text in display, text
assert "FRF_VIC_FIX46_PHASE_SWEEP" in vic
assert "FIX43" not in vic and "FIX44" not in vic
print("X2 scaling/VSYNC source checks passed; VIC phase code unchanged")

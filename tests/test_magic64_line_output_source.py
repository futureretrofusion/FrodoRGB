#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
display_h = (root / "Display.h").read_text(encoding="utf-8", errors="replace")
display = (root / "Display_Amiga.i").read_text(encoding="utf-8", errors="replace")
vic_sc = (root / "VIC_SC.cpp").read_text(encoding="utf-8", errors="replace")
vic_fast = (root / "VIC.cpp").read_text(encoding="utf-8", errors="replace")
config = (root / "FRFBuildConfig.h").read_text(encoding="utf-8", errors="replace")

required_display = [
    "FRF_MAGIC64_LINE_OUTPUT_1.0.24",
    "WritePixelLine8(&FRFMagic64LineRastPort",
    "AllocScreenBuffer(scr, NULL, SB_SCREEN_BITMAP)",
    "AllocScreenBuffer(scr, NULL, SB_COPY_BITMAP)",
    "ChangeScreenBuffer(scr",
    "FreeScreenBuffer(scr",
    "CreateMsgPort()",
    "dbi_SafeMessage.mn_ReplyPort",
    "dbi_UserData1",
    "FRFMagic64LineBackIsSafe",
    "line_number < first_line",
    "line_number >= first_line + line_count",
    "(UWORD)FRFFullscreenViewX",
    "line_number - first_line",
    "line + 32",
    "320,",
    "if (FRFMagic64LineEndFrame(the_screen))",
]
for token in required_display:
    assert token in display, token

assert "void UpdateScanline(uint8 *line, int line_number);" in display_h
assert "the_display->UpdateScanline(chunky_line_start" in vic_sc
assert vic_sc.index("the_display->UpdateScanline(chunky_line_start") < vic_sc.index("chunky_line_start += xmod;")
assert "UpdateScanline" not in vic_fast
assert 'FRF_EDITION_VERSION "1.0.26"' in config
assert 'FRF_MAGIC64_LINE_OUTPUT_MARKER "FRF_RGBFAST_LINE_OUTPUT_1.0.26"' in config

# The line backend is deliberately restricted to the native PAL320 screen.
for token in [
    "FrodoFRFNativePAL320",
    "FRFOutputScale() == 1",
    "!FRFScreenIsCyberGfxMode(scr)",
    "scr->RastPort.BitMap->Depth == 4",
]:
    assert token in display, token

print("MagiC64-style scanline conversion and safe double-buffer source checks passed")

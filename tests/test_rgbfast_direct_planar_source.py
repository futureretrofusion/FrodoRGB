#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
display = (root / "Display_Amiga.i").read_text(encoding="utf-8", errors="replace")
makefile = (root / "Makefile.PiStorm060").read_text(encoding="utf-8", errors="replace")
config = (root / "FRFBuildConfig.h").read_text(encoding="utf-8", errors="replace")

required = [
    "FRF_RGBFAST_DIRECT_PLANAR_1.0.27",
    "FRFMagic64LineCanWriteDirect",
    "FRFConvertPAL320LineDirect(line + 32",
    "FRFPlanar16BuildLUT();",
    "FRFMagic64LineDirectPlanarLines++",
    "FRFMagic64LineAPIFallbackLines++",
    "WritePixelLine8(&FRFMagic64LineRastPort",
    "FRFMagic64LineBuffers[FRFMagic64LineBack]->sb_BitMap",
]
for token in required:
    assert token in display, token

assert "-DFRF_RGBFAST_DIRECT_PLANAR=1" in makefile
assert 'FRF_EDITION_VERSION "1.0.27"' in config
assert 'FRF_MAGIC64_LINE_OUTPUT_MARKER "FRF_RGBFAST_DIRECT_PLANAR_1.0.27"' in config

# Direct planar conversion must be FrodoRGB-only and retain the API fallback.
assert "#if defined(FRF_RGBFAST) && defined(FRF_RGBFAST_DIRECT_PLANAR)" in display
assert display.count("WritePixelLine8(&FRFMagic64LineRastPort") >= 2
assert "FRFMagic64LineBackIsSafe" in display
assert "ChangeScreenBuffer(scr" in display

print("FrodoRGB v1.0.27 direct planar raster source checks passed")

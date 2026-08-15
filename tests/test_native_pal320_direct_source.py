from pathlib import Path

root = Path(__file__).resolve().parents[1]
d = (root / "Display_Amiga.i").read_text(errors="replace")
m = (root / "main_Amiga.i").read_text(errors="replace")
c = (root / "FRFBuildConfig.h").read_text(errors="replace")

required_display = [
    "FRF_NATIVE_PAL320_DIRECT_1.0.23",
    "FRFBlitNativePAL320Direct",
    "FRFConvertPAL320LineDirect",
    "src + (y + 8) * DISPLAY_X + 32",
    "rp->BitMap->Depth != 4",
    "*d0++ = p0",
    "FRFPresentedWidthForScreen",
    "FRFRequesterWidth",
]
for item in required_display:
    assert item in d, item
for item in ["PAL320", "RGB320", "DISPLAYEVERY=", "NODISPLAY", "FrodoFRFNativePAL320"]:
    assert item in m, item
assert 'FRF_EDITION_VERSION "1.0.26"' in c
print("true PAL320 direct planar and display diagnostic source checks passed")

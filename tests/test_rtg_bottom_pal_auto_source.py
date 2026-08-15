#!/usr/bin/env python3
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
main = (root / "main_Amiga.i").read_text(encoding="utf-8")
display = (root / "Display_Amiga.i").read_text(encoding="utf-8")
make = (root / "Makefile.PiStorm060").read_text(encoding="utf-8")

marker = "FRF_RTG_BOTTOM_CLEAN_PAL_AUTO_1.0.29"
assert marker in main and marker in display
assert "int FrodoFRFStartupHardcodedPAL320 = 0;" in main
rgb_start = main.index("#if defined(FRF_RGBFAST) || defined(FRF_RGBEXACT)")
rgb_end = main.index("#endif", rgb_start)
rgb_block = main[rgb_start:rgb_end]
assert "FrodoFRFStartupHardcodedPAL320 = 1;" not in rgb_block
assert "FRF_CLI_OUTPUT_SELECTOR_1.0.30" in rgb_block
assert "FrodoFRFStartupScreenModeRequester" in main  # explicit requester retained
assert "FRF_FULLSCREEN_PENDING_HARDCODED_PAL320" in display
assert "FRFOpenHardcodedPAL320Screen" in display
for token in ["0x00021000UL", "SA_Width, 320", "SA_Height, 256", "SA_Depth, 4"]:
    assert token in display, token
assert "startup hardcoded PAL320 failed; requester fallback" in display
assert "memset(chunky_buf, 0, DISPLAY_X * DISPLAY_Y)" in display
assert "memset(FRFRTGBuf24, 0, need)" in display
assert "draw_led_bar();" in display

for target, required in [
    ("FrodoRGB", ["-DFRF_RGBFAST=1", "-DFRF_RGBFAST_DIRECT_PLANAR=1"]),
    ("FrodoRGBExact", ["-DFRF_RGBEXACT=1", "-DFRF_SC_NATIVE_DIRECT_PLANAR=1"]),
]:
    p = subprocess.run(
        ["make", "-B", "-f", "Makefile.PiStorm060", "-n", target],
        cwd=root, check=True, text=True, capture_output=True,
    )
    for token in required:
        assert token in p.stdout, (target, token)

print("RTG bottom-strip initialisation and hardcoded PAL320 startup checks passed")

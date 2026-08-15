#!/usr/bin/env python3
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
makefile = (root / "Makefile.PiStorm060").read_text(encoding="utf-8", errors="replace")
display = (root / "Display_Amiga.i").read_text(encoding="utf-8", errors="replace")
main = (root / "main_Amiga.i").read_text(encoding="utf-8", errors="replace")
config = (root / "FRFBuildConfig.h").read_text(encoding="utf-8", errors="replace")

for token in [
    "FrodoRGBExact: $(RGBEXACTOBJS)",
    "RGBEXACTFLAGS = -DFRODO_SC -DFRF_RGBEXACT=1 -DFRF_SC_NATIVE_DIRECT_PLANAR=1",
    "$(filter-out main.o Display.o,$(SCOBJS))",
    "main_RGBExact.o:",
    "Display_RGBExact.o:",
    "clean-rgbexact:",
]:
    assert token in makefile, token

assert "FrodoRGB: $(RGBOBJS)" in makefile
assert "-DFRF_RGBFAST=1" in makefile
assert "-DFRF_RGBFAST_DIRECT_PLANAR=1" in makefile
assert "-DPC_IS_POINTER=1" in makefile

assert "defined(FRF_SC_NATIVE_DIRECT_PLANAR) /* FRF_RGBEXACT_NATIVE_1.0.28 */" in display
assert "const int first_line = 8;" in display
assert "const int line_count = 256;" in display
assert "const int destination_y = 0;" in display
assert "FRFConvertPAL320LineDirect(line + 32" in display
assert "FRFMagic64LineBackIsSafe" in display
assert "ChangeScreenBuffer(scr" in display

assert main.count("#if defined(FRF_RGBFAST) || defined(FRF_RGBEXACT)") >= 2
assert "FrodoFRFStartupScreenModeRequester = 1;" in main
assert "FrodoFRFNativePAL320 = 1;" in main
assert "FrodoFRFPresentVSync = 0;" in main
assert "ThePrefs.Emul1541Proc = false;" in main
assert 'FRF_EDITION_VERSION "1.0.27"' in config

result = subprocess.run(
    ["make", "-B", "-f", "Makefile.PiStorm060", "-n", "FrodoRGBExact"],
    cwd=root,
    check=True,
    text=True,
    capture_output=True,
)
commands = result.stdout
for token in [
    "CPUC64_SC.cpp",
    "VIC_SC.cpp",
    "CIA_SC.cpp",
    "CPU1541_SC.cpp",
    "-DFRODO_SC",
    "-DFRF_RGBEXACT=1",
    "-DFRF_SC_NATIVE_DIRECT_PLANAR=1",
    "-o FrodoRGBExact",
]:
    assert token in commands, token

assert "VIC_RGB.cpp" not in commands
assert "CPUC64_PC.cpp" not in commands
print("FrodoRGBExact cycle-exact core/native direct-planar source checks passed")

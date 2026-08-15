from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
makefile = (root / "Makefile.PiStorm060").read_text()
vic = (root / "VIC_RGB.cpp").read_text()
display = (root / "Display_Amiga.i").read_text()
main = (root / "main_Amiga.i").read_text()
config = (root / "FRFBuildConfig.h").read_text()

assert "FrodoRGB: $(RGBOBJS)" in makefile
assert "-DFRF_RGBFAST=1" in makefile
assert "-DPRECISE_CPU_CYCLES=1" in makefile
assert "-DPRECISE_CIA_CYCLES=1" in makefile
assert "CPUC64_RGB.o" in makefile and "CPUC64_PC.cpp" in makefile
assert "VIC_RGB.o" in makefile and "VIC_RGB.cpp" in makefile
assert "main_RGB.o" in makefile and "Display_RGB.o" in makefile

assert "FRF_RGBFAST_VIC_1.0.26" in vic
assert "FRF_VIC_FIX44" in vic
assert "frf_vic_arm_same_raster_handover" in vic
assert "frf_vic_flush_late_sprite_line" in vic
assert "const unsigned FIRST_DISP_LINE = 0x33;" in vic
assert "const unsigned LAST_DISP_LINE = 0xfa;" in vic
assert "the_display->UpdateScanline" in vic
assert vic.index("frf_vic_flush_late_sprite_line();") < vic.index("int cycles_left = ThePrefs.NormalCycles")

assert "#ifdef FRF_RGBFAST" in display
assert "const int first_line = 0;" in display
assert "const int line_count = 200;" in display
assert "const int destination_y = 28;" in display
assert "WritePixelLine8" in display
assert "ChangeScreenBuffer" in display
assert "AllocScreenBuffer" in display
assert "FRFMagic64LineEndFrame" in display

assert "ThePrefs.SkipFrames = 1;" in main
assert "ThePrefs.LimitSpeed = true;" in main
assert "ThePrefs.Emul1541Proc = false;" in main
assert "FrodoFRFPresentVSync = 0;" in main
assert "FRF_CLI_OUTPUT_SELECTOR_1.0.30" in main

assert 'FRF_EDITION_VERSION "1.0.27"' in config
assert 'FRF_RGBFAST_DIRECT_PLANAR_1.0.27' in config

for name, text in {
    "VIC_RGB.cpp": vic,
    "Display_Amiga.i": display,
    "main_Amiga.i": main,
}.items():
    assert "\\nstatic" not in text, f"literal escaped newline corruption in {name}"
    assert "nstatic" not in text, f"corrupt nstatic token in {name}"

# The build recipe must resolve to the dedicated fast/precise line core, not SC.
result = subprocess.run(
    ["make", "-B", "-f", "Makefile.PiStorm060", "-n", "FrodoRGB"],
    cwd=root,
    check=True,
    text=True,
    capture_output=True,
)
commands = result.stdout
assert "CPUC64_PC.cpp" in commands
assert "VIC_RGB.cpp" in commands
assert "-DFRF_RGBFAST=1" in commands
assert "-DFRODO_SC" not in commands
assert "-o FrodoRGB" in commands

# Geometry sanity: 0x33 through 0xfa is exactly 200 PAL raster lines.
assert 0xFA - 0x33 + 1 == 200
assert 28 + 200 + 28 == 256

print("FrodoRGB fast-core, FIX44, 320x200 native line-output checks passed")

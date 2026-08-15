#!/usr/bin/env python3
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
main = (root / "main_Amiga.i").read_text(encoding="utf-8")
display = (root / "Display_Amiga.i").read_text(encoding="utf-8")

marker = "FRF_CLI_OUTPUT_SELECTOR_1.0.30"
assert marker in main and marker in display
assert "int FrodoFRFStartupLockedRTG = 0;" in main
assert "FrodoFRFSetStartupOutputMode" in main
assert "FrodoFRFSetStartupOutputValue" in main
for value in ["RTG", "RGB", "ASK", "WINDOWED", "WORKBENCH"]:
    assert 'FrodoFRFEqNoCase(value, "' + value + '")' in main
for token in [
    'FrodoFRFStartsNoCase(p, "FULLSCREEN=")',
    'FrodoFRFStartsNoCase(p, "WINDOWED")',
    'FrodoFRFStartsNoCase(p, "--windowed")',
    'FrodoFRFStartsNoCase(p, "--fullscreen-rtg")',
    'FrodoFRFStartsNoCase(p, "--fullscreen-rgb")',
]:
    assert token in main, token

rgb_start = main.index("#if defined(FRF_RGBFAST) || defined(FRF_RGBEXACT)")
rgb_end = main.index("#endif", rgb_start)
rgb_block = main[rgb_start:rgb_end]
assert "FrodoFRFStartupHardcodedPAL320 = 1;" not in rgb_block
assert "FrodoFRFNativePAL320 = 1;" not in rgb_block
assert "no output option means a Workbench window" in rgb_block

assert "extern int FrodoFRFStartupLockedRTG" in display
assert "FRF_FULLSCREEN_PENDING_LOCKED_RTG" in display
assert 'FrodoFRFTrace("startup locked RTG queued")' in display
assert "FRF_FULLSCREEN_PENDING_HARDCODED_PAL320" in display
assert "FRF_FULLSCREEN_PENDING_REQUESTER" in display

for target, required in [
    ("FrodoRGB", ["-DFRF_RGBFAST=1", "-DFRF_RGBFAST_DIRECT_PLANAR=1"]),
    ("FrodoRGBExact", ["-DFRF_RGBEXACT=1", "-DFRF_SC_NATIVE_DIRECT_PLANAR=1"]),
]:
    proc = subprocess.run(
        ["make", "-B", "-f", "Makefile.PiStorm060", "-n", target],
        cwd=root, check=True, text=True, capture_output=True,
    )
    for required_token in required:
        assert required_token in proc.stdout, (target, required_token)

print("CLI window/RTG/RGB/requester output-selection source checks passed")

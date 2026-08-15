#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
make = (root / "Makefile.PiStorm060").read_text()
display = (root / "Display_Amiga.i").read_text()
main = (root / "main_Amiga.i").read_text()

assert "RGBFLAGS =" in make
assert "-DFRF_RGBFAST=1" in make
assert "-DFRF_RGBFAST_DIRECT_PLANAR=1" in make
assert "-DPC_IS_POINTER=1" in make
assert "PRECISE_CPU_CYCLES=1" not in make.split("RGBFLAGS =", 1)[1].splitlines()[0]
assert "PRECISE_CIA_CYCLES=1" not in make.split("RGBFLAGS =", 1)[1].splitlines()[0]
assert "FRFMagic64LineBackIsSafe" in display
assert "FRFMagic64LineWaitBackSafe" not in display
assert "while (!FRFMagic64LineSafe" not in display
assert "native RGB swap busy; frame repeated" in display
live = display.split("static int FRFMagic64LineEndFrame", 1)[1].split("static void FRFBlitC64Frame", 1)[0]
assert "while (!ChangeScreenBuffer(scr" not in live
assert "Preserve a command-line NODISPLAY request" in main

print("FrodoRGB direct-PC, line-CIA and non-blocking presentation checks passed")

#!/usr/bin/env python3
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
gxx = shutil.which("g++") or shutil.which("c++")
if not gxx:
    raise SystemExit("host C++ compiler not found")

with tempfile.TemporaryDirectory(prefix="frodo-rgbfast-syntax-") as td:
    dst = Path(td) / "src"
    shutil.copytree(
        root,
        dst,
        ignore=shutil.ignore_patterns("dirent.h", "*.o", "Frodo", "FrodoPC", "FrodoSC", "FrodoRGB", "__pycache__"),
    )
    flags = [
        gxx,
        "-std=gnu++98",
        "-DFRF_RGBFAST=1",
        "-DPC_IS_POINTER=1",
        "-I.",
        "-fsyntax-only",
    ]
    for source in ["VIC_RGB.cpp", "CPUC64_PC.cpp", "CIA.cpp", "CPU1541.cpp"]:
        subprocess.run(flags + [source], cwd=dst, check=True)

print("FrodoRGB VIC/CPU/CIA C++98 host syntax checks passed")

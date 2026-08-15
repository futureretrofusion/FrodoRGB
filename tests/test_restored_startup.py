#!/usr/bin/env python3
"""Static regression checks for the target-confirmed Amiga startup path."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
main = (root / "main_Amiga.i").read_text()
c64 = (root / "C64_Amiga.i").read_text()
mk1 = (root / "Makefile.PiStorm060").read_text()
mk2 = (root / "Makefile.Amiga").read_text()

checks = {
    "captures GetArgStr": "FrodoFRFCaptureRawArgs();" in main and "GetArgStr()" in main,
    "does not dereference argv": "(void)argv;" in main and "argv[" not in main,
    "no generic parser remains": "FRFStartupArgs" not in main + c64 + mk1 + mk2,
    "CRT parser restored": '"CRT="' in main and '"CART="' in main,
    "two CRT loads restored": main.count("FRFEasyFlashLoadCRT(FrodoStartupCartPath)") == 2,
    "CRT boot install restored": "FRFEasyFlashInstallBoot" in main,
    "PRG temp drive copy restored": 'fopen("T:0", "wb")' in main,
    "PRG drive 8 restored": "DRVTYPE_DIR" in main and '"LOAD\\\"0\\\",8"' in main,
    "PRG staged autorun restored": "first_delay = 15000" in main and "load_delay = 24000" in main,
    "PRG emulation-loop hook restored": "FrodoFRFMaybeInjectStartupPRG(this);" in c64,
    "save-state aliases retained": '"SNAPSHOT="' in main and '"SAVESTATE="' in main,
}

failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(("PASS" if ok else "FAIL") + ": " + name)
if failed:
    raise SystemExit("startup restoration checks failed: " + ", ".join(failed))

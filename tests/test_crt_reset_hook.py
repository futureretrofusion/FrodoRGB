from pathlib import Path

root = Path(__file__).resolve().parents[1]
cpu = (root / "CPUC64.cpp").read_text()
flash = (root / "FRFEasyFlash.cpp").read_text()
header = (root / "FRFEasyFlash.h").read_text()

reset_start = cpu.index("void MOS6510::Reset(void)")
reset_end = cpu.index("/*\n *  Illegal opcode encountered", reset_start)
reset = cpu[reset_start:reset_end]

required = [
    "CRT_FIX40_INSERTED_CART_RESET",
    "if (FRFEasyFlashIsLoaded())",
    "FRFEasyFlashCPUReset(ram, basic_rom, kernal_rom);",
]
missing = [item for item in required if item not in reset]
if missing:
    raise SystemExit("missing CRT reset restoration:\n" + "\n".join(missing))

if reset.index("FRFEasyFlashCPUReset") > reset.index("// Clear all interrupt lines"):
    raise SystemExit("cartridge reset restoration occurs too late")

assert "void FRFEasyFlashCPUReset" in flash
assert "void FRFEasyFlashCPUReset" in header
print("CRT reset hook source checks passed")

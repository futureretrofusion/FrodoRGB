from pathlib import Path

root = Path(__file__).resolve().parents[1]
s = (root / "FRFEasyFlash.cpp").read_text()

required = [
    "CRT_FIX37_NORMAL_CRT_HELPER",
    "if (cart_type == 0)",
    "ef_mapper_type = 1;",
    "ef_crt_exrom = hdr[0x18] & 1;",
    "ef_crt_game = hdr[0x19] & 1;",
    "CRT_FIX37: normal type-0 cartridge loaded",
    "if (ef_mapper_type == 1)\n                return ef_normal_8k || ef_normal_16k || ef_normal_ultimax;",
    "if (ef_mapper_type != 2)\n                return open_bus;",
    "CRT_FIX41: normal/Magic ROML bank=%u installed at $8000",
    "if (cart_type == 19)",
    "ef_mapper_type = 3;",
    "CRT_FIX41: Magic Desk type 19 loaded ROML banks=%u",
    "ef_magicdesk_disabled = (value & 0x80) ? 1 : 0;",
    "ef_default_mode = 0;",
    "CRT_FIX41C_MAGICDESK_NO_ROMH",
    "if (ef_mapper_type == 3)\n                return 0;",
]

missing = [item for item in required if item not in s]
if missing:
    raise SystemExit("missing normal CRT restoration markers:\n" + "\n".join(missing))

# Ensure the known-good EasyFlash branch remains present and separate.
assert "if (cart_type != 32)" in s
assert "EasyFlash CRT loaded" in s
print("normal and Magic Desk CRT source restoration checks passed")

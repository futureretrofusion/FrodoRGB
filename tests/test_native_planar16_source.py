#!/usr/bin/env python3
from pathlib import Path
import random

root = Path(__file__).resolve().parents[1]
s = (root / "Display_Amiga.i").read_text(encoding="utf-8")

required = [
    "FRF_NATIVE_PLANAR16_FASTPATH_1.0.21_EXPERIMENTAL",
    "FRFInstallNativeFixed16Palette",
    "LoadRGB32(&scr->ViewPort, table)",
    "pens[i] = i",
    "FRF_PLANAR16_PLANES 4",
    "FRF_PLANAR16_BUFFERS 2",
    "FRFPlanar16PairLUT[4][256]",
    "FRFPlanar16DirtyLine[DISPLAY_Y]",
    "memcmp(now, old, DISPLAY_X)",
    "FRFPlanar16CopyLine(previous, current, line)",
    "WaitBlit()",
    "BltBitMapRastPort(current",
    "rp->BitMap->Depth == 4",
    "FRFOutputScale() != 1",
    "if (!FrodoFRFNativePlanar16 ||",
    "if (FRFBlitNativePlanar16(rp, x, y, src))",
    "WritePixelArray8(rp",
]
for token in required:
    assert token in s, f"missing native planar16 token: {token}"

# Fixed native indexes must not be returned through ReleasePen().
switch_start = s.index("static void FRFSwitchC64Pens(struct Screen *scr, LONG *pens)\n{")
switch_end = s.index("static int FRFInstallNativeFixed16Palette", switch_start)
switch = s[switch_start:switch_end]
assert "if (!FRFC64PensAreFixedNative)" in switch

# Verify the four-pair LUT design for every solid colour and random 8-pixel rows.
lut = [[0] * 256 for _ in range(4)]
for pair_pos in range(4):
    bit0 = 7 - pair_pos * 2
    bit1 = bit0 - 1
    for value in range(256):
        c0 = (value >> 4) & 15
        c1 = value & 15
        packed = 0
        for plane in range(4):
            out = 0
            if c0 & (1 << plane):
                out |= 1 << bit0
            if c1 & (1 << plane):
                out |= 1 << bit1
            packed |= out << (24 - plane * 8)
        lut[pair_pos][value] = packed

def c2p8(pixels):
    packed = 0
    for pair_pos in range(4):
        a = pixels[pair_pos * 2] & 15
        b = pixels[pair_pos * 2 + 1] & 15
        packed |= lut[pair_pos][(a << 4) | b]
    return [(packed >> shift) & 0xff for shift in (24, 16, 8, 0)]

def p2c8(planes):
    out = []
    for bit in range(7, -1, -1):
        colour = 0
        for plane in range(4):
            colour |= ((planes[plane] >> bit) & 1) << plane
        out.append(colour)
    return out

for colour in range(16):
    row = [colour] * 8
    assert p2c8(c2p8(row)) == row

rng = random.Random(0xF20D0120)
for _ in range(5000):
    row = [rng.randrange(16) for _ in range(8)]
    assert p2c8(c2p8(row)) == row

print("optional native planar16 experiment checks passed")

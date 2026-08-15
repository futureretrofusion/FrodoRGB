from pathlib import Path

root = Path(__file__).resolve().parents[1]
d = (root / "Display_Amiga.i").read_text(errors="replace")

# Literal escaped newlines outside strings were accidentally inserted in v1.0.22.
assert r"/*\n * FRF_NATIVE_PAL320_DIRECT" not in d
assert r"}\n\nstatic int FRFCanUseNativePlanar16" not in d
assert "nstatic int FRFCanUseNativePlanar16" not in d
assert "FRF_NATIVE_PAL320_DIRECT_1.0.23" in d
assert "static int FRFCanUseNativePAL320Direct(struct RastPort *rp)\n{" in d
assert "static int FRFBlitNativePAL320Direct(struct RastPort *rp, const UBYTE *src)\n{" in d
print("Display_Amiga.i generated-newline integrity checks passed")

# FRF v1.0.24 MagiC64-style native RGB line output

This test revision replaces the completed-frame native PAL320 presentation path
for FrodoSC with a scanline pipeline recovered from static analysis of the
uploaded MagiC64 1.81 executable.

## Recovered MagiC64 native path

The MagiC64 binary performs the native output work while the VIC raster is
being produced:

1. A completed chunky raster is held in a one-line buffer.
2. `graphics.library/WritePixelLine8()` converts that raster into the hidden
   four-bitplane screen buffer.
3. At the frame boundary, `intuition.library/ChangeScreenBuffer()` swaps the
   two native buffers.
4. If the swap is temporarily refused, MagiC64 waits one video field and
   retries.
5. On systems without the V39 screen-buffer path, it substitutes the alternate
   BitMap and calls `MakeScreen()`/`RethinkDisplay()`.

MagiC64 does not perform one complete chunky-to-planar conversion followed by a
full-screen blit for this path.

## FrodoSC v1.0.24 implementation

- `VIC_SC.cpp` sends each completed raster to `C64Display::UpdateScanline()`.
- The central 320 pixels of lines 8 through 263 are sent to
  `WritePixelLine8()`.
- Two Intuition `ScreenBuffer` objects are used.
- A safe-message port prevents the old front buffer from being modified before
  Intuition releases it.
- `C64Display::Update()` swaps the buffers at VBlank and skips the previous
  full-frame native conversion/copy.
- RTG, X2, windowed output and the fast Frodo core keep their existing paths.

## Build

```sh
make -f Makefile.PiStorm060 test-magic64-line
make -f Makefile.PiStorm060 clean
rm -f *.o Frodo FrodoPC FrodoSC
make -f Makefile.PiStorm060 -j2 FrodoSC
```

## Run

```text
FrodoSC CRT="Work:Carts/ssf2t.crt" X1 PAL320 SCREENMODE NOVSYNC
```

Select a native, non-interlaced PAL 320x256 screen with exactly four
bitplanes.

This is a test revision. Runtime performance and screen-buffer behaviour must
be confirmed on the target Amiga/PiStorm.

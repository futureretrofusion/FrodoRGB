# MagiC64 1.81 native RGB binary analysis

Analysed file: user-supplied AmigaOS `LoadSeg()` executable

- Version string: `$VER: MagiC64 1.81 (28.12.98)`
- Size: 252,564 bytes
- SHA-256: `0a28f70c3ff5ce6a11b96081d7cf46c1d7b752344aad4405f89106a40dcc6049`
- Format: 17 Amiga HUNK segments

The public executable is stripped and contains no source tree, so these results
come from HUNK relocation parsing and 68000 disassembly.

## Confirmed native display behaviour

### Per-raster conversion

At virtual address `0x136768`, MagiC64 calls graphics.library LVO `-$306`,
`WritePixelLine8()`.

The call is prepared with:

- destination RastPort in `A0`;
- temporary RastPort in `A1`;
- chunky line buffer near `0x140484` in `A2`;
- dynamic raster width in `D2`.

The call occurs once for each accepted raster. Narrow one-line border areas use
`WritePixelArray8()` separately at `0x1367ea` and `0x13681e`.

### Two custom native bitmaps

MagiC64 allocates `0x20800` bytes of CHIP memory and divides it into two
`0x10400`-byte display buffers. Each bitmap has four planes separated by
`0x4100` bytes. It initializes two BitMap structures and associates both with
Intuition `ScreenBuffer` handles through `AllocScreenBuffer()`.

### Frame-boundary swap

At `0x1303a4`, MagiC64 calls intuition.library LVO `-$30c`,
`ChangeScreenBuffer()`. If the call fails, it calls `WaitTOF()` and retries.

On the older fallback path, it changes the BitMap used by the screen and calls
`MakeScreen()` followed by `RethinkDisplay()`.

### Separate RTG path

CyberGraphX bitmap locking/direct-memory output is handled separately. The
native planar path is not the RTG path.

## Consequence for Frodo

The earlier FRF experiments still produced a complete chunky frame, converted
or compared it after the frame, and then copied it to the native screen.
MagiC64 instead overlaps native conversion with VIC raster production and has
only a screen-buffer exchange at the frame boundary.

That recovered architecture is the basis of `FRF_MAGIC64_LINE_OUTPUT_1.0.24`.

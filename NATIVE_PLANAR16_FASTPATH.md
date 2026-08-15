# Native 16-colour planar engine test

Version 1.0.20 adds an Amiga-native output path for X1 fullscreen on an exact
4-bitplane screen.

## Why the old path was slow

The previous native RGB PAL path called `WritePixelArray8()` for the complete
384x272 frame. That is a general chunky-to-planar conversion intended to handle
many screen layouts and depths. On a classic planar screen it repeats expensive
conversion and pen mapping work every frame.

## Fast path

When all of these conditions are true:

- requester-selected native screen;
- non-CyberGraphX bitmap;
- X1 output;
- exactly four bitplanes;

Frodo now uses:

1. A fixed C64 palette loaded into colour registers 0 through 15.
2. Direct C64 colour indexes in `chunky_buf`.
3. Four 256-entry pair-position lookup tables to convert eight chunky pixels
   into four planar bytes.
4. Two private 4-bitplane staging bitmaps.
5. Dirty-line comparison so unchanged scanlines reuse prior planar data.
6. The Amiga hardware blitter to copy the completed 384x272 planar image to
   the selected PAL screen.
7. Overlap between CPU conversion and the preceding asynchronous blit.

The generic indexed path remains available for other native depths and X2.
The RTG true-colour and X2 paths are unchanged.

## Recommended screen

Choose an X1 PAL mode with:

- depth exactly 4;
- width at least 384;
- height at least 272.

PAL overscan or an interlaced PAL mode may be needed to provide 384x272.

## Build

```sh
make -f Makefile.PiStorm060 test-native-planar16
make -f Makefile.PiStorm060 clean
rm -f *.o Frodo FrodoPC FrodoSC
make -f Makefile.PiStorm060 -j2 FrodoSC
```

## Test

Start with X1 and no host VSync:

```text
FrodoSC CRT="Work:Carts/ssf2t.crt" X1 NOVSYNC
```

Press `Ctrl+LAlt+LAmiga+U` and select a 4-bitplane PAL mode. Compare speed with
the v1.0.19 native output. X2 RTG behaviour should remain unchanged.

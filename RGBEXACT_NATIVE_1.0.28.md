# FrodoRGBExact cycle-exact native test — 1.0.28 experiment

This adds a separate `FrodoRGBExact` executable. The working `FrodoRGB`
executable and its source path are retained.

`FrodoRGBExact` uses:

- `CPUC64_SC.cpp`, `VIC_SC.cpp` and `CIA_SC.cpp` cycle-by-cycle emulation;
- the integrated FrodoSC cartridge/reset support;
- high-level IEC, so the second cycle-emulated 1541 CPU stays disabled;
- the v1.0.27 direct four-plane line writer;
- the shared non-blocking ScreenBuffer swap;
- PAL320 X1, 16 colours and the automatic screenmode requester;
- FrodoSC's full 320x256 crop, preserving border and raster behaviour.

Build only this target with:

    make -f Makefile.PiStorm060 clean-rgbexact
    make -f Makefile.PiStorm060 -j2 FrodoRGBExact

Run:

    FrodoRGBExact CRT="Work:Carts/ssf2t.crt"

The existing `FrodoRGB` remains the full-speed fallback.

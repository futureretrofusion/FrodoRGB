# FrodoRGB native PAL fast engine — v1.0.26

`FrodoRGB` is a separate performance-oriented executable for classic Amiga
RGB output. It does not weaken or replace `FrodoSC`.

## Architecture

- instruction/scanline CPU and VIC core rather than cycle-by-cycle FrodoSC;
- precise CPU and CIA cycle accounting from FrodoPC;
- FRF FIX44 completed-raster sprite-multiplexer repair;
- only PAL rasters `$33` through `$FA` generate pixels (320x200);
- each final post-IRQ raster is sent through `WritePixelLine8()`;
- two native 4-bitplane `ScreenBuffer`s are exchanged at VBlank;
- fixed 16-colour native palette;
- high-level IEC is forced, avoiding a second cycle-emulated 1541 CPU;
- frame skip is forced to 1 and the PAL screenmode requester opens on launch.

## Build

```sh
make -f Makefile.PiStorm060 clean
rm -f *.o Frodo FrodoPC FrodoSC FrodoRGB
make -f Makefile.PiStorm060 -j2 FrodoRGB
```

## Run

```text
FrodoRGB CRT="Work:Carts/ssf2t.crt"
```

Choose a non-interlaced PAL 320x256 screen with exactly four bitplanes.
`FrodoRGB` automatically selects X1, PAL320, NOVSYNC and the requester.

## Trade-offs

This is a MagiC64-style speed mode. It omits the outer 28 lines above and below
the 320x200 display window and remains a scanline approximation for register
changes made in the middle of a raster. Use `FrodoSC` when cycle-exact VIC
behaviour is more important than native RGB speed.

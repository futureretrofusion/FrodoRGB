# v1.0.20 native planar engine notes

- The specialised fast path requires X1 and a native screen with exactly four
  bitplanes. Other native depths use the older generic path.
- This first revision converts the full changed scanline; it does not yet track
  smaller dirty rectangles within a line.
- FrodoSC CPU/VIC emulation cost remains separate from display conversion cost.

# Known limitations

## VIC-II raster timing

The supported `Frodo` executable uses Frodo's fast scanline VIC core. It draws a
whole raster line from one state snapshot, then runs the CPU work that can
change sprite registers. `FRF_VIC_FIX42` catches late sprite-Y and sprite-enable
writes, but it cannot recover the exact CPU cycle of every mid-line write.

Demanding sprite multiplexers can therefore still show horizontal boundaries
or a few incorrect sprite lines. This is not caused by RTG caching, CPU cache,
`WritePixelArray()`, `WaitTOF()` or host frame synchronisation.

A VICE-like result requires a cycle-exact VIC/CPU path. The old FrodoSC sources
exist in the tree, but they are not yet fully integrated with the FRF cartridge
mapper, Amiga startup path and release testing. `FrodoSC` is therefore not the
supported FRF release target.

## Cartridge compatibility

The FRF mapper has focused tests for CRT hardware types 0, 19 and 32. Other CRT
hardware types may be rejected or may require additional mapper work.
EasyFlash compatibility is improved but should not be assumed universal.

## Target testing

Host regression tests exercise source invariants and cartridge mapping, but do
not reproduce the complete AmigaOS/PiStorm environment. The compiled binary
must still be tested for AHI, RTG, fullscreen, focus changes, reset, save states,
PRG loading and representative cartridge images.

## Media

C64 ROM images and game media are not included. Users must supply legally
obtained ROMs, CRTs, PRGs, D64/T64 images and save states.


## Native planar performance

The v1.0.20 post-frame chunky-to-planar staging engine did not improve speed on target hardware and may be slower. It is disabled by default in v1.0.21. A future native engine must render VIC output directly into bitplanes rather than convert and copy a completed chunky frame.

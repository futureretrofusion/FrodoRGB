# FRF 2026 Frodo RTG v1.0.26 FrodoRGB test

This revision corrects the remaining FrodoRGB hot path. The RGB core now uses
Frodo's direct program-counter pointer, updates the CIA chips once per raster
instead of after every instruction, and never blocks emulation waiting for an
Intuition back buffer. The RTG frame presenter remains bypassed while native
line output is active. See `RGBFAST_HOTPATH_FIX.md`.

# FRF 2026 Frodo RTG v1.0.24 native raster-output test

The native PAL320 FrodoSC path now follows the architecture recovered from the supplied MagiC64 1.81 executable: each completed VIC raster is converted with `WritePixelLine8()` into a hidden four-bitplane screen buffer, and the two buffers are exchanged at VBlank. The previous full-frame native conversion/copy is bypassed while this path is active.

# FRF 2026 Frodo RTG v1.0.23 compile correction

The v1.0.22 PAL320 block was generated with literal `\n` characters, producing compiler tokens such as `nstatic` and stray `n`. v1.0.23 restores real line breaks. The display algorithm is otherwise unchanged.

# FRF 2026 Frodo RTG v1.0.22 test notes

This is a performance test revision for native PAL output.

# FRF 2026 Frodo RTG v1.0.21 test notes

This test revision adds screenmode requester launch flags and restores the previous native-screen presenter as the default. The v1.0.20 planar converter is opt-in only. See `SCREENMODE_LAUNCH.md` and `MAGIC64_RGB_NOTES.md`.

# FRF 2026 Frodo RTG v1.0.20 native planar16 test

This is a performance test revision for requester-selected X1 native PAL
screens. Exact 4-bitplane output now uses a fixed 16-colour palette and a
specialised chunky-to-planar plus hardware-blitter path. Other depths fall back
to the existing generic indexed output. RTG/X2 behaviour is unchanged.

# FRF 2026 Frodo RTG v1.0.19 compile correction

This revision fixes the v1.0.18 AmigaOS compile error caused by calling `MOS6569::ReInitColors()` while only the forward declaration from `C64.h` was visible. `Display_Amiga.i` now includes `VIC.h`.

The hard-coded RTG mode, LAmiga requester hotkey, native PAL palette path, X2 scaling, FrodoSC cartridge integration and multiplex timing behaviour are unchanged.

# FRF 2026 Frodo RTG v1.0.18 fullscreen compile-scope fix

This test revision separates direct fixed RTG fullscreen from the screenmode requester. It also makes native RGB PAL output safe by obtaining palette pens from the selected screen rather than reusing Workbench pen numbers. See `FULLSCREEN_HOTKEY_TEST.md`.

# FRF 2026 Frodo RTG v1.0.15 cycle-exact sprite test

This is a test revision, not a stable release. X2 scaling is retained. VSync should remain disabled for the comparison. The purpose is to determine whether the remaining one-line sprite-multiplexer hole disappears when the existing cycle-exact VIC/CPU path is used with the current FRF cartridge and RTG work.

## Compile correction

The v1.0.17 source could not compile `Display.o` because a file-level helper referenced the `C64Display::TheC64` member without an object. v1.0.18 passes the owning `C64*` explicitly and preserves the v1.0.17 fullscreen colour and LAmiga-hotkey behaviour.

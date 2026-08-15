# v1.0.20 validation

Host-side validation completed:

- fixed-palette/planar16 source checks;
- 8-pixel chunky-to-planar round-trip tests for all solid colours;
- 5,000 deterministic random 8-pixel round trips;
- fullscreen hotkey, scope and complete VIC type checks;
- X2/RTG source checks;
- FrodoSC cartridge integration;
- normal CRT, Magic Desk, EasyFlash and reset source checks;
- AmigaDOS startup parser checks;
- Makefile dry-run for the `FrodoSC` target.

The m68k binary and native PAL performance still require local PiStorm testing.

# Release validation

Validation date: 2026-06-28

The following checks were completed against the v1.0.9 source tree:

- `test-restored-startup`: passed
- `test-normal-crt`: passed
- `test-crt-reset`: passed
- Type-0 8K/16K/Ultimax host CRT loader tests: passed
- Type-19 Magic Desk ROML-only/bank-switch tests: passed
- Type-32 EasyFlash control test: passed
- Forced clean `Makefile.PiStorm060` dry run: passed
- `README.md` and `README-FRF.md` identity check: passed
- GPL v2 file retained in `COPYING`: passed
- Release archive media/object scan: passed before packaging

These checks validate source structure and host-side mapper behaviour. They do
not replace compiling and running the m68k AmigaOS executable on the target.
The target tests in `RELEASE_CHECKLIST.md` remain required for a binary release.


## v1.0.21

Screenmode launch parsing and default-off PLANAR16 source checks are included. Runtime PAL performance still requires target testing.

## v1.0.24 MagiC64-style line-output validation

Passed on the host source tree:

- `test-magic64-line`
  - confirms the FrodoSC completed-raster callback;
  - confirms `WritePixelLine8()` per visible raster;
  - confirms two Intuition `ScreenBuffer` objects;
  - confirms VBlank `ChangeScreenBuffer()` switching;
  - confirms safe-buffer message handling;
  - compiles the new display block as C++98 with an isolated API harness.
- Existing FrodoSC CRT, normal CRT, Magic Desk, EasyFlash, reset, startup,
  fullscreen, X2 and VIC timing regression tests remain passing.

The m68k link and native PAL runtime performance still require the target
Amiga/PiStorm toolchain and hardware.

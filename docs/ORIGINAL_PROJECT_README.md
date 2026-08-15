# Current test revision: v1.0.27

## v1.0.27 FrodoRGB direct planar raster writer

FrodoRGB now converts each final 320-pixel raster directly into the hidden
four-bitplane native ScreenBuffer. This removes the per-line graphics.library
call while retaining the existing non-blocking ChangeScreenBuffer() frame swap.
WritePixelLine8() remains a guarded fallback. FrodoSC is unchanged.


## v1.0.26 FrodoRGB native PAL fast engine

Build `FrodoRGB` for full-speed-oriented classic Amiga RGB output. It combines
the direct-pointer instruction/scanline CPU core, FIX44 sprite-junction repair, a
320x200 rendered window and MagiC64-style `WritePixelLine8()`/`ChangeScreenBuffer()`
presentation. See `RGBFAST_NATIVE_ENGINE.md`.

MagiC64-style per-raster native PAL320 output with screen-buffer flipping.

New command-line launch form: `FrodoSC X1 SCREENMODE`. The experimental v1.0.20 post-frame planar converter is now disabled by default; use `PLANAR16` only for comparison. See `SCREENMODE_LAUNCH.md` and `MAGIC64_RGB_NOTES.md`.

# FRF 2026 Frodo RTG v1.0.20 native planar16 fast path

This test revision adds an exact 16-colour native Amiga display engine for X1,
4-bitplane RGB PAL screens. It replaces the generic `WritePixelArray8()` frame
copy in that mode with a lookup-table chunky-to-planar converter, two planar
staging buffers, dirty-line reuse and a hardware-blitter screen copy.

The fixed RTG mode, X2 output, LAmiga requester hotkey, FrodoSC cycle-exact VIC,
CRT mapping and audio paths are unchanged. See `NATIVE_PLANAR16_FASTPATH.md`.

# FRF 2026 Frodo RTG v1.0.19 VIC header compile fix

## v1.0.19 correction

v1.0.18 correctly passed the owning `C64*` into the fullscreen helper, but `Display_Amiga.i` only included `C64.h`. That header forward-declares `MOS6569`, so the compiler could not call `MOS6569::ReInitColors()`.

v1.0.19 includes `VIC.h` in the Amiga display implementation, providing the complete `MOS6569` type. No fullscreen mode, palette, hotkey, X2, FrodoSC, CRT or timing logic changed.

# FRF 2026 Frodo RTG v1.0.18 fullscreen compile-scope fix

## v1.0.18 fullscreen compile-scope correction

- Fixes the AmigaOS build error where the file-level fullscreen helper tried to access the `C64Display::TheC64` member directly.
- Passes the owning `C64*` explicitly into the helper before refreshing VIC colours for native PAL transitions.
- Keeps the fixed RTG mode `0x502e1203`, X2 scaling, FrodoSC timing, native PAL requester and `Ctrl+LAlt+LAmiga+U` hotkey unchanged.


**FRF 2026 Frodo RTG** is an AmigaOS and PiStorm-focused edition of
**Frodo V4.1b**, the Commodore 64 emulator originally written by
**Christian Bauer**.

- **Original Frodo emulator:** Christian Bauer
- **RTG / CRT added by:** Future Retro Fusion (FRF), 2026
- **AmigaOS integration, PiStorm/68060 release work and 2026 modifications:**
  Future Retro Fusion

The original Frodo attribution and copyright notices remain intact. This
modified edition is distributed under the **GNU General Public License version
2**. See `COPYING`.

## Release status

Version 1.0.9 is the complete FRF source release built from the v1.0.8 emulator
state, with consolidated documentation, expanded About credits, release notes,
known limitations and source checksums. No C64 ROMs, cartridges, PRGs, disks or
save states are included.

A compiled AmigaOS binary is not included in the source archive. Build it with
the existing `/opt/amiga` cross-toolchain as described below.

## What Future Retro Fusion added and improved

### CyberGraphX RTG display

- Added true-colour CyberGraphX output for modern Amiga RTG systems and
  PiStorm graphics environments.
- Converts the C64's 16-colour image to a fixed RGB palette and writes it with
  `WritePixelArray()`.
- Retains the original indexed/pen display path as a fallback for 8-bit and
  non-RTG screens.
- Re-detects the output path after changing between the Workbench window and a
  custom screen.
- Replaced a per-pixel 16-entry colour search with a 256-entry lookup table.
- Fixed RGB-buffer, CyberGraphX-library and display teardown leaks.
- Corrected the chunky display buffer to use `delete[]`.

### Custom-screen fullscreen

- Added split fullscreen switching: **Ctrl+LAlt+U** opens the fixed RTG mode directly; **Ctrl+LAlt+LAmiga+U** opens the RTG/native screenmode requester.
- Restores the proven fixed RTG display ID for **Ctrl+LAlt+U**, with only the
  existing `frodo-fullscreen.cfg` legacy override.
- The **Ctrl+LAlt+LAmiga+U** requester may select a native RGB PAL or RTG
  screen without changing the direct fixed RTG setting.
- Centres the C64 image and clears unused screen space to black.
- Restores the Workbench window and RTG state when fullscreen closes.
- Added safer window, screen, menu, pen, font and bitmap cleanup.

### Pause, focus and AHI audio

- Added **Ctrl+P** / Amiga+P pause and resume.
- Automatically pauses when the emulator loses focus and resumes when focus
  returns.
- Releases AHI while paused or unfocused so another Frodo instance can use it.
- Allows an instance to continue silently if AHI is temporarily unavailable,
  then retries AHI acquisition on resume or focus return.
- Split AHI startup and shutdown signals, fixing a stale-signal race that could
  free resources before the sound task had actually exited.
- Added guarded signal allocation, command signalling and sample-buffer cleanup.

### AmigaDOS command-line launching

The Amiga build captures the real command line from `GetArgStr()`. Historical
target logs showed that this runtime can supply null or corrupted `argv[]`
entries, so the FRF release deliberately does not dereference them.

Supported startup media include:

- CRT/cartridge images
- PRG programs
- D64 disk images
- T64 tape images
- Frodo snapshots/save states
- REU size overrides

Startup media bypasses the normal preferences requester.

### CRT and cartridge support

FRF added and repaired cartridge support for:

- Hardware type 0 fixed 8K cartridges
- Hardware type 0 fixed 16K cartridges
- Hardware type 0 Ultimax cartridges
- Hardware type 19 Magic Desk banked cartridges
- Hardware type 32 EasyFlash cartridges

The cartridge work includes:

- CRT header and CHIP packet parsing
- ROML and ROMH banking
- Magic Desk `$DE00` bank selection and bit-7 disable/re-enable
- EasyFlash IO1 and IO2 registers
- EasyFlash cartridge RAM and hidden RAM under ROML
- IO2 execution support at `$DF00-$DFFF`
- Correct cartridge memory mapping after bank changes
- Reinstallation of an inserted cartridge after C64 reset
- Preservation of the KERNAL/reset vector for ROML-only Magic Desk images
- The target-confirmed two-stage CRT load/reset sequence needed by this old
  Frodo Amiga memory path

The cartridge mapper has host regression tests for type-0 8K, 16K and Ultimax,
type-19 Magic Desk, and a type-32 EasyFlash control image. Cartridge support is
still best described as improved compatibility rather than universal support
for every CRT hardware type.

### PRG autoload

- Added `PRG=` startup loading and `PRGNOAUTO=`.
- Uses the target-confirmed DIR51B method rather than direct RAM injection.
- Copies the program to `T:0`, mounts `T:` as directory drive 8, waits for C64
  startup, types `LOAD"0",8`, then issues the detected `SYS` address or `RUN`.
- This preserves KERNAL loading behaviour needed by packed and self-relocating
  programs.

### Snapshot and disk/tape startup

- Added `SNAPSHOT=` and `SAVESTATE=` direct launch.
- Delays snapshot restoration until the emulation display is ready.
- Added `D64=` and `T64=` startup mounting.
- Preserved the normal snapshot load/save requesters.

### Expanded REU support

- Added REU choices for 1 MB, 2 MB, 4 MB, 8 MB and 16 MB in addition to
  128 KB, 256 KB and 512 KB.
- Added command-line REU selection and off mode.
- Updated allocation, address masking, preferences loading and saving for the
  larger sizes.

### VIC-II sprite-multiplexer correction

- Restored `FRF_VIC_FIX42` for raster-IRQ sprite multiplexers.
- Catches late sprite-Y writes and late sprite-enable writes after the fast
  line-based VIC has already performed its normal comparison.
- Improves games such as the C64 Super Street Fighter II Turbo cartridge, where
  multiplexed sprite rows were previously missing.

This is an approximation inside Frodo's fast scanline VIC. It is not a
cycle-exact VIC-II implementation. Some games can still show horizontal
multiplexer boundaries or a small number of incorrect sprite lines. This is an
emulation-timing limitation, not an RTG cache or host frame-sync problem.

### PiStorm/68060 build and release engineering

- Added a dedicated 68060 hard-float makefile using the established
  `/opt/amiga/bin/m68k-amigaos-*` toolchain layout.
- Uses `-m68060`, `-mhard-float`, high optimisation and omitted frame pointers.
- Added clean Linux-host build commands and configurable toolchain/include paths.
- Added quiet release builds and a separate diagnostic target.
- Added an embedded AmigaOS `$VER:` identity.
- Added FRF edition titles to windows, screens, menus and requesters.
- Added GPL, credits, changelog, release notes, code review, test checklist and
  source checksum documentation.
- Removed stale objects, old binaries, backup trees, precompiled headers and
  unrelated development reports from the public source archive.

### Reliability and safety fixes

- Replaced unsafe `printf(str)` output with literal-safe output.
- Added allocation checks and guarded cleanup in the Amiga display path.
- Fixed fullscreen destruction order and restoration of the windowed screen.
- Fixed AHI task shutdown ordering and invalid-signal handling.
- Restored the proven AmigaDOS command-line path after generic parser attempts
  broke target launching.
- Restored the proven PRG and CRT startup sequences after release cleanup
  accidentally simplified them.

## Keyboard controls

- **Ctrl+P / Amiga+P:** pause or resume emulation
- **Ctrl+LAlt+U:** enter or leave the saved/fixed RTG custom screen
- **Ctrl+LAlt+LAmiga+U:** open the screenmode requester, allowing RTG or native RGB PAL output

The normal Frodo menus and keyboard/joystick controls remain available.

## Command-line examples

Quote paths that contain spaces.

### Cartridge/CRT

```text
Frodo CRT="Work:Carts/game.crt"
Frodo CART="Work:Carts/game.crt"
Frodo -cart "Work:Carts/game.crt"
Frodo --cart="Work:Carts/game.crt"
```

### PRG

```text
Frodo PRG="Work:Games/game.prg"
Frodo PRGNOAUTO="Work:Games/game.prg"
Frodo -prg "Work:Games/game.prg"
Frodo --prg="Work:Games/game.prg"
```

### Snapshot/save state

```text
Frodo SNAPSHOT="Work:States/game.fss"
Frodo SAVESTATE="Work:States/game.fss"
Frodo -snapshot "Work:States/game.fss"
Frodo --savestate="Work:States/game.fss"
Frodo -s "Work:States/game.fss"
```

### Disk and tape

```text
Frodo D64="Work:Disks/game.d64"
Frodo T64="Work:Tapes/game.t64"
```

### REU

```text
Frodo REU=OFF
Frodo REU=128K
Frodo REU=512K
Frodo REU=1M
Frodo REU=2M
Frodo REU=4M
Frodo REU=8M
Frodo REU=16M
```

`REUSIZE=` and the `-reu`/`--reu` forms are also accepted.

Use one startup-media argument at a time. An REU override can accompany that
media argument.

## Build

The normal release build uses the existing `/opt/amiga` toolchain. No `sudo`
or host package installation is part of the build procedure.

```sh
cd FRF_2026_Frodo_RTG_1.0.9_RELEASE_SOURCE
make -f Makefile.PiStorm060 clean
rm -f *.o Frodo FrodoPC FrodoSC
make -f Makefile.PiStorm060 -j2 Frodo
```

Or use:

```sh
./build-frf-pistorm060.sh
```

The finished executable is `./Frodo`.

The defaults are:

```text
Compiler prefix: /opt/amiga/bin/m68k-amigaos-
Headers:         /opt/amiga/m68k-amigaos/sys-include
```

They can be overridden without editing the makefile:

```sh
make -f Makefile.PiStorm060 \
  AMIGA_PREFIX="$HOME/amiga" \
  AMIGA_INCLUDE="$HOME/amiga/m68k-amigaos/sys-include" \
  -j2 Frodo
```

## Diagnostic build

```sh
make -f Makefile.PiStorm060 diagnostic
```

Depending on the path being tested, diagnostics can create files such as:

```text
PROGDIR:frodo-argv.log
PROGDIR:frodo-cartargs.log
PROGDIR:frodo-mediaargs.log
```

Normal release builds keep these diagnostics disabled.

## Host regression tests

```sh
make -f Makefile.PiStorm060 test-restored-startup
make -f Makefile.PiStorm060 test-normal-crt
make -f Makefile.PiStorm060 test-crt-reset
```

These tests do not replace testing the compiled program on AmigaOS/PiStorm.

## Runtime files

Frodo requires separately supplied C64 ROM images and a preferences file. The
source archive does not include commercial ROMs or game media. Do not add ROMs,
cartridges, PRGs, disk images or save states to a public release unless you have
permission to redistribute them.

## Known limitations

- The normal `Frodo` executable uses the fast line-based VIC core. Raster
  effects that change registers within a scanline cannot be fully cycle-exact.
- `FRF_VIC_FIX42` improves sprite multiplexing but may still leave visible
  horizontal boundaries in demanding games. This is not a cache problem.
- The existing FrodoSC source is not yet fully integrated with all FRF CRT and
  Amiga startup modifications and is not the supported release executable.
- CRT support is tested for hardware types 0, 19 and 32, not every cartridge
  hardware type defined by the CRT format.
- Final AHI, RTG, fullscreen, cartridge and save-state testing must be performed
  on the actual target system after compiling.

See `KNOWN_LIMITATIONS.md`, `VALIDATION.md` and `RELEASE_CHECKLIST.md`.

## Licence

FRF 2026 Frodo RTG is a modified version of Frodo and is distributed under the
**GNU General Public License version 2**. When distributing a binary, provide
the complete corresponding source and a copy of the licence. See `COPYING`.

The software is provided without warranty.


## v1.0.13 Y-phase sweep test

FIX46 preserves the next-line-only VIC model and builds controlled Y-phase variants with biases 0, 1, 2 and 3. Use `build-phase-sweep.sh`; see `TIMING_FIX46_TEST.md`. Keep v1.0.9 as the stable backup.


## v1.0.14 command-line display options

The VIC still renders at its native 384x272 resolution. `X2` or `SCALE=2`
selects nearest-neighbour 768x544 output. `VSYNC` optionally waits for the
Amiga screen viewport before the completed frame is copied. These options can
help distinguish host scanout tearing from VIC sprite timing; they do not alter
the sprite Y-phase implementation. See `DISPLAY_X2_VSYNC_TEST.md`.


## v1.0.15 cycle-exact sprite test

The fast VIC still leaves a one-scanline hole in demanding multiplexers. The v1.0.15 test ports the proven FRF cartridge mapping into `FrodoSC`, links the mapper into the cycle-exact target, preserves X2 scaling, and leaves VSync off by default. Build and run `FrodoSC` for the timing comparison.


## v1.0.17 fullscreen hotkeys

See `FULLSCREEN_HOTKEY_TEST.md`. X1 requester mode can select native RGB PAL; X2 requester mode can set a scale-specific RTG screen. Direct fullscreen never opens the requester.

### MagiC64-style native PAL320 test

For the v1.0.24 native RGB performance path, build `FrodoSC` and launch:

```text
FrodoSC CRT="Work:Carts/ssf2t.crt" X1 PAL320 SCREENMODE NOVSYNC
```

Choose a non-interlaced 320x256 native PAL screen with four bitplanes. The
FrodoSC VIC sends completed raster lines directly to a hidden native screen
buffer through `WritePixelLine8()`; the two buffers swap at VBlank. See
`MAGIC64_LINE_OUTPUT_TEST.md` and `MAGIC64_1.81_RGB_BINARY_ANALYSIS.md`.

# FRF 2026 Frodo RTG changelog

## 1.0.27 — FrodoRGB direct planar raster writer

- Replaced FrodoRGB's per-raster graphics.library conversion call with direct writes to the hidden four-bitplane ScreenBuffer.
- Reused the existing 16-colour pair-LUT converter; no RTG conversion or completed-frame blit is introduced.
- Retained WritePixelLine8() as a guarded fallback for invalid, non-native or unaligned bitmaps.
- Kept FrodoSC, RTG, X2, windowed output, FIX44, CIA timing and non-blocking screen swaps unchanged.

## 1.0.26 — FrodoRGB hot-path correction

- Restored `PC_IS_POINTER=1` for direct opcode and operand fetching.
- Removed per-instruction precise CIA updates from the speed-oriented RGB core.
- Removed blocking safe-buffer and `WaitTOF()` waits from the live frame path.
- Native RGB now repeats the prior display frame instead of stalling emulation when Intuition is busy.
- FrodoRGB now honours `NODISPLAY` for bottleneck isolation.

# v1.0.26 — FrodoRGB native PAL fast engine

- Added a separate `FrodoRGB` executable using the precise instruction/scanline core.
- Restored the stronger FIX44 completed-raster sprite-multiplexer repair in `VIC_RGB.cpp`.
- Generates only the central 320x200 PAL display and sends final post-IRQ rasters to hidden native screen buffers.
- Forces one-frame presentation, NOVSYNC, PAL320 requester startup and high-level IEC for the RGB-fast binary.
- Leaves the working FrodoSC cycle-exact path unchanged.

# v1.0.24 — MagiC64-style native raster output test

- Reverse-engineered the supplied MagiC64 1.81 Amiga HUNK executable.
- Added per-raster `WritePixelLine8()` output from the FrodoSC VIC.
- Added two Intuition screen buffers with VBlank switching.
- Added safe-buffer message handling before reusing the old front buffer.
- Native PAL320 FrodoSC bypasses the completed-frame conversion and final copy.
- RTG, X2, windowed and fast-Frodo presentation remain unchanged.

# v1.0.23 — PAL320 generated-newline compile correction

- Replaces literal `\n` text accidentally embedded in the PAL320 C++ block with real source line breaks.
- Adds a source-integrity regression test so escaped-newline corruption cannot be packaged again.
- No PAL320 algorithm, FrodoSC timing, CRT, RTG, X2, palette or hotkey behaviour changed.

# v1.0.22 — true PAL320 direct planar output

- Added a genuine 320x256 native path instead of processing 384x272.
- Added direct visible-bitplane writes with no staging bitmap or final blit.
- Added PAL320/RGB320, DISPLAYEVERY and NODISPLAY flags.

# v1.0.21 — Screenmode launch and planar rollback

- Added `SCREENMODE`/`FULLSCREEN=REQUESTER` launch flags.
- The requester is queued until the complete C64/VIC object exists.
- Experimental post-frame PLANAR16 conversion is disabled by default after target testing showed no speed gain.
- `PLANAR16` remains available for controlled comparison.
- Added MagiC64 display-path analysis notes.

# 1.0.20 — 2026-06-30

- Added a fixed native 16-colour C64 palette at indexes 0 through 15.
- Added an X1, 4-bitplane planar output engine.
- Replaced `WritePixelArray8()` in the fast native case with a four-table
  chunky-to-planar converter.
- Added two private planar staging bitmaps and asynchronous blitter copying.
- Added dirty-line reuse for unchanged scanlines.
- Preserved generic indexed output for other depths and X2.
- Preserved RTG, FrodoSC, CRT, fullscreen-hotkey and audio behaviour.

## v1.0.19 — complete MOS6569 type for fullscreen palette refresh

- Included `VIC.h` from `Display_Amiga.i`.
- Fixed `invalid use of incomplete type class MOS6569` while compiling `Display.o`.
- Added `test-fullscreen-vic-header`.
- No runtime behaviour changed.

## v1.0.18 — fullscreen helper compile-scope fix

- Fixed `Display_Amiga.i` failing to compile because `FRFToggleAslFullscreen()` referenced `TheC64` outside `C64Display` scope.
- The owning `C64*` is now passed explicitly to the helper for native PAL VIC palette refreshes.
- Added a regression test that forbids direct `TheC64` references inside the file-level helper.
- No VIC, FrodoSC, CRT, X2, fixed RTG screenmode or fullscreen-hotkey behaviour changed.

## 1.0.17 — fixed RTG colour path and LAmiga requester

- Restored the proven direct RTG display ID (`0x502e1203`) and legacy `frodo-fullscreen.cfg` override.
- Removed requester-generated X1/X2 mode files from the direct fullscreen path.
- Kept RTG fullscreen on the original C64 pen mapping.
- Limited pen reacquisition to native indexed PAL screens and reinitialised VIC colours after pen changes.
- Changed the requester shortcut to `Ctrl+LAlt+LAmiga+U`.
- Left the FrodoSC cycle-exact multiplexing correction unchanged.

# FRF 2026 Frodo RTG change log

## v1.0.17 — split fixed RTG and requester fullscreen hotkeys

- `Ctrl+LAlt+U` now toggles the fixed/saved RTG mode without opening ASL.
- `Ctrl+LAlt+LAmiga+U` opens the screenmode requester in X1 or X2.
- Native RGB PAL selections stay requester-only and do not replace fixed RTG settings.
- Added independent `frodo-fullscreen-x1.cfg` and `frodo-fullscreen-x2.cfg`.
- Re-acquires the 16 C64 colour pens from each selected screen ColorMap, fixing native indexed-screen palette ownership.
- Preserves X2 scaling and FrodoSC cycle-exact cartridge integration from v1.0.15.

## 1.0.15 FrodoSC cycle-exact sprite test — 2026-06-30

- Preserves X2 nearest-neighbour scaling.
- Leaves VSync optional and off by default.
- Stops further fast-VIC Y-bias changes.
- Ports ROML/ROMH, IO1/IO2, hidden RAM and reset cartridge hooks to `CPUC64_SC.cpp`.
- Links `FRFEasyFlash.o` and `FrodoAmigaCompat.o` into `FrodoSC`.
- Adds a Linux-host-safe FrodoSC build target and source regression test.


## 1.0.14 X2/VSYNC display test — 2026-06-30

- Added command-line nearest-neighbour X2 output (`X2`, `SCALE=2`, `--scale=2`).
- Added optional host presentation synchronization (`VSYNC`, `PRESENT=VSYNC`).
- Added scaled true-colour and indexed RTG copy paths.
- Kept the native VIC framebuffer, FIX46 Y-bias logic, cartridge mapping and startup paths unchanged.
- Added fullscreen size validation for X2 output.

## 1.0.13 Y-phase sweep test — 2026-06-29

- Retains the v1.0.12 next-line-only timing model.
- Replaces the fixed minus-one constant with compile-time normal and expanded sprite Y-phase biases.
- Adds a one-command sweep that builds bias 0, 1, 2 and 3 binaries.
- Makes no framebuffer redraw, background, X-position, cartridge or RTG changes.
- Target-test candidate only.

## 1.0.12 offset test — 2026-06-29

- Removed the failed FIX43/FIX44 previous-raster redraw approach by restarting from v1.0.9.
- Added `FRF_VIC_FIX45_NEXT_LINE_PHASE_MINUS1`.
- Shifts only late sprite-Y and late-enable next-line `mc[]` phase by one raster.
- Leaves framebuffer lines, background rendering, collisions and ordinary VIC drawing unchanged.
- Target-test candidate only.


## 1.0.9 — 2026-06-28

- Prepared the complete public source release based on the v1.0.8 emulator state.
- Expanded the AmigaOS About requester with explicit FRF credits and a concise feature list.
- Added `README.md`, a consolidated `README-FRF.md`, `RELEASE_NOTES.md`,
  `FRF_IMPROVEMENTS.md`, `KNOWN_LIMITATIONS.md` and `VALIDATION.md`.
- Documented all command-line media forms, build commands, tests and release limitations.
- Updated the edition and requester identity to **FRF 2026 Frodo RTG v1.0.9**.
- No emulation, CRT, PRG, RTG, AHI, snapshot, REU or VIC timing code was changed from v1.0.8.

## 1.0.8 — 2026-06-28

- Fixed the remaining black screen for Magic Desk/type-19 single-game CRTs.
- Restored the historical ROML-only rule: Magic Desk never maps ROMH at `$A000` or `$E000`.
- Set the Magic Desk default mode to 0 instead of inheriting EasyFlash Ultimax mode 5.
- Prevented an empty `$FF` ROMH bank from replacing the C64 KERNAL and reset vector.
- Extended the real loader regression test to verify that boot and CPU reset preserve the KERNAL.

## 1.0.7 — 2026-06-28

- Restored the proven `CRT_FIX40_INSERTED_CART_RESET` hook in `MOS6510::Reset()`.
- Normal 8K and Magic Desk cartridges are now reinstalled after Frodo clears the `CBM80` signature during reset.
- Fixes the black screen seen with single-game CRTs while preserving working EasyFlash/multi-game cartridges.
- Added regression checks for the CPU reset hook and cartridge ROM restoration.

## 1.0.6 — 2026-06-28

- Restored ordinary single-game CRT loading that had been lost when the
  release tree retained only the hardware type 32 EasyFlash path.
- Restored **hardware type 19 Magic Desk** banked 8K cartridges, including the
  previously confirmed `Who Dares Wins.crt` path, `$DE00` bank selection and
  bit-7 cartridge disable/re-enable behaviour.
- Restored fixed 8K, fixed 16K and Ultimax cartridge mapping from the CRT
  header EXROM/GAME lines, with a CHIP-layout fallback for imperfect headers.
- Restored normal ROML visibility at `$8000`, 16K ROMH at `$A000`, and Ultimax
  ROMH at `$E000`, including the old direct-memory boot probe used by Frodo.
- Kept ordinary cartridges isolated from EasyFlash-only IO1/IO2 behaviour.
- Preserved the working EasyFlash type-32 path, raw AmigaDOS command-line
  loader, DIR51B PRG loader and `FRF_VIC_FIX42`.
- Added source-level and compiled host regression tests for type-0 8K/16K/
  Ultimax, type-19 Magic Desk bank switching, and a type-32 EasyFlash control.

## 1.0.5 — 2026-06-28

- Prepared a clean frozen source backup for release.
- Added explicit **RTG / CRT added by Future Retro Fusion (FRF), 2026** credit
  to the AmigaOS About requester, README and credits file.
- Preserved Christian Bauer's original Frodo attribution and copyright notices.
- Retained the unmodified GNU GPL version 2 text in `COPYING`.
- No emulation, CRT startup, PRG startup or VIC timing behaviour was changed.

## 1.0.4 — 2026-06-28

- Restored **FRF_VIC_FIX42**, the previously confirmed VIC-II line-mode
  sprite-multiplex correction used by Super Street Fighter II Turbo and other
  raster-IRQ multiplexers.
- Late sprite-Y writes now catch up the sprite DMA/display row when Frodo's
  line-based VIC has already performed its once-per-line comparison.
- Sprites enabled after that comparison are also armed at the correct current
  row.
- This is a VIC emulation correction, not host `WaitTOF()` or frame pacing.
- CRT/PRG command-line startup remains the restored v1.0.3 implementation.


## 1.0.3 — 2026-06-28

### Restored target-confirmed AmigaDOS launch path

- Reverted the generic `FRFStartupArgs` parser introduced during release cleanup.
- Restored the target-confirmed rule that the real AmigaDOS command line comes
  from `GetArgStr()`; this build's `argc/argv` values can be null or corrupted
  and are deliberately not dereferenced.
- Captures `GetArgStr()` immediately in `ArgvReceived()` before any other
  AmigaDOS parsing can consume or alter it.
- Restored the proven two-stage CRT activation sequence used by the old Frodo
  Amiga memory path. Removing the second load/reset prevented command-line CRTs
  from remaining active when emulation began.
- Restored the proven PRG DIR51B loader: copy the PRG to `T:0`, mount `T:` as a
  directory drive 8, issue `LOAD"0",8`, then issue the detected `SYS` command
  or `RUN` after the load has completed.
- Restored the emulation-loop hook in `C64_Amiga.i` that advances the delayed
  PRG load stages after KERNAL/BASIC startup.
- Retained `SNAPSHOT=`, `SAVESTATE=`, `CRT=`, `CART=`, `PRG=`, `T64=`, `D64=`
  and `REU=` parsing on the raw AmigaDOS command line.
- Removed the obsolete parser object and tests from both Amiga makefiles.

### Correction to 1.0–1.0.2 notes

The earlier release review incorrectly described the second CRT load/reset as
a removable duplicate and incorrectly treated `argc/argv` as a reliable fallback.
Target logs in the project history prove the opposite for this specific runtime.

## 1.0.2 — 2026-06-28

### Amiga command-line delivery fix

- Fixed all startup arguments being ignored on C runtimes where `GetArgStr()` is empty after startup processing.
- Startup options are now parsed from both the raw AmigaDOS argument string and `main(argc, argv)`.
- `argv` values override the raw string when both sources are available.
- Moved REU startup parsing into the same tested parser as CRT, PRG and save-state options.
- Added host regression tests that exercise actual `argc/argv` arrays, not only synthetic raw strings.

## 1.0.1 — 2026-06-22

### Startup argument correction

- Replaced overlapping snapshot/cartridge parsers with one quote-aware parser.
- Confirmed and retained `CRT=` and `CART=` support.
- Made the advertised `-cart`, `--cart`, `-crt` and `--crt` forms functional.
- Added `PRG=`, `PROGRAM=`, `-prg` and `--prg` startup autoload.
- Added `SAVESTATE=` and `STATE=` aliases for the existing snapshot loader.
- Added `-savestate`, `--savestate`, `-state` and `--state` forms.
- Added parser regression tests for quoted and unquoted AmigaDOS paths.
- Added delayed PRG loading with BASIC `RUN` or machine-code `SYS` autostart.

## 1.0 — 2026-06-21

### Release identity and packaging

- Added the **FRF 2026 Frodo RTG** edition identity and Future Retro Fusion credits.
- Preserved prominent attribution to original Frodo author Christian Bauer.
- Added GPL v2 licence text, release documentation and a clean Linux-host build path.
- Disabled routine trace files in release builds; use the `diagnostic` target to enable them.

### AmigaOS changes represented by this source tree

- CyberGraphX/RTG true-colour output using a fixed C64 RGB palette.
- Custom-screen fullscreen switching with a centred black surround.
- Pause/resume and focus-aware audio behaviour for multi-instance use.
- Startup snapshot, cartridge/CRT and REU command-line handling.
- EasyFlash and normal CRT mapper work, plus Amiga compatibility support.

### Release-review fixes

- Separated AHI startup and shutdown signals to remove a stale-signal shutdown race.
- Waits only for sound-task command signals, not AHI setup, preserving non-blocking startup.
- Fixed RTG/fullscreen teardown, CyberGraphX/RGB-buffer leaks and `delete[]` usage.
- Replaced per-pixel 16-entry RTG pen searches with a 256-entry lookup table.
- The release cleanup removed the second CRT loading/reset stage. This was
  later confirmed to be a regression and is restored in v1.0.4.
- Fixed unsafe `printf(str)` error output.
- Corrected PiStorm 68060 makefile cleanup, toolchain overrides and dependencies.

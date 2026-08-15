# FRF 2026 Frodo RTG — release code review

Review date: 2026-06-28

## Status

The source has been prepared as a clean release candidate, but it is **not yet a
runtime-certified release binary**. The required m68k AmigaOS cross-compiler,
NDK, AHI headers and CyberGraphX headers were not available in the review
environment, so a real link and Amiga/PiStorm run could not be completed here.

The included `Makefile.PiStorm060` parses successfully in a forced clean-build
dry run and resolves the intended `/opt/amiga/bin/m68k-amigaos-*` commands.

## Release-blocking defects fixed

1. **AHI shutdown race:** startup and task-exit previously shared one signal.
   A pending startup/ready signal could let the destructor return before the
   sound process had exited. Startup and shutdown now have separate signals.
2. **Uninitialised audio command signals:** pause, resume or destruction could
   access child-owned signal numbers before the child had allocated them. The
   main task now waits only for a short command-signal handshake, while AHI
   setup itself remains asynchronous.
3. **Fullscreen/RTG teardown:** exit from fullscreen could close or release the
   wrong window/screen resources. Fullscreen is now closed first and cleanup is
   performed against the original windowed screen.
4. **Memory/resource leaks:** fixed `delete` versus `delete[]` for the chunky
   buffer, released the RTG RGB buffer and closed `cybergraphics.library`.
5. **CRT startup regression:** the release cleanup incorrectly removed the
   second CRT load/reset as a duplicate. Historical target code and logs show
   that this old Frodo Amiga path requires two-stage activation. The proven
   load/install/reset plus reload/reset sequence has been restored.
6. **Unsafe format output:** replaced `printf(str)` with literal-format-safe
   error output.
7. **RTG conversion cost:** replaced a 16-entry colour search for every pixel
   with a prebuilt 256-entry pen-to-C64 lookup table.
8. **Build/release hygiene:** corrected Linux-host cleanup, dependency rules,
   toolchain overrides, deterministic diagnostic builds and release metadata.
9. **Command-line regression:** v1.0.1/v1.0.2 replaced the working
   `GetArgStr()` implementation with a generic parser and treated `argc/argv`
   as reliable. Target logs show `argv[]` is corrupt on this runtime while
   `GetArgStr()` contains the real command. v1.0.4 restores the confirmed raw
   AmigaDOS path and never dereferences `argv`.
10. **PRG startup regression:** direct RAM loading replaced the proven DIR51B
    drive-8 path. v1.0.4 restores the `T:0` copy, directory-drive mount, delayed
    `LOAD"0",8`, and delayed `SYS`/`RUN` sequence.
11. **Normal CRT regression:** the release source accepted only cartridge
    hardware type 32, so ordinary single-game CRTs were rejected. Historical
    target logs identify `Who Dares Wins.crt` as hardware type 19 Magic Desk,
    not type 0. v1.0.6 restored fixed type-0 8K/16K/Ultimax mapping and the
    type-19 Magic Desk bank/disable mapper while keeping EasyFlash separate.
12. **Normal CRT reset regression:** v1.0.6 restored the loader but omitted
    `FRFEasyFlashCPUReset()` and its `MOS6510::Reset()` call. Frodo then erased
    the `CBM80` signature without reinstalling the inserted cartridge, producing
    a black screen. v1.0.7 restores the complete `CRT_FIX40` reset path.
13. **Magic Desk ROMH regression:** the reset hook alone was insufficient. The
    type-19 branch inherited EasyFlash default mode 5 (Ultimax), so the empty
    Magic Desk ROMH array was exposed at `$E000-$FFFF`, replacing the KERNAL
    and reset vector with `$FF`. v1.0.8 sets mode 0 and explicitly disables
    both Magic Desk ROMH windows.

## Release identity added

- Window and requester identity: **FRF 2026 Frodo RTG v1.0.9**.
- Credits: original Frodo by Christian Bauer; AmigaOS RTG edition and 2026
  modifications by Future Retro Fusion.
- Embedded Amiga `$VER:` string.
- GPL v2 licence, credits, changelog, build instructions and release checklist.

## Validation completed

- Makefile forced-build and clean dry runs parse successfully.
- Source invariants confirm that command-line media is read from a captured
  `GetArgStr()` string and unsafe `argv[]` entries are not inspected.
- Historical target logs confirm successful quoted CRT parsing and successful
  PRG DIR51B loading through `T:0`, drive 8, `LOAD"0",8`, and `SYS2061`.
- Git whitespace/error check passes.
- Modified preprocessor blocks are balanced.
- Release diagnostics default off; `frodo-fullscreen.cfg` remains functional.
- Generated source package excludes stale objects, old binaries, backup trees,
  precompiled headers and unrelated comparison reports/scripts.
- Source and host tests verify that `MOS6510::Reset()` calls
  `FRFEasyFlashCPUReset()` before boot continues and that the normal/Magic Desk
  ROML window is reinstalled after a simulated `CBM80` removal.
- The real `FRFEasyFlash.cpp` loader was compiled and exercised on the host
  with synthetic type-0 8K/16K/Ultimax CRTs, a type-19 Magic Desk image with
  bank switching/disable tests, and a type-32 EasyFlash control; all assertions
  passed.

## Mandatory tests before publishing a binary

- Clean cross-compile and link with the exact public toolchain/SDK versions.
- Start/exit tests in windowed and fullscreen modes.
- Single- and dual-instance AHI tests, including focus loss/regain and exit.
- CyberGraphX true-colour and 8-bit indexed fallback tests.
- Snapshot load/save and `SNAPSHOT=`/`SAVESTATE=` launch tests.
- BASIC and machine-code `PRG=` startup tests on the Amiga target.
- Type-0 fixed, type-19 Magic Desk and multiple EasyFlash CRT tests using `CRT=`, `CART=` and `-cart`.
- REU tests at the release-supported sizes.
- Verification that no C64 ROMs, cartridges, games or other copyrighted media
  are accidentally included in the downloadable archive.

## Remaining technical debt

- The generic consolidated parser from v1.0.2 was removed because it changed
  proven target behaviour. The restored code follows the historical working
  implementation, but the newly compiled v1.0.9 executable still requires a
  final target regression test.
- The EasyFlash code contains many experimental fix generations and requires a
  documented cartridge compatibility matrix before it should be described as
  broadly compatible.
- Legacy cross-platform files contain older unchecked string and allocation
  patterns. This review concentrated on the Amiga/PiStorm release target.

## VIC-II multiplexing regression restored in v1.0.4

The v1.0.3 release tree had reverted `VIC.cpp` to the original once-per-line
sprite Y comparison. v1.0.4 restores `FRF_VIC_FIX42`, including late sprite-Y
and late sprite-enable catch-up. This was the historically confirmed SSF2T fix.

## v1.0.9 release-documentation review

- About requester now includes the explicit RTG/CRT credit and major FRF features.
- Primary README, complete improvement inventory, known limitations and release notes are included.
- The GPL v2 text remains unchanged.
- No emulation logic changed from v1.0.8.

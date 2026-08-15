# v1.0.20 native planar output

- Exact 16-colour palette for native 4-bitplane PAL output.
- Lookup-table chunky-to-planar conversion.
- Double planar staging buffers.
- Dirty-line reuse.
- Hardware-blitter screen copy.

# Future Retro Fusion improvements

This document lists the FRF changes represented by **FRF 2026 Frodo RTG
v1.0.9**, based on Frodo V4.1b.

## Display and AmigaOS integration

1. CyberGraphX true-colour RTG output.
2. Indexed/pen display fallback for non-RTG or 8-bit screens.
3. Fixed C64 RGB palette conversion.
4. 256-entry RTG colour lookup replacing repeated 16-colour scans.
5. Runtime RTG-path refresh after screen changes.
6. Ctrl+U custom-screen fullscreen.
7. ASL screen-mode selection and `frodo-fullscreen.cfg` reuse.
8. Centred C64 image with black surround on larger screens.
9. Correct fullscreen-to-window restoration.
10. Safer window, screen, menu, font, pen, bitmap and buffer cleanup.
11. Closure of `cybergraphics.library` and release of the RGB buffer.
12. Correct `delete[]` use for the chunky display buffer.
13. FRF edition titles on windows, screens, requesters and menus.
14. Expanded AmigaOS About requester with original and FRF credits.

## AHI, pause and multiple instances

15. Ctrl+P/Amiga+P real emulation pause.
16. Automatic pause on focus loss and resume on focus return.
17. AHI release while paused or unfocused.
18. AHI retry when focus returns.
19. Silent continuation when another instance temporarily owns AHI.
20. Separate AHI startup and shutdown signals.
21. Protection against stale-signal shutdown races.
22. Guarded child-task command signals and allocations.
23. Correct wait for actual sound-task termination.
24. Safer sample-buffer and signal cleanup.

## Command-line and startup media

25. Target-confirmed raw AmigaDOS `GetArgStr()` parsing.
26. Avoidance of corrupt/null `argv[]` values on the target runtime.
27. Direct `CRT=`/`CART=` cartridge launching.
28. Direct `PRG=` and `PRGNOAUTO=` launching.
29. Direct `D64=` and `T64=` mounting.
30. Direct `SNAPSHOT=` and `SAVESTATE=` loading.
31. REU size command-line overrides.
32. Startup-media bypass of the preferences requester.
33. Delayed snapshot restoration after display/emulation startup.
34. Quoted-path handling for AmigaDOS paths containing spaces.

## PRG loading

35. DIR51B/KERNAL-based PRG loading instead of direct RAM injection.
36. Temporary `T:0` copy and directory-drive-8 mounting.
37. Delayed `LOAD"0",8` injection after C64 cold start.
38. Automatic `RUN` or detected `SYS` command.
39. No-autostart PRG option.

## CRT and cartridge mapping

40. CRT header and CHIP packet parser.
41. Type-0 fixed 8K cartridge support.
42. Type-0 fixed 16K cartridge support.
43. Type-0 Ultimax support.
44. Type-19 Magic Desk banked cartridge support.
45. Type-32 EasyFlash support.
46. Magic Desk `$DE00` bank selection.
47. Magic Desk bit-7 disable and re-enable.
48. EasyFlash bank and mode register handling.
49. EasyFlash IO1 and IO2 access.
50. EasyFlash cartridge RAM.
51. Hidden RAM writes beneath ROML.
52. IO2 execution support at `$DF00-$DFFF`.
53. ROML/ROMH execution pointer remapping after bank changes.
54. Two-stage CRT activation required by the old Amiga Frodo path.
55. Cartridge reinstallation after C64 reset.
56. Preservation of the KERNAL and reset vector for Magic Desk.
57. Separation of ordinary cartridges from EasyFlash-only IO behaviour.
58. Host regression tests for type 0, type 19 and type 32 cartridge paths.

## REU

59. Added 1 MB, 2 MB, 4 MB, 8 MB and 16 MB REU sizes.
60. Updated REU allocation and address masking.
61. Updated preferences loading/saving for expanded sizes.
62. Added `REU=OFF`, `REU=128K` through `REU=16M`, `REUSIZE=`, `-reu`
    and `--reu` startup forms.

## VIC-II compatibility

63. Restored `FRF_VIC_FIX42` late sprite-Y catch-up.
64. Restored late sprite-enable catch-up.
65. Improved raster-IRQ sprite multiplexers such as SSF2T.

The fast VIC remains scanline-based, so this correction cannot provide the
cycle-level accuracy of VICE or a fully integrated cycle-exact FrodoSC build.

## Performance, safety and release work

66. Dedicated PiStorm/68060 hard-float makefile.
67. Configurable cross-compiler prefix and SDK include path.
68. Correct Linux-host cleanup and dependency rules.
69. Quiet release builds and explicit diagnostic builds.
70. Embedded AmigaOS `$VER:` string.
71. Unsafe `printf(str)` replacement.
72. Allocation and cleanup checks in the display and sound paths.
73. Clean source archive with stale objects, binaries and backup trees removed.
74. GNU GPL v2 licence included.
75. README, credits, changelog, release notes, code review, limitations,
    checklist and checksums included.


## v1.0.21

Screenmode launch parsing and default-off PLANAR16 source checks are included. Runtime PAL performance still requires target testing.

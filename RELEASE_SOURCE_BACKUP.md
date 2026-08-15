# FRF 2026 Frodo RTG v1.0.9 — release source backup

Frozen source backup prepared on **2026-06-28**.

## Identity and attribution

- Original Frodo emulator: Christian Bauer
- RTG / CRT added by: Future Retro Fusion (FRF), 2026
- AmigaOS integration, PiStorm/68060 build and 2026 modifications: Future
  Retro Fusion

## Included release state

- CyberGraphX RTG output and indexed fallback.
- Ctrl+U custom-screen fullscreen.
- Pause/focus-aware and multi-instance-oriented AHI behaviour.
- Raw AmigaDOS `GetArgStr()` CRT/PRG/D64/T64/save-state/REU launch path.
- DIR51B drive-8 PRG loader.
- Type-0 8K/16K/Ultimax, type-19 Magic Desk and type-32 EasyFlash mapper work.
- Inserted-cartridge reset restoration and Magic Desk KERNAL protection.
- Expanded REU sizes through 16 MB.
- `FRF_VIC_FIX42` raster sprite-multiplexer correction.
- PiStorm/68060 hard-float build target.
- Complete GPL, credits, README, release notes, improvement inventory, known
  limitations, validation, code review, checklist and source checksum manifest.

## Exclusions

This source backup intentionally contains no compiled objects, executables,
diagnostic logs, C64 ROM images, cartridges, PRGs, disk/tape images or save
states.

## Validation scope

Host regression tests cover the restored startup path and representative
normal/Magic Desk/EasyFlash cartridge maps. Makefile dry runs verify the intended
cross-compiler commands. Final runtime validation remains required on the
AmigaOS/PiStorm target after building.

This is the preferred source archive for the v1.0.9 release build.

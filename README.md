# FrodoRGB

**FrodoRGB** is the Future Retro Fusion AmigaOS 68k RGB/RTG development branch of **Frodo V4.1b**, the Commodore 64 emulator originally written by **Christian Bauer**.

Current staged FRF edition: **v1.0.27**

## Future Retro Fusion Amiga work

- CyberGraphX true-colour RTG output and indexed fallback
- fixed C64 RGB palette conversion and RTG colour lookup
- selectable RTG/native RGB fullscreen handling
- AHI pause, focus and multi-instance lifecycle fixes
- raw AmigaDOS startup argument handling
- CRT, PRG, D64, T64, snapshot and REU launch support
- EasyFlash, 8K/16K, Ultimax and Magic Desk cartridge work
- VIC sprite-multiplexer correction work
- native PAL320 / MagiC64-style line presentation
- dedicated FrodoRGB performance executable
- direct-PC and line-level CIA FrodoRGB hot path
- non-blocking native RGB screen-buffer swaps

## Command line and configuration

A complete reference for the current AmigaOS command-line parser, startup-output switches, media options, REU overrides, display/test switches, saved `Frodo Prefs` keys, defaults and MultiCPU build profiles is here:

**[COMMAND_LINE_AND_CONFIG.md](COMMAND_LINE_AND_CONFIG.md)**

The reference includes cartridge/CRT, PRG/D64/T64, snapshots, REU sizes, `FULLSCREEN=`, `SCREENMODE`, windowed/RTG/RGB output selection, scaling, VSync, PAL320/RGB320, PLANAR16, `DISPLAYEVERY=`, `NODISPLAY`, all persisted preference keys, and the 020/040/060 soft- and hard-float build variants.

> Note: the current `main_Amiga.i` startup guard still requires 68040 + 68881 or higher. The MultiCPU guide calls this out explicitly because the lower-CPU/no-FPU builds need that runtime guard made variant-aware before they can be considered fully supported targets.

## Build

```sh
make -f Makefile.PiStorm060 clean
make -f Makefile.PiStorm060 -j2 FrodoRGB
```

The normal fast `Frodo` target remains available alongside `FrodoRGB`.

## MultiCPU binaries

The MultiCPU release line provides clean independent builds for:

- `FrodoRGB_020`
- `FrodoRGB_020_FPU`
- `FrodoRGB_040`
- `FrodoRGB_040_FPU`
- `FrodoRGB_060`
- `FrodoRGB_060_FPU`

See `COMMAND_LINE_AND_CONFIG.md` for the exact `-m680xx` and soft/hard-float profiles.

## Verification

```sh
./scripts/verify-repo.sh
```

## ROMs and media

No Commodore 64 system ROMs or commercial game media are included.

## Attribution

- Original Frodo emulator: **Christian Bauer**
- RGB / RTG / AmigaOS integration and FRF 2026 modifications: **Future Retro Fusion**

Future Retro Fusion does not claim authorship of the original Frodo core.

## Licensing

See `COPYING` and the repository licensing files. `COPYING` is the authoritative GPLv2 text.

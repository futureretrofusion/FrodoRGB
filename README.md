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

## Build

    make -f Makefile.PiStorm060 clean
    make -f Makefile.PiStorm060 -j2 FrodoRGB

The normal fast Frodo target remains available with .

## Verification

    ./scripts/verify-repo.sh

## ROMs and media

No Commodore 64 system ROMs or commercial game media are included.

## Attribution

- Original Frodo emulator: **Christian Bauer**
- RGB / RTG / AmigaOS integration and FRF 2026 modifications: **Future Retro Fusion**

Future Retro Fusion does not claim authorship of the original Frodo core.

Detailed FRF source notes: 

## Licensing

See , ,  and .  is authoritative;  is byte-identical for GitHub licence detection.

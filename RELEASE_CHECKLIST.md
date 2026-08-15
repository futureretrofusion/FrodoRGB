# v1.0.20 native planar test checklist

- [ ] Build `FrodoSC` with the PiStorm060 makefile.
- [ ] Start with `X1 NOVSYNC`.
- [ ] Select an exactly 4-bitplane PAL screen.
- [ ] Confirm colours match the windowed/RTG C64 palette.
- [ ] Compare frame rate against v1.0.19 native output.
- [ ] Confirm X2 RTG output is unchanged.
- [ ] Confirm Ctrl+LAlt+U direct RTG fullscreen is unchanged.
- [ ] Confirm Ctrl+LAlt+LAmiga+U still opens the requester.
- [ ] Test normal CRT, Magic Desk and EasyFlash reset.

# Release checklist

- [ ] Build from a clean tree using `Makefile.PiStorm060`.
- [ ] Test windowed indexed output and true-colour CyberGraphX output.
- [ ] Enter and leave Ctrl+U fullscreen repeatedly.
- [ ] Exit while windowed and while fullscreen.
- [ ] Test AHI with one instance, two instances, focus loss and focus regain.
- [ ] Load/save a snapshot and launch it with both `SNAPSHOT=` and `SAVESTATE=`.
- [ ] Launch known type-0 8K, 16K and Ultimax CRTs, `Who Dares Wins.crt` or
      another type-19 Magic Desk CRT, and a type-32 EasyFlash CRT using `CRT=`
      and `CART=`; confirm correct ROM maps and Magic Desk bank switching.
- [ ] Reset a running type-0 and type-19 cartridge; confirm it returns to its
      cartridge startup rather than a black screen or BASIC prompt.
- [ ] For a type-19 Magic Desk image, confirm the KERNAL remains visible at
      `$E000-$FFFF` and bank switching through `$DE00` works after startup.
- [ ] Launch the previously proven `Fast Food.prg`, `Terra Cresta.prg` or
      `Tapper.prg` with `PRG=`; confirm `T:0` is created, drive 8 loads it, and
      `SYS2061`/`RUN` is issued after loading.
- [ ] Test REU disabled and the supported requested REU sizes.
- [ ] Verify About shows Christian Bauer, the exact “RTG / CRT added by Future Retro Fusion (FRF), 2026” credit, the FRF feature summary and v1.0.9.
- [ ] Ship `COPYING`, `README.md`, `CREDITS.md`, `CHANGELOG.md`, `RELEASE_NOTES.md`, `KNOWN_LIMITATIONS.md`, `VALIDATION.md` and complete corresponding source.
- [ ] Do not include C64 ROMs or other copyrighted game/media files without permission.

- [ ] Diagnostic build: verify `frodo-argv.log` reports
      `parser=restored-GetArgStr-DIR51B` and the expected raw command line.
- [ ] Confirm no code path dereferences the known-corrupt Amiga `argv[]` array.

## VIC-II raster/multiplex regression

- [ ] Verify SSF2T/SSF2 C64 sprite multiplexing has complete sprite rows and stable fighters.


## v1.0.21

Screenmode launch parsing and default-off PLANAR16 source checks are included. Runtime PAL performance still requires target testing.

## v1.0.24 target checks

- [ ] Build `FrodoSC` with the `/opt/amiga` m68k toolchain.
- [ ] Launch with `X1 PAL320 SCREENMODE NOVSYNC`.
- [ ] Select native PAL 320x256, four bitplanes, non-interlaced.
- [ ] Confirm `WritePixelLine8()` line output is full speed.
- [ ] Confirm no buffer tearing when menus or screen depth changes occur.
- [ ] Confirm RTG X2 remains unchanged.
- [ ] Confirm normal, Magic Desk and EasyFlash CRTs still boot and reset.

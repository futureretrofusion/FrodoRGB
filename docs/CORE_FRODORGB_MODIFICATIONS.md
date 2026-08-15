# FrodoRGB - Future Retro Fusion source modifications

This document records the principal Future Retro Fusion changes represented by **FRF 2026 Frodo RTG v1.0.27**. FrodoRGB is derived from Frodo V4.1b by Christian Bauer.

## Display / RTG

FRF adds CyberGraphX true-colour RTG output, indexed fallback, corrected C64 RGB conversion, a 256-entry colour lookup, output-path refresh after screen changes, centred fullscreen output and safer screen/window/font/pen/bitmap/buffer teardown.

## Fullscreen / native RGB

The Amiga display work includes custom screens, fixed RTG operation, ASL-selected modes, native RGB PAL modes, window restoration and runtime fullscreen switching. Machine-local  files are intentionally excluded.

## AHI / pause / multiple instances

FRF adds real pause behaviour, automatic pause and AHI release on focus loss, AHI reacquisition on focus return, silent continuation while another instance owns AHI, separate startup/shutdown signalling and safer audio-task cleanup.

## AmigaDOS launch/media handling

FRF adds target-safe raw AmigaDOS argument parsing with quoted paths plus direct CRT/CART, PRG/PRGNOAUTO, D64, T64, snapshot/save-state and REU options.

## Cartridge support

FRF work covers fixed 8K/16K, Ultimax, Magic Desk and EasyFlash mapping, ROML/ROMH, IO1/IO2, cartridge RAM, hidden RAM and reset/bank-state handling.

## VIC / sprite multiplexing

The fast VIC lineage includes FRF sprite-Y/sprite-enable catch-up and later completed-raster / sprite-junction correction work for demanding multiplexed-sprite titles.

## Native PAL320 / FrodoRGB

Later revisions add PAL320/RGB320 native presentation using line output, double buffering and . A separate  target isolates the speed-oriented RGB engine from the other Frodo variants.

## v1.0.26 hot-path correction

The verified v1.0.26 lineage restores , removes per-instruction precise CIA updates from the RGB speed core, uses line-level CIA accounting, removes blocking buffer/WaitTOF waits, repeats the prior frame rather than stalling when Intuition is busy, and honours  for bottleneck isolation.

## Public-source hygiene

The GitHub repository excludes C64 ROMs, CRT/PRG/disk/tape media, save states, executables, object files, logs, local fullscreen configuration, archives, backup trees, credentials and personal filesystem paths.

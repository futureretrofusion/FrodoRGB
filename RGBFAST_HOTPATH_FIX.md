# FrodoRGB hot-path correction — v1.0.26

The v1.0.26 RGB binary removed FrodoSC cycle emulation but accidentally kept
three expensive settings/actions:

1. `PC_IS_POINTER=0`, forcing opcode/operand fetch through `read_byte()`.
2. `PRECISE_CIA_CYCLES=1`, updating both CIA chips after every instruction.
3. Blocking waits for a safe native back buffer and repeated `WaitTOF()` calls
   if `ChangeScreenBuffer()` was busy.

v1.0.26 restores Frodo's direct program-counter pointer, returns CIA timing to
one update per raster line, and makes native presentation non-blocking. A busy
screen buffer repeats the previous video frame rather than stopping C64
emulation for another PAL interval.

The RTG frame path is not executed after native line output succeeds. The VIC
still produces a 384-byte indexed raster because that raster is the source for
sprite repair and the cropped 320-pixel native output, but no RTG colour
conversion or RTG blit follows it.

`NODISPLAY` is now honoured by FrodoRGB for direct comparison.

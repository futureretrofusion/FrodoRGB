# v1.0.14 X2 and VSYNC display test

This revision deliberately leaves the v1.0.13/FIX46 VIC timing path unchanged.

## X2 scaling

Nearest-neighbour scaling duplicates every native C64 pixel into a 2x2 block.
It is presentation-only; the VIC still renders the native 384x272 frame.

Accepted forms:

```text
Frodo X2
Frodo -x2
Frodo --x2
Frodo SCALE=2
Frodo --scale=2
```

Return to native size with `X1` or `SCALE=1`. X2 output is 768x544, plus the
16-pixel windowed status strip. If the locked Ctrl-U mode is too small, Frodo
opens the screen-mode requester for a mode large enough to contain the output.

## Optional host VSync

```text
Frodo VSYNC
Frodo VSYNC=ON
Frodo PRESENT=VSYNC
```

Disable with `NOVSYNC`, `VSYNC=OFF`, or `PRESENT=IMMEDIATE`. The option waits
for the Amiga screen viewport before copying the completed frame. It may reduce
host RTG scanout tearing, but cannot fix sprite-only VIC timing seams.

Combined example:

```text
Frodo CRT="Work:Carts/ssf2t.crt" X2 VSYNC
```

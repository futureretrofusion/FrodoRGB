# v1.0.22 true PAL320 direct native output

The earlier requester could show a PAL 320x256 mode name, but Frodo still forced
and processed the full 384x272 framebuffer. The v1.0.20 experimental engine
also converted into staging bitmaps and then blitted the complete image.

`PAL320` / `RGB320` now enables a genuine 320x256 path:

- source crop: x=32..351, y=8..263;
- fixed 16-colour palette, pens 0..15;
- direct writes into the visible four bitplanes;
- 32 pixels converted to one 32-bit word per plane;
- no staging bitmaps;
- no dirty-frame comparison;
- no final full-screen blit.

Use:

```text
FrodoSC CRT="Work:Carts/ssf2t.crt" X1 PAL320 SCREENMODE NOVSYNC
```

Diagnostics:

```text
DISPLAYEVERY=2
DISPLAYEVERY=3
NODISPLAY
DISPLAY=OFF
```

`NODISPLAY` is diagnostic only. If it restores full speed, native presentation
is the bottleneck. `DISPLAYEVERY=2` presents every second emulated frame.

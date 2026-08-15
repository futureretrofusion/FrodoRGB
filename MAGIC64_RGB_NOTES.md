# MagiC64 RGB/planar display notes

MagiC64 1.7 advertised three relevant display optimisations:

- bitplane-optimised graphics functions;
- faster and better Smart Refresh;
- faster border rendering.

Its public package is a finished m68k Amiga application and documentation, not
a source release, so the precise implementation cannot be copied or verified
line by line. The wording and observed behaviour strongly suggest that MagiC64
keeps its native display representation close to the Amiga bitplanes and avoids
a complete chunky-frame conversion plus a second full-frame blit.

The v1.0.20 Frodo experiment remained a post-render converter:

1. FrodoSC rendered all 384x272 pixels to a chunky buffer.
2. The display code compared the new chunky frame with the previous frame.
3. Dirty rows were converted to four staging bitplanes.
4. Unchanged rows were copied between staging bitmaps.
5. The staging bitmap was blitted again into the visible screen bitmap.

On a PiStorm/Amiga native screen this can add CPU work and Chip RAM traffic
instead of removing it. v1.0.21 therefore disables that experiment by default.
Use PLANAR16 only when explicitly comparing it.

A genuinely MagiC64-style next engine should write C64 colour indexes directly
into the destination bitplanes while each VIC raster is rendered, maintain one
visible native bitmap, and update only lines or character/sprite spans that the
VIC changed. That removes the separate full-frame chunky-to-planar pass and the
second full-screen bitmap copy.

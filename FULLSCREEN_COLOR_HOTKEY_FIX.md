# v1.0.17 fullscreen colour and hotkey correction

## Fixed RTG path

`Ctrl+LAlt+U` once again uses the proven fixed RTG display ID `0x502e1203`
(or the existing legacy `frodo-fullscreen.cfg` override). The v1.0.16
scale-specific `frodo-fullscreen-x1.cfg` and `frodo-fullscreen-x2.cfg`
selection path has been removed. Requester choices no longer alter the direct
RTG mode.

## Colour correction

v1.0.16 changed C64 pen numbers on every fullscreen switch but did not
reinitialise the VIC colour table. This could make the RTG fullscreen palette
wrong. v1.0.17 leaves RTG pens unchanged. Pens are switched only for a native
indexed PAL screen, and `ReInitColors()` is called both on entry and return.

## Hotkeys

- `Ctrl+LAlt+U`: direct fixed RTG fullscreen.
- `Ctrl+LAlt+LAmiga+U`: open the RTG/native RGB PAL screenmode requester.

The working FrodoSC cycle-exact sprite multiplexing implementation is unchanged.

# v1.0.18 fullscreen compile-scope correction

## Failure fixed

`FRFToggleAslFullscreen()` is a file-level static helper. v1.0.17 attempted to use `TheC64` inside that helper, but `TheC64` is a member of `C64Display`, so the Amiga compiler correctly reported that it was not declared in that scope.

## Correction

The helper now receives `C64 *c64` from `C64Display::PollKeyboard()` and uses that pointer only when reinitialising VIC colours after native PAL palette changes.

## Unchanged

- FrodoSC cycle-exact multiplexing fix
- X2 scaling
- VSync default/off behaviour
- fixed RTG fullscreen display ID `0x502e1203`
- `Ctrl+LAlt+U` direct RTG fullscreen
- `Ctrl+LAlt+LAmiga+U` screenmode requester
- normal CRT, Magic Desk and EasyFlash mappings

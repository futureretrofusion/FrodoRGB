# v1.0.17 fullscreen colour and hotkey test

This revision restores the proven direct RTG fullscreen path and keeps the
requester separate.

## Hotkeys

- `Ctrl+LAlt+U` toggles the proven fixed RTG fullscreen mode directly.
- `Ctrl+LAlt+LAmiga+U` opens the screenmode requester, then opens the selected
  RTG or native RGB PAL custom screen.

The requester is available in both X1 and X2. Requester selections do not
change the direct RTG display ID.

## Colour handling

RTG fullscreen keeps the original windowed C64 pen mapping. A native indexed
PAL screen acquires its own 16 C64 colour pens and immediately calls
`ReInitColors()`. Returning to Workbench restores its pens and reinitialises
the VIC colour table again.

## Suggested tests

```text
FrodoSC CRT="Work:Carts/ssf2t.crt" X2 NOVSYNC
```

1. Press `Ctrl+LAlt+U`; the requester must not appear and RTG colours must
   match windowed mode.
2. Return to the window.
3. Start with `X1 NOVSYNC`.
4. Press `Ctrl+LAlt+LAmiga+U` and choose a native RGB PAL mode.
5. Confirm its C64 palette is correct and returning to Workbench restores its
   colours.

# Screenmode requester on launch

The following command-line forms start the emulator directly and open the ASL
screenmode requester on the first emulation pass:

```text
FrodoSC SCREENMODE
FrodoSC SCREENMODE=ASK
FrodoSC SCREENMODE=REQUESTER
FrodoSC FULLSCREEN=ASK
FrodoSC FULLSCREEN=REQUESTER
FrodoSC --screenmode
FrodoSC --fullscreen-requester
```

Examples:

```text
FrodoSC CRT="Work:Carts/ssf2t.crt" X1 NOVSYNC SCREENMODE
FrodoSC X1 SCREENMODE=PAL
```

The requester is the same one used by Ctrl+LAlt+LAmiga+U.

The v1.0.20 planar converter is now disabled by default. It can still be enabled
for comparison with `PLANAR16` and disabled explicitly with `NOPLANAR16`.

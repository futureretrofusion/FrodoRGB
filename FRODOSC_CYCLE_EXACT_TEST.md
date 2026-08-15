# FRF 2026 Frodo RTG v1.0.15 cycle-exact sprite test

This test stops changing the fast VIC Y-bias. It builds the existing FrodoSC
cycle-exact CPU/VIC path with the proven FRF CRT mapper, RTG display, X2 scaling,
AHI, startup parser and release fixes.

Build:

```sh
make -f Makefile.PiStorm060 test-frodosc-crt
make -f Makefile.PiStorm060 clean
rm -f *.o Frodo FrodoPC FrodoSC
make -f Makefile.PiStorm060 -j2 FrodoSC
```

Test:

```text
FrodoSC CRT="Work:Carts/ssf2t.crt" X2 NOVSYNC
```

Use `NOVSYNC`; VSync is deliberately not part of the sprite timing fix.
Compare speed and multiplex junctions against the fast `Frodo` binary.

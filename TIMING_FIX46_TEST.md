# FRF_VIC_FIX46 Y-phase sweep

Target testing of v1.0.12 showed that a one-raster phase subtraction improved
multiplexed sprites but did not completely remove the visible Y-phase seam.
FIX46 therefore stops guessing a single constant and builds four otherwise
identical binaries with Y phase biases 0, 1, 2 and 3.

No completed raster is redrawn. Background rendering, X position, colour,
priority, collisions, cartridge mapping and RTG output are unchanged.

Run:

```sh
./build-phase-sweep.sh
```

The binaries are written to `phase-sweep-binaries/`.

Test `YBIAS2` first. If it improves the seam but a smaller offset remains, test
`YBIAS3`. `YBIAS1` should reproduce v1.0.12 and `YBIAS0` is the original FIX42
phase reference.

Report which binary gives the best junction and whether its sprite appears:

- vertically complete;
- one row too high;
- one row too low;
- duplicated at the junction;
- missing a row at the junction.

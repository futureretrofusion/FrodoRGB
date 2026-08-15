# FrodoRGB v1.0.27 direct planar raster writer

This update targets the last few percent of PAL performance without changing
the emulator core again. v1.0.26 already removed indirect PC fetches,
per-instruction CIA updates and blocking ScreenBuffer waits. v1.0.27 removes
the remaining per-raster graphics.library call from the dedicated FrodoRGB
path.

## Changed path

- The VIC still generates only the 200 visible 320-pixel rasters.
- FIX44 still repairs the completed raster before output.
- The existing 16-colour pair LUT converts each raster to four planar rows.
- The rows are written directly into the hidden native ScreenBuffer.
- ChangeScreenBuffer() remains the only frame-end presentation operation.
- WritePixelLine8() remains a guarded fallback.
- FrodoSC and RTG output are unchanged.

## Apply and build

```sh
cd ~/Downloads
unzip FRF_FrodoRGB_1.0.27_DIRECT_PLANAR_APPLY_KIT.zip
cd FRF_FrodoRGB_1.0.27_DIRECT_PLANAR_APPLY_KIT

python3 apply_frodorgb_v1_0_27_direct_planar.py \
  ~/Downloads/FRF_2026_Frodo_RTG_1.0.26_FRODORGB_HOTPATH_FIX_SOURCE

cd ~/Downloads/FRF_2026_Frodo_RTG_1.0.26_FRODORGB_HOTPATH_FIX_SOURCE
make -f Makefile.PiStorm060 test-rgbfast
make -f Makefile.PiStorm060 test-rgbfast-hotpath
make -f Makefile.PiStorm060 test-rgbfast-direct-planar

make -f Makefile.PiStorm060 clean
rm -f *.o Frodo FrodoPC FrodoSC FrodoRGB
make -f Makefile.PiStorm060 -j2 FrodoRGB
```

## Run

```text
FrodoRGB CRT="Work:Carts/ssf2t.crt"
```

Select PAL 320x256, four bitplanes, 16 colours, non-interlaced.

## Comparison fallback

To rebuild the v1.0.26-style line API path for comparison, remove only
`-DFRF_RGBFAST_DIRECT_PLANAR=1` from `RGBFLAGS`, clean, and rebuild FrodoRGB.
Do not change `PC_IS_POINTER=1` or restore per-instruction CIA timing.

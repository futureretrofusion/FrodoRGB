# FrodoRGB command-line and configuration reference

This document describes the **AmigaOS 68k FrodoRGB command-line parser and saved preference/configuration keys present on the current `main` branch**.

The Amiga port reads the raw AmigaDOS command line with `GetArgStr()`. Option matching is case-insensitive. Paths may be quoted when they contain spaces.

> **Current MultiCPU compatibility note**
>
> FrodoRGB can be compiled into 68020, 68040 and 68060 soft-float/hard-float variants, but the current `main_Amiga.i` startup code still contains a runtime check requiring **68040 + 68881 or higher**. Until that guard is made CPU/FPU-variant-aware, the 020 and no-FPU binaries should be treated as build artifacts for compatibility work rather than guaranteed runnable releases.

## Quick examples

```text
FrodoRGB CRT="Work:Carts/ssf2t.crt"
FrodoRGB PRG="Work:Games/demo.prg"
FrodoRGB PRGNOAUTO="Work:Games/demo.prg"
FrodoRGB D64="Work:Disks/game.d64"
FrodoRGB T64="Work:Tapes/game.t64"
FrodoRGB SNAPSHOT="Work:States/game.state"
FrodoRGB REU=16M
FrodoRGB FULLSCREEN=RTG
FrodoRGB FULLSCREEN=RGB
FrodoRGB FULLSCREEN=ASK
FrodoRGB WINDOWED
FrodoRGB PAL320
FrodoRGB DISPLAYEVERY=2
FrodoRGB NODISPLAY
```

For startup-output options, the parser scans left-to-right and the **final output-selection option wins**.

---

# Command-line options

## Cartridge / CRT

| Form | Meaning |
|---|---|
| `CART=<path>` | Load a cartridge/CRT image. |
| `CRT=<path>` | Alias for `CART=`. |
| `--cart <path>` or `--cart=<path>` | Cartridge path. |
| `-cart <path>` or `-cart=<path>` | Cartridge path. |

Supplying a cartridge bypasses the normal startup preferences requester and starts the emulator with the cartridge path applied.

## PRG, D64 and T64 media

| Form | Meaning |
|---|---|
| `PRG=<path>` | Mount/load a PRG and attempt automatic `RUN`/`SYS` startup. |
| `PRGNOAUTO=<path>` | Load the PRG but do not issue the automatic `RUN`/`SYS` command. |
| `--prg <path>` or `--prg=<path>` | Alias for `PRG=`. |
| `-prg <path>` or `-prg=<path>` | Alias for `PRG=`. |
| `D64=<path>` | Mount a D64 image on drive 8. |
| `T64=<path>` | Mount a T64 image on drive 8. |

PRG, D64 and T64 startup media bypass the normal startup preferences requester.

## Snapshots / save states

All of the following select a startup snapshot/state path:

```text
SNAPSHOT=<path>
SAVESTATE=<path>
STATE=<path>
--snapshot <path>
--snapshot=<path>
--savestate <path>
--savestate=<path>
-snapshot <path>
-snapshot=<path>
-savestate <path>
-savestate=<path>
-s <path>
-s=<path>
```

A supplied snapshot bypasses the normal startup preferences requester.

## REU size override

Accepted option forms:

```text
REU=<size>
REUSIZE=<size>
--reu <size>
--reu=<size>
-reu <size>
-reu=<size>
```

Accepted values:

| REU setting | Accepted command-line values |
|---|---|
| Off | `NONE`, `OFF`, `0` |
| 128 KiB | `128`, `128K`, `128KB` |
| 256 KiB | `256`, `256K`, `256KB` |
| 512 KiB | `512`, `512K`, `512KB` |
| 1 MiB | `1M`, `1MB`, `1024K`, `1024KB` |
| 2 MiB | `2M`, `2MB`, `2048K`, `2048KB` |
| 4 MiB | `4M`, `4MB`, `4096K`, `4096KB` |
| 8 MiB | `8M`, `8MB`, `8192K`, `8192KB` |
| 16 MiB | `16M`, `16MB`, `16384K`, `16384KB` |

## Startup output / fullscreen selection

### `FULLSCREEN=<mode>`

Accepted values:

| Destination | Accepted values |
|---|---|
| RTG fullscreen | `RTG`, `CGX`, `CYBERGFX` |
| Native RGB/PAL fullscreen | `RGB`, `NATIVE`, `PAL`, `PAL320` |
| Requester | `ASK`, `REQUEST`, `REQUESTER`, `SCREENMODE` |
| Workbench/windowed | `WINDOW`, `WINDOWED`, `WORKBENCH`, `OFF`, `NO`, `FALSE`, `0` |

Examples:

```text
FrodoRGB FULLSCREEN=RTG
FrodoRGB FULLSCREEN=RGB
FrodoRGB FULLSCREEN=ASK
FrodoRGB FULLSCREEN=WINDOWED
```

### Direct output aliases

```text
WINDOWED
WINDOW
--windowed
--fullscreen-rtg
--fullscreen-rgb
--fullscreen-ask
```

### Screen-mode requester

```text
SCREENMODE
--screenmode
--fullscreen-requester
SCREENMODE=ASK
SCREENMODE=REQUEST
SCREENMODE=REQUESTER
SCREENMODE=SCREENMODE
SCREENMODE=PAL
```

These select the startup screen-mode requester.

## Display scaling

Accepted forms:

```text
SCALE=<value>
DISPLAY_SCALE=<value>
--scale <value>
--scale=<value>
-scale <value>
-scale=<value>
```

Accepted values:

| Scale | Values |
|---|---|
| 1x | `1`, `1X`, `X1` |
| 2x | `2`, `2X`, `X2` |

Direct aliases are also accepted:

```text
X1
--x1
-x1
X2
--x2
-x2
```

## VSync / presentation timing

Value forms:

```text
VSYNC=<value>
PRESENT=<value>
```

Values that enable VSync:

```text
1 ON YES TRUE VSYNC
```

Values that disable VSync / request immediate presentation:

```text
0 OFF NO FALSE IMMEDIATE
```

Direct switches:

```text
VSYNC
--vsync
-vsync
NOVSYNC
--novsync
```

## PAL / native RGB geometry

```text
PAL320
RGB320
NATIVE320
```

These select the cropped native 320x256 PAL presentation path and force display scale to 1x.

```text
PAL384
RGB384
```

These disable the native PAL320 crop and use the wider native presentation path.

## PLANAR16 comparison path

Value form:

```text
PLANAR16=<value>
```

Enable values:

```text
1 ON YES TRUE
```

Disable values:

```text
0 OFF NO FALSE
```

Direct switches:

```text
PLANAR16
--planar16
NOPLANAR16
--noplanar16
```

The source marks this as a comparison/diagnostic path; the post-frame planar converter was slower on the target hardware and is disabled by default.

## Display throttling / display disable

```text
DISPLAYEVERY=<n>
```

`n` is clamped to **1 through 8**. `DISPLAYEVERY=1` is normal display presentation.

Disable rendering/presentation:

```text
NODISPLAY
--nodisplay
DISPLAY=OFF
DISPLAY=NO
DISPLAY=FALSE
DISPLAY=0
```

Enable rendering/presentation:

```text
DISPLAY=ON
DISPLAY=YES
DISPLAY=TRUE
DISPLAY=1
```

`NODISPLAY` is useful for performance/bottleneck testing.

---

# Saved configuration / `Frodo Prefs`

By default the Amiga build loads the file named:

```text
Frodo Prefs
```

The parser uses the form:

```text
Key = Value
```

The following are all keys currently read and written by `Prefs.cpp`.

## CPU, timing and scaling values

| Key | Default | Meaning / accepted value |
|---|---:|---|
| `NormalCycles` | `63` | Available CPU cycles on normal raster lines. Integer. |
| `BadLineCycles` | `23` | Available CPU cycles on VIC bad lines. Integer. |
| `CIACycles` | `63` | CIA timer ticks per raster line. Integer. |
| `FloppyCycles` | `64` | Available 1541 CPU cycles per line. Integer. |
| `SkipFrames` | `2` | Draw every n-th frame. Values <= 0 are corrected to 1. |
| `LatencyMin` | `80` | Minimum audio latency value. Integer. |
| `LatencyMax` | `120` | Maximum audio latency value. Integer. |
| `LatencyAvg` | `280` | Audio latency averaging value. Integer. |
| `ScalingNumerator` | `2` | Saved scaling numerator. Integer. |
| `ScalingDenominator` | `2` | Saved scaling denominator. Integer. |

The dedicated `FrodoRGB`/RGB-fast startup path subsequently forces `SkipFrames=1`, `LimitSpeed=TRUE` and `Emul1541Proc=FALSE` for its performance profile.

## Drives 8 through 11

Each drive has both a type and path:

```text
DriveType8 = DIR|D64|T64
DrivePath8 = <path>
DriveType9 = DIR|D64|T64
DrivePath9 = <path>
DriveType10 = DIR|D64|T64
DrivePath10 = <path>
DriveType11 = DIR|D64|T64
DrivePath11 = <path>
```

Defaults:

```text
DriveType8 = DIR
DrivePath8 = 64prgs
DriveType9 = DIR
DrivePath9 =
DriveType10 = DIR
DrivePath10 =
DriveType11 = DIR
DrivePath11 =
```

## Display/configuration strings

| Key | Default / values |
|---|---|
| `ViewPort` | Default is `Default`. |
| `DisplayMode` | Default is `Default`. |
| `DisplayType` | `WINDOW` or `SCREEN`; default `WINDOW`. |
| `StartupDisplay` | Saved as `WINDOWED`, `RTG`, `RGB`, or `ASK`; default `WINDOWED`. Loader also accepts `PAL`/`PAL320` as RGB and `REQUESTER` as ASK. |

## SID configuration

```text
SIDType = NONE
SIDType = DIGITAL
SIDType = SIDCARD
```

Default: `NONE`.

```text
SIDFilters = TRUE|FALSE
```

Default: `TRUE`.

## REU configuration

Saved `REUSize` values:

```text
NONE
128K
256K
512K
1M
2M
4M
8M
16M
```

Default: `NONE`.

## Boolean configuration keys

All of these use `TRUE` or `FALSE` in the saved preferences file:

| Key | Default | Meaning |
|---|---|---|
| `SpritesOn` | `TRUE` | Enable VIC sprite display. |
| `SpriteCollisions` | `TRUE` | Enable sprite collision handling. |
| `Joystick1On` | `FALSE` | Host joystick connected to C64 port 1. |
| `Joystick2On` | `FALSE` | Host joystick connected to C64 port 2. |
| `JoystickSwap` | `FALSE` | Swap joystick ports. |
| `LimitSpeed` | `FALSE` | Limit emulation speed. |
| `FastReset` | `FALSE` | Fast reset / skip RAM-test-style startup behaviour. |
| `CIAIRQHack` | `FALSE` | CIA IRQ compatibility option. |
| `MapSlash` | `TRUE` | Map `/` in C64 filenames. |
| `Emul1541Proc` | `FALSE` | Enable processor-level 1541 emulation. |
| `SIDFilters` | `TRUE` | Enable SID filters. |
| `DoubleScan` | `TRUE` | Double scan lines where supported. |
| `HideCursor` | `FALSE` | Hide mouse cursor where supported. |
| `DirectSound` | `TRUE` | DirectSound-related setting retained from cross-platform Frodo prefs. |
| `ExclusiveSound` | `FALSE` | Exclusive-sound setting retained from cross-platform Frodo prefs. |
| `AutoPause` | `FALSE` | Auto-pause setting retained from cross-platform Frodo prefs. |
| `PrefsAtStartup` | `FALSE` | Show preferences at startup where supported. |
| `SystemMemory` | `FALSE` | System-memory display/work-surface setting retained from cross-platform Frodo prefs. |
| `AlwaysCopy` | `FALSE` | Always-copy display/work-surface setting retained from cross-platform Frodo prefs. |
| `SystemKeys` | `TRUE` | System/menu key handling setting retained from cross-platform Frodo prefs. |
| `ShowLEDs` | `TRUE` | Show emulated drive/status LEDs where supported. |

Some saved keys originate in the cross-platform Frodo preference structure and may not have an active AmigaOS UI control even though they are still parsed and written.

---

# MultiCPU build variants

The current MultiCPU packaging scheme uses six independent builds:

| Binary | CPU/FPU compile profile |
|---|---|
| `FrodoRGB_020` | `-m68020 -msoft-float` |
| `FrodoRGB_020_FPU` | `-m68020 -mhard-float` |
| `FrodoRGB_040` | `-m68040 -msoft-float` |
| `FrodoRGB_040_FPU` | `-m68040 -mhard-float` |
| `FrodoRGB_060` | `-m68060 -msoft-float` |
| `FrodoRGB_060_FPU` | `-m68060 -mhard-float` |

Each variant must be built from clean object files; object files must not be shared between CPU/FPU profiles.

Again, the current source-level runtime CPU/FPU guard must be made variant-aware before the lower-CPU/no-FPU binaries can be considered fully supported runtime targets.

---

# Source of truth

This reference was derived from the current `main` branch implementation in:

- `main_Amiga.i` — AmigaDOS command-line parsing and startup behaviour.
- `Prefs.cpp` — preference defaults, loading and saving.
- `Prefs.h` — preference fields and startup-display enums.
- `CLI_OUTPUT_SELECTION_1.0.30.md` — startup output-selection behaviour.

When adding a new command-line option or saved preference, update this document in the same change.
/*
 * FRFBuildConfig.h - Release switches for FRF 2026 Frodo RTG
 *
 * Modifications Copyright (C) 2026 Future Retro Fusion
 * Released under the GNU General Public License version 2.
 */
#ifndef FRF_BUILD_CONFIG_H
#define FRF_BUILD_CONFIG_H

/* Release builds are quiet by default. Set to 1 while diagnosing a port. */
#ifndef FRF_ENABLE_DIAGNOSTIC_LOGS
#define FRF_ENABLE_DIAGNOSTIC_LOGS 0
#endif

#define FRF_EDITION_NAME "FRF 2026 Frodo RTG"
#define FRF_MAGIC64_LINE_OUTPUT_MARKER "FRF_RGBFAST_DIRECT_PLANAR_1.0.27"
#define FRF_EDITION_VERSION "1.0.27"

#endif

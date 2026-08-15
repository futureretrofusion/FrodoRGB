/*
 * FRFDiagnostics.h - Optional release diagnostic file helper
 *
 * Copyright (C) 2026 Future Retro Fusion
 * Released under the GNU General Public License version 2.
 */
#ifndef FRF_DIAGNOSTICS_H
#define FRF_DIAGNOSTICS_H

#include "FRFBuildConfig.h"
#include <stdio.h>

static FILE *FRFOpenDiagnosticLog(const char *progdir_path,
                                  const char *fallback_path,
                                  const char *mode)
{
#if FRF_ENABLE_DIAGNOSTIC_LOGS
        FILE *f = NULL;
        if (progdir_path != NULL)
                f = fopen(progdir_path, mode);
        if (f == NULL && fallback_path != NULL)
                f = fopen(fallback_path, mode);
        return f;
#else
        (void)progdir_path;
        (void)fallback_path;
        (void)mode;
        return NULL;
#endif
}

#endif

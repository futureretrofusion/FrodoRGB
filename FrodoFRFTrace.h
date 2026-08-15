/*
 * FrodoFRFTrace.h - Optional diagnostic trace helper
 *
 * Modifications Copyright (C) 2026 Future Retro Fusion
 * Released under the GNU General Public License version 2.
 */
#ifndef FRODO_FRF_TRACE_H
#define FRODO_FRF_TRACE_H

#include "FRFBuildConfig.h"
#include "FRFDiagnostics.h"
#include <stdio.h>

static void FrodoFRFTrace(const char *msg)
{
#if FRF_ENABLE_DIAGNOSTIC_LOGS
        FILE *f = FRFOpenDiagnosticLog("PROGDIR:frodo-instance-trace.log",
                                       "frodo-instance-trace.log", "a");

        if (!f)
                return;

        fprintf(f, "%s\n", msg ? msg : "(null)");
        fclose(f);
#else
        (void)msg;
#endif
}

#endif

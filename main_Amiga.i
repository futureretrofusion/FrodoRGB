/* Modified 2026-06-21 by Future Retro Fusion for FRF 2026 Frodo RTG. */
#include <stdio.h>
#include <string.h>
#include "FRFEasyFlash.h"
#include "FRFBuildConfig.h"
#include "FrodoFRFTrace.h"
#include "FRFDiagnostics.h"

/*
 *  main_Amiga.i - Main program, AmigaOS specific stuff
 *
 *  Frodo (C) 1994-1997,2002 Christian Bauer
 */

#include <exec/types.h>
#include <dos/rdargs.h>
#include <proto/dos.h>
#include <exec/execbase.h>
#include <proto/exec.h>
#include <proto/intuition.h>

/* AmigaOS Version command identity. */
static const char FRF_AMIGA_VERSTAG[] __attribute__((used)) =
        "\0$VER: " FRF_EDITION_NAME " " FRF_EDITION_VERSION " (28.06.2026)";


// Global variables
Frodo *be_app;	// Pointer to Frodo object

// Library bases
extern ExecBase *SysBase;
struct GfxBase *GfxBase = NULL;
struct IntuitionBase *IntuitionBase = NULL;
struct Library *GadToolsBase = NULL;
struct Library *DiskfontBase = NULL;
struct Library *AslBase = NULL;

// Prototypes
void error_exit(const char *str);
void open_libs(void);
void close_libs(void);


/*
 *  Create application object and start it
 */

int main(int argc, char **argv)
{
	if ((SysBase->AttnFlags & (AFF_68040 | AFF_68881)) != (AFF_68040 | AFF_68881))
		error_exit("68040/68881 or higher required.\n");
	open_libs();

	ULONG secs, micros;
	CurrentTime(&secs, &micros);
	srand(micros);

	be_app = new Frodo();
	be_app->ArgvReceived(argc, argv);
	be_app->ReadyToRun();
	delete be_app;

	close_libs();
	return 0;
}


/*
 *  Low-level failure
 */

void error_exit(const char *str)
{
        fputs(str ? str : "Unknown error.\n", stderr);
	close_libs();
	exit(20);
}


/*
 *  Open libraries
 */

void open_libs(void)
{
	if (!(GfxBase = (struct GfxBase *)OpenLibrary("graphics.library", 39)))
		error_exit("Couldn't open Gfx V39.\n");
	if (!(IntuitionBase = (struct IntuitionBase *)OpenLibrary("intuition.library", 39)))
		error_exit("Couldn't open Intuition V39.\n");
	if (!(GadToolsBase = OpenLibrary("gadtools.library", 39)))
		error_exit("Couldn't open GadTools V39.\n");
	if (!(DiskfontBase = OpenLibrary("diskfont.library", 39)))
		error_exit("Couldn't open Diskfont V39.\n");
	if (!(AslBase = OpenLibrary("asl.library", 39)))
		error_exit("Couldn't open ASL V39.\n");
}


/*
 *  Close libraries
 */

void close_libs(void)
{
	if (AslBase)
		CloseLibrary(AslBase);
	if (DiskfontBase)
		CloseLibrary(DiskfontBase);
	if (GadToolsBase)
		CloseLibrary(GadToolsBase);
	if (IntuitionBase)
		CloseLibrary((struct Library *)IntuitionBase);
	if (GfxBase)
		CloseLibrary((struct Library *)GfxBase);
}


/*
 *  Constructor: Initialize member variables
 */

Frodo::Frodo()
{
	TheC64 = NULL;
	prefs_path[0] = 0;
}


/*
 *  Process command line arguments
 *
 *  FRF 2026 Frodo RTG 1.0.9:
 *  Restore the AmigaOS command-line path that was confirmed working on the
 *  target.  This runtime supplies the real command line through GetArgStr();
 *  argc/argv may contain invalid or garbled entries and must not be parsed.
 */

char FrodoStartupSnapshotPath[256] = "";
static char FrodoStartupCartPath[256] = "";
static char FrodoStartupPRGPath[256] = "";
static int FrodoStartupPRGAutorun = 1;
static char FrodoStartupT64Path[256] = "";
static char FrodoStartupD64Path[256] = "";
static char FrodoStartupPRGDirPath[256] = "";
static char FrodoStartupPRGBaseName[96] = "";
static int FrodoStartupBypassPrefs = 0;
static int FrodoStartupREUOverride = -1;
static char FrodoStartupRawArgs[1024] = "";

/*
 * FRF 2026 display command-line options.
 * These are deliberately presentation-only: the VIC always renders its native
 * 384x272 chunky frame, then Display_Amiga.i optionally scales/presents it.
 */
int FrodoFRFDisplayScale = 1;
int FrodoFRFPresentVSync = 0;
/* Open the ASL screenmode requester on the first emulation frame. */
int FrodoFRFStartupScreenModeRequester = 0;
/* FRF_RTG_BOTTOM_CLEAN_PAL_AUTO_1.0.29: native RGB binaries open PAL320 directly. */
int FrodoFRFStartupHardcodedPAL320 = 0;
/* FRF_CLI_OUTPUT_SELECTOR_1.0.30: command-line locked RTG fullscreen request. */
int FrodoFRFStartupLockedRTG = 0;
/* The v1.0.20 post-frame planar converter was slower on target hardware.
 * Keep it available for comparison, but disabled unless PLANAR16 is supplied. */
int FrodoFRFNativePlanar16 = 0;
/* True cropped native PAL mode: present the central 320x256 portion directly
 * into a 4-bitplane screen. */
int FrodoFRFNativePAL320 = 0;
/* Presentation diagnostics. DISPLAYEVERY=1 is normal. */
int FrodoFRFDisplayEvery = 1;
int FrodoFRFNoDisplay = 0;

static int FrodoFRFLower(int c)
{
        if (c >= 'A' && c <= 'Z')
                return c - 'A' + 'a';
        return c;
}

static int FrodoFRFEqNoCase(const char *a, const char *b)
{
        if (!a || !b)
                return 0;

        while (*a && *b) {
                if (FrodoFRFLower((unsigned char)*a) !=
                    FrodoFRFLower((unsigned char)*b))
                        return 0;
                a++;
                b++;
        }

        return *a == 0 && *b == 0;
}

static int FrodoFRFStartsNoCase(const char *s, const char *prefix)
{
        if (!s || !prefix)
                return 0;

        while (*prefix) {
                if (!*s)
                        return 0;
                if (FrodoFRFLower((unsigned char)*s) !=
                    FrodoFRFLower((unsigned char)*prefix))
                        return 0;
                s++;
                prefix++;
        }

        return 1;
}

static int FrodoFRFIsSpace(char c)
{
        return c == ' ' || c == '\t' || c == '\r' || c == '\n';
}

static int FrodoFRFOptionBoundary(char c)
{
        return c == 0 || c == '=' || FrodoFRFIsSpace(c);
}

static void FrodoFRFCopyRawPath(char *dst, int dst_size, const char *path)
{
        int i = 0;
        int j = 0;
        char quote = 0;

        if (!dst || dst_size <= 0)
                return;

        dst[0] = 0;
        if (!path)
                return;

        while (FrodoFRFIsSpace(path[i]))
                i++;

        if (path[i] == '=') {
                i++;
                while (FrodoFRFIsSpace(path[i]))
                        i++;
        }

        if (path[i] == '"' || path[i] == '\'') {
                quote = path[i];
                i++;
        }

        while (path[i] && j < dst_size - 1) {
                if (quote) {
                        if (path[i] == quote)
                                break;
                } else if (FrodoFRFIsSpace(path[i])) {
                        break;
                }

                dst[j++] = path[i++];
        }

        dst[j] = 0;
}

static void FrodoFRFMediaLog(const char *msg, const char *path)
{
#if FRF_ENABLE_DIAGNOSTIC_LOGS
        FILE *f = FRFOpenDiagnosticLog("PROGDIR:frodo-mediaargs.log",
                                       "frodo-mediaargs.log", "a");
        if (!f)
                return;
        fprintf(f, "%s", msg ? msg : "(null)");
        if (path)
                fprintf(f, "%s", path);
        fprintf(f, "\n");
        fclose(f);
#else
        (void)msg;
        (void)path;
#endif
}

static void FrodoFRFCartLog(const char *msg, const char *path)
{
#if FRF_ENABLE_DIAGNOSTIC_LOGS
        FILE *f = FRFOpenDiagnosticLog("PROGDIR:frodo-cartargs.log",
                                       "frodo-cartargs.log", "a");
        if (!f)
                return;
        fprintf(f, "%s", msg ? msg : "(null)");
        if (path)
                fprintf(f, "%s", path);
        fprintf(f, "\n");
        fclose(f);
#else
        (void)msg;
        (void)path;
#endif
}

static void FrodoFRFCaptureRawArgs(void)
{
        const char *raw = (const char *)GetArgStr();

        FrodoStartupRawArgs[0] = 0;
        if (!raw)
                return;

        strncpy(FrodoStartupRawArgs, raw, sizeof(FrodoStartupRawArgs) - 1);
        FrodoStartupRawArgs[sizeof(FrodoStartupRawArgs) - 1] = 0;
}

static void FrodoFRFParseSnapshotRawArgs(void)
{
        const char *p = FrodoStartupRawArgs;

        while (*p) {
                while (FrodoFRFIsSpace(*p))
                        p++;

                if (FrodoFRFStartsNoCase(p, "SNAPSHOT=")) {
                        FrodoFRFCopyRawPath(FrodoStartupSnapshotPath,
                                            sizeof(FrodoStartupSnapshotPath), p + 9);
                        break;
                }
                if (FrodoFRFStartsNoCase(p, "SAVESTATE=")) {
                        FrodoFRFCopyRawPath(FrodoStartupSnapshotPath,
                                            sizeof(FrodoStartupSnapshotPath), p + 10);
                        break;
                }
                if (FrodoFRFStartsNoCase(p, "STATE=")) {
                        FrodoFRFCopyRawPath(FrodoStartupSnapshotPath,
                                            sizeof(FrodoStartupSnapshotPath), p + 6);
                        break;
                }
                if (FrodoFRFStartsNoCase(p, "--snapshot") &&
                    FrodoFRFOptionBoundary(p[10])) {
                        FrodoFRFCopyRawPath(FrodoStartupSnapshotPath,
                                            sizeof(FrodoStartupSnapshotPath), p + 10);
                        break;
                }
                if (FrodoFRFStartsNoCase(p, "--savestate") &&
                    FrodoFRFOptionBoundary(p[11])) {
                        FrodoFRFCopyRawPath(FrodoStartupSnapshotPath,
                                            sizeof(FrodoStartupSnapshotPath), p + 11);
                        break;
                }
                if (FrodoFRFStartsNoCase(p, "-snapshot") &&
                    FrodoFRFOptionBoundary(p[9])) {
                        FrodoFRFCopyRawPath(FrodoStartupSnapshotPath,
                                            sizeof(FrodoStartupSnapshotPath), p + 9);
                        break;
                }
                if (FrodoFRFStartsNoCase(p, "-savestate") &&
                    FrodoFRFOptionBoundary(p[10])) {
                        FrodoFRFCopyRawPath(FrodoStartupSnapshotPath,
                                            sizeof(FrodoStartupSnapshotPath), p + 10);
                        break;
                }
                if (FrodoFRFStartsNoCase(p, "-s") &&
                    FrodoFRFOptionBoundary(p[2])) {
                        FrodoFRFCopyRawPath(FrodoStartupSnapshotPath,
                                            sizeof(FrodoStartupSnapshotPath), p + 2);
                        break;
                }

                while (*p && !FrodoFRFIsSpace(*p))
                        p++;
        }

        if (FrodoStartupSnapshotPath[0])
                FrodoStartupBypassPrefs = 1;
}

static void FrodoFRFParseCartRawArgs(void)
{
        const char *p = FrodoStartupRawArgs;

        while (*p) {
                while (FrodoFRFIsSpace(*p))
                        p++;

                if (FrodoFRFStartsNoCase(p, "CART=")) {
                        FrodoFRFCopyRawPath(FrodoStartupCartPath,
                                            sizeof(FrodoStartupCartPath), p + 5);
                        break;
                }
                if (FrodoFRFStartsNoCase(p, "CRT=")) {
                        FrodoFRFCopyRawPath(FrodoStartupCartPath,
                                            sizeof(FrodoStartupCartPath), p + 4);
                        break;
                }
                if (FrodoFRFStartsNoCase(p, "--cart") &&
                    FrodoFRFOptionBoundary(p[6])) {
                        FrodoFRFCopyRawPath(FrodoStartupCartPath,
                                            sizeof(FrodoStartupCartPath), p + 6);
                        break;
                }
                if (FrodoFRFStartsNoCase(p, "-cart") &&
                    FrodoFRFOptionBoundary(p[5])) {
                        FrodoFRFCopyRawPath(FrodoStartupCartPath,
                                            sizeof(FrodoStartupCartPath), p + 5);
                        break;
                }

                while (*p && !FrodoFRFIsSpace(*p))
                        p++;
        }

        if (FrodoStartupCartPath[0]) {
                FrodoStartupBypassPrefs = 1;
                FrodoFRFCartLog("CART path parsed: ", FrodoStartupCartPath);
        }
}

static void FrodoFRFParseMediaRawArgs(void)
{
        const char *p = FrodoStartupRawArgs;

        while (*p) {
                while (FrodoFRFIsSpace(*p))
                        p++;

                if (FrodoFRFStartsNoCase(p, "PRGNOAUTO=")) {
                        FrodoFRFCopyRawPath(FrodoStartupPRGPath,
                                            sizeof(FrodoStartupPRGPath), p + 10);
                        FrodoStartupPRGAutorun = 0;
                        break;
                }
                if (FrodoFRFStartsNoCase(p, "PRG=")) {
                        FrodoFRFCopyRawPath(FrodoStartupPRGPath,
                                            sizeof(FrodoStartupPRGPath), p + 4);
                        FrodoStartupPRGAutorun = 1;
                        break;
                }
                if (FrodoFRFStartsNoCase(p, "--prg") &&
                    FrodoFRFOptionBoundary(p[5])) {
                        FrodoFRFCopyRawPath(FrodoStartupPRGPath,
                                            sizeof(FrodoStartupPRGPath), p + 5);
                        FrodoStartupPRGAutorun = 1;
                        break;
                }
                if (FrodoFRFStartsNoCase(p, "-prg") &&
                    FrodoFRFOptionBoundary(p[4])) {
                        FrodoFRFCopyRawPath(FrodoStartupPRGPath,
                                            sizeof(FrodoStartupPRGPath), p + 4);
                        FrodoStartupPRGAutorun = 1;
                        break;
                }
                if (FrodoFRFStartsNoCase(p, "T64=")) {
                        FrodoFRFCopyRawPath(FrodoStartupT64Path,
                                            sizeof(FrodoStartupT64Path), p + 4);
                        break;
                }
                if (FrodoFRFStartsNoCase(p, "D64=")) {
                        FrodoFRFCopyRawPath(FrodoStartupD64Path,
                                            sizeof(FrodoStartupD64Path), p + 4);
                        break;
                }

                while (*p && !FrodoFRFIsSpace(*p))
                        p++;
        }

        if (FrodoStartupPRGPath[0]) {
                FrodoStartupBypassPrefs = 1;
                FrodoFRFMediaLog("PRG path parsed: ", FrodoStartupPRGPath);
        }
        if (FrodoStartupT64Path[0]) {
                FrodoStartupBypassPrefs = 1;
                FrodoFRFMediaLog("T64 path parsed: ", FrodoStartupT64Path);
        }
        if (FrodoStartupD64Path[0]) {
                FrodoStartupBypassPrefs = 1;
                FrodoFRFMediaLog("D64 path parsed: ", FrodoStartupD64Path);
        }
}

static void FrodoFRFREUSetValue(const char *v)
{
        if (!v || !v[0])
                return;

        if (FrodoFRFEqNoCase(v, "NONE") || FrodoFRFEqNoCase(v, "OFF") ||
            FrodoFRFEqNoCase(v, "0"))
                FrodoStartupREUOverride = REU_NONE;
        else if (FrodoFRFEqNoCase(v, "128") || FrodoFRFEqNoCase(v, "128K") ||
                 FrodoFRFEqNoCase(v, "128KB"))
                FrodoStartupREUOverride = REU_128K;
        else if (FrodoFRFEqNoCase(v, "256") || FrodoFRFEqNoCase(v, "256K") ||
                 FrodoFRFEqNoCase(v, "256KB"))
                FrodoStartupREUOverride = REU_256K;
        else if (FrodoFRFEqNoCase(v, "512") || FrodoFRFEqNoCase(v, "512K") ||
                 FrodoFRFEqNoCase(v, "512KB"))
                FrodoStartupREUOverride = REU_512K;
        else if (FrodoFRFEqNoCase(v, "1M") || FrodoFRFEqNoCase(v, "1MB") ||
                 FrodoFRFEqNoCase(v, "1024K") || FrodoFRFEqNoCase(v, "1024KB"))
                FrodoStartupREUOverride = REU_1M;
        else if (FrodoFRFEqNoCase(v, "2M") || FrodoFRFEqNoCase(v, "2MB") ||
                 FrodoFRFEqNoCase(v, "2048K") || FrodoFRFEqNoCase(v, "2048KB"))
                FrodoStartupREUOverride = REU_2M;
        else if (FrodoFRFEqNoCase(v, "4M") || FrodoFRFEqNoCase(v, "4MB") ||
                 FrodoFRFEqNoCase(v, "4096K") || FrodoFRFEqNoCase(v, "4096KB"))
                FrodoStartupREUOverride = REU_4M;
        else if (FrodoFRFEqNoCase(v, "8M") || FrodoFRFEqNoCase(v, "8MB") ||
                 FrodoFRFEqNoCase(v, "8192K") || FrodoFRFEqNoCase(v, "8192KB"))
                FrodoStartupREUOverride = REU_8M;
        else if (FrodoFRFEqNoCase(v, "16M") || FrodoFRFEqNoCase(v, "16MB") ||
                 FrodoFRFEqNoCase(v, "16384K") || FrodoFRFEqNoCase(v, "16384KB"))
                FrodoStartupREUOverride = REU_16M;
}

static void FrodoFRFParseREURawArgs(void)
{
        const char *p = FrodoStartupRawArgs;
        char value[32];

        while (*p) {
                while (FrodoFRFIsSpace(*p))
                        p++;

                if (FrodoFRFStartsNoCase(p, "REUSIZE=")) {
                        FrodoFRFCopyRawPath(value, sizeof(value), p + 8);
                        FrodoFRFREUSetValue(value);
                        return;
                }
                if (FrodoFRFStartsNoCase(p, "REU=")) {
                        FrodoFRFCopyRawPath(value, sizeof(value), p + 4);
                        FrodoFRFREUSetValue(value);
                        return;
                }
                if (FrodoFRFStartsNoCase(p, "--reu") &&
                    FrodoFRFOptionBoundary(p[5])) {
                        FrodoFRFCopyRawPath(value, sizeof(value), p + 5);
                        FrodoFRFREUSetValue(value);
                        return;
                }
                if (FrodoFRFStartsNoCase(p, "-reu") &&
                    FrodoFRFOptionBoundary(p[4])) {
                        FrodoFRFCopyRawPath(value, sizeof(value), p + 4);
                        FrodoFRFREUSetValue(value);
                        return;
                }

                while (*p && !FrodoFRFIsSpace(*p))
                        p++;
        }
}


static void FrodoFRFSetDisplayScaleValue(const char *value)
{
        if (!value || !value[0])
                return;

        if (FrodoFRFEqNoCase(value, "2") ||
            FrodoFRFEqNoCase(value, "2X") ||
            FrodoFRFEqNoCase(value, "X2"))
                FrodoFRFDisplayScale = 2;
        else if (FrodoFRFEqNoCase(value, "1") ||
                 FrodoFRFEqNoCase(value, "1X") ||
                 FrodoFRFEqNoCase(value, "X1"))
                FrodoFRFDisplayScale = 1;
}

static void FrodoFRFSetVSyncValue(const char *value)
{
        if (!value || !value[0])
                return;

        if (FrodoFRFEqNoCase(value, "1") ||
            FrodoFRFEqNoCase(value, "ON") ||
            FrodoFRFEqNoCase(value, "YES") ||
            FrodoFRFEqNoCase(value, "TRUE") ||
            FrodoFRFEqNoCase(value, "VSYNC"))
                FrodoFRFPresentVSync = 1;
        else if (FrodoFRFEqNoCase(value, "0") ||
                 FrodoFRFEqNoCase(value, "OFF") ||
                 FrodoFRFEqNoCase(value, "NO") ||
                 FrodoFRFEqNoCase(value, "FALSE") ||
                 FrodoFRFEqNoCase(value, "IMMEDIATE"))
                FrodoFRFPresentVSync = 0;
}

static int FrodoFRFValueMeansRequester(const char *value)
{
        return value && (
                FrodoFRFEqNoCase(value, "ASK") ||
                FrodoFRFEqNoCase(value, "REQUEST") ||
                FrodoFRFEqNoCase(value, "REQUESTER") ||
                FrodoFRFEqNoCase(value, "SCREENMODE") ||
                FrodoFRFEqNoCase(value, "PAL"));
}

enum {
        FRF_STARTUP_OUTPUT_WINDOWED = 0,
        FRF_STARTUP_OUTPUT_RTG = 1,
        FRF_STARTUP_OUTPUT_RGB = 2,
        FRF_STARTUP_OUTPUT_ASK = 3
};

/* FRF_CLI_OUTPUT_SELECTOR_1.0.30
 * Keep startup destinations mutually exclusive. Since the raw argument parser
 * scans left to right, the final display option on the command line wins. */
static void FrodoFRFSetStartupOutputMode(int mode)
{
        FrodoFRFStartupScreenModeRequester = 0;
        FrodoFRFStartupHardcodedPAL320 = 0;
        FrodoFRFStartupLockedRTG = 0;

        if (mode == FRF_STARTUP_OUTPUT_RTG) {
                FrodoFRFStartupLockedRTG = 1;
                FrodoFRFNativePAL320 = 0;
        } else if (mode == FRF_STARTUP_OUTPUT_RGB) {
                FrodoFRFStartupHardcodedPAL320 = 1;
                FrodoFRFNativePAL320 = 1;
                FrodoFRFDisplayScale = 1;
        } else if (mode == FRF_STARTUP_OUTPUT_ASK) {
                FrodoFRFStartupScreenModeRequester = 1;
                FrodoFRFNativePAL320 = 1;
                FrodoFRFDisplayScale = 1;
        } else {
                FrodoFRFNativePAL320 = 0;
        }
}

static int FrodoFRFSetStartupOutputValue(const char *value)
{
        if (!value || !value[0])
                return 0;

        if (FrodoFRFEqNoCase(value, "RTG") ||
            FrodoFRFEqNoCase(value, "CGX") ||
            FrodoFRFEqNoCase(value, "CYBERGFX")) {
                FrodoFRFSetStartupOutputMode(FRF_STARTUP_OUTPUT_RTG);
                return 1;
        }

        if (FrodoFRFEqNoCase(value, "RGB") ||
            FrodoFRFEqNoCase(value, "NATIVE") ||
            FrodoFRFEqNoCase(value, "PAL") ||
            FrodoFRFEqNoCase(value, "PAL320")) {
                FrodoFRFSetStartupOutputMode(FRF_STARTUP_OUTPUT_RGB);
                return 1;
        }

        if (FrodoFRFEqNoCase(value, "ASK") ||
            FrodoFRFEqNoCase(value, "REQUEST") ||
            FrodoFRFEqNoCase(value, "REQUESTER") ||
            FrodoFRFEqNoCase(value, "SCREENMODE")) {
                FrodoFRFSetStartupOutputMode(FRF_STARTUP_OUTPUT_ASK);
                return 1;
        }

        if (FrodoFRFEqNoCase(value, "WINDOW") ||
            FrodoFRFEqNoCase(value, "WINDOWED") ||
            FrodoFRFEqNoCase(value, "WORKBENCH") ||
            FrodoFRFEqNoCase(value, "OFF") ||
            FrodoFRFEqNoCase(value, "NO") ||
            FrodoFRFEqNoCase(value, "FALSE") ||
            FrodoFRFEqNoCase(value, "0")) {
                FrodoFRFSetStartupOutputMode(FRF_STARTUP_OUTPUT_WINDOWED);
                return 1;
        }

        return 0;
}


static void FrodoFRFSetPlanar16Value(const char *value)
{
        if (!value || !value[0])
                return;

        if (FrodoFRFEqNoCase(value, "1") ||
            FrodoFRFEqNoCase(value, "ON") ||
            FrodoFRFEqNoCase(value, "YES") ||
            FrodoFRFEqNoCase(value, "TRUE"))
                FrodoFRFNativePlanar16 = 1;
        else if (FrodoFRFEqNoCase(value, "0") ||
                 FrodoFRFEqNoCase(value, "OFF") ||
                 FrodoFRFEqNoCase(value, "NO") ||
                 FrodoFRFEqNoCase(value, "FALSE"))
                FrodoFRFNativePlanar16 = 0;
}


static void FrodoFRFSetDisplayEveryValue(const char *value)
{
        int n = value ? atoi(value) : 1;
        if (n < 1) n = 1;
        if (n > 8) n = 8;
        FrodoFRFDisplayEvery = n;
}

static void FrodoFRFSetDisplayEnabledValue(const char *value)
{
        if (!value || !value[0])
                return;
        if (FrodoFRFEqNoCase(value, "OFF") ||
            FrodoFRFEqNoCase(value, "NO") ||
            FrodoFRFEqNoCase(value, "FALSE") ||
            FrodoFRFEqNoCase(value, "0"))
                FrodoFRFNoDisplay = 1;
        else if (FrodoFRFEqNoCase(value, "ON") ||
                 FrodoFRFEqNoCase(value, "YES") ||
                 FrodoFRFEqNoCase(value, "TRUE") ||
                 FrodoFRFEqNoCase(value, "1"))
                FrodoFRFNoDisplay = 0;
}

static void FrodoFRFParseDisplayRawArgs(void)
{
        const char *p = FrodoStartupRawArgs;
        char value[32];

        while (*p) {
                while (FrodoFRFIsSpace(*p))
                        p++;

                if (!*p)
                        break;

                if (FrodoFRFStartsNoCase(p, "SCALE=") ||
                    FrodoFRFStartsNoCase(p, "DISPLAY_SCALE=")) {
                        const char *v = FrodoFRFStartsNoCase(p, "SCALE=")
                                      ? p + 6 : p + 14;
                        FrodoFRFCopyRawPath(value, sizeof(value), v);
                        FrodoFRFSetDisplayScaleValue(value);
                } else if (FrodoFRFStartsNoCase(p, "--scale") &&
                           FrodoFRFOptionBoundary(p[7])) {
                        FrodoFRFCopyRawPath(value, sizeof(value), p + 7);
                        FrodoFRFSetDisplayScaleValue(value);
                } else if (FrodoFRFStartsNoCase(p, "-scale") &&
                           FrodoFRFOptionBoundary(p[6])) {
                        FrodoFRFCopyRawPath(value, sizeof(value), p + 6);
                        FrodoFRFSetDisplayScaleValue(value);
                } else if ((FrodoFRFStartsNoCase(p, "X2") &&
                            FrodoFRFOptionBoundary(p[2])) ||
                           (FrodoFRFStartsNoCase(p, "--x2") &&
                            FrodoFRFOptionBoundary(p[4])) ||
                           (FrodoFRFStartsNoCase(p, "-x2") &&
                            FrodoFRFOptionBoundary(p[3]))) {
                        FrodoFRFDisplayScale = 2;
                } else if ((FrodoFRFStartsNoCase(p, "X1") &&
                            FrodoFRFOptionBoundary(p[2])) ||
                           (FrodoFRFStartsNoCase(p, "--x1") &&
                            FrodoFRFOptionBoundary(p[4])) ||
                           (FrodoFRFStartsNoCase(p, "-x1") &&
                            FrodoFRFOptionBoundary(p[3]))) {
                        FrodoFRFDisplayScale = 1;
                } else if (FrodoFRFStartsNoCase(p, "VSYNC=")) {
                        FrodoFRFCopyRawPath(value, sizeof(value), p + 6);
                        FrodoFRFSetVSyncValue(value);
                } else if (FrodoFRFStartsNoCase(p, "PRESENT=")) {
                        FrodoFRFCopyRawPath(value, sizeof(value), p + 8);
                        FrodoFRFSetVSyncValue(value);
                } else if ((FrodoFRFStartsNoCase(p, "VSYNC") &&
                            FrodoFRFOptionBoundary(p[5])) ||
                           (FrodoFRFStartsNoCase(p, "--vsync") &&
                            FrodoFRFOptionBoundary(p[7])) ||
                           (FrodoFRFStartsNoCase(p, "-vsync") &&
                            FrodoFRFOptionBoundary(p[6]))) {
                        FrodoFRFPresentVSync = 1;
                } else if ((FrodoFRFStartsNoCase(p, "NOVSYNC") &&
                            FrodoFRFOptionBoundary(p[7])) ||
                           (FrodoFRFStartsNoCase(p, "--novsync") &&
                            FrodoFRFOptionBoundary(p[9]))) {
                        FrodoFRFPresentVSync = 0;
                } else if (FrodoFRFStartsNoCase(p, "SCREENMODE=")) {
                        FrodoFRFCopyRawPath(value, sizeof(value), p + 11);
                        if (FrodoFRFValueMeansRequester(value))
                                FrodoFRFSetStartupOutputMode(FRF_STARTUP_OUTPUT_ASK);
                } else if (FrodoFRFStartsNoCase(p, "FULLSCREEN=")) {
                        FrodoFRFCopyRawPath(value, sizeof(value), p + 11);
                        FrodoFRFSetStartupOutputValue(value);
                } else if ((FrodoFRFStartsNoCase(p, "SCREENMODE") &&
                            FrodoFRFOptionBoundary(p[10])) ||
                           (FrodoFRFStartsNoCase(p, "--screenmode") &&
                            FrodoFRFOptionBoundary(p[12])) ||
                           (FrodoFRFStartsNoCase(p, "--fullscreen-requester") &&
                            FrodoFRFOptionBoundary(p[22]))) {
                        FrodoFRFSetStartupOutputMode(FRF_STARTUP_OUTPUT_ASK);
                } else if ((FrodoFRFStartsNoCase(p, "WINDOWED") &&
                            FrodoFRFOptionBoundary(p[8])) ||
                           (FrodoFRFStartsNoCase(p, "WINDOW") &&
                            FrodoFRFOptionBoundary(p[6])) ||
                           (FrodoFRFStartsNoCase(p, "--windowed") &&
                            FrodoFRFOptionBoundary(p[10]))) {
                        FrodoFRFSetStartupOutputMode(FRF_STARTUP_OUTPUT_WINDOWED);
                } else if (FrodoFRFStartsNoCase(p, "--fullscreen-rtg") &&
                           FrodoFRFOptionBoundary(p[16])) {
                        FrodoFRFSetStartupOutputMode(FRF_STARTUP_OUTPUT_RTG);
                } else if (FrodoFRFStartsNoCase(p, "--fullscreen-rgb") &&
                           FrodoFRFOptionBoundary(p[16])) {
                        FrodoFRFSetStartupOutputMode(FRF_STARTUP_OUTPUT_RGB);
                } else if (FrodoFRFStartsNoCase(p, "--fullscreen-ask") &&
                           FrodoFRFOptionBoundary(p[16])) {
                        FrodoFRFSetStartupOutputMode(FRF_STARTUP_OUTPUT_ASK);
                } else if (FrodoFRFStartsNoCase(p, "PLANAR16=")) {
                        FrodoFRFCopyRawPath(value, sizeof(value), p + 9);
                        FrodoFRFSetPlanar16Value(value);
                } else if ((FrodoFRFStartsNoCase(p, "PLANAR16") &&
                            FrodoFRFOptionBoundary(p[8])) ||
                           (FrodoFRFStartsNoCase(p, "--planar16") &&
                            FrodoFRFOptionBoundary(p[10]))) {
                        FrodoFRFNativePlanar16 = 1;
                } else if ((FrodoFRFStartsNoCase(p, "NOPLANAR16") &&
                            FrodoFRFOptionBoundary(p[10])) ||
                           (FrodoFRFStartsNoCase(p, "--noplanar16") &&
                            FrodoFRFOptionBoundary(p[12]))) {
                        FrodoFRFNativePlanar16 = 0;
                } else if ((FrodoFRFStartsNoCase(p, "PAL320") &&
                            FrodoFRFOptionBoundary(p[6])) ||
                           (FrodoFRFStartsNoCase(p, "RGB320") &&
                            FrodoFRFOptionBoundary(p[6])) ||
                           (FrodoFRFStartsNoCase(p, "NATIVE320") &&
                            FrodoFRFOptionBoundary(p[9]))) {
                        FrodoFRFNativePAL320 = 1;
                        FrodoFRFDisplayScale = 1;
                } else if ((FrodoFRFStartsNoCase(p, "PAL384") &&
                            FrodoFRFOptionBoundary(p[6])) ||
                           (FrodoFRFStartsNoCase(p, "RGB384") &&
                            FrodoFRFOptionBoundary(p[6]))) {
                        FrodoFRFNativePAL320 = 0;
                } else if (FrodoFRFStartsNoCase(p, "DISPLAYEVERY=")) {
                        FrodoFRFCopyRawPath(value, sizeof(value), p + 13);
                        FrodoFRFSetDisplayEveryValue(value);
                } else if ((FrodoFRFStartsNoCase(p, "NODISPLAY") &&
                            FrodoFRFOptionBoundary(p[9])) ||
                           (FrodoFRFStartsNoCase(p, "--nodisplay") &&
                            FrodoFRFOptionBoundary(p[11]))) {
                        FrodoFRFNoDisplay = 1;
                } else if (FrodoFRFStartsNoCase(p, "DISPLAY=")) {
                        FrodoFRFCopyRawPath(value, sizeof(value), p + 8);
                        FrodoFRFSetDisplayEnabledValue(value);
                }

                while (*p && !FrodoFRFIsSpace(*p))
                        p++;
        }
}

static void FrodoFRFREUApplyOverride(void)
{
        if (FrodoStartupREUOverride >= 0)
                ThePrefs.REUSize = FrodoStartupREUOverride;
}

static int FrodoFRFPreparePRGTempDriveCopy(const char *path)
{
        FILE *in;
        FILE *out;
        int ch;

        if (!path || !path[0])
                return 0;

        in = fopen(path, "rb");
        if (!in) {
                FrodoFRFMediaLog("PRG temp copy source open failed: ", path);
                return 0;
        }

        out = fopen("T:0", "wb");
        if (!out) {
                fclose(in);
                FrodoFRFMediaLog("PRG temp copy destination open failed: T:0", NULL);
                return 0;
        }

        while ((ch = fgetc(in)) >= 0)
                fputc(ch, out);

        fclose(out);
        fclose(in);

        strcpy(FrodoStartupPRGDirPath, "T:");
        strcpy(FrodoStartupPRGBaseName, "0");
        FrodoFRFMediaLog("PRG temp drive copy ready: T:0", NULL);
        return 1;
}

static void FrodoFRFSplitPRGPathForDrive(const char *path)
{
        const char *last_slash;
        const char *last_colon;
        const char *sep;
        int dir_len;

        FrodoStartupPRGDirPath[0] = 0;
        FrodoStartupPRGBaseName[0] = 0;
        if (!path || !path[0])
                return;

        last_slash = strrchr(path, '/');
        last_colon = strrchr(path, ':');
        sep = NULL;

        if (last_slash && last_colon)
                sep = last_slash > last_colon ? last_slash : last_colon;
        else if (last_slash)
                sep = last_slash;
        else if (last_colon)
                sep = last_colon;

        if (sep) {
                dir_len = (*sep == ':') ? (int)(sep - path) + 1 : (int)(sep - path);
                if (dir_len <= 0) {
                        strcpy(FrodoStartupPRGDirPath, ".");
                } else {
                        if (dir_len >= (int)sizeof(FrodoStartupPRGDirPath))
                                dir_len = sizeof(FrodoStartupPRGDirPath) - 1;
                        strncpy(FrodoStartupPRGDirPath, path, dir_len);
                        FrodoStartupPRGDirPath[dir_len] = 0;
                }
                strncpy(FrodoStartupPRGBaseName, sep + 1,
                        sizeof(FrodoStartupPRGBaseName) - 1);
                FrodoStartupPRGBaseName[sizeof(FrodoStartupPRGBaseName) - 1] = 0;
        } else {
                strncpy(FrodoStartupPRGDirPath, AppDirPath[0] ? AppDirPath : ".",
                        sizeof(FrodoStartupPRGDirPath) - 1);
                FrodoStartupPRGDirPath[sizeof(FrodoStartupPRGDirPath) - 1] = 0;
                strncpy(FrodoStartupPRGBaseName, path,
                        sizeof(FrodoStartupPRGBaseName) - 1);
                FrodoStartupPRGBaseName[sizeof(FrodoStartupPRGBaseName) - 1] = 0;
        }
}

static void FrodoFRFMediaApplyDriveOverride(void)
{
        if (FrodoStartupPRGPath[0]) {
                if (!FrodoFRFPreparePRGTempDriveCopy(FrodoStartupPRGPath))
                        FrodoFRFSplitPRGPathForDrive(FrodoStartupPRGPath);

                ThePrefs.DriveType[0] = DRVTYPE_DIR;
                strncpy(ThePrefs.DrivePath[0],
                        FrodoStartupPRGDirPath[0] ? FrodoStartupPRGDirPath : ".",
                        sizeof(ThePrefs.DrivePath[0]) - 1);
                ThePrefs.DrivePath[0][sizeof(ThePrefs.DrivePath[0]) - 1] = 0;
                FrodoFRFMediaLog("PRG mounted parent directory on drive 8: ",
                                 ThePrefs.DrivePath[0]);
                FrodoFRFMediaLog("PRG dir-load target basename: ",
                                 FrodoStartupPRGBaseName);
        }

        if (FrodoStartupT64Path[0]) {
                ThePrefs.DriveType[0] = DRVTYPE_T64;
                strncpy(ThePrefs.DrivePath[0], FrodoStartupT64Path,
                        sizeof(ThePrefs.DrivePath[0]) - 1);
                ThePrefs.DrivePath[0][sizeof(ThePrefs.DrivePath[0]) - 1] = 0;
        }

        if (FrodoStartupD64Path[0]) {
                ThePrefs.DriveType[0] = DRVTYPE_D64;
                strncpy(ThePrefs.DrivePath[0], FrodoStartupD64Path,
                        sizeof(ThePrefs.DrivePath[0]) - 1);
                ThePrefs.DrivePath[0][sizeof(ThePrefs.DrivePath[0]) - 1] = 0;
        }
}

static void FrodoFRFStuffKeyboardCommand(C64 *c64, const char *cmd)
{
        int n = 0;

        if (!c64 || !c64->RAM || !cmd)
                return;

        while (cmd[n] && n < 9) {
                c64->RAM[0x0277 + n] = (uint8)cmd[n];
                n++;
        }

        c64->RAM[0x0277 + n] = 0x0d;
        n++;
        c64->RAM[0x00c6] = (uint8)n;
}

static int FrodoFRFExtractBasicSYSAddress(C64 *c64,
                                           unsigned int load_addr,
                                           unsigned int end_addr,
                                           unsigned int *sys_addr)
{
        unsigned int p;
        unsigned int limit;
        unsigned int value = 0;
        int found_digit = 0;

        if (!c64 || !c64->RAM || !sys_addr)
                return 0;
        if (load_addr != 0x0801 && load_addr != 0x0800)
                return 0;

        limit = end_addr;
        if (limit > load_addr + 256)
                limit = load_addr + 256;
        if (limit > 0x10000)
                limit = 0x10000;

        for (p = load_addr; p < limit; p++) {
                if (c64->RAM[p & 0xffff] == 0x9e) {
                        p++;
                        while (p < limit && c64->RAM[p & 0xffff] == ' ')
                                p++;
                        while (p < limit &&
                               c64->RAM[p & 0xffff] >= '0' &&
                               c64->RAM[p & 0xffff] <= '9') {
                                value = value * 10 +
                                        (unsigned int)(c64->RAM[p & 0xffff] - '0');
                                found_digit = 1;
                                p++;
                        }
                        if (found_digit && value < 0x10000) {
                                *sys_addr = value;
                                return 1;
                        }
                        return 0;
                }
        }

        return 0;
}

static int FrodoFRFStartupPRGDelayCounter = 0;
static int FrodoFRFStartupPRGStage = 0;

void FrodoFRFResetStartupPRGDelay(void)
{
        FrodoFRFStartupPRGDelayCounter = 0;
        FrodoFRFStartupPRGStage = 0;
}

int FrodoFRFMaybeInjectStartupPRG(C64 *c64)
{
#ifdef FRODO_SC
        const int first_delay = 300000;
        const int load_delay = 420000;
#else
        const int first_delay = 15000;
        const int load_delay = 24000;
#endif

        if (!FrodoStartupPRGPath[0] || FrodoFRFStartupPRGStage >= 3)
                return 0;

        FrodoFRFStartupPRGDelayCounter++;

        if (FrodoFRFStartupPRGStage == 0) {
                if (FrodoFRFStartupPRGDelayCounter < first_delay)
                        return 0;

                FrodoFRFStartupPRGStage = 1;
                FrodoFRFStartupPRGDelayCounter = 0;
                if (FrodoStartupPRGBaseName[0] == '0' &&
                    FrodoStartupPRGBaseName[1] == 0) {
                        FrodoFRFStuffKeyboardCommand(c64, "LOAD\"0\",8");
                        FrodoFRFMediaLog("PRG DIRLOAD command stuffed: LOAD 0 from drive 8", NULL);
                } else {
                        FrodoFRFStuffKeyboardCommand(c64, "LOAD\"*\",8");
                        FrodoFRFMediaLog("PRG DIRLOAD command stuffed: LOAD * from drive 8", NULL);
                }
                return 1;
        }

        if (FrodoFRFStartupPRGStage == 1) {
                unsigned int sys_addr = 0;
                char cmd[16];
                char logbuf[64];

                if (FrodoFRFStartupPRGDelayCounter < load_delay)
                        return 0;

                FrodoFRFStartupPRGStage = 2;
                FrodoFRFStartupPRGDelayCounter = 0;

                if (FrodoStartupPRGAutorun) {
                        if (FrodoFRFExtractBasicSYSAddress(c64, 0x0801,
                                                          0x10000, &sys_addr)) {
                                sprintf(cmd, "SYS%u", sys_addr);
                                FrodoFRFStuffKeyboardCommand(c64, cmd);
                                sprintf(logbuf, "PRG DIRLOAD autorun command SYS%u", sys_addr);
                                FrodoFRFMediaLog(logbuf, NULL);
                        } else {
                                FrodoFRFStuffKeyboardCommand(c64, "RUN");
                                FrodoFRFMediaLog("PRG DIRLOAD autorun command RUN", NULL);
                        }
                }

                FrodoFRFStartupPRGStage = 3;
                return 1;
        }

        return 0;
}

void Frodo::ArgvReceived(int argc, char **argv)
{
        (void)argc;
        (void)argv;

        FrodoStartupSnapshotPath[0] = 0;
        FrodoStartupCartPath[0] = 0;
        FrodoStartupPRGPath[0] = 0;
        FrodoStartupT64Path[0] = 0;
        FrodoStartupD64Path[0] = 0;
        FrodoStartupPRGDirPath[0] = 0;
        FrodoStartupPRGBaseName[0] = 0;
        FrodoStartupPRGAutorun = 1;
        FrodoStartupBypassPrefs = 0;
        FrodoStartupREUOverride = -1;
        FrodoFRFDisplayScale = 1;
        FrodoFRFPresentVSync = 0;
        FrodoFRFStartupScreenModeRequester = 0;
        FrodoFRFStartupHardcodedPAL320 = 0;
        FrodoFRFStartupLockedRTG = 0;
        FrodoFRFNativePlanar16 = 0;
        FrodoFRFNativePAL320 = 0;
        FrodoFRFDisplayEvery = 1;
        FrodoFRFNoDisplay = 0;

        /* Capture before any AmigaDOS parser can consume or alter it. */
        FrodoFRFCaptureRawArgs();
        FrodoFRFParseCartRawArgs();
        FrodoFRFParseMediaRawArgs();
        FrodoFRFParseSnapshotRawArgs();
        FrodoFRFParseREURawArgs();
        FrodoFRFParseDisplayRawArgs();

#if defined(FRF_RGBFAST) || defined(FRF_RGBEXACT)
        /* Dedicated native-RGB binary: start directly in the proven low-bandwidth
         * PAL path. The requester still lets the user choose the exact monitor
         * mode, but X2, post-frame planar conversion and extra display skipping
         * are deliberately disabled. */
        FrodoFRFDisplayScale = 1;
        FrodoFRFPresentVSync = 0;
        /* FRF_CLI_OUTPUT_SELECTOR_1.0.30: no output option means a Workbench window;
         * FULLSCREEN=RTG/RGB/ASK selects a custom-screen destination. */
        FrodoFRFNativePlanar16 = 0;
        FrodoFRFDisplayEvery = 1;
        /* Preserve a command-line NODISPLAY request for bottleneck tests. */
#endif

#if FRF_ENABLE_DIAGNOSTIC_LOGS
        {
                FILE *f = FRFOpenDiagnosticLog("PROGDIR:frodo-argv.log",
                                               "frodo-argv.log", "w");
                if (f) {
                        fprintf(f, "parser=restored-GetArgStr-DIR51B\n");
                        fprintf(f, "rawargs=%s\n", FrodoStartupRawArgs);
                        fprintf(f, "snapshot=%s\n", FrodoStartupSnapshotPath);
                        fprintf(f, "cartridge=%s\n", FrodoStartupCartPath);
                        fprintf(f, "prg=%s\n", FrodoStartupPRGPath);
                        fprintf(f, "t64=%s\n", FrodoStartupT64Path);
                        fprintf(f, "d64=%s\n", FrodoStartupD64Path);
                        fprintf(f, "bypass_prefs=%d\n", FrodoStartupBypassPrefs);
                        fprintf(f, "display_scale=%d\n", FrodoFRFDisplayScale);
                        fprintf(f, "present_vsync=%d\n", FrodoFRFPresentVSync);
                        fprintf(f, "startup_screenmode_requester=%d\n", FrodoFRFStartupScreenModeRequester);
                        fprintf(f, "native_planar16=%d\n", FrodoFRFNativePlanar16);
                        fprintf(f, "native_pal320=%d\n", FrodoFRFNativePAL320);
                        fprintf(f, "display_every=%d\n", FrodoFRFDisplayEvery);
                        fprintf(f, "no_display=%d\n", FrodoFRFNoDisplay);
                        fclose(f);
                }
        }
#endif
}


/*
 *  Arguments processed, run emulation
 */

void Frodo::ReadyToRun(void)
{
        FrodoFRFTrace("MAIN ReadyToRun enter");
        int frf_start_emulator = 0;

        getcwd(AppDirPath, 256);

        if (!prefs_path[0])
                strcpy(prefs_path, "Frodo Prefs");
        ThePrefs.Load(prefs_path);

#if defined(FRF_RGBFAST) || defined(FRF_RGBEXACT)
        /* Match MagiC64's practical speed profile: one frame per PAL refresh,
         * instruction/scanline emulation, and high-level IEC instead of a
         * second cycle-emulated 1541 CPU. */
        ThePrefs.SkipFrames = 1;
        ThePrefs.LimitSpeed = true;
        ThePrefs.Emul1541Proc = false;
#endif

        FrodoFRFREUApplyOverride();
        FrodoFRFMediaApplyDriveOverride();

        if (FrodoStartupCartPath[0] || FrodoStartupPRGPath[0] ||
            FrodoStartupT64Path[0] || FrodoStartupD64Path[0])
                FrodoStartupBypassPrefs = 1;

        if (FrodoStartupBypassPrefs || FrodoStartupSnapshotPath[0] ||
            (FrodoFRFStartupScreenModeRequester ||
             FrodoFRFStartupHardcodedPAL320 ||
             FrodoFRFStartupLockedRTG))
                frf_start_emulator = 1;
        else
                frf_start_emulator = ThePrefs.ShowEditor(TRUE, prefs_path);

        if (frf_start_emulator) {
                TheC64 = new C64;

                if (load_rom_files()) {
                        /*
                         * Restore the proven two-stage cartridge activation.
                         * The first load installs the boot mapping into the old
                         * Frodo memory arrays; the second reload/reset leaves the
                         * cartridge active immediately before C64::Run().
                         */
                        if (FrodoStartupCartPath[0]) {
                                if (FRFEasyFlashLoadCRT(FrodoStartupCartPath)) {
                                        FRFEasyFlashInstallBoot(TheC64->RAM,
                                                                TheC64->Basic,
                                                                TheC64->Kernal);
                                        TheC64->Reset();
                                }
                        }

                        if (FrodoStartupPRGPath[0]) {
                                FrodoFRFResetStartupPRGDelay();
                                FrodoFRFMediaLog("PRG DIRLOAD armed: ",
                                                 FrodoStartupPRGPath);
                        }

                        if (FrodoStartupCartPath[0]) {
                                if (FRFEasyFlashLoadCRT(FrodoStartupCartPath))
                                        TheC64->Reset();
                        }

                        TheC64->Run();
                }

                delete TheC64;
                TheC64 = NULL;
        }
}


void Frodo::RunPrefsEditor(void)
{
	Prefs *prefs = new Prefs(ThePrefs);
	if (prefs->ShowEditor(FALSE, prefs_path)) {
		TheC64->NewPrefs(prefs);
		ThePrefs = *prefs;
	}
	delete prefs;
}

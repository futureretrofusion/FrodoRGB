/* Modified 2026-06-21 by Future Retro Fusion for FRF 2026 Frodo RTG. */
#include <proto/cybergraphics.h>
#include <cybergraphx/cybergraphics.h>
#include <exec/libraries.h>
#include <stdlib.h>
#include <stdio.h>
#include <graphics/displayinfo.h>
#include <intuition/screens.h>
#include "FRFBuildConfig.h"
#include "FrodoFRFTrace.h"
#include "FRFDiagnostics.h"

/*
 *  Display_Amiga.i - C64 graphics display, emulator window handling,
 *                    Amiga specific stuff
 *
 *  Frodo (C) 1994-1997,2002 Christian Bauer
 */

#include <exec/types.h>
#include <devices/inputevent.h>
#include <exec/memory.h>
#include <intuition/intuition.h>
#include <libraries/gadtools.h>
#include <libraries/asl.h>
#include <proto/exec.h>
#include <proto/graphics.h>
#include <proto/intuition.h>
#include <proto/dos.h>
#include <proto/gadtools.h>
#include <utility/tagitem.h>
#include <proto/diskfont.h>
#include <proto/asl.h>

#include "C64.h"
#include "VIC.h"
#include "SAM.h"
#include "Version.h"


/*
  C64 keyboard matrix:

    Bit 7   6   5   4   3   2   1   0
  0    CUD  F5  F3  F1  F7 CLR RET DEL
  1    SHL  E   S   Z   4   A   W   3
  2     X   T   F   C   6   D   R   5
  3     V   U   H   B   8   G   Y   7
  4     N   O   K   M   0   J   I   9
  5     ,   @   :   .   -   L   P   +
  6     /   ^   =  SHR HOM  ;   *   
  7    R/S  Q   C= SPC  2  CTL  <-  1
*/


/*
  Tables for key translation
  Bit 0..2: row/column in C64 keyboard matrix
  Bit 3   : implicit shift
  Bit 5   : joystick emulation (bit 0..4: mask)
*/

const int key_byte[128] = {
	 7,  7,  7,  1,  1,   2,   2,   3,
	 3,  4,  4,  5,  5,   6,  -1,0x30,
	 7,  1,  1,  2,  2,   3,   3,   4,
	 4,  5,  5,  6, -1,0x26,0x22,0x2a,
	 1,  1,  2,  2,  3,   3,   4,   4,
	 5,  5,  6,  6, -1,0x24,0x30,0x28,
	 6,  1,  2,  2,  3,   3,   4,   4,
	 5,  5,  6, -1, -1,0x25,0x21,0x29,
	 7,  0, -1,  0,  0,   7,   6,  -1,
	-1, -1, -1, -1,8+0,   0,   0, 8+0,
	 0,8+0,  0,8+0,  0, 8+0,   0, 8+0,
	-1, -1,  6,  6, -1,  -1,  -1,  -1,
	 1,  6,  1,  7,  7,   7,   7,  -1,
	-1, -1, -1, -1, -1,  -1,  -1,  -1,
	-1, -1, -1, -1, -1,  -1,  -1,  -1,
	-1, -1, -1, -1, -1,  -1,  -1,  -1
};

const int key_bit[128] = {
	 1,  0,  3,  0,  3,  0,  3,  0,
	 3,  0,  3,  0,  3,  0, -1, -1,
	 6,  1,  6,  1,  6,  1,  6,  1,
	 6,  1,  6,  1, -1, -1, -1, -1,
	 2,  5,  2,  5,  2,  5,  2,  5,
     2,  5,  2,  5, -1, -1, -1, -1,
	 6,  4,  7,  4,  7,  4,  7,  4,
	 7,  4,  7, -1, -1, -1, -1, -1,
	 4,  0, -1,  1,  1,  7,  3, -1,
	-1, -1, -1, -1,  7,  7,  2,  2,
	 4,  4,  5,  5,  6,  6,  3,  3,
	-1, -1,  6,  5, -1, -1, -1, -1,
	 7,  4,  7,  2,  5,  5,  5, -1,
	-1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1
};


/*
 *  Menu definitions
 */

const struct NewMenu new_menus[] = {
	NM_TITLE, "FRF Frodo RTG", NULL, 0, 0, NULL,
	NM_ITEM, "About FRF Frodo RTG...", NULL, 0, 0, NULL,
	NM_ITEM, NM_BARLABEL, NULL, 0, 0, NULL,
	NM_ITEM, "Preferences...", "P", 0, 0, NULL,
	NM_ITEM, NM_BARLABEL, NULL, 0, 0, NULL,
	NM_ITEM, "Reset C64", NULL, 0, 0, NULL,
	NM_ITEM, "Insert next disk", "D", 0, 0, NULL,
	NM_ITEM, "SAM...", "M", 0, 0, NULL,
	NM_ITEM, NM_BARLABEL, NULL, 0, 0, NULL,
	NM_ITEM, "Load snapshot...", "O", 0, 0, NULL,
	NM_ITEM, "Save snapshot...", "S", 0, 0, NULL,
	NM_ITEM, NM_BARLABEL, NULL, 0, 0, NULL,
	NM_ITEM, "Quit FRF Frodo RTG", "Q", 0, 0, NULL,
	NM_END, NULL, NULL, 0, 0, NULL
};


/*
 *  Font attributes
 */

const struct TextAttr led_font_attr = {
	"Helvetica.font", 11, FS_NORMAL, 0
};

const struct TextAttr speedo_font_attr = {
	"Courier.font", 11, FS_NORMAL, 0
};


/*
 *  Display constructor: Create window/screen
 */


/*
 * FRF 2026:
 * Separate pause hotkey state.
 * Ctrl-P / Amiga-P toggles Pause/Resume only.
 * It does NOT open the prefs GUI.
 */


/* CRT_FIX18_EASYCART_INPUT_GLOBALS */


/* CRT_FIX23_SEPARATED_LAUNCH_GLOBALS */
static int FrodoEasyCartF1Pulse = 0;
static int FrodoEasyCartReturnPulse = 0;
static int FrodoEasyCartFire2Pulse = 0;

static int FrodoEasyCartF1Latch23 = 0;
static int FrodoEasyCartReturnLatch23 = 0;
static int FrodoEasyCartFireLatch23 = 0;

static void FrodoEasyCartFix23Log(const char *msg)
{
#if !FRF_ENABLE_DIAGNOSTIC_LOGS
        (void)msg;
        return;
#endif
        FILE *f = FRFOpenDiagnosticLog("PROGDIR:frodo-easyflash.log", "frodo-easyflash.log", "a");
        if (!f)
                return;

        fprintf(f, "%s\n", msg ? msg : "(null)");
        fclose(f);
}

static int FrodoEasyCartF1Frames = 0;
static int FrodoEasyCartReturnFrames = 0;
static int FrodoEasyCartFire2Frames = 0;

static int FrodoEasyCartF1Latch = 0;
static int FrodoEasyCartReturnLatch = 0;
static int FrodoEasyCartFireLatch = 0;

static void FrodoEasyCartInputLog(const char *msg)
{
#if !FRF_ENABLE_DIAGNOSTIC_LOGS
        (void)msg;
        return;
#endif
        FILE *f = FRFOpenDiagnosticLog("PROGDIR:frodo-easyflash.log", "frodo-easyflash.log", "a");

        if (!f)
                return;

        fprintf(f, "%s\n", msg ? msg : "(null)");
        fclose(f);
}

static int FrodoAmigaPauseHotkeyActive = 0;


/*
 * FRF 2026:
 * Auto-pause when Frodo loses window focus.
 * This mimics UAE-style behaviour so another instance can take focus/audio.
 */
static int FrodoAmigaFocusAutoPaused = 0;

/*
 * FRF 2026:
 * Suppress focus auto-pause briefly during fullscreen transitions.
 * Opening/closing a custom screen generates inactive/active events that
 * can leave AHI paused after returning to the Workbench window.
 */
static int FrodoAmigaSuppressFocusAutoPause = 0;

/* Parsed in main_Amiga.i before the C64/display objects are constructed. */
extern int FrodoFRFDisplayScale;
extern int FrodoFRFPresentVSync;
extern int FrodoFRFStartupScreenModeRequester;
extern int FrodoFRFStartupHardcodedPAL320;
extern int FrodoFRFStartupLockedRTG; /* FRF_CLI_OUTPUT_SELECTOR_1.0.30 */ /* FRF_RTG_BOTTOM_CLEAN_PAL_AUTO_1.0.29 */
extern int FrodoFRFNativePlanar16;
extern int FrodoFRFNativePAL320;
extern int FrodoFRFDisplayEvery;
extern int FrodoFRFNoDisplay;

static int FRFScreenIsCyberGfxMode(struct Screen *scr);

static int FRFOutputScale(void)
{
        return FrodoFRFDisplayScale == 2 ? 2 : 1;
}

static LONG FRFOutputWidth(void)
{
        return (LONG)DISPLAY_X * FRFOutputScale();
}

static LONG FRFOutputHeight(void)
{
        return (LONG)DISPLAY_Y * FRFOutputScale();
}

static LONG FRFRequesterWidth(void)
{
        return (FrodoFRFNativePAL320 && FRFOutputScale() == 1) ? 320 : FRFOutputWidth();
}

static LONG FRFRequesterHeight(void)
{
        return (FrodoFRFNativePAL320 && FRFOutputScale() == 1) ? 256 : FRFOutputHeight();
}

static LONG FRFPresentedWidthForScreen(struct Screen *scr)
{
        if (scr && FrodoFRFNativePAL320 && FRFOutputScale() == 1 &&
            !FRFScreenIsCyberGfxMode(scr))
                return 320;
        return FRFOutputWidth();
}

static LONG FRFPresentedHeightForScreen(struct Screen *scr)
{
        if (scr && FrodoFRFNativePAL320 && FRFOutputScale() == 1 &&
            !FRFScreenIsCyberGfxMode(scr))
                return 256;
        return FRFOutputHeight();
}


#define FRF_FRODO_IDCMP_FLAGS (IDCMP_CLOSEWINDOW | IDCMP_RAWKEY | IDCMP_ACTIVEWINDOW | IDCMP_INACTIVEWINDOW | IDCMP_MENUPICK | IDCMP_REFRESHWINDOW)

/*
 * FRF 2026:
 * Split fullscreen hotkeys.
 *
 * E-UAE style:
 *   - direct fixed RTG mode on Ctrl+LAlt+U
 *   - ASL RTG/native requester on Ctrl+LAlt+LAmiga+U
 *   - open the selected custom screen
 *   - open a borderless backdrop window on it
 *   - switch Frodo drawing/input to that window
 */
enum {
        FRF_FULLSCREEN_PENDING_NONE = 0,
        FRF_FULLSCREEN_PENDING_LOCKED_RTG = 1,
        FRF_FULLSCREEN_PENDING_REQUESTER = 2,
        FRF_FULLSCREEN_PENDING_HARDCODED_PAL320 = 3 /* FRF_RTG_BOTTOM_CLEAN_PAL_AUTO_1.0.29 */
};

static int FRFFullscreenPendingMode = FRF_FULLSCREEN_PENDING_NONE;
static int FRFAslFullscreenActive = 0;
static struct Screen *FRFAslFullscreenScreen = NULL;
static struct Window *FRFAslFullscreenWindow = NULL;
static struct Window *FRFAslWindowedWindow = NULL;
static struct Screen *FRFC64PenScreen = NULL;
/* Only native indexed PAL screens require a new pen set.  RTG fullscreen
 * keeps the proven windowed C64 pen mapping unchanged. */
static int FRFFullscreenNativePensActive = 0;
/* Native PAL uses exact palette indexes 0..15 rather than allocated pens. */
static int FRFC64PensAreFixedNative = 0;

static void FRFSwitchC64Pens(struct Screen *scr, LONG *pens);
static int FRFInstallNativeFixed16Palette(struct Screen *scr, LONG *pens);
static void FRFPlanar16Invalidate(void);
static void FRFPlanar16Shutdown(void);
static void FRFMagic64LineShutdown(void);


/* FRF_FULLSCREEN_CENTER_BLACK
 * Fullscreen custom screen is usually slightly larger than the C64 image
 * (known-good mode is 400x300 while DISPLAY_X/Y is 384x272).
 * Keep everything outside the emulated C64 viewport black and draw the
 * viewport centered.  The LED/status strip is windowed-only.
 */
static LONG FRFFullscreenViewX = 0;
static LONG FRFFullscreenViewY = 0;
static LONG FRFFullscreenScreenW = DISPLAY_X;
static LONG FRFFullscreenScreenH = DISPLAY_Y;

static void FRFSetFullscreenCenteredViewport(struct Screen *scr)
{
        if (!scr) {
                FRFFullscreenScreenW = FRFOutputWidth();
                FRFFullscreenScreenH = FRFOutputHeight();
                FRFFullscreenViewX = 0;
                FRFFullscreenViewY = 0;
                return;
        }

        {
                LONG pw = FRFPresentedWidthForScreen(scr);
                LONG ph = FRFPresentedHeightForScreen(scr);
                FRFFullscreenScreenW = scr->Width;
                FRFFullscreenScreenH = scr->Height;
                FRFFullscreenViewX = (scr->Width > pw) ? ((scr->Width - pw) / 2) : 0;
                FRFFullscreenViewY = (scr->Height > ph) ? ((scr->Height - ph) / 2) : 0;
        }
}

static void FRFClearFullscreenBlack(struct Screen *scr)
{
        if (!scr)
                return;

        /* Pen 0 is forced black, then the whole custom screen/backdrop is cleared. */
        SetRGB32(&scr->ViewPort, 0, 0, 0, 0);
        SetAPen(&scr->RastPort, 0);
        SetBPen(&scr->RastPort, 0);
        RectFill(&scr->RastPort, 0, 0, scr->Width - 1, scr->Height - 1);
}




/*
 * FRF 2026:
 * Locked RTG fullscreen mode for Ctrl+LAlt+U.
 *
 * IMPORTANT:
 * Do NOT read frodo-screenmode.cfg here.
 * That file is a live log/cache and gets overwritten by startup/windowed mode.
 *
 * Direct Ctrl+LAlt+U uses the proven fixed RTG display ID or the
 * existing legacy frodo-fullscreen.cfg override.
 *
 */

/*
 * FRF 2026:
 * Locked RTG fullscreen mode for Ctrl+LAlt+U.
 *
 * IMPORTANT:
 * Do NOT read frodo-screenmode.cfg here.
 * That file is a live log/cache and gets overwritten by startup/windowed mode.
 *
 * Direct Ctrl+LAlt+U uses the proven fixed RTG display ID or the
 * existing legacy frodo-fullscreen.cfg override.
 *
 */
static ULONG FRFReadLockedFullscreenDisplayID(void)
{
        FILE *f;
        char line[160];

        /*
         * Proven fixed RTG mode used before the requester split.  Keep the
         * legacy frodo-fullscreen.cfg override, but do not let requester
         * selections or X1/X2 cache files replace this direct mode.
         */
        ULONG id = 0x502e1203;

        f = fopen("PROGDIR:frodo-fullscreen.cfg", "r");
        if (!f)
                f = fopen("frodo-fullscreen.cfg", "r");

        if (!f)
                return id;

        while (fgets(line, sizeof(line), f)) {
                if (!strncmp(line, "DISPLAYID=", 10)) {
                        unsigned int tmp = 0;
                        if (sscanf(line + 10, "%x", &tmp) == 1)
                                id = (ULONG)tmp;
                }
        }

        fclose(f);
        return id;
}



static struct Screen *FRFOpenLockedFullscreenScreen(void)
{
        ULONG mode_id = FRFReadLockedFullscreenDisplayID();
        struct Screen *scr;

        FrodoFRFTrace("CTRLALTU locked RTG direct open begin");

        /*
         * Do not force 1280x720. Do not read windowed cfg.
         * Do not open the ASL requester.
         */
        scr = OpenScreenTags(NULL,
                SA_DisplayID, mode_id,
                SA_Quiet, TRUE,
                SA_ShowTitle, FALSE,
                SA_AutoScroll, TRUE,
                TAG_DONE);

        if (scr) {
                FrodoFRFTrace("CTRLALTU locked RTG OpenScreenTags ok");
                return scr;
        }

        FrodoFRFTrace("CTRLALTU locked RTG OpenScreenTags failed");
        return NULL;
}



/*
 * FRF_RTG_BOTTOM_CLEAN_PAL_AUTO_1.0.29
 *
 * Open the standard native PAL low-resolution display directly. The explicit
 * width/height/depth tags prevent a saved RTG mode or ASL preference from
 * changing the RGB binary's presentation. If this mode is unavailable, the
 * caller falls back to the existing requester.
 */
static struct Screen *FRFOpenHardcodedPAL320Screen(void)
{
        const ULONG display_id = 0x00021000UL; /* PAL_MONITOR_ID | LORES_KEY */
        struct Screen *scr;

        FrodoFRFTrace("startup hardcoded PAL320 open begin");
        scr = OpenScreenTags(NULL,
                SA_DisplayID, display_id,
                SA_Width, 320,
                SA_Height, 256,
                SA_Depth, 4,
                SA_Overscan, OSCAN_STANDARD,
                SA_AutoScroll, FALSE,
                SA_ShowTitle, FALSE,
                SA_Quiet, TRUE,
                SA_Behind, FALSE,
                SA_PubName, (ULONG)"FRFFrodoRGB",
                SA_SharePens, TRUE,
                SA_Draggable, FALSE,
                SA_Interleaved, TRUE,
                TAG_DONE);

        if (scr != NULL)
                FrodoFRFTrace("startup hardcoded PAL320 OpenScreenTags ok");
        else
                FrodoFRFTrace("startup hardcoded PAL320 failed; requester fallback");
        return scr;
}


static struct Screen *FRFAskAndOpenScreen(void)
{
        struct ScreenModeRequester *req;
        struct Screen *scr;
        ULONG display_id;
        LONG screen_w;
        LONG screen_h;
        LONG depth;
        UWORD overscan;
        BOOL autoscroll;

        FrodoFRFTrace("CTRLALTAMIGA requester mode begin");

        req = (struct ScreenModeRequester *)AllocAslRequest(ASL_ScreenModeRequest, NULL);
        if (req == NULL) {
                FrodoFRFTrace("CTRLU ASL AllocAslRequest failed");
                return NULL;
        }

        display_id = INVALID_ID;
        screen_w = FRFRequesterWidth();
        screen_h = FRFRequesterHeight();
        depth = FrodoFRFNativePAL320 ? 4 : 8;
        overscan = OSCAN_STANDARD;
        autoscroll = TRUE;

        if (AslRequestTags(req,
                ASLSM_TitleText, (ULONG)"Select FRF Frodo fullscreen mode (RTG or RGB PAL)",
                ASLSM_InitialDisplayID, 0,
                ASLSM_InitialDisplayDepth, FrodoFRFNativePAL320 ? 4 : 8,
                ASLSM_InitialDisplayWidth, FRFRequesterWidth(),
                ASLSM_InitialDisplayHeight, FRFRequesterHeight(),
                ASLSM_MinWidth, FRFRequesterWidth(),
                ASLSM_MinHeight, FRFRequesterHeight(),
                ASLSM_DoWidth, TRUE,
                ASLSM_DoHeight, TRUE,
                ASLSM_DoDepth, TRUE,
                ASLSM_DoOverscanType, TRUE,
                ASLSM_PropertyFlags, 0,
                ASLSM_PropertyMask, DIPF_IS_DUALPF | DIPF_IS_PF2PRI,
                TAG_DONE)) {
                screen_w = req->sm_DisplayWidth;
                screen_h = req->sm_DisplayHeight;
                depth = req->sm_DisplayDepth;
                display_id = req->sm_DisplayID;
                overscan = req->sm_OverscanType;
                autoscroll = req->sm_AutoScroll;
        } else {
                FrodoFRFTrace("CTRLALTAMIGA requester cancelled");
                FreeAslRequest(req);
                return NULL;
        }

        FreeAslRequest(req);

        FrodoFRFTrace("CTRLALTAMIGA opening selected screen");

        scr = OpenScreenTags(NULL,
                SA_DisplayID, display_id,
                SA_Width, screen_w,
                SA_Height, screen_h,
                SA_Depth, depth,
                SA_Overscan, overscan,
                SA_AutoScroll, autoscroll,
                SA_ShowTitle, FALSE,
                SA_Quiet, TRUE,
                SA_Behind, FALSE,
                SA_PubName, (ULONG)"FRFFrodo",
                SA_SharePens, TRUE,
                SA_Draggable, TRUE,
                SA_Interleaved, TRUE,
                TAG_DONE);

        if (scr == NULL) {
                FrodoFRFTrace("CTRLU ASL OpenScreenTags failed");
                return NULL;
        }

        FrodoFRFTrace("CTRLU ASL OpenScreenTags ok");
        return scr;
}


static void FRFToggleAslFullscreen(struct Window **window_ptr,
        struct Screen **screen_ptr,
        struct RastPort **rp_ptr,
        int *xo_ptr,
        int *yo_ptr,
        LONG *pens,
        int requested_mode,
        C64 *c64)
{
        struct Screen *scr;
        struct Window *win;

        FrodoFRFTrace(requested_mode == FRF_FULLSCREEN_PENDING_HARDCODED_PAL320 ?
                "startup hardcoded PAL320 toggle requested" :
                (requested_mode == FRF_FULLSCREEN_PENDING_REQUESTER ?
                 "CTRLALTAMIGA requester toggle requested" :
                 "CTRLALTU locked RTG toggle requested"));

        if (window_ptr == NULL || *window_ptr == NULL)
                return;

        if (!FRFAslFullscreenActive) {
                FRFAslWindowedWindow = *window_ptr;

                if (requested_mode == FRF_FULLSCREEN_PENDING_HARDCODED_PAL320) {
                        scr = FRFOpenHardcodedPAL320Screen();
                        if (scr == NULL)
                                scr = FRFAskAndOpenScreen();
                } else if (requested_mode == FRF_FULLSCREEN_PENDING_REQUESTER)
                        scr = FRFAskAndOpenScreen();
                else
                        scr = FRFOpenLockedFullscreenScreen();

                if (scr != NULL &&
                    requested_mode == FRF_FULLSCREEN_PENDING_LOCKED_RTG &&
                    !FRFScreenIsCyberGfxMode(scr)) {
                        static char rtg_msg[] =
                                "The saved direct fullscreen mode is not an RTG mode.\n"
                                "Use Ctrl+LAlt+LAmiga+U and choose an RTG mode first.";
                        static char rtg_ok[] = "OK";

                        FrodoFRFTrace("locked fullscreen mode rejected because it is not RTG");
                        CloseScreen(scr);
                        scr = NULL;
                        ShowRequester(rtg_msg, rtg_ok, NULL);
                }

                if (scr != NULL &&
                    requested_mode == FRF_FULLSCREEN_PENDING_REQUESTER &&
                    !FRFScreenIsCyberGfxMode(scr) &&
                    scr->RastPort.BitMap != NULL &&
                    scr->RastPort.BitMap->Depth < 4) {
                        static char depth_msg[] =
                                "Native RGB fullscreen requires at least 4 bitplanes (16 colours).";
                        static char depth_ok[] = "OK";

                        FrodoFRFTrace("requester native screen rejected below 4 bitplanes");
                        CloseScreen(scr);
                        scr = NULL;
                        ShowRequester(depth_msg, depth_ok, NULL);
                }

                if (scr != NULL &&
                    (scr->Width < FRFPresentedWidthForScreen(scr) ||
                     scr->Height < FRFPresentedHeightForScreen(scr))) {
                        static char size_msg[] =
                                "The fixed fullscreen mode is too small for the selected scale.\n"
                                "Use Ctrl+LAlt+LAmiga+U to choose a suitable mode.";
                        static char ok_text[] = "OK";

                        FrodoFRFTrace("fullscreen mode too small for selected scale");
                        CloseScreen(scr);
                        scr = NULL;

                        if (requested_mode == FRF_FULLSCREEN_PENDING_LOCKED_RTG)
                                ShowRequester(size_msg, ok_text, NULL);
                }

                if (scr == NULL)
                        return;

                win = OpenWindowTags(NULL,
                        WA_CustomScreen, (ULONG)scr,
                        WA_Left, 0,
                        WA_Top, 0,
                        WA_Width, scr->Width,
                        WA_Height, scr->Height,
                        WA_Borderless, TRUE,
                        WA_Backdrop, TRUE,
                        WA_Activate, TRUE,
                        WA_RMBTrap, TRUE,
                        WA_ReportMouse, TRUE,
                        WA_IDCMP, FRF_FRODO_IDCMP_FLAGS,
                        TAG_DONE);

                if (win == NULL) {
                        FrodoFRFTrace("fullscreen OpenWindowTags failed");
                        CloseScreen(scr);
                        return;
                }

                /* Keep the established RTG colour path unchanged.  Only a
                 * native indexed screen requires pens from the selected
                 * screen's ColorMap.  Reinitialise the VIC colour table after
                 * changing pen numbers so the chunky framebuffer and pen map
                 * remain in agreement. */
                FRFFullscreenNativePensActive = 0;
                if (!FRFScreenIsCyberGfxMode(scr)) {
                        if (FRFInstallNativeFixed16Palette(scr, pens)) {
                                if (c64 != NULL && c64->TheVIC != NULL)
                                        c64->TheVIC->ReInitColors();
                                FRFFullscreenNativePensActive = 1;
                                FRFPlanar16Invalidate();
                                FrodoFRFTrace("native PAL fixed 16-colour palette installed");
                        }
                } else {
                        FrodoFRFTrace("RTG fullscreen retaining proven windowed C64 pen mapping");
                }

                FRFSetFullscreenCenteredViewport(scr);
                FRFClearFullscreenBlack(scr);

                FRFAslFullscreenScreen = scr;
                FRFAslFullscreenWindow = win;

                *window_ptr = win;
                if (screen_ptr)
                        *screen_ptr = scr;
                if (rp_ptr)
                        *rp_ptr = win->RPort;
                if (xo_ptr)
                        *xo_ptr = (int)FRFFullscreenViewX;
                if (yo_ptr)
                        *yo_ptr = (int)FRFFullscreenViewY;

                ScreenToFront(scr);
                WindowToFront(win);
                ActivateWindow(win);

                FRFAslFullscreenActive = 1;
                FrodoFRFTrace(requested_mode == FRF_FULLSCREEN_PENDING_REQUESTER ?
                        "requester fullscreen active" :
                        "locked RTG fullscreen active");
        } else {
                FrodoFRFTrace("fullscreen returning windowed");

                if (FRFAslWindowedWindow != NULL) {
                        /* RTG fullscreen never changed pens.  Native PAL did,
                         * so restore the windowed screen's pens before closing
                         * the native screen and reinitialise VIC colours. */
                        if (FRFFullscreenNativePensActive) {
                                FRFSwitchC64Pens(FRFAslWindowedWindow->WScreen, pens);
                                if (c64 != NULL && c64->TheVIC != NULL)
                                        c64->TheVIC->ReInitColors();
                                FRFFullscreenNativePensActive = 0;
                                FRFPlanar16Invalidate();
                                FrodoFRFTrace("windowed pens restored and VIC colours reinitialised");
                        }

                        *window_ptr = FRFAslWindowedWindow;
                        if (screen_ptr)
                                *screen_ptr = FRFAslWindowedWindow->WScreen;
                        if (rp_ptr)
                                *rp_ptr = FRFAslWindowedWindow->RPort;
                        if (xo_ptr)
                                *xo_ptr = FRFAslWindowedWindow->BorderLeft;
                        if (yo_ptr)
                                *yo_ptr = FRFAslWindowedWindow->BorderTop;
                }

                FRFMagic64LineShutdown();

                if (FRFAslFullscreenWindow != NULL) {
                        CloseWindow(FRFAslFullscreenWindow);
                        FRFAslFullscreenWindow = NULL;
                }

                if (FRFAslFullscreenScreen != NULL) {
                        CloseScreen(FRFAslFullscreenScreen);
                        FRFAslFullscreenScreen = NULL;
                }

                if (*window_ptr != NULL) {
                        WindowToFront(*window_ptr);
                        ActivateWindow(*window_ptr);
                }

                FRFAslFullscreenActive = 0;
                FRFSetFullscreenCenteredViewport(NULL);
                FrodoFRFTrace("fullscreen windowed active");
        }
}


#ifndef RECTFMT_RGB
#define RECTFMT_RGB 0
#endif

/*
 * FRF 2026:
 * RTG true-colour C64 palette output.
 *
 * Old path:
 *   C64 colour -> Workbench/custom-screen pen -> WritePixelArray8()
 *
 * New RTG path:
 *   C64 colour index -> fixed C64 RGB palette -> WritePixelArray()
 */
struct Library *CyberGfxBase = NULL;
static int FRFRTGDirectRGB = 0;
static UBYTE *FRFRTGBuf24 = NULL;
static LONG FRFRTGBufBytes = 0;
static UBYTE *FRFScaledBuf8 = NULL;
static LONG FRFScaledBuf8Bytes = 0;
static UBYTE FRFPenToC64[256];

static const UBYTE FRF_C64_RGB[16][3] = {
        {0x00, 0x00, 0x00},
        {0xff, 0xff, 0xff},
        {0x81, 0x33, 0x38},
        {0x75, 0xce, 0xc8},
        {0x8e, 0x3c, 0x97},
        {0x56, 0xac, 0x4d},
        {0x2e, 0x2c, 0x9b},
        {0xed, 0xf1, 0x71},
        {0x8e, 0x50, 0x29},
        {0x55, 0x38, 0x00},
        {0xc4, 0x6c, 0x71},
        {0x4a, 0x4a, 0x4a},
        {0x7b, 0x7b, 0x7b},
        {0xa9, 0xff, 0x9f},
        {0x70, 0x6d, 0xeb},
        {0xb2, 0xb2, 0xb2}
};

static int FRFEnsureCyberGfx(void)
{
        if (CyberGfxBase != NULL)
                return 1;

        CyberGfxBase = OpenLibrary("cybergraphics.library", 40);
        if (CyberGfxBase == NULL) {
                FrodoFRFTrace("FRF RTG: cybergraphics.library open failed");
                return 0;
        }

        FrodoFRFTrace("FRF RTG: cybergraphics.library opened");
        return 1;
}

static int FRFScreenIsCyberGfxMode(struct Screen *scr)
{
        if (scr == NULL || scr->RastPort.BitMap == NULL)
                return 0;
        if (!FRFEnsureCyberGfx())
                return 0;
        return GetCyberMapAttr(scr->RastPort.BitMap, CYBRMATTR_ISCYBERGFX) ? 1 : 0;
}


static int FRFScreenIsRTGTrueColor(struct RastPort *rp)
{
        LONG is_cgx;
        LONG depth;

        if (rp == NULL || rp->BitMap == NULL)
                return 0;

        if (!FRFEnsureCyberGfx())
                return 0;

        is_cgx = GetCyberMapAttr(rp->BitMap, CYBRMATTR_ISCYBERGFX);
        depth = GetCyberMapAttr(rp->BitMap, CYBRMATTR_DEPTH);

        return (is_cgx && depth > 8);
}

static void FRFLogScreenMode(struct Screen *scr, struct RastPort *rp, const char *tag)
{
#if !FRF_ENABLE_DIAGNOSTIC_LOGS
        (void)scr;
        (void)rp;
        (void)tag;
        return;
#else
        FILE *f;
        ULONG did = INVALID_ID;
        LONG depth = 0;
        LONG is_cgx = 0;

        if (scr != NULL)
                did = GetVPModeID(&scr->ViewPort);

        if (rp != NULL && rp->BitMap != NULL) {
                depth = rp->BitMap->Depth;
                if (FRFEnsureCyberGfx())
                        is_cgx = GetCyberMapAttr(rp->BitMap, CYBRMATTR_ISCYBERGFX);
        }

        f = FRFOpenDiagnosticLog("PROGDIR:frodo-screenmode.log", "frodo-screenmode.log", "a");

        if (f) {
                fprintf(f, "[%s]\n", tag ? tag : "screen");
                fprintf(f, "DISPLAYID=0x%08lx\n", (unsigned long)did);
                fprintf(f, "WIDTH=%ld\n", scr ? (long)scr->Width : 0L);
                fprintf(f, "HEIGHT=%ld\n", scr ? (long)scr->Height : 0L);
                fprintf(f, "DEPTH=%ld\n", (long)depth);
                fprintf(f, "CYBERGFX=%ld\n", (long)is_cgx);
                fprintf(f, "RTG_DIRECT_RGB=%ld\n", (long)FRFRTGDirectRGB);
                fprintf(f, "DISPLAY_SCALE=%ld\n", (long)FRFOutputScale());
                fprintf(f, "PRESENT_VSYNC=%ld\n\n", (long)FrodoFRFPresentVSync);
                fclose(f);
        }

        f = FRFOpenDiagnosticLog("PROGDIR:frodo-screenmode.cfg", "frodo-screenmode.cfg", "w");

        if (f) {
                fprintf(f, "DISPLAYID=0x%08lx\n", (unsigned long)did);
                fprintf(f, "WIDTH=%ld\n", scr ? (long)scr->Width : 0L);
                fprintf(f, "HEIGHT=%ld\n", scr ? (long)scr->Height : 0L);
                fprintf(f, "DEPTH=%ld\n", (long)depth);
                fprintf(f, "CYBERGFX=%ld\n", (long)is_cgx);
                fclose(f);
        }
#endif
}

static void FRFRefreshRTGMode(struct Screen *scr, struct RastPort *rp, const char *tag)
{
        FRFRTGDirectRGB = FRFScreenIsRTGTrueColor(rp);

        if (FRFRTGDirectRGB)
                FrodoFRFTrace("FRF RTG: direct RGB active");
        else
                FrodoFRFTrace("FRF RTG: indexed fallback active");

        FRFLogScreenMode(scr, rp, tag);
}

static void FRFBuildPenToC64Map(const LONG *pens)
{
        int i;

        for (i = 0; i < 256; i++)
                FRFPenToC64[i] = (UBYTE)(i & 15);

        if (pens != NULL) {
                for (i = 0; i < 16; i++) {
                        if (pens[i] >= 0 && pens[i] <= 255)
                                FRFPenToC64[(UBYTE)pens[i]] = (UBYTE)i;
                }
        }
}

static void FRFSwitchC64Pens(struct Screen *scr, LONG *pens)
{
        int i;

        if (pens == NULL)
                return;

        if (FRFC64PenScreen != NULL) {
                /*
                 * Exact native palette indexes 0..15 were not allocated with
                 * ObtainBestPen(), so they must not be released.
                 */
                if (!FRFC64PensAreFixedNative) {
                        for (i = 0; i < 16; i++) {
                                if (pens[i] >= 0)
                                        ReleasePen(FRFC64PenScreen->ViewPort.ColorMap, pens[i]);
                        }
                }
                for (i = 0; i < 16; i++)
                        pens[i] = -1;
        }

        FRFC64PenScreen = NULL;
        FRFC64PensAreFixedNative = 0;

        if (scr != NULL) {
                for (i = 0; i < 16; i++)
                        pens[i] = ObtainBestPen(scr->ViewPort.ColorMap,
                                palette_red[i] * 0x01010101UL,
                                palette_green[i] * 0x01010101UL,
                                palette_blue[i] * 0x01010101UL,
                                TAG_DONE, 0);
                FRFC64PenScreen = scr;
        }

        FRFBuildPenToC64Map(pens);
}


/*
 * FRF_NATIVE_PLANAR16_FASTPATH_1.0.21_EXPERIMENTAL
 *
 * Native 4-bitplane screens own palette indexes 0..15.  Loading the complete
 * palette once removes per-frame pen remapping and lets the VIC render direct
 * four-bit C64 colour indexes into chunky_buf.
 */
static int FRFInstallNativeFixed16Palette(struct Screen *scr, LONG *pens)
{
        ULONG table[1 + 16 * 3 + 1];
        int i;
        int n = 0;

        if (scr == NULL || pens == NULL || scr->RastPort.BitMap == NULL)
                return 0;

        FRFSwitchC64Pens(NULL, pens);

        table[n++] = (16UL << 16) | 0UL;
        for (i = 0; i < 16; i++) {
                table[n++] = (ULONG)palette_red[i] * 0x01010101UL;
                table[n++] = (ULONG)palette_green[i] * 0x01010101UL;
                table[n++] = (ULONG)palette_blue[i] * 0x01010101UL;
                pens[i] = i;
        }
        table[n] = 0;
        LoadRGB32(&scr->ViewPort, table);

        FRFC64PenScreen = scr;
        FRFC64PensAreFixedNative = 1;
        FRFBuildPenToC64Map(pens);
        return 1;
}

static int FRFChunkyToC64Index(UBYTE v)
{
        return (int)FRFPenToC64[v];
}

static int FRFEnsureRTGFrameBuffer(void)
{
        LONG need = FRFOutputWidth() * FRFOutputHeight() * 3;

        if (FRFRTGBuf24 != NULL && FRFRTGBufBytes == need)
                return 1;

        if (FRFRTGBuf24 != NULL) {
                delete [] FRFRTGBuf24;
                FRFRTGBuf24 = NULL;
                FRFRTGBufBytes = 0;
        }

        FRFRTGBuf24 = new UBYTE[need];
        if (FRFRTGBuf24 == NULL) {
                FrodoFRFTrace("FRF RTG: RGB buffer allocation failed");
                return 0;
        }

        memset(FRFRTGBuf24, 0, need); /* FRF_RTG_BOTTOM_CLEAN_PAL_AUTO_1.0.29 */
        FRFRTGBufBytes = need;
        FrodoFRFTrace("FRF RTG: RGB buffer allocated");
        return 1;
}

static int FRFEnsureScaled8FrameBuffer(void)
{
        LONG need = FRFOutputWidth() * FRFOutputHeight();

        if (FRFScaledBuf8 != NULL && FRFScaledBuf8Bytes == need)
                return 1;

        if (FRFScaledBuf8 != NULL) {
                delete [] FRFScaledBuf8;
                FRFScaledBuf8 = NULL;
                FRFScaledBuf8Bytes = 0;
        }

        FRFScaledBuf8 = new UBYTE[need];
        if (FRFScaledBuf8 == NULL) {
                FrodoFRFTrace("FRF RTG: indexed X2 buffer allocation failed");
                return 0;
        }

        FRFScaledBuf8Bytes = need;
        FrodoFRFTrace("FRF RTG: indexed X2 buffer allocated");
        return 1;
}

static void FRFScaleIndexed2x(const UBYTE *src, UBYTE *dst)
{
        const LONG out_w = FRFOutputWidth();
        int sy;

        for (sy = 0; sy < DISPLAY_Y; sy++) {
                const UBYTE *srow = src + sy * DISPLAY_X;
                UBYTE *drow0 = dst + (sy * 2) * out_w;
                UBYTE *drow1 = drow0 + out_w;
                int sx;

                for (sx = 0; sx < DISPLAY_X; sx++) {
                        UBYTE v = srow[sx];
                        drow0[sx * 2] = v;
                        drow0[sx * 2 + 1] = v;
                }
                memcpy(drow1, drow0, out_w);
        }
}

static void FRFConvertRGBFrame(const UBYTE *src, UBYTE *dst)
{
        const int scale = FRFOutputScale();
        const LONG out_w = FRFOutputWidth();
        int sy;

        if (scale == 1) {
                LONG n;
                LONG total = DISPLAY_X * DISPLAY_Y;
                for (n = 0; n < total; n++) {
                        int ci = FRFChunkyToC64Index(src[n]);
                        *dst++ = FRF_C64_RGB[ci][0];
                        *dst++ = FRF_C64_RGB[ci][1];
                        *dst++ = FRF_C64_RGB[ci][2];
                }
                return;
        }

        for (sy = 0; sy < DISPLAY_Y; sy++) {
                const UBYTE *srow = src + sy * DISPLAY_X;
                UBYTE *drow0 = dst + (sy * 2) * out_w * 3;
                UBYTE *drow1 = drow0 + out_w * 3;
                int sx;

                for (sx = 0; sx < DISPLAY_X; sx++) {
                        int ci = FRFChunkyToC64Index(srow[sx]);
                        UBYTE *pixel = drow0 + sx * 6;
                        pixel[0] = FRF_C64_RGB[ci][0];
                        pixel[1] = FRF_C64_RGB[ci][1];
                        pixel[2] = FRF_C64_RGB[ci][2];
                        pixel[3] = pixel[0];
                        pixel[4] = pixel[1];
                        pixel[5] = pixel[2];
                }
                memcpy(drow1, drow0, out_w * 3);
        }
}


/*
 * FRF_NATIVE_PLANAR16_FASTPATH_1.0.21_EXPERIMENTAL
 *
 * The generic WritePixelArray8() path is expensive on classic planar screens:
 * it performs a general chunky-to-planar conversion every frame.  The native
 * engine below specialises for the exact Frodo case:
 *
 *   - X1 output (384x272)
 *   - native, non-CyberGraphX screen
 *   - exactly four bitplanes / 16 colours
 *   - fixed C64 palette at colour registers 0..15
 *
 * Four small pair-position lookup tables convert eight chunky pixels into one
 * byte for each bitplane.  Two planar staging bitmaps let the CPU convert the
 * next frame while the Amiga blitter finishes copying the previous one.
 * Unchanged raster lines reuse the previous planar line instead of being
 * converted again.
 */
#define FRF_PLANAR16_PLANES 4
#define FRF_PLANAR16_BUFFERS 2

static struct BitMap FRFPlanar16BitMap[FRF_PLANAR16_BUFFERS];
static int FRFPlanar16Ready = 0;
static int FRFPlanar16Current = 0;
static int FRFPlanar16Last = 0;
static int FRFPlanar16HaveLast = 0;
static UBYTE *FRFPlanar16PreviousChunky = NULL;
static UBYTE FRFPlanar16DirtyLine[DISPLAY_Y];
static ULONG FRFPlanar16PairLUT[4][256];
static int FRFPlanar16LUTReady = 0;

static void FRFPlanar16BuildLUT(void)
{
        int pair_pos;
        int value;

        if (FRFPlanar16LUTReady)
                return;

        for (pair_pos = 0; pair_pos < 4; pair_pos++) {
                int bit0 = 7 - pair_pos * 2;
                int bit1 = bit0 - 1;

                for (value = 0; value < 256; value++) {
                        UBYTE c0 = (UBYTE)((value >> 4) & 15);
                        UBYTE c1 = (UBYTE)(value & 15);
                        ULONG packed = 0;
                        int plane;

                        for (plane = 0; plane < 4; plane++) {
                                UBYTE out = 0;
                                if (c0 & (1 << plane))
                                        out |= (UBYTE)(1 << bit0);
                                if (c1 & (1 << plane))
                                        out |= (UBYTE)(1 << bit1);
                                packed |= (ULONG)out << (24 - plane * 8);
                        }
                        FRFPlanar16PairLUT[pair_pos][value] = packed;
                }
        }

        FRFPlanar16LUTReady = 1;
}

static void FRFPlanar16FreeBitMap(struct BitMap *bm)
{
        int plane;

        if (bm == NULL)
                return;

        for (plane = 0; plane < FRF_PLANAR16_PLANES; plane++) {
                if (bm->Planes[plane] != NULL) {
                        FreeRaster(bm->Planes[plane], DISPLAY_X, DISPLAY_Y);
                        bm->Planes[plane] = NULL;
                }
        }
}

static int FRFPlanar16AllocBitMap(struct BitMap *bm)
{
        int plane;
        LONG plane_bytes;

        if (bm == NULL)
                return 0;

        InitBitMap(bm, FRF_PLANAR16_PLANES, DISPLAY_X, DISPLAY_Y);
        plane_bytes = (LONG)bm->BytesPerRow * (LONG)bm->Rows;

        for (plane = 0; plane < FRF_PLANAR16_PLANES; plane++) {
                bm->Planes[plane] = AllocRaster(DISPLAY_X, DISPLAY_Y);
                if (bm->Planes[plane] == NULL) {
                        FRFPlanar16FreeBitMap(bm);
                        return 0;
                }
                memset(bm->Planes[plane], 0, plane_bytes);
        }
        return 1;
}

static int FRFPlanar16Ensure(void)
{
        int b;

        if (FRFPlanar16Ready)
                return 1;

        FRFPlanar16BuildLUT();

        for (b = 0; b < FRF_PLANAR16_BUFFERS; b++) {
                memset(&FRFPlanar16BitMap[b], 0, sizeof(struct BitMap));
                if (!FRFPlanar16AllocBitMap(&FRFPlanar16BitMap[b])) {
                        int j;
                        for (j = 0; j <= b; j++)
                                FRFPlanar16FreeBitMap(&FRFPlanar16BitMap[j]);
                        return 0;
                }
        }

        FRFPlanar16PreviousChunky = new UBYTE[DISPLAY_X * DISPLAY_Y];
        if (FRFPlanar16PreviousChunky == NULL) {
                for (b = 0; b < FRF_PLANAR16_BUFFERS; b++)
                        FRFPlanar16FreeBitMap(&FRFPlanar16BitMap[b]);
                return 0;
        }

        FRFPlanar16Current = 0;
        FRFPlanar16Last = 0;
        FRFPlanar16HaveLast = 0;
        FRFPlanar16Ready = 1;
        FrodoFRFTrace("native planar16 engine allocated");
        return 1;
}

static void FRFPlanar16Invalidate(void)
{
        /* A native screen may be closed immediately after this call. */
        if (FRFPlanar16Ready)
                WaitBlit();
        FRFPlanar16HaveLast = 0;
}

static void FRFPlanar16Shutdown(void)
{
        int b;

        if (!FRFPlanar16Ready && FRFPlanar16PreviousChunky == NULL)
                return;

        WaitBlit();

        for (b = 0; b < FRF_PLANAR16_BUFFERS; b++)
                FRFPlanar16FreeBitMap(&FRFPlanar16BitMap[b]);

        delete [] FRFPlanar16PreviousChunky;
        FRFPlanar16PreviousChunky = NULL;
        FRFPlanar16Ready = 0;
        FRFPlanar16HaveLast = 0;
        FrodoFRFTrace("native planar16 engine released");
}

static void FRFPlanar16ConvertLine(const UBYTE *src, struct BitMap *dst, int line)
{
        const LONG bpr = dst->BytesPerRow;
        UBYTE *d0 = (UBYTE *)dst->Planes[0] + line * bpr;
        UBYTE *d1 = (UBYTE *)dst->Planes[1] + line * bpr;
        UBYTE *d2 = (UBYTE *)dst->Planes[2] + line * bpr;
        UBYTE *d3 = (UBYTE *)dst->Planes[3] + line * bpr;
        int x;
        int out = 0;

        for (x = 0; x < DISPLAY_X; x += 8, out++) {
                ULONG packed =
                        FRFPlanar16PairLUT[0][((src[x + 0] & 15) << 4) | (src[x + 1] & 15)] |
                        FRFPlanar16PairLUT[1][((src[x + 2] & 15) << 4) | (src[x + 3] & 15)] |
                        FRFPlanar16PairLUT[2][((src[x + 4] & 15) << 4) | (src[x + 5] & 15)] |
                        FRFPlanar16PairLUT[3][((src[x + 6] & 15) << 4) | (src[x + 7] & 15)];

                d0[out] = (UBYTE)(packed >> 24);
                d1[out] = (UBYTE)(packed >> 16);
                d2[out] = (UBYTE)(packed >> 8);
                d3[out] = (UBYTE)packed;
        }
}

static void FRFPlanar16CopyLine(const struct BitMap *src, struct BitMap *dst, int line)
{
        LONG bytes = src->BytesPerRow;
        int plane;

        for (plane = 0; plane < FRF_PLANAR16_PLANES; plane++) {
                const UBYTE *s = (const UBYTE *)src->Planes[plane] + line * bytes;
                UBYTE *d = (UBYTE *)dst->Planes[plane] + line * bytes;
                memcpy(d, s, bytes);
        }
}

/*
 * FRF_NATIVE_PAL320_DIRECT_1.0.23
 *
 * True 320x256 native path.  The previous implementation still converted and
 * copied the complete 384x272 frame even when the selected mode was labelled
 * 320x256.  This path crops 32 pixels from each side and 8 lines from top and
 * bottom, then writes 32-bit plane words directly into the visible 4-plane
 * bitmap.  There are no staging bitmaps, dirty-frame comparisons or final
 * full-screen blits.
 */
static int FRFCanUseNativePAL320Direct(struct RastPort *rp)
{
        LONG byte_x;

        if (!FrodoFRFNativePAL320 ||
            !FRFAslFullscreenActive ||
            !FRFFullscreenNativePensActive ||
            !FRFC64PensAreFixedNative ||
            FRFOutputScale() != 1 ||
            rp == NULL ||
            rp->BitMap == NULL ||
            rp->BitMap->Depth != 4 ||
            FRFAslFullscreenScreen == NULL ||
            FRFScreenIsCyberGfxMode(FRFAslFullscreenScreen) ||
            FRFAslFullscreenScreen->Width < 320 ||
            FRFAslFullscreenScreen->Height < 256)
                return 0;

        byte_x = FRFFullscreenViewX >> 3;
        return ((FRFFullscreenViewX & 7) == 0) && ((byte_x & 3) == 0);
}

static void FRFConvertPAL320LineDirect(const UBYTE *src, struct BitMap *dst, int dst_line, LONG byte_x)
{
        const LONG bpr = dst->BytesPerRow;
        ULONG *d0 = (ULONG *)((UBYTE *)dst->Planes[0] + dst_line * bpr + byte_x);
        ULONG *d1 = (ULONG *)((UBYTE *)dst->Planes[1] + dst_line * bpr + byte_x);
        ULONG *d2 = (ULONG *)((UBYTE *)dst->Planes[2] + dst_line * bpr + byte_x);
        ULONG *d3 = (ULONG *)((UBYTE *)dst->Planes[3] + dst_line * bpr + byte_x);
        int x;

        for (x = 0; x < 320; x += 32) {
                ULONG p0 = 0, p1 = 0, p2 = 0, p3 = 0;
                int group;

                for (group = 0; group < 4; group++) {
                        const UBYTE *q = src + x + group * 8;
                        ULONG packed =
                                FRFPlanar16PairLUT[0][((q[0] & 15) << 4) | (q[1] & 15)] |
                                FRFPlanar16PairLUT[1][((q[2] & 15) << 4) | (q[3] & 15)] |
                                FRFPlanar16PairLUT[2][((q[4] & 15) << 4) | (q[5] & 15)] |
                                FRFPlanar16PairLUT[3][((q[6] & 15) << 4) | (q[7] & 15)];
                        p0 = (p0 << 8) | ((packed >> 24) & 255);
                        p1 = (p1 << 8) | ((packed >> 16) & 255);
                        p2 = (p2 << 8) | ((packed >> 8) & 255);
                        p3 = (p3 << 8) | (packed & 255);
                }

                *d0++ = p0;
                *d1++ = p1;
                *d2++ = p2;
                *d3++ = p3;
        }
}

static int FRFBlitNativePAL320Direct(struct RastPort *rp, const UBYTE *src)
{
        int y;
        LONG byte_x;
        int dst_y;

        if (!FRFCanUseNativePAL320Direct(rp) || src == NULL)
                return 0;

        FRFPlanar16BuildLUT();
        byte_x = FRFFullscreenViewX >> 3;
        dst_y = (int)FRFFullscreenViewY;

        for (y = 0; y < 256; y++) {
                const UBYTE *row = src + (y + 8) * DISPLAY_X + 32;
                FRFConvertPAL320LineDirect(row, rp->BitMap, dst_y + y, byte_x);
        }

        return 1;
}

static int FRFCanUseNativePlanar16(struct RastPort *rp)
{
        if (!FrodoFRFNativePlanar16 ||
            !FRFAslFullscreenActive ||
            !FRFFullscreenNativePensActive ||
            !FRFC64PensAreFixedNative ||
            FRFOutputScale() != 1 ||
            rp == NULL ||
            rp->BitMap == NULL)
                return 0;

        if (FRFScreenIsCyberGfxMode(FRFAslFullscreenScreen))
                return 0;

        return rp->BitMap->Depth == 4;
}

static int FRFBlitNativePlanar16(struct RastPort *rp, int x, int y, const UBYTE *src)
{
        struct BitMap *current;
        const struct BitMap *previous;
        int line;
        int dirty_count = 0;

        if (!FRFCanUseNativePlanar16(rp) || src == NULL)
                return 0;

        if (!FRFPlanar16Ensure())
                return 0;

        current = &FRFPlanar16BitMap[FRFPlanar16Current];
        previous = &FRFPlanar16BitMap[FRFPlanar16Last];

        if (!FRFPlanar16HaveLast) {
                memset(FRFPlanar16DirtyLine, 1, sizeof(FRFPlanar16DirtyLine));
                dirty_count = DISPLAY_Y;
        } else {
                for (line = 0; line < DISPLAY_Y; line++) {
                        const UBYTE *now = src + line * DISPLAY_X;
                        const UBYTE *old = FRFPlanar16PreviousChunky + line * DISPLAY_X;
                        int dirty = memcmp(now, old, DISPLAY_X) != 0;
                        FRFPlanar16DirtyLine[line] = (UBYTE)dirty;
                        if (dirty)
                                dirty_count++;
                }
        }

        if (dirty_count == 0)
                return 1;

        for (line = 0; line < DISPLAY_Y; line++) {
                const UBYTE *row = src + line * DISPLAY_X;

                if (FRFPlanar16DirtyLine[line])
                        FRFPlanar16ConvertLine(row, current, line);
                else
                        FRFPlanar16CopyLine(previous, current, line);
        }

        memcpy(FRFPlanar16PreviousChunky, src, DISPLAY_X * DISPLAY_Y);

        /*
         * Conversion runs while the previous hardware blit may still be
         * reading the other staging bitmap.  Synchronise only before issuing
         * the next copy, then let this copy continue asynchronously.
         */
        WaitBlit();
        BltBitMapRastPort(current,
                0, 0,
                rp,
                x, y,
                DISPLAY_X, DISPLAY_Y,
                0xc0);

        FRFPlanar16Last = FRFPlanar16Current;
        FRFPlanar16Current ^= 1;
        FRFPlanar16HaveLast = 1;
        return 1;
}


/*
 * FRF_MAGIC64_LINE_OUTPUT_1.0.24
 *
 * Reverse-engineered from MagiC64 1.81:
 *   - render one completed chunky raster at a time
 *   - convert it with graphics.library/WritePixelLine8()
 *   - draw into the hidden Intuition ScreenBuffer
 *   - flip the two native screen buffers with ChangeScreenBuffer() at VBlank
 *
 * This deliberately avoids full-frame WritePixelArray8(), a completed-frame
 * C chunky-to-planar pass, staging bitmaps and a final full-screen blit.
 *
 * It is enabled for FrodoSC and the dedicated FrodoRGB fast-line core on an
 * X1, native, four-bitplane PAL320 fullscreen screen. RTG, X2 and windowed
 * paths remain unchanged.
 */
static struct ScreenBuffer *FRFMagic64LineBuffers[2] = { NULL, NULL };
static struct Screen *FRFMagic64LineScreen = NULL;
static struct RastPort FRFMagic64LineRastPort;
static int FRFMagic64LineFront = 0;
static int FRFMagic64LineBack = 1;
static int FRFMagic64LineFrameTouched = 0;
static struct MsgPort *FRFMagic64LinePort = NULL;

/* FRF_RGBFAST_DIRECT_PLANAR_1.0.27
 *
 * The v1.0.26 line path called graphics.library/WritePixelLine8() for every
 * visible raster. At PAL rate that is 10,000 library calls per second.
 * FrodoRGB already owns a hidden native four-plane ScreenBuffer, so the fast
 * build can use the existing 16-colour LUT converter to write 40 longwords per
 * plane row directly. FrodoSC and all RTG/windowed paths retain their existing
 * code. A strict capability check keeps WritePixelLine8() as the fallback.
 */
static ULONG FRFMagic64LineDirectPlanarLines = 0;
static ULONG FRFMagic64LineAPIFallbackLines = 0;

static int FRFMagic64LineCanWriteDirect(struct BitMap *bm)
{
        LONG byte_x = FRFFullscreenViewX >> 3;

        return bm != NULL &&
               bm->Depth == 4 &&
               bm->BytesPerRow >= 40 &&
               bm->Planes[0] != NULL &&
               bm->Planes[1] != NULL &&
               bm->Planes[2] != NULL &&
               bm->Planes[3] != NULL &&
               (FRFFullscreenViewX & 7) == 0 &&
               (byte_x & 3) == 0;
}

static int FRFMagic64LineSafe[2] = { 0, 1 };
static int FRFMagic64LineDropFrame = 0;
static ULONG FRFMagic64LineDroppedFrames = 0;
static ULONG FRFMagic64LineSwapMisses = 0;

static int FRFMagic64LineCanUse(struct Screen *scr)
{
        return scr != NULL &&
               FRFAslFullscreenActive &&
               FrodoFRFNativePAL320 &&
               FRFOutputScale() == 1 &&
               !FRFScreenIsCyberGfxMode(scr) &&
               scr->RastPort.BitMap != NULL &&
               scr->RastPort.BitMap->Depth == 4 &&
               scr->Width >= 320 &&
               scr->Height >= 256;
}

static void FRFMagic64LineResetState(void)
{
        FRFMagic64LineBuffers[0] = NULL;
        FRFMagic64LineBuffers[1] = NULL;
        FRFMagic64LineScreen = NULL;
        FRFMagic64LineFront = 0;
        FRFMagic64LineBack = 1;
        FRFMagic64LineFrameTouched = 0;
        FRFMagic64LineSafe[0] = 0;
        FRFMagic64LineSafe[1] = 1;
        FRFMagic64LineDropFrame = 0;
        FRFMagic64LineDroppedFrames = 0;
        FRFMagic64LineSwapMisses = 0;
        FRFMagic64LineDirectPlanarLines = 0;
        FRFMagic64LineAPIFallbackLines = 0;
        InitRastPort(&FRFMagic64LineRastPort);
        FRFMagic64LineRastPort.BitMap = NULL;
}

static void FRFMagic64LineDrainMessages(void)
{
        struct Message *msg;

        if (FRFMagic64LinePort == NULL)
                return;

        while ((msg = GetMsg(FRFMagic64LinePort)) != NULL) {
                /*
                 * DBufInfo lays dbi_UserData1 directly after the safe
                 * Message. This is the same extraction used by the official
                 * Intuition double-buffer example.
                 */
                ULONG displayed = (ULONG)(*((APTR *)(msg + 1)));
                if (displayed < 2)
                        FRFMagic64LineSafe[displayed ^ 1] = 1;
        }
}

static int FRFMagic64LineBackIsSafe(void)
{
        if (FRFMagic64LinePort == NULL)
                return 0;

        FRFMagic64LineDrainMessages();
        return FRFMagic64LineSafe[FRFMagic64LineBack] != 0;
}

static void FRFMagic64LineShutdown(void)
{
        struct Screen *scr = FRFMagic64LineScreen;

        if (scr != NULL) {
                if (FRFMagic64LineBuffers[0] != NULL &&
                    FRFMagic64LineFront != 0) {
                        int guard = 8;
                        while (!ChangeScreenBuffer(scr, FRFMagic64LineBuffers[0]) &&
                               guard-- > 0)
                                WaitTOF();
                        FRFMagic64LineFront = 0;
                        FRFMagic64LineBack = 1;
                }

                WaitTOF();

                if (FRFMagic64LineBuffers[1] != NULL)
                        FreeScreenBuffer(scr, FRFMagic64LineBuffers[1]);
                if (FRFMagic64LineBuffers[0] != NULL)
                        FreeScreenBuffer(scr, FRFMagic64LineBuffers[0]);
        }

        if (FRFMagic64LinePort != NULL) {
                FRFMagic64LineDrainMessages();
                DeleteMsgPort(FRFMagic64LinePort);
                FRFMagic64LinePort = NULL;
        }

        FRFMagic64LineResetState();
}

static int FRFMagic64LineEnsure(struct Screen *scr)
{
        if (!FRFMagic64LineCanUse(scr))
                return 0;

        if (FRFMagic64LineScreen == scr &&
            FRFMagic64LineBuffers[0] != NULL &&
            FRFMagic64LineBuffers[1] != NULL)
                return 1;

        FRFMagic64LineShutdown();

        FRFMagic64LinePort = CreateMsgPort();
        if (FRFMagic64LinePort == NULL) {
                FRFMagic64LineResetState();
                return 0;
        }

        FRFMagic64LineBuffers[0] =
                AllocScreenBuffer(scr, NULL, SB_SCREEN_BITMAP);
        if (FRFMagic64LineBuffers[0] == NULL) {
                DeleteMsgPort(FRFMagic64LinePort);
                FRFMagic64LinePort = NULL;
                FRFMagic64LineResetState();
                return 0;
        }

        FRFMagic64LineBuffers[1] =
                AllocScreenBuffer(scr, NULL, SB_COPY_BITMAP);
        if (FRFMagic64LineBuffers[1] == NULL) {
                FreeScreenBuffer(scr, FRFMagic64LineBuffers[0]);
                DeleteMsgPort(FRFMagic64LinePort);
                FRFMagic64LinePort = NULL;
                FRFMagic64LineResetState();
                return 0;
        }

        FRFMagic64LineScreen = scr;
        FRFMagic64LineFront = 0;
        FRFMagic64LineBack = 1;
        FRFMagic64LineFrameTouched = 0;
        FRFMagic64LineSafe[0] = 0;
        FRFMagic64LineSafe[1] = 1;

        FRFMagic64LineBuffers[0]->sb_DBufInfo->dbi_UserData1 = (APTR)0;
        FRFMagic64LineBuffers[1]->sb_DBufInfo->dbi_UserData1 = (APTR)1;

        InitRastPort(&FRFMagic64LineRastPort);
        FRFMagic64LineRastPort.BitMap =
                FRFMagic64LineBuffers[0]->sb_BitMap;
        SetRast(&FRFMagic64LineRastPort, 0);
        FRFMagic64LineRastPort.BitMap =
                FRFMagic64LineBuffers[1]->sb_BitMap;
        SetRast(&FRFMagic64LineRastPort, 0);
        FRFMagic64LineRastPort.BitMap =
                FRFMagic64LineBuffers[FRFMagic64LineBack]->sb_BitMap;

#if (defined(FRF_RGBFAST) && defined(FRF_RGBFAST_DIRECT_PLANAR)) || \
    defined(FRF_SC_NATIVE_DIRECT_PLANAR) /* FRF_RGBEXACT_NATIVE_1.0.28 */
        /* Build the 4 x 256 pair LUT once, outside the raster hot path. */
        FRFPlanar16BuildLUT();
        if (FRFMagic64LineCanWriteDirect(FRFMagic64LineRastPort.BitMap))
                FrodoFRFTrace("FrodoRGB direct four-plane raster writer active");
        else
                FrodoFRFTrace("FrodoRGB direct planar unavailable; using WritePixelLine8");
#else
        FrodoFRFTrace("MagiC64-style native scanline double buffer active");
#endif
        return 1;
}

static int FRFMagic64LineWrite(struct Screen *scr,
        struct RastPort *temp_rp,
        UBYTE *line,
        int line_number)
{
        if (line == NULL || temp_rp == NULL)
                return 0;

        if (!FRFMagic64LineEnsure(scr))
                return 0;

#ifdef FRF_RGBFAST
        /* MagiC64-class fast path: VIC_RGB.cpp generates only PAL rasters
         * $33..$FA, so its framebuffer line numbers are already 0..199. The
         * unused 28 lines above and below remain black. */
        const int first_line = 0;
        const int line_count = 200;
        const int destination_y = 28;
#else
        /* Accuracy path: centre the full 320x256 crop. */
        const int first_line = 8;
        const int line_count = 256;
        const int destination_y = 0;
#endif

        if (line_number < first_line ||
            line_number >= first_line + line_count)
                return 1;

        /* Never stall emulation waiting for Intuition. MagiC64's practical
         * behaviour is to keep the emulator moving and present only when a
         * native back buffer is available. If the old front buffer is not yet
         * safe at the first visible raster, repeat the previous display frame
         * rather than blocking the C64 for another PAL interval. */
        if (line_number == first_line) {
                FRFMagic64LineDropFrame = 0;
                if (!FrodoFRFNoDisplay && !FRFMagic64LineBackIsSafe()) {
                        FRFMagic64LineDropFrame = 1;
                        FRFMagic64LineDroppedFrames++;
                }
        }

        if (!FrodoFRFNoDisplay && !FRFMagic64LineDropFrame) {
                const int dst_line = (int)(FRFFullscreenViewY + destination_y +
                                           line_number - first_line);
#if (defined(FRF_RGBFAST) && defined(FRF_RGBFAST_DIRECT_PLANAR)) || \
    defined(FRF_SC_NATIVE_DIRECT_PLANAR) /* FRF_RGBEXACT_NATIVE_1.0.28 */
                struct BitMap *bm =
                        FRFMagic64LineBuffers[FRFMagic64LineBack]->sb_BitMap;
                if (FRFMagic64LineCanWriteDirect(bm)) {
                        FRFConvertPAL320LineDirect(line + 32, bm, dst_line,
                                                  FRFFullscreenViewX >> 3);
                        FRFMagic64LineDirectPlanarLines++;
                } else {
                        WritePixelLine8(&FRFMagic64LineRastPort,
                                (UWORD)FRFFullscreenViewX,
                                (UWORD)dst_line,
                                320,
                                line + 32,
                                temp_rp);
                        FRFMagic64LineAPIFallbackLines++;
                }
#else
                WritePixelLine8(&FRFMagic64LineRastPort,
                        (UWORD)FRFFullscreenViewX,
                        (UWORD)dst_line,
                        320,
                        line + 32,
                        temp_rp);
#endif
        }

        FRFMagic64LineFrameTouched = 1;
        return 1;
}

static int FRFMagic64LineEndFrame(struct Screen *scr)
{
        if (FRFMagic64LineScreen != scr ||
            FRFMagic64LineBuffers[0] == NULL ||
            FRFMagic64LineBuffers[1] == NULL ||
            !FRFMagic64LineFrameTouched)
                return 0;

        FRFMagic64LineFrameTouched = 0;

        if (FrodoFRFNoDisplay)
                return 1;

        if (FRFMagic64LineDropFrame) {
                FRFMagic64LineDropFrame = 0;
                return 1;
        }

        FRFMagic64LineBuffers[FRFMagic64LineBack]->
                sb_DBufInfo->dbi_SafeMessage.mn_ReplyPort =
                        FRFMagic64LinePort;

        /* One non-blocking swap attempt. Waiting with WaitTOF here can add an
         * entire PAL frame to emulation time. If Intuition cannot accept the
         * buffer yet, retain the current front buffer and try a fresh frame. */
        if (!ChangeScreenBuffer(scr,
                    FRFMagic64LineBuffers[FRFMagic64LineBack])) {
                FRFMagic64LineSwapMisses++;
                FrodoFRFTrace("native RGB swap busy; frame repeated");
                return 1;
        }

        {
                int old_front = FRFMagic64LineFront;
                FRFMagic64LineFront = FRFMagic64LineBack;
                FRFMagic64LineBack = old_front;
                FRFMagic64LineSafe[FRFMagic64LineBack] = 0;
        }
        FRFMagic64LineRastPort.BitMap =
                FRFMagic64LineBuffers[FRFMagic64LineBack]->sb_BitMap;
        return 1;
}


static void FRFBlitC64Frame(struct RastPort *rp, int x, int y, UBYTE *src, const ULONG *pens, struct RastPort *temp_rp)
{
        const LONG out_w = FRFOutputWidth();
        const LONG out_h = FRFOutputHeight();
        const int scale = FRFOutputScale();

        (void)pens;

        /* FRF_FULLSCREEN_CENTER_BLACK: guard against stale xo/yo during screen toggles. */
        if (FRFAslFullscreenActive) {
                x = (int)FRFFullscreenViewX;
                y = (int)FRFFullscreenViewY;
        }

        if (rp == NULL || src == NULL)
                return;

        if (FRFBlitNativePAL320Direct(rp, src))
                return;

        if (FRFBlitNativePlanar16(rp, x, y, src))
                return;

        if (FRFRTGDirectRGB && FRFEnsureCyberGfx() && FRFEnsureRTGFrameBuffer()) {
                FRFConvertRGBFrame(src, FRFRTGBuf24);

                WritePixelArray(FRFRTGBuf24,
                        0, 0,
                        out_w * 3,
                        rp,
                        x, y,
                        out_w, out_h,
                        RECTFMT_RGB);
                return;
        }

        if (scale == 2) {
                if (!FRFEnsureScaled8FrameBuffer())
                        return;
                FRFScaleIndexed2x(src, FRFScaledBuf8);
                src = FRFScaledBuf8;
        }

        WritePixelArray8(rp,
                x, y,
                x + out_w - 1,
                y + out_h - 1,
                src,
                temp_rp);
}

C64Display::C64Display(C64 *the_c64) : TheC64(the_c64)
{
    FrodoFRFTrace("DISPLAY constructor enter");
	int i;
        const LONG output_w = FRFOutputWidth();
        const LONG output_h = FRFOutputHeight();

        the_window = NULL;
        the_screen = NULL;
        the_rp = NULL;
        the_visual_info = NULL;
        the_menus = NULL;
        led_font = NULL;
        speedo_font = NULL;
        temp_bm = NULL;
        chunky_buf = NULL;
        open_req = save_req = NULL;
        for (i=0; i<16; i++)
                pens[i] = -1;

	// LEDs off
	for (i=0; i<4; i++)
		led_state[i] = old_led_state[i] = LED_OFF;

	// Allocate chunky buffer to draw into
	chunky_buf = new UBYTE[DISPLAY_X * DISPLAY_Y];
        if (chunky_buf == NULL)
                error_exit("FRF Frodo RTG: couldn't allocate display buffer.\n");

        memset(chunky_buf, 0, DISPLAY_X * DISPLAY_Y); /* FRF_RTG_BOTTOM_CLEAN_PAL_AUTO_1.0.29 */
	// Open fonts
	led_font = OpenDiskFont(&led_font_attr);
	speedo_font = OpenDiskFont(&speedo_font_attr);
        if (led_font == NULL || speedo_font == NULL)
                error_exit("FRF Frodo RTG: couldn't open required fonts.\n");

	// Open window on default pubscreen
	FrodoFRFTrace("DISPLAY before OpenWindowTags");
    the_window = OpenWindowTags(NULL,
		WA_Left, 0,
		WA_Top, 0,
		WA_InnerWidth, output_w,
		WA_InnerHeight, output_h + 16,
		WA_Title, (ULONG)FRF_EDITION_STRING,
		WA_ScreenTitle, (ULONG)FRF_FULL_VERSION_STRING,
		WA_IDCMP, IDCMP_CLOSEWINDOW | IDCMP_RAWKEY | IDCMP_ACTIVEWINDOW | IDCMP_INACTIVEWINDOW | IDCMP_MENUPICK | IDCMP_REFRESHWINDOW,
		WA_DragBar, TRUE,
		WA_DepthGadget, TRUE,
		WA_CloseGadget, TRUE,
		WA_SimpleRefresh, TRUE,
		WA_Activate, TRUE,
		WA_NewLookMenus, TRUE,
		TAG_DONE);
	FrodoFRFTrace("DISPLAY after OpenWindowTags");
        if (the_window == NULL)
                error_exit("FRF Frodo RTG: couldn't open display window.\n");
    the_screen = the_window->WScreen;
	the_rp = the_window->RPort;
	xo = the_window->BorderLeft;
	yo = the_window->BorderTop;

    FRFRefreshRTGMode(the_screen, the_rp, "startup");

	// Create menus
	the_visual_info = GetVisualInfo(the_screen, NULL);
	the_menus = CreateMenus(new_menus, GTMN_FullMenu, TRUE, TAG_DONE);
        if (the_visual_info != NULL && the_menus != NULL) {
	        LayoutMenus(the_menus, the_visual_info, GTMN_NewLookMenus, TRUE, TAG_DONE);
	        SetMenuStrip(the_window, the_menus);
        }

	// Obtain 16 pens from the current screen's own ColorMap.
        FRFSwitchC64Pens(the_screen, pens);

	// Allocate temporary RastPort for WritePixelArra8()
	temp_bm = AllocBitMap(output_w, 1, 8, 0, NULL);
        if (temp_bm == NULL)
                error_exit("FRF Frodo RTG: couldn't allocate temporary bitmap.\n");
	InitRastPort(&temp_rp);
	temp_rp.BitMap = temp_bm;

	// Draw LED bar
	draw_led_bar();
    FrodoFRFTrace("DISPLAY after draw_led_bar");

	// Allocate file requesters
	open_req = (struct FileRequester *)AllocAslRequestTags(ASL_FileRequest,
		ASLFR_Window, (ULONG)the_window,
		ASLFR_SleepWindow, TRUE,
		ASLFR_TitleText, (ULONG)"FRF Frodo RTG: Load snapshot...",
		ASLFR_RejectIcons, TRUE,
		TAG_DONE);
	save_req = (struct FileRequester *)AllocAslRequestTags(ASL_FileRequest,
		ASLFR_Window, (ULONG)the_window,
		ASLFR_SleepWindow, TRUE,
		ASLFR_TitleText, (ULONG)"FRF Frodo RTG: Save snapshot...",
		ASLFR_DoSaveMode, TRUE,
		ASLFR_RejectIcons, TRUE,
		TAG_DONE);


        draw_led_bar(); /* FRF_RTG_BOTTOM_CLEAN_PAL_AUTO_1.0.29: initialise bottom RTG strip */

        /* The C64/VIC objects are completed after this display constructor.
         * Queue the launch requester now; PollKeyboard() opens it on the first
         * emulation pass when the whole machine is valid. */
        if (FrodoFRFStartupHardcodedPAL320) {
                FRFFullscreenPendingMode = FRF_FULLSCREEN_PENDING_HARDCODED_PAL320;
                FrodoFRFStartupHardcodedPAL320 = 0;
                FrodoFRFTrace("startup hardcoded PAL320 queued");
        } else if (FrodoFRFStartupLockedRTG) {
                FRFFullscreenPendingMode = FRF_FULLSCREEN_PENDING_LOCKED_RTG;
                FrodoFRFStartupLockedRTG = 0;
                FrodoFRFTrace("startup locked RTG queued");
        } else if (FrodoFRFStartupScreenModeRequester) {
                FRFFullscreenPendingMode = FRF_FULLSCREEN_PENDING_REQUESTER;
                FrodoFRFStartupScreenModeRequester = 0;
                FrodoFRFTrace("startup screenmode requester queued");
        }
}


/*
 *  Display destructor
 */

C64Display::~C64Display()
{
        FRFPlanar16Shutdown();

        /* Return to the original window before freeing window-owned resources. */
        if (FRFAslFullscreenActive) {
                if (FRFFullscreenNativePensActive && FRFAslWindowedWindow != NULL) {
                        FRFSwitchC64Pens(FRFAslWindowedWindow->WScreen, pens);
                        FRFFullscreenNativePensActive = 0;
                }

                FRFMagic64LineShutdown();

                if (FRFAslFullscreenWindow != NULL) {
                        CloseWindow(FRFAslFullscreenWindow);
                        FRFAslFullscreenWindow = NULL;
                }
                if (FRFAslFullscreenScreen != NULL) {
                        CloseScreen(FRFAslFullscreenScreen);
                        FRFAslFullscreenScreen = NULL;
                }
                the_window = FRFAslWindowedWindow;
                if (the_window != NULL) {
                        the_screen = the_window->WScreen;
                        the_rp = the_window->RPort;
                }
                FRFAslFullscreenActive = 0;
                FRFSetFullscreenCenteredViewport(NULL);
        }
        FRFAslWindowedWindow = NULL;

	if (open_req != NULL)
		FreeAslRequest(open_req);
	if (save_req != NULL)
		FreeAslRequest(save_req);

	if (temp_bm != NULL)
		FreeBitMap(temp_bm);

        FRFSwitchC64Pens(NULL, pens);

	if (the_menus != NULL) {
		if (the_window != NULL)
			ClearMenuStrip(the_window);
		FreeMenus(the_menus);
	}

	if (the_visual_info != NULL)
		FreeVisualInfo(the_visual_info);

	if (the_window != NULL)
		CloseWindow(the_window);

        if (speedo_font != NULL)
                CloseFont(speedo_font);
        if (led_font != NULL)
                CloseFont(led_font);

	delete [] chunky_buf;
        chunky_buf = NULL;

        if (FRFRTGBuf24 != NULL) {
                delete [] FRFRTGBuf24;
                FRFRTGBuf24 = NULL;
                FRFRTGBufBytes = 0;
        }
        if (FRFScaledBuf8 != NULL) {
                delete [] FRFScaledBuf8;
                FRFScaledBuf8 = NULL;
                FRFScaledBuf8Bytes = 0;
        }
        if (CyberGfxBase != NULL) {
                CloseLibrary(CyberGfxBase);
                CyberGfxBase = NULL;
        }
}


/*
 *  Prefs may have changed
 */

void C64Display::NewPrefs(Prefs *prefs)
{
}


/*
 *  Receive one completed raster from FrodoSC or FrodoRGB.
 *
 *  FrodoRGB calls this only after its CPU timeslice and FIX44 late-sprite
 *  repair, so native output receives the final coherent raster.
 */
void C64Display::UpdateScanline(uint8 *line, int line_number)
{
        FRFMagic64LineWrite(the_screen, &temp_rp, line, line_number);
}


/*
 *  Redraw bitmap
 */

void C64Display::Update(void)
{
        /* The MagiC64-style native path already wrote every completed raster
         * into the hidden screen buffer. At VBlank, flip buffers and skip the
         * old completed-frame conversion/copy. */
        if (FRFMagic64LineEndFrame(the_screen))
                return;

        /* Optional host-display synchronization. This can remove RTG scanout
         * tearing, but it intentionally does not change VIC emulation timing. */
        if (FrodoFRFPresentVSync && the_screen != NULL)
                WaitBOVP(&the_screen->ViewPort);

        // Update C64 display. DISPLAYEVERY and NODISPLAY are diagnostic
        // controls for measuring native-screen presentation overhead.
        {
                static int frf_display_phase = 0;
                int every = FrodoFRFDisplayEvery < 1 ? 1 : FrodoFRFDisplayEvery;
                int present = 0;

                if (!FrodoFRFNoDisplay) {
                        frf_display_phase++;
                        if (frf_display_phase >= every) {
                                frf_display_phase = 0;
                                present = 1;
                        }
                }

                if (present)
                        FRFBlitC64Frame(the_rp, xo, yo, chunky_buf, pens, &temp_rp);
        }

        /* FRF_FULLSCREEN_CENTER_BLACK:
         * Fullscreen is C64 viewport only. Do not draw the 16px LED strip
         * below DISPLAY_Y because the centered 384x272 viewport in 400x300
         * would push that strip into/outside the bottom border.
         */
        if (FRFAslFullscreenActive)
                return;

	// Update drive LEDs
	for (int i=0; i<4; i++)
		if (led_state[i] != old_led_state[i]) {
			draw_led(i, led_state[i]);
			old_led_state[i] = led_state[i];
		}
}


/*
 *  Draw LED bar at the bottom of the window
 */

void C64Display::draw_led_bar(void)
{
        const LONG ow = FRFOutputWidth();
        const LONG oh = FRFOutputHeight();

        if (FRFAslFullscreenActive)
                return;

	int i;
	char str[16];

	SetAPen(the_rp, pens[15]);	// Light gray
	SetBPen(the_rp, pens[15]);	// Light gray
	RectFill(the_rp, xo, yo+oh, xo+ow-1, yo+oh+15);

	SetAPen(the_rp, pens[1]);	// White
	Move(the_rp, xo, yo+oh); Draw(the_rp, xo+ow-1, yo+oh);
	for (i=0; i<5; i++) {
		Move(the_rp, xo+ow*i/5, yo+oh); Draw(the_rp, xo+ow*i/5, yo+oh+14);
	}
	for (i=2; i<6; i++) {
		Move(the_rp, xo+ow*i/5-23, yo+oh+11); Draw(the_rp, xo+ow*i/5-9, yo+oh+11);
		Move(the_rp, xo+ow*i/5-9, yo+oh+11); Draw(the_rp, xo+ow*i/5-9, yo+oh+5);
	}

	SetAPen(the_rp, pens[12]);	// Medium gray
	Move(the_rp, xo, yo+oh+15); Draw(the_rp, xo+ow-1, yo+oh+15);
	for (i=1; i<6; i++) {
		Move(the_rp, xo+ow*i/5-1, yo+oh+1); Draw(the_rp, xo+ow*i/5-1, yo+oh+15);
	}
	for (i=2; i<6; i++) {
		Move(the_rp, xo+ow*i/5-24, yo+oh+11); Draw(the_rp, xo+ow*i/5-24, yo+oh+4);
		Move(the_rp, xo+ow*i/5-24, yo+oh+4); Draw(the_rp, xo+ow*i/5-9, yo+oh+4);
	}

	SetFont(the_rp, led_font);
	for (i=0; i<4; i++) {
		sprintf(str, "Drive %d", i+8);
		SetAPen(the_rp, pens[0]);	// Black
		Move(the_rp, xo+ow*(i+1)/5+8, yo+oh+11);
		Text(the_rp, str, strlen(str));
		draw_led(i, LED_OFF);
	}
}


/*
 *  Draw one LED
 */

void C64Display::draw_led(int num, int state)
{
        const LONG ow = FRFOutputWidth();
        const LONG oh = FRFOutputHeight();

        if (FRFAslFullscreenActive)
                return;

	switch (state) {
		case LED_OFF:
		case LED_ERROR_OFF:
			SetAPen(the_rp, pens[0]);	// Black;
			break;
		case LED_ON:
			SetAPen(the_rp, pens[5]);	// Green
			break;
		case LED_ERROR_ON:
			SetAPen(the_rp, pens[2]);	// Red
			break;
	}
	RectFill(the_rp, xo+ow*(num+2)/5-23, yo+oh+5, xo+ow*(num+2)/5-10, yo+oh+10);
}


/*
 *  Update speedometer
 */

void C64Display::Speedometer(int speed)
{
        const LONG ow = FRFOutputWidth();
        const LONG oh = FRFOutputHeight();

        if (FRFAslFullscreenActive)
                return;

	static int delay = 0;

	if (delay >= 20) {
		char str[16];
		sprintf(str, "%d%%", speed);
		SetAPen(the_rp, pens[15]);	// Light gray
		RectFill(the_rp, xo+1, yo+oh+1, xo+ow/5-2, yo+oh+14);
		SetAPen(the_rp, pens[0]);	// Black
		SetFont(the_rp, speedo_font);
		Move(the_rp, xo+24, yo+oh+10);
		Text(the_rp, str, strlen(str));
		delay = 0;
	} else
		delay++;
}


/*
 *  Return pointer to bitmap data
 */

UBYTE *C64Display::BitmapBase(void)
{
	return chunky_buf;
}


/*
 *  Return number of bytes per row
 */

int C64Display::BitmapXMod(void)
{
	return DISPLAY_X;
}


/*
 *  Handle IDCMP messages
 */

void C64Display::PollKeyboard(UBYTE *key_matrix, UBYTE *rev_matrix, UBYTE *joystick)
{
        if (FrodoAmigaSuppressFocusAutoPause > 0)
                FrodoAmigaSuppressFocusAutoPause--;

        if (FRFFullscreenPendingMode != FRF_FULLSCREEN_PENDING_NONE) {
                int frf_fullscreen_mode = FRFFullscreenPendingMode;
                FRFFullscreenPendingMode = FRF_FULLSCREEN_PENDING_NONE;

                /*
                 * Pause while the ASL requester is open and while we switch
                 * the active output window.
                 */
                TheC64->Pause();
                FRFToggleAslFullscreen(&the_window, &the_screen, &the_rp, &xo, &yo, pens, frf_fullscreen_mode, TheC64);

                /*
                 * FRF 2026:
                 * Returning from custom screen can leave the AHI sound task
                 * paused because focus IDCMP messages race the fullscreen toggle.
                 * Force the focus state sane and send a couple of Resume()
                 * signals so the AHI retry loop wakes up.
                 */
                FrodoAmigaSuppressFocusAutoPause = 120;
                FrodoAmigaFocusAutoPaused = 0;

                if (!FRFAslFullscreenActive && the_window != NULL) {
                        if (the_window->WScreen != NULL)
                                ScreenToFront(the_window->WScreen);
                        WindowToFront(the_window);
                        ActivateWindow(the_window);
                }

                FrodoFRFTrace("fullscreen forced audio/focus resume after screen switch");

                Delay(2);
                TheC64->Resume();
                Delay(2);
                TheC64->Resume();

                FRFRefreshRTGMode(the_screen, the_rp,
                        FRFAslFullscreenActive ? "fullscreen" : "windowed");
                TheC64->Resume();
        }

struct IntuiMessage *msg;

	// Get and analyze all pending window messages
	while ((msg = (struct IntuiMessage *)GetMsg(the_window->UserPort)) != NULL) {

		// Extract data and reply message
		ULONG iclass = msg->Class;
		USHORT code = msg->Code;
                                                /* CRT_FIX23_SEPARATED_RAWKEY */
                                                {
                                                        UWORD frf_make = code & 0x7f;
                                                        int frf_down = ((code & 0x80) == 0);

                                                        /* Amiga F1 rawkey 0x50 -> C64 F1 only */
                                                        if (frf_make == 0x50) {
                                                                if (frf_down && !FrodoEasyCartF1Latch23) {
                                                                        FrodoEasyCartF1Pulse = 2;
                                                                        FrodoEasyCartF1Latch23 = 1;
                                                                        FrodoEasyCartFix23Log("CRT_FIX23: F1-only launch pulse");
                                                                } else if (!frf_down) {
                                                                        FrodoEasyCartF1Latch23 = 0;
                                                                }
                                                        }

                                                        /* Amiga Return/keypad Enter -> C64 RETURN only */
                                                        if (frf_make == 0x44 || frf_make == 0x43) {
                                                                if (frf_down && !FrodoEasyCartReturnLatch23) {
                                                                        FrodoEasyCartReturnPulse = 2;
                                                                        FrodoEasyCartReturnLatch23 = 1;
                                                                        FrodoEasyCartFix23Log("CRT_FIX23: RETURN-only launch pulse");
                                                                } else if (!frf_down) {
                                                                        FrodoEasyCartReturnLatch23 = 0;
                                                                }
                                                        }

                                                        /*
                                                         * Space = keyboard test for C64 joystick port 2 fire.
                                                         * Real joystick fire is still handled by Frodo's normal joystick code.
                                                         */
                                                        if (frf_make == 0x40) {
                                                                if (frf_down && !FrodoEasyCartFireLatch23) {
                                                                        FrodoEasyCartFire2Pulse = 2;
                                                                        FrodoEasyCartFireLatch23 = 1;
                                                                        FrodoEasyCartFix23Log("CRT_FIX23: PORT2-FIRE-only launch pulse");
                                                                } else if (!frf_down) {
                                                                        FrodoEasyCartFireLatch23 = 0;
                                                                }
                                                        }
                                                }


                                                /* CRT_FIX18_EASYCART_RAWKEY */
                                                {
                                                        UWORD frf_make = code & 0x7f;
                                                        int frf_down = ((code & 0x80) == 0);

                                                        /* F1 -> C64 F1 */
                                                        if (frf_make == 0x50) {
                                                                if (frf_down && !FrodoEasyCartF1Latch) {
                                                                        FrodoEasyCartF1Frames = 4;
                                                                        FrodoEasyCartF1Latch = 1;
                                                                        FrodoEasyCartInputLog("CRT_FIX18: F1 pressed");
                                                                } else if (!frf_down) {
                                                                        FrodoEasyCartF1Latch = 0;
                                                                }
                                                        }

                                                        /* Return / keypad Enter -> C64 RETURN */
                                                        if (frf_make == 0x44 || frf_make == 0x43) {
                                                                if (frf_down && !FrodoEasyCartReturnLatch) {
                                                                        FrodoEasyCartReturnFrames = 4;
                                                                        FrodoEasyCartReturnLatch = 1;
                                                                        FrodoEasyCartInputLog("CRT_FIX18: RETURN pressed");
                                                                } else if (!frf_down) {
                                                                        FrodoEasyCartReturnLatch = 0;
                                                                }
                                                        }

                                                        /*
                                                         * Space -> keyboard test for joystick fire on C64 port 2.
                                                         * Real joystick fire remains handled by normal joystick code.
                                                         */
                                                        if (frf_make == 0x40) {
                                                                if (frf_down && !FrodoEasyCartFireLatch) {
                                                                        FrodoEasyCartFire2Frames = 4;
                                                                        FrodoEasyCartFireLatch = 1;
                                                                        FrodoEasyCartInputLog("CRT_FIX18: keyboard port2 FIRE pressed");
                                                                } else if (!frf_down) {
                                                                        FrodoEasyCartFireLatch = 0;
                                                                }
                                                        }
                                                }


		ReplyMsg((struct Message *)msg);

		// Action depends on message class
		switch (iclass) {

			case IDCMP_CLOSEWINDOW:	// Closing the window quits Frodo
				TheC64->Quit();
				break;

			
                case IDCMP_INACTIVEWINDOW:
                        /*
                         * FRF 2026:
                         * Auto-pause when this Frodo window loses focus,
                         * but never during fullscreen screen transitions.
                         */
                        if (FRFAslFullscreenActive || FrodoAmigaSuppressFocusAutoPause > 0) {
                                FrodoFRFTrace("FOCUS inactive ignored during fullscreen transition");
                                break;
                        }

                        if (!FrodoAmigaFocusAutoPaused) {
                                TheC64->Pause();
                                FrodoAmigaFocusAutoPaused = 1;
                        }
                        break;

                case IDCMP_ACTIVEWINDOW:
                        /*
                         * FRF 2026:
                         * Resume when focus returns.
                         */
                        if (FRFAslFullscreenActive || FrodoAmigaSuppressFocusAutoPause > 0) {
                                FrodoFRFTrace("FOCUS active ignored during fullscreen transition");
                                break;
                        }

                        if (FrodoAmigaFocusAutoPaused) {
                                TheC64->Resume();
                                FrodoAmigaFocusAutoPaused = 0;
                        }
                        break;

case IDCMP_RAWKEY:
                    /*
                     * Ctrl-P / Amiga-P:
                     * Use the same modal GUI route that already pauses,
                     * opens the prefs GUI, then resumes.
                     *
                     * Amiga rawkey P = 0x19.
                     * Mask with 0x7f so key-up events do not confuse us.
                     */
                    {
                            UWORD frodo_rawkey = (UWORD)(code & 0x7f);
                            UWORD frodo_qual  = msg->Qualifier;

                            /*
                             * Ctrl+LAlt+U:
                             *   toggle the saved/fixed RTG fullscreen mode.
                             *
                             * Ctrl+LAlt+LAmiga+U:
                             *   open the ASL screenmode requester.  At X1 this
                             *   may be an RTG mode or a native Amiga RGB PAL
                             *   screen.  Native choices do not replace the
                             *   saved direct-RTG mode.
                             *
                             * Amiga rawkey U = 0x16.
                             */
                            if (!(code & 0x80) &&
                                frodo_rawkey == 0x16 &&
                                (frodo_qual & IEQUALIFIER_CONTROL) &&
                                (frodo_qual & IEQUALIFIER_LALT)) {
                                    if (frodo_qual & IEQUALIFIER_LCOMMAND) {
                                            FrodoFRFTrace("CTRL+LALT+LAMIGA+U requester detected");
                                            FRFFullscreenPendingMode = FRF_FULLSCREEN_PENDING_REQUESTER;
                                    } else {
                                            FrodoFRFTrace("CTRL+LALT+U locked RTG detected");
                                            FRFFullscreenPendingMode = FRF_FULLSCREEN_PENDING_LOCKED_RTG;
                                    }
                                    break;
                            }

                            if (!(code & 0x80) &&
                                frodo_rawkey == 0x19 &&
                                (frodo_qual & (IEQUALIFIER_CONTROL |
                                               IEQUALIFIER_LCOMMAND |
                                               IEQUALIFIER_RCOMMAND))) {
                                    if (!FrodoAmigaPauseHotkeyActive) {
                                            TheC64->Pause();
                                            FrodoAmigaPauseHotkeyActive = 1;
                                    } else {
                                            TheC64->Resume();
                                            FrodoAmigaPauseHotkeyActive = 0;
                                    }
                                    break;
                            }
                    }
				switch (code) {

					case 0x58:	// F9: NMI (Restore)
						TheC64->NMI();
						break;

					case 0x59:	// F10: Reset
						TheC64->Reset();
						break;

					case 0x5e:	// '+' on keypad: Increase SkipFrames
						ThePrefs.SkipFrames++;
						break;

					case 0x4a:	// '-' on keypad: Decrease SkipFrames
						if (ThePrefs.SkipFrames > 1)
							ThePrefs.SkipFrames--;
						break;

					case 0x5d:	// '*' on keypad: Toggle speed limiter
						ThePrefs.LimitSpeed = !ThePrefs.LimitSpeed;
						break;

					case 0x5c:{	// '/' on keypad: Toggle processor-level 1541 emulation
						Prefs *prefs = new Prefs(ThePrefs);
						prefs->Emul1541Proc = !prefs->Emul1541Proc;
						TheC64->NewPrefs(prefs);
						ThePrefs = *prefs;
						delete prefs;
						break;
					}

					default:{
						// Convert Amiga keycode to C64 row/column
						int c64_byte = key_byte[code & 0x7f];
						int c64_bit = key_bit[code & 0x7f];

						if (c64_byte != -1) {
							if (!(c64_byte & 0x20)) {

								// Normal keys
								bool shifted = c64_byte & 8;
								c64_byte &= 7;
								if (!(code & 0x80)) {

									// Key pressed
									if (shifted) {
										key_matrix[6] &= 0xef;
										rev_matrix[4] &= 0xbf;
									}
									key_matrix[c64_byte] &= ~(1 << c64_bit);
									rev_matrix[c64_bit] &= ~(1 << c64_byte);
								} else {

									// Key released
									if (shifted) {
										key_matrix[6] |= 0x10;
										rev_matrix[4] |= 0x40;
									}
									key_matrix[c64_byte] |= (1 << c64_bit);
									rev_matrix[c64_bit] |= (1 << c64_byte);
								}
							} else {

								// Joystick emulation
								c64_byte &= 0x1f;
								if (code & 0x80)
									*joystick |= c64_byte;
								else
									*joystick &= ~c64_byte;
							}
						}
					}
				}
				break;

			case IDCMP_MENUPICK:{
				if (code == MENUNULL)
					break;

				// Get item number
				int item_number = ITEMNUM(code);
				switch (item_number) {

					case 0: {	// About Frodo
						TheC64->Pause();
						char str[1024];
                                                sprintf(str,
                                                        "%s\n"
                                                        "Based on %s\n\n"
                                                        "Original emulator: Christian Bauer\n"
                                                        "RTG / CRT added by: Future Retro Fusion (FRF), 2026\n\n"
                                                        "FRF edition improvements:\n"
                                                        "- CyberGraphX RTG output and indexed fallback\n"
                                                        "- Fixed RTG and requester-selected RGB PAL fullscreen\n"
                                                        "- AHI pause, focus and multi-instance fixes\n"
                                                        "- CRT, PRG, D64/T64, save-state and REU launch options\n"
                                                        "- EasyFlash, 8K/16K/Ultimax and Magic Desk CRT support\n"
                                                        "- VIC sprite-multiplexer correction\n"
                                                        "- PiStorm/68060 build and release fixes\n\n"
                                                        "Original Copyright 1994-1997, 2002 Christian Bauer\n"
                                                        "FRF modifications Copyright 2026 Future Retro Fusion\n"
                                                        "GNU GPL version 2 - no warranty\n"
                                                        "See README-FRF.md for full details.",
                                                        FRF_EDITION_STRING, VERSION_STRING);
						ShowRequester(str, "OK");
						TheC64->Resume();
						break;
					}

					case 2:		// Preferences
						TheC64->Pause();
						be_app->RunPrefsEditor();
						TheC64->Resume();
						break;

					case 4:		// Reset C64
						TheC64->Reset();
						break;

					case 5:		// Insert next disk
						if (strlen(ThePrefs.DrivePath[0]) > 4) {
							char str[256];
							strcpy(str, ThePrefs.DrivePath[0]);
							char *p = str + strlen(str) - 5;

							// If path matches "*.?64", increment character before the '.'
							if (p[1] == '.' && p[3] == '6' && p[4] == '4') {
								p[0]++;

								// If no such file exists, set character before the '.' to '1', 'a' or 'A'
								FILE *file;
								if ((file = fopen(str, "rb")) == NULL) {
									if (isdigit(p[0]))
										p[0] = '1';
									else if (isupper(p[0]))
										p[0] = 'A';
									else
										p[0] = 'a';
								} else
									fclose(file);

								// Set new prefs
								Prefs *prefs = new Prefs(ThePrefs);
								strcpy(prefs->DrivePath[0], str);
								TheC64->NewPrefs(prefs);
								ThePrefs = *prefs;
								delete prefs;
							}
						}
						break;

					case 6:		// SAM
						TheC64->Pause();
						SAM(TheC64);
						TheC64->Resume();
						break;

					case 8:		// Load snapshot
						if (open_req != NULL && AslRequest(open_req, NULL)) {
							char path[256];
							strncpy(path, open_req->fr_Drawer, 255);
							AddPart(path, open_req->fr_File, 255);
							TheC64->Pause();
							TheC64->LoadSnapshot(path);
							TheC64->Resume();
						}
						break;

					case 9:		// Save snapshot
						if (save_req != NULL && AslRequest(save_req, NULL)) {
							char path[256];
							strncpy(path, save_req->fr_Drawer, 255);
							AddPart(path, save_req->fr_File, 255);
							TheC64->Pause();
							TheC64->SaveSnapshot(path);
							TheC64->Resume();
						}
						break;

					case 11:	// Quit Frodo
						TheC64->Quit();
						break;
				}
				break;
			}

			case IDCMP_REFRESHWINDOW:
				BeginRefresh(the_window);
				draw_led_bar();
				EndRefresh(the_window, TRUE);
				break;
		}
	}

        /* CRT_FIX18_EASYCART_FINAL_APPLY
         *
         * Apply these AFTER normal Frodo keyboard/joystick polling.
         *
         * C64 keyboard matrix:
         *   F1     = row 0, column 4
         *   RETURN = row 0, column 1
         *
         * Joystick fire is bit 4 low.
         * EasyCart launch fire is on C64 port 2, so use joystick[1].
         */
        if (FrodoEasyCartF1Frames > 0) {
                key_matrix[0] &= ~0x10;
                rev_matrix[4] &= ~0x01;
                FrodoEasyCartF1Frames--;
        }

        if (FrodoEasyCartReturnFrames > 0) {
                key_matrix[0] &= ~0x02;
                rev_matrix[1] &= ~0x01;
                FrodoEasyCartReturnFrames--;
        }

        if (FrodoEasyCartFire2Frames > 0) {
                joystick[1] &= ~0x10;
                FrodoEasyCartFire2Frames--;
        }


        /* CRT_FIX23_SEPARATED_FINAL_APPLY
         * Apply after normal polling, but never press multiple launch
         * actions together.
         */
        if (FrodoEasyCartF1Pulse > 0) {
                key_matrix[0] &= ~0x10;  /* C64 F1 */
                rev_matrix[4] &= ~0x01;
                FrodoEasyCartF1Pulse--;
        }

        if (FrodoEasyCartReturnPulse > 0) {
                key_matrix[0] &= ~0x02;  /* C64 RETURN */
                rev_matrix[1] &= ~0x01;
                FrodoEasyCartReturnPulse--;
        }

        if (FrodoEasyCartFire2Pulse > 0) {
                joystick[1] &= ~0x10;    /* C64 joystick port 2 fire */
                FrodoEasyCartFire2Pulse--;
        }

}


/*
 *  Check if NumLock is down (for switching the joystick keyboard emulation)
 */

bool C64Display::NumLock(void)
{
	return FALSE;
}


/*
 *  Allocate C64 colors
 */

void C64Display::InitColors(UBYTE *colors)
{
	// Spread pens into colors array
	for (int i=0; i<256; i++)
		colors[i] = pens[i & 0x0f];
}


/*
 *  Show a requester
 */

long ShowRequester(char *str, char *button1, char *button2)
{
	struct EasyStruct es;
	char gads[256];

	strcpy(gads, button1);
	if (button2) {
		strcat(gads, "|");
		strcat(gads, button2);
	}

	es.es_StructSize = sizeof(struct EasyStruct);
	es.es_Flags = 0;
	es.es_Title = (char *)FRF_EDITION_STRING;
	es.es_TextFormat = str;
	es.es_GadgetFormat = gads;

	return EasyRequestArgs(NULL, &es, NULL, NULL) % 1;
}

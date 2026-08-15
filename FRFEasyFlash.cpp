/* Modified 2026-06-28 by Future Retro Fusion for FRF 2026 Frodo RTG.
 * Restores type-0 8K/16K/Ultimax and type-19 Magic Desk CRT support while preserving EasyFlash. */

static int ef_io2_read_log_count = 0;
static int ef_io2_write_log_count = 0;
#include "sysdeps.h"
#include "FRFEasyFlash.h"
#include "FRFBuildConfig.h"
#include "FRFDiagnostics.h"

#include <stdio.h>
#include <string.h>

static unsigned char ef_roml[64][0x2000];
static unsigned char ef_romh[64][0x2000];
static unsigned char ef_ram[0x100];

/* CRT_FIX35_SAFE_CART16_VIEW_GLOBALS
 *
 * CRT_FIX34 used a full 64K CPU view and made SSF2T worse/crashy
 * (bad jump into $D701).  This safer view only makes the real 16K
 * cartridge window contiguous for PC_IS_POINTER:
 *
 *   $8000-$9FFF -> ROML
 *   $A000-$BFFF -> ROMH when 16K mode is active
 *
 * It fixes the original $9FFF->$A000 pointer crossing without allowing
 * execution to wander through a synthetic $D000 I/O page.
 */
static unsigned char ef_fix35_cart16_view[0x4000];
static int ef_fix35_view_log_count = 0;

/* CRT_FIX13_LIVE_COPY_GLOBALS */
static unsigned char *ef_fix13_ram = 0;
static unsigned char *ef_fix13_basic = 0;
static unsigned char *ef_fix13_kernal = 0;

static unsigned char ef_fix13_saved_ram8000[0x2000];
static unsigned char ef_fix13_saved_basic[0x2000];
static unsigned char ef_fix13_saved_kernal[0x2000];


/* CRT_FIX25_SHADOW_ROML_GLOBALS
 *
 * Frodo currently needs ROML physically copied into RAM for boot/menu.
 * But real C64 writes under cartridge ROM must still update hidden RAM.
 * This shadow stores writes to $8000-$9FFF while ROML is visible.
 * When EasyFlash switches cart off, live-copy restores this shadow.
 */
static unsigned char ef_fix25_under_roml[0x2000];
static int ef_fix25_shadow_ready = 0;
static int ef_fix25_shadow_log_count = 0;

static int ef_fix13_saved = 0;
static int ef_fix13_apply_log_count = 0;

static int ef_loaded = 0;


/*
 * FRF 2026:
 * CRT mapper state.
 *
 * 0 = none
 * 1 = Normal fixed 8K/16K cartridge
 * 2 = EasyFlash
 *
 * Default to EasyFlash so older partial patches still compile/use type 32.
 */
static int ef_mapper_type = 2;
static int ef_magicdesk_disabled = 0; /* hardware type 19 bit-7 disable latch */

/*
 * FRF 2026:
 * Default EasyFlash reset mode derived from CRT header EXROM/GAME.
 *
 * EasyFlash $DE02 modes:
 *   5 = Ultimax
 *   6 = 8K
 *   7 = 16K
 */
static int ef_default_mode = 5;
static unsigned char ef_crt_exrom = 1;
static unsigned char ef_crt_game = 0;
static int ef_normal_8k = 0;
static int ef_normal_16k = 0;
static int ef_normal_ultimax = 0;
static unsigned char ef_bank = 0;
static unsigned char ef_control = 0x07; /* reset = 16K cart mode, bank 0 */

static unsigned short be16(const unsigned char *p)
{
        return ((unsigned short)p[0] << 8) | p[1];
}

static unsigned long be32(const unsigned char *p)
{
        return ((unsigned long)p[0] << 24) |
               ((unsigned long)p[1] << 16) |
               ((unsigned long)p[2] << 8) |
               p[3];
}


static void ef_logf(const char *fmt,
                    unsigned int a,
                    unsigned int b,
                    unsigned int c,
                    unsigned int d)
{
        FILE *f = FRFOpenDiagnosticLog("PROGDIR:frodo-easyflash.log", "frodo-easyflash.log", "a");

        if (!f)
                return;

        fprintf(f, fmt, a, b, c, d);
        fprintf(f, "\n");
        fclose(f);
}

static void ef_log(const char *msg)
{
        FILE *f = FRFOpenDiagnosticLog("PROGDIR:frodo-easyflash.log", "frodo-easyflash.log", "a");

        if (!f)
                return;

        fprintf(f, "%s\n", msg ? msg : "(null)");
        fclose(f);
}


static void ef_log_path(const char *prefix, const char *path)
{
        FILE *f = FRFOpenDiagnosticLog("PROGDIR:frodo-easyflash.log", "frodo-easyflash.log", "a");

        if (!f)
                return;

        fprintf(f, "%s%s\n", prefix ? prefix : "", path ? path : "(null)");
        fclose(f);
}

static int ef_has_device_or_slash(const char *path)
{
        const char *p = path;

        if (!p)
                return 0;

        while (*p) {
                if (*p == ':' || *p == '/' || *p == '\\')
                        return 1;
                p++;
        }

        return 0;
}

static FILE *ef_open_crt_file(const char *path)
{
        FILE *f;
        char alt[512];

        if (!path || !path[0]) {
                ef_log("CRT open failed: empty path");
                return NULL;
        }

        ef_log_path("CRT open trying: ", path);

        f = fopen(path, "rb");
        if (f) {
                ef_log_path("CRT open OK: ", path);
                return f;
        }

        if (!ef_has_device_or_slash(path)) {
                strcpy(alt, "PROGDIR:");
                strncat(alt, path, sizeof(alt) - strlen(alt) - 1);

                ef_log_path("CRT open trying: ", alt);

                f = fopen(alt, "rb");
                if (f) {
                        ef_log_path("CRT open OK: ", alt);
                        return f;
                }
        }

        ef_log_path("CRT open failed for: ", path);
        return NULL;
}


static void ef_log_easyflash_mode(const char *prefix)
{
        FILE *f = FRFOpenDiagnosticLog("PROGDIR:frodo-easyflash.log", "frodo-easyflash.log", "a");

        if (!f)
                return;

        fprintf(f, "%s bank=%u control=$%02x mode=%u\n",
                prefix ? prefix : "EasyFlash mode:",
                (unsigned int)(ef_bank & 0x3f),
                (unsigned int)ef_control,
                (unsigned int)(ef_control & 7));

        fclose(f);
}

/* CRT_FIX37_NORMAL_CRT_HELPER
 * Configure ordinary hardware type-0 CRT images independently from the
 * EasyFlash type-32 mapper. EXROM/GAME are active-low in the CRT header.
 */
static void ef_fix37_configure_normal_crt(int roml_chips, int romh_chips)
{
        ef_normal_8k = 0;
        ef_normal_16k = 0;
        ef_normal_ultimax = 0;

        if (ef_crt_exrom == 0 && ef_crt_game == 0) {
                ef_normal_16k = 1;
        } else if (ef_crt_exrom == 0 && ef_crt_game == 1) {
                ef_normal_8k = 1;
        } else if (ef_crt_exrom == 1 && ef_crt_game == 0) {
                ef_normal_ultimax = 1;
        } else {
                /* Broken/non-standard headers occur in older CRT dumps.
                 * Fall back to the CHIP layout rather than rejecting them.
                 */
                if (roml_chips && romh_chips)
                        ef_normal_16k = 1;
                else if (roml_chips)
                        ef_normal_8k = 1;
                else if (romh_chips)
                        ef_normal_ultimax = 1;
        }

        /* A 16K header with only one populated half is treated as the
         * actually supplied 8K/Ultimax image.
         */
        if (ef_normal_16k && (!roml_chips || !romh_chips)) {
                if (roml_chips && !romh_chips) {
                        ef_normal_16k = 0;
                        ef_normal_8k = 1;
                } else if (!roml_chips && romh_chips) {
                        ef_normal_16k = 0;
                        ef_normal_ultimax = 1;
                }
        }

        if (ef_normal_16k)
                ef_default_mode = 7;
        else if (ef_normal_8k)
                ef_default_mode = 6;
        else
                ef_default_mode = 5;

        ef_logf("CRT_FIX37: normal CRT EXROM=%u GAME=%u 8K=%u 16K=%u",
                ef_crt_exrom, ef_crt_game, ef_normal_8k, ef_normal_16k);
        ef_logf("CRT_FIX37: normal CRT Ultimax=%u ROMLchips=%u ROMHchips=%u mapper=%u",
                ef_normal_ultimax, roml_chips, romh_chips, ef_mapper_type);
}

static int ef_mode(void)
{
        int m = ef_control & 7;

        /*
         * $DE02 modes 0 and 2 use the physical boot/jumper line state.
         * In a CRT file we approximate that from the header EXROM/GAME.
         */
        if (m == 0 || m == 2)
                return ef_default_mode;

        return m;
}

/* CRT_FIX35_REBUILD_SAFE_CART16_VIEW */
static void ef_fix35_rebuild_cart16_view(const char *where)
{
        unsigned int i;
        unsigned int bank;
        int m;
        int roml_active;
        int romh_a000_active;

        if (!ef_loaded)
                return;

        bank = ef_bank & 0x3f;
        m = ef_mode();

        if (ef_mapper_type == 1) {
                roml_active = ef_normal_8k || ef_normal_16k || ef_normal_ultimax;
                romh_a000_active = ef_normal_16k;
        } else if (ef_mapper_type == 3) {
                roml_active = !ef_magicdesk_disabled;
                romh_a000_active = 0;
        } else {
                roml_active = (m == 5 || m == 6 || m == 7);
                romh_a000_active = (m == 7);
        }

        for (i = 0; i < 0x2000; i++) {
                if (roml_active)
                        ef_fix35_cart16_view[i] = ef_roml[bank][i];
                else if (ef_fix13_ram)
                        ef_fix35_cart16_view[i] = ef_fix13_ram[0x8000 + i];
                else
                        ef_fix35_cart16_view[i] = 0xff;

                if (romh_a000_active)
                        ef_fix35_cart16_view[0x2000 + i] = ef_romh[bank][i];
                else if (ef_fix13_basic)
                        ef_fix35_cart16_view[0x2000 + i] = ef_fix13_basic[i];
                else
                        ef_fix35_cart16_view[0x2000 + i] = 0xff;
        }

        if (ef_fix35_view_log_count < 128) {
                ef_logf("CRT_FIX35: rebuilt safe 16K cart view bank=%u mode=%u where=%u count=%u",
                        bank,
                        m,
                        where ? (unsigned int)((unsigned char)where[0]) : 0,
                        ef_fix35_view_log_count);
                ef_fix35_view_log_count++;
        }
}

/* CRT_FIX13_LIVE_COPY_HELPER */
static void ef_fix13_apply_live_copy(void)
{
        unsigned int i;
        unsigned int bank;
        int m;
        int roml_active = 0;
        int romh_a000_active = 0;
        int romh_e000_active = 0;

        if (!ef_loaded)
                return;

        if (!ef_fix13_ram || !ef_fix13_basic || !ef_fix13_kernal)
                return;

        if (!ef_fix13_saved) {
                for (i = 0; i < 0x2000; i++) {
                        ef_fix13_saved_ram8000[i] = ef_fix13_ram[0x8000 + i];
                        ef_fix13_saved_basic[i] = ef_fix13_basic[i];
                        ef_fix13_saved_kernal[i] = ef_fix13_kernal[i];
                }
                ef_fix13_saved = 1;
                /* CRT_FIX25_SHADOW_INIT_IN_APPLY */
                if (!ef_fix25_shadow_ready) {
                        for (i = 0; i < 0x2000; i++)
                                ef_fix25_under_roml[i] = ef_fix13_saved_ram8000[i];

                        ef_fix25_shadow_ready = 1;
                        ef_log("CRT_FIX25: initialized hidden RAM under ROML");
                }

        }

        bank = ef_bank & 0x3f;
        m = ef_mode();

        if (ef_mapper_type == 1) {
                roml_active = ef_normal_8k || ef_normal_16k || ef_normal_ultimax;
                romh_a000_active = ef_normal_16k;
                romh_e000_active = ef_normal_ultimax;
        } else if (ef_mapper_type == 2) {
                roml_active = (m == 5 || m == 6 || m == 7);
                romh_a000_active = (m == 7);
                romh_e000_active = (m == 5);
        } else if (ef_mapper_type == 3) {
                roml_active = !ef_magicdesk_disabled;
        }

        /*
         * Restore base memory first, then overlay currently selected cart bank.
         * This prevents stale bank-0 ROMH at $E000 after the cart switches to 16K mode.
         */
        for (i = 0; i < 0x2000; i++) {
                ef_fix13_ram[0x8000 + i] = ef_fix25_shadow_ready ? ef_fix25_under_roml[i] : ef_fix13_saved_ram8000[i]; /* CRT_FIX25: restore hidden RAM under ROML */
                ef_fix13_basic[i] = ef_fix13_saved_basic[i];
                ef_fix13_kernal[i] = ef_fix13_saved_kernal[i];
        }

        if (roml_active) {
                if (ef_mapper_type == 1 || ef_mapper_type == 3) {
                        /* CRT_FIX41_NORMAL_MAGICDESK_BOOT_COPY: ordinary and
                         * Magic Desk cartridges need CBM80/signature bytes
                         * visible to old direct RAM probes as well as the
                         * mapper-aware CPU read path.
                         */
                        for (i = 0; i < 0x2000; i++)
                                ef_fix13_ram[0x8000 + i] = ef_roml[bank][i];
                } else {
                        /* EasyFlash keeps true hidden RAM beneath ROML. */
                }
        }

        if (romh_a000_active) {
                for (i = 0; i < 0x2000; i++)
                        ef_fix13_basic[i] = ef_romh[bank][i];
        }

        if (romh_e000_active) {
                for (i = 0; i < 0x2000; i++)
                        ef_fix13_kernal[i] = ef_romh[bank][i];
        }

        if (ef_fix13_apply_log_count < 128) {
                ef_logf("CRT_FIX13: live bank apply bank=%u mode=%u ROML=%u A000=%u",
                        bank,
                        m,
                        roml_active,
                        romh_a000_active);
                ef_logf("CRT_FIX13: live bank apply E000=%u control=$%02x saved=%u count=%u",
                        romh_e000_active,
                        ef_control,
                        ef_fix13_saved,
                        ef_fix13_apply_log_count);
                ef_fix13_apply_log_count++;
        }

        ef_fix35_rebuild_cart16_view("apply");
}



int FRFEasyFlashIsLoaded(void)
{
        return ef_loaded;
}

void FRFEasyFlashReset(void)
{
        FRFEasyFlashForce10Stamp("FRFEasyFlashReset");
        if (!ef_loaded)
                return;

        ef_bank = 0;
        memset(ef_ram, 0xff, sizeof(ef_ram));

        if (ef_mapper_type == 2) {
                ef_control = ef_default_mode & 7;

                if (ef_control == 5)
                        ef_log("EasyFlash reset: bank 0, Ultimax/header");
                else if (ef_control == 6)
                        ef_log("EasyFlash reset: bank 0, 8K/header");
                else if (ef_control == 7)
                        ef_log("EasyFlash reset: bank 0, 16K/header");
                else
                        ef_log("EasyFlash reset: bank 0, header/off");

                ef_logf("EasyFlash reset detail: EXROM=%u GAME=%u DEFAULTMODE=%u CONTROL=$%02x",
                        ef_crt_exrom, ef_crt_game, ef_default_mode, ef_control);

        } else if (ef_mapper_type == 1) {
                ef_control = 0x00;
                if (ef_normal_16k)
                        ef_log("Normal CRT reset: fixed 16K cartridge");
                else if (ef_normal_8k)
                        ef_log("Normal CRT reset: fixed 8K cartridge");
                else if (ef_normal_ultimax)
                        ef_log("Normal CRT reset: fixed Ultimax cartridge");
                else
                        ef_log("Normal CRT reset");
        } else if (ef_mapper_type == 3) {
                ef_control = 0x00;
                ef_bank = 0;
                ef_magicdesk_disabled = 0;
                ef_log("CRT_FIX41: Magic Desk reset: bank 0 visible at $8000");
        }

        ef_fix35_rebuild_cart16_view("reset");
}

/* CRT_FIX40_INSERTED_CART_RESET_STATE
 * Restore the inserted cartridge to its power-on bank/mode on every C64
 * reset, then reapply the visible ROM windows before boot continues.
 */
void FRFEasyFlashCPUReset(unsigned char *ram,
                          unsigned char *basic_rom,
                          unsigned char *kernal_rom)
{
        if (!ef_loaded)
                return;

        FRFEasyFlashReset();
        FRFEasyFlashInstallBoot(ram, basic_rom, kernal_rom);
        ef_log("CRT_FIX40: inserted CRT state restored on CPU reset");
}

int FRFEasyFlashROMLActive(void)
{
        int m;

        if (!ef_loaded)
                return 0;

        if (ef_mapper_type == 1)
                return ef_normal_8k || ef_normal_16k || ef_normal_ultimax;

        if (ef_mapper_type == 3)
                return !ef_magicdesk_disabled;

        m = ef_mode();
        return m == 5 || m == 6 || m == 7;
}

int FRFEasyFlashROMH_A000_Active(void)
{
        if (!ef_loaded)
                return 0;

        if (ef_mapper_type == 1)
                return ef_normal_16k;

        /* CRT_FIX41C_MAGICDESK_NO_ROMH:
         * Magic Desk is an 8K ROML-only mapper. It must never inherit the
         * EasyFlash default mode and expose the empty ROMH array at $A000.
         */
        if (ef_mapper_type == 3)
                return 0;

        return ef_mode() == 7;
}

int FRFEasyFlashROMH_E000_Active(void)
{
        if (!ef_loaded)
                return 0;

        if (ef_mapper_type == 1)
                return ef_normal_ultimax;

        /* CRT_FIX41C_MAGICDESK_NO_ROMH:
         * Magic Desk never supplies ROMH at $E000. Without this guard, the
         * inherited EasyFlash mode 5 maps an all-$FF ROMH over the KERNAL and
         * reset vector, producing a black screen.
         */
        if (ef_mapper_type == 3)
                return 0;

        return ef_mode() == 5;
}

unsigned char FRFEasyFlashReadROML(unsigned short off)
{
        return ef_roml[ef_bank & 0x3f][off & 0x1fff];
}

unsigned char FRFEasyFlashReadROMH(unsigned short off)
{
        return ef_romh[ef_bank & 0x3f][off & 0x1fff];
}


/* CRT_FIX32_CPU_ROM_POINTER_ACCESSORS
 *
 * Frodo's PC_IS_POINTER CPU core fetches opcodes through direct pointers.
 * Returning the current bank pointers lets CPUC64.cpp execute cartridge ROM
 * without copying ROML into real C64 RAM. That keeps RAM at $8000-$9FFF as
 * the true hidden/VIC-visible RAM underneath the cartridge.
 */
unsigned char *FRFEasyFlashGetROMLPointer(void)
{
        if (!ef_loaded)
                return 0;

        if (!FRFEasyFlashROMLActive())
                return 0;

        /* CRT_FIX35_SAFE_CART16_VIEW:
         * Return the safe contiguous 16K cart window. CPUC64.cpp subtracts
         * $8000 from this pointer to form pc_base, so sequential fetch from
         * $9FFF to $A000 lands in ROMH only when 16K mode is active.
         */
        ef_fix35_rebuild_cart16_view("romlptr");
        return ef_fix35_cart16_view;
}

unsigned char *FRFEasyFlashGetROMHPointer(void)
{
        if (!ef_loaded)
                return 0;

        if (FRFEasyFlashROMH_A000_Active()) {
                ef_fix35_rebuild_cart16_view("romhptr");
                return ef_fix35_cart16_view + 0x2000;
        }

        if (FRFEasyFlashROMH_E000_Active())
                return ef_romh[ef_bank & 0x3f];

        return 0;
}

unsigned char FRFEasyFlashReadIO1(unsigned short off, unsigned char open_bus)
{
        /*
         * EasyFlash $DE00/$DE02 are write-only. Return open bus.
         */
        (void)off;
        return open_bus;
}

unsigned char FRFEasyFlashReadIO2(unsigned short off, unsigned char open_bus)
{
        if (!ef_loaded)
                return open_bus;

        /* Ordinary fixed cartridges do not expose EasyFlash IO2 RAM. */
        if (ef_mapper_type != 2)
                return open_bus;

        if (ef_io2_read_log_count < 64) {
                ef_logf("CRT_FIX08: read IO2 $DF%02x = $%02x count=%u",
                        off & 0xff,
                        ef_ram[off & 0xff],
                        ef_io2_read_log_count,
                        0);
                ef_io2_read_log_count++;
        }

        return ef_ram[off & 0xff];
}

void FRFEasyFlashWriteIO1(unsigned short off, unsigned char value)
{
        if (!ef_loaded)
                return;

        if (ef_mapper_type == 3) {
                if ((off & 0xff) == 0x00) {
                        ef_bank = value & 0x3f;
                        ef_magicdesk_disabled = (value & 0x80) ? 1 : 0;
                        ef_fix13_apply_live_copy();
                        ef_logf("CRT_FIX41: Magic Desk write bank=%u disabled=%u value=$%02x",
                                ef_bank, ef_magicdesk_disabled, value, 0);
                }
                return;
        }

        if (ef_mapper_type != 2)
                return;

        /*
         * EasyFlash IO1:
         *   $DE00 = bank select
         *   $DE02 = mode/control
         */
        if ((off & 0xff) == 0x00) {
                ef_bank = value & 0x3f;
                /* CRT_FIX13 apply after bank write */
                ef_fix13_apply_live_copy();
                ef_log_easyflash_mode("EasyFlash write $DE00:");
                return;
        }

        if ((off & 0xff) == 0x02) {
                ef_control = value & 0x07;
                /* CRT_FIX13 apply after control write */
                ef_fix13_apply_live_copy();
                ef_log_easyflash_mode("EasyFlash write $DE02:");
                return;
        }
}

void FRFEasyFlashWriteIO2(unsigned short off, unsigned char value)
{
        if (!ef_loaded || ef_mapper_type != 2)
                return;

        ef_ram[off & 0xff] = value;

        /* CRT_FIX27_MIRROR_IO2_TO_RAM
         *
         * Frodo's fast CPU core can fetch opcodes directly from its RAM
         * array instead of calling read_byte() for every byte. EasyFlash
         * helpers deliberately write executable code into IO2 RAM
         * $DF00-$DFFF and jump there.
         *
         * Keep the real EasyFlash IO2 RAM above, but also mirror the byte
         * into Frodo's RAM window so direct opcode fetch sees the helper.
         */
        if (ef_fix13_ram) {
                ef_fix13_ram[0xdf00 + (off & 0xff)] = value;
        }

        if (ef_io2_write_log_count < 128) {
                ef_logf("CRT_FIX27: mirrored IO2 opcode RAM $%04x = $%02x",
                        0xdf00 + (off & 0xff),
                        value,
                        ef_io2_write_log_count,
                        0);
        }

        if (ef_io2_write_log_count < 128) {
                ef_logf("CRT_FIX08: write IO2 $DF%02x = $%02x count=%u",
                        off & 0xff,
                        value,
                        ef_io2_write_log_count,
                        0);
                ef_io2_write_log_count++;
        }
}


/* CRT_FIX25_WRITE_UNDER_ROML_FUNCTION */
void FRFEasyFlashWriteUnderROML(unsigned short off, unsigned char value)
{
        unsigned int i;

        if (!ef_loaded)
                return;

        off &= 0x1fff;

        if (!ef_fix25_shadow_ready) {
                if (ef_fix13_saved) {
                        for (i = 0; i < 0x2000; i++)
                                ef_fix25_under_roml[i] = ef_fix13_saved_ram8000[i];
                } else {
                        for (i = 0; i < 0x2000; i++)
                                ef_fix25_under_roml[i] = 0;
                }

                ef_fix25_shadow_ready = 1;
                ef_log("CRT_FIX25: late initialized hidden RAM under ROML");
        }

        ef_fix25_under_roml[off] = value;

        if (ef_fix25_shadow_log_count < 128) {
                ef_logf("CRT_FIX25: shadow write under ROML $%04x = $%02x",
                        0x8000 + off,
                        value,
                        ef_fix25_shadow_log_count,
                        0);
                ef_fix25_shadow_log_count++;
        }
}

int FRFEasyFlashLoadCRT(const char *path)
{
        FILE *f;
        unsigned char hdr[0x40];
        unsigned long header_len;
        unsigned short cart_type;
        unsigned char chip[0x10];
        int chips = 0;
        int roml_chips = 0;
        int romh_chips = 0;

        f = ef_open_crt_file(path);
        if (!f) {
                ef_log("CRT load failed: cannot open CRT");
                return 0;
        }

        if (fread(hdr, 1, sizeof(hdr), f) != sizeof(hdr)) {
                fclose(f);
                ef_log("CRT load failed: short CRT header");
                return 0;
        }

        if (memcmp(hdr, "C64 CARTRIDGE", 13) != 0) {
                fclose(f);
                ef_log("CRT load failed: not C64 CARTRIDGE");
                return 0;
        }

        header_len = be32(hdr + 0x10);
        cart_type = be16(hdr + 0x16);

        if (header_len < 0x40) {
                fclose(f);
                ef_log("CRT load failed: invalid header length");
                return 0;
        }

        /* CRT_FIX37_NORMAL_CRT_SAFE_SPLIT
         * Hardware type 0 is the normal fixed 8K/16K/Ultimax format.
         * Keep it separate from the already-working EasyFlash type-32 path.
         */
        if (cart_type == 0) {
                ef_mapper_type = 1;
                ef_magicdesk_disabled = 0;
                ef_crt_exrom = hdr[0x18] & 1;
                ef_crt_game = hdr[0x19] & 1;
                /* Magic Desk is ROML-only. Do not inherit EasyFlash's
                 * default Ultimax mode (5), which would expose empty ROMH. */
                ef_default_mode = 0;
                ef_bank = 0;
                ef_control = 0;
                ef_normal_8k = 0;
                ef_normal_16k = 0;
                ef_normal_ultimax = 0;

                memset(ef_roml, 0xff, sizeof(ef_roml));
                memset(ef_romh, 0xff, sizeof(ef_romh));
                memset(ef_ram, 0xff, sizeof(ef_ram));

                if (fseek(f, header_len, SEEK_SET) != 0) {
                        fclose(f);
                        ef_log("Normal CRT load failed: cannot seek to CHIP data");
                        return 0;
                }

                while (fread(chip, 1, sizeof(chip), f) == sizeof(chip)) {
                        unsigned long packet_len;
                        unsigned short bank;
                        unsigned short addr;
                        unsigned short size;
                        unsigned char buf[0x4000];

                        if (memcmp(chip, "CHIP", 4) != 0)
                                break;

                        packet_len = be32(chip + 4);
                        bank = be16(chip + 10);
                        addr = be16(chip + 12);
                        size = be16(chip + 14);

                        if (packet_len < 0x10 || size == 0 || size > sizeof(buf)) {
                                fclose(f);
                                ef_log("Normal CRT load failed: invalid CHIP packet");
                                return 0;
                        }

                        memset(buf, 0xff, sizeof(buf));
                        if (fread(buf, 1, size, f) != size) {
                                fclose(f);
                                ef_log("Normal CRT load failed: short CHIP data");
                                return 0;
                        }

                        /* Fixed type-0 cartridges normally use bank 0. Ignore
                         * duplicate/nonzero banks rather than letting them
                         * overwrite the visible fixed image.
                         */
                        if (bank == 0) {
                                if (addr == 0x8000) {
                                        unsigned int first = size > 0x2000 ? 0x2000 : size;
                                        memcpy(ef_roml[0], buf, first);
                                        roml_chips++;

                                        if (size > 0x2000) {
                                                unsigned int second = size - 0x2000;
                                                if (second > 0x2000)
                                                        second = 0x2000;
                                                memcpy(ef_romh[0], buf + 0x2000, second);
                                                romh_chips++;
                                        }
                                } else if (addr == 0xa000 || addr == 0xe000) {
                                        unsigned int amount = size > 0x2000 ? 0x2000 : size;
                                        memcpy(ef_romh[0], buf, amount);
                                        romh_chips++;
                                }
                        }

                        chips++;
                        if (packet_len > 0x10UL + (unsigned long)size)
                                fseek(f, packet_len - 0x10 - size, SEEK_CUR);
                }

                fclose(f);

                if (!roml_chips && !romh_chips) {
                        ef_log("Normal CRT load failed: no usable ROM chips");
                        return 0;
                }

                ef_fix37_configure_normal_crt(roml_chips, romh_chips);
                ef_loaded = 1;
                FRFEasyFlashReset();
                ef_log("CRT_FIX37: normal type-0 cartridge loaded");
                return 1;
        }

        /* CRT_FIX41_MAGIC_DESK
         * Hardware type 19 is the common Magic Desk/Domark/HES banked 8K
         * format used by single-game CRTs such as Who Dares Wins.  $DE00
         * selects a ROML bank; bit 7 disables the cartridge.
         */
        if (cart_type == 19) {
                ef_mapper_type = 3;
                ef_crt_exrom = hdr[0x18] & 1;
                ef_crt_game = hdr[0x19] & 1;
                ef_bank = 0;
                ef_control = 0;
                ef_magicdesk_disabled = 0;
                ef_normal_8k = 0;
                ef_normal_16k = 0;
                ef_normal_ultimax = 0;

                memset(ef_roml, 0xff, sizeof(ef_roml));
                memset(ef_romh, 0xff, sizeof(ef_romh));
                memset(ef_ram, 0xff, sizeof(ef_ram));

                if (fseek(f, header_len, SEEK_SET) != 0) {
                        fclose(f);
                        ef_log("Magic Desk CRT load failed: cannot seek to CHIP data");
                        return 0;
                }

                while (fread(chip, 1, sizeof(chip), f) == sizeof(chip)) {
                        unsigned long packet_len;
                        unsigned short bank;
                        unsigned short addr;
                        unsigned short size;
                        unsigned char buf[0x2000];

                        if (memcmp(chip, "CHIP", 4) != 0)
                                break;

                        packet_len = be32(chip + 4);
                        bank = be16(chip + 10);
                        addr = be16(chip + 12);
                        size = be16(chip + 14);

                        if (packet_len < 0x10 || bank >= 64 || size == 0 || size > sizeof(buf)) {
                                fclose(f);
                                ef_log("Magic Desk CRT load failed: invalid CHIP packet");
                                return 0;
                        }

                        memset(buf, 0xff, sizeof(buf));
                        if (fread(buf, 1, size, f) != size) {
                                fclose(f);
                                ef_log("Magic Desk CRT load failed: short CHIP data");
                                return 0;
                        }

                        if (addr == 0x8000) {
                                memcpy(ef_roml[bank], buf, size);
                                roml_chips++;
                        }

                        chips++;
                        if (packet_len > 0x10UL + (unsigned long)size)
                                fseek(f, packet_len - 0x10 - size, SEEK_CUR);
                }

                fclose(f);

                if (!roml_chips) {
                        ef_log("Magic Desk CRT load failed: no ROML banks");
                        return 0;
                }

                ef_loaded = 1;
                FRFEasyFlashReset();
                ef_logf("CRT_FIX41: Magic Desk type 19 loaded ROML banks=%u",
                        roml_chips, 0, 0, 0);
                return 1;
        }

        /* Preserve the existing known-good EasyFlash path exactly for type 32. */
        if (cart_type != 32) {
                fclose(f);
                ef_logf("CRT load failed: unsupported hardware type=%u (supported 0 and 32)",
                        cart_type, 0, 0, 0);
                return 0;
        }

        ef_mapper_type = 2;
        ef_magicdesk_disabled = 0;
        ef_default_mode = 5;
        ef_crt_exrom = 1;
        ef_crt_game = 0;
        ef_normal_8k = 0;
        ef_normal_16k = 0;
        ef_normal_ultimax = 0;
        ef_bank = 0;
        ef_control = 0x07;

        memset(ef_roml, 0xff, sizeof(ef_roml));
        memset(ef_romh, 0xff, sizeof(ef_romh));
        memset(ef_ram, 0xff, sizeof(ef_ram));

        fseek(f, header_len, SEEK_SET);

        while (fread(chip, 1, sizeof(chip), f) == sizeof(chip)) {
                unsigned long packet_len;
                unsigned short bank;
                unsigned short addr;
                unsigned short size;
                unsigned char buf[0x2000];

                if (memcmp(chip, "CHIP", 4) != 0)
                        break;

                packet_len = be32(chip + 4);
                bank = be16(chip + 10);
                addr = be16(chip + 12);
                size = be16(chip + 14);

                if (bank >= 64 || size > 0x2000) {
                        fclose(f);
                        ef_log("EasyFlash load failed: invalid CHIP bank/size");
                        return 0;
                }

                memset(buf, 0xff, sizeof(buf));

                if (fread(buf, 1, size, f) != size) {
                        fclose(f);
                        ef_log("EasyFlash load failed: short CHIP data");
                        return 0;
                }

                if (addr == 0x8000) {
                        memcpy(ef_roml[bank], buf, size);
                        roml_chips++;
                } else if (addr == 0xa000) {
                        memcpy(ef_romh[bank], buf, size);
                        romh_chips++;
                }

                chips++;

                if (packet_len > 0x10UL + (unsigned long)size)
                        fseek(f, packet_len - 0x10 - size, SEEK_CUR);
        }

        fclose(f);

        if (roml_chips == 0 || romh_chips == 0) {
                ef_log("EasyFlash load failed: missing ROML/ROMH chips");
                return 0;
        }

        ef_loaded = 1;
        FRFEasyFlashReset();

        ef_log("EasyFlash CRT loaded");
        return 1;
}


unsigned short FRFEasyFlashGetResetVector(void)
{
        /*
         * In Ultimax mode, C64 reset vector $FFFC/$FFFD is ROMH offset
         * $1FFC/$1FFD of the currently selected bank.
         */
        unsigned char lo = ef_romh[ef_bank & 0x3f][0x1ffc];
        unsigned char hi = ef_romh[ef_bank & 0x3f][0x1ffd];

        return (unsigned short)(lo | ((unsigned short)hi << 8));
}

void FRFEasyFlashLogCPUResetVector(unsigned short old_pc, unsigned short new_pc)
{
        FILE *f = FRFOpenDiagnosticLog("PROGDIR:frodo-easyflash.log", "frodo-easyflash.log", "a");

        if (!f)
                return;

        fprintf(f,
                "CPU Reset vector override: old=$%04x new=$%04x bank=%u mode=%u control=$%02x\n",
                (unsigned int)old_pc,
                (unsigned int)new_pc,
                (unsigned int)(ef_bank & 0x3f),
                (unsigned int)ef_mode(),
                (unsigned int)ef_control);

        fclose(f);
}

void FRFEasyFlashLogLoadedVectors(void)
{
        FILE *f = FRFOpenDiagnosticLog("PROGDIR:frodo-easyflash.log", "frodo-easyflash.log", "a");

        if (!f)
                return;

        fprintf(f, "EasyFlash bank0 ROML $8000 bytes: %02x %02x %02x %02x %02x %02x %02x %02x\n",
                ef_roml[0][0], ef_roml[0][1], ef_roml[0][2], ef_roml[0][3],
                ef_roml[0][4], ef_roml[0][5], ef_roml[0][6], ef_roml[0][7]);

        fprintf(f, "EasyFlash bank0 ROMH $E000 bytes: %02x %02x %02x %02x %02x %02x %02x %02x\n",
                ef_romh[0][0], ef_romh[0][1], ef_romh[0][2], ef_romh[0][3],
                ef_romh[0][4], ef_romh[0][5], ef_romh[0][6], ef_romh[0][7]);

        fprintf(f, "EasyFlash bank0 ROMH reset bytes $FFFC: %02x %02x %02x %02x\n",
                ef_romh[0][0x1ffc], ef_romh[0][0x1ffd],
                ef_romh[0][0x1ffe], ef_romh[0][0x1fff]);

        fprintf(f, "EasyFlash bank0 reset vector: $%04x\n",
                (unsigned int)(ef_romh[0][0x1ffc] | ((unsigned int)ef_romh[0][0x1ffd] << 8)));

        fclose(f);
}



/*
 * CRT_BOOTINSTALL07:
 * Force initial cartridge boot mapping into the active Frodo memory arrays.
 *
 * This is deliberately a boot install, not a full mapper replacement.
 * It fixes the current black-screen failure where CRT is loaded but the CPU
 * reset path never actually sees the EasyFlash ROMH reset vector.
 */
void FRFEasyFlashInstallBoot(unsigned char *ram,
                             unsigned char *basic_rom,
                             unsigned char *kernal_rom)
{
        /*
         * CRT_FIX13:
         * register live memory pointers so $DE00/$DE02 bank switches
         * can update the actual Frodo ROM/RAM windows.
         */
        ef_fix13_ram = ram;
        ef_fix13_basic = basic_rom;
        ef_fix13_kernal = kernal_rom;

        ef_fix13_apply_live_copy();


        unsigned int i;
        unsigned int bank;

        if (!ef_loaded) {
                ef_log("CRT_BOOTINSTALL07: skipped, no CRT loaded");
                return;
        }

        if (!ram || !basic_rom || !kernal_rom) {
                ef_log("CRT_BOOTINSTALL07: skipped, null memory pointer");
                return;
        }

        bank = ef_bank & 0x3f;

        /*
         * ROML visible at $8000-$9fff.
         * Copy into RAM window so even old/inline CPU paths can execute it.
         */
        if (FRFEasyFlashROMLActive()) {
                if (ef_mapper_type == 1 || ef_mapper_type == 3) {
                        for (i = 0; i < 0x2000; i++)
                                ram[0x8000 + i] = ef_roml[bank][i];
                        ef_logf("CRT_FIX41: normal/Magic ROML bank=%u installed at $8000", bank, 0, 0, 0);
                } else {
                        /* EasyFlash retains its RAM underlay and uses the CPU
                         * cartridge pointer for ROML execution.
                         */
                        ef_logf("CRT_FIX32: ROML bank=%u CPU-pointer mapped, RAM underlay kept at $8000", bank, 0, 0, 0);
                }
        }

        /*
         * 16K mode ROMH visible at $a000-$bfff.
         * Frodo usually maps this through Basic ROM pointer.
         */
        if (FRFEasyFlashROMH_A000_Active()) {
                for (i = 0; i < 0x2000; i++)
                        basic_rom[i] = ef_romh[bank][i];

                ef_logf("CRT_BOOTINSTALL07: installed ROMH bank=%u at $a000", bank, 0, 0, 0);
        }

        /*
         * Ultimax mode ROMH visible at $e000-$ffff.
         * Frodo reset usually reads the vector through Kernal ROM pointer.
         */
        if (FRFEasyFlashROMH_E000_Active()) {
                for (i = 0; i < 0x2000; i++)
                        kernal_rom[i] = ef_romh[bank][i];

                ef_logf("CRT_BOOTINSTALL07: installed ROMH bank=%u at $e000", bank, 0, 0, 0);
                ef_logf("CRT_BOOTINSTALL07: reset vector bytes lo=$%02x hi=$%02x pc=$%02x%02x",
                        ef_romh[bank][0x1ffc],
                        ef_romh[bank][0x1ffd],
                        ef_romh[bank][0x1ffd],
                        ef_romh[bank][0x1ffc]);
        }

        ef_log("CRT_BOOTINSTALL07: boot install complete");
}



/*
 * CRT_FORCE10:
 * Hard proof that the new CRT/EasyFlash binary is running.
 */
void FRFEasyFlashForce10Stamp(const char *where)
{
        FILE *f = FRFOpenDiagnosticLog("PROGDIR:frodo-easyflash.log", "frodo-easyflash.log", "a");

        if (!f)
                return;

        fprintf(f, "CRT_FORCE10_ACTIVE: %s\n", where ? where : "(null)");
        fclose(f);
}

/*
 * CRT_FORCE10:
 * Frodo 4.1b blocks jumps into $D000-$DFFF as "I/O space".
 * EasyFlash deliberately executes helper/EAPI code from IO2 RAM
 * at $DF00-$DFFF, so suppress that requester while a CRT is active.
 */
void FRFEasyFlashSuppressIOJump(void)
{
        FILE *f = FRFOpenDiagnosticLog("PROGDIR:frodo-easyflash.log", "frodo-easyflash.log", "a");

        if (!f)
                return;

        fprintf(f, "CRT_FORCE10: suppressed Frodo I/O-space jump requester\n");
        fclose(f);
}



/*
 * CRT_FORCE11:
 * EasyFlash executes helper/EAPI code from IO2 RAM at $DF00-$DFFF.
 * Frodo's old jump-to-I/O guard must allow this for CRTs.
 */
int FRFEasyFlashAllowIO2Execute(unsigned short from, unsigned short to)
{
        FILE *f;

        if (!FRFEasyFlashIsLoaded())
                return 0;

        if (ef_mapper_type != 2)
                return 0;

        if (to < 0xdf00 || to > 0xdfff)
                return 0;

        f = FRFOpenDiagnosticLog("PROGDIR:frodo-easyflash.log", "frodo-easyflash.log", "a");

        if (f) {
                fprintf(f,
                        "CRT_FORCE11: allowed EasyFlash IO2 execute from $%04x to $%04x\n",
                        (unsigned int)from,
                        (unsigned int)to);
                fclose(f);
        }

        return 1;
}

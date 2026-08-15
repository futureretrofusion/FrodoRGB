/* Modified 2026-06-28 by Future Retro Fusion for FRF 2026 Frodo RTG. */
#ifndef FRF_EASYFLASH_H
#define FRF_EASYFLASH_H
/* CRT_FIX35 header: same pointer API, safer FRFEasyFlash.cpp implementation. */

int FRFEasyFlashLoadCRT(const char *path);
void FRFEasyFlashReset(void);
int FRFEasyFlashIsLoaded(void);

int FRFEasyFlashROMLActive(void);
int FRFEasyFlashROMH_A000_Active(void);
int FRFEasyFlashROMH_E000_Active(void);

unsigned char FRFEasyFlashReadROML(unsigned short off);
unsigned char FRFEasyFlashReadROMH(unsigned short off);
unsigned char *FRFEasyFlashGetROMLPointer(void);
unsigned char *FRFEasyFlashGetROMHPointer(void);
unsigned char FRFEasyFlashReadIO1(unsigned short off, unsigned char open_bus);
unsigned char FRFEasyFlashReadIO2(unsigned short off, unsigned char open_bus);

void FRFEasyFlashWriteIO1(unsigned short off, unsigned char value);
void FRFEasyFlashWriteIO2(unsigned short off, unsigned char value);
void FRFEasyFlashWriteUnderROML(unsigned short off, unsigned char value);

void FRFEasyFlashInstallBoot(unsigned char *ram, unsigned char *basic_rom, unsigned char *kernal_rom);
void FRFEasyFlashCPUReset(unsigned char *ram, unsigned char *basic_rom, unsigned char *kernal_rom);

unsigned short FRFEasyFlashGetResetVector(void);
void FRFEasyFlashLogCPUResetVector(unsigned short old_pc, unsigned short new_pc);

void FRFEasyFlashForce10Stamp(const char *where);
void FRFEasyFlashSuppressIOJump(void);
int FRFEasyFlashAllowIO2Execute(unsigned short from, unsigned short to);
#endif

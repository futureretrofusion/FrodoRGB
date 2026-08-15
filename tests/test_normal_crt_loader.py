#!/usr/bin/env python3
"""Compile and exercise the real FRFEasyFlash CRT loader on the host.

This does not emulate a C64. It verifies CRT parsing and the visible ROM windows
for ordinary type-0 8K/16K/Ultimax images and preserves type-32 EasyFlash.
"""
from __future__ import print_function

import os
import shutil
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def be16(value):
    return struct.pack(">H", value)


def be32(value):
    return struct.pack(">I", value)


def write_crt(path, cart_type, exrom, game, chips):
    header = bytearray(0x40)
    header[0:16] = b"C64 CARTRIDGE   "
    header[0x10:0x14] = be32(0x40)
    header[0x14:0x16] = be16(0x0100)
    header[0x16:0x18] = be16(cart_type)
    header[0x18] = exrom
    header[0x19] = game

    with open(str(path), "wb") as handle:
        handle.write(header)
        for bank, address, data in chips:
            packet = bytearray(0x10)
            packet[0:4] = b"CHIP"
            packet[4:8] = be32(0x10 + len(data))
            packet[8:10] = be16(0)  # ROM CHIP packet
            packet[10:12] = be16(bank)
            packet[12:14] = be16(address)
            packet[14:16] = be16(len(data))
            handle.write(packet)
            handle.write(data)


def run():
    compiler = shutil.which("g++")
    if compiler is None:
        print("SKIP: g++ is not installed; source-level test remains available")
        return 0

    with tempfile.TemporaryDirectory(prefix="frf-crt-test-") as temp_name:
        temp = Path(temp_name)
        for name in ("FRFEasyFlash.cpp", "FRFEasyFlash.h", "FRFBuildConfig.h", "FRFDiagnostics.h"):
            shutil.copy2(str(ROOT / name), str(temp / name))
        (temp / "sysdeps.h").write_text("#ifndef SYSDEPS_H\n#define SYSDEPS_H\n#endif\n")

        harness = r'''#include "FRFEasyFlash.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void need(int condition, const char *message)
{
    if (!condition) {
        fprintf(stderr, "FAIL: %s\n", message);
        exit(1);
    }
}

int main(int argc, char **argv)
{
    unsigned char ram[65536];
    unsigned char basic[8192];
    unsigned char kernal[8192];
    const char *mode;

    need(argc == 3, "usage: harness MODE CRT");
    mode = argv[1];
    memset(ram, 0x91, sizeof(ram));
    memset(basic, 0x92, sizeof(basic));
    memset(kernal, 0x93, sizeof(kernal));

    need(FRFEasyFlashLoadCRT(argv[2]) == 1, "CRT loader rejected test image");
    need(FRFEasyFlashIsLoaded() == 1, "loaded flag not set");

    if (!strcmp(mode, "8k")) {
        need(FRFEasyFlashROMLActive(), "8K ROML not active");
        need(!FRFEasyFlashROMH_A000_Active(), "8K unexpectedly maps ROMH at A000");
        need(!FRFEasyFlashROMH_E000_Active(), "8K unexpectedly maps ROMH at E000");
        need(FRFEasyFlashReadROML(0) == 0x11, "8K ROML contents wrong");
        FRFEasyFlashInstallBoot(ram, basic, kernal);
        need(ram[0x8000] == 0x11, "8K boot ROML not copied to 8000");
    } else if (!strcmp(mode, "16k")) {
        need(FRFEasyFlashROMLActive(), "16K ROML not active");
        need(FRFEasyFlashROMH_A000_Active(), "16K ROMH not active at A000");
        need(!FRFEasyFlashROMH_E000_Active(), "16K unexpectedly maps ROMH at E000");
        need(FRFEasyFlashReadROML(0) == 0x22, "16K ROML contents wrong");
        need(FRFEasyFlashReadROMH(0) == 0x33, "16K ROMH contents wrong");
        FRFEasyFlashInstallBoot(ram, basic, kernal);
        need(ram[0x8000] == 0x22, "16K boot ROML not copied to 8000");
        need(basic[0] == 0x33, "16K boot ROMH not mapped at A000");
    } else if (!strcmp(mode, "ultimax")) {
        need(FRFEasyFlashROMLActive(), "Ultimax ROML not active");
        need(!FRFEasyFlashROMH_A000_Active(), "Ultimax unexpectedly maps ROMH at A000");
        need(FRFEasyFlashROMH_E000_Active(), "Ultimax ROMH not active at E000");
        need(FRFEasyFlashReadROML(0) == 0x44, "Ultimax ROML contents wrong");
        need(FRFEasyFlashReadROMH(0) == 0x55, "Ultimax ROMH contents wrong");
        FRFEasyFlashInstallBoot(ram, basic, kernal);
        need(ram[0x8000] == 0x44, "Ultimax boot ROML not copied to 8000");
        need(kernal[0] == 0x55, "Ultimax boot ROMH not mapped at E000");
    } else if (!strcmp(mode, "magicdesk")) {
        need(FRFEasyFlashROMLActive(), "Magic Desk bank 0 not active");
        need(!FRFEasyFlashROMH_A000_Active(), "Magic Desk unexpectedly maps ROMH at A000");
        need(!FRFEasyFlashROMH_E000_Active(), "Magic Desk unexpectedly maps ROMH at E000");
        need(FRFEasyFlashReadROML(0) == 0x80, "Magic Desk bank 0 contents wrong");
        FRFEasyFlashInstallBoot(ram, basic, kernal);
        need(ram[0x8000] == 0x80, "Magic Desk bank 0 boot copy missing");
        need(kernal[0] == 0x93 && kernal[0x1ffc] == 0x93 && kernal[0x1ffd] == 0x93,
             "Magic Desk boot install corrupted KERNAL/reset vector");
        /* Simulate Frodo's reset-time CBM80 removal, then verify the
         * inserted-cartridge reset hook restores bank 0 and its signature. */
        ram[0x8004] = 0x00;
        FRFEasyFlashCPUReset(ram, basic, kernal);
        need(ram[0x8000] == 0x80, "Magic Desk CPU reset did not restore bank 0");
        need(ram[0x8004] == 0x80, "Magic Desk CPU reset did not restore ROML bytes");
        need(!FRFEasyFlashROMH_E000_Active(), "Magic Desk CPU reset enabled ROMH at E000");
        need(kernal[0] == 0x93 && kernal[0x1ffc] == 0x93 && kernal[0x1ffd] == 0x93,
             "Magic Desk CPU reset corrupted KERNAL/reset vector");
        FRFEasyFlashWriteIO1(0, 3);
        need(FRFEasyFlashROMLActive(), "Magic Desk bank 3 not active");
        need(FRFEasyFlashReadROML(0) == 0x83, "Magic Desk bank switch failed");
        need(ram[0x8000] == 0x83, "Magic Desk live bank copy failed");
        FRFEasyFlashWriteIO1(0, 0x87);
        need(!FRFEasyFlashROMLActive(), "Magic Desk bit-7 disable failed");
        need(ram[0x8000] == 0x91, "Magic Desk disable did not restore hidden RAM");
        FRFEasyFlashWriteIO1(0, 2);
        need(FRFEasyFlashROMLActive(), "Magic Desk re-enable failed");
        need(FRFEasyFlashReadROML(0) == 0x82, "Magic Desk re-enabled bank wrong");
    } else if (!strcmp(mode, "easyflash")) {
        need(FRFEasyFlashROMLActive(), "EasyFlash ROML path regressed");
        need(FRFEasyFlashROMH_E000_Active(), "EasyFlash reset ROMH path regressed");
        need(FRFEasyFlashReadROML(0) == 0x66, "EasyFlash ROML contents wrong");
        need(FRFEasyFlashReadROMH(0) == 0x77, "EasyFlash ROMH contents wrong");
    } else {
        need(0, "unknown test mode");
    }

    return 0;
}
'''
        (temp / "harness.cpp").write_text(harness)

        subprocess.check_call([
            compiler, "-std=gnu++98", "-Wall", "-Wextra", "-I", str(temp),
            str(temp / "FRFEasyFlash.cpp"), str(temp / "harness.cpp"),
            "-o", str(temp / "crt_loader_test")
        ])

        rom8 = bytes([0x11]) * 0x2000
        roml16 = bytes([0x22]) * 0x2000
        romh16 = bytes([0x33]) * 0x2000
        romlu = bytes([0x44]) * 0x2000
        romhu = bytearray([0x55]) * 0x2000
        romhu[0x1FFC] = 0x00
        romhu[0x1FFD] = 0xE0
        romlef = bytes([0x66]) * 0x2000
        romhef = bytes([0x77]) * 0x2000

        magicdesk = [(bank, 0x8000, bytes([0x80 + bank]) * 0x2000) for bank in range(8)]

        cases = [
            ("8k", 0, 0, 1, [(0, 0x8000, rom8)]),
            ("16k", 0, 0, 0, [(0, 0x8000, roml16), (0, 0xA000, romh16)]),
            ("ultimax", 0, 1, 0, [(0, 0x8000, romlu), (0, 0xE000, bytes(romhu))]),
            ("magicdesk", 19, 0, 1, magicdesk),
            ("easyflash", 32, 1, 0, [(0, 0x8000, romlef), (0, 0xA000, romhef)]),
        ]

        for mode, cart_type, exrom, game, chips in cases:
            image = temp / (mode + ".crt")
            write_crt(image, cart_type, exrom, game, chips)
            subprocess.check_call([str(temp / "crt_loader_test"), mode, str(image)])

    print("host CRT loader tests passed: type-0 8K/16K/Ultimax, type-19 Magic Desk ROML-only boot, and type-32 EasyFlash")
    return 0


if __name__ == "__main__":
    sys.exit(run())

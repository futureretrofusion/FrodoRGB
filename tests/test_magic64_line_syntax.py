#!/usr/bin/env python3
from pathlib import Path
import os
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / "Display_Amiga.i").read_text(encoding="utf-8", errors="replace")
start = source.index("static struct ScreenBuffer *FRFMagic64LineBuffers")
end = source.index("\n\nstatic void FRFBlitC64Frame", start)
block = source[start:end]

compiler = "/usr/bin/g++" if Path("/usr/bin/g++").is_file() else shutil.which("g++")
if compiler is None:
    print("SKIP: native g++ is not installed")
    raise SystemExit(0)

env = os.environ.copy()
for key in (
    "GCC_EXEC_PREFIX", "COMPILER_PATH", "LIBRARY_PATH", "C_INCLUDE_PATH",
    "CPLUS_INCLUDE_PATH", "OBJC_INCLUDE_PATH", "LD_LIBRARY_PATH", "LD",
    "CC", "CXX", "AR", "AS", "NM", "RANLIB", "STRIP"
):
    env.pop(key, None)
env["PATH"] = "/usr/bin:/bin"

stub = r'''
typedef unsigned char UBYTE;
typedef unsigned short UWORD;
typedef unsigned long ULONG;
typedef long LONG;
typedef void *APTR;
struct MsgPort;
struct Message { MsgPort *mn_ReplyPort; };
struct MsgPort {};
struct BitMap { int Depth; };
struct RastPort { struct BitMap *BitMap; };
struct DBufInfo { struct Message dbi_SafeMessage; APTR dbi_UserData1; };
struct ScreenBuffer { struct BitMap *sb_BitMap; struct DBufInfo *sb_DBufInfo; };
struct Screen { struct RastPort RastPort; int Width; int Height; };
int FRFAslFullscreenActive = 1;
int FrodoFRFNativePAL320 = 1;
int FrodoFRFNoDisplay = 0;
LONG FRFFullscreenViewX = 0;
LONG FRFFullscreenViewY = 0;
#define SB_SCREEN_BITMAP 1
#define SB_COPY_BITMAP 2
#define NULL 0
int FRFOutputScale() { return 1; }
int FRFScreenIsCyberGfxMode(Screen *) { return 0; }
void InitRastPort(RastPort *) {}
Message *GetMsg(MsgPort *) { return 0; }
void WaitPort(MsgPort *) {}
int ChangeScreenBuffer(Screen *, ScreenBuffer *) { return 1; }
void WaitTOF() {}
void FreeScreenBuffer(Screen *, ScreenBuffer *) {}
void DeleteMsgPort(MsgPort *) {}
MsgPort *CreateMsgPort() { return (MsgPort *)1; }
ScreenBuffer *AllocScreenBuffer(Screen *, BitMap *, ULONG) { return (ScreenBuffer *)1; }
void SetRast(RastPort *, int) {}
void FrodoFRFTrace(const char *) {}
void WritePixelLine8(RastPort *, UWORD, UWORD, UWORD, UBYTE *, RastPort *) {}
'''

with tempfile.TemporaryDirectory(prefix="frf-magic64-line-") as td:
    test_cpp = Path(td) / "test.cpp"
    test_cpp.write_text(stub + "\n" + block + "\nint main(){return 0;}\n")
    subprocess.check_call([
        compiler, "-std=gnu++98", "-Wall", "-Wextra", "-fpermissive",
        "-fsyntax-only", str(test_cpp)
    ], env=env)

print("MagiC64-style native line block C++98 syntax check passed")

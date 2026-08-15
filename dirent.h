#ifndef FRODO_AMIGA_LOCAL_DIRENT_H
#define FRODO_AMIGA_LOCAL_DIRENT_H

/*
 * Tiny AmigaOS dirent compatibility layer for Frodo.
 * The m68k-amigaos-gcc sys/dirent.h says "not supported", but Frodo's
 * 1541fs.cpp only needs opendir(), readdir(), closedir(), and d_name.
 */

#include <exec/types.h>
#include <exec/memory.h>
#include <dos/dos.h>
#include <dos/dostags.h>
#include <proto/exec.h>
#include <proto/dos.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

struct dirent {
	char d_name[108];
};

typedef struct FrodoAmigaDIR {
	BPTR lock;
	struct FileInfoBlock *fib;
	struct dirent ent;
	int ready;
} DIR;

static inline DIR *opendir(const char *path)
{
	DIR *d;
	const char *use_path = (path && path[0]) ? path : ".";

	d = (DIR *)AllocVec(sizeof(DIR), MEMF_CLEAR);
	if (!d)
		return 0;

	d->fib = (struct FileInfoBlock *)AllocDosObject(DOS_FIB, 0);
	if (!d->fib) {
		FreeVec(d);
		return 0;
	}

	d->lock = Lock((CONST_STRPTR)use_path, ACCESS_READ);
	if (!d->lock) {
		FreeDosObject(DOS_FIB, d->fib);
		FreeVec(d);
		return 0;
	}

	if (!Examine(d->lock, d->fib)) {
		UnLock(d->lock);
		FreeDosObject(DOS_FIB, d->fib);
		FreeVec(d);
		return 0;
	}

	d->ready = 1;
	return d;
}

static inline struct dirent *readdir(DIR *d)
{
	if (!d || !d->ready)
		return 0;

	if (!ExNext(d->lock, d->fib))
		return 0;

	strncpy(d->ent.d_name, (const char *)d->fib->fib_FileName, sizeof(d->ent.d_name) - 1);
	d->ent.d_name[sizeof(d->ent.d_name) - 1] = 0;

	return &d->ent;
}

static inline int closedir(DIR *d)
{
	if (!d)
		return -1;

	if (d->lock)
		UnLock(d->lock);

	if (d->fib)
		FreeDosObject(DOS_FIB, d->fib);

	FreeVec(d);
	return 0;
}

#ifdef __cplusplus
}
#endif

#endif

/*
 * Amiga NDK inline headers define DOS calls like Open/Read/Write/Close
 * as macros. Frodo has C++ methods with the same names, e.g.
 * Drive::Open() and Drive::Read(), so these macros must not leak out.
 */
#ifndef FRODO_AMIGADOS_MACRO_CLEANUP
#define FRODO_AMIGADOS_MACRO_CLEANUP
#ifdef Open
#undef Open
#endif
#ifdef Read
#undef Read
#endif
#ifdef Write
#undef Write
#endif
#ifdef Close
#undef Close
#endif
#ifdef Seek
#undef Seek
#endif
#endif

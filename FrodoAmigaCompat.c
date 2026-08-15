/*
 * Frodo AmigaOS compatibility shims for m68k-amigaos-gcc/libnix style builds.
 */

#include <exec/types.h>
#include <exec/tasks.h>
#include <dos/dos.h>
#include <dos/dosextens.h>
#include <proto/exec.h>
#include <proto/dos.h>
#include <string.h>
#include <stddef.h>
#include <sys/stat.h>
#include <signal.h>

char *getcwd(char *buf, size_t size)
{
	struct Process *proc;
	BPTR lock;

	if (!buf || size == 0)
		return 0;

	buf[0] = 0;

	proc = (struct Process *)FindTask(0);
	if (!proc)
		return 0;

	lock = proc->pr_CurrentDir;
	if (!lock)
		return 0;

	if (!NameFromLock(lock, (STRPTR)buf, (LONG)size))
		return 0;

	return buf;
}

int chdir(const char *path)
{
	BPTR lock;
	BPTR old;

	if (!path)
		return -1;

	lock = Lock((CONST_STRPTR)path, ACCESS_READ);
	if (!lock)
		return -1;

	old = CurrentDir(lock);

	if (old)
		UnLock(old);

	return 0;
}

int stat(const char *path, struct stat *st)
{
	BPTR lock;
	struct FileInfoBlock *fib;

	if (!path || !st)
		return -1;

	memset(st, 0, sizeof(*st));

	fib = (struct FileInfoBlock *)AllocDosObject(DOS_FIB, 0);
	if (!fib)
		return -1;

	lock = Lock((CONST_STRPTR)path, ACCESS_READ);
	if (!lock) {
		FreeDosObject(DOS_FIB, fib);
		return -1;
	}

	if (!Examine(lock, fib)) {
		UnLock(lock);
		FreeDosObject(DOS_FIB, fib);
		return -1;
	}

	st->st_size = fib->fib_Size;

	if (fib->fib_DirEntryType > 0)
		st->st_mode = S_IFDIR;
	else
		st->st_mode = S_IFREG;

	UnLock(lock);
	FreeDosObject(DOS_FIB, fib);
	return 0;
}

int sigaction(int signum, const struct sigaction *act, struct sigaction *oldact)
{
	(void)signum;
	(void)act;

	if (oldact)
		memset(oldact, 0, sizeof(*oldact));

	return 0;
}

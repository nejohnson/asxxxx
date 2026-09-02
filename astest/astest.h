/* astest.h */

/*
 *  Copyright (C) 2026  Alan R. Baldwin
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/*)Module	astest.h
 *
 *	The module astest.h contains the only platform dependent
 *	definitions required by astest.c:  how a directory is
 *	created, which character separates the elements of a path,
 *	and how the return value of system() is decoded.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

/*
 * Directory creation and the path separator.
 *
 * Paths are held internally with '/' throughout and translated to
 * DIRSEP only when a command string is built.  On DOS this also
 * keeps a leading '/' from being read as the switch character.
 */

#if defined(MSDOS) || defined(__MSDOS__) || defined(__DOS__) || defined(_WIN32)
#  if defined(__TURBOC__)
#    include <dir.h>
#  else
#    include <direct.h>
#  endif
#  define MKDIR(p)	mkdir(p)
#  define DIRSEP	'\\'
#  define PLATFORM_DOS	1
#else
#  include <sys/types.h>
#  include <sys/stat.h>
#  define MKDIR(p)	mkdir((p), 0777)
#  define DIRSEP	'/'
#  define PLATFORM_DOS	0
#endif

/*
 * The exit status of a child process.
 *
 * POSIX system() returns a wait status which must be shifted;
 * DOS and Windows return the child's exit code directly.  There
 * is no portable way to detect which, so the platforms ASxxxx is
 * built on are listed explicitly.  A compiler outside the list
 * falls into the DOS branch, which is why exitchk() in astest.c
 * verifies the decoding against a known exit code before any
 * test case is allowed to run.
 */

#if defined(__unix__) || defined(__linux__) || defined(__APPLE__) || \
    defined(__CYGWIN__) || defined(__DJGPP__) || defined(unix)
#  define WAITSTATUS	1
#else
#  define WAITSTATUS	0
#endif

/*
 * The null device, and stderr redirection.
 *
 * '>' is the one redirection every supported command interpreter
 * accepts.  '2>' is understood by the Bourne shell and by cmd.exe
 * but not by COMMAND.COM, so on real MS-DOS the diagnostics of a
 * tool are left on the console rather than captured.
 */

#if PLATFORM_DOS
#  define NULLDEV	"NUL"
#else
#  define NULLDEV	"/dev/null"
#endif

#if defined(__MSDOS__) || defined(__DOS__) || (defined(MSDOS) && !defined(_WIN32))
#  define REDIR2	""
#else
#  define REDIR2	" 2>"
#endif

/*
 * Buffer sizes.
 */

#define	NLINE	512		/* Text line length */
#define	NPATH	256		/* Path length */
#define	NNAME	64		/* Case id / file name length */
#define	NSTEP	64		/* Steps per test case */
#define	NCASE	256		/* Cases in the manifest */

/*
 * Test case step verbs.
 */

#define	V_NAME	 1		/* name    <text>            */
#define	V_SRC	 2		/* src     <dir>             */
#define	V_TOOL	 3		/* tool    <name>            */
#define	V_COPY	 4		/* copy    <file>            */
#define	V_ASM	 5		/* asm     <opts> <base>     */
#define	V_LINK	 6		/* link    <opts> <name...>  */
#define	V_SCAN	 7		/* scan    <opts> <file>     */
#define	V_GOLD	 8		/* gold    <file>            */
#define	V_GOLDB	 9		/* goldbin <file>            */
#define	V_ABSENT 10		/* absent  <file>            */
#define	V_EXPECT 11		/* expect  <n>               */

/*
 * Case results.
 */

#define	R_PASS	0
#define	R_FAIL	1
#define	R_SKIP	2

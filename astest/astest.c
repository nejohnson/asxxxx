/* astest.c */

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

#include "astest.h"

/*)Module	astest.c
 *
 *	The module astest.c is a regression test driver for the
 *	ASxxxx assemblers and the ASLink linker.
 *
 *	Each test case is a directory under astest/cases/ holding a
 *	script named run.tst, and the expected output of the tools
 *	that script runs.  The manifest astest/tests.lst lists the
 *	cases to run.  Every case is executed in its own working
 *	directory so that no test writes into the source tree.
 *
 *	The expected output of a tool cannot be compared directly:
 *	the page headings written by newpag() carry the program
 *	version and the time of the run, and a linker map names the
 *	files it was given.  normline() removes exactly those, and
 *	nothing else, from both the produced file and the expected
 *	one.  The expected files are stored already normalised so
 *	that a difference between two of them is a difference in
 *	the tools rather than in the day they were run.
 *
 *	astest.c contains the following functions:
 *		int	main()
 *		void	usage()
 *		int	exitcode()
 *		int	exitchk()
 *		int	runtool()
 *		int	runcase()
 *		int	readtst()
 *		void	mkwork()
 *		void	cleanwork()
 *		int	normcmp()
 *		int	normline()
 *		int	bincmp()
 *		int	filecopy()
 *		char *	pathcat()
 *		void	nativepath()
 */

/*
 * Forward declarations.
 */
static int	filecopy(char *src, char *dst);

/*
 * A single step of a test case script.
 */
struct step {
	int	s_verb;			/* V_xxxx */
	int	s_expect;		/* Expected exit status */
	char	s_arg[NLINE];		/* Verb argument, verbatim */
};

/*
 * Global state.
 */
static char	toolpath[NPATH];	/* -T, where the executables are */
static char	rootpath[NPATH];	/* -R, the top of the ASxxxx tree */
static char	workroot[NPATH];	/* -W, where working directories go */
static char	casedir[NPATH];		/* astest/cases/<id> */
static char	workdir[NPATH];		/* <workroot>/<id> */
static char	srcdir[NPATH];		/* Input directory for this case */
static char	toolname[NNAME];	/* Assembler for this case */
static char	casename[NLINE];	/* Description for the summary */

static int	blessf;			/* -b, write expected files */
static int	verbf;			/* -v, echo each command */
static int	keepf;			/* -k, keep working directories */
static int	nrun, npass, nfail, nskip;
static char	failed[NCASE][NNAME];

static struct step steps[NSTEP];
static int	nstep;

/*)Function	void	usage(void)
 *
 *	The function usage() outputs a summary of the command line
 *	options to stdout.
 */

static char *usetxt[] = {
	"Usage: astest [-options] [case ...]",
	"  -T   dir   Directory holding the ASxxxx executables",
	"  -R   dir   Top of the ASxxxx source tree",
	"  -W   dir   Directory to create working directories in",
	"  -b         Bless: write the produced output as expected output",
	"  -k         Keep working directories after a case passes",
	"  -v         Echo each command as it is run",
	"  -h         Show this help list",
	"",
	"With no case names every case in astest/tests.lst is run.",
	"",
	0
};

static void
usage(void)
{
	char **dp;

	for (dp = usetxt; *dp; dp++) {
		fprintf(stdout, "%s\n", *dp);
	}
}

/*)Function	char *	pathcat(dst, dir, file)
 *
 *		char *	dst		destination buffer, NPATH bytes
 *		char *	dir		directory, may be empty
 *		char *	file		file name, appended to dir
 *
 *	The function pathcat() joins a directory and a file name
 *	with a single '/'.  Paths are held with '/' throughout and
 *	converted by nativepath() only when a command is built.
 */

static char *
pathcat(char *dst, char *dir, char *file)
{
	int n;

	dst[0] = 0;
	if (dir != NULL && dir[0] != 0) {
		strcpy(dst, dir);
		n = strlen(dst);
		if (n > 0 && dst[n-1] != '/') {
			strcat(dst, "/");
		}
	}
	strcat(dst, file);
	return (dst);
}

/*)Function	void	nativepath(str)
 *
 *		char *	str		string to convert in place
 *
 *	The function nativepath() converts '/' to the separator the
 *	host command interpreter expects.  On systems where '/' is
 *	already correct it does nothing.
 */

static void
nativepath(char *str)
{
	if (DIRSEP != '/') {
		while (*str) {
			if (*str == '/') {
				*str = DIRSEP;
			}
			str += 1;
		}
	}
}

/*)Function	int	exitcode(rc)
 *
 *		int	rc		the value system() returned
 *
 *	The function exitcode() converts the return value of
 *	system() into the exit status of the child process.  See
 *	the comment on WAITSTATUS in astest.h.
 */

static int
exitcode(int rc)
{
	if (rc == -1) {
		return (-1);
	}
#if WAITSTATUS
	if ((rc & 0x7F) != 0) {
		return (128 + (rc & 0x7F));
	}
	return ((rc >> 8) & 0xFF);
#else
	return (rc);
#endif
}

/*)Function	int	exitchk(void)
 *
 *	The function exitchk() verifies that exitcode() decodes a
 *	known exit status correctly before any test is run.
 *
 *	There is no portable way to tell whether system() returns a
 *	wait status or a raw exit code, so astest.h selects between
 *	them by preprocessor test.  A compiler outside that list
 *	would silently mis-read every result.  asxscn with no
 *	arguments prints its usage and exits ER_WARNING, which is 1,
 *	so running it is a two line self test of the whole
 *	mechanism.  It fires once, before the first case, and
 *	aborts the run rather than reporting false results.
 */

static int
exitchk(void)
{
	char cmd[NPATH+NLINE];
	char tool[NPATH];
	int st;

	pathcat(tool, toolpath, "asxscn");
	nativepath(tool);
	if (REDIR2[0]) {
		sprintf(cmd, "%s > %s%s%s", tool, NULLDEV, REDIR2, NULLDEV);
	} else {
		sprintf(cmd, "%s > %s", tool, NULLDEV);
	}
	st = exitcode(system(cmd));
	if (st == -1) {
		fprintf(stderr, "?astest-Error-Cannot run a command interpreter\n");
		return (0);
	}
	if (st == 126 || st == 127) {
		fprintf(stderr, "?astest-Error-Tool not found: %s\n", tool);
		return (0);
	}
	if (st != 1) {
		fprintf(stderr, "?astest-Error-Exit status decoding is wrong\n");
		fprintf(stderr, "              '%s' should exit 1, read as %d\n", tool, st);
		return (0);
	}
	return (1);
}

/*)Function	int	runtool(tool, args, out, expect)
 *
 *		char *	tool		executable name, no directory
 *		char *	args		arguments, already built
 *		char *	out		file to redirect stdout to
 *		int	expect		required exit status
 *
 *	The function runtool() runs one of the ASxxxx programs and
 *	compares its exit status with the one the script requires.
 *
 *	Only '>' redirection is used:  it is the one form that the
 *	Bourne shell, cmd.exe and COMMAND.COM all accept.  Nothing
 *	is quoted, because the quoting rules of those three do not
 *	agree;  paths containing a space are rejected at startup
 *	instead.
 */

static int
runtool(char *tool, char *args, char *out, int expect)
{
	char cmd[NPATH+NPATH+NLINE];
	char path[NPATH];
	char redir[NPATH];
	int st;

	pathcat(path, toolpath, tool);
	nativepath(path);
	strcpy(redir, out);
	nativepath(redir);
	if (REDIR2[0]) {
		sprintf(cmd, "%s %s > %s%s%s", path, args, redir, REDIR2, redir);
	} else {
		sprintf(cmd, "%s %s > %s", path, args, redir);
	}
	if (verbf) {
		fprintf(stdout, "astest:   %s\n", cmd);
	}
	st = exitcode(system(cmd));
	if (st != expect) {
		fprintf(stdout, "astest:          command: %s\n", cmd);
		fprintf(stdout, "astest:          expected exit %d, got %d\n", expect, st);
		return (0);
	}
	return (1);
}

/*)Function	int	normline(src, dst)
 *
 *		char *	src		the line to normalise
 *		char *	dst		the normalised result
 *
 *	The function normline() removes from a line of tool output
 *	everything that varies between two runs of the same test.
 *	It is applied to the produced file and to the expected file
 *	alike, so the expected files are stored already normalised
 *	and a difference between them is always a real one.
 *
 *	Removed, in order:
 *
 *	(1)	The line terminator and any trailing white space,
 *		so that a file written with CRLF compares equal to
 *		the same file written with LF.
 *
 *	(2)	Every form feed.  newpag() begins a page heading
 *		with one, and map() writes one on a line of its own.
 *
 *	(3)	The program version.  "ASxxxx Linker V06.10" becomes
 *		"ASxxxx Linker V--.--", so that the author's version
 *		bumps do not invalidate every expected file.  The
 *		right aligned "Page n" is left alone, which is what
 *		keeps pagination itself under test.
 *
 *	(4)	The time of the run:  a trailing field of the form
 *		produced by ctime(), together with the run of spaces
 *		before it.  The day of the month is space padded
 *		when it is a single digit, so both forms are matched.
 *
 *	The caller removes file specifications from a linker map;
 *	that is not done here because a map is the only output that
 *	contains one, and a source line in a listing could easily
 *	hold something that resembles a path.
 */

static int
istime(char *p)
{
	/*
	 * Www Mmm dd hh:mm:ss yyyy   -- 24 characters
	 * 012345678901234567890123
	 */
	int i;

	for (i = 0; i < 3; i++) { if (!isalpha(p[i] & 0x7F)) return (0); }
	if (p[3] != ' ') return (0);
	for (i = 4; i < 7; i++) { if (!isalpha(p[i] & 0x7F)) return (0); }
	if (p[7] != ' ') return (0);
	if (!isdigit(p[8] & 0x7F) && p[8] != ' ') return (0);
	if (!isdigit(p[9] & 0x7F)) return (0);
	if (p[10] != ' ') return (0);
	if (!isdigit(p[11] & 0x7F) || !isdigit(p[12] & 0x7F)) return (0);
	if (p[13] != ':') return (0);
	if (!isdigit(p[14] & 0x7F) || !isdigit(p[15] & 0x7F)) return (0);
	if (p[16] != ':') return (0);
	if (!isdigit(p[17] & 0x7F) || !isdigit(p[18] & 0x7F)) return (0);
	if (p[19] != ' ') return (0);
	for (i = 20; i < 24; i++) { if (!isdigit(p[i] & 0x7F)) return (0); }
	return (p[24] == 0);
}

static void
normline(char *src, char *dst)
{
	char *p, *q, *v;
	int n;

	/*
	 * (2) Copy, dropping every form feed.
	 */
	p = src;
	q = dst;
	while (*p) {
		if (*p != '\f' && *p != '\n' && *p != '\r') {
			*q++ = *p;
		}
		p += 1;
	}
	*q = 0;

	/*
	 * (1) Trailing white space.
	 */
	n = strlen(dst);
	while (n > 0 && (dst[n-1] == ' ' || dst[n-1] == '\t')) {
		dst[--n] = 0;
	}

	/*
	 * (3) The program version.
	 */
	v = strstr(dst, "ASxxxx ");
	if (v != NULL) {
		p = strstr(v, " V");
		if (p != NULL) {
			p += 2;
			q = p;
			while (*q && *q != ' ') {
				q += 1;
			}
			if (q != p) {
				/* replace the version with a fixed width tag */
				memmove(p + 5, q, strlen(q) + 1);
				memcpy(p, "--.--", 5);
			}
		}
	}

	/*
	 * (4) The time of the run.
	 */
	n = strlen(dst);
	if (n >= 24 && istime(dst + n - 24)) {
		n -= 24;
		while (n > 0 && (dst[n-1] == ' ' || dst[n-1] == '\t')) {
			n -= 1;
		}
		dst[n] = 0;
	}
}

/*)Function	void	stripath(str)
 *
 *		char *	str		line to edit in place
 *
 *	The function stripath() removes the directory part of every
 *	white space delimited word of a line.  It is applied only to
 *	a linker map, which names the files it linked and the
 *	libraries it searched;  the directory those were found in
 *	depends on where the test was run from.
 */

static void
stripath(char *str)
{
	char buf[NLINE];
	char *p, *q, *w;
	int lead;

	p = str;
	q = buf;
	while (*p) {
		if (*p == ' ' || *p == '\t') {
			*q++ = *p++;
			continue;
		}
		/*
		 * A word.  Copy it, then back up over the last
		 * separator if it had one.
		 */
		w = q;
		lead = 0;
		while (*p && *p != ' ' && *p != '\t') {
			if (*p == '\\') {
				*q++ = '/';
			} else {
				*q++ = *p;
			}
			if (*(q-1) == '/') {
				lead = 1;
			}
			p += 1;
		}
		if (lead) {
			char *last = q;
			while (last > w && *(last-1) != '/') {
				last -= 1;
			}
			memmove(w, last, (int) (q - last));
			q = w + (int) (q - last);
		}
	}
	*q = 0;
	strcpy(str, buf);
}

/*)Function	int	ismap(name)
 *
 *		char *	name		file name
 *
 *	The function ismap() reports whether a file name ends in
 *	".map".  Only a map has its file specifications removed.
 */

static int
ismap(char *name)
{
	int n;

	n = strlen(name);
	return (n >= 4 && strcmp(name + n - 4, ".map") == 0);
}

/*)Function	int	normcmp(produced, expected, name)
 *
 *		char *	produced	the file the tools wrote
 *		char *	expected	the file holding what they should write
 *		char *	name		the file name, for the map test
 *
 *	The function normcmp() compares two files a line at a time
 *	after normalising both, and reports the first line that
 *	differs.  Trailing blank lines are ignored on both sides so
 *	that a missing final newline never matters.
 *
 *	When blessf is set the normalised produced file is written
 *	to the expected file instead of being compared.
 */

static int
normcmp(char *produced, char *expected, char *name)
{
	FILE *fp, *gp;
	char lbuf[NLINE], gbuf[NLINE];
	char lnrm[NLINE], gnrm[NLINE];
	int line, lend, gend, mapf;

	if ((fp = fopen(produced, "r")) == NULL) {
		fprintf(stdout, "astest:          missing output: %s\n", produced);
		return (0);
	}
	mapf = ismap(name);

	if (blessf) {
		if ((gp = fopen(expected, "w")) == NULL) {
			fprintf(stdout, "astest:          cannot write: %s\n", expected);
			fclose(fp);
			return (0);
		}
		while (fgets(lbuf, sizeof(lbuf), fp) != NULL) {
			normline(lbuf, lnrm);
			if (mapf) {
				stripath(lnrm);
			}
			fprintf(gp, "%s\n", lnrm);
		}
		fclose(gp);
		fclose(fp);
		return (1);
	}

	if ((gp = fopen(expected, "r")) == NULL) {
		fprintf(stdout, "astest:          no expected output: %s\n", expected);
		fprintf(stdout, "astest:          (run 'make bless' to create it)\n");
		fclose(fp);
		return (0);
	}

	line = 0;
	for (;;) {
		lend = (fgets(lbuf, sizeof(lbuf), fp) == NULL);
		gend = (fgets(gbuf, sizeof(gbuf), gp) == NULL);
		if (lend && gend) {
			break;
		}
		line += 1;
		if (lend) {
			lbuf[0] = 0;
		}
		if (gend) {
			gbuf[0] = 0;
		}
		normline(lbuf, lnrm);
		normline(gbuf, gnrm);
		if (mapf) {
			stripath(lnrm);
			stripath(gnrm);
		}
		if (strcmp(lnrm, gnrm) != 0) {
			/*
			 * Both files may end in blank lines that the
			 * other does not have;  that is not a
			 * difference.
			 */
			if (lnrm[0] == 0 && gend) {
				continue;
			}
			if (gnrm[0] == 0 && lend) {
				continue;
			}
			fprintf(stdout, "astest:          %s line %d\n", name, line);
			fprintf(stdout, "astest:          expected: %s\n", gnrm);
			fprintf(stdout, "astest:          actual:   %s\n", lnrm);
			fclose(fp);
			fclose(gp);
			return (0);
		}
	}
	fclose(fp);
	fclose(gp);
	return (1);
}

/*)Function	int	bincmp(produced, expected)
 *
 *		char *	produced	the file the tools wrote
 *		char *	expected	the file holding what they should write
 *
 *	The function bincmp() compares two files byte for byte,
 *	for output that carries no heading and must not be
 *	normalised.
 */

static int
bincmp(char *produced, char *expected)
{
	FILE *fp, *gp;
	int c, d, n;

	if ((fp = fopen(produced, "rb")) == NULL) {
		fprintf(stdout, "astest:          missing output: %s\n", produced);
		return (0);
	}
	if (blessf) {
		int ok;
		fclose(fp);
		ok = filecopy(produced, expected);
		if (!ok) {
			fprintf(stdout, "astest:          cannot write: %s\n", expected);
		}
		return (ok);
	}
	if ((gp = fopen(expected, "rb")) == NULL) {
		fprintf(stdout, "astest:          no expected output: %s\n", expected);
		fclose(fp);
		return (0);
	}
	n = 0;
	for (;;) {
		c = getc(fp);
		d = getc(gp);
		if (c == EOF && d == EOF) {
			break;
		}
		if (c != d) {
			fprintf(stdout, "astest:          binary difference at byte %d\n", n);
			fclose(fp);
			fclose(gp);
			return (0);
		}
		n += 1;
	}
	fclose(fp);
	fclose(gp);
	return (1);
}

/*)Function	int	filecopy(src, dst)
 *
 *		char *	src		file to read
 *		char *	dst		file to write
 *
 *	The function filecopy() copies a file verbatim.  It is used
 *	by the copy verb, for library files and hand written object
 *	files that a test needs in its working directory, and by
 *	bincmp() when blessing.
 */

static int
filecopy(char *src, char *dst)
{
	FILE *fp, *gp;
	int c;

	if ((fp = fopen(src, "rb")) == NULL) {
		return (0);
	}
	if ((gp = fopen(dst, "wb")) == NULL) {
		fclose(fp);
		return (0);
	}
	while ((c = getc(fp)) != EOF) {
		putc(c, gp);
	}
	fclose(gp);
	fclose(fp);
	return (1);
}

/*)Function	int	readtst(path)
 *
 *		char *	path		the run.tst file to read
 *
 *	The function readtst() reads a test case script into the
 *	steps[] array.  The format is one step per line:  a verb,
 *	white space, and the rest of the line as its argument.  A
 *	line whose first character is '#' is a comment, and a blank
 *	line is ignored.
 */

static struct {
	char *v_name;
	int   v_verb;
} verbs[] = {
	{ "name",	V_NAME	  },
	{ "src",	V_SRC	  },
	{ "tool",	V_TOOL	  },
	{ "copy",	V_COPY	  },
	{ "asm",	V_ASM	  },
	{ "link",	V_LINK	  },
	{ "scan",	V_SCAN	  },
	{ "gold",	V_GOLD	  },
	{ "goldbin",	V_GOLDB	  },
	{ "absent",	V_ABSENT  },
	{ "expect",	V_EXPECT  },
	{ NULL,		0	  }
};

static int
readtst(char *path)
{
	FILE *fp;
	char line[NLINE];
	char verb[NNAME];
	char *p, *q;
	int i, n, expect;

	if ((fp = fopen(path, "r")) == NULL) {
		fprintf(stdout, "astest:          cannot open %s\n", path);
		return (0);
	}
	nstep = 0;
	expect = 0;
	while (fgets(line, sizeof(line), fp) != NULL) {
		p = line;
		while (*p == ' ' || *p == '\t') {
			p += 1;
		}
		n = strlen(p);
		while (n > 0 && (p[n-1] == '\n' || p[n-1] == '\r' ||
				 p[n-1] == ' '  || p[n-1] == '\t')) {
			p[--n] = 0;
		}
		if (*p == 0 || *p == '#') {
			continue;
		}
		q = verb;
		while (*p && *p != ' ' && *p != '\t' && (q - verb) < NNAME-1) {
			*q++ = *p++;
		}
		*q = 0;
		while (*p == ' ' || *p == '\t') {
			p += 1;
		}
		for (i = 0; verbs[i].v_name != NULL; i++) {
			if (strcmp(verb, verbs[i].v_name) == 0) {
				break;
			}
		}
		if (verbs[i].v_name == NULL) {
			fprintf(stdout, "astest:          unknown verb '%s' in %s\n", verb, path);
			fclose(fp);
			return (0);
		}
		if (verbs[i].v_verb == V_EXPECT) {
			expect = atoi(p);
			continue;
		}
		if (nstep >= NSTEP) {
			fprintf(stdout, "astest:          too many steps in %s\n", path);
			fclose(fp);
			return (0);
		}
		steps[nstep].s_verb = verbs[i].v_verb;
		steps[nstep].s_expect = expect;
		strcpy(steps[nstep].s_arg, p);
		nstep += 1;
		expect = 0;
	}
	fclose(fp);
	return (1);
}

/*)Function	void	subst(dst, src)
 *
 *		char *	dst		result
 *		char *	src		text to substitute into
 *
 *	The function subst() replaces %w with the working directory
 *	and %s with the current source directory.  A linker option
 *	that names a directory, -k for a library path, cannot use a
 *	bare name:  only the file names in a command file are taken
 *	relative to that file.
 */

static void
subst(char *dst, char *src)
{
	char *q;

	q = dst;
	while (*src) {
		if (src[0] == '%' && (src[1] == 'w' || src[1] == 's')) {
			strcpy(q, (src[1] == 'w') ? workdir : srcdir);
			q += strlen(q);
			src += 2;
		} else {
			*q++ = *src++;
		}
	}
	*q = 0;
}

/*)Function	void	mkwork(id)
 *
 *		char *	id		the case id
 *
 *	The function mkwork() creates the working directory for a
 *	case.  The root is created first;  both may already exist,
 *	which is not an error.
 */

static void
mkwork(char *id)
{
	char path[NPATH];

	strcpy(path, workroot);
	nativepath(path);
	MKDIR(path);

	pathcat(workdir, workroot, id);
	strcpy(path, workdir);
	nativepath(path);
	MKDIR(path);
}

/*)Function	int	runcase(id)
 *
 *		char *	id		the case id
 *
 *	The function runcase() runs one test case and returns
 *	R_PASS, R_FAIL or R_SKIP.  Execution stops at the first step
 *	that fails.
 */

static int
runcase(char *id)
{
	char path[NPATH+NLINE], gpath[NPATH+NLINE], args[NLINE+NPATH+NPATH];
	char lnk[NPATH], base[NNAME];
	char *p, *q;
	FILE *fp;
	int i, nout;

	pathcat(casedir, rootpath, "astest/cases");
	pathcat(path, casedir, id);
	strcpy(casedir, path);

	pathcat(path, casedir, "run.tst");
	if (!readtst(path)) {
		return (R_FAIL);
	}

	strcpy(srcdir, casedir);
	strcpy(toolname, "ascheck");
	strcpy(casename, id);
	mkwork(id);
	nout = 0;

	for (i = 0; i < nstep; i++) {
		p = steps[i].s_arg;

		switch (steps[i].s_verb) {

		case V_NAME:
			strcpy(casename, p);
			break;

		case V_SRC:
			pathcat(srcdir, rootpath, p);
			break;

		case V_TOOL:
			strcpy(toolname, p);
			break;

		case V_COPY:
			pathcat(path, srcdir, p);
			pathcat(gpath, workdir, p);
			if (!filecopy(path, gpath)) {
				fprintf(stdout, "astest:          cannot copy %s\n", path);
				return (R_FAIL);
			}
			break;

		case V_ASM:
			/*
			 * asm <opts> <base>
			 *
			 * The base name is the last word.  -o+ sends
			 * every output of the assembler to the working
			 * directory;  it must precede the source file
			 * because fixrelfil() takes the first name it
			 * is given.
			 */
			q = p + strlen(p);
			while (q > p && *(q-1) != ' ' && *(q-1) != '\t') {
				q -= 1;
			}
			strcpy(base, q);
			if (q > p) {
				*(q-1) = 0;
			} else {
				*p = 0;
			}
			sprintf(args, "%s -o+%s/%s %s/%s",
				p, workdir, base, srcdir, base);
			nativepath(args + strlen(p) + 1);
			sprintf(path, "%s/asm%d.out", workdir, nout++);
			if (!runtool(toolname, args, path, steps[i].s_expect)) {
				return (R_FAIL);
			}
			break;

		case V_LINK:
			/*
			 * link <opts> <name...>
			 *
			 * The names are written to a command file in the
			 * working directory.  A bare name in a command
			 * file is taken relative to the command file, so
			 * every output lands in the working directory and
			 * the command line stays short.
			 */
			pathcat(lnk, workdir, "run.lnk");
			if ((fp = fopen(lnk, "w")) == NULL) {
				fprintf(stdout, "astest:          cannot write %s\n", lnk);
				return (R_FAIL);
			}
			/*
			 * ';' separates one command file line from the
			 * next, so that an option and its argument stay
			 * together:  aslink reads '-a name=expr' as one
			 * line, not as two.
			 */
			subst(args, p);
			q = args;
			while (*q) {
				char word[NLINE];
				char *w = word;
				int n2;
				while (*q == ' ' || *q == '\t') {
					q += 1;
				}
				while (*q && *q != ';') {
					*w++ = *q++;
				}
				if (*q == ';') {
					q += 1;
				}
				*w = 0;
				n2 = strlen(word);
				while (n2 > 0 && (word[n2-1] == ' ' || word[n2-1] == '\t')) {
					word[--n2] = 0;
				}
				if (word[0]) {
					fprintf(fp, "%s\n", word);
				}
			}
			fprintf(fp, "-e\n");
			fclose(fp);
			sprintf(args, "-n -f %s/run", workdir);
			nativepath(args + 3);
			sprintf(path, "%s/link%d.out", workdir, nout++);
			if (!runtool("aslink", args, path, steps[i].s_expect)) {
				return (R_FAIL);
			}
			break;

		case V_SCAN:
			/*
			 * scan <opts> <file>
			 */
			q = p + strlen(p);
			while (q > p && *(q-1) != ' ' && *(q-1) != '\t') {
				q -= 1;
			}
			strcpy(base, q);
			if (q > p) {
				*(q-1) = 0;
			} else {
				*p = 0;
			}
			sprintf(args, "%s %s/%s", p, workdir, base);
			nativepath(args + strlen(p) + 1);
			sprintf(path, "%s/scan%d.out", workdir, nout++);
			if (!runtool("asxscn", args, path, steps[i].s_expect)) {
				return (R_FAIL);
			}
			break;

		case V_GOLD:
			pathcat(path, workdir, p);
			sprintf(gpath, "%s/%s.gold", casedir, p);
			if (!normcmp(path, gpath, p)) {
				return (R_FAIL);
			}
			break;

		case V_GOLDB:
			pathcat(path, workdir, p);
			sprintf(gpath, "%s/%s.gold", casedir, p);
			if (!bincmp(path, gpath)) {
				return (R_FAIL);
			}
			break;

		case V_ABSENT:
			pathcat(path, workdir, p);
			if ((fp = fopen(path, "r")) != NULL) {
				fclose(fp);
				fprintf(stdout, "astest:          %s exists and should not\n", p);
				return (R_FAIL);
			}
			break;

		default:
			break;
		}
	}
	return (R_PASS);
}

/*)Function	int	main(argc, argv)
 *
 *		int	argc		argument count
 *		char *	argv[]		argument list
 *
 *	The function main() reads the manifest, runs each case named
 *	on the command line or, if none are named, every case in the
 *	manifest, and prints a summary.  It exits 1 if any case
 *	failed and 0 otherwise.
 */

int
main(int argc, char *argv[])
{
	FILE *fp;
	char path[NPATH+NLINE];
	char line[NLINE];
	char *p;
	int i, j, n, rc, only;

	strcpy(toolpath, ".");
	strcpy(rootpath, "..");
	strcpy(workroot, "_astest");
	only = 0;

	for (i = 1; i < argc; i++) {
		p = argv[i];
		if (*p == '-') {
			switch (p[1]) {
			case 'T':
			case 'R':
			case 'W':
				if (p[2] != 0) {
					strcpy(path, p+2);
				} else if (i+1 < argc) {
					strcpy(path, argv[++i]);
				} else {
					fprintf(stderr, "?astest-Error-Missing argument to -%c\n", p[1]);
					return (1);
				}
				if (strchr(path, ' ') != NULL) {
					fprintf(stderr, "?astest-Error-Path may not contain a space: %s\n", path);
					fprintf(stderr, "              Commands are built without quoting;  the\n");
					fprintf(stderr, "              quoting rules of the supported command\n");
					fprintf(stderr, "              interpreters do not agree.\n");
					return (1);
				}
				if      (p[1] == 'T') strcpy(toolpath, path);
				else if (p[1] == 'R') strcpy(rootpath, path);
				else                  strcpy(workroot, path);
				break;

			case 'b':	blessf = 1;	break;
			case 'k':	keepf = 1;	break;
			case 'v':	verbf = 1;	break;
			case 'h':	usage();	return (0);
			default:
				fprintf(stderr, "?astest-Error-Unknown option %s\n", p);
				usage();
				return (1);
			}
		} else {
			only = 1;
		}
	}

	if (!exitchk()) {
		return (1);
	}

	pathcat(path, rootpath, "astest/tests.lst");
	if ((fp = fopen(path, "r")) == NULL) {
		fprintf(stderr, "?astest-Error-Cannot open manifest %s\n", path);
		return (1);
	}

	while (fgets(line, sizeof(line), fp) != NULL) {
		p = line;
		while (*p == ' ' || *p == '\t') {
			p += 1;
		}
		n = strlen(p);
		while (n > 0 && (p[n-1] == '\n' || p[n-1] == '\r' ||
				 p[n-1] == ' '  || p[n-1] == '\t')) {
			p[--n] = 0;
		}
		if (*p == 0 || *p == '#') {
			continue;
		}
		if (strlen(p) > 8) {
			fprintf(stderr, "?astest-Error-Case id '%s' exceeds 8 characters\n", p);
			fprintf(stderr, "              Working directories must keep to 8.3 names.\n");
			fclose(fp);
			return (1);
		}
		if (only) {
			int want = 0;
			for (j = 1; j < argc; j++) {
				if (argv[j][0] != '-' && strcmp(argv[j], p) == 0) {
					want = 1;
				}
			}
			if (!want) {
				continue;
			}
		}

		nrun += 1;
		rc = runcase(p);
		if (rc == R_PASS) {
			npass += 1;
			fprintf(stdout, "astest: %-8s %s  %s\n", p,
				blessf ? "BLESS" : "PASS ", casename);
		} else if (rc == R_SKIP) {
			nskip += 1;
			fprintf(stdout, "astest: %-8s SKIP   %s\n", p, casename);
		} else {
			if (nfail < NCASE) {
				strcpy(failed[nfail], p);
			}
			nfail += 1;
			fprintf(stdout, "astest: %-8s FAIL   %s\n", p, casename);
		}
	}
	fclose(fp);

	fprintf(stdout, "astest: %d case(s): %d passed, %d failed, %d skipped\n",
		nrun, npass, nfail, nskip);
	if (nfail) {
		fprintf(stdout, "astest: failed:");
		for (i = 0; i < nfail && i < NCASE; i++) {
			fprintf(stdout, " %s", failed[i]);
		}
		fprintf(stdout, "\n");
	}
	if (keepf) {
		/* working directories are left in place */
	}
	return (nfail ? 1 : 0);
}

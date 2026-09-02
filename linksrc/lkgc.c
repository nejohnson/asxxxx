/* lkgc.c */

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

#include "aslink.h"

/*)Module	lkgc.c
 *
 *	The module lkgc.c discards the sections of a program that
 *	nothing reaches.
 *
 *	A section here is an areax:  the code and data one A
 *	directive of one object module contributed to an area.  If a
 *	program puts each of its functions in its own area, which is
 *	what the .function directive is for, then a section is a
 *	function and discarding unreachable sections discards
 *	unreachable functions.
 *
 *	The references between sections are already in the object
 *	files.  Every R line names the section its relocations
 *	belong to, and every relocation in it names either an area,
 *	which is a section of the same module, or a symbol, whose
 *	defining section is recorded by newsym().  So the graph the
 *	collector needs is read rather than derived:  gcrel() records
 *	the edges as the R lines go by on the first pass, and
 *	gcmark() walks them from a set of roots.
 *
 *	What is left unmarked is not written.  Nothing is moved and
 *	no address is decided here;  the sweep only sets a flag that
 *	lnksect() reads when it lays the areas out, so a discarded
 *	section simply contributes no size.
 *
 *	The roots are:
 *
 *	(1)	Every section of an absolute area.  Its address was
 *		chosen by the programmer and is often the only thing
 *		that reaches it - an interrupt vector is not called
 *		from anywhere.
 *
 *	(2)	Every section of an area named in a -a option, for
 *		the same reason:  an area given an address is an
 *		area someone placed deliberately.
 *
 *	(3)	Every section of an area marked KEEP.
 *
 *	(4)	Every name given with -r, which may be a symbol or an
 *		area.
 *
 *	(5)	Every area named by a reference to one of the symbols
 *		the linker itself generates:  a_<area>, l_<area>,
 *		s_<area>_n and m_<area>_n.  Those carry no link back
 *		to a section, so a program that copies initialised
 *		data by reading a_<area> and l_<area> - which is what
 *		a startup module does - refers to the area without
 *		any relocation pointing into it.  Without this the
 *		collector would discard exactly the data that
 *		startup code exists to copy, and nothing would say
 *		so.
 *
 *	lkgc.c contains the following functions:
 *		void	gcrel()
 *		void	gcrsav()
 *		void	gcsect()
 *		int	gcdead()
 *		void	gclist()
 *		void	gcmark()
 *		void	gcref()
 *		void	gcarea()
 *		int	gcgsym()
 */

static void	gcmark(struct areax *taxp);
static void	gcarea(struct area *tap);
static int	gcgsym(char *id, char *area);

/*)Function	void	gcrel(void)
 *
 *	The function gcrel() reads an R line on the first pass and
 *	records the references it describes.
 *
 *	The R line is self describing;  unlike relr3() and relr4()
 *	this needs none of the T line data, only the indices:
 *
 *		R 0 0 nn nn n1 n2 xx xx ...
 *
 *	nn nn is the section the relocations belong to, and each
 *	following group of four names a mode, a byte index and an
 *	area or symbol index.  The two object file versions differ
 *	only in which bit of the mode selects a symbol.
 *
 *	local variables:
 *		areax	**a		module area list
 *		sym	**s		module symbol list
 *		aref	*rp		new reference
 *		int	aindex		section the R line belongs to
 *		int	rindex		area or symbol referred to
 *		int	mode		relocation mode
 *		int	symbit		mode bit selecting a symbol
 *
 *	global variables:
 *		int	ASxxxx_VERSION	object file version
 *		head	*hp		current head structure
 *
 *	functions called:
 *		a_uint	eval()		lkeval.c
 *		a_uint	evword()	lkrloc.c
 *		int	more()		lklex.c
 *		char *	new()		lksym.c
 *
 *	side effects:
 *		A reference is recorded for each relocation.
 */

void
gcrel(void)
{
	struct areax **a;
	struct sym **s;
	struct areax *taxp;
	struct aref *rp;
	int aindex, rindex, mode, symbit;

	a = hp->a_list;
	s = hp->s_list;
	symbit = (ASxxxx_VERSION == 3) ? R3_SYM : R4_SYM;

	/*
	 * Skip the two leading bytes and read the section index.
	 * A malformed line is left for relr3()/relr4() to report on
	 * the second pass;  say nothing here.
	 */
	if (eval() || eval()) {
		return;
	}
	aindex = (int) evword();
	if (aindex >= hp->h_narea) {
		return;
	}
	taxp = a[aindex];

	while (more()) {
		mode = (int) eval();
		(void) eval();
		rindex = (int) evword();

		rp = (struct aref *) new (sizeof(struct aref));
		if (mode & symbit) {
			if (rindex >= hp->h_nsym) {
				return;
			}
			rp->r_sp = s[rindex];
		} else {
			if (rindex >= hp->h_narea) {
				return;
			}
			rp->r_axp = a[rindex];
		}
		rp->r_rp = taxp->a_rp;
		taxp->a_rp = rp;
	}
}

/*)Function	void	gcrsav(void)
 *
 *	The function gcrsav() saves a -r option, the name of a
 *	symbol or an area to keep, and enables collection.  It
 *	follows glblsav() in lkmain.c.
 *
 *	side effects:
 *		A globl structure is created and gcflag is set.
 */

void
gcrsav(void)
{
	struct globl *tgsp;
	char *p;
	int c;

	p = ip;
	while ((c = *p) != 0) {
		if ((c == ' ') || (c == '\t')) {
			p += 1;
		} else {
			break;
		}
	}
	if (*p == 0) {
		fprintf(stderr, "?ASlink-Error-Missing -r argument\n");
		lkexit(ER_FATAL);
	}
	tgsp = (struct globl *) new (sizeof(struct globl));
	if (gcrootp == NULL) {
		gcrootp = tgsp;
	} else {
		gcrsp = gcrootp;
		while (gcrsp->g_globl) {
			gcrsp = gcrsp->g_globl;
		}
		gcrsp->g_globl = tgsp;
	}
	tgsp->g_strp = strsto(p);
	gcflag = 1;
}

/*)Function	int	gcgsym(id, area)
 *
 *		char *	id		symbol name
 *		char *	area		area name, filled in
 *
 *	The function gcgsym() reports whether a symbol name is one
 *	of the four the linker generates for an area, and if it is,
 *	returns the name of that area.
 *
 *		a_<area>	l_<area>
 *		s_<area>_n	m_<area>_n
 *
 *	The s_ and m_ forms carry a section number, so the trailing
 *	'_' and digits are removed;  an area name may itself contain
 *	'_', so only a final run of digits preceded by '_' is taken.
 *
 *	side effects:
 *		none
 */

static int
gcgsym(char *id, char *area)
{
	char *p;
	int n, sect;

	if (id[0] == 0 || id[1] != '_') {
		return (0);
	}
	sect = (id[0] == 's') || (id[0] == 'm');
	if (!sect && (id[0] != 'a') && (id[0] != 'l')) {
		return (0);
	}
	strncpy(area, id + 2, NCPS-1);
	area[NCPS-1] = 0;
	n = strlen(area);
	if (n == 0) {
		return (0);
	}
	if (sect) {
		/*
		 * Remove a trailing _<digits>, and only that.
		 */
		p = area + n;
		while (p > area && *(p-1) >= '0' && *(p-1) <= '9') {
			p -= 1;
		}
		if (p == area + n || p == area || *(p-1) != '_') {
			return (0);
		}
		*(p-1) = 0;
		if (area[0] == 0) {
			return (0);
		}
	}
	return (1);
}

/*)Function	void	gcarea(tap)
 *
 *		area *	tap		area to keep
 *
 *	The function gcarea() marks every section of an area.
 */

static void
gcarea(struct area *tap)
{
	struct areax *taxp;

	for (taxp = tap->a_axp; taxp != NULL; taxp = taxp->a_axp) {
		gcmark(taxp);
	}
}

/*)Function	void	gcmark(taxp)
 *
 *		areax *	taxp		section to keep
 *
 *	The function gcmark() marks a section and everything it
 *	refers to.  A section already marked stops the walk, which
 *	is what makes a cycle of mutually recursive functions
 *	terminate.
 *
 *	A reference to a symbol is followed to the section that
 *	defines it.  A symbol that nothing defines has no section to
 *	follow;  symdef() reports it separately and there is nothing
 *	to mark.
 *
 *	side effects:
 *		Sections are marked reachable.
 */

static void
gcmark(struct areax *taxp)
{
	struct aref *rp;

	if (taxp == NULL || taxp->a_gcf) {
		return;
	}
	taxp->a_gcf = 1;
	for (rp = taxp->a_rp; rp != NULL; rp = rp->r_rp) {
		if (rp->r_axp != NULL) {
			gcmark(rp->r_axp);
		} else
		if (rp->r_sp != NULL) {
			gcmark(rp->r_sp->s_axp);
		}
	}
}

/*)Function	int	gcdead(taxp)
 *
 *		areax *	taxp		section
 *
 *	The function gcdead() reports whether a section is being
 *	discarded.  It is false unless collection was asked for, so
 *	every caller can be written without a second test.
 */

int
gcdead(struct areax *taxp)
{
	if (gcflag == 0 || taxp == NULL) {
		return (0);
	}
	return (taxp->a_gcf == 0);
}

/*)Function	void	gcsect(void)
 *
 *	The function gcsect() collects the unreachable sections.  It
 *	is called once, after the libraries have been searched so
 *	that every section is known, and before any address has been
 *	assigned:  lnksect() adds a section's boundary padding into
 *	its size as it lays the area out, so the sizes must not have
 *	been touched when the sections are counted here.
 *
 *	side effects:
 *		Reachable sections are marked;  the rest are counted
 *		and reported through gclist().
 */

void
gcsect(void)
{
	struct area *tap;
	struct areax *taxp;
	struct globl *tgsp;
	struct base *tbsp;
	struct sym *tsp;
	char area[NCPS];
	char id[NCPS];
	int i, found;

	if (gcflag == 0) {
		return;
	}

	/*
	 * (1) and (3):  absolute areas, and areas marked KEEP.
	 */
	for (tap = areap; tap != NULL; tap = tap->a_ap) {
		if (((tap->a_flag & A4_ABS) == A4_ABS) ||
		     (tap->a_flag & A4_KEEP)) {
			gcarea(tap);
		}
	}

	/*
	 * (2)  areas given an address with -a.
	 */
	for (tbsp = a_basep; tbsp != NULL; tbsp = tbsp->link) {
		ip = tbsp->strp;
		getid(id, -1);
		for (tap = areap; tap != NULL; tap = tap->a_ap) {
			if (symeq(id, tap->a_id, 1)) {
				gcarea(tap);
			}
		}
	}

	/*
	 * (4)  names given with -r, a symbol or an area.
	 */
	for (tgsp = gcrootp; tgsp != NULL; tgsp = tgsp->g_globl) {
		found = 0;
		if ((tsp = lkpsym(tgsp->g_strp, 0)) != NULL) {
			if (tsp->s_axp != NULL) {
				gcmark(tsp->s_axp);
				found = 1;
			}
		}
		for (tap = areap; tap != NULL; tap = tap->a_ap) {
			if (symeq(tgsp->g_strp, tap->a_id, 1)) {
				gcarea(tap);
				found = 1;
			}
		}
		if (!found) {
			fprintf(stderr,
				"?ASlink-Error-No definition of -r root %s\n",
				tgsp->g_strp);
			lkerr++;
		}
	}

	/*
	 * (5)  areas reached only through a generated area symbol.
	 */
	for (i = 0; i < NHASH; ++i) {
		for (tsp = symhash[i]; tsp != NULL; tsp = tsp->s_sp) {
			if (tsp->s_type & S_DEF) {
				continue;
			}
			if (!gcgsym(tsp->s_id, area)) {
				continue;
			}
			for (tap = areap; tap != NULL; tap = tap->a_ap) {
				if (symeq(area, tap->a_id, 1)) {
					gcarea(tap);
				}
			}
		}
	}

	/*
	 * Count what is left.  A section that holds nothing is not
	 * counted:  discarding it removes no code and saying so
	 * would bury the sections that matter.  Every module
	 * declares the default areas whether it uses them or not,
	 * so those are most of them.
	 */
	gcnrem = 0;
	gcbrem = 0;
	for (tap = areap; tap != NULL; tap = tap->a_ap) {
		for (taxp = tap->a_axp; taxp != NULL; taxp = taxp->a_axp) {
			if ((taxp->a_gcf == 0) && (taxp->a_size != 0)) {
				gcnrem += 1;
				gcbrem += taxp->a_size;
			}
		}
	}

	/*
	 * A symbol defined in a discarded section is not in the
	 * program any more.  Keep it out of the map and out of the
	 * debugger files, where its name would otherwise be given an
	 * address that now holds something else.
	 */
	for (i = 0; i < NHASH; ++i) {
		for (tsp = symhash[i]; tsp != NULL; tsp = tsp->s_sp) {
			if (gcdead(tsp->s_axp)) {
				tsp->s_flag = 1;
			}
		}
	}
	if (gcnrem) {
		fprintf(stdout,
			"ASlink: %d section(s) discarded, %u byte(s)\n",
			gcnrem, (unsigned) gcbrem);
	}
}

/*)Function	void	gclist(fp)
 *
 *		FILE *	fp		output file handle
 *
 *	The function gclist() lists the discarded sections, with the
 *	module each came from, so that what was removed and what it
 *	cost can be read rather than guessed at.
 *
 *	side effects:
 *		The list is written to fp.
 */

void
gclist(FILE *fp)
{
	struct area *tap;
	struct areax *taxp;
	struct globl *tgsp;

	if (gcflag == 0 || fp == NULL) {
		return;
	}
	newpag(fp);
	fprintf(fp, "\nSections Discarded                        [ module(s) ]\n\n");
	if (gcnrem == 0) {
		fprintf(fp, "None\n");
	}
	for (tap = areap; tap != NULL; tap = tap->a_ap) {
		for (taxp = tap->a_axp; taxp != NULL; taxp = taxp->a_axp) {
			if (taxp->a_gcf || (taxp->a_size == 0)) {
				continue;
			}
			fprintf(fp, "%-32.32s %6u  [ %-.24s ]\n",
				tap->a_id, (unsigned) taxp->a_size,
				(taxp->a_bhp && taxp->a_bhp->m_id) ?
					taxp->a_bhp->m_id : "");
		}
	}
	fprintf(fp, "\n%d section(s) discarded, %u byte(s)\n",
		gcnrem, (unsigned) gcbrem);

	fprintf(fp, "\nRoots\n\n");
	for (tgsp = gcrootp; tgsp != NULL; tgsp = tgsp->g_globl) {
		fprintf(fp, "%s\n", tgsp->g_strp);
	}
	fprintf(fp, "\n");
}

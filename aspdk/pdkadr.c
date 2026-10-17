/* pdkadr.c */

/*
 *  Copyright (C) 1998-2009  Alan R. Baldwin
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
 *
 *
 * Alan R. Baldwin
 * 721 Berkeley St.
 * Kent, Ohio  44240
 *
 *   This Assember Ported by
 *      John L. Hartman (JLH)
 *      jhartman at compuserve dot com
 *      noice at noicedebugger dot com
 */

#include "asxxxx.h"
#include "pdk.h"

/*
 * A register name is a name only when the whole word is the name:
 * "a," is the accumulator, "abc" is a symbol.  The input is left
 * after the name when it matches and untouched when it does not.
 */
int
pdkreg(char *name)
{
	char *p, *q;
	int c;

	p = ip;
	for (q = name; *q != '\0'; q++) {
		c = get();
		if (ccase[c & 0x7F] != *q) {
			ip = p;
			return(0);
		}
	}
	c = get();
	unget(c);
	if (ctype[c & 0x7F] & (LETTER | DIGIT)) {
		ip = p;
		return(0);
	}
	return(1);
}

/*
 * Read an operand.  ioAdr makes a bare address an I/O register
 * rather than data memory, for the .io mnemonics.
 */
int
addr(struct expr *esp, int ioAdr)
{
	int c;

	c = getnb();
	unget(c);
	if (c == '#') {
		/*
		 * Immediate.  A relocatable one written without < or >
		 * is an address that has to fit the field whole - #_x,
		 * a RAM address - so the linker checks it; one with < or
		 * > has chosen its byte, and an absolute one is a number,
		 * where #-1 and #0xFF are the same.
		 */
		getnb();
		c = getnb();
		unget(c);
		expr(esp);
		esp->e_mode = S_K;
		if ((c != '<') && (c != '>') && !is_abs(esp))
			esp->e_rlcf |= R_USGN;
	} else
	if (pdkreg("a")) {
		/* Accumulator */
		esp->e_mode = S_A;
	} else
	if (pdkreg("sp")) {
		/* Stack pointer, I/O register 2 */
		esp->e_mode = S_IO;
		esp->e_addr = 2;
	} else
	if (pdkreg("f")) {
		/* Flags, I/O register 0 */
		esp->e_mode = S_IO;
		esp->e_addr = 0;
	} else {
		expr(esp);
		esp->e_mode = ioAdr ? S_IO : S_M;
	}
	return (esp->e_mode);
}

/*
 * Read a bit:  #n, or one of the flag bits by name.
 */
int
pdkbit(struct expr *esp)
{
	int c;

	c = getnb();
	unget(c);
	if (c == '#') {
		getnb();
		expr(esp);
		esp->e_mode = S_K;
		return (esp->e_mode);
	}
	esp->e_mode = S_K;
	if (pdkreg("ac")) {
		esp->e_addr = 2;
	} else
	if (pdkreg("ov")) {
		esp->e_addr = 3;
	} else
	if (pdkreg("c")) {
		esp->e_addr = 1;
	} else
	if (pdkreg("z")) {
		esp->e_addr = 0;
	} else {
		esp->e_mode = 0;
		esp->e_addr = 0;
	}
	return (esp->e_mode);
}

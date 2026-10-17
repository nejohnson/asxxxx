/* pdkmch.c */

/*
 *  Copyright (C) 1998-2011  Alan R. Baldwin
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

/*
 * The emitters the Padauk cores share.  Each takes the forms an
 * instruction has - its opcode and operand field for each operand
 * combination - reads the operands, and writes the form they match.
 */

#include "asxxxx.h"
#include "pdk.h"

/*
 * The relocation mode for an operand field.
 */
static int
pdkmode(a_uint mask)
{
	switch (mask) {
	case 0x000F:	return(R_4BIT);
	case 0x001F:	return(R_5BIT);
	case 0x003F:	return(R_6BIT);
	case 0x007F:	return(R_7BIT);
	case 0x00FF:	return(R_8BIT);
	case 0x03FF:	return(R_10BIT);
	case 0x07FF:	return(R_11BIT);
	case 0x0FFF:	return(R_12BIT);
	case 0x001E:	return(R_5BITE);
	case 0x003E:	return(R_6BITE);
	case 0x007E:	return(R_7BITE);
	case 0x00FE:	return(R_8BITE);
	default:
		xerr('q', "Internal error:  no relocation mode for the operand field.");
		return(R_NORM);
	}
}

/*
 * Write an instruction with its operand merged into the operand
 * field, relocatable or not.  An address is checked against the
 * field's width; an immediate is not, as .db does not check, so
 * #-1 and #0xFF are both 0xFF.
 */
void
outpdkrm(struct inst inst, struct expr *esp)
{
	int r;

	/*
	 * The field is the mask less any bit the opcode has set.  A
	 * form whose mask reaches into its own opcode - cneqsn a,m on
	 * the 14 bit core, 0x1780 with a mask of 0xFF - has a field
	 * one bit narrower than the mask, and the linker's merge
	 * replaces every bit of the field it is given, so given the
	 * whole mask it would clear the opcode bit.
	 */
	r = pdkmode(inst.mask & ~inst.op);
	if (esp->e_mode != S_K)
		r |= R_USGN;
	outrwm(esp, r, inst.op);
}

/*
 * An I/O register:  always an absolute number.
 */
void
outpdkaw(struct inst inst, struct expr *esp)
{
	if (!is_abs(esp))
		xerr('r', "An I/O register must be an absolute address.");
	outpdkrm(inst, esp);
}

/*
 * A form with no operand.
 */
static void
outpdka(struct inst inst)
{
	outaw(inst.op);
}

void
emov(a_uint op, struct inst def, struct inst ioa, struct inst aio,
	struct inst ma, struct inst am)
{
	int ioAdr = (op & PDK_OPCODE_ADR_IO) ? 1 : 0;
	struct expr e, e1;
	int t, t1;

	clrexpr(&e);
	clrexpr(&e1);
	t = addr(&e, ioAdr);
	comma(1);
	t1 = addr(&e1, ioAdr);
	if (t == S_IO && t1 == S_A) {
		outpdkaw(ioa, &e);
	} else
	if (t == S_A && t1 == S_IO) {
		outpdkaw(aio, &e1);
	} else
	if (t == S_M && t1 == S_A) {
		outpdkrm(ma, &e);
	} else
	if (t == S_A && t1 == S_M) {
		outpdkrm(am, &e1);
	} else
	if (t == S_A && t1 == S_K) {
		outpdkrm(def, &e1);
	} else
		xerr('a', "Invalid operands for mov.");
}

void
eidxm(struct inst am, struct inst ma)
{
	struct expr e, e1;
	int t, t1;

	clrexpr(&e);
	clrexpr(&e1);
	t = addr(&e, 0);
	comma(1);
	t1 = addr(&e1, 0);
	if (t == S_A && t1 == S_M) {
		outpdkrm(am, &e1);
	} else
	if (t == S_M && t1 == S_A) {
		outpdkrm(ma, &e);
	} else
		xerr('a', "Arguments: a,m or m,a.");
}

void
earith(struct inst def, struct inst ma, struct inst am)
{
	struct expr e, e1;
	int t, t1;

	clrexpr(&e);
	clrexpr(&e1);
	t = addr(&e, 0);
	comma(1);
	t1 = addr(&e1, 0);
	if (t == S_M && t1 == S_A) {
		outpdkrm(ma, &e);
	} else
	if (t == S_A && t1 == S_M) {
		outpdkrm(am, &e1);
	} else
	if (t == S_A && t1 == S_K) {
		outpdkrm(def, &e1);
	} else
		xerr('a', "Arguments: m,a or a,m or a,#k.");
}

void
earithc(struct inst ma, struct inst am, struct inst m, struct inst a)
{
	struct expr e, e1;
	int t, t1;

	clrexpr(&e);
	t = more() ? addr(&e, 0) : S_A;
	if (comma(0)) {
		clrexpr(&e1);
		t1 = addr(&e1, 0);
		if (t == S_M && t1 == S_A) {
			outpdkrm(ma, &e);
		} else
		if (t == S_A && t1 == S_M) {
			outpdkrm(am, &e1);
		} else
			xerr('a', "Arguments: m,a or a,m.");
	} else
	if (t == S_M) {
		outpdkrm(m, &e);
	} else
	if (t == S_A) {
		outpdka(a);
	} else
		xerr('a', "Arguments: a or m.");
}

void
eshift(struct inst a, struct inst m)
{
	struct expr e;
	int t;

	clrexpr(&e);
	t = more() ? addr(&e, 0) : S_A;
	if (t == S_A) {
		outpdka(a);
	} else
	if (t == S_M) {
		outpdkrm(m, &e);
	} else
		xerr('a', "Arguments: a or m.");
}

void
ebit(a_uint op, struct inst def, struct inst ma, struct inst am,
	struct inst *ioa)
{
	int ioAdr = (op & PDK_OPCODE_ADR_IO) ? 1 : 0;
	struct expr e, e1;
	int t, t1;

	clrexpr(&e);
	clrexpr(&e1);
	t = addr(&e, ioAdr);
	t1 = 0;
	if (!more()) {
		/* One operand:  #k means a,#k; io means io,a. */
		if (t == S_K) {
			t = S_A;
			t1 = S_K;
			e1 = e;
		} else
		if (t == S_IO) {
			t1 = S_A;
		}
	} else {
		comma(1);
		t1 = addr(&e1, ioAdr);
	}
	if (t == S_M && t1 == S_A) {
		outpdkrm(ma, &e);
	} else
	if (t == S_A && t1 == S_M) {
		outpdkrm(am, &e1);
	} else
	if (t == S_A && t1 == S_K) {
		outpdkrm(def, &e1);
	} else
	if (t == S_IO && t1 == S_A && ioa) {
		outpdkaw(*ioa, &e);
	} else
		xerr('a', "Invalid operands.");
}

void
enot(struct inst def, struct inst m)
{
	struct expr e;
	int t;

	clrexpr(&e);
	t = more() ? addr(&e, 0) : S_A;
	if (t == S_M) {
		outpdkrm(m, &e);
	} else
	if (t == S_A) {
		outpdka(def);
	} else
		xerr('a', "Arguments: a or m.");
}

/*
 * set0, set1, t0sn, t1sn:  io.n or m.n, the bit number going into
 * the opcode at offset.
 */
void
ebitn(a_uint op, struct inst io, struct inst m, int offset)
{
	int ioAdr = (op & PDK_OPCODE_ADR_IO) ? 1 : 0;
	struct expr e, e1;
	a_uint bitn;
	int t;

	clrexpr(&e);
	clrexpr(&e1);
	t = addr(&e, ioAdr);
	comma(1);
	if (pdkbit(&e1) != S_K)
		xerr('a', "A bit number is required.");
	if (!is_abs(&e1) || (e1.e_addr & ~((a_uint) 7)))
		xerr('a', "A bit number is 0 to 7.");
	bitn = (e1.e_addr & 7) << offset;
	if (t == S_IO) {
		io.op |= bitn;
		outpdkaw(io, &e);
	} else
	if (t == S_M) {
		m.op |= bitn;
		outpdkrm(m, &e);
	} else
		xerr('a', "Arguments: io,n or m,n.");
}

void
eskip(struct inst def, struct inst m)
{
	struct expr e;
	int t;

	clrexpr(&e);
	t = addr(&e, 0);
	if (t == S_A) {
		comma(1);
		clrexpr(&e);
		t = addr(&e, 0);
	}
	if (t == S_M) {
		outpdkrm(m, &e);
	} else
	if (t == S_K) {
		outpdkrm(def, &e);
	} else
		xerr('a', "Arguments: a,m or a,#k.");
}

void
ezsn(struct inst def, struct inst m)
{
	/* izsn and dzsn take what not takes. */
	enot(def, m);
}

void
eret(struct inst def, struct inst k)
{
	struct expr e;

	if (more()) {
		clrexpr(&e);
		if (addr(&e, 0) != S_K)
			xerr('a', "Argument: #k.");
		outpdkrm(k, &e);
	} else
		outpdka(def);
}

void
eone(struct inst m)
{
	struct expr e;

	clrexpr(&e);
	if (addr(&e, 0) != S_M)
		xerr('a', "Argument: m.");
	outpdkrm(m, &e);
}

void
exch(struct inst m)
{
	struct expr e;
	int t;

	clrexpr(&e);
	t = addr(&e, 0);
	if (t == S_A) {
		comma(1);
		clrexpr(&e);
		t = addr(&e, 0);
	}
	if (t != S_M)
		xerr('a', "Arguments: a,m or m.");
	outpdkrm(m, &e);
}

/*
 * pushaf and popaf, and push af and pop af, which carry 0x2000 in
 * their value to say they take the af operand.
 */
void
epupo(struct inst def)
{
	if (def.op & 0x2000) {
		if (!pdkreg("af"))
			xerr('a', "Argument: af.");
		def.op &= 0x1FFF;
	}
	outpdka(def);
}

/*
 * An instruction whose one operand is a, which may be left out.
 */
void
eopta(struct inst def)
{
	struct expr e;

	if (more()) {
		clrexpr(&e);
		if (addr(&e, 0) != S_A)
			xerr('a', "Argument: a.");
	}
	outpdka(def);
}

void
eswapc(a_uint op, struct inst iok, int offset)
{
	int ioAdr = (op & PDK_OPCODE_ADR_IO) ? 1 : 0;
	struct expr e, e1;
	int t, t1;

	clrexpr(&e);
	clrexpr(&e1);
	t = addr(&e, ioAdr);
	comma(1);
	t1 = pdkbit(&e1);
	if (t != S_IO || t1 != S_K)
		xerr('a', "Arguments: io,n.");
	if (!is_abs(&e1) || (e1.e_addr & ~((a_uint) 7)))
		xerr('a', "A bit number is 0 to 7.");
	iok.op |= (e1.e_addr & 7) << offset;
	outpdkaw(iok, &e);
}

void
espec(struct inst am, struct inst ma)
{
	struct expr e, e1;
	int t, t1;

	clrexpr(&e);
	clrexpr(&e1);
	t = addr(&e, 0);
	comma(1);
	t1 = addr(&e1, 0);
	if (t == S_A && t1 == S_M) {
		outpdkrm(am, &e1);
	} else
	if (t == S_M && t1 == S_A) {
		outpdkrm(ma, &e);
	} else
		xerr('a', "Arguments: a,m or m,a.");
}

/*
 * goto and call:  a code address, in words, as code is.
 */
void
ejump(struct inst def)
{
	struct expr e;

	clrexpr(&e);
	expr(&e);
	e.e_mode = S_M;
	outpdkrm(def, &e);
}
